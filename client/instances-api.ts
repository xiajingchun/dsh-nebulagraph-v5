/**
 * Client-side wire client for the plugin's `/dsh-nebula/api` route.
 *
 * The host registers the route on its webServer (see src/instances-api.ts);
 * this module is the browser half: JSON POST fetch with the same
 * `{ ok, value }` / `{ ok: false, error }` envelope, typed against the
 * mirrored instance shapes in ./nebula-instances.ts.
 */

import type { NebulaInstanceSettings } from './nebula-instances.ts'

/** The wire view of the namespace: resolved section plus write facts. */
export interface InstancesView {
  value: NebulaInstanceSettings
  /** Revision fencing the next write; undefined before the first read. */
  revision?: number
  /** Whether the settings document accepts writes. */
  writable: boolean
}

/** One wire failure of the instances API. */
export class InstancesApiError extends Error {
  readonly code: string

  constructor(code: string, message: string) {
    super(message)
    this.name = 'InstancesApiError'
    this.code = code
  }
}

/** POST one API method and decode the `{ ok, value }` envelope. */
export async function callInstancesApi<T>(
  method: string,
  payload?: unknown,
  signal?: AbortSignal,
): Promise<T> {
  let response: Response
  try {
    response = await fetch(`/dsh-nebula/api/${method}`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(payload ?? {}),
      signal,
    })
  } catch (error) {
    throw new InstancesApiError('network', error instanceof Error ? error.message : String(error))
  }
  const parsed: unknown = await response.json().catch(() => null)
  if (!response.ok || parsed === null || typeof parsed !== 'object'
    || (parsed as { ok?: unknown }).ok !== true) {
    const error = (parsed as { error?: { code?: string; message?: string } })?.error
    throw new InstancesApiError(error?.code ?? 'http', error?.message ?? `HTTP ${response.status}`)
  }
  return (parsed as { value: T }).value
}

/** The instances API surface. */
export const instancesApi = {
  get: (signal?: AbortSignal): Promise<InstancesView> =>
    callInstancesApi<InstancesView>('instances.get', undefined, signal),
  update: (section: NebulaInstanceSettings, revision?: number): Promise<InstancesView> =>
    callInstancesApi<InstancesView>('instances.update', { section, revision }),
}
