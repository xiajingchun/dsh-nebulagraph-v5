/**
 * Integration test: run an in-process fake `nebula.proto.graph.GraphService`
 * (same vendored protos as the client) and verify the full authenticate →
 * execute → decode → error → disconnect flow over real gRPC.
 */

import assert from 'node:assert/strict'
import { describe, it } from 'node:test'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import * as grpc from '@grpc/grpc-js'
import * as protoLoader from '@grpc/proto-loader'
import { NebulaClient, STATUS_SUCCESS } from '../src/nebula-client.ts'

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

/** A one-column string result table, e.g. `SHOW GRAPHS`. */
function graphsTable(names: string[]): unknown {
  return {
    data_layout_version: Buffer.from([1]),
    meta: {
      table_type: 0,
      num_records: String(names.length),
      row_type: {
        num_columns: 1,
        column_names: ['graph_name'],
        column_types: [{ value_type: Buffer.from([0x10]) }],
      },
      num_batches: 1,
      time_zone_offset: 0,
      is_little_endian: true,
      graph_schema: null,
    },
    batch: [{ vectors: [{ num_nested_vectors: 0, common_meta_data: { num_records: names.length, vector_content_type: 2 }, special_meta_data: Buffer.alloc(0), vector_data: Buffer.concat(names.map(inlineString)), null_bit_map: null, nested_vectors: [] }] }],
  }
}

function okStatus(): { code: Buffer; message: Buffer } {
  return { code: Buffer.from(STATUS_SUCCESS), message: Buffer.from('') }
}

interface FakeGraphService {
  authenticate(req: { username: Buffer; auth_info: Buffer; client_info: { lang: string; protocol_version: Buffer; version: Buffer } }): {
    status: { code: Buffer; message: Buffer }
    session_id: number
    version: Buffer
  }
  execute(req: { session_id: number | string; stmt: Buffer }): {
    status: { code: Buffer; message: Buffer }
    result?: unknown
    summary?: unknown
  }
  seenAuth?: { username: string; authInfo: string; lang: string }
  seenSessionIds: (number | string)[]
  seenStmts: string[]
}

function startFakeServer(): Promise<{ port: number; close: () => Promise<void>; fake: FakeGraphService }> {
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
  const fake: FakeGraphService = {
    authenticate(req) {
      fake.seenAuth = {
        username: req.username.toString(),
        authInfo: req.auth_info.toString(),
        lang: req.client_info.lang,
      }
      if (req.username.toString() === 'baduser') {
        return { status: { code: Buffer.from('E_BAD_USERNAME_PASSWORD'), message: Buffer.from('bad credentials') }, session_id: 0, version: Buffer.from('') }
      }
      return { status: okStatus(), session_id: 42, version: Buffer.from('5.0.0-test') }
    },
    execute(req) {
      fake.seenSessionIds.push(req.session_id)
      const stmt = req.stmt.toString()
      fake.seenStmts.push(stmt)
      if (stmt.startsWith('BAD')) {
        return { status: { code: Buffer.from('E_SYNTAX_ERROR'), message: Buffer.from('syntax error near BAD') } }
      }
      if (stmt.startsWith('SHOW GRAPHS')) {
        return { status: okStatus(), result: graphsTable(['movie', 'ldbc']), summary: { elapsed_time: { total_server_time_us: '1234' } } }
      }
      if (stmt === 'USE graph') {
        return { status: okStatus() }
      }
      return { status: okStatus() }
    },
    seenSessionIds: [],
    seenStmts: [],
  }
  const server = new grpc.Server()
  server.addService(grpcObj.nebula.proto.graph.GraphService.service, {
    authenticate: (call: grpc.ServerUnaryCall<{ username: Buffer; auth_info: Buffer; client_info: { lang: string; protocol_version: Buffer; version: Buffer } }, unknown>, callback: grpc.sendUnaryData<unknown>) => {
      callback(null, fake.authenticate(call.request))
    },
    execute: (call: grpc.ServerUnaryCall<{ session_id: string | number; stmt: Buffer }, unknown>, callback: grpc.sendUnaryData<unknown>) => {
      callback(null, fake.execute(call.request))
    },
  } as never)
  return new Promise((resolve, reject) => {
    server.bindAsync('127.0.0.1:0', grpc.ServerCredentials.createInsecure(), (err, port) => {
      if (err !== null && err !== undefined) {
        reject(err)
        return
      }
      resolve({
        port,
        fake,
        close: () => new Promise<void>((res) => server.tryShutdown(() => res())),
      })
    })
  })
}

describe('NebulaClient over gRPC', () => {
  it('authenticates, executes, decodes, and reports server errors', async () => {
    const fakeServer = await startFakeServer()
    try {
      const client = await NebulaClient.connect({
        host: '127.0.0.1',
        port: fakeServer.port,
        user: 'root',
        password: 'secret',
        timeoutMs: 10_000,
      })
      assert.equal(client.serverVersion, '5.0.0-test')
      assert.deepEqual(fakeServer.fake.seenAuth, {
        username: 'root',
        authInfo: JSON.stringify({ password: 'secret' }),
        lang: 'JAVASCRIPT',
      })
      // The password is cleared from the options object right after
      // authentication, so it never lingers in memory (or the registry) for
      // the connection's lifetime.
      assert.equal((client as unknown as { options: { password: string } }).options.password, '')

      const result = await client.execute('SHOW GRAPHS')
      assert.equal(result.ok, true)
      assert.deepEqual(result.columns, ['graph_name'])
      assert.deepEqual(result.rows, [['movie'], ['ldbc']])
      assert.equal(result.numRows, 2)
      assert.equal(result.latencyUs, 1234)

      const useResult = await client.execute('USE graph')
      assert.equal(useResult.ok, true)
      assert.deepEqual(useResult.rows, [])

      const badResult = await client.execute('BAD QUERY')
      assert.equal(badResult.ok, false)
      assert.deepEqual(badResult.error, { code: 'E_SYNTAX_ERROR', message: 'syntax error near BAD' })

      // Session id (int64 on the wire) is reused across calls on the same connection.
      assert.deepEqual(fakeServer.fake.seenSessionIds, ['42', '42', '42'])

      // Closing signs the session out via the SESSION CLOSE statement (v5 has
      // no signout RPC), so the server-side session is actually released.
      await client.close()
      assert.equal(client.isClosed, true)
      assert.equal(fakeServer.fake.seenStmts.at(-1), 'SESSION CLOSE')
      assert.equal(fakeServer.fake.seenSessionIds.length, 4)
    } finally {
      await fakeServer.close()
    }
  })

  it('rejects authentication failures with NebulaError', async () => {
    const fakeServer = await startFakeServer()
    try {
      await assert.rejects(
        () => NebulaClient.connect({ host: '127.0.0.1', port: fakeServer.port, user: 'baduser', password: 'x', timeoutMs: 10_000 }),
        /authentication failed: E_BAD_USERNAME_PASSWORD/,
      )
    } finally {
      await fakeServer.close()
    }
  })

  it('fails loudly on an unreachable server', async () => {
    await assert.rejects(
      () => NebulaClient.connect({ host: '127.0.0.1', port: 1, user: 'root', password: 'x', timeoutMs: 3_000 }),
      /gRPC call failed|connect ECONNREFUSED|deadline exceeded|unavailable/i,
    )
  })
})
