/**
 * Packaged `gql-query-generator` skill provider.
 *
 * Serves the bundled NebulaGraph GQL query-generation skill from the plugin's
 * `gql-query-generator/` directory through `ctx.skills`, so the agent's `skill`
 * tool can load it and its `references/*.md` resolve against the packaged
 * directory. Mirrors `dsh-skill-badge`'s provider shape: one static candidate
 * in `list()`, and `get()` reads the current SKILL.md body on demand (edits
 * take effect without a rebuild for link-installed plugins).
 */

import { readFile } from 'node:fs/promises'
import { fileURLToPath } from 'node:url'
import type { Context } from '@deepseek-ai/cordis'
import {
  BUNDLED_SKILL_RANK,
  type SkillCandidate,
  type SkillDefinition,
  type SkillProvider,
} from '@deepseek-ai/dsh-skill'

/** Provider name, unique in the skills registry layer. */
export const PROVIDER_NAME = 'dsh-nebula'

/** Packaged skill directory (sibling of lib/). */
export const SKILL_DIR = fileURLToPath(new URL('../gql-query-generator/', import.meta.url))

/** Absolute path of the skill body inside the packaged directory. */
export const SKILL_BODY_PATH = fileURLToPath(new URL('../gql-query-generator/SKILL.md', import.meta.url))

const INVOCATION = { modelInvocable: true, userInvocable: true } as const
const SOURCE = 'bundled' as const

const RESOURCE_BASE = {
  kind: 'directory',
  path: SKILL_DIR,
} as const

/** Minimal frontmatter parse: name, description, whenToUse plus the body without the frontmatter block. */
export interface SkillMeta {
  name: string
  description: string
  whenToUse?: string
}

function parseSkillFile(raw: string): { meta: SkillMeta; body: string } | undefined {
  if (!raw.startsWith('---')) return undefined
  const end = raw.indexOf('\n---')
  if (end === -1) return undefined
  const block = raw.slice(4, end)
  const body = raw.slice(end + 4).trim()
  const meta: Partial<SkillMeta> = {}
  for (const line of block.split('\n')) {
    const match = /^([a-zA-Z][\w-]*):\s*(.*)$/.exec(line)
    if (match === null) continue
    const key = match[1]
    const value = match[2].trim()
    if (key === 'name') meta.name = value
    else if (key === 'description') meta.description = value
    else if (key === 'whenToUse') meta.whenToUse = value
  }
  if (meta.name === undefined || meta.description === undefined) return undefined
  return { meta: meta as SkillMeta, body }
}

/** Load the packaged SKILL.md and parse its frontmatter. */
export async function loadPackagedSkill(): Promise<{ meta: SkillMeta; body: string }> {
  const raw = await readFile(SKILL_BODY_PATH, 'utf8')
  const parsed = parseSkillFile(raw)
  if (parsed === undefined) {
    throw new Error(`dsh-nebula: invalid frontmatter in packaged skill ${SKILL_BODY_PATH} (name and description are required)`)
  }
  return parsed
}

/**
 * Build the skill provider bound to the packaged directory.
 *
 * @returns the provider serving `gql-query-generator`.
 */
export function createGqlSkillProvider(): SkillProvider {
  const provider: SkillProvider = {
    name: PROVIDER_NAME,
    async list() {
      const { meta } = await loadPackagedSkill()
      return [makeCandidate(meta)]
    },
    async get(_candidate) {
      const { meta, body } = await loadPackagedSkill()
      return makeDefinition(meta, body)
    },
  }
  return provider
}

function makeCandidate(meta: SkillMeta): SkillCandidate {
  return {
    name: meta.name,
    description: meta.description,
    ...meta.whenToUse !== undefined ? { whenToUse: meta.whenToUse } : {},
    invocation: INVOCATION,
    source: SOURCE,
    provider: PROVIDER_NAME,
    resourceBase: RESOURCE_BASE,
    rank: BUNDLED_SKILL_RANK,
    locator: SKILL_BODY_PATH,
    path: SKILL_BODY_PATH,
  }
}

function makeDefinition(meta: SkillMeta, body: string): SkillDefinition {
  return {
    name: meta.name,
    description: meta.description,
    ...meta.whenToUse !== undefined ? { whenToUse: meta.whenToUse } : {},
    invocation: INVOCATION,
    source: SOURCE,
    provider: PROVIDER_NAME,
    resourceBase: RESOURCE_BASE,
    content: body,
    path: SKILL_BODY_PATH,
  }
}

/** Register the packaged skill provider on `ctx.skills`. */
export function applyGqlSkillProvider(ctx: Context): void {
  ctx.skills.registerProvider(() => createGqlSkillProvider())
}
