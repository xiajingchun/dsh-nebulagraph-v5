/**
 * Skill provider tests: the packaged `gql-query-generator` skill lists
 * correctly, loads its body, and points at the packaged references directory.
 */

import assert from 'node:assert/strict'
import { existsSync } from 'node:fs'
import { describe, it } from 'node:test'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { createGqlSkillProvider, PROVIDER_NAME, SKILL_DIR, loadPackagedSkill } from '../src/skill.ts'

describe('gql-query-generator skill provider', () => {
  it('parses the packaged SKILL.md frontmatter', async () => {
    const { meta, body } = await loadPackagedSkill()
    assert.equal(meta.name, 'gql-query-generator')
    assert.match(meta.description, /NebulaGraph/)
    assert.ok(body.length > 100, 'skill body should carry the generation rules')
    assert.match(body, /Reference Routing/)
  })

  it('lists the skill candidate with a resolvable resource base', async () => {
    const provider = createGqlSkillProvider()
    assert.equal(provider.name, PROVIDER_NAME)
    const candidates = await provider.list({ cwd: process.cwd(), signal: new AbortController().signal })
    const candidate = (Array.isArray(candidates) ? candidates : [])[0]
    assert.ok(candidate, 'provider should list one candidate')
    assert.equal(candidate.name, 'gql-query-generator')
    assert.equal(candidate.provider, PROVIDER_NAME)
    assert.equal(candidate.rank, 600)
    assert.deepEqual(candidate.resourceBase, { kind: 'directory', path: SKILL_DIR })
    // The packaged references the skill routes to must exist next to it.
    for (const ref of ['query-language.md', 'patterns.md', 'validation.md', 'expressions.md']) {
      assert.ok(existsSync(join(SKILL_DIR, 'references', ref)), `missing packaged reference ${ref}`)
    }
  })

  it('loads the skill definition with the frontmatter stripped', async () => {
    const provider = createGqlSkillProvider()
    const candidates = await provider.list({ cwd: process.cwd(), signal: new AbortController().signal })
    const candidate = (Array.isArray(candidates) ? candidates : [])[0]
    const skill = await provider.get(candidate, { cwd: process.cwd(), signal: new AbortController().signal })
    assert.ok(skill, 'provider.get should return the skill definition')
    assert.equal(skill.name, 'gql-query-generator')
    assert.equal(skill.provider, PROVIDER_NAME)
    assert.ok(!skill.content.startsWith('---'), 'content must not include the frontmatter block')
    assert.match(skill.content, /^# GQL Query Generator/m)
  })

  it('resolves the packaged directory relative to the built lib', () => {
    // The provider lives in lib/skill.js at build time; ../gql-query-generator
    // must land on the package's skill directory, not the source tree.
    const fromLib = join(dirname(fileURLToPath(new URL('../lib/skill.js', import.meta.url))), '..', 'gql-query-generator')
    assert.equal(fromLib, SKILL_DIR.replace(/\/$/, ''))
    assert.ok(existsSync(join(fromLib, 'SKILL.md')))
  })
})
