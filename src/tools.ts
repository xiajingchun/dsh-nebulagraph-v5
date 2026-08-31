/**
 * Model-facing NebulaGraph tools: connect, execute nGQL, disconnect.
 *
 * The connection lifecycle mirrors the ngql console: authenticate once with
 * host/port/user/password, then execute statements on the same server-side
 * session (so `USE graph` persists), and finally disconnect.
 */

import { defineTool } from '@deepseek-ai/dsh-tools'
// dsh-tools ≥ 0.1.2-alpha.2 no longer re-exports JsonValue; it now lives in
// dsh-util-values (the tools package imports it from there internally).
import type { JsonValue } from '@deepseek-ai/dsh-util-values'
import { NebulaClient } from './nebula-client.ts'
import type { NebulaExecuteResult, TlsMode, TlsOptions } from './nebula-client.ts'
import { formatValue, renderTable } from './format.ts'
import { extractGraphData } from './graphData.ts'
import type { GraphProjection } from './graphData.ts'
import type { ConnectionEntry, ConnectionRegistry } from './registry.ts'
import { resolveInstanceSource } from './instances.ts'
import type { NebulaInstance, NebulaInstanceSettings } from './instances.ts'
import { buildSchemaGraphMeta, collectGraphSchema, formatSchemaOverview, parseGraphTypeDesc, parseShowGraphs, sessionSetGraph } from './schema.ts'

/** A credential reference is a POSIX shell identifier (same rule as the DSH credentials seam). */
const REF_PATTERN = /^[A-Za-z_][A-Za-z0-9_]*$/

/** Validate a credential reference without depending on the host's credentials package. */
function assertCredentialRef(ref: string): string {
  if (!REF_PATTERN.test(ref)) {
    throw new TypeError(`passwordRef "${ref}" must be a POSIX identifier (letters, digits, underscore)`)
  }
  return ref
}

/** Defaults used when a tool argument is omitted. */
export interface NebulaToolDefaults {
  host: string
  port: number
  user: string
  password: string
  /**
   * Credential reference (environment variable name) resolving to the
   * default login password. Resolved per connection through the DSH
   * credentials seam (falling back to the process environment), so the
   * password never appears in tool arguments or configuration surfaces.
   * Takes precedence over the plaintext `password` default.
   */
  passwordRef?: string
  /** TLS mode for new connections (default `auto`). */
  tls: TlsMode
  /** CA bundle (PEM) for verifying the server certificate. */
  ca?: string
  /** Client certificate (PEM) for mutual TLS. */
  cert?: string
  /** Client private key (PEM) for mutual TLS. */
  key?: string
  /** Server name override for SNI and certificate verification. */
  servername?: string
  timeoutMs: number
  /** Upper bound on concurrently open connections (default 5). */
  maxConnections: number
}

/** Argument shape of `nebula_connect`. */
export interface ConnectArgs {
  /**
   * Alias of a NebulaGraph instance profile configured in Settings →
   * NebulaGraph (e.g. `prod`). Resolves host/port/user/passwordRef/tls from
   * the profile; per-call arguments still override the profile. Omit to use
   * the configured default instance, then plugin config.
   */
  instance?: string
  host?: string
  port?: number
  user?: string
  /**
   * Credential reference (environment variable name) resolving to this
   * connection's password. Overrides the configured `passwordRef` default.
   */
  passwordRef?: string
  /** TLS mode: `off` (plaintext), `on` (TLS required), `auto` (try TLS, fall back). */
  tls?: TlsMode
  /** CA bundle (PEM) for verifying the server certificate. */
  ca?: string
  timeoutMs?: number
}

/** Argument shape of `nebula_execute`. */
export interface ExecuteArgs {
  connectionId: string
  gql: string
  timeoutMs?: number
}

/** Argument shape of `nebula_disconnect`. */
export interface DisconnectArgs {
  connectionId: string
}

/**
 * Resolve one connect call's effective parameters.
 *
 * The base values come from the instance profile addressed by `instance`
 * (or the settings default), falling back to plugin config; per-call tool
 * arguments override on top of that. A non-auto TLS policy in the ACTIVE
 * configuration (the resolved profile, else plugin config) is an ENFORCED
 * transport policy: the model-facing tool argument must not weaken it.
 *
 * @param args - the tool's arguments.
 * @param defaults - resolved plugin-config defaults.
 * @param instanceSettings - the current `dsh-nebula` settings section.
 * @returns the effective input plus the resolved profile provenance.
 */
function resolveConnectArgs(
  args: ConnectArgs,
  defaults: NebulaToolDefaults,
  instanceSettings: NebulaInstanceSettings,
): {
  input: Omit<Required<ConnectArgs>, 'passwordRef' | 'ca' | 'instance'> & { passwordRef?: string; ca?: string }
  source: { instance?: NebulaInstance; viaDefault?: boolean; warning?: string }
} {
  const source = resolveInstanceSource(args.instance?.trim(), instanceSettings)
  const instance = source.instance
  const baseHost = instance?.host ?? defaults.host
  const basePort = instance?.port ?? defaults.port
  const baseUser = instance?.user ?? defaults.user
  const basePasswordRef = instance?.passwordRef ?? defaults.passwordRef
  const baseTls = instance?.tls ?? defaults.tls
  const baseCa = instance?.ca ?? defaults.ca
  const baseTimeoutMs = instance?.timeoutMs ?? defaults.timeoutMs
  const sourceLabel = instance !== undefined ? `instance "${instance.alias}"` : 'plugin config'

  if (args.host !== undefined && args.host.trim().length === 0) throw new Error('host must be a non-empty string')
  const port = args.port ?? basePort
  if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error(`port must be an integer in [1, 65535], got ${port}`)
  const timeoutMs = args.timeoutMs ?? baseTimeoutMs
  if (!Number.isInteger(timeoutMs) || timeoutMs < 1) throw new Error('timeoutMs must be a positive integer')
  let tls = args.tls ?? baseTls
  if (tls !== 'off' && tls !== 'on' && tls !== 'auto') throw new Error(`tls must be "off", "on", or "auto", got ${tls}`)
  // A non-auto tls in the active configuration is an ENFORCED transport
  // policy: the model-facing tool argument must not weaken it (e.g.
  // tls: "on" → "auto" would silently downgrade to plaintext and defeat the
  // admin's intent). The tool may only choose tls when the active
  // configuration leaves it flexible ("auto").
  if (args.tls !== undefined && baseTls !== 'auto' && args.tls !== baseTls) {
    throw new Error(
      `tls is enforced as "${baseTls}" by ${sourceLabel} and cannot be overridden to "${args.tls}" by a tool argument;`
      + ' change the instance settings or plugin config if a different transport policy is intended',
    )
  }
  return {
    input: {
      host: args.host ?? baseHost,
      port,
      user: args.user ?? baseUser,
      passwordRef: args.passwordRef ?? basePasswordRef,
      tls,
      ca: args.ca ?? baseCa,
      timeoutMs,
    },
    source,
  }
}

/** TLS options for one connection, merging the resolved profile with per-call overrides. */
function resolveTlsOptions(
  input: { tls: TlsMode; ca?: string },
  defaults: NebulaToolDefaults,
  source: { instance?: NebulaInstance },
): TlsOptions {
  const tls: TlsOptions = { mode: input.tls }
  const instance = source.instance
  const ca = input.ca ?? instance?.ca
  if (ca !== undefined && ca.trim().length > 0) tls.ca = ca
  const cert = instance?.cert ?? defaults.cert
  if (cert !== undefined && cert.length > 0) tls.cert = cert
  const key = instance?.key ?? defaults.key
  if (key !== undefined && key.length > 0) tls.key = key
  const servername = instance?.servername ?? defaults.servername
  if (servername !== undefined && servername.length > 0) tls.servername = servername
  return tls
}

/**
 * Resolve the password for one connection: an explicit or configured
 * `passwordRef` wins (resolved through the DSH credentials seam, falling
 * back to the process environment), then the configured plaintext password.
 * The value is used only for the authenticate call and never surfaces in
 * tool arguments, output, or the registry.
 */
async function resolvePassword(
  ctx: { get<T>(key: string): T | undefined },
  ref: string | undefined,
  fallback: string,
): Promise<string> {
  if (ref !== undefined && ref.trim().length > 0) {
    const resolved = await resolveCredentialValue(ctx, ref)
    if (resolved !== undefined && resolved.length > 0) return resolved
    throw new Error(`passwordRef "${ref}" did not resolve to a value; set it in the environment or the DSH credentials store`)
  }
  return fallback
}

/** Resolve one credential reference through the credentials seam, then the environment. */
async function resolveCredentialValue(
  ctx: { get<T>(key: string): T | undefined },
  ref: string,
): Promise<string | undefined> {
  assertCredentialRef(ref)
  type CredentialsLike = { resolve(ref: string): Promise<{ value: string } | undefined> }
  const credentials = ctx.get<CredentialsLike>('credentials')
  if (credentials !== undefined) {
    const resolved = await credentials.resolve(ref)
    if (resolved !== undefined && resolved.value.length > 0) return resolved.value
  }
  const ambient = process.env[ref]
  return ambient !== undefined && ambient.length > 0 ? ambient : undefined
}

function formatConnectOutput(result: {
  connectionId: string
  host: string
  port: number
  user: string
  serverVersion: string
  tlsFallback?: boolean
  instance?: string
  viaDefault?: boolean
  warning?: string
}): string {
  const where = result.instance !== undefined
    ? ` (instance "${result.instance}"${result.viaDefault === true ? ', default' : ''})`
    : ''
  const lines = [
    `Connected to NebulaGraph at ${result.host}:${result.port} as ${result.user}${where}.`,
    `Server version: ${result.serverVersion}`,
    `Connection id: ${result.connectionId} — pass it to nebula_execute to run queries.`,
  ]
  if (result.tlsFallback === true) {
    lines.push('Warning: the server did not complete a TLS handshake; connected over plaintext (insecure). Set tls: "on" to require TLS.')
  }
  if (result.warning !== undefined && result.warning.length > 0) {
    lines.push(`Warning: ${result.warning}`)
  }
  return lines.join('\n')
}

/** Render an execute result like the ngql console: table, row count, errors. */
function formatExecuteOutput(result: NebulaExecuteResult): string {
  if (!result.ok) {
    return `Error: ${result.error?.code ?? 'UNKNOWN'}: ${result.error?.message ?? 'unknown error'}`
  }
  const parts: string[] = []
  if (result.columns.length > 0) {
    parts.push(renderTable(result.columns, result.rows))
  }
  const footerBits: string[] = []
  if (result.numRows > 0) footerBits.push(`Got ${result.numRows} rows`)
  if (result.latencyUs > 0) footerBits.push(`time spent ${result.latencyUs}us`)
  if (result.summary?.affectedNodes !== undefined && result.summary.affectedNodes > 0) {
    footerBits.push(`affected nodes: ${result.summary.affectedNodes}`)
  }
  if (result.summary?.affectedEdges !== undefined && result.summary.affectedEdges > 0) {
    footerBits.push(`affected edges: ${result.summary.affectedEdges}`)
  }
  if (footerBits.length > 0) parts.push(footerBits.join(' '))
  return parts.join('\n')
}

/**
 * Primary-key lookup from the per-entry catalog cache. The v5 columnar
 * result carries no primary-key definition, so this only knows what
 * `SHOW GRAPHS` + `DESC GRAPH TYPE` already populated.
 */
function lookupPrimaryKey(entry: ConnectionEntry, graph: string, type: string): string[] | undefined {
  const cache = entry.schemaCache
  if (cache === undefined) return undefined
  const graphType = cache.graphTypes.get(graph)
  if (graphType === undefined) return undefined
  return cache.nodePrimaryKeys.get(`${graphType}\0${type}`)
}

/** Multiedge-key lookup (same catalog cache as primary keys). */
function lookupMultiedgeKey(entry: ConnectionEntry, graph: string, type: string): string[] | undefined {
  const cache = entry.schemaCache
  if (cache === undefined) return undefined
  const graphType = cache.graphTypes.get(graph)
  if (graphType === undefined) return undefined
  return cache.edgeMultiedgeKeys.get(`${graphType}\0${type}`)
}

/** Fetch `DESC GRAPH TYPE` for one graph type; best-effort, cached, deduped. */
async function fetchElementKeys(entry: ConnectionEntry, graphType: string, signal?: AbortSignal): Promise<void> {
  const cache = entry.schemaCache
  if (cache === undefined) return
  const pending = cache.inflight.get(graphType)
  if (pending !== undefined) {
    await pending
    return
  }
  const run = (async () => {
    try {
      const desc = await entry.client.execute(`DESC GRAPH TYPE \`${graphType.replaceAll('`', '``')}\``, signal)
      if (desc.ok) {
        const { nodes, edges } = parseGraphTypeDesc(desc)
        for (const node of nodes) {
          cache.nodePrimaryKeys.set(`${graphType}\0${node.name}`, node.primaryKey)
        }
        for (const edge of edges) {
          cache.edgeMultiedgeKeys.set(`${graphType}\0${edge.name}`, edge.multiedgeKey)
        }
      }
    } catch {
      // Catalog resolution is best-effort: an empty key degrades the client
      // label to its fallback instead of failing the query.
    }
  })()
  cache.inflight.set(graphType, run)
  try {
    await run
  } finally {
    cache.inflight.delete(graphType)
  }
}

/**
 * Resolve the primary/multiedge-key property names for every
 * (graph, element type) pair, warming the per-entry cache with
 * `SHOW GRAPHS` + `DESC GRAPH TYPE`.
 */
async function resolveElementKeys(
  entry: ConnectionEntry,
  nodePairs: Array<[string, string]>,
  edgePairs: Array<[string, string]>,
  signal?: AbortSignal,
): Promise<void> {
  const pairs = [...nodePairs, ...edgePairs]
  if (pairs.length === 0) return
  if (entry.schemaCache === undefined) {
    entry.schemaCache = {
      graphTypes: new Map(),
      nodePrimaryKeys: new Map(),
      edgeMultiedgeKeys: new Map(),
      inflight: new Map(),
    }
  }
  const cache = entry.schemaCache
  const graphs = [...new Set(pairs.map(([graph]) => graph))]
  const missingGraphs = graphs.filter((graph) => !cache.graphTypes.has(graph))
  if (missingGraphs.length > 0) {
    try {
      const show = await entry.client.execute('SHOW GRAPHS', signal)
      if (show.ok) {
        for (const info of parseShowGraphs(show)) {
          if (info.graphType !== '') cache.graphTypes.set(info.name, info.graphType)
        }
      }
    } catch {
      // best-effort (see fetchElementKeys)
    }
  }
  const graphTypes = [...new Set(
    pairs.map(([graph]) => cache.graphTypes.get(graph)).filter((t): t is string => t !== undefined),
  )]
  await Promise.all(graphTypes.map((graphType) => fetchElementKeys(entry, graphType, signal)))
}

/**
 * Register the NebulaGraph tools on `ctx.tools`.
 *
 * @param ctx - the plugin context (must expose `ctx.tools` and, when
 *   available, the optional `ctx.credentials` seam).
 * @param registry - the shared connection registry.
 * @param defaults - resolved plugin-config defaults.
 * @param instanceSettings - reads the current `dsh-nebula` settings section
 *   (instance profiles by alias); falls back to an empty section when no
 *   settings provider is composed. MUST read the live section at call time:
 *   the settings source lands asynchronously after plugin apply (cordis
 *   defers inject callbacks through a microtask), so a thunk holding a value
 *   captured at registration would never see committed changes.
 * @returns the registration disposer (usually left to the effect registry).
 */
export function applyNebulaTools(
  ctx: {
    tools: { register(tool: ReturnType<typeof defineTool>): unknown }
    get<T>(key: string): T | undefined
  },
  registry: ConnectionRegistry,
  defaults: NebulaToolDefaults,
  instanceSettings: () => NebulaInstanceSettings = () => ({ instances: [] }),
): void {
  ctx.tools.register(defineTool({
    name: 'nebula_connect',
    description: 'Connect to a NebulaGraph server and start a session. Returns a connectionId to use with nebula_execute. To use a pre-configured instance, pass its alias as the `instance` argument (e.g. instance: "prod") — host/port/user/passwordRef/tls then come from that profile; otherwise the instance marked as default in Settings is used, then plugin config. Per-call host/port/user/passwordRef/tls/ca/timeoutMs still override the profile. The password is resolved per connection from the configured passwordRef (via the DSH credentials seam or the environment) — never pass a password as a tool argument. TLS defaults to "auto": try TLS, then fall back to plaintext when the server has no TLS listener; set tls to "on" to require TLS, or "off" for plaintext only. If a connection with tls: "on" fails, the server does not speak TLS or its certificate is untrusted — do NOT retry with different host/user/port/tls arguments, that cannot fix it; report the error to the user instead. When the active instance or plugin config enforces a non-auto tls policy (tls: "on" or "off"), the tls argument cannot override it — the enforced policy applies and a conflicting tls argument is rejected.',
    parameters: {
      instance: { type: 'string', description: 'Alias of a configured NebulaGraph instance (Settings → NebulaGraph). Unknown aliases are rejected and the error lists the configured aliases.' },
      host: { type: 'string', description: 'Graphd host (defaults to the instance profile, then plugin config, 127.0.0.1).' },
      port: { type: 'number', description: 'Graphd gRPC port (defaults to 9669).' },
      user: { type: 'string', description: 'Login user name (defaults to root).' },
      passwordRef: { type: 'string', description: 'Credential reference (environment variable name) resolving to this connection\'s password; overrides the configured default. The password value itself is never a tool argument.' },
      tls: { type: 'string', description: 'TLS mode: "auto" (default, try TLS then fall back to plaintext), "on" (require TLS — failure means the server has no TLS or an untrusted certificate, do not retry), or "off" (plaintext). Ignored/rejected when the active instance or plugin config enforces a non-auto tls policy.' },
      ca: { type: 'string', description: 'CA bundle (PEM) for verifying the server certificate, when it is not trusted by the system roots.' },
      timeoutMs: { type: 'number', description: 'Connect/auth timeout in milliseconds (default 30000).' },
    },
    output: {
      schema: {
        type: 'object',
        additionalProperties: false,
        properties: {
          connectionId: { type: 'string' },
          host: { type: 'string' },
          port: { type: 'number' },
          user: { type: 'string' },
          serverVersion: { type: 'string' },
          tlsFallback: { type: 'boolean' },
          instance: { type: 'string' },
          viaDefault: { type: 'boolean' },
          warning: { type: 'string' },
        },
      },
      render: (_args, value) => [{ type: 'text', text: formatConnectOutput(value as never) }],
    },
    timeoutMs: 60_000,
    async execute(args, exec) {
      const { input, source } = resolveConnectArgs(args as ConnectArgs, defaults, instanceSettings())
      if (registry.list().length >= defaults.maxConnections) {
        throw new Error(`connection limit reached (${defaults.maxConnections}); disconnect an idle connection first (nebula_disconnect)`)
      }
      const password = await resolvePassword(ctx, input.passwordRef, defaults.password)
      const tls = resolveTlsOptions(input, defaults, source)
      // The same options object is passed to the client AND stored in the
      // registry: `authenticate` clears `password` on it after success, so
      // the plaintext never lingers in either the client or the registry.
      const options = { ...input, password, tls }
      const client = await NebulaClient.connect(options, exec.signal)
      const entry = registry.add(options, client)
      return {
        connectionId: entry.connectionId,
        host: input.host,
        port: input.port,
        user: input.user,
        serverVersion: client.serverVersion,
        tlsFallback: client.usedTlsFallback || undefined,
        ...source.instance === undefined ? {} : { instance: source.instance.alias },
        ...source.viaDefault === true ? { viaDefault: true } : {},
        ...source.warning === undefined ? {} : { warning: source.warning },
      }
    },
  }))

  ctx.tools.register(defineTool({
    name: 'nebula_execute',
    description: 'Execute an nGQL statement on an open NebulaGraph connection (from nebula_connect) and return the result table as structured rows. The server-side session persists, so "USE graph" and similar statements affect later calls on the same connectionId. Use one statement per call.',
    parameters: {
      connectionId: { type: 'string', required: true, description: 'The connection id returned by nebula_connect.' },
      gql: { type: 'string', required: true, description: 'The nGQL statement to execute, e.g. "SHOW GRAPHS", "USE `movie`", "MATCH (v) RETURN v LIMIT 10".' },
      timeoutMs: { type: 'number', description: 'Per-call timeout in milliseconds (defaults to the connection timeout).' },
    },
    output: {
      schema: {
        type: 'object',
        additionalProperties: false,
        properties: {
          ok: { type: 'boolean' },
          columns: { type: 'array', items: { type: 'string' } },
          rows: { type: 'json' },
          numRows: { type: 'number' },
          latencyUs: { type: 'number' },
          error: {
            type: 'object',
            additionalProperties: false,
            properties: {
              code: { type: 'string' },
              message: { type: 'string' },
            },
          },
          summary: {
            type: 'object',
            additionalProperties: false,
            properties: {
              affectedNodes: { type: 'number' },
              affectedEdges: { type: 'number' },
              exportedRecords: { type: 'number' },
              totalServerTimeUs: { type: 'number' },
              numWarnings: { type: 'number' },
            },
          },
        },
      },
      render: (_args, value) => [{ type: 'text', text: formatExecuteOutput(value as never) }],
      // Replayable graph projection: the Web Client renders an interactive
      // AntV G6 graph from this meta when the result contains nodes/edges.
      // Node primary keys and edge multiedge keys are resolved from the
      // per-entry catalog cache (warmed by execute) — see resolveElementKeys.
      presentationMeta: (args, value) => {
        const entry = registry.get((args as ExecuteArgs).connectionId)
        const rows = (value as { rows?: unknown[][] }).rows
        const graph = entry === undefined
          ? extractGraphData(rows)
          : extractGraphData(
              rows,
              (graphName, type) => lookupPrimaryKey(entry, graphName, type),
              (graphName, type) => lookupMultiedgeKey(entry, graphName, type),
            )
        // Projection objects are plain JSON; the interface cast keeps the
        // host schema honest at the meta boundary.
        return (graph === undefined ? {} : { graph }) as unknown as JsonValue
      },
    },
    async execute(args, exec) {
      const entry = registry.get(args.connectionId)
      if (entry === undefined) {
        throw new Error(`unknown connectionId ${args.connectionId}; open one with nebula_connect first`)
      }
      if (args.gql.trim().length === 0) throw new Error('gql must be a non-empty statement')
      const result = await entry.client.execute(args.gql, exec.signal)
      // Track the session's working graph so `nebula_schema` (and the model's
      // follow-up queries) know which graph the session is on.
      if (result.ok) {
        const graph = sessionSetGraph(args.gql)
        if (graph !== undefined) entry.currentGraph = graph
      }
      // Warm the element-key catalog cache for graph-shaped results so the
      // presentation meta can label nodes with primary keys and edges with
      // their multiedge keys.
      if (result.ok) {
        const rows = result.rows as unknown[][]
        const missingNodes: Array<[string, string]> = []
        const missingEdges: Array<[string, string]> = []
        extractGraphData(
          rows,
          (graphName, type) => {
            const pk = lookupPrimaryKey(entry, graphName, type)
            if (pk === undefined) missingNodes.push([graphName, type])
            return pk
          },
          (graphName, type) => {
            const mk = lookupMultiedgeKey(entry, graphName, type)
            if (mk === undefined) missingEdges.push([graphName, type])
            return mk
          },
        )
        await resolveElementKeys(entry, missingNodes, missingEdges, exec.signal)
      }
      // Decoded cells are JSON-safe by construction (see the decode package).
      return { ...result, rows: result.rows as JsonValue[][] }
    },
  }))

  ctx.tools.register(defineTool({
    name: 'nebula_disconnect',
    description: 'Close an open NebulaGraph connection (from nebula_connect) and release its server-side session. Call this when you are done querying.',
    parameters: {
      connectionId: { type: 'string', required: true, description: 'The connection id returned by nebula_connect.' },
    },
    output: {
      schema: {
        type: 'object',
        additionalProperties: false,
        properties: {
          connectionId: { type: 'string' },
          closed: { type: 'boolean' },
        },
      },
      render: (_args, value) => [{ type: 'text', text: `Connection ${formatValue(value)} closed.` }],
    },
    async execute(args) {
      const entry = await registry.remove(args.connectionId)
      if (entry === undefined) {
        return { connectionId: args.connectionId, closed: false }
      }
      return { connectionId: args.connectionId, closed: true }
    },
  }))

  const graphInfoSchema = {
    type: 'object',
    additionalProperties: false,
    properties: {
      name: { type: 'string', required: true },
      graphType: { type: 'string', required: true },
      schema: { type: 'string', required: true },
      owner: { type: 'string', required: true },
      extra: { type: 'string', required: true },
    },
  } as const
  const nodeTypeSchema = {
    type: 'object',
    additionalProperties: false,
    properties: {
      name: { type: 'string', required: true },
      pattern: { type: 'string', required: true },
      labels: { type: 'array', items: { type: 'string' }, required: true },
      primaryKey: { type: 'array', items: { type: 'string' }, required: true },
      properties: { type: 'array', items: { type: 'string' }, required: true },
    },
  } as const
  const edgeTypeSchema = {
    type: 'object',
    additionalProperties: false,
    properties: {
      name: { type: 'string', required: true },
      pattern: { type: 'string', required: true },
      source: { type: 'string', required: true },
      target: { type: 'string', required: true },
      labels: { type: 'array', items: { type: 'string' }, required: true },
      multiedgeKey: { type: 'array', items: { type: 'string' }, required: true },
      properties: { type: 'array', items: { type: 'string' }, required: true },
    },
  } as const

  ctx.tools.register(defineTool({
    name: 'nebula_schema',
    description: 'Introspect the schema of a NebulaGraph v5 graph: runs SHOW GRAPHS, resolves the target graph (explicit graph= argument, or the session working graph from SESSION SET graph, or the sole graph), then DESC GRAPH TYPE <graph_type> and returns the graph type\'s node types and edge types (labels, primary/multiedge keys, properties). Read-only: the session working graph is never changed. The Web Client renders the result as an interactive G6 schema graph — do not re-render the schema as additional charts or diagrams (e.g. dsh-ui) in your reply; summarize in text (and plain tables when useful) only.',
    parameters: {
      connectionId: { type: 'string', required: true, description: 'The connection id returned by nebula_connect.' },
      graph: { type: 'string', description: 'Target graph name. Omit to use the session working graph (SESSION SET graph) or the sole graph.' },
    },
    output: {
      schema: {
        type: 'object',
        additionalProperties: false,
        properties: {
          ok: { type: 'boolean', required: true },
          graphs: { type: 'array', items: graphInfoSchema, required: true },
          graph: graphInfoSchema,
          nodes: { type: 'array', items: nodeTypeSchema, required: true },
          edges: { type: 'array', items: edgeTypeSchema, required: true },
          numNodes: { type: 'number', required: true },
          numEdges: { type: 'number', required: true },
        },
      },
      render: (_args, value) => [{ type: 'text', text: formatSchemaOverview(value as never) }],
      // Replayable schema-graph projection: the Web Client draws the graph
      // type as a meta-graph (node types as vertices, edge types as arcs).
      presentationMeta: (_args, value) => {
        const projection = buildSchemaGraphMeta(value as never)
        return { graph: projection } as unknown as JsonValue
      },
    },
    async execute(args, exec) {
      const entry = registry.get(args.connectionId)
      if (entry === undefined) {
        throw new Error(`unknown connectionId ${args.connectionId}; open one with nebula_connect first`)
      }
      const overview = await collectGraphSchema(
        (stmt) => entry.client.execute(stmt, exec.signal),
        args.graph,
        entry.currentGraph,
      )
      return overview
    },
  }))
}
