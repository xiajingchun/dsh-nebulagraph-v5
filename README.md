# dsh-nebula

A [DeepSeek Harness](https://github.com/deepseek-ai) plugin that connects to a
**NebulaGraph v5** server and executes **ISO-GQL** statements, in the spirit of
the `ngql` console.

The plugin speaks the native NebulaGraph v5 wire protocol (gRPC +
`nebula.proto.graph.GraphService`) with a **pure-JS client** — no native
modules, no external gateway. Results come back as structured JSON rows plus
an ngql-style ASCII table render.

> **Syntax policy**: only NebulaGraph v5 ISO-GQL is supported — exactly what
> the bundled `gql-query-generator` skill documents plus explicitly confirmed
> catalog statements (`SHOW GRAPHS`, `DESC GRAPH TYPE`). Open-source
> NebulaGraph nGQL (`USE space`, `SHOW SPACES`, `SHOW TAGS`, `DESCRIBE TAG`,
> …) is **not** referenced. The v5 session working graph is switched with
> `SESSION SET graph <name>`, or scoped per statement with `USE <graph> <stmt>`
> / `USE <graph> { … }`.

## Features

- Connect / authenticate against a graphd (`nebula_connect`), execute GQL on
  the same server-side session (`nebula_execute`), and close it
  (`nebula_disconnect`).
- Decodes the columnar `VectorResultTable` payload exactly like the official
  nebula-go v5 client: scalars, strings, temporal values, lists, sets, maps,
  records, vertices, edges, paths, embedding vectors, geography, `Any`-typed
  columns, const vectors, and null bitmaps.
- **Schema exploration (`nebula_schema`)**: one call runs `SHOW GRAPHS`,
  resolves the target graph (explicit `graph=` argument, the session working
  graph from `SESSION SET graph`, or the sole graph), then `DESC GRAPH TYPE`
  and returns the graph type's node types and edge types — labels,
  primary/multiedge keys, and properties. Read-only: the session working graph
  is never changed.
- ngql-compatible value rendering (`(id@type:labels{props})`,
- **Interactive graph rendering (Web Client)**: when a `nebula_execute` result
  contains nodes, edges, or paths, the result is projected into a replayable
  graph payload and the bundled Web Client plugin renders it as an interactive
  [AntV G6](https://g6.antv.antgroup.com/) graph (drag / zoom / hover),
  alongside the normal table output. Only the **final** graph result of each
  turn renders: the plugin keeps one G6 card per turn whose content is the
  latest graph-carrying tool result, so intermediate results the agent
  produces while thinking (probe queries, exploration steps) never accumulate
  as separate cards — the single card left behind after the turn settles is
  the turn's last graph, placed at that result's position in the
  conversation. Node labels always show the vertex's
  **primary key** — the property values named by `DESC GRAPH TYPE` for the
  node's type (the v5 columnar result carries no primary-key definition, so
  the host resolves it lazily via `SHOW GRAPHS` + `DESC GRAPH TYPE` and
  caches it per connection); a **composite primary key** joins its values
  with `:`. Edge labels show the edge type name, plus the composed
  **multiedge-key** values with their property names (e.g.
  `serve (start_year=2002, end_year=2011)`) only when the type's
  multiedge key defines real properties — `Unique`/`Auto` edges get no
  suffix, and the raw rank is never shown. Hovering a node or edge opens a
  tooltip with its full type/labels and property list (properties beyond the
  first 10 and values longer than 80 chars are truncated to keep the card
  compact).
  To feed this renderer, the bundled
  `gql-query-generator` skill defaults `RETURN` to the **complete graph
  elements** whenever a prompt asks to return a node type or edge type (e.g.
  "return Star Wars directors and actors") — the pattern's node and edge
  variables (or the path variable) — and only projects a specific property
  (e.g. `name`) when the prompt explicitly asks for it. `nebula_schema` results render as a
  **schema meta-graph**: node types become card vertices (name, labels,
  🔑 primary key, properties) and edge types become arcs between their
  pattern's source/target node types, laid out with a layered dagre layout.
  Large data graphs switch to a **lite mode** (>300 nodes or >600 edges):
  bounded force layout, no edge labels, and lighter drag behaviors; payloads
  above 700 nodes / 1400 edges are additionally capped client-side (with a
  notice) so the browser stays responsive.
  `(src)-[rank@type:labels{props}]->(dst)`, `2019-01-01T12:34:56.123456`,
  durations as `P1Y2M3DT4H5M6.123456S`, …) and an ASCII table output.
- `SESSION SET graph` and other session-state statements persist per
  `connectionId`; the plugin tracks the session's working graph so
  `nebula_schema` can target it automatically.
- Bundles the **`gql-query-generator`** skill: the plugin registers a
  `ctx.skills` provider so the agent's `skill` tool can load NebulaGraph
  GQL-writing guidance (reference docs ship in `gql-query-generator/references/`
  and resolve against the packaged directory).
- Plugin config supplies default connection parameters; every tool argument
  can override them per call.
- **Password never travels through the model**: `nebula_connect` takes a
  `passwordRef` (a credential reference / environment variable name), not the
  password value. The value is resolved per connection through the DSH
  credentials seam (`ctx.credentials`, falling back to the process
  environment) and cleared from memory right after authentication. Tool
  arguments, output, and the registry never carry the plaintext.
- **TLS by default, plaintext fallback available**: connections try TLS first
  (`tls: "auto"`, the default) and fall back to plaintext only when the server
  has no TLS listener — the fallback is reported to the caller as a warning.
  Set `tls: "on"` to require TLS (fails if the server does not speak it) or
  `tls: "off"` to force plaintext. CA / client certificate / key / server name
  overrides are configurable for private CAs and mutual TLS.
- Unloading the plugin closes every open session (effect-based cleanup).

## Tools

| Tool | Purpose |
| --- | --- |
| `nebula_connect` | Connect to a graphd and open a session. Arguments: `host`, `port`, `user`, `passwordRef`, `tls`, `ca`, `timeoutMs` (all optional, defaulting to plugin config). The password itself is never an argument — it resolves from `passwordRef` via the DSH credentials seam / environment. Returns a `connectionId` (plus `tlsFallback` when the server had no TLS). |
| `nebula_execute` | Run one GQL statement on a connection. Arguments: `connectionId` (required), `gql` (required), `timeoutMs`. Returns `{ ok, columns, rows, numRows, latencyUs, summary?, error? }`. |
| `nebula_schema` | Introspect a graph's schema. Arguments: `connectionId` (required), `graph` (optional — defaults to the session working graph, then the sole graph). Runs `SHOW GRAPHS` + `DESC GRAPH TYPE`, returns `{ graphs, graph, nodes, edges, … }`. Read-only. |
| `nebula_disconnect` | Close a connection and release its server-side session. |

## Skill

The plugin registers a `bundled` skill provider on `ctx.skills` named
`dsh-nebula` that serves the **`gql-query-generator`** skill from the packaged
`gql-query-generator/` directory. The model can load it through the `skill`
tool (or a direct user invocation); its `references/*.md` resolve against the
packaged directory via the skill's `resourceBase`. The skill body is read
from disk on each load, so editing `SKILL.md` takes effect without a rebuild
for link-installed plugins.

Typical agent flow:

```text
nebula_connect (host: 192.168.8.6, port: 9669, user: root, passwordRef: NEBULA_PASSWORD)
  → { connectionId: "…", tlsFallback: false }
nebula_execute (connectionId, gql: "SHOW GRAPHS")
nebula_schema  (connectionId, graph: "movie")
  → { graphs: […], graph: { name: "movie", graphType: "movie_type", … },
      nodes: [ { name: "Actor", labels: [Person], primaryKey: [id], … } ],
      edges: [ { name: "Act", source: "Actor", target: "Movie", … } ] }
nebula_execute (connectionId, gql: "SESSION SET graph movie")
nebula_execute (connectionId, gql: "MATCH (n) RETURN n LIMIT 5")
nebula_disconnect (connectionId)
```

## Install

The plugin is an out-of-tree DSH bundle: a plain npm package whose manifest
declares a `dsh.bundle` patch. Any DSH installation (rc.5+; the web profile
ships `ctx.skills`, so the bundled skill provider works out of the box) can
install it in one command:

```sh
# from a registry (once published)
dsh plugin --profile web add dsh-nebula

# from the packed tarball
dsh plugin --profile web add /path/to/dsh-nebula-0.1.0.tgz

# from a local checkout while developing
dsh plugin --profile web add link:/path/to/dsh-nebula
```

This runs `pnpm add` in the profile directory, then appends `dsh-nebula` to
`dsh.profile.bundles` because the package declares a `dsh.bundle` patch
(`cordis.patch.yml` inserts the plugin row). Restart the profile
(`dsh web`) for the new bundle to mount. `nodeLinker: hoisted` profiles must
approve the `protobufjs` build script (the shipped web profile already does).

### Publishing for other users

```sh
cd dsh-nebula
npm login        # once
pnpm publish     # runs build + tests via prepublishOnly
```

The tarball (`pnpm pack` → `dsh-nebula-0.1.0.tgz`) is fully self-contained:
compiled `lib/`, vendored protos, the packaged `gql-query-generator/` skill
(including its `.feature` evidence files), `cordis.patch.yml`, README, and
LICENSE. It was verified by installing the tarball into a fresh throwaway
profile: the bundle joins `dsh.profile.bundles`, the module resolves, and the
skill provider lists/loads `gql-query-generator` with its resource base inside
the installed package.

### Config

Plugin config lives in the profile's patch layer (e.g.
`~/.dsh/profiles/web/cordis.patch.yml`):

```yaml
- insert:
    - id: nebula
      name: dsh-nebula
      config:
        host: 127.0.0.1
        port: 9669
        user: root
        passwordRef: NEBULA_PASSWORD   # preferred: credential reference (env var name)
        tls: auto                      # auto | on | off
        timeoutMs: 30000
        maxConnections: 5
```

| Field | Default | Meaning |
| --- | --- | --- |
| `host` | `127.0.0.1` | Default graphd host. |
| `port` | `9669` | Default graphd gRPC port. |
| `user` | `root` | Default login user name. |
| `passwordRef` | *(none)* | Credential reference (environment variable name) resolving to the default password via the DSH credentials seam. **Preferred over `password`** — the value never appears in config surfaces, tool arguments, or logs. |
| `password` | `''` | Default login password (plaintext). Fallback used only when `passwordRef` is unset; keep it out of shared config files. |
| `tls` | `'auto'` | TLS mode: `auto` (try TLS, fall back to plaintext when the server has no TLS listener), `on` (require TLS), `off` (plaintext only). |
| `ca` | *(none)* | CA bundle (PEM) for verifying the server certificate (private / self-signed CAs). |
| `cert` / `key` | *(none)* | Client certificate and private key (PEM) for mutual TLS. The key is config-only and never exposed as a tool argument. |
| `servername` | *(none)* | Override the server name used for SNI and certificate verification. |
| `timeoutMs` | `30000` | Default per-request deadline (ms). |
| `maxConnections` | `5` | Upper bound on concurrently open connections. |

To use a `passwordRef`, store the value in the DSH credentials document
(`~/.dsh/.credentials.yaml`, mode 0600) or the process environment, e.g.:

```yaml
# ~/.dsh/.credentials.yaml
NEBULA_PASSWORD: s3cr3t
```

The password is resolved per connection at `nebula_connect` time and cleared
from memory immediately after authentication succeeds.

## Development

```sh
pnpm install
pnpm typecheck
pnpm build     # tsc → lib/ + copies vendored protos to lib/proto
pnpm test      # decoder unit tests + gRPC integration tests (in-process fake GraphService)
```

The package is plain ESM (`"type": "module"`) with no runtime dependencies
beyond `@grpc/grpc-js`, `@grpc/proto-loader`, and `schemastery`.

## How it works

- **Protocol** — the vendored protos under `src/proto/nebula/` are the
  official NebulaGraph 5.0 definitions (graph/common/vector) from
  nebula-go v5. `AuthRequest.auth_info` is `JSON.stringify({ password })` and
  `ClientInfo.lang` advertises `JAVASCRIPT`; `Status.code == "00000"` means
  success. The password is sent only inside the one-time `Authenticate` call
  and cleared from the client/registry options immediately after success.
- **Transport security** — the channel uses gRPC credentials per the `tls`
  mode: `on` → `createSsl` (with optional CA / client cert / server-name
  override), `off` → `createInsecure`, `auto` → try TLS first, then recreate
  the channel with plaintext credentials only when the handshake fails at the
  transport level (never on an authentication failure). A plaintext fallback
  is surfaced as `tlsFallback` in the connect output and as a warning line.
- **Logout** — the v5 gRPC service has no signout RPC; closing a session
  executes the `SESSION CLOSE` statement before releasing the channel
  (mirroring nebula-go v5 `connection.Close()`), so the server-side session
  is released immediately instead of lingering until its idle timeout.
- **Decoder** — `src/decode/` is a faithful TypeScript port of nebula-go v5's
  `internal/decode` (column type schemas, flat/const vector layouts, chunked
  strings, node/edge property vectors, path adjacency lists, composite value
  encoding).
- **Registry** — open connections live in a per-plugin registry; disposing the
  plugin closes them all.

## License

MIT
