/**
 * Unit tests for the instance-profile vocabulary (src/instances.ts):
 * schema validation, cross-field validation, and alias resolution.
 */

import assert from 'node:assert/strict'
import { describe, it } from 'node:test'
import {
  NebulaInstanceSettingsSchema,
  findInstance,
  listAliases,
  resolveInstanceSource,
  validateInstanceSettings,
} from '../src/instances.ts'

describe('NebulaInstanceSettingsSchema', () => {
  it('resolves defaults for an absent section', () => {
    const value = NebulaInstanceSettingsSchema({} as never)
    assert.deepEqual(value.instances, [])
    assert.equal(value.defaultInstance, undefined)
  })

  it('rejects a section with an invalid alias charset', () => {
    assert.throws(
      () => NebulaInstanceSettingsSchema({ instances: [{ alias: 'bad alias!', host: 'h' }] } as never),
      /alias/,
    )
  })

  it('rejects a section with a missing host', () => {
    assert.throws(
      () => NebulaInstanceSettingsSchema({ instances: [{ alias: 'dev' }] } as never),
      /host/,
    )
  })

  it('accepts a well-formed instance list and keeps optional fields', () => {
    const value = NebulaInstanceSettingsSchema({
      instances: [{
        alias: 'prod',
        host: '10.0.0.1',
        port: 9669,
        user: 'root',
        passwordRef: 'PROD_PW',
        tls: 'on',
        timeoutMs: 15000,
        note: 'production',
      }],
      defaultInstance: 'prod',
    } as never)
    assert.equal(value.instances.length, 1)
    assert.equal(value.instances[0].alias, 'prod')
    assert.equal(value.instances[0].port, 9669)
    assert.equal(value.instances[0].tls, 'on')
    assert.equal(value.defaultInstance, 'prod')
  })

  it('resolves credentialRefs with a default of an empty list', () => {
    const value = NebulaInstanceSettingsSchema({} as never)
    assert.deepEqual(value.credentialRefs, [])
    const withRefs = NebulaInstanceSettingsSchema({ credentialRefs: ['NEBULA_PASSWORD', 'UAT_PW'] } as never)
    assert.deepEqual(withRefs.credentialRefs, ['NEBULA_PASSWORD', 'UAT_PW'])
  })

  it('rejects an ill-formed credentialRefs entry', () => {
    assert.throws(
      () => NebulaInstanceSettingsSchema({ credentialRefs: ['bad ref!'] } as never),
      /credentialRefs/,
    )
  })
})

describe('validateInstanceSettings', () => {
  it('rejects duplicate aliases', () => {
    assert.throws(
      () => validateInstanceSettings({
        instances: [{ alias: 'dev', host: 'a' }, { alias: 'dev', host: 'b' }],
      }),
      /duplicate NebulaGraph instance alias "dev"/,
    )
  })

  it('rejects an empty host', () => {
    assert.throws(
      () => validateInstanceSettings({ instances: [{ alias: 'dev', host: '  ' }] }),
      /empty host/,
    )
  })

  it('accepts unique well-formed instances', () => {
    validateInstanceSettings({
      instances: [{ alias: 'dev', host: 'a' }, { alias: 'prod', host: 'b' }],
    })
  })
})

describe('resolveInstanceSource', () => {
  const settings = {
    instances: [
      { alias: 'dev', host: '127.0.0.1' },
      { alias: 'prod', host: '10.0.0.1' },
    ],
    defaultInstance: 'dev',
  }

  it('resolves an explicit alias', () => {
    const source = resolveInstanceSource('prod', settings)
    assert.equal(source.instance?.alias, 'prod')
    assert.equal(source.viaDefault, undefined)
    assert.equal(source.warning, undefined)
  })

  it('throws on an unknown alias and lists the configured aliases', () => {
    assert.throws(
      () => resolveInstanceSource('staging', settings),
      /unknown NebulaGraph instance alias "staging"; configured aliases: dev, prod/,
    )
  })

  it('throws with a hint when no instances are configured', () => {
    assert.throws(
      () => resolveInstanceSource('x', { instances: [] }),
      /no instances configured/,
    )
  })

  it('falls back to the default instance when no alias is given', () => {
    const source = resolveInstanceSource(undefined, settings)
    assert.equal(source.instance?.alias, 'dev')
    assert.equal(source.viaDefault, true)
  })

  it('warns (instead of failing) when the default instance is stale', () => {
    const source = resolveInstanceSource(undefined, { instances: [], defaultInstance: 'gone' })
    assert.equal(source.instance, undefined)
    assert.match(source.warning ?? '', /default instance "gone" is not in the instance list/)
  })

  it('returns no profile when nothing is configured', () => {
    const source = resolveInstanceSource(undefined, { instances: [] })
    assert.equal(source.instance, undefined)
    assert.equal(source.viaDefault, undefined)
    assert.equal(source.warning, undefined)
  })
})

describe('lookup helpers', () => {
  const settings = {
    instances: [{ alias: 'dev', host: 'a' }, { alias: 'prod', host: 'b' }],
  }

  it('findInstance matches by exact alias', () => {
    assert.equal(findInstance(settings, 'dev')?.host, 'a')
    assert.equal(findInstance(settings, 'DEV'), undefined)
  })

  it('listAliases returns aliases in display order', () => {
    assert.deepEqual(listAliases(settings), ['dev', 'prod'])
  })
})
