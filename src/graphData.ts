/**
 * Graph payload extraction: scan decoded result rows for node / edge / path
 * cells and project a replayable `{ nodes, edges }` structure that the Web
 * Client renders with AntV G6. Emitted as the `nebula_execute` tool's
 * `presentationMeta`, so it survives session-log replay without re-parsing
 * the canonical value.
 */

/** Node projection for the client graph. */
export interface GraphNodeProjection {
  id: string
  type: string
  labels: string[]
  properties: Record<string, unknown>
}

/** Edge projection for the client graph (endpoint ids as strings). */
export interface GraphEdgeProjection {
  id: string
  source: string
  target: string
  type: string
  rank?: string
  direction?: 'outgoing' | 'incoming' | 'none'
  properties: Record<string, unknown>
}

/** The projected graph payload carried in `tool/result` meta. */
export interface GraphProjection {
  nodes: GraphNodeProjection[]
  edges: GraphEdgeProjection[]
  /** True when the projection was capped to keep the browser bundle small. */
  truncated?: boolean
}

/** Cap on projected elements; larger results degrade to a table-only render. */
export const MAX_GRAPH_NODES = 1000
export const MAX_GRAPH_EDGES = 2000

interface NodeLike { nodeId: unknown; type: unknown; labels: unknown; properties: unknown }
interface EdgeLike {
  srcId: unknown
  dstId: unknown
  rank: unknown
  direction: unknown
  type: unknown
  labels: unknown
  properties: unknown
}
interface PathLike { elements: unknown }

function isNodeCell(value: unknown): value is NodeLike {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
    && 'nodeId' in value && 'type' in value && 'properties' in value
}
function isEdgeCell(value: unknown): value is EdgeLike {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
    && 'srcId' in value && 'dstId' in value && 'rank' in value && 'direction' in value
}
function isPathCell(value: unknown): value is PathLike {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
    && 'elements' in value && Array.isArray((value as PathLike).elements)
}

function stringId(value: unknown): string {
  if (typeof value === 'string') return value
  if (typeof value === 'number') return String(value)
  if (typeof value === 'bigint') return value.toString()
  return String(value)
}

function plainProperties(properties: unknown): Record<string, unknown> {
  if (typeof properties !== 'object' || properties === null || Array.isArray(properties)) return {}
  return properties as Record<string, unknown>
}

function labelsOf(labels: unknown): string[] {
  return Array.isArray(labels) ? labels.map(String) : []
}

/**
 * Extract nodes/edges from one decoded result value.
 *
 * @param rows - decoded result rows (cells are plain JSON values).
 * @returns a graph projection, or undefined when no node/edge/path cell was found.
 */
export function extractGraphData(rows: unknown[][] | undefined | null): GraphProjection | undefined {
  if (!Array.isArray(rows) || rows.length === 0) return undefined
  const nodes = new Map<string, GraphNodeProjection>()
  const edges: GraphEdgeProjection[] = []
  let truncated = false

  const addNode = (cell: NodeLike): void => {
    const id = stringId(cell.nodeId)
    if (nodes.has(id)) return
    if (nodes.size >= MAX_GRAPH_NODES) {
      truncated = true
      return
    }
    nodes.set(id, {
      id,
      type: typeof cell.type === 'string' ? cell.type : '',
      labels: labelsOf(cell.labels),
      properties: plainProperties(cell.properties),
    })
  }

  const addEdge = (cell: EdgeLike): void => {
    if (edges.length >= MAX_GRAPH_EDGES) {
      truncated = true
      return
    }
    const source = stringId(cell.srcId)
    const target = stringId(cell.dstId)
    // Ensure both endpoints exist so G6 does not drop the edge.
    if (!nodes.has(source)) {
      if (nodes.size < MAX_GRAPH_NODES) nodes.set(source, { id: source, type: '', labels: [], properties: {} })
      else truncated = true
    }
    if (!nodes.has(target)) {
      if (nodes.size < MAX_GRAPH_NODES) nodes.set(target, { id: target, type: '', labels: [], properties: {} })
      else truncated = true
    }
    edges.push({
      id: `${source}->${target}#${edges.length}`,
      source,
      target,
      type: typeof cell.type === 'string' ? cell.type : '',
      ...cell.rank !== undefined ? { rank: stringId(cell.rank) } : {},
      ...(cell.direction === 'outgoing' || cell.direction === 'incoming' || cell.direction === 'none')
        ? { direction: cell.direction }
        : {},
      properties: plainProperties(cell.properties),
    })
  }

  const addPath = (cell: PathLike): void => {
    // Paths alternate nodes and edges; expand to the same projection.
    for (const element of cell.elements as unknown[]) {
      if (isNodeCell(element)) addNode(element)
      else if (isEdgeCell(element)) addEdge(element)
    }
  }

  for (const row of rows) {
    if (!Array.isArray(row)) continue
    for (const cell of row) {
      if (isNodeCell(cell)) addNode(cell)
      else if (isEdgeCell(cell)) addEdge(cell)
      else if (isPathCell(cell)) addPath(cell)
    }
  }

  if (nodes.size === 0 && edges.length === 0) return undefined
  return {
    nodes: [...nodes.values()],
    edges,
    ...truncated ? { truncated: true } : {},
  }
}
