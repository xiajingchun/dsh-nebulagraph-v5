/**
 * Host graph projection tests: `nebula_execute` results containing nodes,
 * edges, or paths project a replayable `{ nodes, edges }` payload for the
 * Web Client's G6 renderer.
 */

import assert from 'node:assert/strict'
import { describe, it } from 'node:test'
import { extractGraphData } from '../src/graphData.ts'

describe('extractGraphData', () => {
  it('returns undefined for non-graph results', () => {
    assert.equal(extractGraphData([['movie', 'ldbc']]), undefined)
    assert.equal(extractGraphData([], ), undefined)
    assert.equal(extractGraphData(null), undefined)
    assert.equal(extractGraphData([[1, 2], ['a', 'b']]), undefined)
  })

  it('projects node cells and dedupes by nodeId', () => {
    const graph = extractGraphData([
      [{ nodeId: 1n, type: 'Movie', labels: ['Movie'], properties: { name: 'A' } }],
      [{ nodeId: 1n, type: 'Movie', labels: ['Movie'], properties: { name: 'A' } }],
      [{ nodeId: 2, type: 'Person', labels: ['Person'], properties: { name: 'B' } }],
    ])
    assert.ok(graph, 'graph projection expected')
    assert.equal(graph.nodes.length, 2)
    assert.equal(graph.edges.length, 0)
    assert.deepEqual(graph.nodes.map((n) => n.id), ['1', '2'])
    // No primary-key resolver: the field is present and empty.
    assert.deepEqual(graph.nodes[0].primaryKey, [])
  })

  it('resolves primary-key property names via the resolver (per graph and type)', () => {
    const graph = extractGraphData(
      [
        [{ nodeId: 1, graph: 'movie', type: 'Movie', labels: ['Movie'], properties: { id: 129, name: 'A' } }],
        [{ nodeId: 2, graph: 'movie', type: 'Actor', labels: ['Person'], properties: { id: 3 } }],
      ],
      (g, t) => (g === 'movie' && t === 'Movie' ? ['id', 'name'] : t === 'Actor' ? ['id'] : undefined),
    )
    assert.ok(graph)
    // Composite key: both property names are kept for the client to compose.
    assert.deepEqual(graph.nodes[0].primaryKey, ['id', 'name'])
    assert.deepEqual(graph.nodes[1].primaryKey, ['id'])
  })

  it('projects edge cells and synthesizes missing endpoint nodes', () => {
    const graph = extractGraphData([
      [{
        srcId: 1n, dstId: 2n, rank: 0n, direction: 'outgoing', type: 'DIRECTED',
        graph: 'movie', labels: ['DIRECTED'], properties: { since: 2000 },
      }],
    ])
    assert.ok(graph)
    assert.equal(graph.nodes.length, 2)
    assert.equal(graph.edges.length, 1)
    assert.deepEqual(graph.edges[0], {
      id: '1->2#0',
      source: '1',
      target: '2',
      type: 'DIRECTED',
      rank: '0',
      direction: 'outgoing',
      properties: { since: 2000 },
      multiedgeKey: [],
    })
  })

  it('upgrades endpoint placeholders when the real node cell arrives later', () => {
    // `RETURN v, e, w` delivers the edge before its endpoint node cell, so
    // the placeholder created for w must be replaced by the real cell.
    const graph = extractGraphData([
      [{
        nodeId: 1,
        graph: 'basketballplayer',
        type: 'player',
        labels: ['player'],
        properties: { id: 'p1', name: 'Steve' },
      }, {
        srcId: 1, dstId: 2, rank: 0, direction: 'outgoing', graph: 'basketballplayer', type: 'serve',
        labels: [], properties: {},
      }, {
        nodeId: 2,
        graph: 'basketballplayer',
        type: 'team',
        labels: ['team'],
        properties: { id: 't1', name: 'Warriors' },
      }],
    ], () => ['id'])
    assert.ok(graph)
    const team = graph.nodes.find((n) => n.id === '2')
    assert.ok(team)
    assert.equal(team.type, 'team')
    assert.deepEqual(team.properties, { id: 't1', name: 'Warriors' })
    assert.deepEqual(team.primaryKey, ['id'])
  })

  it('resolves multiedge-key property names via the resolver', () => {
    const graph = extractGraphData(
      [[{
        srcId: 1, dstId: 2, rank: 0, direction: 'outgoing', graph: 'basketballplayer', type: 'serve',
        labels: [], properties: { start_year: 2000, end_year: 2015 },
      }]],
      undefined,
      (g, t) => (g === 'basketballplayer' && t === 'serve' ? ['start_year', 'end_year'] : undefined),
    )
    assert.ok(graph)
    assert.deepEqual(graph.edges[0].multiedgeKey, ['start_year', 'end_year'])
  })

  it('expands path cells into nodes and edges', () => {
    const graph = extractGraphData([
      [{
        elements: [
          { nodeId: 1n, type: 'A', labels: [], properties: {} },
          { srcId: 1n, dstId: 2n, rank: 0n, direction: 'outgoing', type: 'E', labels: [], properties: {} },
          { nodeId: 2n, type: 'B', labels: [], properties: {} },
        ],
      }],
    ])
    assert.ok(graph)
    assert.equal(graph.nodes.length, 2)
    assert.equal(graph.edges.length, 1)
  })

  it('caps projections and flags truncation', () => {
    const rows = Array.from({ length: 1500 }, (_, i) => [
      { nodeId: BigInt(i + 1), type: 'N', labels: [], properties: {} },
    ])
    const graph = extractGraphData(rows)
    assert.ok(graph)
    assert.equal(graph.truncated, true)
    assert.ok(graph.nodes.length <= 1000)
  })
})
