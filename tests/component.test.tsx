/**
 * Component render regression test: mount NebulaInstancesSection in every
 * state with react-test-renderer and flush effects. Guards against
 * render-phase crashes that would blank the Settings → NebulaGraph page
 * (the slot framework retires an entry whose render throws — e.g. the
 * `ref={string}` on a function component that React 18 rejects).
 */

import assert from 'node:assert/strict'
import { describe, it } from 'node:test'
import TestRenderer from 'react-test-renderer'
import { createElement } from 'react'
import { NebulaInstancesSection } from '../client/NebulaInstancesSection.tsx'
import type { InstancesView } from '../client/instances-api.ts'
import type { NebulaInstanceSettings } from '../client/nebula-instances.ts'
import { zh } from '../client/locales.ts'

const t = (key: string, params?: Record<string, unknown>): string => {
  const template = (zh as Record<string, string>)[key] ?? key
  if (params === undefined) return template
  return template.replace(/\{(\w+)\}/g, (match, name: string) =>
    name in params ? String(params[name]) : match)
}

function view(value: NebulaInstanceSettings, revision = 1, writable = true): InstancesView {
  return { value, revision, writable }
}

function baseProps(): Record<string, unknown> {
  return {
    t,
    describeCredentials: async (refs: string[]) =>
      refs.map((ref) => ({ ref, configured: true, writable: true })),
    setCredential: async (): Promise<boolean> => true,
    unsetCredential: async (): Promise<boolean> => true,
    subscribeCredentials: (): (() => void) => () => {},
    subscribe: (): (() => void) => () => {},
    close: (): void => {},
  }
}

/** Mount the section, flush load/effect promises, and assert no throw. */
async function mountsCleanly(props: Record<string, unknown>): Promise<void> {
  let root: TestRenderer.ReactTestRenderer | undefined
  try {
    await TestRenderer.act(async () => {
      root = TestRenderer.create(createElement(NebulaInstancesSection, props as never))
      await new Promise((resolve) => setTimeout(resolve, 20))
    })
  } finally {
    if (root !== undefined) root.unmount()
  }
}

describe('NebulaInstancesSection render', () => {
  it('paints through theme tokens only (no hardcoded hex colors in any style prop)', async () => {
    let root: TestRenderer.ReactTestRenderer | undefined
    try {
      await TestRenderer.act(async () => {
        root = TestRenderer.create(createElement(NebulaInstancesSection, {
          ...baseProps(),
          load: async () => view({
            instances: [{ alias: 'uat', host: '10.0.0.1', port: 9669, user: 'uat_test', passwordRef: 'NEBULA_PASSWORD_UAT', tls: 'auto', note: 'dev' }],
            defaultInstance: 'uat',
            credentialRefs: ['NEBULA_PASSWORD'],
          }),
          update: async (section: NebulaInstanceSettings) => view(section),
        } as never))
        await new Promise((resolve) => setTimeout(resolve, 20))
      })
      // Every color must resolve through a --dsw-alias-* token so the page
      // follows the DSH light/dark Appearance setting; a hardcoded hex here
      // would freeze the section in one palette (regression: was dark-only).
      const HEX = /#[0-9a-fA-F]{3,8}\b/
      const offenders: string[] = []
      let tokenStyles = 0
      const walk = (node: TestRenderer.ReactTestInstance): void => {
        const style = node.props.style
        if (style !== undefined) {
          const text = JSON.stringify(style)
          if (HEX.test(text)) offenders.push(text)
          if (text.includes('--dsw-alias-')) tokenStyles += 1
        }
        for (const child of node.children) {
          if (typeof child === 'object') walk(child)
        }
      }
      if (root !== undefined) walk(root.root)
      assert.deepEqual(offenders, [])
      assert.ok(tokenStyles > 0, 'expected at least one theme-token style')
    } finally {
      if (root !== undefined) root.unmount()
    }
  })

  it('renders a populated instance list (instances + default + credential refs)', async () => {
    await mountsCleanly({
      ...baseProps(),
      load: async () => view({
        instances: [{ alias: 'uat', host: '10.0.0.1', port: 9669, user: 'uat_test', passwordRef: 'NEBULA_PASSWORD_UAT', tls: 'auto', note: 'dev' }],
        defaultInstance: 'uat',
        credentialRefs: ['NEBULA_PASSWORD'],
      }),
      update: async (section: NebulaInstanceSettings) => view(section),
    })
  })

  it('renders the empty state', async () => {
    await mountsCleanly({
      ...baseProps(),
      load: async () => view({ instances: [] }),
      update: async (section: NebulaInstanceSettings) => view(section),
    })
  })

  it('renders the read-only state', async () => {
    await mountsCleanly({
      ...baseProps(),
      load: async () => view({ instances: [] }, 1, false),
      update: async (section: NebulaInstanceSettings) => view(section),
    })
  })

  it('renders the error state without throwing', async () => {
    await mountsCleanly({
      ...baseProps(),
      load: async () => { throw new Error('boom') },
      update: async () => { throw new Error('unused') },
    })
  })

  it('renders the loading state without throwing', async () => {
    await mountsCleanly({
      ...baseProps(),
      load: () => new Promise(() => {}),
      update: async (section: NebulaInstanceSettings) => view(section),
    })
  })
})
