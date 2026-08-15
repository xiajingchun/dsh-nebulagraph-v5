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
import type { ConnectionRegistry } from './registry.ts'

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
      presentationMeta: (_args, value) => {
        const graph = extractGraphData((value as { rows?: unknown[][] }).rows)
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
}
