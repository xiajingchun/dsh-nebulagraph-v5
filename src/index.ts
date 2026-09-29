/**
 * dsh-nebula — a DeepSeek Harness plugin that connects to NebulaGraph 5.0 and
 * executes nGQL queries, in the spirit of the `ngql` console.
 *
 * The plugin registers four model-facing tools:
 * - `nebula_connect` — authenticate against a graphd (gRPC) and open a session
 * - `nebula_execute` — run one nGQL statement, returning decoded rows
 * - `nebula_schema` — introspect a graph's schema (SHOW GRAPHS + DESC GRAPH TYPE)
 * - `nebula_disconnect` — close the session
 *
 * Connection parameters default to plugin config (cordis.yml) and can be
 * overridden per call. When the host composes a settings provider, the
 * plugin additionally registers a `dsh-nebula` settings namespace holding
 * named instance profiles (see ./instances.ts): `nebula_connect` then
 * accepts an `instance` alias resolved from Settings → NebulaGraph, so the
 * model can say "connect to the `prod` Nebula" and the connection targets
 * that profile. All registrations are effect-based: unloading the plugin
 * closes every open session and unregisters the tools.
 *
 * @module dsh-nebula
 */

// `Volatile` is the live-config reference a schemastery `.volatile()` field
// resolves to; cordis re-exports it from cosmokit, and it is type-only here,
// so no runtime dependency is added.
import type { Context, Volatile } from '@deepseek-ai/cordis'
// Type-only import: pulls in dsh-settings' `Context.settings` module
// augmentation (the provider methods are reached via ctx.inject below, so no
// runtime import is needed). Same pattern as the harness's own consumers.
import type {} from '@deepseek-ai/dsh-settings'
import z from '@deepseek-ai/schemastery'
import { ConnectionRegistry } from './registry.ts'
import { applyGqlSkillProvider } from './skill.ts'
import { applyNebulaTools } from './tools.ts'
import type { NebulaToolDefaults } from './tools.ts'
import type { TlsMode } from './nebula-client.ts'
import { registerInstancesApi } from './instances-api.ts'
import {
  NebulaInstanceSettingsFields,
  settingsNamespaceOf,
} from './instances.ts'
import type { NebulaInstance, NebulaInstanceSettings } from './instances.ts'

export {
  INSTANCE_ALIAS_PATTERN,
  NebulaInstanceSchema,
  NebulaInstanceSettingsFields,
  NebulaInstanceSettingsSchema,
  defaultAliasOf,
  findInstance,
  listAliases,
  resolveInstanceSource,
  settingsNamespaceOf,
  validateInstanceSettings,
} from './instances.ts'
export type { NebulaInstance, NebulaInstanceSettings } from './instances.ts'
export {
  NEBULA_API_PREFIX,
  applyInstancesUpdate,
  createInstancesApiHandler,
  isLoopbackHostname,
  isTrustedApiRequest,
  methodOf,
  readInstancesView,
  registerInstancesApi,
  trustedHostsOf,
} from './instances-api.ts'
export type { InstancesView, LoaderFace, SettingsFace, WebServerFace } from './instances-api.ts'
export { createGqlSkillProvider, loadPackagedSkill, PROVIDER_NAME, SKILL_DIR, SKILL_BODY_PATH } from './skill.ts'
export type { SkillMeta } from './skill.ts'

/** Cordis plugin name used by loader diagnostics. */
export const name = 'dsh-nebula'

/** Services required by this plugin. */
export const inject = ['tools', 'systemPrompt', 'skills']

/** Plugin config: default connection parameters + connection cap. */
export interface Config {
  /** Default graphd host. */
  host?: string
  /** Default graphd gRPC port. */
  port?: number
  /** Default login user name. */
  user?: string
  /** Default login password (plaintext; prefer `passwordRef`). */
  password?: string
  /**
   * Credential reference (environment variable name) resolving to the
   * default login password via the DSH credentials seam. Takes precedence
   * over the plaintext `password`; the value itself never appears in config
   * surfaces or tool arguments.
   */
  passwordRef?: string
  /** TLS mode for new connections: `off`, `on`, or `auto` (default). */
  tls?: TlsMode
  /** CA bundle (PEM) for verifying the server certificate. */
  ca?: string
  /** Client certificate (PEM) for mutual TLS. */
  cert?: string
  /** Client private key (PEM) for mutual TLS. */
  key?: string
  /** Server name override for SNI and certificate verification. */
  servername?: string
  /** Default per-request timeout in milliseconds. */
  timeoutMs?: number
  /** Upper bound on concurrently open connections. */
  maxConnections?: number
  /**
   * Named connection presets managed by Settings → NebulaGraph. Live
   * (volatile) storage: dsh-settings ≥ 0.2.0 edits the plugin's own profile
   * entry and commits volatile values into the running config in place.
   */
  instances: Volatile<NebulaInstance[]>
  /** Alias of the instance used when `nebula_connect` omits `instance`. */
  defaultInstance: Volatile<string | undefined>
  /** Credential references the settings page offers controls for. */
  credentialRefs: Volatile<string[]>
}

export const Config = z.object({
  host: z.string().default('127.0.0.1'),
  port: z.number().default(9669),
  user: z.string().default('root'),
  password: z.string().default(''),
  passwordRef: z.string(),
  tls: z.union(['off', 'on', 'auto'] as const).default('auto'),
  ca: z.string(),
  cert: z.string(),
  key: z.string(),
  servername: z.string(),
  timeoutMs: z.number().default(30_000),
  maxConnections: z.number().default(5),
  ...NebulaInstanceSettingsFields,
})

/**
 * Compile-time proof that the schema above resolves to the documented
 * {@link Config} shape (the type `apply` receives). The schema cannot be
 * *annotated* `z<Config>`: a volatile field accepts plain data as input and
 * resolves to a live reference, so the schema's input and output types differ
 * by design.
 */
type AssertTrue<T extends true> = T
const configSchemaMatches: AssertTrue<Schemastery.TypeT<typeof Config> extends Config ? true : false> = true
void configSchemaMatches

/** Resolve the validated config into tool defaults. */
function resolveConfig(config: Config): NebulaToolDefaults {
  const port = config.port ?? 9669
  const timeoutMs = config.timeoutMs ?? 30_000
  const maxConnections = config.maxConnections ?? 5
  if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error('dsh-nebula: port must be an integer in [1, 65535]')
  if (!Number.isInteger(timeoutMs) || timeoutMs < 1) throw new Error('dsh-nebula: timeoutMs must be a positive integer')
  if (!Number.isInteger(maxConnections) || maxConnections < 1) throw new Error('dsh-nebula: maxConnections must be a positive integer')
  const tls = config.tls ?? 'auto'
  if (tls !== 'off' && tls !== 'on' && tls !== 'auto') throw new Error('dsh-nebula: tls must be "off", "on", or "auto"')
  return {
    host: config.host ?? '127.0.0.1',
    port,
    user: config.user ?? 'root',
    password: config.password ?? '',
    passwordRef: config.passwordRef,
    tls,
    ca: config.ca,
    cert: config.cert,
    key: config.key,
    servername: config.servername,
    timeoutMs,
    maxConnections,
  }
}

/**
 * Plugin entry: register the NebulaGraph tools, the instance-profile settings
 * storage (when a settings provider exists), and a short guidance section,
 * and close every open session when the plugin unloads.
 *
 * @param ctx - plugin context (tools + systemPrompt services).
 * @param config - validated plugin config (schemastery fills defaults).
 */
export function apply(ctx: Context, config: Config): void {
  const defaults = resolveConfig(config)
  const registry = new ConnectionRegistry()

  // The instance profiles live in this plugin's own profile entry (the
  // `instances` / `defaultInstance` / `credentialRefs` volatile Config
  // fields); without a settings provider the section is simply the config
  // defaults (empty) and the tools fall back to plugin-config defaults
  // exactly as before. Reading through the volatile references at call time
  // always yields the freshly committed value — a settings write updates
  // them in place and never remounts the plugin, so nothing here may capture
  // a snapshot (see applyNebulaTools below).
  const instanceSettings = (): NebulaInstanceSettings => {
    const defaultInstance = config.defaultInstance?.get()
    return {
      instances: [...(config.instances?.get() ?? [])],
      ...defaultInstance === undefined ? {} : { defaultInstance },
      credentialRefs: [...(config.credentialRefs?.get() ?? [])],
    }
  }

  // Settings → NebulaGraph is a plugin-owned page (`settings.section` in the
  // Web Client), so opt this entry out of the schema-derived automatic page.
  // dsh-settings ≥ 0.2.0 replaced the old `installSection`/`validate` hooks:
  // the entry's Config schema is the storage contract, `configure` only owns
  // the page policy, and cross-field checks now run in the Web API before a
  // write (see applyInstancesUpdate).
  ctx.inject(['settings'], (settingsCtx) => {
    settingsCtx.effect(() => settingsCtx.settings.configure({ auto: false }, ctx.fiber))
  })

  // Settings → NebulaGraph page transport: a plugin-owned webServer route
  // (the client bundle cannot know this plugin's profile entry id, and the
  // harness's settings RPC offers no cross-field validation).
  // Registered only when a web surface + settings provider + loader are
  // composed — headless deployments simply never mount the route.
  const settingsNamespace = settingsNamespaceOf(ctx.fiber)
  ctx.inject(['settings', 'webServer', 'loader'], (sctx) => {
    // The injected services arrive as context properties; read them through
    // `get` with structural faces (the plugin does not depend on the
    // webserver/loader packages' types).
    sctx.effect(() => registerInstancesApi(
      sctx,
      sctx.get('settings') as never,
      sctx.get('webServer') as never,
      sctx.get('loader') as never,
      settingsNamespace,
    ), 'dsh-nebula: instances api route')
  })

  applyNebulaTools(ctx, registry, defaults, () => instanceSettings())
  applyGqlSkillProvider(ctx)

  ctx.systemPrompt.section({
    name: 'tool:nebula',
    order: 110,
    text: 'Use nebula_connect to connect to a NebulaGraph v5 server (returns a connectionId), nebula_execute to run GQL statements such as SHOW GRAPHS, SESSION SET graph <name>, and MATCH/GET queries (results come back as structured rows plus an ngql-style table), and nebula_disconnect when done. To connect to a pre-configured NebulaGraph instance, pass its alias as the `instance` argument — e.g. nebula_connect(instance: "prod") — no host/port/user/tls needed; aliases are managed by the user in Settings → NebulaGraph. When no `instance` argument is given, the instance marked as default in Settings is used, falling back to plugin config. One server-side session persists per connectionId, so SESSION SET graph applies to later queries on the same connection. To learn a graph\'s schema (node types, edge types, labels, keys, properties), call nebula_schema — it runs SHOW GRAPHS and DESC GRAPH TYPE for you, and the Web Client renders the schema as an interactive G6 graph, so never re-render schema results as extra charts or diagrams (e.g. dsh-ui) in replies; text summaries and plain tables are enough. When a user asks to return a node type or edge type (e.g. "return Star Wars directors and actors"), default the RETURN clause to the complete elements — the pattern\'s node and edge variables (or the path variable) — so the Web Client renders them as an interactive G6 graph; project a specific property (e.g. name) only when the user explicitly asks for it. Only NebulaGraph v5 ISO-GQL syntax is supported, exactly as documented in the gql-query-generator skill or as explicitly given by the user. NebulaGraph v5 speaks ISO-GQL, which is fundamentally different from — and incompatible with — the nGQL used by the open-source NebulaGraph: never reference, imitate, or migrate open-source nGQL syntax in any form (clauses such as GO/FETCH/LOOKUP and pipe syntax are not valid in v5). When writing or migrating GQL queries, load the gql-query-generator skill first and use only the v5 ISO-GQL it documents; if a construct is neither documented in the skill nor given by the user, do not guess from open-source nGQL knowledge — ask the user instead. Never ask the user for a password: nebula_connect resolves it from the configured passwordRef (credentials seam / environment) — if a connection needs credentials the user has not configured, say so and point them at the plugin config (or the instance\'s passwordRef in Settings → NebulaGraph) instead of accepting a password in chat. When nebula_connect fails, do not keep retrying with different arguments: a passwordRef resolution error means the credential is missing (tell the user how to configure it), an unknown instance alias means the alias is not configured (the error names the aliases the user has), and a tls: "on" failure means the server has no TLS or an untrusted certificate (report it — changing host/user/port/tls cannot fix it). Never work around a TLS failure by downgrading the transport: when the active instance or plugin config enforces tls: "on" or "off", do not pass a different tls argument to relax it (the tool rejects conflicting overrides) and do not suggest the user relax the policy — a TLS enforcement failure is a server configuration issue to report, not a connection to force. One failed attempt per distinct cause is enough; report the error and ask the user how to proceed.',
  })

  ctx.effect(() => async () => {
    await registry.dispose()
  })
}
