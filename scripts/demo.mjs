/**
 * dsh-nebula demo: connect to a NebulaGraph 5.0 server and run a few nGQL
 * statements, printing ngql-style tables. Uses the exact same code path as
 * the nebula_connect / nebula_execute / nebula_disconnect tools.
 *
 * Usage:
 *   NEBULA_HOST=192.168.8.187 NEBULA_PORT=39669 NEBULA_USER=root \
 *     NEBULA_PASSWORD=Nebula123 node scripts/demo.mjs
 *
 * Arguments can also be passed positionally:
 *   node scripts/demo.mjs <host> <port> <user> <password>
 */

import { NebulaClient } from '../lib/client.js'
import { renderTable } from '../lib/format.js'

const [host = process.env.NEBULA_HOST ?? '127.0.0.1', port = Number(process.env.NEBULA_PORT ?? 9669),
  user = process.env.NEBULA_USER ?? 'root', password = process.env.NEBULA_PASSWORD ?? ''] = process.argv.slice(2)

console.log(`>>> connecting to ${host}:${port} as ${user} …`)
const client = await NebulaClient.connect({ host, port, user, password, timeoutMs: 15000 })
console.log(`connected (server version: ${client.serverVersion})\n`)

async function run(label, gql) {
  console.log(`>>> ${label}: ${gql}`)
  const result = await client.execute(gql)
  if (!result.ok) {
    console.log(`Error: ${result.error?.code}: ${result.error?.message}\n`)
    return result
  }
  if (result.columns.length > 0) {
    console.log(renderTable(result.columns, result.rows))
  }
  const bits = []
  if (result.numRows > 0) bits.push(`Got ${result.numRows} rows`)
  if (result.latencyUs > 0) bits.push(`time spent ${result.latencyUs}us`)
  if (result.summary?.affectedNodes) bits.push(`affected nodes: ${result.summary.affectedNodes}`)
  if (result.summary?.affectedEdges) bits.push(`affected edges: ${result.summary.affectedEdges}`)
  if (bits.length > 0) console.log(bits.join(' '))
  console.log()
  return result
}

await run('SHOW GRAPHS', 'SHOW GRAPHS')
// Pick the first graph and run a sample query against it, if any.
const graphs = (await run('SHOW GRAPHS', 'SHOW GRAPHS')).rows
if (graphs.length > 0) {
  const graph = String(graphs[0][0]).replace(/[`"]/g, '')
  await run('USE', `USE \`${graph}\``)
  await run('sample query', `SHOW TAGS`)
}

await client.close()
console.log('disconnected (SESSION CLOSE sent).')
