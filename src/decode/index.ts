/**
 * NebulaGraph 5.0 columnar result-table decoder.
 *
 * Public entry: {@link decodeResultTable}. Everything else is internal
 * machinery ported from nebula-go v5 `internal/decode`.
 */

export { decodeResultTable } from './resultTable.ts'
export type { DecodedTable, ProtoVectorResultTable, ProtoNestedVector, ProtoVectorBatch, ProtoPropertyGraphSchema } from './resultTable.ts'
export { ColumnType, VectorType, EdgeDirection, columnTypeName } from './types.ts'
export type { TypeSchema, DecodeContext, GraphSchema, ElementSchema, PathMeta, PropSchema, ElementProps, GraphElementProps } from './types.ts'
export { BytesReader, bytesToInt8, bytesToInt16, bytesToInt32, bytesToInt64Big, bytesToUint16, bytesToUint32, bytesToUint64Big, downcastBigInt } from './bytes.ts'
export { newTypeSchema, utf8 } from './columnType.ts'
export { decodeValue, decodeAnyCompositeValue, decodeBasicValue, decodePathSpecialData, decodePropVectorIndex } from './value.ts'
export type { NodeValue, EdgeValue, PathValue, NestedVectorLike } from './value.ts'
