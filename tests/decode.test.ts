/**
 * Decoder unit tests: build synthetic `VectorResultTable` payloads by hand
 * (the plain-object shapes proto-loader produces) and verify the decoded
 * columns/rows. Payload layouts follow nebula-go v5's columnar encoding.
 */

import assert from 'node:assert/strict'
import { describe, it } from 'node:test'
import { decodeResultTable } from '../src/decode/resultTable.ts'
import type { ProtoVectorResultTable, ProtoNestedVector } from '../src/decode/resultTable.ts'
import { formatValue, renderTable } from '../src/format.ts'

function u32(n: number): Buffer {
  const b = Buffer.alloc(4)
  b.writeUInt32LE(n >>> 0, 0)
  return b
}
function i32(n: number): Buffer {
  const b = Buffer.alloc(4)
  b.writeInt32LE(n, 0)
  return b
}
function i64(n: bigint): Buffer {
  const b = Buffer.alloc(8)
  b.writeBigInt64LE(n, 0)
  return b
}
function u64(n: bigint): Buffer {
  const b = Buffer.alloc(8)
  b.writeBigUInt64LE(n, 0)
  return b
}

/** Bit-pack a datetime into the 8-byte qword layout (year16|month4|day5|hour5|minute6|sec6|microsec26). */
function packDatetime(year: number, month: number, day: number, hour: number, minute: number, sec: number, microsec: number): bigint {
  return BigInt(year)
    | (BigInt(month) << 16n)
    | (BigInt(day) << 20n)
    | (BigInt(hour) << 25n)
    | (BigInt(minute) << 30n)
    | (BigInt(sec) << 36n)
    | (BigInt(microsec) << 42n)
}

/** A short string (< 12 bytes) encoded as a 16-byte inline flat header. */
function inlineString(s: string): Buffer {
  const bytes = Buffer.from(s, 'utf8')
  const header = Buffer.alloc(16)
  bytes.copy(header, 4)
  header.writeUInt32LE(bytes.length, 0)
  return header
}

function flatVector(rows: Buffer[], vectorContentType = 2): ProtoNestedVector {
  return {
    num_nested_vectors: 0,
    common_meta_data: { num_records: rows.length, vector_content_type: vectorContentType },
    special_meta_data: Buffer.alloc(0),
    vector_data: Buffer.concat(rows),
    null_bit_map: null,
    nested_vectors: [],
  }
}

const flat = (vectorContentType = 2) => ({ vectorContentType })

function table(columns: string[], types: number[], vectors: ProtoNestedVector[], graphSchema?: ProtoVectorResultTable['meta']['graph_schema']): ProtoVectorResultTable {
  return {
    data_layout_version: Buffer.from([1]),
    meta: {
      table_type: 0,
      num_records: String(vectors[0]?.common_meta_data?.num_records ?? 0),
      row_type: {
        num_columns: columns.length,
        column_names: columns,
        column_types: types.map((value_type) => ({ value_type: Buffer.from([value_type]) })),
      },
      num_batches: 1,
      time_zone_offset: 0,
      is_little_endian: true,
      graph_schema: graphSchema ?? null,
    },
    batch: [{ vectors }],
  }
}

describe('decodeResultTable', () => {
  it('decodes basic scalar columns (string, int32, int64, datetime)', () => {
    const t = table(
      ['name', 'age', 'big', 'ts'],
      [0x10, 0x09, 0x0b, 0x18], // String, Int32, Int64, LocalDatetime
      [
        flatVector([inlineString('alice'), inlineString('bob')]),
        flatVector([i32(30), i32(25)]),
        flatVector([i64(-7897618527020261406n), i64(42n)]),
        flatVector([i64(packDatetime(2019, 1, 1, 12, 34, 56, 123456)), i64(packDatetime(2020, 12, 31, 23, 59, 59, 1))]),
      ],
    )
    const decoded = decodeResultTable(t)
    assert.deepEqual(decoded.columns, ['name', 'age', 'big', 'ts'])
    assert.equal(decoded.numRecords, 2)
    assert.deepEqual(decoded.rows, [
      ['alice', 30, '-7897618527020261406', '2019-01-01T12:34:56.123456'],
      ['bob', 25, 42, '2020-12-31T23:59:59.000001'],
    ])
    // The huge int64 stays lossless as a decimal string.
    assert.equal(decoded.rows[0][2], '-7897618527020261406')
  })

  it('honors the null bitmap', () => {
    const nullBitmap = Buffer.from([0b0000_0101]) // bits 0 and 2 set → rows 0 and 2 present
    const vector: ProtoNestedVector = {
      num_nested_vectors: 0,
      common_meta_data: { num_records: 3, vector_content_type: flat().vectorContentType },
      special_meta_data: Buffer.alloc(0),
      vector_data: Buffer.concat([i32(1), i32(2), i32(3)]),
      null_bit_map: nullBitmap,
      nested_vectors: [],
    }
    const decoded = decodeResultTable(table(['v'], [0x09], [vector]))
    assert.deepEqual(decoded.rows, [[1], [null], [3]])
  })

  it('decodes a const vector once and replays it', () => {
    // const vector: one int32 value encoded in vector_data
    const vector: ProtoNestedVector = {
      num_nested_vectors: 0,
      common_meta_data: { num_records: 3, vector_content_type: 1 }, // Const
      special_meta_data: Buffer.alloc(0),
      vector_data: i32(7),
      null_bit_map: null,
      nested_vectors: [],
    }
    const decoded = decodeResultTable(table(['v'], [0x09], [vector]))
    assert.deepEqual(decoded.rows, [[7], [7], [7]])
  })

  it('decodes a list column', () => {
    // two lists: [1,2] and [3,4,5]; elements live in a nested flat int32 vector
    const header = Buffer.concat([u32(0), u32(2), u32(2), u32(3)]) // row0 offset=0 size=2; row1 offset=2 size=3
    const vector: ProtoNestedVector = {
      num_nested_vectors: 1,
      common_meta_data: { num_records: 2, vector_content_type: 2 },
      special_meta_data: Buffer.alloc(0),
      vector_data: header,
      null_bit_map: null,
      nested_vectors: [flatVector([i32(1), i32(2), i32(3), i32(4), i32(5)])],
    }
    // column type: List<Int32> = 0x11 followed by 0x09
    const decoded = decodeResultTable({
      data_layout_version: Buffer.from([1]),
      meta: {
        table_type: 0,
        num_records: '2',
        row_type: { num_columns: 1, column_names: ['lst'], column_types: [{ value_type: Buffer.from([0x11, 0x09]) }] },
        num_batches: 1,
        time_zone_offset: 0,
        is_little_endian: true,
        graph_schema: null,
      },
      batch: [{ vectors: [vector] }],
    })
    assert.deepEqual(decoded.rows, [[[1, 2]], [[3, 4, 5]]])
  })

  it('decodes a record column with named nested vectors', () => {
    // record with props a:int32 and s:string; special meta data names them
    const names = Buffer.concat([u16(1), Buffer.from('a'), u16(1), Buffer.from('s')])
    const vector: ProtoNestedVector = {
      num_nested_vectors: 2,
      common_meta_data: { num_records: 1, vector_content_type: 2 },
      special_meta_data: names,
      vector_data: Buffer.concat([i32(0), i32(0)]), // per-row headers (unused for record)
      null_bit_map: null,
      nested_vectors: [flatVector([i32(10)]), flatVector([inlineString('hi')])],
    }
    // Record schema: 0x13 + numFields(4B)=2 + [len(2)=1,"a",type 0x09] + [len(2)=1,"s",type 0x10]
    const recordType = Buffer.concat([
      Buffer.from([0x13]), u32(2),
      u16(1), Buffer.from('a'), Buffer.from([0x09]),
      u16(1), Buffer.from('s'), Buffer.from([0x10]),
    ])
    const decoded = decodeResultTable({
      data_layout_version: Buffer.from([1]),
      meta: {
        table_type: 0,
        num_records: '1',
        row_type: { num_columns: 1, column_names: ['r'], column_types: [{ value_type: recordType }] },
        num_batches: 1,
        time_zone_offset: 0,
        is_little_endian: true,
        graph_schema: null,
      },
      batch: [{ vectors: [vector] }],
    })
    assert.deepEqual(decoded.rows, [[{ a: 10, s: 'hi' }]])
  })

  it('decodes a node column with schema names and properties', () => {
    const nodeTypeId = 3
    const vertexId = 100n
    const nodeId = (BigInt(nodeTypeId) << 48n) | vertexId
    // node header: nodeId(8) + graphId(4) + padding(4)
    const nodeHeader = Buffer.concat([i64(nodeId), i32(1), Buffer.alloc(4)])
    // prop vector index special meta: 1 prop "name"; 1 element type; graph 1, type 3, 1 prop, vector index 0
    const specialMeta = Buffer.concat([
      u32(1), u16(4), Buffer.from('name'),
      u32(1), i32(1), u16(nodeTypeId), u32(1), i32(0),
    ])
    const vector: ProtoNestedVector = {
      num_nested_vectors: 1,
      common_meta_data: { num_records: 1, vector_content_type: 2 },
      special_meta_data: specialMeta,
      vector_data: nodeHeader,
      null_bit_map: null,
      nested_vectors: [flatVector([inlineString('Tom')])],
    }
    // column type: Node schema — 1 element type: graph 1, type id 3, 1 prop "name" of type String
    const columnType = Buffer.concat([
      Buffer.from([0x01]), // Node
      u32(1), i32(1), u16(nodeTypeId), u32(1), u16(4), Buffer.from('name'), Buffer.from([0x10]),
    ])
    const graphSchema: ProtoVectorResultTable['meta']['graph_schema'] = [
      {
        graph_id: 1,
        graph_name: Buffer.from('movie'),
        node_type: [
          { node_type_id: nodeTypeId, node_type_name: Buffer.from('Person'), label: [Buffer.from('Person'), Buffer.from('Actor')] },
        ],
        edge_type: [],
      },
    ]
    const decoded = decodeResultTable({
      data_layout_version: Buffer.from([1]),
      meta: {
        table_type: 0,
        num_records: '1',
        row_type: { num_columns: 1, column_names: ['v'], column_types: [{ value_type: columnType }] },
        num_batches: 1,
        time_zone_offset: 0,
        is_little_endian: true,
        graph_schema: graphSchema,
      },
      batch: [{ vectors: [vector] }],
    })
    // Node ids are composite int64s: top 16 bits carry the node type id.
    assert.deepEqual(decoded.rows, [
      [{ nodeId: Number(nodeId), graph: 'movie', type: 'Person', labels: ['Person', 'Actor'], properties: { name: 'Tom' } }],
    ])
    // ngql-style rendering includes the vertex form
    assert.equal(formatValue(decoded.rows[0][0]), `(${Number(nodeId)}@Person:Person&Actor{name:Tom})`)
  })

  it('renders an ngql-style table', () => {
    const t = table(
      ['name', 'age'],
      [0x10, 0x09],
      [flatVector([inlineString('alice'), inlineString('bob')]), flatVector([i32(30), i32(25)])],
    )
    const decoded = decodeResultTable(t)
    const out = renderTable(decoded.columns, decoded.rows)
    assert.match(out, /\| name  \| age \|/)
    assert.match(out, /\| alice \| 30  \|/)
    assert.match(out, /\| bob   \| 25  \|/)
  })
})

function u16(n: number): Buffer {
  const b = Buffer.alloc(2)
  b.writeUInt16LE(n, 0)
  return b
}
