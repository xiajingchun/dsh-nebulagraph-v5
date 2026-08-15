/**
 * NebulaGraph 5.0 gRPC client: authenticate, execute nGQL, decode the
 * columnar result table into plain JSON, and tear down the session.
 *
 * The wire contract mirrors the official nebula-go v5 client:
 * - service `nebula.proto.graph.GraphService` with `Authenticate` / `Execute`
 * - `auth_info` is a JSON object carrying the password
 * - `client_info.lang` advertises JAVASCRIPT (5) with protocol version 5.0.0
 * - `Status.code == "00000"` means success
 */

import * as grpc from '@grpc/grpc-js'
import * as protoLoader from '@grpc/proto-loader'
import protobuf from 'protobufjs'
import { existsSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { EMBEDDED_PROTOS } from './generated-protos.ts'
import { decodeResultTable } from './decode/index.ts'
import type { DecodedTable } from './decode/index.ts'

/** Client software version advertised in `ClientInfo.version`. */
export const CLIENT_VERSION = 'dsh-nebula/0.1.0'

/** Wire protocol version declared by nebula-common `common.proto`. */
export const PROTOCOL_VERSION = '5.0.0'

/** SQLSTATE-style success code returned in `Status.code`. */
export const STATUS_SUCCESS = '00000'

/** Connection parameters for {@link NebulaClient}. */
export interface NebulaConnectOptions {
  /** Graphd host. */
  host: string
  /** Graphd gRPC port (default 9669). */
  port: number
  /** Login user name (default `root`). */
  user: string
  /** Login password. */
  password: string
  /** Per-request deadline in milliseconds (default 30000). */
  timeoutMs: number
}

/** Structured error thrown for transport and authentication failures. */
export class NebulaError extends Error {
  constructor(
    message: string,
    readonly kind: 'transport' | 'auth' | 'protocol' = 'transport',
  ) {
    super(message)
    this.name = 'NebulaError'
  }
}

/** Server-side query outcome (success or a reported query error). */
export interface NebulaExecuteResult {
  /** Whether the statement executed without a server-reported error. */
  ok: boolean
  /** Result column names. */
  columns: string[]
  /** Result rows; cells are plain JSON values. */
  rows: unknown[][]
  /** Number of rows returned. */
  numRows: number
  /** Server-side execution time in microseconds (when reported). */
  latencyUs: number
  /** Server-reported error (code + message) when `ok` is false. */
  error?: { code: string; message: string }
  /** Summary statistics reported by the server, when present. */
  summary?: {
    affectedNodes?: number
    affectedEdges?: number
    exportedRecords?: number
    totalServerTimeUs?: number
    numWarnings?: number
  }
}

interface AuthResponse {
  status: { code: Buffer; message: Buffer }
  session_id: string | number
  version: Buffer
}

interface ExecuteResponse {
  status: { code: Buffer; message: Buffer }
  result?: unknown
  summary?: {
    elapsed_time?: { total_server_time_us?: string | number }
    query_stats?: { num_affected_nodes?: string | number; num_affected_edges?: string | number; num_exported_records?: string | number }
    num_warnings?: string | number
  }
  cursor?: Buffer
}

type GraphServiceClient = {
  authenticate(req: unknown, options: grpc.CallOptions, cb: (err: grpc.ServiceError | null, resp?: AuthResponse) => void): grpc.ClientUnaryCall
  execute(req: unknown, options: grpc.CallOptions, cb: (err: grpc.ServiceError | null, resp?: ExecuteResponse) => void): grpc.ClientUnaryCall
  close(): void
}

// In CJS bundles `import.meta` is an empty object; the packaged proto dir is
// then unavailable and the loader falls back to in-memory parsing.
const protoDir = import.meta.url ? join(dirname(fileURLToPath(import.meta.url)), 'proto') : ''

let serviceCtor: (new (address: string, credentials: grpc.ChannelCredentials, options?: object) => GraphServiceClient) | null = null

/** protobufjs `toObject` options matching proto-loader's `keepCase/longs/enums/defaults/oneofs`. */
const TO_OBJECT_OPTIONS = { longs: String, enums: String, defaults: true, oneofs: true }

let protoRoot: protobuf.Root | null = null

/**
 * Parse the vendored protocol definitions fully in memory (no filesystem
 * access), so sandboxed single-file builds work. Each file keeps its own
 * `syntax`/`package` declaration and is parsed into the same root; the
 * `google/protobuf` descriptor dependency and the file-level custom options
 * it backs are stripped — the client never reads those extensions.
 */
function getProtoRoot(): protobuf.Root {
  if (protoRoot !== null) return protoRoot
  let root: protobuf.Root | undefined
  for (const file of ['common.proto', 'vector.proto', 'graph.proto']) {
    let source = EMBEDDED_PROTOS[file]
    source = stripDescriptorBits(source)
    source = stripImports(source)
    const parsed = root === undefined
      ? protobuf.parse(source, { keepCase: true })
      : protobuf.parse(source, root, { keepCase: true })
    root = parsed.root
  }
  if (root === undefined) throw new Error('failed to parse vendored protos')
  protoRoot = root
  return protoRoot
}

/** Drop the descriptor.proto import and the custom file-option machinery. */
function stripDescriptorBits(source: string): string {
  return source
    .replace(/^\s*import "google\/protobuf\/descriptor\.proto";\s*$/gm, '')
    .replace(/\n\s*extend google\.protobuf\.FileOptions \{[^}]*\}\s*/gs, '\n')
    .replace(/^\s*option \((?:protocol_version|supported_versions|meta_protocol_version|meta_supported_versions)\) = [^;]*;\s*$/gm, '')
}

/** Drop cross-file imports; every file is parsed into the same root. */
function stripImports(source: string): string {
  return source.replace(/^\s*import "[^"]+";\s*$/gm, '')
}

/** One hand-built method definition mirroring proto-loader's output shape. */
interface BuiltMethodDefinition extends grpc.MethodDefinition<object, object> {
  originalName: string
  requestType: { format: string; type: protobuf.Type }
  responseType: { format: string; type: protobuf.Type }
}

/** Build the gRPC package definition from the in-memory protobufjs root. */
function buildPackageDefinition(root: protobuf.Root): Record<string, unknown> {
  const service = root.lookupService('nebula.proto.graph.GraphService')
  // protobufjs fullName carries a leading dot; the wire FQN must not.
  const serviceFqn = service.fullName.replace(/^\./, '')
  const methods: Record<string, BuiltMethodDefinition> = {}
  for (const [methodName, method] of Object.entries(service.methods)) {
    const requestType = root.lookupType(method.requestType)
    const responseType = root.lookupType(method.responseType)
    // proto-loader keys methods by the original name and exposes the
    // camelCase accessor via `originalName`; mirror that so the generated
    // client surface matches (`client.authenticate`, `client.execute`, ...).
    const originalName = methodName.charAt(0).toLowerCase() + methodName.slice(1)
    methods[methodName] = {
      path: `/${serviceFqn}/${methodName}`,
      requestStream: method.requestStream ?? false,
      responseStream: method.responseStream ?? false,
      requestSerialize: (value) => Buffer.from(requestType.encode(requestType.fromObject(value)).finish()),
      requestDeserialize: (data) => requestType.toObject(requestType.decode(data), TO_OBJECT_OPTIONS) as object,
      responseSerialize: (value) => Buffer.from(responseType.encode(responseType.fromObject(value)).finish()),
      responseDeserialize: (data) => responseType.toObject(responseType.decode(data), TO_OBJECT_OPTIONS) as object,
      originalName,
      requestType: { format: 'Protocol Buffer 3 DescriptorProto', type: requestType },
      responseType: { format: 'Protocol Buffer 3 DescriptorProto', type: responseType },
    }
  }
  // Flat dotted-key format, matching proto-loader's package definition layout.
  return { [serviceFqn]: methods }
}

/** Lazily load the vendored protos and build the GraphService client class. */
function getServiceCtor(): (new (address: string, credentials: grpc.ChannelCredentials, options?: object) => GraphServiceClient) {
  if (serviceCtor !== null) return serviceCtor
  type PackageDefinition = ReturnType<typeof protoLoader.loadSync>
  let packageDefinition: PackageDefinition
  if (existsSync(join(protoDir, 'nebula', 'graph.proto'))) {
    // Packaged copy present: prefer the file-based loader.
    packageDefinition = protoLoader.loadSync(
      ['nebula/graph.proto', 'nebula/common.proto', 'nebula/vector.proto'],
      { includeDirs: [protoDir], keepCase: true, longs: String, enums: String, defaults: true, oneofs: true },
    )
  } else {
    // Single-file build: parse the embedded definitions in memory.
    packageDefinition = buildPackageDefinition(getProtoRoot()) as unknown as PackageDefinition
  }
  // loadPackageDefinition returns a nested namespace tree for dotted-key input.
  const grpcObj = grpc.loadPackageDefinition(packageDefinition) as unknown as {
    nebula: { proto: { graph: { GraphService: new (address: string, credentials: grpc.ChannelCredentials, options?: object) => GraphServiceClient } } }
  }
  const GraphService = grpcObj.nebula?.proto?.graph?.GraphService
  if (GraphService === undefined) throw new NebulaError('failed to load nebula GraphService from vendored protos', 'protocol')
  serviceCtor = GraphService
  return GraphService
}

function toErrorMessage(status: { code: Buffer; message: Buffer }): { code: string; message: string } {
  return {
    code: status.code.toString(),
    message: status.message.toString(),
  }
}

function callWithTimeout<T>(
  call: (options: grpc.CallOptions, cb: (err: grpc.ServiceError | null, resp?: T) => void) => grpc.ClientUnaryCall,
  timeoutMs: number,
  signal?: AbortSignal,
): Promise<T> {
  return new Promise<T>((resolve, reject) => {
    const options: grpc.CallOptions = { deadline: Date.now() + timeoutMs }
    const pending = call(options, (err, resp) => {
      if (signal !== undefined) signal.removeEventListener('abort', onAbort)
      if (err !== null && err !== undefined) reject(new NebulaError(`gRPC call failed: ${err.message}`, 'transport'))
      else if (resp === undefined) reject(new NebulaError('gRPC call returned no response', 'transport'))
      else resolve(resp)
    })
    const onAbort = (): void => {
      pending.cancel()
    }
    if (signal !== undefined) {
      if (signal.aborted) onAbort()
      else signal.addEventListener('abort', onAbort, { once: true })
    }
  })
}

/** One authenticated NebulaGraph session over a gRPC channel. */
export class NebulaClient {
  private channel: grpc.Client
  private client: GraphServiceClient
  private sessionId: number | string | null = null
  private closed = false
  private readonly options: NebulaConnectOptions

  private constructor(channel: grpc.Client, client: GraphServiceClient, options: NebulaConnectOptions) {
    this.channel = channel
    this.client = client
    this.options = options
  }

  /**
   * Connect to a graphd and authenticate. Throws {@link NebulaError} on
   * transport or authentication failure.
   *
   * @param options - connection parameters.
   * @param signal - optional abort signal to cancel the attempt.
   * @returns an authenticated client.
   */
  static async connect(options: NebulaConnectOptions, signal?: AbortSignal): Promise<NebulaClient> {
    const address = `${options.host}:${options.port}`
    const Ctor = getServiceCtor()
    const channel = new grpc.Client(address, grpc.credentials.createInsecure(), {
      'grpc.max_receive_message_length': -1,
      'grpc.max_send_message_length': -1,
      'grpc.keepalive_time_ms': 30_000,
    })
    const client = new Ctor(address, grpc.credentials.createInsecure(), {
      'grpc.max_receive_message_length': -1,
      'grpc.max_send_message_length': -1,
    })
    const nebula = new NebulaClient(channel, client, options)
    try {
      await nebula.authenticate(signal)
      return nebula
    } catch (err) {
      await nebula.close()
      throw err
    }
  }

  private async authenticate(signal?: AbortSignal): Promise<void> {
    const authInfo = JSON.stringify({ password: this.options.password })
    const resp = await callWithTimeout<AuthResponse>(
      (options, cb) => this.client.authenticate(
        {
          username: Buffer.from(this.options.user),
          auth_info: Buffer.from(authInfo),
          client_info: {
            lang: 'JAVASCRIPT',
            protocol_version: Buffer.from(PROTOCOL_VERSION),
            version: Buffer.from(CLIENT_VERSION),
          },
        },
        options,
        cb,
      ),
      this.options.timeoutMs,
      signal,
    )
    const status = toErrorMessage(resp.status)
    if (status.code !== STATUS_SUCCESS) {
      throw new NebulaError(`authentication failed: ${status.code}: ${status.message}`, 'auth')
    }
    this.sessionId = resp.session_id
    this.serverVersion = resp.version.toString()
  }

  /** Server version string reported at authentication. */
  serverVersion = ''

  /**
   * Execute one nGQL statement on this session and return the decoded result.
   *
   * @param stmt - the statement text (may contain multiple statements).
   * @param signal - optional abort signal to cancel the call.
   * @returns the decoded result table plus summary; server-reported query
   *   errors come back as `ok: false` with `error`, not as thrown exceptions.
   */
  async execute(stmt: string, signal?: AbortSignal): Promise<NebulaExecuteResult> {
    if (this.sessionId === null) throw new NebulaError('not authenticated')
    const resp = await callWithTimeout<ExecuteResponse>(
      (options, cb) => this.client.execute({ session_id: this.sessionId, stmt: Buffer.from(stmt) }, options, cb),
      this.options.timeoutMs,
      signal,
    )
    const status = toErrorMessage(resp.status)
    const latencyUs = toNumber(resp.summary?.elapsed_time?.total_server_time_us)
    if (status.code !== STATUS_SUCCESS) {
      return {
        ok: false,
        columns: [],
        rows: [],
        numRows: 0,
        latencyUs,
        error: status,
      }
    }
    const decoded: DecodedTable = decodeResultTable(resp.result as never)
    return {
      ok: true,
      columns: decoded.columns,
      rows: decoded.rows,
      numRows: decoded.numRecords,
      latencyUs,
      ...buildSummary(resp.summary),
    }
  }

  /** Whether the underlying channel is still open. */
  get isClosed(): boolean {
    return this.closed
  }

  /**
   * Close this session: sign out by executing the `SESSION CLOSE` statement
   * (the NebulaGraph 5.0 logout mechanism — the gRPC service has no signout
   * RPC, mirroring nebula-go v5 `connection.Close()`), then release the
   * channel. The logout is best-effort: transport or server errors are
   * ignored and the channel is always closed. Idempotent.
   */
  async close(): Promise<void> {
    if (this.closed) return
    this.closed = true
    if (this.sessionId !== null) {
      try {
        // Mirrors the official client: a short dedicated deadline, errors ignored.
        await callWithTimeout<ExecuteResponse>(
          (options, cb) => this.client.execute({ session_id: this.sessionId, stmt: Buffer.from(SESSION_CLOSE_STMT) }, options, cb),
          SESSION_CLOSE_TIMEOUT_MS,
        )
      } catch {
        // best-effort logout
      }
    }
    try {
      this.client.close()
    } catch {
      // closing an already-closed client is a no-op
    }
    this.channel.close()
  }
}

/** The statement that signs a session out on NebulaGraph 5.0 (v5 protocol). */
export const SESSION_CLOSE_STMT = 'SESSION CLOSE'

/** Deadline for the logout statement, matching nebula-go v5's `defaultCloseTimeout`. */
const SESSION_CLOSE_TIMEOUT_MS = 1_000

function toNumber(value: string | number | undefined | null): number {
  if (value === undefined || value === null) return 0
  const n = typeof value === 'string' ? Number(value) : value
  return Number.isFinite(n) ? n : 0
}

function buildSummary(summary: ExecuteResponse['summary']): Pick<NebulaExecuteResult, 'summary'> {
  const s = summary
  if (s === undefined || s === null) return {}
  return {
    summary: {
      ...s.query_stats?.num_affected_nodes !== undefined ? { affectedNodes: toNumber(s.query_stats.num_affected_nodes) } : {},
      ...s.query_stats?.num_affected_edges !== undefined ? { affectedEdges: toNumber(s.query_stats.num_affected_edges) } : {},
      ...s.query_stats?.num_exported_records !== undefined ? { exportedRecords: toNumber(s.query_stats.num_exported_records) } : {},
      ...s.elapsed_time?.total_server_time_us !== undefined ? { totalServerTimeUs: toNumber(s.elapsed_time.total_server_time_us) } : {},
      ...s.num_warnings !== undefined ? { numWarnings: toNumber(s.num_warnings) } : {},
    },
  }
}
