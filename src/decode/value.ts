/**
 * Per-value decoding for the NebulaGraph 5.0 columnar result layout.
 *
 * Port of nebula-go v5 `internal/decode/resultTable_helper.go`,
 * `value_nebula.go` (formatting) and `utils.go` (geography). Decoded values
 * are plain JSON-ready values:
 *
 * - `null` for NULL / unknown values
 * - `boolean`, `number`, `string` for scalars
 * - temporal values are rendered with ngql's literal formats
 *   (`2019-01-01`, `12:34:56.123456`, `2019-01-01T12:34:56.123456`, zoned
 *   variants with `+08:00` suffix, durations as `P1Y2M3DT4H5M6.123456S`)
 * - `number[]` for embedding vectors
 * - node/edge/path objects carrying ids, schema names, labels, properties
 * - geography objects (point / line-string / polygon) when the shape is
 *   supported
 *
 * int64/uint64 values outside the JS safe-integer range are returned as
 * decimal strings so no precision is lost in JSON.
 */

import {
  BytesReader,
  bytesToFloat32,
  bytesToFloat64,
  bytesToInt8,
  bytesToInt16,
  bytesToInt32,
  bytesToInt64Big,
  bytesToUint16,
  bytesToUint32,
  bytesToUint64Big,
  downcastBigInt,
} from './bytes.ts'
import { utf8 } from './columnType.ts'
import type { DecodeContext, ElementProps, GraphElementProps, GraphSchema, PathMeta, PropSchema, TypeSchema } from './types.ts'
import { ColumnType, columnTypeName, EdgeDirection, VectorType } from './types.ts'

/** Nested vector wire shape (protobuf `nebula.proto.vector.NestedVector`). */
export interface NestedVectorLike {
  common_meta_data: { num_records: number; vector_content_type: number }
  special_meta_data: Uint8Array
  vector_data: Uint8Array
  null_bit_map: Uint8Array | null
  nested_vectors: NestedVectorLike[]
}

/** Basic column byte widths (fixed-size types). */
const sizeMap: Record<number, number> = {
  [ColumnType.Bool]: 1,
  [ColumnType.Int8]: 1,
  [ColumnType.Uint8]: 1,
  [ColumnType.Int16]: 2,
  [ColumnType.Uint16]: 2,
  [ColumnType.Int32]: 4,
  [ColumnType.Uint32]: 4,
  [ColumnType.Int64]: 8,
  [ColumnType.Uint64]: 8,
  [ColumnType.Float32]: 4,
  [ColumnType.Float64]: 8,
  [ColumnType.Date]: 4,
  [ColumnType.LocalTime]: 8,
  [ColumnType.ZonedTime]: 8,
  [ColumnType.LocalDatetime]: 8,
  [ColumnType.ZonedDatetime]: 8,
  [ColumnType.Duration]: 8,
}

/** Basic (fixed-size) column types that decode straight from bytes. */
function isBasicColumnType(code: number): boolean {
  switch (code) {
    case ColumnType.Bool:
    case ColumnType.Int8:
    case ColumnType.Int16:
    case ColumnType.Int32:
    case ColumnType.Int64:
    case ColumnType.Uint8:
    case ColumnType.Uint16:
    case ColumnType.Uint32:
    case ColumnType.Uint64:
    case ColumnType.Float32:
    case ColumnType.Float64:
    case ColumnType.LocalTime:
    case ColumnType.LocalDatetime:
    case ColumnType.ZonedTime:
    case ColumnType.ZonedDatetime:
    case ColumnType.Date:
    case ColumnType.Duration:
      return true
    default:
      return false
  }
}

const oneBitmasks = [1, 2, 4, 8, 16, 32, 64, 128]

/** True when the bit for `index` is set in the null bitmap (set bit = value present). */
function nullBitSet(bitmap: Uint8Array, index: number): boolean {
  return (bitmap[index >> 3] & oneBitmasks[index & 7]) !== 0
}

function pad2(n: number): string {
  return n < 0 ? `-${pad2(-n)}` : n < 10 ? `0${n}` : String(n)
}
function pad4(n: number): string {
  const s = n < 0 ? -n : n
  const base = s < 10 ? `000${s}` : s < 100 ? `00${s}` : s < 1000 ? `0${s}` : String(s)
  return n < 0 ? `-${base}` : base
}
function pad6(n: number): string {
  const s = n < 0 ? -n : n
  const base = s < 10 ? `00000${s}` : s < 100 ? `0000${s}` : s < 1000 ? `000${s}` : s < 10000 ? `00${s}` : s < 100000 ? `0${s}` : String(s)
  return n < 0 ? `-${base}` : base
}

/** Render a zone offset in seconds as `+08:00` / `-05:30` / `Z`. */
function zoneSuffix(offsetSeconds: number): string {
  if (offsetSeconds === 0) return 'Z'
  const sign = offsetSeconds < 0 ? '-' : '+'
  const abs = Math.abs(offsetSeconds)
  const hours = Math.floor(abs / 3600)
  const minutes = Math.floor((abs % 3600) / 60)
  return `${sign}${pad2(hours)}:${pad2(minutes)}`
}

/** Shift a UTC wall-clock by a fixed zone offset (seconds) and re-read components. */
function shiftByOffset(
  offsetSeconds: number,
  year: number, month: number, day: number, hour: number, minute: number, sec: number, microsec: number,
): { year: number; month: number; day: number; hour: number; minute: number; sec: number; microsec: number } {
  const ms = Date.UTC(year, month - 1, day, hour, minute, sec, Math.trunc(microsec / 1000)) + offsetSeconds * 1000
  const d = new Date(ms)
  return {
    year: d.getUTCFullYear(),
    month: d.getUTCMonth() + 1,
    day: d.getUTCDate(),
    hour: d.getUTCHours(),
    minute: d.getUTCMinutes(),
    sec: d.getUTCSeconds(),
    microsec: microsec % 1000 + d.getUTCMilliseconds() * 1000,
  }
}

const microsecondsPerDay = 24 * 60 * 60 * 1_000_000
const microsecondsPerHour = 60 * 60 * 1_000_000
const microsecondsPerMinute = 60 * 1_000_000
const microsecondsPerSecond = 1_000_000

/**
 * Decode one basic (fixed-size) value from its bytes.
 *
 * @param bs - the value bytes (at least `sizeMap[type]` long).
 * @param type - the column type code.
 * @param timezoneOffset - server zone offset in seconds, for zoned types.
 * @returns the decoded plain value.
 */
export function decodeBasicValue(bs: Uint8Array, type: number, timezoneOffset: number): unknown {
  switch (type) {
    case ColumnType.Bool:
      return bs[0] === 1
    case ColumnType.Int8:
      return bytesToInt8(bs.subarray(0, 1))
    case ColumnType.Int16:
      return bytesToInt16(bs.subarray(0, 2))
    case ColumnType.Int32:
      return bytesToInt32(bs.subarray(0, 4))
    case ColumnType.Int64:
      return int64ToJson(bytesToInt64Big(bs.subarray(0, 8)))
    case ColumnType.Uint8:
      return bs[0]
    case ColumnType.Uint16:
      return bytesToUint16(bs.subarray(0, 2))
    case ColumnType.Uint32:
      return bytesToUint32(bs.subarray(0, 4))
    case ColumnType.Uint64:
      return uint64ToJson(bytesToUint64Big(bs.subarray(0, 8)))
    case ColumnType.Float32:
      return bytesToFloat32(bs)
    case ColumnType.Float64:
      return bytesToFloat64(bs)
    case ColumnType.String:
      return utf8(bs)
    case ColumnType.Decimal:
      return utf8(bs)
    case ColumnType.Date:
      return `${pad4(bytesToInt16(bs.subarray(0, 2)))}-${pad2(bytesToInt8(bs.subarray(2, 3)))}-${pad2(bytesToInt8(bs.subarray(3, 4)))}`
    case ColumnType.LocalTime: {
      const hour = bytesToInt8(bs.subarray(0, 1))
      const minute = bytesToInt8(bs.subarray(1, 2))
      const sec = bytesToInt8(bs.subarray(2, 3))
      const microsec = bytesToInt32(bs.subarray(4, 8))
      return `${pad2(hour)}:${pad2(minute)}:${pad2(sec)}.${pad6(microsec)}`
    }
    case ColumnType.ZonedTime: {
      const hour = bytesToInt8(bs.subarray(0, 1))
      const minute = bytesToInt8(bs.subarray(1, 2))
      const sec = bytesToInt8(bs.subarray(2, 3))
      const microsec = bytesToInt32(bs.subarray(4, 8))
      // The official client pins the date to "today" while shifting; the
      // resulting time-of-day is what matters for a time-only value.
      const now = new Date()
      const shifted = shiftByOffset(timezoneOffset, now.getUTCFullYear(), now.getUTCMonth() + 1, now.getUTCDate(), hour, minute, sec, microsec)
      return `${pad2(shifted.hour)}:${pad2(shifted.minute)}:${pad2(shifted.sec)}.${pad6(shifted.microsec)}${zoneSuffix(timezoneOffset)}`
    }
    case ColumnType.LocalDatetime:
      return formatLocalDatetime(bytesToInt64Big(bs.subarray(0, 8)))
    case ColumnType.ZonedDatetime: {
      const qword = bytesToInt64Big(bs.subarray(0, 8))
      const { year, month, day, hour, minute, sec, microsec } = unpackDatetime(qword)
      const shifted = shiftByOffset(timezoneOffset, year, month, day, hour, minute, sec, microsec)
      return `${pad4(shifted.year)}-${pad2(shifted.month)}-${pad2(shifted.day)}T${pad2(shifted.hour)}:${pad2(shifted.minute)}:${pad2(shifted.sec)}.${pad6(shifted.microsec)}${zoneSuffix(timezoneOffset)}`
    }
    case ColumnType.Duration:
      return formatDuration(bytesToInt64Big(bs.subarray(0, 8)))
    default:
      return null
  }
}

function unpackDatetime(qword: bigint): { year: number; month: number; day: number; hour: number; minute: number; sec: number; microsec: number } {
  return {
    year: Number(qword & 0xffffn),
    month: Number((qword >> 16n) & 0xfn),
    day: Number((qword >> 20n) & 0x1fn),
    hour: Number((qword >> 25n) & 0x1fn),
    minute: Number((qword >> 30n) & 0x3fn),
    sec: Number((qword >> 36n) & 0x3fn),
    microsec: Number((qword >> 42n) & 0x3ffffffn),
  }
}

function formatLocalDatetime(qword: bigint): string {
  const { year, month, day, hour, minute, sec, microsec } = unpackDatetime(qword)
  return `${pad4(year)}-${pad2(month)}-${pad2(day)}T${pad2(hour)}:${pad2(minute)}:${pad2(sec)}.${pad6(microsec)}`
}

/** ngql-compatible duration literal, e.g. `P1Y2M3DT4H5M6.123456S`. */
function formatDuration(raw: bigint): string {
  const isMonthBased = (raw & 1n) === 1n
  const value = raw >> 1n
  let prefix = 'P'
  if (isMonthBased) {
    const year = Number(value / 12n)
    const month = Number(value % 12n)
    if (year !== 0) prefix += `${year}Y`
    if (month !== 0) prefix += `${month}M`
    if (year === 0 && month === 0) prefix += '0M'
  } else {
    const day = Number(value / BigInt(microsecondsPerDay))
    const hour = Number((value % BigInt(microsecondsPerDay)) / BigInt(microsecondsPerHour))
    const minute = Number((value % BigInt(microsecondsPerHour)) / BigInt(microsecondsPerMinute))
    const sec = Number((value % BigInt(microsecondsPerMinute)) / BigInt(microsecondsPerSecond))
    const microsec = Number(value % BigInt(microsecondsPerSecond))
    if (day !== 0) prefix += `${day}D`
    if (hour !== 0 || minute !== 0 || sec !== 0 || microsec !== 0) prefix += 'T'
    if (hour !== 0) prefix += `${hour}H`
    if (minute !== 0) prefix += `${minute}M`
    if (sec !== 0 || microsec !== 0) {
      if (microsec === 0) prefix += `${sec}S`
      else {
        let ms = sec * 1_000_000 + microsec
        const isMinus = sec < 0 || microsec < 0
        if (isMinus) ms = -ms
        let s = Math.trunc(ms / 1_000_000)
        let ss = ms % 1_000_000
        if (isMinus) {
          s = -s
          ss = -ss
        }
        prefix += `${s}.${pad6(ss)}`
        prefix = prefix.replace(/0+$/, '')
        prefix += 'S'
      }
    }
    if (day === 0 && hour === 0 && minute === 0 && sec === 0 && microsec === 0) prefix += 'T0S'
  }
  return prefix
}

function int64ToJson(value: bigint): number | string {
  const n = downcastBigInt(value)
  return typeof n === 'bigint' ? n.toString() : n
}
function uint64ToJson(value: bigint): number | string {
  const n = downcastBigInt(value)
  return typeof n === 'bigint' ? n.toString() : n
}

/** Node value in the canonical JSON result. */
export interface NodeValue {
  nodeId: number | string
  graph: string
  type: string
  labels: string[]
  properties: Record<string, unknown>
}

/** Edge value in the canonical JSON result. */
export interface EdgeValue {
  srcId: number | string
  dstId: number | string
  rank: number | string
  direction: 'outgoing' | 'incoming' | 'none'
  graph: string
  type: string
  labels: string[]
  properties: Record<string, unknown>
}

/** Path value in the canonical JSON result: alternating nodes and edges. */
export interface PathValue {
  elements: unknown[]
}

/**
 * Decode a value from a vector at a row index.
 *
 * @param ctx - table decode context (zone offset + graph schema).
 * @param vector - the nested vector holding the column's data.
 * @param vectorType - the vector layout kind (flat/const).
 * @param index - row index inside the vector.
 * @param schema - the column's parsed type schema.
 * @param cachedConst - shared cache for const-vector values (one per column).
 * @returns the decoded plain value.
 */
export function decodeValue(
  ctx: DecodeContext,
  vector: NestedVectorLike,
  vectorType: number,
  index: number,
  schema: TypeSchema,
  cachedConst: { value: unknown } | null,
): unknown {
  if (vectorType === VectorType.Const) {
    // The official client caches the first decoded row (including a null from
    // the null bitmap) and replays it for every later row.
    if (cachedConst !== null && cachedConst.value !== undefined) return cachedConst.value
    let value: unknown
    if (hasNullBitmap(vector) && !nullBitSet(vector.null_bit_map as Uint8Array, index)) {
      value = null
    } else {
      value = decodeConstValue(ctx, vector, schema)
    }
    if (cachedConst !== null) cachedConst.value = value
    return value
  }
  if (hasNullBitmap(vector) && !nullBitSet(vector.null_bit_map as Uint8Array, index)) {
    return null
  }
  if (vectorType === VectorType.Flat) return decodeFlatValue(ctx, vector, index, schema)
  throw new Error(`invalid vector type: ${vectorType}`)
}

/** Whether the vector carries a meaningful null bitmap (proto-loader pads unset bytes with an empty buffer). */
function hasNullBitmap(vector: NestedVectorLike): boolean {
  const bm = vector.null_bit_map
  return bm !== null && bm !== undefined && bm.length > 0
}

function decodeConstValue(ctx: DecodeContext, vector: NestedVectorLike, schema: TypeSchema): unknown {
  const r = new BytesReader(vector.vector_data)
  if (isBasicColumnType(schema.type)) {
    const size = sizeMap[schema.type]
    return decodeBasicValue(r.readN(size), schema.type, ctx.timezoneOffset)
  }
  return decodeAnyCompositeValue(ctx, r, schema.type)
}

function decodeFlatValue(ctx: DecodeContext, vector: NestedVectorLike, index: number, schema: TypeSchema): unknown {
  switch (schema.type) {
    case ColumnType.String:
    case ColumnType.Decimal:
      return decodeChunkedString(vector, index, schema.type)
    case ColumnType.Node:
      return decodeNode(ctx, vector, index, schema)
    case ColumnType.Edge:
      return decodeEdge(ctx, vector, index, schema)
    case ColumnType.Path:
      return decodePath(ctx, vector, index, schema)
    case ColumnType.List:
      return decodeListOrSet(ctx, vector, index, schema, 'list')
    case ColumnType.Set:
      return decodeListOrSet(ctx, vector, index, schema, 'set')
    case ColumnType.Map:
      return decodeMap(ctx, vector, index, schema)
    case ColumnType.Record:
      return decodeRecord(ctx, vector, index, schema)
    case ColumnType.Vector:
      return decodeEmbeddingVector(vector, index, schema)
    case ColumnType.Geography:
      return decodeGeography(vector, index)
    case ColumnType.Any:
      return decodeAnyValue(ctx, vector, index)
    case ColumnType.Unknown:
      return null
    default:
      if (isBasicColumnType(schema.type)) {
        const size = sizeMap[schema.type]
        const bs = vector.vector_data.subarray(index * size, index * size + size)
        return decodeBasicValue(bs, schema.type, ctx.timezoneOffset)
      }
      return null
  }
}

/** String/decimal flat layout: 16-byte header, inline prefix or chunk reference. */
function decodeChunkedString(vector: NestedVectorLike, index: number, type: number): string {
  const header = vector.vector_data.subarray(index * 16, index * 16 + 16)
  const strLen = bytesToUint32(header.subarray(0, 4))
  if (strLen <= 12) {
    return utf8(header.subarray(4, 4 + strLen))
  }
  const chunkIndex = bytesToUint32(header.subarray(12, 16))
  const chunkOffset = bytesToUint32(header.subarray(8, 12))
  const chunk = vector.nested_vectors[chunkIndex]
  const data = chunk.vector_data.subarray(chunkOffset, chunkOffset + strLen)
  return utf8(data)
}

function decodeNode(ctx: DecodeContext, vector: NestedVectorLike, index: number, schema: TypeSchema): NodeValue {
  if (schema.kind !== 'element') throw new Error('node column schema is not an element schema')
  const header = vector.vector_data.subarray(index * 16, index * 16 + 16)
  const nodeId = int64ToJson(bytesToInt64Big(header.subarray(0, 8)))
  const graphId = bytesToInt32(header.subarray(8, 12))
  const nodeTypeId = Number(bytesToInt64Big(header.subarray(0, 8)) >> 48n)
  return decodeElementWithProps(ctx, vector, index, schema.props, graphId, nodeTypeId, (names, props) => ({
    nodeId,
    graph: names.graph,
    type: names.type,
    labels: names.labels,
    properties: props,
  }))
}

function decodeEdge(ctx: DecodeContext, vector: NestedVectorLike, index: number, schema: TypeSchema): EdgeValue {
  if (schema.kind !== 'element') throw new Error('edge column schema is not an element schema')
  const header = vector.vector_data.subarray(index * 32, index * 32 + 32)
  const srcId = int64ToJson(bytesToInt64Big(header.subarray(0, 8)))
  const dstId = int64ToJson(bytesToInt64Big(header.subarray(8, 16)))
  const rank = int64ToJson(bytesToInt64Big(header.subarray(16, 24)))
  const graphId = bytesToInt32(header.subarray(24, 28))
  const edgeTypeId = bytesToInt32(header.subarray(28, 32))
  const noDirectType = edgeTypeId & 0x3fffffff
  const direction = getEdgeDirection(edgeTypeId >> 30)
  return decodeElementWithProps(ctx, vector, index, schema.props, graphId, noDirectType, (names, props) => {
    const outgoing = direction === EdgeDirection.Incoming
    return {
      srcId: outgoing ? dstId : srcId,
      dstId: outgoing ? srcId : dstId,
      rank,
      direction: direction === EdgeDirection.Outgoing ? 'outgoing' : direction === EdgeDirection.Incoming ? 'incoming' : 'none',
      graph: names.graph,
      type: names.type,
      labels: names.labels,
      properties: props,
    }
  })
}

/** Shared node/edge decoding: resolve the element schema names + property vectors. */
function decodeElementWithProps<T>(
  ctx: DecodeContext,
  vector: NestedVectorLike,
  index: number,
  elementPropsByGraph: GraphElementProps,
  graphId: number,
  elementTypeId: number,
  build: (names: { graph: string; type: string; labels: string[] }, properties: Record<string, unknown>) => T,
): T {
  const props = elementPropsByGraph.get(graphId)?.get(elementTypeId)
  if (props === undefined) throw new Error(`element type not found: graph ${graphId}, type ${elementTypeId}`)
  const names = getSchemaName(ctx.graphsSchema, graphId, elementTypeId, true)
  const properties: Record<string, unknown> = {}
  for (const prop of props.values()) {
    const nested = vector.nested_vectors[prop.vectorIndex]
    properties[prop.name] = decodeFlatValue(ctx, nested, index, prop.schema)
  }
  return build(names, properties)
}

function getSchemaName(
  graphsSchema: Map<number, GraphSchema>,
  graphId: number,
  elementTypeId: number,
  isNode: boolean,
): { graph: string; type: string; labels: string[] } {
  const gs = graphsSchema.get(graphId)
  if (gs === undefined) throw new Error(`graph not found: ${graphId}`)
  const es = (isNode ? gs.nodes : gs.edges).get(elementTypeId)
  if (es === undefined) throw new Error(`element id not found: ${elementTypeId}`)
  return { graph: gs.name, type: es.typeName, labels: es.labels }
}

function getEdgeDirection(d: number): EdgeDirection {
  switch (d) {
    case 0: return EdgeDirection.Outgoing
    case 1: return EdgeDirection.Incoming
    default: return EdgeDirection.NoDirection
  }
}

function decodeListOrSet(ctx: DecodeContext, vector: NestedVectorLike, index: number, schema: TypeSchema, kind: 'list' | 'set'): unknown[] {
  const header = vector.vector_data.subarray(index * 8, index * 8 + 8)
  const offset = bytesToUint32(header.subarray(0, 4))
  const size = bytesToUint32(header.subarray(4, 8))
  const sub = kind === 'list' && schema.kind === 'list' ? schema.sub : schema.kind === 'set' ? schema.sub : schema
  const dataVector = vector.nested_vectors[0]
  const values: unknown[] = new Array(size)
  for (let i = 0; i < size; i++) {
    values[i] = decodeValue(ctx, dataVector, VectorType.Flat, offset + i, sub, null)
  }
  return values
}

function decodeMap(ctx: DecodeContext, vector: NestedVectorLike, index: number, schema: TypeSchema): Record<string, unknown> {
  if (schema.kind !== 'map') throw new Error('map column schema is not a map schema')
  const header = vector.vector_data.subarray(index * 8, index * 8 + 8)
  const offset = bytesToUint32(header.subarray(0, 4))
  const size = bytesToUint32(header.subarray(4, 8))
  const result: Record<string, unknown> = {}
  for (let i = 0; i < size; i++) {
    const key = decodeValue(ctx, vector.nested_vectors[0], VectorType.Flat, offset + i, schema.key, null)
    const value = decodeValue(ctx, vector.nested_vectors[1], VectorType.Flat, offset + i, schema.value, null)
    result[String(key)] = value
  }
  return result
}

function decodeRecord(ctx: DecodeContext, vector: NestedVectorLike, index: number, schema: TypeSchema): Record<string, unknown> {
  if (schema.kind !== 'record') throw new Error('record column schema is not a record schema')
  // Property names ride in the vector's special meta data: 2-byte length + bytes per prop.
  const r = new BytesReader(vector.special_meta_data)
  const names: string[] = []
  for (let i = 0; i < schema.props.size; i++) {
    const size = bytesToInt16(r.readN(2))
    names.push(utf8(r.readN(size)))
  }
  const result: Record<string, unknown> = {}
  for (let i = 0; i < names.length; i++) {
    const propSchema = schema.props.get(names[i])
    if (propSchema === undefined) throw new Error(`prop not found: ${names[i]}`)
    const nested = vector.nested_vectors[i]
    result[names[i]] = decodeValue(ctx, nested, VectorType.Flat, index, propSchema, null)
  }
  return result
}

function decodeEmbeddingVector(vector: NestedVectorLike, index: number, schema: TypeSchema): number[] {
  if (schema.kind !== 'vector') throw new Error('vector column schema is not a vector schema')
  const dim = schema.dim
  const offset = index * dim * 4
  const values: number[] = new Array(dim)
  for (let i = 0; i < dim; i++) {
    values[i] = bytesToFloat32(vector.vector_data.subarray(offset + i * 4, offset + i * 4 + 4))
  }
  return values
}

function decodeGeography(vector: NestedVectorLike, index: number): unknown {
  const header = vector.vector_data.subarray(index * 8, index * 8 + 8)
  const chunkIndex = bytesToUint32(header.subarray(0, 4))
  const chunkOffset = bytesToInt32(header.subarray(4, 8))
  const chunk = vector.nested_vectors[chunkIndex]
  const r = new BytesReader(chunk.vector_data.subarray(chunkOffset))
  return decodeGeographyData(r)
}

function decodeGeographyData(r: BytesReader): unknown {
  const shape = bytesToInt8(r.readN(1))
  const srid = bytesToInt32(r.readN(4))
  const readPoint = (): { lng: number; lat: number } => {
    const x = bytesToFloat64(r.readN(8))
    const y = bytesToFloat64(r.readN(8))
    return { lng: x, lat: y }
  }
  switch (shape) {
    case 0: { // PointP
      return { shape: 'Point', srid, point: readPoint() }
    }
    case 4: { // LineStringL
      const numCoords = bytesToInt32(r.readN(4))
      const coords: { lng: number; lat: number }[] = []
      for (let i = 0; i < numCoords; i++) coords.push(readPoint())
      return { shape: 'LineString', srid, coords }
    }
    case 8: { // PolygonP
      const loops = bytesToInt32(r.readN(4))
      const rowIndexes: number[] = []
      for (let i = 0; i < loops + 1; i++) rowIndexes.push(bytesToInt32(r.readN(4)))
      const numCoords = rowIndexes[loops]
      const coords: { lng: number; lat: number }[] = []
      for (let i = 0; i < numCoords; i++) coords.push(readPoint())
      const polygons: { lng: number; lat: number }[][] = []
      for (let i = 0; i < loops; i++) {
        const start = rowIndexes[i]
        const end = rowIndexes[i + 1]
        if (start < end && start < coords.length && end <= coords.length) polygons.push(coords.slice(start, end))
      }
      return { shape: 'Polygon', srid, polygons }
    }
    default:
      throw new Error(`unsupported geography shape: ${shape}`)
  }
}

/** ColumnType.Any: each row carries its own type byte and data location. */
function decodeAnyValue(ctx: DecodeContext, vector: NestedVectorLike, index: number): unknown {
  const dataTypeVector = vector.nested_vectors[0]
  const typeByte = dataTypeVector.vector_data[index]
  const dataType = columnTypeName[typeByte]
  if (dataType === undefined) throw new Error(`invalid column type: ${typeByte}`)
  const dataBytes = vector.vector_data.subarray(index * 8, index * 8 + 8)
  if (isBasicColumnType(typeByte)) {
    return decodeBasicValue(dataBytes, typeByte, ctx.timezoneOffset)
  }
  const chunkIndex = bytesToUint32(dataBytes.subarray(0, 4))
  const chunkOffset = bytesToUint32(dataBytes.subarray(4, 8))
  const r = new BytesReader(vector.nested_vectors[chunkIndex + 1].vector_data)
  r.readN(chunkOffset)
  return decodeAnyCompositeValue(ctx, r, typeByte)
}

/**
 * Decode a composite (non-basic) value from a byte stream. Used by const
 * vectors and `Any` columns, where values are serialized inline with their
 * own type tags.
 *
 * @param ctx - table decode context.
 * @param r - the reader positioned at the value.
 * @param type - the value's column type code.
 * @returns the decoded plain value.
 */
export function decodeAnyCompositeValue(ctx: DecodeContext, r: BytesReader, type: number): unknown {
  if (isBasicColumnType(type)) {
    const size = sizeMap[type]
    return decodeBasicValue(r.readN(size), type, ctx.timezoneOffset)
  }
  switch (type) {
    case ColumnType.Unknown:
      return null
    case ColumnType.String:
    case ColumnType.Decimal: {
      const size = bytesToUint16(r.readN(2))
      return utf8(r.readN(size))
    }
    case ColumnType.List:
    case ColumnType.Set: {
      const subType = r.readN(1)[0]
      const size = type === ColumnType.List ? bytesToUint16(r.readN(2)) : bytesToUint32(r.readN(4))
      const bitSize = Math.ceil(size / 8)
      const nullBytes = r.readN(bitSize)
      const values: unknown[] = new Array(size)
      for (let i = 0; i < size; i++) {
        values[i] = (nullBytes[i >> 3] & oneBitmasks[i & 7]) === 0
          ? null
          : decodeAnyCompositeValue(ctx, r, subType)
      }
      return values
    }
    case ColumnType.Map: {
      // keys and values each encoded as a Set of values
      const keys = decodeAnyCompositeValue(ctx, r, ColumnType.Set) as unknown[]
      const values = decodeAnyCompositeValue(ctx, r, ColumnType.Set) as unknown[]
      if (keys.length !== values.length) throw new Error('map key size not equal to value size')
      const result: Record<string, unknown> = {}
      for (let i = 0; i < keys.length; i++) result[String(keys[i])] = values[i]
      return result
    }
    case ColumnType.Record: {
      const size = bytesToUint16(r.readN(2))
      const result: Record<string, unknown> = {}
      for (let i = 0; i < size; i++) {
        const nameLength = bytesToInt16(r.readN(2))
        const name = utf8(r.readN(nameLength))
        const subType = r.readN(1)[0]
        result[name] = decodeAnyCompositeValue(ctx, r, subType)
      }
      return result
    }
    case ColumnType.Node: {
      const nodeIdRaw = bytesToInt64Big(r.readN(8))
      const graphId = bytesToInt32(r.readN(4))
      const propSize = bytesToUint16(r.readN(2))
      const nodeTypeId = Number(nodeIdRaw >> 48n)
      const properties: Record<string, unknown> = {}
      for (let i = 0; i < propSize; i++) {
        const nameSize = bytesToInt16(r.readN(2))
        const name = utf8(r.readN(nameSize))
        const subType = r.readN(1)[0]
        properties[name] = decodeAnyCompositeValue(ctx, r, subType)
      }
      const names = getSchemaName(ctx.graphsSchema, graphId, nodeTypeId, true)
      return {
        nodeId: int64ToJson(nodeIdRaw),
        graph: names.graph,
        type: names.type,
        labels: names.labels,
        properties,
      } satisfies NodeValue
    }
    case ColumnType.Edge: {
      const srcRaw = bytesToInt64Big(r.readN(8))
      const dstRaw = bytesToInt64Big(r.readN(8))
      const rankRaw = bytesToInt64Big(r.readN(8))
      const graphId = bytesToInt32(r.readN(4))
      const edgeTypeId = bytesToInt32(r.readN(4))
      const propSize = bytesToUint16(r.readN(2))
      const noDirectType = edgeTypeId & 0x3fffffff
      const direction = getEdgeDirection(edgeTypeId >> 30)
      const properties: Record<string, unknown> = {}
      for (let i = 0; i < propSize; i++) {
        const nameSize = bytesToInt16(r.readN(2))
        const name = utf8(r.readN(nameSize))
        const subType = r.readN(1)[0]
        properties[name] = decodeAnyCompositeValue(ctx, r, subType)
      }
      const names = getSchemaName(ctx.graphsSchema, graphId, noDirectType, false)
      const outgoing = direction === EdgeDirection.Incoming
      return {
        srcId: outgoing ? int64ToJson(dstRaw) : int64ToJson(srcRaw),
        dstId: outgoing ? int64ToJson(srcRaw) : int64ToJson(dstRaw),
        rank: int64ToJson(rankRaw),
        direction: direction === EdgeDirection.Outgoing ? 'outgoing' : direction === EdgeDirection.Incoming ? 'incoming' : 'none',
        graph: names.graph,
        type: names.type,
        labels: names.labels,
        properties,
      } satisfies EdgeValue
    }
    case ColumnType.Path: {
      const elementNum = bytesToInt16(r.readN(2))
      const elements: unknown[] = []
      for (let i = 0; i < elementNum; i++) {
        const subType = r.readN(1)[0]
        elements.push(decodeAnyCompositeValue(ctx, r, subType))
      }
      return { elements } satisfies PathValue
    }
    case ColumnType.Vector: {
      const size = bytesToInt16(r.readN(2))
      const values: number[] = new Array(size)
      for (let i = 0; i < size; i++) values[i] = bytesToFloat32(r.readN(4))
      return values
    }
    case ColumnType.Geography:
      return decodeGeographyData(r)
    default:
      throw new Error(`invalid column type: ${type}`)
  }
}

/** Port of the flat path decoding (adjacency-list walk through paired vectors). */
function decodePath(ctx: DecodeContext, vector: NestedVectorLike, index: number, schema: TypeSchema): PathValue {
  if (schema.kind !== 'path') throw new Error('path column schema is not a path schema')
  if (schema.meta === undefined) throw new Error('path column schema has no meta')
  const header = vector.vector_data.subarray(index * 16, index * 16 + 16)
  const totalNum = bytesToInt32(header.subarray(0, 4))
  const headerIdx = bytesToUint16(header.subarray(4, 6))
  const headOffset = bytesToUint32(header.subarray(8, 12))
  const elements: unknown[] = new Array(totalNum)

  let pairIndex = headerIdx
  let sentinelPair = schema.meta.nodePairIndex.get(pairIndex)
  if (sentinelPair === undefined) throw new Error('element type not found in path meta')
  let sentinelType: number = ColumnType.Node
  let sentinelOffset = headOffset

  for (let i = 0; i < totalNum; i++) {
    const pair = sentinelPair
    if (sentinelType === ColumnType.Node) {
      elements[i] = decodeNode(ctx, vector.nested_vectors[pair.cur], sentinelOffset, { kind: 'element', type: ColumnType.Node, props: schema.node })
    } else {
      elements[i] = decodeEdge(ctx, vector.nested_vectors[pair.cur], sentinelOffset, { kind: 'element', type: ColumnType.Edge, props: schema.edge })
    }
    // The adjacency vector holds the next hop header as a flat int64.
    const adjVector = vector.nested_vectors[pair.adj]
    const headerRaw = decodeValue(ctx, adjVector, VectorType.Flat, sentinelOffset, { kind: 'basic', type: ColumnType.Int64 }, null)
    const pathHeader = newPathAdjHeader(typeof headerRaw === 'string' ? BigInt(headerRaw) : BigInt(headerRaw as number))
    sentinelOffset = pathHeader.nextOffset
    sentinelType = pathHeader.nextIsEdge ? ColumnType.Edge : ColumnType.Node
    const nextPair = sentinelType === ColumnType.Node
      ? schema.meta.nodePairIndex.get(pathHeader.nextVectorIndex)
      : schema.meta.edgePairIndex.get(pathHeader.nextVectorIndex)
    if (nextPair === undefined) throw new Error('element type not found in path meta')
    sentinelPair = nextPair
  }
  return { elements }
}

interface PathAdjHeader {
  nextIsEdge: boolean
  nextVectorIndex: number
  nextOffset: number
}

function newPathAdjHeader(value: bigint): PathAdjHeader {
  const isEnd = ((value >> 63n) & 1n) === 1n
  const nextIsEdge = ((value >> 62n) & 1n) === 1n
  const nextVectorIndex = Number((value >> 32n) & 0xffffn)
  const nextOffset = Number(value & 0xffffffffn)
  void isEnd
  return { nextIsEdge, nextVectorIndex, nextOffset }
}

/**
 * Parse the path column's special meta data: node type pairs then edge type
 * pairs, each pair naming the `cur`/`adj` nested vectors.
 *
 * @param specialMetaData - the vector's special meta data bytes.
 * @param nodePairs - map filled with node type id → vector pair.
 * @param edgePairs - map filled with edge type id → vector pair.
 */
export function decodePathSpecialData(
  specialMetaData: Uint8Array,
  nodePairs: Map<number, { cur: number; adj: number }>,
  edgePairs: Map<number, { cur: number; adj: number }>,
): void {
  const r = new BytesReader(specialMetaData)
  const nodeTypeNum = bytesToInt32(r.readN(4))
  let nestedVectorIndex = 0
  for (let i = 0; i < nodeTypeNum; i++) {
    r.readN(4) // graph id, unused
    r.readN(2) // node type id, unused
    const pairIndex = bytesToUint16(r.readN(2))
    nodePairs.set(pairIndex, { cur: nestedVectorIndex, adj: nestedVectorIndex + 1 })
    nestedVectorIndex += 2
  }
  const edgeTypeNum = bytesToInt32(r.readN(4))
  for (let i = 0; i < edgeTypeNum; i++) {
    r.readN(4) // graph id, unused
    r.readN(4) // edge type id, unused
    const pairIndex = bytesToUint16(r.readN(2))
    edgePairs.set(pairIndex, { cur: nestedVectorIndex, adj: nestedVectorIndex + 1 })
    nestedVectorIndex += 2
  }
}

/**
 * Decode the element property vector indices from a node/edge vector's
 * special meta data and stamp them onto the parsed schema.
 *
 * Layout: `num props + [prop names] + num element types + [graph id + element
 * type id + num props + [vector index]*]`, where each vector index is the
 * property's position in the prop-name list (and its nested vector slot).
 *
 * @param vectorIndexesByGraph - the schema's graph → element type → prop map.
 * @param specialMetaData - the vector's special meta data bytes.
 * @param isNode - whether this is a node (2-byte type ids) or edge (4-byte).
 */
export function decodePropVectorIndex(
  vectorIndexesByGraph: GraphElementProps,
  specialMetaData: Uint8Array,
  isNode: boolean,
): void {
  const r = new BytesReader(specialMetaData)
  const propsNum = bytesToInt32(r.readN(4))
  const propList: string[] = []
  for (let i = 0; i < propsNum; i++) {
    const size = bytesToInt16(r.readN(2))
    propList.push(utf8(r.readN(size)))
  }
  const elementTypeSize = isNode ? 2 : 4
  const nodeTypeNum = bytesToInt32(r.readN(4))
  for (let i = 0; i < nodeTypeNum; i++) {
    const graphId = bytesToInt32(r.readN(4))
    const idBytes = r.readN(elementTypeSize)
    const elementTypeId = isNode ? bytesToInt16(idBytes) : bytesToInt32(idBytes)
    const propNum = bytesToInt32(r.readN(4))
    for (let j = 0; j < propNum; j++) {
      const vectorIndex = bytesToInt32(r.readN(4))
      const elementProps = vectorIndexesByGraph.get(graphId)?.get(elementTypeId)
      if (elementProps === undefined) continue
      const prop = elementProps.get(propList[vectorIndex])
      if (prop !== undefined) prop.vectorIndex = vectorIndex
    }
  }
}

export { ColumnType, VectorType }
