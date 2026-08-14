// Build the Web Client plugin bundle to lib/client.js in the module-loader
// contract: `window.__ModuleLoader__.load({ id, factory: (require) => ... })`.
// Externals (react, @deepseek-ai/*) resolve through the loader's module
// table; everything else (AntV G6 and friends) is inlined.
import { buildSync } from 'esbuild'
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = join(dirname(fileURLToPath(import.meta.url)), '..')
const outfile = join(root, 'lib', 'client.js')

mkdirSync(join(root, 'lib'), { recursive: true })

const EXTERNALS = [
  'react',
  'react/jsx-runtime',
  'react-dom',
  'react-dom/client',
  '@deepseek-ai/cordis',
  '@deepseek-ai/dsh-client-runtime',
  '@deepseek-ai/dsh-client-runtime/client',
  '@deepseek-ai/dsh-client-ui-conversation',
  '@deepseek-ai/dsh-client-ui-conversation/client',
  '@deepseek-ai/dsh-client-ui-slots',
  '@deepseek-ai/dsh-client-ui-primitives',
  '@deepseek-ai/dsh-client-web-react',
]

const result = buildSync({
  entryPoints: [join(root, 'client', 'index.tsx')],
  bundle: true,
  platform: 'browser',
  format: 'cjs',
  target: 'es2020',
  outfile: join(root, 'lib', '.client.tmp.js'),
  external: EXTERNALS,
  jsx: 'automatic',
  logLevel: 'warning',
  minify: false,
})

if (result.errors.length > 0) {
  for (const e of result.errors) console.error(e.text)
  process.exit(1)
}

const body = readFileSync(join(root, 'lib', '.client.tmp.js'), 'utf8')
const wrapped = [
  'window.__ModuleLoader__.load({',
  `\tid: "dsh-nebula",`,
  '\tfactory: (require) => {',
  '\t\tvar module = { exports: {} };',
  '\t\tvar exports = module.exports;',
  '\t\tObject.defineProperty(exports, Symbol.toStringTag, { value: "Module" });',
  body,
  '\t\treturn module.exports;',
  '\t}',
  '});',
].join('\n')
writeFileSync(outfile, wrapped)
console.log(`built ${outfile} (${(Buffer.byteLength(wrapped) / 1024).toFixed(0)} KiB)`)
