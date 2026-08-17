/**
 * Client-side mirror of the host's instance-profile vocabulary.
 *
 * The Web Client cannot import host code (bundle purity); the wire carries
 * plain JSON sections, so this module re-declares the shapes, a defensive
 * normalizer for malformed stored sections, and the draft validation the
 * settings form uses. Keep it in sync with `src/instances.ts` (the host is
 * the authority — the settings provider validates writes against its schema).
 */

/** Alias grammar shared with the host (`src/instances.ts`). */
export const INSTANCE_ALIAS_PATTERN = /^[A-Za-z0-9_-]{1,64}$/

/** Credential-reference grammar (same rule as the DSH credentials seam). */
export const CREDENTIAL_REF_PATTERN = /^[A-Za-z_][A-Za-z0-9_]*$/

/** One named connection preset (wire shape; mirrors the host type). */
export interface NebulaInstance {
  alias: string
  host: string
  port?: number
  user?: string
  passwordRef?: string
  tls?: 'off' | 'on' | 'auto'
  ca?: string
  cert?: string
  key?: string
  servername?: string
  timeoutMs?: number
  note?: string
}

/** The `dsh-nebula` settings section (wire shape; mirrors the host type). */
export interface NebulaInstanceSettings {
  instances: NebulaInstance[]
  defaultInstance?: string
  /** Extra credential references (refs not named by any instance). */
  credentialRefs?: string[]
}

/** The section when the namespace carries nothing usable. */
export const EMPTY_SETTINGS: NebulaInstanceSettings = { instances: [] }

function isInstance(value: unknown): value is NebulaInstance {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) return false
  const record = value as Record<string, unknown>
  return typeof record.alias === 'string' && typeof record.host === 'string'
}

/** Normalize one wire section defensively; never throws. */
export function normalizeSettings(value: unknown): NebulaInstanceSettings {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) return EMPTY_SETTINGS
  const raw = value as Record<string, unknown>
  const instances = Array.isArray(raw.instances) ? raw.instances.filter(isInstance) : []
  const defaultInstance = typeof raw.defaultInstance === 'string' && raw.defaultInstance.trim() !== ''
    ? raw.defaultInstance
    : undefined
  const credentialRefs = Array.isArray(raw.credentialRefs)
    ? raw.credentialRefs.filter((ref): ref is string => typeof ref === 'string' && ref.trim() !== '')
    : []
  return {
    instances,
    ...(defaultInstance === undefined ? {} : { defaultInstance }),
    ...(credentialRefs.length === 0 ? {} : { credentialRefs }),
  }
}

/** A user-editable instance draft (empty fields = unset). */
export interface InstanceDraft {
  alias: string
  host: string
  port: string
  user: string
  passwordRef: string
  tls: 'off' | 'on' | 'auto'
  ca: string
  cert: string
  key: string
  servername: string
  timeoutMs: string
  note: string
}

/** Seed a fresh draft from an existing instance (for editing), or blank. */
export function draftFrom(instance: NebulaInstance | undefined): InstanceDraft {
  return {
    alias: instance?.alias ?? '',
    host: instance?.host ?? '',
    port: instance?.port === undefined ? '' : String(instance.port),
    user: instance?.user ?? '',
    passwordRef: instance?.passwordRef ?? '',
    tls: instance?.tls ?? 'auto',
    ca: instance?.ca ?? '',
    cert: instance?.cert ?? '',
    key: instance?.key ?? '',
    servername: instance?.servername ?? '',
    timeoutMs: instance?.timeoutMs === undefined ? '' : String(instance.timeoutMs),
    note: instance?.note ?? '',
  }
}

/** Outcome of validating one draft; failures carry a locale key to translate. */
export type DraftValidation = { ok: true; instance: NebulaInstance } | { ok: false; code: string }

/** Validate a draft and project it to a wire instance; returns the problem otherwise. */
export function validateDraft(draft: InstanceDraft): DraftValidation {
  const alias = draft.alias.trim()
  if (alias.length === 0) return { ok: false, code: 'aliasEmpty' }
  if (!INSTANCE_ALIAS_PATTERN.test(alias)) {
    return { ok: false, code: 'aliasPattern' }
  }
  const host = draft.host.trim()
  if (host.length === 0) return { ok: false, code: 'hostEmpty' }
  const port = parsePort(draft.port)
  if (port !== undefined && port === null) return { ok: false, code: 'portInvalid' }
  const timeoutMs = parsePositiveInt(draft.timeoutMs)
  if (timeoutMs !== undefined && timeoutMs === null) return { ok: false, code: 'timeoutInvalid' }
  const instance: NebulaInstance = {
    alias,
    host,
    ...(port === undefined ? {} : { port }),
    ...(draft.user.trim() === '' ? {} : { user: draft.user.trim() }),
    ...(draft.passwordRef.trim() === '' ? {} : { passwordRef: draft.passwordRef.trim() }),
    tls: draft.tls,
    ...(draft.ca.trim() === '' ? {} : { ca: draft.ca }),
    ...(draft.cert.trim() === '' ? {} : { cert: draft.cert }),
    ...(draft.key.trim() === '' ? {} : { key: draft.key }),
    ...(draft.servername.trim() === '' ? {} : { servername: draft.servername.trim() }),
    ...(timeoutMs === undefined ? {} : { timeoutMs }),
    ...(draft.note.trim() === '' ? {} : { note: draft.note.trim() }),
  }
  return { ok: true, instance }
}

/** Parse a port draft: undefined (blank), null (invalid), or the number. */
function parsePort(text: string): number | null | undefined {
  if (text.trim() === '') return undefined
  const value = Number(text)
  return Number.isInteger(value) && value >= 1 && value <= 65535 ? value : null
}

/** Parse a positive-int draft: undefined (blank), null (invalid), or the number. */
function parsePositiveInt(text: string): number | null | undefined {
  if (text.trim() === '') return undefined
  const value = Number(text)
  return Number.isInteger(value) && value >= 1 ? value : null
}

/** TLS mode labels shown in the form and badges. */
export const TLS_LABELS: Record<'off' | 'on' | 'auto', string> = {
  auto: 'auto',
  on: 'on (TLS)',
  off: 'off (明文)',
}
