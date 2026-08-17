/**
 * Connection registry shared by the model-facing tools: keeps authenticated
 * {@link NebulaClient} sessions alive across tool calls so the model can
 * `USE graph` once and keep querying on the same server-side session.
 */

import { randomUUID } from 'node:crypto'
import { NebulaClient } from './nebula-client.ts'
import type { NebulaConnectOptions } from './nebula-client.ts'

/** Lazy catalog cache for resolving element keys of graph results. */
export interface SchemaCache {
  /** graph name → graph type, from `SHOW GRAPHS`. */
  graphTypes: Map<string, string>
  /** `graphType\0nodeType` → primary-key property names, from `DESC GRAPH TYPE`. */
  nodePrimaryKeys: Map<string, string[]>
  /** `graphType\0edgeType` → multiedge-key property names, from `DESC GRAPH TYPE`. */
  edgeMultiedgeKeys: Map<string, string[]>
  /** graphType → in-flight `DESC GRAPH TYPE` fetch (dedupes concurrent lookups). */
  inflight: Map<string, Promise<void>>
}

/** One registered connection. */
export interface ConnectionEntry {
  /** Opaque handle the model passes back to `nebula_execute`. */
  connectionId: string
  /** The authenticated session client. */
  client: NebulaClient
  /** Resolved connection parameters. */
  options: NebulaConnectOptions
  /** When the entry was created. */
  createdAt: number
  /**
   * The session's working graph, tracked from `SESSION SET graph <name>`
   * statements run through `nebula_execute`. Lets `nebula_schema` (and the
   * model's follow-up queries) target the graph the session is already on.
   */
  currentGraph?: string
  /**
   * Catalog cache populated on the first graph-shaped `nebula_execute`
   * result: the v5 columnar result carries no primary-key definition, so
   * `SHOW GRAPHS` + `DESC GRAPH TYPE` are fetched lazily and cached here.
   */
  schemaCache?: SchemaCache
}

/** Tracks live connections; disposing the plugin closes every session. */
export class ConnectionRegistry {
  private readonly entries = new Map<string, ConnectionEntry>()

  /** Register a connected client and return its handle. */
  add(options: NebulaConnectOptions, client: NebulaClient): ConnectionEntry {
    const entry: ConnectionEntry = {
      connectionId: randomUUID(),
      client,
      options,
      createdAt: Date.now(),
    }
    this.entries.set(entry.connectionId, entry)
    return entry
  }

  /** Look up a connection by its opaque id. */
  get(connectionId: string): ConnectionEntry | undefined {
    return this.entries.get(connectionId)
  }

  /** All live connections, newest first. */
  list(): ConnectionEntry[] {
    return [...this.entries.values()].sort((a, b) => b.createdAt - a.createdAt)
  }

  /**
   * Close and forget one connection, signing its session out first.
   *
   * @param connectionId - the connection handle.
   * @returns the closed entry, or undefined when unknown.
   */
  async remove(connectionId: string): Promise<ConnectionEntry | undefined> {
    const entry = this.entries.get(connectionId)
    if (entry === undefined) return undefined
    this.entries.delete(connectionId)
    await entry.client.close()
    return entry
  }

  /** Close every connection (signing each session out); used on plugin dispose. */
  async dispose(): Promise<void> {
    const entries = [...this.entries.values()]
    this.entries.clear()
    await Promise.allSettled(entries.map((entry) => entry.client.close()))
  }
}
