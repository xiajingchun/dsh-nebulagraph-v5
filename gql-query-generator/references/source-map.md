# Query Skill Source Map

## Version Baseline

- Documentation: NebulaGraph `5.3.0` Chinese HTML
- Feature corpus: NebulaGraph `5.3.0`
- Skill compatibility: NebulaGraph `5.3.0`
- Code audit: `nebula-ng` tag `v5.3.0` (`ff090434b`) and master `40ff12b51` (2026-07-10)

Refresh corpora: `v5.3.0_zh_html` and `v5.3.0_features`. The packaged skill is self-contained and does not require the original source directories.

## Documentation Mapping

The generated [documented-functions.md](documented-functions.md) is the complete callable allowlist: 146 Database names, 143 Analytics names, 143 shared names, and three non-call forms documented beside the functions. The generated [documented-syntax.md](documented-syntax.md) indexes all 64 documentation pages in the query skill's declared scope. Regenerate both files instead of maintaining a hand-picked allowlist.

| Skill area | v5.3.0 documentation |
| --- | --- |
| Query composition and result flow | `database-gql-reference/dql/` |
| `MATCH`, node, edge, and path patterns | `database-gql-reference/dql/match/`, `database-gql-reference/patterns/` |
| K-hop and quantified paths | `database-gql-reference/patterns/path-patterns/` |
| Dynamic labels and predicates | `database-gql-reference/fe/expressions/label/`, `database-gql-reference/fe/predicates/labeled/` |
| Node and edge element types | `database-gql-reference/patterns/node-patterns/`, `database-gql-reference/patterns/edge-patterns/` |
| Expressions and functions | `database-gql-reference/fe/expressions/`, `database-gql-reference/fe/functions/` |
| NULL checks and documented predicates | `database-gql-reference/fe/predicates/null/`, `database-gql-reference/fe/predicates/` |
| List deduplication and lambda projection | `database-gql-reference/fe/functions/list/`, `database-gql-reference/fe/functions/lambda/` |
| `LET`, `FOR`, `FILTER`, subqueries, paging | `database-gql-reference/dql/` |
| Named and inline procedure calls | `database-gql-reference/dql/call/` |
| DML | `database-gql-reference/dml/` |
| Nearest-neighbor queries | `database-gql-reference/dql/nearest-neighbor/` |
| Parameters and execution hints | `database-gql-reference/executions/` |

## Feature Mapping

The vendored subset under `tests/features/` is the implementation-evidence layer.

| Skill area | Key feature evidence |
| --- | --- |
| Core match and path behavior | `match/*.feature` |
| K-hop expansion | `match/KHopExpand.feature` |
| Dynamic node/edge labels | `match/QueryOnLabel.feature` |
| Dynamic node/edge element types | `match/QueryOnElementType.feature` |
| VC index and quantified expansion | `index/vc_index_bitraversal_and_topn.feature` |
| Expressions and functions | `expr/*.feature`, `function/*.feature` |
| Result flow and composition | `let/`, `for/`, `filter/`, `subquery/`, `composite/`, `return/` |
| DML | `insert/Insert.feature`, `set/Set.feature`, `delete/Delete.feature` |
| Parameters and graph variables | `parameter/Parameter.feature`, selected `variable/*.feature` |

## Precedence

Use docs as the complete allowlist for public syntax, functions, predicates, and member methods. A cataloged capability does not require a feature or high-frequency example as a second authorization. Feature scenarios and code only establish confirmed implementation boundaries and cannot promote an undocumented internal capability into default output. If implementation evidence directly conflicts with a documented form, preserve the documented capability record but explain or gate the confirmed environment/version restriction.

The 2026-07-13 audit found no query parser changes between `v5.3.0` and `40ff12b51`; every vendored query feature remained byte-identical to the corresponding master file. Keep the public compatibility baseline at 5.3.0 unless a later release is explicitly selected.
