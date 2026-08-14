/**
 * ngql-style formatting for decoded result values and ASCII table rendering.
 *
 * Cell formatting mirrors the NebulaGraph console (`ngql/pkg/printer`): plain
 * strings print unquoted, strings containing special characters print with
 * Go-style quoting, vertices/edges/paths print in the console's
 * `(id@type:labels{props})` / `(src)-[rank@type:labels{props}]->(dst)` forms,
 * and record/map keys are sorted.
 */

/** Escape and quote a string exactly like Go's `strconv.Quote` (double-quoted). */
function goQuote(str: string): string {
  let out = '"'
  for (const ch of str) {
    const code = ch.codePointAt(0)!
    switch (ch) {
      case '"': out += '\\"'; break
      case '\\': out += '\\\\'; break
      case '\n': out += '\\n'; break
      case '\r': out += '\\r'; break
      case '\t': out += '\\t'; break
      case '\b': out += '\\b'; break
      case '\f': out += '\\f'; break
      case '\v': out += '\\v'; break
      case '\u0007': out += '\\a'; break
      default:
        if (code < 0x20 || code === 0x7f) out += `\\x${code.toString(16).padStart(2, '0')}`
        else out += ch
    }
  }
  return out + '"'
}

/** ngql's `strQuoteSpecial` + unwrap: quote only when the string needs it. */
function strQuoteSpecial(str: string): string {
  const special = ['"', '\u0007', '\b', '\f', '\n', '\r', '\t', '\v', ' ', '\\', ',']
  let rr = str
  if (special.some((c) => str.includes(c))) {
    rr = goQuote(str)
  } else if (str === '') {
    rr = goQuote(str)
  }
  if (rr.startsWith('"') && rr.endsWith('"') && rr.length >= 2) {
    rr = rr.slice(1, -1)
    rr = rr.replaceAll('\\\\', '\\')
    rr = rr.replaceAll('\\"', '"')
  }
  return rr
}

function formatNumber(n: number): string {
  if (Number.isInteger(n) && Math.abs(n) < 1e21) return String(n)
  return String(n)
}

/** Format a decoded cell value in ngql console style. */
export function formatValue(value: unknown): string {
  if (value === null || value === undefined) return 'NULL'
  switch (typeof value) {
    case 'boolean':
      return value ? 'true' : 'false'
    case 'number':
      return formatNumber(value)
    case 'string':
      return strQuoteSpecial(value)
    case 'object': {
      if (Array.isArray(value)) {
        return `[${value.map((v) => formatValue(v)).join(',')}]`
      }
      const obj = value as Record<string, unknown>
      if (isNode(obj)) return formatNode(obj)
      if (isEdge(obj)) return formatEdge(obj)
      if (isPath(obj)) return formatPath(obj)
      if (isGeography(obj)) return formatGeography(obj)
      const keys = Object.keys(obj).sort()
      return `{${keys.map((k) => `${strQuoteSpecial(k)}:${formatValue(obj[k])}`).join(',')}}`
    }
    default:
      return String(value)
  }
}

interface NodeLike { nodeId: unknown; graph: unknown; type: unknown; labels: unknown; properties: unknown }
interface EdgeLike {
  srcId: unknown; dstId: unknown; rank: unknown; direction: unknown
  graph: unknown; type: unknown; labels: unknown; properties: unknown
}
interface PathLike { elements: unknown }
interface GeoLike { shape: unknown; srid: unknown; [k: string]: unknown }

function isNode(obj: object): obj is NodeLike {
  return 'nodeId' in obj && 'type' in obj && 'properties' in obj
}
function isEdge(obj: object): obj is EdgeLike {
  return 'srcId' in obj && 'dstId' in obj && 'rank' in obj && 'direction' in obj
}
function isPath(obj: object): obj is PathLike {
  return 'elements' in obj && Array.isArray((obj as PathLike).elements)
}
function isGeography(obj: object): obj is GeoLike {
  return 'shape' in obj && 'srid' in obj
}

function formatProps(properties: unknown): string {
  if (properties === null || properties === undefined || typeof properties !== 'object') return ''
  const obj = properties as Record<string, unknown>
  return Object.keys(obj).sort().map((k) => `${k}:${formatValue(obj[k])}`).join(',')
}

function formatNode(n: NodeLike): string {
  const labels = Array.isArray(n.labels) ? (n.labels as string[]).join('&') : ''
  return `(${String(n.nodeId)}@${String(n.type)}:${labels}{${formatProps(n.properties)}})`
}

function formatEdge(e: EdgeLike): string {
  const labels = Array.isArray(e.labels) ? (e.labels as string[]).join('&') : ''
  const directed = e.direction === 'outgoing' || e.direction === 'incoming'
  const left = directed ? '-' : '~'
  const right = directed ? '->' : '~'
  return `(${String(e.srcId)})${left}[${String(e.rank)}@${String(e.type)}:${labels}{${formatProps(e.properties)}}]${right}(${String(e.dstId)})`
}

function formatPath(p: PathLike): string {
  const elements = p.elements as unknown[]
  let out = ''
  let prevNodeId: unknown = null
  for (const element of elements) {
    if (isNode(element as Record<string, unknown>)) {
      const node = element as unknown as NodeLike
      prevNodeId = node.nodeId
      out += formatNode(node)
    } else if (isEdge(element as Record<string, unknown>)) {
      const edge = element as unknown as EdgeLike
      const labels = Array.isArray(edge.labels) ? (edge.labels as string[]).join('&') : ''
      const estr = `[${String(edge.rank)}@${String(edge.type)}:${labels}{${formatProps(edge.properties)}}]`
      if (edge.direction === 'none') {
        out += `~${estr}~`
      } else if (edge.direction === 'incoming') {
        out += `<${estr}-`
      } else {
        out += `-${estr}>`
      }
      void prevNodeId
    }
  }
  return out
}

function formatGeography(g: GeoLike): string {
  return JSON.stringify(g)
}

/** Render decoded rows as an ngql-style ASCII table. */
export function renderTable(columns: string[], rows: unknown[][]): string {
  const widths = columns.map((c, i) => {
    let w = c.length
    for (const row of rows) {
      const cell = row[i] === undefined ? '' : formatValue(row[i])
      if (cell.length > w) w = cell.length
    }
    return w
  })
  const border = `+${widths.map((w) => '-'.repeat(w + 2)).join('+')}+`
  const renderRow = (cells: string[]): string =>
    `|${cells.map((c, i) => ` ${c.padEnd(widths[i])} `).join('|')}|`
  const lines: string[] = [border]
  lines.push(renderRow(columns))
  lines.push(border)
  for (const row of rows) {
    lines.push(renderRow(row.map((v) => formatValue(v))))
  }
  lines.push(border)
  return lines.join('\n')
}
