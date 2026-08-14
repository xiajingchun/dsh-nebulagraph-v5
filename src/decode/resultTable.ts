/**
 * Top-level decoder for a NebulaGraph 5.0 `VectorResultTable`: converts the
 * protobuf-decoded table into column names and JSON-ready rows.
 *
 * Port of nebula-go v5 `internal/decode/resultTable.go`. The gRPC layer
 * passes the deserialized `ExecuteResponse.result` here; the payload shapes
 * follow `@grpc/proto-loader` defaults (bytes → Buffer, uint32/int32 →
 * number, int64/uint64 → string unless configured otherwise).
 */

import { BytesReader } from './bytes.ts'
import { newTypeSchema } from './columnType.ts'
import type { DecodeContext, GraphSchema, TypeSchema } from './types.ts'
import { ColumnType } from './types.ts'
import { decodePathSpecialData, decodePropVectorIndex, decodeValue } from './value.ts'
import type { NestedVectorLike } from './value.ts'

/** Nested-vector wire shapes as produced by proto-loader. */
export interface ProtoNestedVector {
  num_nested_vectors: number
  common_meta_data: { num_records: number; vector_content_type: number } | null
  special_meta_data: Buffer
  vector_data: Buffer
  null_bit_map: Buffer | null
  nested_vectors: ProtoNestedVector[]
}

export interface ProtoVectorBatch {
  vectors: ProtoNestedVector[]
}

export interface ProtoVectorResultTable {
  data_layout_version: Buffer
  meta: {
    table_type: number
    num_records: string | number
    row_type: { num_columns: number; column_names: string[]; column_types: { value_type: Buffer }[] } | null
    num_batches: number
    time_zone_offset: number
    is_little_endian: boolean
    graph_schema: ProtoPropertyGraphSchema[] | null
  }
  batch: ProtoVectorBatch[]
}

export interface ProtoPropertyGraphSchema {
  graph_id: number
  graph_name: Buffer
  node_type: { node_type_id: number; node_type_name: Buffer; label: Buffer[] }[]
  edge_type: { edge_type_id: number; edge_type_name: Buffer; label: Buffer[] }[]
}

/** A decoded result table: column names plus one array of row values per row. */
export interface DecodedTable {
  columns: string[]
  rows: unknown[][]
  numRecords: number
}

/** Convert a proto NestedVector to the shape the value decoder expects. */
function toNestedVector(v: ProtoNestedVector): NestedVectorLike {
  // The server may omit common_meta_data on auxiliary nested vectors (string
  // chunks, property vectors); the official Go client treats the nil proto
  // field as zero values.
  const common = v.common_meta_data ?? { num_records: 0, vector_content_type: 0 }
  return {
    common_meta_data: { num_records: common.num_records, vector_content_type: common.vector_content_type },
    special_meta_data: toU8(v.special_meta_data),
    vector_data: toU8(v.vector_data),
    null_bit_map: v.null_bit_map === null || v.null_bit_map === undefined ? null : toU8(v.null_bit_map),
    nested_vectors: (v.nested_vectors ?? []).map(toNestedVector),
  }
}

function toU8(b: Buffer): Uint8Array {
  // proto-loader gives Buffer (a Uint8Array subclass); keep the same bytes.
  return b
}

/**
 * Decode a full `VectorResultTable` into columns and rows.
 *
 * @param table - the proto-decoded result table (may be null/undefined).
 * @returns column names and rows; an empty table when the payload is absent.
 */
export function decodeResultTable(table: ProtoVectorResultTable | null | undefined): DecodedTable {
  if (table === null || table === undefined || table.meta === null || table.meta === undefined) {
    return { columns: [], rows: [], numRecords: 0 }
  }
  const meta = table.meta
  const columns: string[] = meta.row_type?.column_names ?? []
  const schemas: TypeSchema[] = []
  for (const ct of meta.row_type?.column_types ?? []) {
    schemas.push(newTypeSchema(new BytesReader(toU8(ct.value_type))))
  }

  const ctx: DecodeContext = {
    timezoneOffset: Number(meta.time_zone_offset) * 60,
    graphsSchema: buildGraphsSchema(meta.graph_schema),
  }

  const batches = table.batch ?? []
  const rows: unknown[][] = []
  for (const batch of batches) {
    const vectors = (batch.vectors ?? []).map(toNestedVector)
    if (vectors.length === 0) continue
    const numRecords = vectors[0].common_meta_data.num_records
    // Prepare per-column decode state: vector kind + element/path meta.
    const prepared = vectors.map((vector, colIndex) => {
      const schema = schemas[colIndex] ?? { kind: 'basic', type: ColumnType.Unknown }
      const content = vector.common_meta_data.vector_content_type
      const vectorType = content & 0xff
      const nullAllSet = (content & (1 << 8)) !== 0
      prepareVector(schema, vector)
      return { schema, vectorType, nullAllSet, vector, cachedConst: { value: undefined } as { value: unknown } }
    })
    for (let rowIndex = 0; rowIndex < numRecords; rowIndex++) {
      const row: unknown[] = new Array(prepared.length)
      for (let colIndex = 0; colIndex < prepared.length; colIndex++) {
        const p = prepared[colIndex]
        row[colIndex] = decodeValue(ctx, p.vector, p.vectorType, rowIndex, p.schema, p.cachedConst)
      }
      rows.push(row)
    }
  }
  return { columns, rows, numRecords: rows.length }
}

/**
 * Stamp per-vector meta (element property vector indices, path adjacency
 * pairs) onto the column schema before rows decode. Mirrors the Go client's
 * `vectorWrapper.prepare()`.
 *
 * @param schema - the parsed column schema (mutated in place).
 * @param vector - the batch's vector for this column.
 */
function prepareVector(schema: TypeSchema, vector: NestedVectorLike): void {
  if (schema.kind === 'element') {
    decodePropVectorIndex(schema.props, vector.special_meta_data, schema.type === ColumnType.Node)
  } else if (schema.kind === 'path') {
    const nodePairs = new Map<number, { cur: number; adj: number }>()
    const edgePairs = new Map<number, { cur: number; adj: number }>()
    decodePathSpecialData(vector.special_meta_data, nodePairs, edgePairs)
    schema.meta = { nodePairIndex: nodePairs, edgePairIndex: edgePairs }
  }
}

function buildGraphsSchema(gs: ProtoPropertyGraphSchema[] | null): Map<number, GraphSchema> {
  const result = new Map<number, GraphSchema>()
  if (gs === null || gs === undefined) return result
  for (const g of gs) {
    const nodes = new Map<number, { typeName: string; typeId: number; labels: string[] }>()
    for (const n of g.node_type ?? []) {
      nodes.set(n.node_type_id, {
        typeName: n.node_type_name.toString(),
        typeId: n.node_type_id,
        labels: (n.label ?? []).map((l) => l.toString()),
      })
    }
    const edges = new Map<number, { typeName: string; typeId: number; labels: string[] }>()
    for (const e of g.edge_type ?? []) {
      edges.set(e.edge_type_id, {
        typeName: e.edge_type_name.toString(),
        typeId: e.edge_type_id,
        labels: (e.label ?? []).map((l) => l.toString()),
      })
    }
    result.set(g.graph_id, { name: g.graph_name.toString(), id: g.graph_id, nodes, edges })
  }
  return result
}
