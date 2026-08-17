/**
 * Unit tests for the plugin-owned instances Web API (src/instances-api.ts):
 * the browser-trust fence, the method dispatcher, the namespace view/write
 * logic, and the full HTTP handler against fake req/res objects.
 */

import assert from 'node:assert/strict'
import { describe, it } from 'node:test'
import type { IncomingMessage, ServerResponse } from 'node:http'
import { NEBULA_SETTINGS_NAMESPACE } from '../src/index.ts'
import {
  applyInstancesUpdate,
  createInstancesApiHandler,
  isLoopbackHostname,
  isTrustedApiRequest,
  methodOf,
  readInstancesView,
  trustedHostsOf,
} from '../src/index.ts'
import type { SettingsFace } from '../src/index.ts'

/** In-memory settings provider stub matching the structural SettingsFace. */
class FakeSettings implements SettingsFace {
  readonly writable = true
  private doc: Record<string, unknown> = {}
  private revision = 1

  get(ns: string): unknown {
    return this.doc[ns]
  }

  describe(): Array<{ ns: string; value: unknown; revision: number }> {
    return [{
      ns: String(NEBULA_SETTINGS_NAMESPACE),
      value: structuredClone(this.doc[String(NEBULA_SETTINGS_NAMESPACE)] ?? { instances: [] }),
      revision: this.revision,
    }]
  }

  async update(ns: string, patch: object, expectedRevision?: number): Promise<void> {
    if (expectedRevision !== undefined && expectedRevision !== this.revision) {
      throw new Error(`settings namespace "${ns}" changed since it was read (expected revision ${String(expectedRevision)}, now ${String(this.revision)})`)
    }
    const current = (this.doc[ns] ?? {}) as Record<string, unknown>
    this.doc[ns] = { ...current, ...patch }
    this.revision += 1
  }
}

function headersOf(headers: Record<string, string>): IncomingMessage['headers'] {
  return headers as IncomingMessage['headers']
}

describe('isLoopbackHostname', () => {
  it('accepts localhost, [::1], and 127.x.y.z', () => {
    assert.equal(isLoopbackHostname('localhost'), true)
    assert.equal(isLoopbackHostname('[::1]'), true)
    assert.equal(isLoopbackHostname('127.0.0.1'), true)
    assert.equal(isLoopbackHostname('127.255.1.9'), true)
  })
  it('rejects other hosts', () => {
    assert.equal(isLoopbackHostname('192.168.8.187'), false)
    assert.equal(isLoopbackHostname('example.com'), false)
    assert.equal(isLoopbackHostname('128.0.0.1'), false)
  })
})

describe('isTrustedApiRequest', () => {
  it('allows loopback Host with a same-origin browser request', () => {
    const request = {
      headers: headersOf({
        host: '127.0.0.1:3080',
        'sec-fetch-site': 'same-origin',
        origin: 'http://127.0.0.1:3080',
      }),
    }
    assert.equal(isTrustedApiRequest(request, []), true)
  })
  it('allows a trusted non-loopback authority', () => {
    const request = {
      headers: headersOf({
        host: '192.168.8.7:3080',
        'sec-fetch-site': 'same-origin',
        origin: 'http://192.168.8.7:3080',
      }),
    }
    assert.equal(isTrustedApiRequest(request, ['192.168.8.7']), true)
  })
  it('rejects an untrusted non-loopback authority', () => {
    const request = {
      headers: headersOf({ host: 'evil.example.com', origin: 'http://evil.example.com' }),
    }
    assert.equal(isTrustedApiRequest(request, []), false)
  })
  it('rejects cross-site fetches', () => {
    const request = {
      headers: headersOf({ host: '127.0.0.1:3080', 'sec-fetch-site': 'cross-site' }),
    }
    assert.equal(isTrustedApiRequest(request, []), false)
  })
  it('rejects a mismatched Origin', () => {
    const request = {
      headers: headersOf({ host: '127.0.0.1:3080', origin: 'http://evil.example.com' }),
    }
    assert.equal(isTrustedApiRequest(request, []), false)
  })
  it('allows an absent Origin (non-browser or curl)', () => {
    const request = { headers: headersOf({ host: '127.0.0.1:3080' }) }
    assert.equal(isTrustedApiRequest(request, []), true)
  })
  it('rejects a missing Host header', () => {
    assert.equal(isTrustedApiRequest({ headers: {} }, []), false)
  })
})

describe('trustedHostsOf', () => {
  it('reads the connection row trustedHosts', () => {
    const loader = {
      entries: () => [
        { options: { name: 'connection', config: { trustedHosts: ['10.0.0.1', '10.0.0.2'] } } },
        { options: { name: 'other', config: {} } },
      ],
    }
    assert.deepEqual(trustedHostsOf(loader), ['10.0.0.1', '10.0.0.2'])
  })
  it('returns [] without a connection row', () => {
    assert.deepEqual(trustedHostsOf({ entries: () => [] }), [])
  })
})

describe('methodOf', () => {
  it('parses the method from the route path', () => {
    assert.equal(methodOf('/dsh-nebula/api/instances.get'), 'instances.get')
    assert.equal(methodOf('/dsh-nebula/api/instances.update'), 'instances.update')
  })
  it('rejects unknown shapes', () => {
    assert.equal(methodOf('/dsh-nebula/api/'), undefined)
    assert.equal(methodOf('/dsh-nebula/api/a/b'), undefined)
    assert.equal(methodOf('/other/path'), undefined)
  })
})

describe('readInstancesView', () => {
  it('returns the resolved section with revision and writable', () => {
    const settings = new FakeSettings()
    const view = readInstancesView(settings)
    assert.deepEqual(view.value, { instances: [] })
    assert.equal(view.revision, 1)
    assert.equal(view.writable, true)
  })
})

describe('applyInstancesUpdate', () => {
  it('writes the section and returns the fresh view', async () => {
    const settings = new FakeSettings()
    const view = await applyInstancesUpdate(settings, {
      section: { instances: [{ alias: 'dev', host: '10.0.0.1' }], defaultInstance: 'dev' },
    })
    assert.equal(view.value.instances.length, 1)
    assert.equal(view.value.instances[0].alias, 'dev')
    assert.equal(view.value.defaultInstance, 'dev')
    assert.equal(view.revision, 2)
  })
  it('rejects a non-object payload or section', async () => {
    const settings = new FakeSettings()
    await assert.rejects(() => applyInstancesUpdate(settings, null), /payload must be a plain object/)
    await assert.rejects(() => applyInstancesUpdate(settings, { section: 'nope' }), /section object/)
  })
})

/** A minimal fake ServerResponse capturing the status and JSON body. */
function captureResponse(): { res: ServerResponse; status: number[]; body: string[] } {
  const status: number[] = []
  const body: string[] = []
  const res = {
    writableEnded: false,
    writeHead(code: number): unknown { status.push(code); return undefined },
    end(payload?: string): unknown { body.push(payload ?? ''); return undefined },
  } as unknown as ServerResponse
  return { res, status, body }
}

function fakeRequest(parts: {
  method?: string
  url?: string
  headers?: Record<string, string>
  rawBody?: string
}): IncomingMessage {
  const req = {
    method: parts.method ?? 'POST',
    url: parts.url ?? '/dsh-nebula/api/instances.get',
    headers: headersOf(parts.headers ?? {}),
    on: (event: string, cb: (chunk?: Buffer) => void): unknown => {
      if (event === 'data' && parts.rawBody !== undefined) {
        cb(Buffer.from(parts.rawBody))
      }
      if (event === 'end') { cb() }
      return undefined
    },
  } as unknown as IncomingMessage
  return req
}

describe('createInstancesApiHandler', () => {
  it('serves instances.get with a view', async () => {
    const settings = new FakeSettings()
    const handler = createInstancesApiHandler(settings, [])
    const { res, status, body } = captureResponse()
    await handler(fakeRequest({ headers: { host: '127.0.0.1:3080' } }), res)
    assert.deepEqual(status, [200])
    const parsed = JSON.parse(body[0] ?? '') as { ok: boolean; value: { value: unknown; revision: number } }
    assert.equal(parsed.ok, true)
    assert.deepEqual(parsed.value.value, { instances: [] })
    assert.equal(parsed.value.revision, 1)
  })

  it('serves instances.update and reflects the write', async () => {
    const settings = new FakeSettings()
    const handler = createInstancesApiHandler(settings, [])
    const { res, status, body } = captureResponse()
    await handler(fakeRequest({
      url: '/dsh-nebula/api/instances.update',
      headers: { host: '127.0.0.1:3080' },
      rawBody: JSON.stringify({ section: { instances: [{ alias: 'prod', host: '10.0.0.1' }], defaultInstance: '' }, revision: 1 }),
    }), res)
    assert.deepEqual(status, [200])
    const parsed = JSON.parse(body[0] ?? '') as { ok: boolean; value: { value: { instances: { alias: string }[] } } }
    assert.equal(parsed.ok, true)
    assert.equal(parsed.value.value.instances[0].alias, 'prod')
    // The settings provider actually persisted the section.
    assert.equal((settings.get(String(NEBULA_SETTINGS_NAMESPACE)) as { instances: unknown[] }).instances.length, 1)
  })

  it('answers 403 to an untrusted request', async () => {
    const settings = new FakeSettings()
    const handler = createInstancesApiHandler(settings, [])
    const { res, status, body } = captureResponse()
    await handler(fakeRequest({ headers: { host: 'evil.example.com' } }), res)
    assert.deepEqual(status, [403])
    assert.equal(JSON.parse(body[0] ?? '').ok, false)
  })

  it('answers 405 to a non-POST method', async () => {
    const settings = new FakeSettings()
    const handler = createInstancesApiHandler(settings, [])
    const { res, status } = captureResponse()
    await handler(fakeRequest({ method: 'GET', headers: { host: '127.0.0.1:3080' } }), res)
    assert.deepEqual(status, [405])
  })

  it('answers 404 to an unknown method', async () => {
    const settings = new FakeSettings()
    const handler = createInstancesApiHandler(settings, [])
    const { res, status } = captureResponse()
    await handler(fakeRequest({ url: '/dsh-nebula/api/instances.hack', headers: { host: '127.0.0.1:3080' } }), res)
    assert.deepEqual(status, [404])
  })

  it('answers 400 to a malformed body', async () => {
    const settings = new FakeSettings()
    const handler = createInstancesApiHandler(settings, [])
    const { res, status } = captureResponse()
    await handler(fakeRequest({
      url: '/dsh-nebula/api/instances.update',
      headers: { host: '127.0.0.1:3080' },
      rawBody: 'not json',
    }), res)
    assert.deepEqual(status, [400])
  })

  it('answers 409 when the write raced a stale revision', async () => {
    const settings = new FakeSettings()
    // Bump the revision so the client's held revision is stale.
    await settings.update(String(NEBULA_SETTINGS_NAMESPACE), { instances: [] })
    const handler = createInstancesApiHandler(settings, [])
    const { res, status, body } = captureResponse()
    await handler(fakeRequest({
      url: '/dsh-nebula/api/instances.update',
      headers: { host: '127.0.0.1:3080' },
      rawBody: JSON.stringify({ section: { instances: [], defaultInstance: '' }, revision: 1 }),
    }), res)
    assert.deepEqual(status, [409])
    assert.equal(JSON.parse(body[0] ?? '').error.code, 'conflict')
  })
})
