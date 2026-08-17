/**
 * Schema introspection unit tests: parsing `SHOW GRAPHS` / `DESC GRAPH TYPE`
 * results, target-graph resolution, the ASCII render, the G6 schema-graph
 * projection, and `SESSION SET graph` tracking.
 */

import assert from 'node:assert/strict'
import { describe, it } from 'node:test'
import type { NebulaExecuteResult } from '../src/nebula-client.ts'
import {
  buildSchemaGraphMeta,
  collectGraphSchema,
  formatSchemaOverview,
  parseGraphTypeDesc,
  parseListCell,
  parsePatternGroups,
  parseShowGraphs,
  resolveTargetGraph,
  sessionSetGraph,
} from '../src/schema.ts'

function ok(columns: string[], rows: unknown[][]): NebulaExecuteResult {
  return { ok: true, columns, rows, numRows: rows.length, latencyUs: 0 }
}

/** Realistic `DESC GRAPH TYPE movie_type` rows, string-encoded list cells. */
const movieTypeRows: unknown[][] = [
  ['Node', 'Actor', '(Actor)', '[Person]', '[id]', '[id,name,birthDate]'],
  ['Node', 'Director', '(Director)', '[Person]', '[id]', '[id,name,birthDate]'],
  ['Node', 'User', '(User)', '[Person]', '[id]', '[id]'],
  ['Node', 'Movie', '(Movie)', '[Movie]', '[id]', '[id,name]'],
  ['Node', 'Genre', '(Genre)', '[Genre]', '[id]', '[id,name]'],
  ['Edge', 'Act', '(Actor)-[Act]->(Movie)', '[Act]', 'Unique', '[]'],
  ['Edge', 'Direct', '(Director)-[Direct]->(Movie)', '[Direct]', 'Unique', '[]'],
  ['Edge', 'Watch', '(User)-[Watch]->(Movie)', '[Watch]', 'Unique', '[rate]'],
  ['Edge', 'WithGenre', '(Movie)-[WithGenre]->(Genre)', '[WithGenre]', 'Unique', '[]'],
]

const showGraphsRows: unknown[][] = [
  ['movie', 'movie_type', '/default_schema', 'root', ''],
  ['basketballplayer', 'basketballplayer', '/default_schema', 'root', ''],
  ['#movie', 'movie_type', '/tmp_schema', 'root', 'distributed:false'],
]

describe('parseListCell', () => {
  it('handles string, array, quoted, scalar and null encodings', () => {
    assert.deepEqual(parseListCell('[id,name,birthDate]'), ['id', 'name', 'birthDate'])
    assert.deepEqual(parseListCell(['id', 'name']), ['id', 'name'])
    assert.deepEqual(parseListCell("['a','b']"), ['a', 'b'])
    assert.deepEqual(parseListCell('Unique'), ['Unique'])
    assert.deepEqual(parseListCell('[]'), [])
    assert.deepEqual(parseListCell(''), [])
    assert.deepEqual(parseListCell(null), [])
    assert.deepEqual(parseListCell(undefined), [])
  })
})

describe('parseShowGraphs', () => {
  it('maps the five SHOW GRAPHS columns', () => {
    const graphs = parseShowGraphs(ok(['name', 'graph_type', 'schema', 'owner', 'extra'], showGraphsRows))
    assert.equal(graphs.length, 3)
    assert.deepEqual(graphs[0], {
      name: 'movie', graphType: 'movie_type', schema: '/default_schema', owner: 'root', extra: '',
    })
    assert.deepEqual(graphs[2], {
      name: '#movie', graphType: 'movie_type', schema: '/tmp_schema', owner: 'root', extra: 'distributed:false',
    })
  })

  it('returns an empty list when the query failed', () => {
    const failed: NebulaExecuteResult = { ok: false, columns: [], rows: [], numRows: 0, latencyUs: 0, error: { code: 'E', message: 'boom' } }
    assert.deepEqual(parseShowGraphs(failed), [])
  })
})

describe('parsePatternGroups', () => {
  it('extracts source and target from edge patterns', () => {
    assert.deepEqual(parsePatternGroups('(Actor)-[Act]->(Movie)'), ['Actor', 'Movie'])
    assert.deepEqual(parsePatternGroups('(player)-[follow]->(player)'), ['player', 'player'])
    assert.deepEqual(parsePatternGroups('(Actor)'), ['Actor'])
  })
})

describe('parseGraphTypeDesc', () => {
  it('splits node and edge rows and decodes list cells', () => {
    const { nodes, edges } = parseGraphTypeDesc(ok(
      ['entity_type', 'type_name', 'type_pattern', 'labels', 'primary_key/multiedge_key', 'properties'],
      movieTypeRows,
    ))
    assert.equal(nodes.length, 5)
    assert.equal(edges.length, 4)

    const actor = nodes[0]
    assert.deepEqual(actor, {
      name: 'Actor', pattern: '(Actor)', labels: ['Person'], primaryKey: ['id'], properties: ['id', 'name', 'birthDate'],
    })

    const act = edges[0]
    assert.deepEqual(act, {
      name: 'Act', pattern: '(Actor)-[Act]->(Movie)', source: 'Actor', target: 'Movie',
      labels: ['Act'], multiedgeKey: ['Unique'], properties: [],
    })
    const watch = edges[2]
    assert.deepEqual(watch.multiedgeKey, ['Unique'])
    assert.deepEqual(watch.properties, ['rate'])
  })

  it('tolerates array-encoded cells (decoder variant)', () => {
    const rows: unknown[][] = [
      ['Edge', 'serve', '(player)-[serve]->(team)', ['serve'], ['start_year', 'end_year'], ['start_year', 'end_year']],
    ]
    const { edges } = parseGraphTypeDesc(ok(
      ['entity_type', 'type_name', 'type_pattern', 'labels', 'primary_key/multiedge_key', 'properties'],
      rows,
    ))
    assert.deepEqual(edges[0].multiedgeKey, ['start_year', 'end_year'])
    assert.deepEqual(edges[0].properties, ['start_year', 'end_year'])
    assert.equal(edges[0].source, 'player')
    assert.equal(edges[0].target, 'team')
  })
})

describe('resolveTargetGraph', () => {
  const graphs = parseShowGraphs(ok(['name', 'graph_type', 'schema', 'owner', 'extra'], showGraphsRows))

  it('prefers the explicit graph argument', () => {
    const target = resolveTargetGraph(graphs, 'basketballplayer')
    assert.equal(target.name, 'basketballplayer')
    assert.equal(target.graphType, 'basketballplayer')
  })

  it('falls back to the tracked working graph', () => {
    const target = resolveTargetGraph(graphs, undefined, 'movie')
    assert.equal(target.name, 'movie')
  })

  it('rejects unknown graphs with a helpful listing', () => {
    assert.throws(() => resolveTargetGraph(graphs, 'nope'), /unknown graph nope.*available graphs: movie, basketballplayer, #movie/)
  })

  it('requires a graph type', () => {
    const typeless = parseShowGraphs(ok(['name', 'graph_type', 'schema', 'owner', 'extra'], [['bare', null, '', '', '']]))
    assert.throws(() => resolveTargetGraph(typeless, 'bare'), /no graph type/)
  })

  it('throws when no graph can be determined', () => {
    assert.throws(() => resolveTargetGraph(graphs, undefined, undefined), /pass graph=<name>/)
  })

  it('uses the sole graph when unambiguous', () => {
    const sole = parseShowGraphs(ok(['name', 'graph_type', 'schema', 'owner', 'extra'], [['only', 'only_type', '', '', '']]))
    assert.equal(resolveTargetGraph(sole).name, 'only')
  })
})

describe('collectGraphSchema', () => {
  it('runs SHOW GRAPHS then DESC GRAPH TYPE and assembles the overview', async () => {
    const seen: string[] = []
    const execute = async (stmt: string): Promise<NebulaExecuteResult> => {
      seen.push(stmt)
      if (stmt === 'SHOW GRAPHS') return ok(['name', 'graph_type', 'schema', 'owner', 'extra'], showGraphsRows)
      if (stmt.startsWith('DESC GRAPH TYPE')) {
        return ok(['entity_type', 'type_name', 'type_pattern', 'labels', 'primary_key/multiedge_key', 'properties'], movieTypeRows)
      }
      return ok([], [])
    }
    const overview = await collectGraphSchema(execute, 'movie')
    assert.deepEqual(seen, ['SHOW GRAPHS', 'DESC GRAPH TYPE `movie_type`'])
    assert.equal(overview.graph.name, 'movie')
    assert.equal(overview.numNodes, 5)
    assert.equal(overview.numEdges, 4)
  })

  it('propagates SHOW GRAPHS and DESC GRAPH TYPE failures', async () => {
    const failGraphs = async (stmt: string): Promise<NebulaExecuteResult> =>
      stmt === 'SHOW GRAPHS'
        ? { ok: false, columns: [], rows: [], numRows: 0, latencyUs: 0, error: { code: 'E101', message: 'denied' } }
        : ok([], [])
    await assert.rejects(() => collectGraphSchema(failGraphs, 'movie'), /SHOW GRAPHS failed: E101: denied/)

    const failDesc = async (stmt: string): Promise<NebulaExecuteResult> =>
      stmt.startsWith('DESC GRAPH TYPE')
        ? { ok: false, columns: [], rows: [], numRows: 0, latencyUs: 0, error: { code: 'NS101', message: 'not found' } }
        : ok(['name', 'graph_type', 'schema', 'owner', 'extra'], showGraphsRows)
    await assert.rejects(() => collectGraphSchema(failDesc, 'movie'), /DESC GRAPH TYPE movie_type failed: NS101: not found/)
  })
})

describe('formatSchemaOverview', () => {
  it('renders a readable dump', async () => {
    const execute = async (stmt: string): Promise<NebulaExecuteResult> => {
      if (stmt === 'SHOW GRAPHS') return ok(['name', 'graph_type', 'schema', 'owner', 'extra'], showGraphsRows)
      return ok(['entity_type', 'type_name', 'type_pattern', 'labels', 'primary_key/multiedge_key', 'properties'], movieTypeRows)
    }
    const overview = await collectGraphSchema(execute, 'movie')
    const text = formatSchemaOverview(overview)
    assert.match(text, /Graphs \(3\): movie, basketballplayer, #movie/)
    assert.match(text, /Graph type: movie_type \(graph movie, schema \/default_schema, owner root\)/)
    assert.match(text, /NODE TYPES \(5\)/)
    assert.match(text, /EDGE TYPES \(4\)/)
    assert.match(text, /\(Actor\)-\[Act\]->\(Movie\)/)
  })
})

describe('buildSchemaGraphMeta', () => {
  it('projects a schema meta-graph for the Web Client', async () => {
    const execute = async (stmt: string): Promise<NebulaExecuteResult> => {
      if (stmt === 'SHOW GRAPHS') return ok(['name', 'graph_type', 'schema', 'owner', 'extra'], showGraphsRows)
      return ok(['entity_type', 'type_name', 'type_pattern', 'labels', 'primary_key/multiedge_key', 'properties'], movieTypeRows)
    }
    const overview = await collectGraphSchema(execute, 'movie')
    const meta = buildSchemaGraphMeta(overview)
    assert.equal(meta.kind, 'schema')
    assert.equal(meta.graphType, 'movie_type')
    assert.equal(meta.nodes.length, 5)
    assert.equal(meta.edges.length, 4)
    assert.deepEqual(meta.edges[0], {
      id: 'Actor->Act->Movie', source: 'Actor', target: 'Movie', name: 'Act',
      labels: ['Act'], multiedgeKey: ['Unique'], properties: [],
    })
  })

  it('adds placeholder nodes for dangling pattern references', () => {
    const execute = async (stmt: string): Promise<NebulaExecuteResult> => {
      if (stmt === 'SHOW GRAPHS') return ok(['name', 'graph_type', 'schema', 'owner', 'extra'], [['g', 'gt', '', '', '']])
      return ok(
        ['entity_type', 'type_name', 'type_pattern', 'labels', 'primary_key/multiedge_key', 'properties'],
        [['Edge', 'link', '(Ghost)-[link]->(AlsoGhost)', '[link]', 'Unique', '[]']],
      )
    }
    return collectGraphSchema(execute).then((overview) => {
      const meta = buildSchemaGraphMeta(overview)
      assert.deepEqual(meta.nodes.map((n) => n.id).sort(), ['AlsoGhost', 'Ghost'])
      assert.equal(meta.edges[0].source, 'Ghost')
      assert.equal(meta.edges[0].target, 'AlsoGhost')
    })
  })
})

describe('sessionSetGraph', () => {
  it('parses the v5 working-graph switch, case-insensitively', () => {
    assert.equal(sessionSetGraph('SESSION SET graph movie'), 'movie')
    assert.equal(sessionSetGraph('session set graph basketballplayer'), 'basketballplayer')
    assert.equal(sessionSetGraph('SESSION SET GRAPH `movie`'), 'movie')
    assert.equal(sessionSetGraph('SESSION SET graph movie;'), 'movie')
  })

  it('takes the last of several switches and ignores other statements', () => {
    assert.equal(sessionSetGraph('SESSION SET graph a; SESSION SET graph b'), 'b')
    assert.equal(sessionSetGraph('SESSION SET VALUE $_x=1'), undefined)
    assert.equal(sessionSetGraph('MATCH (n) RETURN n'), undefined)
    assert.equal(sessionSetGraph(''), undefined)
  })
})
