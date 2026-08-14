/**
 * dsh-nebula — a DeepSeek Harness plugin that connects to NebulaGraph 5.0 and
 * executes nGQL queries, in the spirit of the `ngql` console.
 *
 * The plugin registers three model-facing tools:
 * - `nebula_connect` — authenticate against a graphd (gRPC) and open a session
 * - `nebula_execute` — run one nGQL statement, returning decoded rows
 * - `nebula_disconnect` — close the session
 *
 * Connection parameters default to plugin config (cordis.yml) and can be
 * overridden per call. All registrations are effect-based: unloading the
 * plugin closes every open session and unregisters the tools.
 *
 * @module dsh-nebula
 */

import type { Context } from '@deepseek-ai/cordis'
import z from 'schemastery'
import { ConnectionRegistry } from './registry.ts'
import { applyGqlSkillProvider } from './skill.ts'
import { applyNebulaTools } from './tools.ts'
import type { NebulaToolDefaults } from './tools.ts'

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
  /** Default login password. */
  password?: string
  /** Default per-request timeout in milliseconds. */
  timeoutMs?: number
  /** Upper bound on concurrently open connections. */
  maxConnections?: number
}

export const Config: z<Config> = z.object({
  host: z.string().default('127.0.0.1'),
  port: z.number().default(9669),
  user: z.string().default('root'),
  password: z.string().default(''),
  timeoutMs: z.number().default(30_000),
  maxConnections: z.number().default(5),
})

/** Resolve the validated config into tool defaults. */
function resolveConfig(config: Config): NebulaToolDefaults {
  const port = config.port ?? 9669
  const timeoutMs = config.timeoutMs ?? 30_000
  const maxConnections = config.maxConnections ?? 5
  if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error('dsh-nebula: port must be an integer in [1, 65535]')
  if (!Number.isInteger(timeoutMs) || timeoutMs < 1) throw new Error('dsh-nebula: timeoutMs must be a positive integer')
  if (!Number.isInteger(maxConnections) || maxConnections < 1) throw new Error('dsh-nebula: maxConnections must be a positive integer')
  return {
    host: config.host ?? '127.0.0.1',
    port,
    user: config.user ?? 'root',
    password: config.password ?? '',
    timeoutMs,
    maxConnections,
  }
}

/**
 * Plugin entry: register the NebulaGraph tools and a short guidance section,
 * and close every open session when the plugin unloads.
 *
 * @param ctx - plugin context (tools + systemPrompt services).
 * @param config - validated plugin config (schemastery fills defaults).
 */
export function apply(ctx: Context, config: Config): void {
  const defaults = resolveConfig(config)
  const registry = new ConnectionRegistry()

  applyNebulaTools(ctx, registry, defaults)
  applyGqlSkillProvider(ctx)

  ctx.systemPrompt.section({
    name: 'tool:nebula',
    order: 110,
    text: 'Use nebula_connect to connect to a NebulaGraph server (returns a connectionId), nebula_execute to run nGQL statements such as SHOW GRAPHS, USE graph, and MATCH/GET queries (results come back as structured rows plus an ngql-style table), and nebula_disconnect when done. One server-side session persists per connectionId, so a USE statement applies to later queries on the same connection. For writing or migrating GQL queries, load the gql-query-generator skill first.',
  })

  ctx.effect(() => async () => {
    await registry.dispose()
  })
}
