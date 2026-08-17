/**
 * TLS mode behavior against a PLAINTEXT server (i.e. a server whose listener
 * does not speak TLS at all):
 *
 * - `auto` (default): the TLS probe fails at the transport level, the client
 *   falls back to plaintext, and the caller is told via `usedTlsFallback`.
 * - `on`: TLS is required, so connecting to a plaintext server fails.
 * - `off`: plaintext directly, no probe, no fallback flag.
 *
 * Uses `localhost` (a hostname) so the TLS handshake is a real attempt; an IP
 * target makes Node reject the SNI servername locally, which would not
 * exercise the same code path.
 */
import { describe, it } from 'node:test'
import assert from 'node:assert/strict'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import * as grpc from '@grpc/grpc-js'
import * as protoLoader from '@grpc/proto-loader'
import { NebulaClient } from '../src/nebula-client.ts'

const protoDir = join(dirname(fileURLToPath(import.meta.url)), '..', 'src', 'proto')

describe('TLS modes against a plaintext server', () => {
  it('auto falls back to plaintext and reports it; on fails; off connects cleanly', async () => {
    const packageDefinition = protoLoader.loadSync(['nebula/graph.proto', 'nebula/common.proto', 'nebula/vector.proto'], {
      includeDirs: [protoDir], keepCase: true, longs: String, enums: String, defaults: true, oneofs: true,
    })
    const grpcObj = grpc.loadPackageDefinition(packageDefinition) as unknown as {
      nebula: { proto: { graph: { GraphService: { service: grpc.ServiceDefinition } } } }
    }
    const server = new grpc.Server()
    server.addService(grpcObj.nebula.proto.graph.GraphService.service, {
      authenticate: (_call: never, callback: grpc.sendUnaryData<unknown>) => {
        callback(null, { status: { code: Buffer.from('00000'), message: Buffer.from('') }, session_id: '42', version: Buffer.from('5.0.0') })
      },
      execute: (_call: never, callback: grpc.sendUnaryData<unknown>) => {
        callback(null, { status: { code: Buffer.from('00000'), message: Buffer.from('') } })
      },
    } as never)
    const port = await new Promise<number>((resolve, reject) => {
      server.bindAsync('127.0.0.1:0', grpc.ServerCredentials.createInsecure(), (err, p) => (err ? reject(err) : resolve(p)))
    })
    try {
      // auto: TLS probe fails at transport level → plaintext fallback + flag.
      const auto = await NebulaClient.connect({ host: 'localhost', port, user: 'root', password: 'x', timeoutMs: 8000 })
      assert.equal(auto.usedTlsFallback, true)
      await auto.close()

      // on: TLS required — the plaintext server must fail the connection,
      // and the error must make clear this is a server-side TLS issue that
      // retrying with different host/user/port cannot fix (so the agent stops
      // attempting rather than looping).
      await assert.rejects(
        () => NebulaClient.connect({ host: 'localhost', port, user: 'root', password: 'x', timeoutMs: 8000, tls: { mode: 'on' } }),
        (err: unknown) => {
          const message = (err as Error).message
          return /TLS connection to .* failed/.test(message)
            && /did not complete a TLS handshake/.test(message)
            && /retrying with different host, user, or port/.test(message)
        },
      )

      // off: plaintext directly — connects without a probe or fallback.
      const off = await NebulaClient.connect({ host: 'localhost', port, user: 'root', password: 'x', timeoutMs: 8000, tls: { mode: 'off' } })
      assert.equal(off.usedTlsFallback, false)
      await off.close()
    } finally {
      await new Promise<void>((resolve) => server.tryShutdown(() => resolve()))
    }
  })
})
