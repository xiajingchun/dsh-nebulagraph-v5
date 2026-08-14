/**
 * Column type schema parser: turns the byte payload of a column's
 * `ValueType.value_type` into a {@link TypeSchema} tree. Port of nebula-go v5
 * `internal/decode/columnType.go`.
 */

import { BytesReader, bytesToInt16, bytesToInt32, bytesToUint16, bytesToUint32 } from './bytes.ts'
import type { ElementProps, ElementTypeProps, GraphElementProps, PropSchema, TypeSchema } from './types.ts'
import { ColumnType, columnTypeName } from './types.ts'

function typeFromCode(code: number): number {
  if (columnTypeName[code] === undefined) throw new Error(`unknown column type: ${code}`)
  return code
}

/**
 * Parse one column type schema from a byte reader. Recurses for composite
 * types (list/set/map/record/vector/path and element property schemas).
 *
 * @param r - the reader positioned at the type byte.
 * @returns the parsed schema.
 */
export function newTypeSchema(r: BytesReader): TypeSchema {
  const code = typeFromCode(r.readN(1)[0] ?? -1)
  switch (code) {
    case ColumnType.List:
      return { kind: 'list', type: code, sub: newTypeSchema(r) }
    case ColumnType.Set:
      return { kind: 'set', type: code, sub: newTypeSchema(r) }
    case ColumnType.Map:
      return { kind: 'map', type: code, key: newTypeSchema(r), value: newTypeSchema(r) }
    case ColumnType.Record: {
      // field num + [name (2-byte len + bytes) + type]
      const numFields = bytesToInt32(r.readN(4))
      const props = new Map<string, TypeSchema>()
      for (let i = 0; i < numFields; i++) {
        const size = bytesToInt16(r.readN(2))
        const name = utf8(r.readN(size))
        props.set(name, newTypeSchema(r))
      }
      return { kind: 'record', type: code, props }
    }
    case ColumnType.Node:
      return { kind: 'element', type: code, props: decodeElementTypes(r, true) }
    case ColumnType.Edge:
      return { kind: 'element', type: code, props: decodeElementTypes(r, false) }
    case ColumnType.Path: {
      // num of elements + [element type (node/edge schema)]*
      const node = new Map<number, ElementTypeProps>()
      const edge = new Map<number, ElementTypeProps>()
      const elementNum = bytesToInt32(r.readN(4))
      for (let i = 0; i < elementNum; i++) {
        const element = newTypeSchema(r)
        if (element.kind !== 'element') throw new Error('invalid column type in path schema')
        const target = element.type === ColumnType.Node ? node : edge
        for (const [graphId, elementTypes] of element.props) {
          const existingGraph = target.get(graphId)
          if (existingGraph === undefined) {
            target.set(graphId, elementTypes)
          } else {
            for (const [elementTypeId, props] of elementTypes) {
              const existing = existingGraph.get(elementTypeId)
              if (existing === undefined) existingGraph.set(elementTypeId, props)
              else for (const [name, prop] of props) existing.set(name, prop)
            }
          }
        }
      }
      return { kind: 'path', type: code, node, edge }
    }
    case ColumnType.Decimal:
      // precision (2B) + scale (2B), no decoding impact
      r.readN(2)
      r.readN(2)
      return { kind: 'basic', type: code }
    case ColumnType.Vector: {
      // dim (4B) + element type (must be float32)
      const dim = bytesToUint32(r.readN(4))
      const sub = newTypeSchema(r)
      if (sub.type !== ColumnType.Float32) throw new Error('invalid column type in vector schema')
      return { kind: 'vector', type: code, dim, sub }
    }
    default:
      return { kind: 'basic', type: code }
  }
}

/**
 * Parse the node/edge property schema block:
 * `num element types + [graph id (4B) + element type id (2B node / 4B edge) + num props + [prop name (2B len + bytes) + prop type]]`
 *
 * @param r - the reader.
 * @param isNode - whether the block describes node or edge types.
 * @returns graph id → element type id → property name → schema.
 */
function decodeElementTypes(r: BytesReader, isNode: boolean): GraphElementProps {
  const elementTypeSize = isNode ? 2 : 4
  const numElementType = bytesToInt32(r.readN(4))
  const result: GraphElementProps = new Map()
  for (let i = 0; i < numElementType; i++) {
    const graphId = bytesToInt32(r.readN(4))
    const idBytes = r.readN(elementTypeSize)
    const elementTypeId = isNode ? bytesToInt16(idBytes) : bytesToInt32(idBytes)
    let graphType = result.get(graphId)
    if (graphType === undefined) {
      graphType = new Map()
      result.set(graphId, graphType)
    }
    const props: ElementProps = new Map()
    const numProps = bytesToInt32(r.readN(4))
    for (let j = 0; j < numProps; j++) {
      const size = bytesToInt16(r.readN(2))
      const name = utf8(r.readN(size))
      const prop: PropSchema = { name, schema: newTypeSchema(r), vectorIndex: 0 }
      props.set(name, prop)
    }
    graphType.set(elementTypeId, props)
  }
  return result
}

function utf8(bs: Uint8Array): string {
  return new TextDecoder().decode(bs)
}

export { utf8, bytesToUint16 }
