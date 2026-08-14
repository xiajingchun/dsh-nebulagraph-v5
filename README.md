# dsh-nebula

A [DeepSeek Harness](https://github.com/deepseek-ai) plugin that connects to a
**NebulaGraph 5.0** server and executes nGQL queries, in the spirit of the
`ngql` console tool.

The plugin speaks the native NebulaGraph 5.0 wire protocol (gRPC +
`nebula.proto.graph.GraphService`) with a **pure-JS client** — no native
modules, no external gateway. Results come back as structured JSON rows plus
an ngql-style ASCII table render.

## Features

- Connect / authenticate against a graphd (`nebula_connect`), execute nGQL on
  the same server-side session (`nebula_execute`), and close it
  (`nebula_disconnect`).
- Decodes the columnar `VectorResultTable` payload exactly like the official
  nebula-go v5 client: scalars, strings, temporal values, lists, sets, maps,
  records, vertices, edges, paths, embedding vectors, geography, `Any`-typed
  columns, const vectors, and null bitmaps.
- ngql-compatible value rendering (`(id@type:labels{props})`,
  `(src)-[rank@type:labels{props}]->(dst)`, `2019-01-01T12:34:56.123456`,
  durations as `P1Y2M3DT4H5M6.123456S`, …) and an ASCII table output.
- `USE graph` and other session-state statements persist per `connectionId`.
- Bundles the **`gql-query-generator`** skill: the plugin registers a
  `ctx.skills` provider so the agent's `skill` tool can load NebulaGraph
  GQL-writing guidance (reference docs ship in `gql-query-generator/references/`
  and resolve against the packaged directory).
- Plugin config supplies default connection parameters; every tool argument
  can override them per call.
- Unloading the plugin closes every open session (effect-based cleanup).

## Tools

| Tool | Purpose |
| --- | --- |
| `nebula_connect` | Connect to a graphd and open a session. Arguments: `host`, `port`, `user`, `password`, `timeoutMs` (all optional, defaulting to plugin config). Returns a `connectionId`. |
| `nebula_execute` | Run one nGQL statement on a connection. Arguments: `connectionId` (required), `gql` (required), `timeoutMs`. Returns `{ ok, columns, rows, numRows, latencyUs, summary?, error? }`. |
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
nebula_connect (host: 192.168.8.6, port: 9669, user: root, password: …)
  → { connectionId: "…" }
nebula_execute (connectionId, gql: "SHOW GRAPHS")
nebula_execute (connectionId, gql: "USE `movie`")
nebula_execute (connectionId, gql: "MATCH (v) RETURN v LIMIT 5")
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
        password: ''
        timeoutMs: 30000
        maxConnections: 5
```

| Field | Default | Meaning |
| --- | --- | --- |
| `host` | `127.0.0.1` | Default graphd host. |
| `port` | `9669` | Default graphd gRPC port. |
| `user` | `root` | Default login user name. |
| `password` | `''` | Default login password. |
| `timeoutMs` | `30000` | Default per-request deadline (ms). |
| `maxConnections` | `5` | Upper bound on concurrently open connections. |

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
  success.
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
