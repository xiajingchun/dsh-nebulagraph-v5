/**
 * Plugin-level integration test: run the plugin's `apply` against a stub
 * context, then drive the registered tools end-to-end against the in-process
 * fake GraphService (same fixture as client.test.ts).
 */

import assert from 'node:assert/strict'
import { describe, it } from 'node:test'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import * as grpc from '@grpc/grpc-js'
import * as protoLoader from '@grpc/proto-loader'
import type { ToolDefinition } from '@deepseek-ai/dsh-tools'
import { apply, Config } from '../src/index.ts'
import type { ToolRunContext } from '@deepseek-ai/dsh-tools'

const protoDir = join(dirname(fileURLToPath(import.meta.url)), '..', 'src', 'proto')

function u32(n: number): Buffer {
  const b = Buffer.alloc(4)
  b.writeUInt32LE(n >>> 0, 0)
  return b
}
function inlineString(s: string): Buffer {
  const bytes = Buffer.from(s, 'utf8')
  const header = Buffer.alloc(16)
  bytes.copy(header, 4)
  header.writeUInt32LE(bytes.length, 0)
  return header
}

function graphsTable(names: string[]): unknown {
  return {
    data_layout_version: Buffer.from([1]),
    meta: {
      table_type: 0,
      num_records: String(names.length),
      row_type: { num_columns: 1, column_names: ['graph_name'], column_types: [{ value_type: Buffer.from([0x10]) }] },
      num_batches: 1,
      time_zone_offset: 0,
      is_little_endian: true,
      graph_schema: null,
    },
    batch: [{ vectors: [{ num_nested_vectors: 0, common_meta_data: { num_records: names.length, vector_content_type: 2 }, special_meta_data: Buffer.alloc(0), vector_data: Buffer.concat(names.map(inlineString)), null_bit_map: null, nested_vectors: [] }] }],
  }
}

function startFakeServer(): Promise<{ port: number; close: () => Promise<void>; seenStmts: string[] }> {
  const packageDefinition = protoLoader.loadSync(['nebula/graph.proto', 'nebula/common.proto', 'nebula/vector.proto'], {
    includeDirs: [protoDir],
    keepCase: true,
    longs: String,
    enums: String,
    defaults: true,
    oneofs: true,
  })
  const grpcObj = grpc.loadPackageDefinition(packageDefinition) as unknown as {
    nebula: { proto: { graph: { GraphService: { service: grpc.ServiceDefinition } } } }
  }
  const seenStmts: string[] = []
  const server = new grpc.Server()
  server.addService(grpcObj.nebula.proto.graph.GraphService.service, {
    authenticate: (call: grpc.ServerUnaryCall<unknown, unknown>, callback: grpc.sendUnaryData<unknown>) => {
      callback(null, { status: { code: Buffer.from('00000'), message: Buffer.from('') }, session_id: '7', version: Buffer.from('5.0.0') })
    },
    execute: (call: grpc.ServerUnaryCall<{ session_id: string; stmt: Buffer }, unknown>, callback: grpc.sendUnaryData<unknown>) => {
      const stmt = call.request.stmt.toString()
      seenStmts.push(stmt)
      if (stmt.startsWith('SHOW GRAPHS')) {
        callback(null, { status: { code: Buffer.from('00000'), message: Buffer.from('') }, result: graphsTable(['movie', 'ldbc']), summary: { elapsed_time: { total_server_time_us: '99' } } })
      } else {
        callback(null, { status: { code: Buffer.from('00000'), message: Buffer.from('') } })
      }
    },
  } as never)
  return new Promise((resolve, reject) => {
    server.bindAsync('127.0.0.1:0', grpc.ServerCredentials.createInsecure(), (err, port) => {
      if (err !== null && err !== undefined) reject(err)
      else resolve({ port, seenStmts, close: () => new Promise<void>((res) => server.tryShutdown(() => res())) })
    })
  })
}

/** A minimal stub context exposing just what the plugin's `apply` touches. */
function stubContext() {
  const registered = new Map<string, ToolDefinition>()
  const sections: { name: string; order: number; text: string }[] = []
  const disposers: (() => void)[] = []
  const ctx = {
    tools: {
      register: (tool: ToolDefinition): void => {
        registered.set(tool.name, tool)
      },
    },
    systemPrompt: {
      section: (s: { name: string; order: number; text: string }): void => {
        sections.push(s)
      },
    },
    skills: {
      registerProvider: (): (() => void) => () => {},
    },
    effect: (cb: () => () => void): (() => void) => {
      const disposer = cb()
      disposers.push(disposer)
      return () => {}
    },
  }
  return { ctx, registered, sections, disposers }
}

function runExec(tool: ToolDefinition, args: unknown): Promise<unknown> {
  const exec = { signal: new AbortController().signal } as unknown as ToolRunContext
  return tool.execute(args, exec) as Promise<unknown>
}

describe('dsh-nebula plugin', () => {
  it('registers the three tools and a prompt section', () => {
    const { ctx, registered, sections } = stubContext()
    apply(ctx as never, Config({}))
    assert.deepEqual([...registered.keys()], ['nebula_connect', 'nebula_execute', 'nebula_disconnect'])
    assert.ok(sections.some((s) => s.name === 'tool:nebula'))
  })

  it('connects, executes, and disconnects end-to-end', async () => {
    const fakeServer = await startFakeServer()
    try {
      const { ctx, registered, disposers } = stubContext()
      apply(ctx as never, Config({}))

      const connectTool = registered.get('nebula_connect')!
      const executeTool = registered.get('nebula_execute')!
      const disconnectTool = registered.get('nebula_disconnect')!

      const connected = (await runExec(connectTool, {
        host: '127.0.0.1',
        port: fakeServer.port,
        user: 'root',
        password: 'secret',
      })) as { connectionId: string; serverVersion: string; host: string; port: number }
      assert.equal(connected.serverVersion, '5.0.0')
      assert.equal(connected.port, fakeServer.port)
      assert.ok(connected.connectionId.length > 0)

      const result = (await runExec(executeTool, { connectionId: connected.connectionId, gql: 'SHOW GRAPHS' })) as {
        ok: boolean
        columns: string[]
        rows: unknown[][]
        numRows: number
      }
      assert.equal(result.ok, true)
      assert.deepEqual(result.columns, ['graph_name'])
      assert.deepEqual(result.rows, [['movie'], ['ldbc']])
      assert.equal(result.numRows, 2)

      // Unknown connection ids fail loudly.
      await assert.rejects(
        () => runExec(executeTool, { connectionId: 'nope', gql: 'SHOW GRAPHS' }),
        /unknown connectionId nope/,
      )

      const closed = (await runExec(disconnectTool, { connectionId: connected.connectionId })) as { closed: boolean }
      assert.equal(closed.closed, true)

      // Disconnect must actually release the server-side session: the v5
      // protocol signs out by executing the SESSION CLOSE statement.
      assert.equal(fakeServer.seenStmts.at(-1), 'SESSION CLOSE')

      // Plugin dispose closes any remaining sessions (registry cleanup).
      await Promise.all(disposers.map((disposer) => disposer()))
    } finally {
      await fakeServer.close()
    }
  })
})
