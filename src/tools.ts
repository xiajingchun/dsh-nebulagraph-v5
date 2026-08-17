/**
 * Model-facing NebulaGraph tools: connect, execute nGQL, disconnect.
 *
 * The connection lifecycle mirrors the ngql console: authenticate once with
 * host/port/user/password, then execute statements on the same server-side
 * session (so `USE graph` persists), and finally disconnect.
 */

import { defineTool } from '@deepseek-ai/dsh-tools'
import type { JsonValue } from '@deepseek-ai/dsh-tools'
import { NebulaClient } from './nebula-client.ts'
import type { NebulaExecuteResult } from './nebula-client.ts'
import { formatValue, renderTable } from './format.ts'
import { extractGraphData } from './graphData.ts'
import type { GraphProjection } from './graphData.ts'
import type { ConnectionEntry, ConnectionRegistry } from './registry.ts'
import { buildSchemaGraphMeta, collectGraphSchema, formatSchemaOverview, parseGraphTypeDesc, parseShowGraphs, sessionSetGraph } from './schema.ts'

/** Defaults used when a tool argument is omitted. */
export interface NebulaToolDefaults {
  host: string
  port: number
  user: string
  password: string
  timeoutMs: number
  /** Upper bound on concurrently open connections (default 5). */
  maxConnections: number
}

/** Argument shape of `nebula_connect`. */
export interface ConnectArgs {
  host?: string
  port?: number
  user?: string
  password?: string
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

function resolveConnectArgs(args: ConnectArgs, defaults: NebulaToolDefaults): Required<ConnectArgs> {
  if (args.host !== undefined && args.host.trim().length === 0) throw new Error('host must be a non-empty string')
  const port = args.port ?? defaults.port
  if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error(`port must be an integer in [1, 65535], got ${port}`)
  const timeoutMs = args.timeoutMs ?? defaults.timeoutMs
  if (!Number.isInteger(timeoutMs) || timeoutMs < 1) throw new Error('timeoutMs must be a positive integer')
  return {
    host: args.host ?? defaults.host,
    port,
    user: args.user ?? defaults.user,
    password: args.password ?? defaults.password,
    timeoutMs,
  }
}

function formatConnectOutput(result: {
  connectionId: string
  host: string
  port: number
  user: string
  serverVersion: string
}): string {
  return [
    `Connected to NebulaGraph at ${result.host}:${result.port} as ${result.user}.`,
    `Server version: ${result.serverVersion}`,
    `Connection id: ${result.connectionId} — pass it to nebula_execute to run queries.`,
  ].join('\n')
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
 * Register the three NebulaGraph tools on `ctx.tools`.
 *
 * @param ctx - the plugin context (must expose `ctx.tools`).
 * @param registry - the shared connection registry.
 * @param defaults - resolved plugin-config defaults.
 * @returns the registration disposer (usually left to the effect registry).
 */
export function applyNebulaTools(
  ctx: { tools: { register(tool: ReturnType<typeof defineTool>): unknown } },
  registry: ConnectionRegistry,
  defaults: NebulaToolDefaults,
): void {
  ctx.tools.register(defineTool({
    name: 'nebula_connect',
    description: 'Connect to a NebulaGraph server and start a session. Returns a connectionId to use with nebula_execute. Credentials default to plugin config; provide them per-call to connect elsewhere.',
    parameters: {
      host: { type: 'string', description: 'Graphd host (defaults to plugin config, 127.0.0.1).' },
      port: { type: 'number', description: 'Graphd gRPC port (defaults to 9669).' },
      user: { type: 'string', description: 'Login user name (defaults to plugin config, root).' },
      password: { type: 'string', description: 'Login password (defaults to plugin config).' },
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
        },
      },
      render: (_args, value) => [{ type: 'text', text: formatConnectOutput(value as never) }],
    },
    timeoutMs: 60_000,
    async execute(args, exec) {
      const input = resolveConnectArgs(args, defaults)
      if (registry.list().length >= defaults.maxConnections) {
        throw new Error(`connection limit reached (${defaults.maxConnections}); disconnect an idle connection first (nebula_disconnect)`)
      }
      const client = await NebulaClient.connect(input, exec.signal)
      const entry = registry.add(input, client)
      return {
        connectionId: entry.connectionId,
        host: input.host,
        port: input.port,
        user: input.user,
        serverVersion: client.serverVersion,
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
