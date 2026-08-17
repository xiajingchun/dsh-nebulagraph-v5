/**
 * dsh-nebula Web Client plugin: renders an interactive AntV G6 graph when a
 * `nebula_execute` result contains nodes / edges / paths.
 *
 * The host half of `nebula_execute` projects a replayable `{ graph }` payload
 * into `tool/result` meta; this plugin's conversation node matches those
 * events and a keyed Chat renderer mounts a G6 graph (drag / zoom) from it.
 *
 * Only the turn's FINAL graph renders: one card per turn whose content is the
 * latest graph-carrying tool result, so intermediate results the agent
 * produces while thinking never accumulate as separate G6 cards.
 */

import { createElement, useEffect, useRef, useState } from 'react'
import { Graph } from '@antv/g6'
import type {
  ClientContext,
  ConversationLocation,
  ConversationNodeContext,
  ConversationNodeDefinition,
} from '@deepseek-ai/dsh-client-runtime/client'
import type { ChatNodeViewProps } from '@deepseek-ai/dsh-client-ui-conversation/client'

/** Graph payload projected by the host `nebula_execute` tool. */
interface GraphProjection {
  nodes: {
    id: string
    type: string
    labels: string[]
    properties: Record<string, unknown>
    /** Primary-key property names for the node's type (from DESC GRAPH TYPE). */
    primaryKey?: string[]
  }[]
  edges: {
    id: string
    source: string
    target: string
    type: string
    rank?: string
    direction?: 'outgoing' | 'incoming' | 'none'
    properties: Record<string, unknown>
    /**
     * Multiedge-key property names for the edge's type (from DESC GRAPH
     * TYPE); `['Unique']`/`['Auto']` when the type has no multiedge key.
     */
    multiedgeKey?: string[]
  }[]
  truncated?: boolean
}

/**
 * Schema-graph payload projected by the host `nebula_schema` tool: the graph
 * type drawn as a meta-graph (node types as vertices, edge types as arcs).
 */
interface SchemaGraphProjection {
  kind: 'schema'
  graphType: string
  nodes: { id: string; name: string; labels: string[]; primaryKey: string[]; properties: string[] }[]
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

type NebulaGraphPayload = GraphProjection | SchemaGraphProjection

interface NebulaGraphState {
  /** The latest graph-carrying tool result of the turn; absent before any. */
  graph?: NebulaGraphPayload
  turn: number
  step?: number
}

interface NebulaGraphChatData {
  graph: NebulaGraphPayload
}

declare module '@deepseek-ai/dsh-client-ui-conversation/client' {
  interface ChatNodeDataMap {
    'nebula-graph': NebulaGraphChatData
  }
}

declare module '@deepseek-ai/dsh-client-runtime/client' {
  interface ConversationStepDataMap {
    'nebula-graph': NebulaGraphChatData
  }
}

function isGraphMeta(meta: unknown): meta is { graph: GraphProjection } {
  return typeof meta === 'object' && meta !== null && !Array.isArray(meta)
    && 'graph' in meta && (meta as { graph?: unknown }).graph !== undefined
}

function locationOf(context: ConversationNodeContext): ConversationLocation {
  return context.start?.location ?? context.matches[0]?.location ?? { kind: 'unresolved' }
}

/**
 * One G6 card per turn — "only the final result renders". The per-turn
 * context opens on `turn/start`, and every graph-carrying `tool/result` of
 * that turn replaces the state with its LATEST graph; intermediate graph
 * tool results therefore never accumulate as separate cards. The card stays
 * anchored to the newest graph result's log position, so once the turn
 * settles the single card left behind is the turn's final graph, sitting
 * exactly where that final result appears in the conversation.
 */
const nebulaGraphDefinition: ConversationNodeDefinition<NebulaGraphState> = {
  kind: 'nebula-graph',
  target: 'chat',
  match: (event) => {
    // Open the per-turn context on turn/start (guaranteed to precede the
    // turn's tool results), so the first graph result of the turn can update
    // an existing context instead of starting a second one.
    if (event.type === 'turn/start') {
      return { id: `nebula-${event.data.turn}`, role: 'start' }
    }
    if (event.type === 'tool/result' && isGraphMeta(event.data.meta)) {
      return { id: `nebula-${event.data.turn}`, role: 'update' }
    }
    return null
  },
  start: (context, match) => {
    if (match.event.type !== 'turn/start') throw new Error('nebula-graph start requires turn/start')
    return { turn: match.event.data.turn }
  },
  update: (context, match) => {
    if (match.event.type !== 'tool/result') return context.state
    const meta = match.event.data.meta
    if (!isGraphMeta(meta)) return context.state
    return {
      graph: meta.graph,
      turn: match.event.data.turn,
      step: match.event.data.step,
    }
  },
  publication: () => 'immediate',
  buildViewNode: (context) => {
    if (context.state === undefined || context.state.graph === undefined) return null
    // Anchor to the latest graph tool/result of the turn: matches are in
    // ascending log order and every update match is a graph tool/result, so
    // the last match is the turn's final graph result.
    const latest = context.matches.at(-1)
    return {
      key: context.key,
      kind: 'nebula-graph',
      id: context.id,
      target: 'chat',
      anchorSeq: latest?.event.seq ?? context.start?.event.seq ?? 0,
      location: latest?.location ?? locationOf(context),
      visibility: 'visible',
      data: { graph: context.state.graph },
    }
  },
}

/**
 * Tooltip budget: at most this many properties per element, and property
 * values longer than this many characters are truncated — keeps the hover
 * card compact regardless of how wide the page layout is.
 */
const TOOLTIP_MAX_PROPERTIES = 10
const TOOLTIP_MAX_VALUE_CHARS = 80

/**
 * Lite-mode thresholds: a data graph beyond these switches to cheap
 * rendering (bounded force layout, no edge labels, lighter behaviors).
 */
const LITE_NODE_THRESHOLD = 300
const LITE_EDGE_THRESHOLD = 600

/**
 * Client-side render caps applied on top of the host-side truncation: a
 * payload larger than this would still jank the browser, so only this many
 * elements are handed to G6 (edges with dropped endpoints are filtered out).
 */
const RENDER_NODE_CAP = 700
const RENDER_EDGE_CAP = 1400

/** Node-type fill palette (dark-background friendly, mutually distinct). */
const TYPE_PALETTE = [
  '#5B8FF9', '#5AD8A6', '#F6BD16', '#E8684A', '#6DC8EC', '#9270CA',
  '#FF9D4D', '#269A99', '#FF99C3', '#B8F542', '#AB47BC', '#00ACC1',
]

/** Neutral fill for elements with no type (e.g. still-placeholder endpoints). */
const TYPE_UNKNOWN_FILL = '#7a828e'

/**
 * Assign a distinct fill color to every element type present in the current
 * graph: types are sorted and the palette is consumed in order, so two
 * different types in one graph never share a color (a plain hash modulo the
 * palette collides — e.g. `player` and `team` both map to the same slot).
 */
function buildTypeColors(types: Iterable<string>): Map<string, string> {
  const distinct = [...new Set(types)].filter((t) => t.length > 0).sort()
  const colors = new Map<string, string>()
  for (let i = 0; i < distinct.length; i++) {
    colors.set(distinct[i], TYPE_PALETTE[i % TYPE_PALETTE.length])
  }
  return colors
}

/** Resolve the fill color of one element from the graph's type→color map. */
function colorForType(type: string, typeColors: Map<string, string>): string {
  if (type.length === 0) return TYPE_UNKNOWN_FILL
  return typeColors.get(type) ?? TYPE_PALETTE[0]
}

/**
 * Compose the primary-key label of a data node from its property values,
 * using the primary-key property names the host resolved from
 * `DESC GRAPH TYPE`. A composite primary key joins its values with `:`.
 * Returns undefined when the schema is unknown or a key property is missing
 * (in which case callers fall back to a readable property / internal id).
 */
function primaryKeyLabel(node: GraphProjection['nodes'][number]): string | undefined {
  const names = node.primaryKey ?? []
  if (names.length === 0) return undefined
  const values: string[] = []
  for (const name of names) {
    const value = node.properties[name]
    if (value === undefined || value === null) return undefined
    values.push(String(value))
  }
  return values.join(':')
}

/**
 * Node label is always the node's primary-key value (composed from the
 * primary-key property names given by `DESC GRAPH TYPE`, joined with `:` for
 * composite keys). Without schema info (catalog lookup failed) it falls back
 * to a readable property, then the internal id.
 */
function nodeLabel(node: GraphProjection['nodes'][number]): string {
  const pk = primaryKeyLabel(node)
  if (pk !== undefined && pk.length > 0) return pk
  const props = node.properties
  const name = props.name ?? props.title
  return typeof name === 'string' && name.length > 0 ? name : node.id
}

/**
 * Edge label: the edge type name plus, only when the type's multiedge key
 * defines real properties (not Unique/Auto), the key values composed from
 * the edge's properties with their property names (`name=value`, joined by
 * `, `). The raw server rank is meaningless on its own and never shown.
 */
function edgeLabel(edge: GraphProjection['edges'][number]): string {
  const base = edge.type
  const mk = edge.multiedgeKey ?? []
  const hasKey = mk.length > 0 && mk[0] !== 'Unique' && mk[0] !== 'Auto'
  if (!hasKey) return base
  const parts: string[] = []
  for (const name of mk) {
    const value = edge.properties[name]
    if (value !== undefined && value !== null) parts.push(`${name}=${String(value)}`)
  }
  return parts.length > 0 ? `${base} (${parts.join(', ')})` : base
}

/** Project the graph payload into G6 v5 data. */
function toG6Data(graph: GraphProjection): {
  nodes: { id: string; data: Record<string, unknown> }[]
  edges: { id: string; source: string; target: string; data: Record<string, unknown> }[]
} {
  return {
    nodes: graph.nodes.map((node) => ({
      id: node.id,
      data: {
        type: node.type,
        labels: node.labels,
        label: nodeLabel(node),
        primaryKey: node.primaryKey ?? [],
        ...node.properties,
        kind: 'data-node',
      },
    })),
    edges: graph.edges.map((edge) => ({
      id: edge.id,
      source: edge.source,
      target: edge.target,
      data: {
        type: edge.type,
        label: edgeLabel(edge),
        ...edge.properties,
        rank: edge.rank,
        direction: edge.direction,
        multiedgeKey: edge.multiedgeKey ?? [],
        kind: 'data-edge',
      },
    })),
  }
}

function isSchemaGraph(graph: NebulaGraphPayload): graph is SchemaGraphProjection {
  return 'kind' in graph && graph.kind === 'schema'
}

/** Schema node label: type name plus its labels (kept short for the circle). */
function schemaNodeLabel(node: SchemaGraphProjection['nodes'][number]): string {
  const lines: string[] = [node.name]
  if (node.labels.length > 0) lines.push(`[${node.labels.join(', ')}]`)
  return lines.join('\n')
}

/** Approximate schema node diameter from the type name (shared by layout + style). */
function schemaNodeSize(node: SchemaGraphProjection['nodes'][number]): number {
  const text = `${node.name}${node.labels.length > 0 ? ` [${node.labels.join(',')}]` : ''}`
  return Math.max(46, text.length * 8.5 + 30)
}

/** Schema edge label: type name, multiedge key, and properties. */
function schemaEdgeLabel(edge: SchemaGraphProjection['edges'][number]): string {
  const base = edge.name
  const key = edge.multiedgeKey.length > 0 && edge.multiedgeKey[0] !== 'Unique' && edge.multiedgeKey[0] !== 'Auto'
    ? `key:${edge.multiedgeKey.join(',')}`
    : ''
  const props = edge.properties.length > 0 ? `[${edge.properties.join(', ')}]` : ''
  return [base, key, props].filter((p) => p.length > 0).join('\n')
}

function escapeHtml(text: string): string {
  return text.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;')
}

/** Cap a tooltip value to keep the card compact; whitespace is normalized. */
function formatTooltipValue(value: unknown): string {
  let text: string
  if (typeof value === 'string') text = value
  else if (value === null) text = 'null'
  else if (typeof value === 'object') {
    try {
      text = JSON.stringify(value)
    } catch {
      text = String(value)
    }
  } else text = String(value)
  text = text.replace(/\s+/g, ' ').trim()
  return text.length > TOOLTIP_MAX_VALUE_CHARS ? `${text.slice(0, TOOLTIP_MAX_VALUE_CHARS)}…` : text
}

/** Render property rows (first N, remainder counted) as an HTML fragment. */
function propertyRowsHtml(
  properties: Record<string, unknown>,
  isKey: (key: string) => boolean = () => false,
): string {
  const keys = Object.keys(properties)
  if (keys.length === 0) return '<span style="color:#7a828e">(no properties)</span>'
  const rows = keys.slice(0, TOOLTIP_MAX_PROPERTIES).map((key) => {
    const keyHtml = isKey(key) ? `🔑 ${escapeHtml(key)}` : escapeHtml(key)
    return `<span style="color:#d8dee9">${keyHtml}</span>: <span style="color:#9aa4b2">${escapeHtml(formatTooltipValue(properties[key]))}</span>`
  })
  const omitted = keys.length - rows.length
  if (omitted > 0) rows.push(`<span style="color:#7a828e">… 另有 ${omitted} 个属性未显示</span>`)
  return rows.join('<br/>')
}

/** Compose a node's primary-key value from G6 node data (key names + values). */
function primaryKeyValueFromData(d: Record<string, unknown>): string | undefined {
  const names = Array.isArray(d.primaryKey) ? d.primaryKey.map(String) : []
  if (names.length === 0) return undefined
  const values: string[] = []
  for (const name of names) {
    const value = d[name]
    if (value === undefined || value === null) return undefined
    values.push(String(value))
  }
  return values.join(':')
}

/** Tooltip card for a data-graph node: primary key + all properties (truncated). */
function dataNodeTooltip(item: { data?: Record<string, unknown> }): string {
  const d = item.data ?? {}
  const type = typeof d.type === 'string' && d.type.length > 0 ? d.type : '—'
  const labels = Array.isArray(d.labels) && d.labels.length > 0 ? d.labels.map(String).join(', ') : '—'
  const pk = primaryKeyValueFromData(d)
  const pkNames = Array.isArray(d.primaryKey) ? d.primaryKey.map(String) : []
  const props: Record<string, unknown> = {}
  for (const [key, value] of Object.entries(d)) {
    if (key === 'type' || key === 'labels' || key === 'label' || key === 'kind' || key === 'primaryKey') continue
    props[key] = value
  }
  const title = pk !== undefined && pk.length > 0
    ? `<b>🔑 ${escapeHtml(pk)}</b>`
    : `<b>${escapeHtml(String(d.label ?? ''))}</b>`
  return [
    title,
    `<span style="color:#9aa4b2">type: ${escapeHtml(type)}<br/>labels: ${escapeHtml(labels)}</span>`,
    '<span style="color:#9aa4b2">properties:</span>',
    propertyRowsHtml(props, (key) => pkNames.includes(key)),
  ].join('<br/>')
}

/** Tooltip card for a data-graph edge: type + endpoints + all properties (truncated). */
function dataEdgeTooltip(item: { source?: unknown; target?: unknown; data?: Record<string, unknown> }): string {
  const d = item.data ?? {}
  const type = typeof d.type === 'string' && d.type.length > 0 ? d.type : '—'
  const direction = typeof d.direction === 'string' && d.direction.length > 0
    ? ` · direction: ${escapeHtml(d.direction)}`
    : ''
  const mk = Array.isArray(d.multiedgeKey) ? d.multiedgeKey.map(String) : []
  const hasKey = mk.length > 0 && mk[0] !== 'Unique' && mk[0] !== 'Auto'
  const keyLine = hasKey
    ? `<span style="color:#9aa4b2">multiedge key: ${escapeHtml(mk.join(', '))}</span>`
    : ''
  const props: Record<string, unknown> = {}
  for (const [key, value] of Object.entries(d)) {
    if (key === 'type' || key === 'label' || key === 'kind' || key === 'rank' || key === 'direction' || key === 'multiedgeKey') continue
    props[key] = value
  }
  return [
    `<b>${escapeHtml(type)}</b>`,
    `<span style="color:#9aa4b2">${escapeHtml(String(item.source ?? ''))} → ${escapeHtml(String(item.target ?? ''))}${direction}</span>`,
    keyLine,
    '<span style="color:#9aa4b2">properties:</span>',
    propertyRowsHtml(props, (key) => hasKey && mk.includes(key)),
  ].filter((line) => line.length > 0).join('<br/>')
}

/** Tooltip card for a schema node: labels, primary key, and property list. */
function schemaNodeTooltip(node: SchemaGraphProjection['nodes'][number]): string {
  const labels = node.labels.length > 0 ? escapeHtml(node.labels.join(', ')) : '—'
  const key = node.primaryKey.length > 0 ? escapeHtml(node.primaryKey.join(', ')) : '—'
  const rows = node.properties.slice(0, TOOLTIP_MAX_PROPERTIES)
    .map((p) => `${node.primaryKey.includes(p) ? '🔑 ' : ''}${escapeHtml(p)}`)
  const omitted = node.properties.length - rows.length
  if (omitted > 0) rows.push(`… 另有 ${omitted} 个属性未显示`)
  return [
    `<b>${escapeHtml(node.name)}</b>`,
    `<span style="color:#9aa4b2">labels: ${labels}<br/>primary key: ${key}</span>`,
    '<span style="color:#9aa4b2">properties:</span>',
    rows.length > 0 ? rows.join('<br/>') : '<span style="color:#7a828e">(no properties)</span>',
  ].join('<br/>')
}

/** Tooltip card for a schema edge: type name, multiedge key, and property list. */
function schemaEdgeTooltip(edge: SchemaGraphProjection['edges'][number]): string {
  const key = edge.multiedgeKey.length > 0 && edge.multiedgeKey[0] !== 'Unique' && edge.multiedgeKey[0] !== 'Auto'
    ? `key: ${escapeHtml(edge.multiedgeKey.join(', '))}`
    : 'key: —'
  const rows = edge.properties.slice(0, TOOLTIP_MAX_PROPERTIES).map((p) => escapeHtml(p))
  const omitted = edge.properties.length - rows.length
  if (omitted > 0) rows.push(`… 另有 ${omitted} 个属性未显示`)
  return [
    `<b>${escapeHtml(edge.name)}</b>`,
    `<span style="color:#9aa4b2">${key}</span>`,
    '<span style="color:#9aa4b2">properties:</span>',
    rows.length > 0 ? rows.join('<br/>') : '<span style="color:#7a828e">(no properties)</span>',
  ].join('<br/>')
}

/** Project a schema graph into G6 v5 data with render hints on each node. */
function toSchemaG6Data(graph: SchemaGraphProjection): {
  nodes: { id: string; data: Record<string, unknown> }[]
  edges: { id: string; source: string; target: string; data: Record<string, unknown> }[]
} {
  return {
    nodes: graph.nodes.map((node) => ({
      id: node.id,
      data: {
        kind: 'schema-node',
        name: node.name,
        label: schemaNodeLabel(node),
        labels: node.labels,
        primaryKey: node.primaryKey,
        properties: node.properties,
        size: schemaNodeSize(node),
      },
    })),
    edges: graph.edges.map((edge) => ({
      id: edge.id,
      source: edge.source,
      target: edge.target,
      data: {
        kind: 'schema-edge',
        name: edge.name,
        type: edge.name,
        multiedgeKey: edge.multiedgeKey,
        properties: edge.properties,
        label: schemaEdgeLabel(edge),
      },
    })),
  }
}

/**
 * Cap what G6 renders for very large payloads: only the first N nodes are
 * kept and edges whose endpoints were dropped are filtered out, so the
 * canvas stays responsive even when the host-side truncation was generous.
 */
function capRenderData(graph: {
  nodes: { id: string }[]
  edges: { source: string; target: string }[]
}): {
  nodes: { id: string }[]
  edges: { source: string; target: string }[]
  furtherTruncated: boolean
} {
  if (graph.nodes.length <= RENDER_NODE_CAP && graph.edges.length <= RENDER_EDGE_CAP) {
    return { nodes: graph.nodes, edges: graph.edges, furtherTruncated: false }
  }
  const nodes = graph.nodes.slice(0, RENDER_NODE_CAP)
  const kept = new Set(nodes.map((n) => n.id))
  const edges = graph.edges
    .filter((e) => kept.has(e.source) && kept.has(e.target))
    .slice(0, RENDER_EDGE_CAP)
  return { nodes, edges, furtherTruncated: true }
}

/** Chat node renderer: an interactive G6 graph inside a fixed-height card. */
function NebulaGraphView({ node }: { node: ChatNodeViewProps<'nebula-graph'>['node'] }): ReturnType<typeof createElement> {
  const containerRef = useRef<HTMLDivElement | null>(null)
  const graphRef = useRef<Graph | null>(null)
  const [fullscreen, setFullscreen] = useState(false)
  const graph = node.data.graph
  const schema = isSchemaGraph(graph)
  // Lite mode: beyond these sizes the d3-force simulation and per-element
  // labels dominate the frame budget, so switch to cheap rendering.
  const lite = !schema && (graph.nodes.length > LITE_NODE_THRESHOLD || graph.edges.length > LITE_EDGE_THRESHOLD)
  const capped = capRenderData(graph)
  // Distinct color per element type within this graph (see buildTypeColors).
  const schemaTypeColors = schema ? buildTypeColors(graph.nodes.map((n) => n.name)) : new Map<string, string>()
  const dataTypeColors = !schema
    ? buildTypeColors(capped.nodes.map((n) => String((n as { type?: unknown }).type ?? '')))
    : new Map<string, string>()

  useEffect(() => {
    const el = containerRef.current
    if (el === null) return
    let disposed = false
    const g = schema
      // Schema graph: the graph type as a directed meta-graph. Node types are
      // circle vertices (type name + labels inside; labels, 🔑 primary key and
      // properties on hover); edge types are arcs between their pattern's
      // source/target node types. A layered dagre layout reads naturally for
      // the Actor→Movie→Genre shape.
      ? new Graph({
          container: el,
          data: toSchemaG6Data(graph),
          autoResize: true,
          layout: {
            type: 'dagre',
            rankdir: 'LR',
            nodesep: 24,
            ranksep: 72,
            nodeSize: (d) => (d.data as { size?: number }).size ?? 48,
          },
          node: {
            type: 'circle',
            style: {
              size: (d) => (d.data as { size?: number }).size ?? 48,
              fill: (d) => `${colorForType(String((d.data as { name?: unknown }).name ?? ''), schemaTypeColors)}2e`,
              stroke: (d) => colorForType(String((d.data as { name?: unknown }).name ?? ''), schemaTypeColors),
              lineWidth: 1.5,
              labelText: (d) => String((d.data as { label?: unknown }).label ?? ''),
              labelFill: '#d8dee9',
              labelFontSize: 12,
              labelLineHeight: 14,
              labelPlacement: 'center',
            },
          },
          edge: {
            style: {
              stroke: '#7a828e',
              labelText: (d) => String((d.data as { label?: unknown }).label ?? ''),
              labelFill: '#9aa4b2',
              labelFontSize: 11,
              labelLineHeight: 14,
              endArrow: true,
            },
          },
          plugins: [{
            type: 'tooltip',
            trigger: 'hover',
            getContent: (_event: unknown, items: { data?: Record<string, unknown> }[]) => {
              const datum = items[0] as { data?: Record<string, unknown> } | undefined
              const d = datum?.data
              if (d?.kind === 'schema-node') {
                return schemaNodeTooltip(d as unknown as SchemaGraphProjection['nodes'][number])
              }
              if (d?.kind === 'schema-edge') {
                return schemaEdgeTooltip(d as unknown as SchemaGraphProjection['edges'][number])
              }
              return ''
            },
          }],
          behaviors: ['drag-canvas', 'zoom-canvas', 'drag-element', 'hover-activate'],
        })
      // Data graph. Small graphs keep the d3-force simulation and edge
      // labels; large ones (lite) use the bounded `force` layout, no edge
      // labels, and lighter behaviors so the browser stays responsive.
      : new Graph({
          container: el,
          data: toG6Data({ nodes: capped.nodes, edges: capped.edges } as GraphProjection),
          autoResize: true,
          animation: !lite,
          layout: lite
            ? {
                type: 'force',
                linkDistance: 120,
                nodeStrength: 80,
                edgeStrength: 0.1,
                preventOverlap: true,
                nodeSize: 44,
                collideStrength: 0.8,
                maxIteration: 120,
                minMovement: 1,
                animate: false,
              }
            : {
                type: 'd3-force',
                linkDistance: 150,
                edgeStrength: 0.15,
                nodeStrength: -300,
                preventOverlap: true,
                nodeSize: 52,
                collideStrength: 1,
                centerStrength: 0.2,
              },
          node: {
            style: {
              size: 36,
              fill: (d) => colorForType(String((d.data as { type?: unknown }).type ?? ''), dataTypeColors),
              labelText: (d) => String((d.data as { label?: unknown }).label ?? d.id),
              labelPlacement: 'bottom',
              labelFill: '#d8dee9',
            },
          },
          edge: {
            style: {
              stroke: '#7a828e',
              labelText: lite ? () => '' : (d) => String((d.data as { label?: unknown }).label ?? ''),
              labelFill: '#9aa4b2',
              endArrow: true,
            },
          },
          plugins: [{
            type: 'tooltip',
            trigger: 'hover',
            getContent: (_event: unknown, items: { data?: Record<string, unknown> }[]) => {
              const item = items[0] as { data?: Record<string, unknown> } | undefined
              const kind = item?.data?.kind
              if (kind === 'data-node') return dataNodeTooltip(item as { data?: Record<string, unknown> })
              if (kind === 'data-edge') {
                return dataEdgeTooltip(item as { source?: unknown; target?: unknown; data?: Record<string, unknown> })
              }
              return ''
            },
          }],
          behaviors: lite
            ? ['drag-canvas', 'zoom-canvas', 'drag-element']
            : ['drag-canvas', 'zoom-canvas', 'drag-element-force', 'hover-activate'],
        })
    graphRef.current = g
    const fit = (): void => {
      try {
        g.fitView()
      } catch {
        // fit may race teardown; ignore
      }
    }
    g.on('afterlayout', fit)
    g.render().catch(() => {
      // Rendering failure must not crash the chat view.
    })
    return () => {
      disposed = true
      graphRef.current = null
      g.destroy()
    }
    void disposed
  }, [graph])

  // Sync state with native fullscreen (Esc / exit).
  useEffect(() => {
    const onChange = (): void => {
      if (document.fullscreenElement === null) setFullscreen(false)
      else requestAnimationFrame(() => graphRef.current?.fitView())
    }
    document.addEventListener('fullscreenchange', onChange)
    return () => document.removeEventListener('fullscreenchange', onChange)
  }, [])

  // Fit the view when the overlay container resizes.
  useEffect(() => {
    if (fullscreen) requestAnimationFrame(() => graphRef.current?.fitView())
  }, [fullscreen])

  // Re-run the force simulation: releases dragged positions and re-spreads.
  const reheat = (): void => {
    const g = graphRef.current
    if (g === null) return
    try {
      g.stopLayout()
      void g.layout().catch(() => {})
    } catch {
      // layout may race teardown; ignore
    }
  }

  const toggleFullscreen = (): void => {
    const el = containerRef.current
    if (el === null) return
    if (fullscreen) {
      document.exitFullscreen?.().catch(() => {})
      setFullscreen(false)
    } else {
      el.requestFullscreen?.().catch(() => {})
      setFullscreen(true)
    }
  }

  const summary = schema
    ? `Schema ${graph.graphType} · ${graph.nodes.length} node type${graph.nodes.length === 1 ? '' : 's'} · ${graph.edges.length} edge type${graph.edges.length === 1 ? '' : 's'}`
    : `${graph.nodes.length} node${graph.nodes.length === 1 ? '' : 's'} · ${graph.edges.length} edge${graph.edges.length === 1 ? '' : 's'}`
  const containerStyle = fullscreen
    ? { position: 'fixed' as const, inset: 0, zIndex: 9999, width: '100vw', height: '100vh', background: '#12151c' }
    : { width: '100%', height: 480, background: '#12151c' }
  return createElement(
    'div',
    { style: { border: '1px solid #2a3140', borderRadius: 8, overflow: 'hidden', marginTop: 8 } },
    createElement(
      'div',
      { style: { padding: '6px 10px', fontSize: 12, color: '#9aa4b2', display: 'flex', justifyContent: 'space-between', alignItems: 'center', background: '#1b212c' } },
      createElement('span', null, `NebulaGraph · ${summary}`),
      createElement(
        'span',
        { style: { display: 'flex', gap: 10, alignItems: 'center' } },
        createElement('span', null, '拖拽/滚轮缩放'),
        createElement(
          'button',
          {
            onClick: reheat,
            style: { cursor: 'pointer', background: '#2a3140', color: '#d8dee9', border: 'none', borderRadius: 4, padding: '2px 8px', fontSize: 12 },
          },
          '⟳ 重新布局',
        ),
        createElement(
          'button',
          {
            onClick: toggleFullscreen,
            style: { cursor: 'pointer', background: '#2a3140', color: '#d8dee9', border: 'none', borderRadius: 4, padding: '2px 8px', fontSize: 12 },
          },
          fullscreen ? '退出全屏' : '⛶ 全屏',
        ),
      ),
    ),
    createElement(
      'div',
      { ref: containerRef, style: containerStyle },
      fullscreen
        ? createElement(
            'div',
            {
              onClick: toggleFullscreen,
              style: { position: 'absolute', top: 8, right: 12, cursor: 'pointer', background: '#2a3140', color: '#d8dee9', borderRadius: 6, padding: '4px 10px', fontSize: 12, zIndex: 10000 },
            },
            '✕ 退出全屏 (Esc)',
          )
        : null,
    ),
    !schema && (graph.truncated === true || capped.furtherTruncated)
      ? createElement(
          'div',
          { style: { padding: '4px 10px', fontSize: 12, color: '#e8a13a' } },
          graph.truncated === true && capped.furtherTruncated
            ? '结果较大：服务端与客户端均已截断以保证流畅'
            : capped.furtherTruncated
              ? '结果较大：为保持流畅，客户端已进一步截断渲染的节点/边'
              : '结果较大，已截断部分节点/边',
        )
      : null,
  )
}

/** Client services required by this plugin. */
export const inject = ['conversationEvents', 'slots']

/** Mount the conversation node definition and the keyed Chat renderer. */
export function apply(ctx: ClientContext): void {
  ctx.conversationEvents.register(nebulaGraphDefinition)
  ctx.slots.inject('conversation.chat.node', () => ctx.slots.register({
    name: 'conversation.chat.node',
    key: 'nebula-graph',
  }, NebulaGraphView))
}
