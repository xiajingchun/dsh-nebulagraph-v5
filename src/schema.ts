/**
 * NebulaGraph v5 (ISO GQL) schema introspection: `SHOW GRAPHS` + `DESC GRAPH TYPE`.
 *
 * The v5 catalog is a *graph of graph types*:
 * - `SHOW GRAPHS` lists every graph with its `graph_type` (plus schema kind,
 *   owner and extra flags).
 * - `DESC GRAPH TYPE <graph_type>` returns one row per element type: nodes
 *   (`entity_type = Node`) and edges (`entity_type = Edge`). Each edge row's
 *   `type_pattern` — e.g. `(Actor)-[Act]->(Movie)` — directly encodes the
 *   edge's source and target node types, so a graph type's schema is itself a
 *   small directed graph: node types as vertices, edge types as arcs.
 *
 * Only syntax recorded in the bundled gql-query-generator skill or explicitly
 * provided by the maintainer is used here — no open-source nGQL statements
 * (`SHOW SPACES`, `DESCRIBE TAG`, …) are referenced.
 */

import type { NebulaExecuteResult } from './nebula-client.ts'
import { renderTable } from './format.ts'

/** One row of `SHOW GRAPHS`. */
export interface GraphInfo {
  /** Graph name (the `name` column). */
  name: string
  /** Graph type this graph instantiates (`graph_type` column). */
  graphType: string
  /** Schema kind, e.g. `/default_schema` or `/tmp_schema`. */
  schema: string
  /** Graph owner. */
  owner: string
  /** Extra flags, e.g. `distributed:false`. */
  extra: string
}

/** One node type inside a graph type (`DESC GRAPH TYPE` row, entity_type=Node). */
export interface SchemaNodeType {
  name: string
  /** Canonical pattern, e.g. `(Actor)`. */
  pattern: string
  /** Type labels, e.g. `[Person]` for actor/director/user. */
  labels: string[]
  /** Primary-key property names, e.g. `[id]`. */
  primaryKey: string[]
  /** Property names, e.g. `[id,name,birthDate]`. */
  properties: string[]
}

/** One edge type inside a graph type (`DESC GRAPH TYPE` row, entity_type=Edge). */
export interface SchemaEdgeType {
  name: string
  /** Canonical pattern, e.g. `(Actor)-[Act]->(Movie)`. */
  pattern: string
  /** Source node type parsed from the pattern. */
  source: string
  /** Target node type parsed from the pattern. */
  target: string
  /** Edge labels. */
  labels: string[]
  /** `Unique`, `Auto`, or the multiedge key property list. */
  multiedgeKey: string[]
  /** Property names. */
  properties: string[]
}

/** The `nebula_schema` tool's canonical value. */
export interface GraphSchemaOverview {
  ok: true
  /** Every graph known to the server (`SHOW GRAPHS`). */
  graphs: GraphInfo[]
  /** The graph that was introspected. */
  graph: GraphInfo
  /** Node types of the graph type. */
  nodes: SchemaNodeType[]
  /** Edge types of the graph type. */
  edges: SchemaEdgeType[]
  numNodes: number
  numEdges: number
}

/** G6 projection for the schema graph (consumed by the Web Client). */
export interface SchemaGraphProjection {
  kind: 'schema'
  graphType: string
  nodes: {
    id: string
    name: string
    labels: string[]
    primaryKey: string[]
    properties: string[]
  }[]
  edges: {
    id: string
    source: string
    target: string
    name: string
    labels: string[]
    multiedgeKey: string[]
    properties: string[]
  }[]
}

/**
 * Normalize a catalog cell that may arrive as a string like `[a,b]`, a quoted
 * string, or a decoded JS array. `Unique`/`Auto` scalars become single-element
 * lists; `NULL`/missing cells become empty lists.
 */
export function parseListCell(value: unknown): string[] {
  if (Array.isArray(value)) return value.map((v) => String(v))
  if (typeof value !== 'string') {
    if (value === null || value === undefined) return []
    return [String(value)]
  }
  const s = value.trim()
  if (s === '') return []
  if (s.startsWith('[') && s.endsWith(']')) {
    const inner = s.slice(1, -1).trim()
    if (inner === '') return []
    return inner.split(',').map((p) => p.trim().replace(/^['"]|['"]$/g, ''))
  }
  return [s]
}

/** Parse a `SHOW GRAPHS` result into {@link GraphInfo} rows. */
export function parseShowGraphs(result: NebulaExecuteResult): GraphInfo[] {
  if (!result.ok) return []
  return result.rows.map((row) => ({
    name: cell(row[0]),
    graphType: cell(row[1]),
    schema: cell(row[2]),
    owner: cell(row[3]),
    extra: cell(row[4]),
  }))
}

function cell(value: unknown): string {
  return value === null || value === undefined ? '' : String(value)
}

/** Extract every `(…)` group of a type pattern, e.g. `(Actor)-[Act]->(Movie)`. */
export function parsePatternGroups(pattern: string): string[] {
  const out: string[] = []
  const re = /\(([^()]*)\)/g
  let m: RegExpExecArray | null
  while ((m = re.exec(pattern)) !== null) {
    const g = m[1].trim()
    if (g.length > 0) out.push(g)
  }
  return out
}

/**
 * Parse a `DESC GRAPH TYPE` result into node and edge types. Rows are mapped
 * by the stable v5 column layout
 * `entity_type, type_name, type_pattern, labels, primary_key/multiedge_key, properties`.
 */
export function parseGraphTypeDesc(result: NebulaExecuteResult): { nodes: SchemaNodeType[]; edges: SchemaEdgeType[] } {
  const nodes: SchemaNodeType[] = []
  const edges: SchemaEdgeType[] = []
  if (!result.ok) return { nodes, edges }
  for (const row of result.rows) {
    const entityType = cell(row[0]).toLowerCase()
    const name = cell(row[1])
    const pattern = cell(row[2])
    const labels = parseListCell(row[3])
    const key = parseListCell(row[4])
    const properties = parseListCell(row[5])
    if (entityType.startsWith('node')) {
      nodes.push({ name, pattern, labels, primaryKey: key, properties })
    } else if (entityType.startsWith('edge')) {
      const groups = parsePatternGroups(pattern)
      const source = groups[0] ?? ''
      const target = groups[groups.length - 1] ?? source
      edges.push({ name, pattern, source, target, labels, multiedgeKey: key, properties })
    }
    // Unknown entity_type rows are skipped (defensive: catalog shape drift).
  }
  return { nodes, edges }
}

/**
 * Run the full introspection: `SHOW GRAPHS`, resolve the target graph, then
 * `DESC GRAPH TYPE` for its graph type. Read-only — the session's working
 * graph is never changed.
 *
 * @param execute - transport callback (typically `entry.client.execute`).
 * @param graph - optional target graph name. Resolution order: explicit
 *   `graph` argument → the session's tracked working graph (from
 *   `SESSION SET graph`) → the sole graph when the server has exactly one →
 *   an error listing the available graphs.
 * @param currentGraph - the session's tracked working graph, if any.
 * @throws Error when the target graph cannot be resolved or the catalog
 *   queries fail (code + message included).
 */
export async function collectGraphSchema(
  execute: (stmt: string) => Promise<NebulaExecuteResult>,
  graph?: string,
  currentGraph?: string,
): Promise<GraphSchemaOverview> {
  const graphsResult = await execute('SHOW GRAPHS')
  if (!graphsResult.ok) {
    throw new Error(`SHOW GRAPHS failed: ${graphsResult.error?.code ?? 'UNKNOWN'}: ${graphsResult.error?.message ?? 'unknown error'}`)
  }
  const graphs = parseShowGraphs(graphsResult)
  const target = resolveTargetGraph(graphs, graph, currentGraph)
  const descResult = await execute(`DESC GRAPH TYPE \`${escapeIdent(target.graphType)}\``)
  if (!descResult.ok) {
    throw new Error(
      `DESC GRAPH TYPE ${target.graphType} failed: ${descResult.error?.code ?? 'UNKNOWN'}: ${descResult.error?.message ?? 'unknown error'}`,
    )
  }
  const { nodes, edges } = parseGraphTypeDesc(descResult)
  return {
    ok: true,
    graphs,
    graph: target,
    nodes,
    edges,
    numNodes: nodes.length,
    numEdges: edges.length,
  }
}

function escapeIdent(name: string): string {
  return name.replaceAll('`', '``')
}

/** Resolve which graph to introspect; throws a helpful error when ambiguous. */
export function resolveTargetGraph(graphs: GraphInfo[], graph?: string, currentGraph?: string): GraphInfo {
  if (graph !== undefined && graph.trim().length > 0) {
    const byName = graphs.find((g) => g.name === graph)
    if (byName === undefined) {
      throw new Error(`unknown graph ${graph}; available graphs: ${graphs.map((g) => g.name).join(', ') || '(none)'}`)
    }
    if (byName.graphType === '') {
      throw new Error(`graph ${graph} has no graph type in SHOW GRAPHS; cannot introspect its schema`)
    }
    return byName
  }
  if (currentGraph !== undefined && currentGraph.length > 0) {
    const byCurrent = graphs.find((g) => g.name === currentGraph)
    if (byCurrent !== undefined && byCurrent.graphType !== '') return byCurrent
  }
  if (graphs.length === 1 && graphs[0].graphType !== '') return graphs[0]
  const hint = graphs.length === 0
    ? 'the server has no graphs'
    : `available graphs: ${graphs.map((g) => g.name).join(', ')}`
  throw new Error(
    `cannot determine the target graph — pass graph=<name> (${hint}), or select one first with SESSION SET graph <name>`,
  )
}

/** ngql-style ASCII dump of a schema overview, used as the tool render. */
export function formatSchemaOverview(overview: GraphSchemaOverview): string {
  const parts: string[] = []
  parts.push(
    `Graphs (${overview.graphs.length}): ${overview.graphs.map((g) => g.name).join(', ') || '(none)'}`,
  )
  const g = overview.graph
  parts.push(
    `Graph type: ${g.graphType} (graph ${g.name}, schema ${g.schema || '?'}, owner ${g.owner || '?'}${g.extra ? `, ${g.extra}` : ''})`,
  )

  const nodeRows = overview.nodes.map((n) => [
    n.name,
    n.labels.length > 0 ? `[${n.labels.join(', ')}]` : '',
    n.primaryKey.length > 0 ? `[${n.primaryKey.join(', ')}]` : '',
    n.properties.length > 0 ? `[${n.properties.join(', ')}]` : '[]',
  ])
  parts.push(`NODE TYPES (${overview.numNodes})`)
  parts.push(renderTable(['name', 'labels', 'primary key', 'properties'], nodeRows))

  const edgeRows = overview.edges.map((e) => [
    e.pattern,
    e.labels.length > 0 ? `[${e.labels.join(', ')}]` : '',
    e.multiedgeKey.length > 0 ? e.multiedgeKey.join(', ') : '',
    e.properties.length > 0 ? `[${e.properties.join(', ')}]` : '[]',
  ])
  parts.push(`EDGE TYPES (${overview.numEdges})`)
  parts.push(renderTable(['pattern', 'labels', 'multiedge key', 'properties'], edgeRows))
  return parts.join('\n')
}

/**
 * Project a schema overview into the Web Client's graph payload so the G6
 * renderer can draw the graph type as a meta-graph: node types as vertices,
 * edge types as arcs between their source/target node types.
 */
export function buildSchemaGraphMeta(overview: GraphSchemaOverview): SchemaGraphProjection {
  const known = new Set(overview.nodes.map((n) => n.name))
  const nodes: SchemaGraphProjection['nodes'] = overview.nodes.map((n) => ({
    id: n.name,
    name: n.name,
    labels: n.labels,
    primaryKey: n.primaryKey,
    properties: n.properties,
  }))
  const edges: SchemaGraphProjection['edges'] = []
  for (const e of overview.edges) {
    if (!known.has(e.source)) {
      nodes.push({ id: e.source, name: e.source, labels: [], primaryKey: [], properties: [] })
      known.add(e.source)
    }
    if (!known.has(e.target)) {
      nodes.push({ id: e.target, name: e.target, labels: [], primaryKey: [], properties: [] })
      known.add(e.target)
    }
    edges.push({
      id: `${e.source}->${e.name}->${e.target}`,
      source: e.source,
      target: e.target,
      name: e.name,
      labels: e.labels,
      multiedgeKey: e.multiedgeKey,
      properties: e.properties,
    })
  }
  return { kind: 'schema', graphType: overview.graph.graphType, nodes, edges }
}

/**
 * Extract the graph name from a `SESSION SET graph <name>` statement (the v5
 * way to switch the session's working graph). Case-insensitive; when several
 * `SESSION SET graph` statements share one call, the last one wins.
 */
export function sessionSetGraph(stmt: string): string | undefined {
  let found: string | undefined
  for (const segment of stmt.split(';')) {
    const m = /^\s*session\s+set\s+graph\s+`?([A-Za-z0-9_]+)`?\s*$/i.exec(segment)
    if (m !== null) found = m[1]
  }
  return found
}
