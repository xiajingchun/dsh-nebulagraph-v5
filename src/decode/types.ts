/**
 * Column type codes used by the NebulaGraph 5.0 columnar result layout.
 *
 * These are the byte values that appear in a column's `ValueType.value_type`
 * payload and inside composite values. The mapping mirrors the official
 * nebula-go v5 `internal/decode` package (columnTypeMap) so that a result
 * table serialized by any NebulaGraph 5.0 server decodes identically.
 */
export const ColumnType = {
  Node: 0x01,
  Edge: 0x02,
  Unknown: 0x03,
  Bool: 0x04,
  Int8: 0x05,
  Uint8: 0x06,
  Int16: 0x07,
  Uint16: 0x08,
  Int32: 0x09,
  Uint32: 0x0a,
  Int64: 0x0b,
  Uint64: 0x0c,
  Float32: 0x0d,
  Float64: 0x0e,
  String: 0x10,
  List: 0x11,
  Path: 0x12,
  Record: 0x13,
  Vector: 0x14,
  LocalTime: 0x15,
  Duration: 0x16,
  Date: 0x17,
  LocalDatetime: 0x18,
  ZonedTime: 0x19,
  ZonedDatetime: 0x20,
  Decimal: 0x22,
  Geography: 0x24,
  Set: 0x25,
  Map: 0x26,
  Any: 0xfe,
  Invalid: 0xff,
} as const

export type ColumnTypeCode = (typeof ColumnType)[keyof typeof ColumnType]

/** Reverse lookup: byte value → symbolic name, for diagnostics and rendering. */
export const columnTypeName: Record<number, string> = Object.fromEntries(
  Object.entries(ColumnType).map(([name, code]) => [code, name]),
)

/** Vector layout kinds carried in `NestedVector.common_meta_data.vector_content_type`. */
export const VectorType = {
  Invalid: 0,
  Const: 1,
  Flat: 2,
  Parallel: 3,
} as const

/**
 * Parsed column schema. `List`/`Set`/`Map`/`Record`/`Vector`/`Node`/`Edge`/
 * `Path` carry nested type information that drives decoding; every other
 * column is a plain basic column.
 */
export type TypeSchema =
  | { kind: 'basic'; type: number }
  | { kind: 'list'; type: number; sub: TypeSchema }
  | { kind: 'set'; type: number; sub: TypeSchema }
  | { kind: 'map'; type: number; key: TypeSchema; value: TypeSchema }
  | { kind: 'vector'; type: number; dim: number; sub: TypeSchema }
  | { kind: 'record'; type: number; props: Map<string, TypeSchema> }
  | { kind: 'element'; type: number; props: GraphElementProps }
  | { kind: 'path'; type: number; node: GraphElementProps; edge: GraphElementProps; meta?: PathMeta }

/**
 * Property schema for node/edge element types, keyed by graph id then
 * element type id then property name. `vectorIndex` is the index of the
 * nested vector that holds the property's values.
 */
export interface PropSchema {
  name: string
  schema: TypeSchema
  vectorIndex: number
}
export type ElementProps = Map<string, PropSchema>
export type ElementTypeProps = Map<number, ElementProps>
export type GraphElementProps = Map<number, ElementTypeProps>

/** Graph schema information from `VectorTableMetaData.graph_schema`. */
export interface GraphSchema {
  name: string
  id: number
  nodes: Map<number, ElementSchema>
  edges: Map<number, ElementSchema>
}
export interface ElementSchema {
  typeName: string
  typeId: number
  labels: string[]
}

/** Path adjacency metadata parsed from a path column's special meta data. */
export interface PathMeta {
  nodePairIndex: Map<number, PathPair>
  edgePairIndex: Map<number, PathPair>
}
export interface PathPair {
  cur: number
  adj: number
}

/** Per-vector context needed while decoding rows of one result table. */
export interface DecodeContext {
  /** Server time zone offset in seconds (from `VectorTableMetaData.time_zone_offset` minutes). */
  timezoneOffset: number
  graphsSchema: Map<number, GraphSchema>
}

/** Edges carry a direction encoded in the top bits of the edge type id. */
export enum EdgeDirection {
  Outgoing = 0,
  Incoming = 1,
  NoDirection = 2,
}
