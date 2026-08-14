/**
 * dsh-nebula Web Client plugin: renders an interactive AntV G6 graph when a
 * `nebula_execute` result contains nodes / edges / paths.
 *
 * The host half of `nebula_execute` projects a replayable `{ graph }` payload
 * into `tool/result` meta; this plugin's conversation node matches those
 * events and a keyed Chat renderer mounts a G6 graph (drag / zoom) from it.
 */

import { createElement, useEffect, useRef } from 'react'
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
  nodes: { id: string; type: string; labels: string[]; properties: Record<string, unknown> }[]
  edges: {
    id: string
    source: string
    target: string
    type: string
    rank?: string
    direction?: 'outgoing' | 'incoming' | 'none'
    properties: Record<string, unknown>
  }[]
  truncated?: boolean
}

interface NebulaGraphState {
  graph: GraphProjection
  turn: number
  step: number
}

interface NebulaGraphChatData {
  graph: GraphProjection
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
 * One tool/result is a complete business unit: stable id from the event's own
 * log position, start-only (no updates), published immediately.
 */
const nebulaGraphDefinition: ConversationNodeDefinition<NebulaGraphState> = {
  kind: 'nebula-graph',
  target: 'chat',
  match: (event) => {
    if (event.type === 'tool/result' && isGraphMeta(event.data.meta)) {
      return { id: `nebula-${event.seq}`, role: 'start' }
    }
    return null
  },
  start: (context, match) => {
    if (match.event.type !== 'tool/result') throw new Error('nebula-graph requires tool/result')
    const meta = match.event.data.meta
    if (!isGraphMeta(meta)) throw new Error('nebula-graph requires graph meta')
    return {
      graph: meta.graph,
      turn: match.event.data.turn,
      step: match.event.data.step,
    }
  },
  update: (context) => context.state,
  publication: () => 'immediate',
  buildViewNode: (context) => {
    if (context.state === undefined) return null
    return {
      key: context.key,
      kind: 'nebula-graph',
      id: context.id,
      target: 'chat',
      anchorSeq: context.start?.event.seq ?? context.matches[0]?.event.seq ?? 0,
      location: locationOf(context),
      visibility: 'visible',
      data: { graph: context.state.graph },
    }
  },
}

/** Stable color per node type (G6 style fill). */
function colorForType(type: string): string {
  const palette = ['#5B8FF9', '#5AD8A6', '#F6BD16', '#E8684A', '#6DC8EC', '#9270CA', '#FF9D4D', '#269A99', '#FF99C3', '#B8F542']
  let hash = 0
  for (let i = 0; i < type.length; i++) hash = (hash * 31 + type.charCodeAt(i)) >>> 0
  return palette[hash % palette.length] ?? '#5B8FF9'
}

function nodeLabel(node: GraphProjection['nodes'][number]): string {
  const props = node.properties
  const name = props.name ?? props.title ?? props.id
  return typeof name === 'string' && name.length > 0 ? name : node.id
}

function edgeLabel(edge: GraphProjection['edges'][number]): string {
  const props = edge.properties
  const name = props.name ?? props.role
  const base = typeof name === 'string' && name.length > 0 ? name : edge.type
  return edge.rank !== undefined && edge.rank !== '' ? `${base} (${edge.rank})` : base
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
        ...node.properties,
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
      },
    })),
  }
}

/** Chat node renderer: an interactive G6 graph inside a fixed-height card. */
function NebulaGraphView({ node }: { node: ChatNodeViewProps<'nebula-graph'>['node'] }): ReturnType<typeof createElement> {
  const containerRef = useRef<HTMLDivElement | null>(null)
  const graph = node.data.graph

  useEffect(() => {
    const el = containerRef.current
    if (el === null) return
    let disposed = false
    const g = new Graph({
      container: el,
      data: toG6Data(graph),
      autoResize: true,
      autoFit: 'view',
      node: {
        style: {
          fill: (d) => colorForType(String((d.data as { type?: unknown }).type ?? '')),
          labelText: (d) => String((d.data as { label?: unknown }).label ?? d.id),
          labelPlacement: 'bottom',
          labelFill: '#d8dee9',
        },
      },
      edge: {
        style: {
          stroke: '#7a828e',
          labelText: (d) => String((d.data as { label?: unknown }).label ?? ''),
          labelFill: '#9aa4b2',
          endArrow: true,
        },
      },
      behaviors: ['drag-canvas', 'zoom-canvas', 'drag-element', 'hover-activate'],
    })
    g.render().catch(() => {
      // Rendering failure must not crash the chat view.
    })
    return () => {
      disposed = true
      g.destroy()
    }
    void disposed
  }, [graph])

  const summary = `${graph.nodes.length} node${graph.nodes.length === 1 ? '' : 's'} · ${graph.edges.length} edge${graph.edges.length === 1 ? '' : 's'}`
  return createElement(
    'div',
    { style: { border: '1px solid #2a3140', borderRadius: 8, overflow: 'hidden', marginTop: 8 } },
    createElement(
      'div',
      { style: { padding: '6px 10px', fontSize: 12, color: '#9aa4b2', display: 'flex', justifyContent: 'space-between', background: '#1b212c' } },
      createElement('span', null, `NebulaGraph · ${summary}`),
      createElement('span', null, '拖拽/滚轮缩放'),
    ),
    createElement(
      'div',
      { ref: containerRef, style: { width: '100%', height: 420, background: '#12151c' } },
    ),
    graph.truncated === true
      ? createElement('div', { style: { padding: '4px 10px', fontSize: 12, color: '#e8a13a' } }, '结果较大，已截断部分节点/边')
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
