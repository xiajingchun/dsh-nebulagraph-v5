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

/**
 * Encode one string column as a flat string vector. Short values (≤ 12 bytes)
 * inline into the 16-byte header; longer values are appended to a shared
 * chunk referenced by the header (the v5 columnar string layout).
 */
function strVector(rows: string[]): unknown {
  const headers: Buffer[] = []
  let chunkData = Buffer.alloc(0)
  for (const s of rows) {
    const bytes = Buffer.from(s, 'utf8')
    const header = Buffer.alloc(16)
    header.writeUInt32LE(bytes.length, 0)
    if (bytes.length <= 12) {
      bytes.copy(header, 4)
    } else {
      header.writeUInt32LE(chunkData.length, 8) // chunk offset
      header.writeUInt32LE(0, 12) // chunk index (single shared chunk)
      chunkData = Buffer.concat([chunkData, bytes])
    }
    headers.push(header)
  }
  const chunked = chunkData.length > 0
  return {
    num_nested_vectors: chunked ? 1 : 0,
    common_meta_data: { num_records: rows.length, vector_content_type: 2 },
    special_meta_data: Buffer.alloc(0),
    vector_data: Buffer.concat(headers),
    null_bit_map: null,
    nested_vectors: chunked
      ? [{
          num_nested_vectors: 0,
          common_meta_data: { num_records: 1, vector_content_type: 1 },
          special_meta_data: Buffer.alloc(0),
          vector_data: chunkData,
          null_bit_map: null,
          nested_vectors: [],
        }]
      : [],
  }
}

/** A multi-column string result table (e.g. `SHOW GRAPHS`, `DESC GRAPH TYPE`). */
function stringsTable(columns: string[], rows: string[][]): unknown {
  const vectors = columns.map((_, ci) => strVector(rows.map((r) => r[ci] ?? '')))
  return {
    data_layout_version: Buffer.from([1]),
    meta: {
      table_type: 0,
      num_records: String(rows.length),
      row_type: {
        num_columns: columns.length,
        column_names: columns,
        column_types: columns.map(() => ({ value_type: Buffer.from([0x10]) })),
      },
      num_batches: 1,
      time_zone_offset: 0,
      is_little_endian: true,
      graph_schema: null,
    },
    batch: [{ vectors }],
  }
}

/** `SHOW GRAPHS` as the v5 server returns it: name / graph_type / schema / owner / extra. */
function showGraphsTable(): unknown {
  return stringsTable(['name', 'graph_type', 'schema', 'owner', 'extra'], [
    ['movie', 'movie_type', '/default_schema', 'root', ''],
    ['basketballplayer', 'basketballplayer', '/default_schema', 'root', ''],
  ])
}

/** `DESC GRAPH TYPE movie_type` rows: node types + edge types with patterns. */
function descGraphTypeTable(): unknown {
  return stringsTable(
    ['entity_type', 'type_name', 'type_pattern', 'labels', 'primary_key/multiedge_key', 'properties'],
    [
      ['Node', 'Actor', '(Actor)', '[Person]', '[id]', '[id,name,birthDate]'],
      ['Node', 'Director', '(Director)', '[Person]', '[id]', '[id,name,birthDate]'],
      ['Node', 'User', '(User)', '[Person]', '[id]', '[id]'],
      ['Node', 'Movie', '(Movie)', '[Movie]', '[id]', '[id,name]'],
      ['Node', 'Genre', '(Genre)', '[Genre]', '[id]', '[id,name]'],
      ['Edge', 'Act', '(Actor)-[Act]->(Movie)', '[Act]', 'Unique', '[]'],
      ['Edge', 'Direct', '(Director)-[Direct]->(Movie)', '[Direct]', 'Unique', '[]'],
      ['Edge', 'Watch', '(User)-[Watch]->(Movie)', '[Watch]', 'Unique', '[rate]'],
      ['Edge', 'WithGenre', '(Movie)-[WithGenre]->(Genre)', '[WithGenre]', 'Unique', '[]'],
    ],
  )
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
      const okStatus = { code: Buffer.from('00000'), message: Buffer.from('') }
      if (stmt.startsWith('SHOW GRAPHS')) {
        callback(null, { status: okStatus, result: showGraphsTable(), summary: { elapsed_time: { total_server_time_us: '99' } } })
      } else if (stmt.startsWith('DESC GRAPH TYPE')) {
        callback(null, { status: okStatus, result: descGraphTypeTable() })
      } else if (/^\s*SESSION SET graph\s+/i.test(stmt)) {
        callback(null, { status: okStatus })
      } else {
        callback(null, { status: okStatus })
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
  it('registers the four tools and a prompt section', () => {
    const { ctx, registered, sections } = stubContext()
    apply(ctx as never, Config({}))
    assert.deepEqual(
      [...registered.keys()],
      ['nebula_connect', 'nebula_execute', 'nebula_disconnect', 'nebula_schema'],
    )
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
      assert.deepEqual(result.columns, ['name', 'graph_type', 'schema', 'owner', 'extra'])
      assert.deepEqual(result.rows, [
        ['movie', 'movie_type', '/default_schema', 'root', ''],
        ['basketballplayer', 'basketballplayer', '/default_schema', 'root', ''],
      ])
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

  it('introspects a graph schema with nebula_schema (SESSION SET graph + explicit graph)', async () => {
    const fakeServer = await startFakeServer()
    try {
      const { ctx, registered } = stubContext()
      apply(ctx as never, Config({}))

      const connectTool = registered.get('nebula_connect')!
      const executeTool = registered.get('nebula_execute')!
      const schemaTool = registered.get('nebula_schema')!

      const connected = (await runExec(connectTool, {
        host: '127.0.0.1',
        port: fakeServer.port,
        user: 'root',
        password: 'secret',
      })) as { connectionId: string }

      // Switching the working graph is tracked: an explicit SESSION SET graph
      // followed by a graph-less nebula_schema targets the working graph.
      await runExec(executeTool, { connectionId: connected.connectionId, gql: 'SESSION SET graph movie' })
      const overview = (await runExec(schemaTool, { connectionId: connected.connectionId })) as {
        ok: boolean
        graph: { name: string; graphType: string }
        nodes: { name: string; primaryKey: string[] }[]
        edges: { name: string; source: string; target: string; properties: string[] }[]
        numNodes: number
        numEdges: number
      }
      assert.equal(overview.ok, true)
      assert.equal(overview.graph.name, 'movie')
      assert.equal(overview.graph.graphType, 'movie_type')
      assert.equal(overview.numNodes, 5)
      assert.equal(overview.numEdges, 4)
      const actor = overview.nodes.find((n) => n.name === 'Actor')
      assert.deepEqual(actor?.primaryKey, ['id'])
      const act = overview.edges.find((e) => e.name === 'Act')
      assert.equal(act?.source, 'Actor')
      assert.equal(act?.target, 'Movie')

      // The tool projects a replayable schema-graph meta for the Web Client.
      const meta = schemaTool.output.presentationMeta?.({}, overview as never) as {
        graph: { kind: string; graphType: string; nodes: unknown[]; edges: unknown[] }
      }
      assert.equal(meta.graph.kind, 'schema')
      assert.equal(meta.graph.graphType, 'movie_type')
      assert.equal(meta.graph.nodes.length, 5)
      assert.equal(meta.graph.edges.length, 4)

      // An explicit graph argument overrides the working graph.
      const explicit = (await runExec(schemaTool, { connectionId: connected.connectionId, graph: 'basketballplayer' })) as {
        graph: { name: string; graphType: string }
      }
      assert.equal(explicit.graph.name, 'basketballplayer')
      assert.equal(explicit.graph.graphType, 'basketballplayer')

      // Unknown graphs fail loudly with the available list.
      await assert.rejects(
        () => runExec(schemaTool, { connectionId: connected.connectionId, graph: 'nope' }),
        /unknown graph nope.*available graphs: movie, basketballplayer/,
      )
      // Unknown connection ids fail loudly too.
      await assert.rejects(
        () => runExec(schemaTool, { connectionId: 'nope' }),
        /unknown connectionId nope/,
      )
    } finally {
      await fakeServer.close()
    }
  })
})
