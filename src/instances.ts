/**
 * NebulaGraph instance profiles — user-managed connection presets.
 *
 * The plugin registers a `dsh-nebula` settings namespace holding a list of
 * named instances. Each instance carries its own connection parameters
 * (host, port, user, passwordRef, TLS policy, timeouts), addressed by a
 * short `alias` the model can type directly ("connect to the `prod` Nebula").
 *
 * This module owns the shared vocabulary: the namespace id, the instance
 * record type, the schemastery schema the settings provider validates writes
 * against, the cross-field validation, and the pure alias-lookup helpers used
 * by the tools and the settings Web API. The Web Client mirrors the JSON
 * shapes in `client/nebula-instances.ts` (bundle purity — it never imports
 * host code).
 */

import z from 'schemastery'
import type { TlsMode } from './nebula-client.ts'

/**
 * Settings namespace of the named instance profiles. Registered only when a
 * settings provider is composed; the Web Client reads and writes it through
 * the plugin-owned `/dsh-nebula/api` route (the harness's own settings RPC
 * serves only namespaces on its explicit exposure allowlist).
 *
 * dsh-settings ≥ 0.1.2-alpha.2 dropped the `settingsNamespace()` branding
 * helper: namespaces are now plain lowercase-kebab strings validated by the
 * provider (`SettingsProvider.installSection`).
 */
export const NEBULA_SETTINGS_NAMESPACE = 'dsh-nebula'

/**
 * Alias grammar: a short POSIX-ish identifier the model types in prompts and
 * tool arguments. Letters, digits, `-`, `_`; 1–64 chars.
 */
export const INSTANCE_ALIAS_PATTERN = /^[A-Za-z0-9_-]{1,64}$/

/**
 * Credential-reference grammar (same rule as the DSH credentials seam): a
 * POSIX shell identifier. The settings page manages the VALUES behind these
 * references through the harness credentials RPC.
 */
export const CREDENTIAL_REF_PATTERN = /^[A-Za-z_][A-Za-z0-9_]*$/

/**
 * One named connection preset. All fields are optional except `alias` and
 * `host`; absent fields fall back to plugin config defaults at connect time.
 */
export interface NebulaInstance {
  /** Short name the model references the instance by (unique). */
  alias: string
  /** Graphd host. */
  host: string
  /** Graphd gRPC port (default 9669). */
  port?: number
  /** Login user name (default root). */
  user?: string
  /**
   * Credential reference (environment variable name) resolving to this
   * instance's password via the DSH credentials seam. The value itself never
   * appears in the settings document, tool arguments, or logs.
   */
  passwordRef?: string
  /** TLS mode for this instance: `auto` (default), `on`, or `off`. */
  tls?: TlsMode
  /** CA bundle (PEM) for verifying the server certificate. */
  ca?: string
  /** Client certificate (PEM) for mutual TLS. */
  cert?: string
  /** Client private key (PEM) for mutual TLS. */
  key?: string
  /** Server name override for SNI and certificate verification. */
  servername?: string
  /** Per-request deadline in milliseconds (default 30000). */
  timeoutMs?: number
  /** Free-form note shown in the settings page (never read by the tools). */
  note?: string
}

/** The `dsh-nebula` settings namespace section: instances + default pick. */
export interface NebulaInstanceSettings {
  /** All named instances, in display order. */
  instances: NebulaInstance[]
  /**
   * Alias of the instance used when `nebula_connect` is called without an
   * explicit `instance` argument. A stale reference to a deleted instance
   * degrades to plugin-config defaults (see {@link resolveInstanceSource}).
   */
  defaultInstance?: string
  /**
   * Extra credential references managed from the settings page that no
   * instance names — e.g. the plugin-config default's `passwordRef`. The
   * references are stored here so the page can offer set/clear controls for
   * them; the VALUES live in the DSH credentials document and never in this
   * section.
   */
  credentialRefs?: string[]
}

/** Schemastery schema of one instance record (validates stored sections). */
export const NebulaInstanceSchema: z<NebulaInstance> = z.object({
  alias: z.string().required().pattern(INSTANCE_ALIAS_PATTERN),
  host: z.string().required(),
  port: z.number().min(1).max(65535),
  user: z.string(),
  passwordRef: z.string(),
  tls: z.union(['off', 'on', 'auto'] as const),
  ca: z.string(),
  cert: z.string(),
  key: z.string(),
  servername: z.string(),
  timeoutMs: z.number().min(1),
  note: z.string(),
})

/** Schemastery schema of the whole `dsh-nebula` namespace section. */
export const NebulaInstanceSettingsSchema: z<NebulaInstanceSettings> = z.object({
  instances: z.array(NebulaInstanceSchema).default([]),
  defaultInstance: z.string(),
  credentialRefs: z.array(z.string().pattern(CREDENTIAL_REF_PATTERN)).default([]),
})

/**
 * Cross-field validation run by the settings provider on every stored
 * section (and at registration). Only per-instance facts are checked — a
 * stale `defaultInstance` is tolerated deliberately so a settings UI can
 * delete an instance and clear the default in separate writes.
 *
 * @param value - schema-valid section.
 */
export function validateInstanceSettings(value: NebulaInstanceSettings): void {
  const seen = new Set<string>()
  for (const instance of value.instances) {
    if (instance.alias.trim().length === 0) {
      throw new Error('NebulaGraph instance alias must not be empty')
    }
    if (seen.has(instance.alias)) {
      throw new Error(`duplicate NebulaGraph instance alias "${instance.alias}"`)
    }
    seen.add(instance.alias)
    if (instance.host.trim().length === 0) {
      throw new Error(`NebulaGraph instance "${instance.alias}" has an empty host`)
    }
  }
}

/** Look up one instance by exact alias match. */
export function findInstance(
  settings: NebulaInstanceSettings,
  alias: string,
): NebulaInstance | undefined {
  return settings.instances.find((instance) => instance.alias === alias)
}

/** Every configured alias, in display order. */
export function listAliases(settings: NebulaInstanceSettings): string[] {
  return settings.instances.map((instance) => instance.alias)
}

/** The alias of the configured default instance, when one is set. */
export function defaultAliasOf(settings: NebulaInstanceSettings): string | undefined {
  const alias = settings.defaultInstance
  return alias !== undefined && alias.trim().length > 0 ? alias : undefined
}

/**
 * Which instance profile a connect call resolves to, given the tool's
 * explicit `instance` argument and the settings section.
 *
 * Resolution order:
 * 1. explicit `instance` alias — unknown aliases are a hard error listing
 *    the configured aliases;
 * 2. the section's `defaultInstance` — a stale default that no longer
 *    exists degrades to plugin-config defaults with a warning;
 * 3. plugin-config defaults (no profile).
 *
 * @param argsInstance - the tool's `instance` argument (trimmed), or undefined.
 * @param settings - the current namespace section (config defaults when the
 *   settings service is absent).
 * @returns the resolved profile and provenance facts.
 */
export function resolveInstanceSource(
  argsInstance: string | undefined,
  settings: NebulaInstanceSettings,
): { instance?: NebulaInstance; viaDefault?: boolean; warning?: string } {
  if (argsInstance !== undefined && argsInstance.length > 0) {
    const instance = findInstance(settings, argsInstance)
    if (instance === undefined) {
      const aliases = listAliases(settings)
      const hint = aliases.length > 0
        ? `; configured aliases: ${aliases.join(', ')}`
        : ' (no instances configured — add one in Settings → NebulaGraph, or pass host/port directly)'
      throw new Error(`unknown NebulaGraph instance alias "${argsInstance}"${hint}`)
    }
    return { instance }
  }
  const defaultAlias = defaultAliasOf(settings)
  if (defaultAlias !== undefined) {
    const instance = findInstance(settings, defaultAlias)
    if (instance !== undefined) return { instance, viaDefault: true }
    return {
      warning: `the configured default instance "${defaultAlias}" is not in the instance list; `
        + 'connected with plugin-config defaults (check Settings → NebulaGraph)',
    }
  }
  return {}
}
