/**
 * Plugin-owned Web API backing the Settings → NebulaGraph page.
 *
 * dsh-settings ≥ 0.2.0 stores settings in the plugin's own profile entry, so
 * the section lives in the Config schema of the `dsh-nebula` row (see
 * ./instances.ts) rather than in a third-party settings namespace. The
 * harness's settings RPC addresses entries by profile id, which the client
 * bundle cannot know (the id is chosen by whoever mounts the plugin), so the
 * established plugin-owned pattern still applies: a webServer route with a
 * browser-trust fence, reading and writing the entry through the settings
 * provider directly. The route resolves the entry by the id the Loader
 * recorded on the plugin's fiber and reports it back in every view, so the
 * client can filter forwarded `settings/document-updated` events.
 *
 * Wire contract (JSON, POST to `/dsh-nebula/api/<method>`):
 * - `instances.get`    → `{ ok, value: { value, revision, writable, namespace } }`
 * - `instances.update` → payload `{ section, revision? }` →
 *                        `{ ok, value: { value, revision, writable, namespace } }`
 * Errors answer `{ ok: false, error: { code, message } }` with a matching
 * HTTP status. The route never exposes secrets: the section carries only
 * credential *references* (`passwordRef`), never password values.
 */

import type { IncomingMessage, ServerResponse } from 'node:http'
import type { Context } from '@deepseek-ai/cordis'
import { validateInstanceSettings } from './instances.ts'
import type { NebulaInstanceSettings } from './instances.ts'

/** Route prefix registered on the webServer. */
export const NEBULA_API_PREFIX = '/dsh-nebula/api'

/** The wire view of the entry: the resolved section plus write facts. */
export interface InstancesView {
  value: NebulaInstanceSettings
  /** Revision fencing the next write; undefined before the first read. */
  revision?: number
  /** Whether the settings document accepts writes. */
  writable: boolean
  /**
   * Profile entry id the section was read from (the settings namespace).
   * The client compares forwarded document-updated events against it.
   */
  namespace: string
}

/** Settings-provider face the route needs (structural — no package import). */
export interface SettingsFace {
  describe(options?: { redactSecrets?: boolean }): Array<{ ns: string; value: unknown; revision: number }>
  update(ns: string, patch: object, expectedRevision?: number): Promise<void>
  readonly writable: boolean
}

/** The webServer service face (structural). */
export interface WebServerFace {
  register(route: {
    kind: 'exact' | 'prefix'
    path: string
    handler: (req: IncomingMessage, res: ServerResponse) => void | Promise<void>
  }): () => void
}

/** The cordis loader face (structural) for the connection row's trustedHosts. */
export interface LoaderFace {
  entries(): Iterable<{ options: { name?: string; config?: { trustedHosts?: string[] } } }>
}

// ── Browser-trust fence (mirrors the harness gateway / better-sidebar) ──────

function header(headers: IncomingMessage['headers'], name: string): string | undefined {
  const value = headers[name]
  return typeof value === 'string' ? value : undefined
}

/** Parse a Host-header authority, or undefined when unparsable. */
function parseAuthority(authority: string): URL | undefined {
  try {
    return new URL(`http://${authority}`)
  } catch {
    return undefined
  }
}

/** Whether a normalized URL hostname names the local loopback authority. */
export function isLoopbackHostname(hostname: string): boolean {
  if (hostname === 'localhost' || hostname === '[::1]') return true
  const parts = hostname.split('.')
  return parts.length === 4
    && parts[0] === '127'
    && parts.every((part) => /^\d{1,3}$/.test(part) && Number(part) <= 255)
}

/**
 * Decide whether one settings-page request may reach the plugin route:
 * the Host header must be loopback or a deployment-trusted authority, and
 * browser requests must be same-origin (no cross-site fetch, matching
 * Origin). This is the same trust contract as the harness /api gateway.
 */
export function isTrustedApiRequest(
  request: Pick<IncomingMessage, 'headers'>,
  trustedHosts: readonly string[],
): boolean {
  const host = header(request.headers, 'host')
  if (host === undefined) return false
  const hostUrl = parseAuthority(host)
  if (hostUrl === undefined) return false
  const trusted = trustedHosts.some((entry) => {
    const entryUrl = parseAuthority(entry)
    if (entryUrl === undefined) return false
    // trustedHosts are port-less IP literals (the web runtime derives LAN
    // literals per boot); a port-less entry matches any port on that host.
    return entryUrl.port === '' ? entryUrl.hostname === hostUrl.hostname : entryUrl.host === hostUrl.host
  })
  if (!isLoopbackHostname(hostUrl.hostname) && !trusted) return false
  if (header(request.headers, 'sec-fetch-site') === 'cross-site') return false
  const origin = header(request.headers, 'origin')
  if (origin === undefined) return true
  try {
    return new URL(origin).host === hostUrl.host
  } catch {
    return false
  }
}

/** The connection row's resolved trustedHosts (live read, like better-sidebar). */
export function trustedHostsOf(loader: LoaderFace): string[] {
  for (const entry of loader.entries()) {
    if (entry.options.name === 'connection') return entry.options.config?.trustedHosts ?? []
  }
  return []
}

// ── View + write logic (pure, unit-testable) ────────────────────────────────

/** Read the current instance-profiles view from the settings provider. */
export function readInstancesView(settings: SettingsFace, namespace: string): InstancesView {
  const descriptor = settings.describe({ redactSecrets: true })
    .find((entry) => entry.ns === namespace)
  return {
    value: (descriptor?.value ?? { instances: [] }) as NebulaInstanceSettings,
    ...descriptor === undefined ? {} : { revision: descriptor.revision },
    writable: settings.writable,
    namespace,
  }
}

/**
 * Apply one client-supplied section. The client always sends the complete
 * `{ instances, defaultInstance, credentialRefs }` triple, so a merge update
 * over the current user layer replaces each field; an empty `defaultInstance`
 * clears the default. The provider validates the section against the Config
 * schema (rejecting the write with its message) and this function runs the
 * cross-field checks the schema cannot express before any write.
 *
 * @param settings - the settings provider.
 * @param namespace - profile entry id holding the section.
 * @param payload - the raw POST body of `instances.update`.
 * @returns the fresh view after the committed write.
 */
export async function applyInstancesUpdate(
  settings: SettingsFace,
  namespace: string,
  payload: unknown,
): Promise<InstancesView> {
  if (typeof payload !== 'object' || payload === null || Array.isArray(payload)) {
    throw new TypeError('instances.update payload must be a plain object')
  }
  const body = payload as Record<string, unknown>
  const section = body.section
  if (typeof section !== 'object' || section === null || Array.isArray(section)) {
    throw new TypeError('instances.update requires a section object')
  }
  const candidate = section as Record<string, unknown>
  if (!Array.isArray(candidate.instances)) {
    throw new TypeError('instances.update section requires an instances array')
  }
  validateInstanceSettings(candidate as unknown as NebulaInstanceSettings)
  const expectedRevision = typeof body.revision === 'number' ? body.revision : undefined
  await settings.update(
    namespace,
    section as object,
    expectedRevision,
  )
  return readInstancesView(settings, namespace)
}

// ── HTTP plumbing ───────────────────────────────────────────────────────────

function writeJson(res: ServerResponse, status: number, body: unknown): void {
  if (res.writableEnded) return
  res.writeHead(status, { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' })
  res.end(JSON.stringify(body))
}

function ok(value: unknown): unknown {
  return { ok: true, value }
}

function fail(code: string, message: string): { ok: false; error: { code: string; message: string } } {
  return { ok: false, error: { code, message } }
}

function readBody(req: IncomingMessage): Promise<unknown> {
  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = []
    req.on('data', (chunk: Buffer) => { chunks.push(chunk) })
    req.on('end', () => {
      const raw = Buffer.concat(chunks).toString('utf8')
      if (raw.trim() === '') { resolve({}); return }
      try {
        resolve(JSON.parse(raw) as unknown)
      } catch {
        reject(new TypeError('request body must be JSON'))
      }
    })
    req.on('error', reject)
  })
}

/** The route method from a request pathname (`/dsh-nebula/api/instances.get`). */
export function methodOf(pathname: string, prefix = NEBULA_API_PREFIX): string | undefined {
  const rest = pathname.startsWith(`${prefix}/`) ? pathname.slice(prefix.length + 1) : undefined
  if (rest === undefined || rest.length === 0 || rest.includes('/')) return undefined
  return rest
}

/**
 * Build the request handler for the plugin route.
 *
 * @param settings - the settings provider.
 * @param trustedHosts - deployment-trusted authorities beyond loopback.
 * @param namespace - profile entry id holding the section, or undefined when
 *   the plugin was composed without the Loader (every method then reports
 *   `settings-unavailable` instead of writing to a guessed entry).
 */
export function createInstancesApiHandler(
  settings: SettingsFace,
  trustedHosts: readonly string[],
  namespace: string | undefined,
): (req: IncomingMessage, res: ServerResponse) => Promise<void> {
  return async (req, res) => {
    if (!isTrustedApiRequest(req, trustedHosts)) {
      writeJson(res, 403, fail('forbidden', 'request is not trusted (loopback or trusted authority, same-origin)'))
      return
    }
    if (req.method !== 'POST') {
      writeJson(res, 405, fail('method-not-allowed', `method ${req.method ?? ''} not allowed; use POST`))
      return
    }
    let method: string | undefined
    try {
      const url = new URL(req.url ?? '/', 'http://localhost')
      method = methodOf(url.pathname)
    } catch {
      writeJson(res, 400, fail('bad-request', 'unparsable request path'))
      return
    }
    if (method === undefined) {
      writeJson(res, 404, fail('not-found', 'unknown dsh-nebula api method'))
      return
    }
    if (namespace === undefined) {
      writeJson(res, 503, fail(
        'settings-unavailable',
        'dsh-nebula has no profile entry id: Settings → NebulaGraph requires the plugin to be mounted by the DSH profile loader',
      ))
      return
    }
    let payload: unknown
    try {
      payload = await readBody(req)
    } catch (error) {
      writeJson(res, 400, fail('bad-request', error instanceof Error ? error.message : 'invalid body'))
      return
    }
    try {
      switch (method) {
        case 'instances.get':
          writeJson(res, 200, ok(readInstancesView(settings, namespace)))
          return
        case 'instances.update':
          writeJson(res, 200, ok(await applyInstancesUpdate(settings, namespace, payload)))
          return
        default:
          writeJson(res, 404, fail('not-found', `unknown dsh-nebula api method "${method}"`))
      }
    } catch (error) {
      // A conflict is its own outcome: the client must re-read and re-apply.
      const message = error instanceof Error ? error.message : String(error)
      const conflict = /changed since it was read/.test(message)
      writeJson(res, conflict ? 409 : 400, fail(conflict ? 'conflict' : 'rejected', message))
    }
  }
}

/** Register the route on the webServer (disposed with the caller's fiber). */
export function registerInstancesApi(
  ctx: Context,
  settings: SettingsFace,
  webServer: WebServerFace,
  loader: LoaderFace,
  namespace: string | undefined,
): () => void {
  const trustedHosts = trustedHostsOf(loader)
  return webServer.register({
    kind: 'prefix',
    path: NEBULA_API_PREFIX,
    handler: createInstancesApiHandler(settings, trustedHosts, namespace),
  })
}
