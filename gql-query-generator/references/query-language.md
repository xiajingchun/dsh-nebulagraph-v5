# Query Language Reference

Use this file as the detailed NebulaGraph 5.3.0 query syntax reference. Search by clause name instead of loading the whole file.

## Contents

- Task boundary, operating mode, and reference routing
- Query skeleton and core clauses
- Procedure calls, DML, parameters, and statement blocks
- Decision points and hard constraints
- Generation workflow, quality bar, and output preferences

## What This Skill Produces
- 根据自然语言生成可直接使用的 GQL 查询草稿。
- 同时输出查询、关键假设、简短说明。

## When to Use
- 把自然语言需求转成 GQL 查询（MATCH/WHERE/RETURN/ORDER BY/LIMIT 等）。
- 补全或改写已有查询。
- **将 Cypher（openCypher）语句转换为 GQL**。
- **将 nGQL（NebulaGraph 2.x/3.x）语句转换为 GQL**。
- 调用命名过程或内联过程的查询。
- 基于错误码做最小修复改写。
- 向量最近邻查询。
- 参数化查询。

## Do Not Use（改用 `gql-procedure-generator`）
- `CREATE/ALTER/DROP PROCEDURE`、过程体生成。
- 图算法（BFS/DFS、SSSP、PageRank 等）。
- `WHILE` + `match_compute_statement`、`NODE VALUE`、`ACTIVE_SET`。

## Operating Mode
- 自包含 skill：直接依据本文件规则生成查询。
- 详细参考材料在同目录下，按需加载。
- 规则同时参考 v5.3.0 用户文档、`nebula-ng` 实现与 ISO/IEC 39075:2024；默认生成函数必须以用户文档为准。
- feature 和代码用于验证实现边界，不能单独授权未文档化函数；与文档冲突时停止默认生成并说明差异。

## References（按需加载）
- [expressions.md](expressions.md) — 表达式、谓词、运算符
- [patterns.md](patterns.md) — 图模式、路径、量词、过滤放置
- [functions.md](functions.md) — 函数家族、lambda、legacy 迁移
- [error-codes.md](error-codes.md) — 错误码改写映射与决策树
- [nearest-neighbor.md](nearest-neighbor.md) — KNN/ANN 查询模板
- [migration.md](migration.md) — Cypher/nGQL → GQL 语法映射与迁移决策

---

## Query Skeleton

```gql
[USE <graph_name>]
MATCH <graph_pattern>
[WHERE <cross_variable_condition>]
[CALL <procedure>(<args>) [YIELD <items>]]
RETURN <items>
[ORDER BY <sort_items>]
[OFFSET <n>]
[LIMIT <n>]
```

## Core Clauses

### MATCH
- 基础：`MATCH <graph_pattern>` / `OPTIONAL MATCH <graph_pattern>`
- 图模式按点-边-点交替组织。
- **执行方向**：除全路径/最短路径（双向 BFS）外，引擎从左往右执行。因此：
  - 把带过滤条件（锚点）的节点放在 pattern 左侧。
  - 当同一 pattern 中同时存在已绑定变量和未绑定变量时，已绑定变量放左侧。适用于所有场景：子查询引用外层变量、`NEXT` 后第二段引用第一段返回的变量、同一语句中前面 pattern 已绑定的变量在后续 pattern 中复用。
- 路径变量：`p = <path_pattern>` — 只在后续引用整条路径时声明。
- 变长路径量词放在边方向后：`-[:T]->{1,3}`、`-[:T]->*`、`-[:T]->+`。
- **禁止** Cypher 风格 `[:T*1..3]`。
- 未明确要求时不主动添加匹配模式前缀或路径类型前缀。
- 最短路：`ALL SHORTEST`、`ANY SHORTEST`、`SHORTEST n` — 只在用户要求时生成。
- 详细模式规则见 [patterns.md](patterns.md)。

### WHERE / Filter Placement
**三级优先级**：
1. 单变量等值 → pattern 属性 `{prop: value}`
2. 单变量非等值（IN、范围、CONTAINS 等） → pattern 内 `WHERE`
3. 跨变量/结果级约束 → 外层 `WHERE`

**此规则适用于所有图模式**（普通 MATCH、shortest path、quantified path、variable-length 等）——只要过滤条件仅涉及单个变量，就必须写进该变量所在的 pattern，不要留在外层 `WHERE`。

Preferred:
```gql
MATCH (src:Tag WHERE src.id IN <ids>)-[:E]->(dst:Tag WHERE dst.id IN <ids>)
RETURN src, dst
```

Anti-pattern（不要生成）:
```gql
MATCH (src:Tag)-[:E]->(dst:Tag)
WHERE src.id IN <ids> AND dst.id IN <ids>
RETURN src, dst
```

- `AND` 连接多条件；只有用户说"或者"才用 `OR`。
- 在 `WHERE` / `FILTER` 中表达"存在某个图模式"或"排除某个图模式"时，使用相关子查询：`EXISTS { MATCH ... }` / `NOT EXISTS { MATCH ... }`。不要生成裸 pattern 谓词，例如 `AND NOT (p1)-[:follow]-(p2)`。
- 当自然语言出现“是 A，但不是 B”“不是好友”“没有某关系”“排除某模式”“without ...”“but not ...”这类排除关系时，把被排除的图模式落成 `NOT EXISTS { MATCH ... }`；当表达“是 A，且也是/并且有 B 关系”时，把额外图模式落成 `EXISTS { MATCH ... }`。

Preferred:
```gql
MATCH (p1:player)-[:serve]->(t:team)<-[:serve]-(p2:player)
WHERE p1.id <> p2.id
  AND NOT EXISTS {
    MATCH (p1)-[:follow]-(p2)
  }
RETURN p1, p2
```

Anti-pattern（不要生成）:
```gql
MATCH (p1:player)-[:serve]->(t:team)<-[:serve]-(p2:player)
WHERE p1.id <> p2.id
  AND NOT (p1)-[:follow]-(p2)
RETURN p1, p2
```

- 详细表达式规则见 [expressions.md](expressions.md)。

### RETURN
```gql
RETURN [ALL | DISTINCT] <expr> [AS <alias>], ...
RETURN *
```
- 别名用 `AS`；需去重用 `DISTINCT`。
- `count(*)`、`count(DISTINCT <expr>)`。
- 只在用户要所有列时用 `RETURN *`。

### Aggregation & GROUP BY
```gql
RETURN <group_keys>, <aggregate_functions>
GROUP BY <group_keys>
```
- RETURN 中有聚合函数才进入聚合模式。
- `GROUP BY ()` — 所有行归为一组。
- 没有聚合函数不要生成 `GROUP BY`。

### ORDER BY / OFFSET / LIMIT
固定顺序：`ORDER BY` → `OFFSET` → `LIMIT`。
- `ASC`/`DESC`；`NULLS FIRST`/`NULLS LAST`。
- `OFFSET` 也可写 `SKIP`，参数为非负整数。
- `ORDER BY` 不可用子查询表达式。
- `RETURN DISTINCT` / `GROUP BY` 时只能按 RETURN 中可见列排序。

### CALL（命名过程）
```gql
CALL <procedure>(<args>) [YIELD <items>]
RETURN <items>
```
- `CALL` 后必须跟结果语句（`RETURN` 或 `RETURN *`）。
- `OPTIONAL CALL` — 未命中时产出 null 列。
- `YIELD` 挑选/重命名过程输出列。

### CALL { ... }（内联过程）
```gql
CALL { <procedure_body> }
RETURN <items>
```
- 适合查询组合（子查询 + 外层排序/聚合）。
- 内部只放 DQL，不放 DDL/DML。

### FILTER
```gql
FILTER [WHERE] <condition>
```
- 对前一步结果做二次筛选。
- 聚合之后的筛选需先 `NEXT` 再 `FILTER`。

### LET
```gql
LET <var> = <expr>, ...
```
- 声明后续可用的变量。
- 跨 `NEXT` 时需先放进 `RETURN`。
- 不要在子查询内重定义与外层同名的变量。

### FOR
```gql
FOR <var> IN <list_expr>
FOR <var>, <idx> IN <list_expr> WITH ORDINALITY  -- 1-based
FOR <var>, <idx> IN <list_expr> WITH OFFSET      -- 0-based
```
- 展开列表或表；多个 `FOR` 产生笛卡尔积。
- 不用作图遍历原语。

### NEXT
- 把上一段 RETURN 的列传递给下一段查询。
- 只有前一段 RETURN 的列才能在后段使用。
- 典型场景：聚合后再过滤、中间结果复用。

### Composite Query
```gql
<linear_query> UNION [DISTINCT|ALL] <linear_query>
<linear_query> EXCEPT [DISTINCT|ALL] <linear_query>
<linear_query> INTERSECT [DISTINCT|ALL] <linear_query>
```
- 两侧列数、列名、顺序一致。
- 同层不混用不同连接词。
- 默认 `DISTINCT`。

### USE
```gql
USE <graph_name>
USE <graph_variable>
```
- 只在图上下文不可省略时生成。
- 用户没提供时不主动添加。

### DML（INSERT / SET / DELETE）
只在用户明确要求写操作时生成。

```gql
INSERT <pattern>                    -- 冲突时报错
INSERT OR REPLACE <pattern>         -- 替换
INSERT OR IGNORE <pattern>          -- 忽略
INSERT OR UPDATE <pattern>          -- 仅更新属性
```

```gql
SET <element>.<prop> = <expr>       -- 更新属性
SET <node>:<label>                  -- 追加标签
```

```gql
[DETACH | NODETACH] DELETE <elements>
```

### Parameterized Query
```gql
PARAMETERS $<name>=<expr>, ...
MATCH (v:<Tag>)
WHERE v.<prop> = $<name>
RETURN v
```
- 只在用户明确要求参数化时使用。
- 会话参数：`SESSION SET VALUE $<name>=<expr>` / `SESSION RESET $<name>`。

### FINISH
```gql
FINISH
```
- 结束查询且不返回数据；只在用户明确要求时使用。

### Statement Block Rules
- 线性查询以 `RETURN` 或 `FINISH` 收口。
- DDL 最多一条，独占整个语句块。
- DML 最多一条，必须是语句块最后一条。
- 多段通过 `NEXT` 传递结果。

---

## Procedure

1. 判断用户意图：新生成 / 改写 / 补全 / 解释 / 错误修复 / **Cypher 迁移** / **nGQL 迁移**。
2. **若输入是 Cypher 或 nGQL 语句**，加载 [migration.md](migration.md)，识别语言特征并按映射表逐条改写。
3. 确定查询主干：`MATCH` / `CALL procedure(...)` / `CALL { ... }`。
4. 抽取图模式、过滤条件、返回列、聚合、排序分页。
5. Schema 不足时继续生成草稿，不确定部分用占位符（`<Tag>`、`<prop>`）。
6. 若涉及错误码，加载 [error-codes.md](error-codes.md) 按优先级修复。
7. 若涉及向量近邻，加载 [nearest-neighbor.md](nearest-neighbor.md) 套模板。
8. 迁移场景额外输出：原语句中被改写的关键差异点。
9. 输出顺序：GQL 查询 → 关键假设 → 简短说明（迁移时附改写差异）。

## Key Decision Points
- 同一需求既可 `MATCH` 也可 `CALL` → 选更短更直接的。
- 单变量等值过滤 → 属性字面量 `{prop: value}`，不要 pattern WHERE。
- 单变量非等值 → pattern 内 `WHERE`，不要外层 WHERE。
- 所有图模式（含 shortest path、quantified path）的单变量过滤都必须下沉到 pattern，不要留在外层 WHERE。
- 跨变量约束 → 外层 `WHERE`。
- 图模式存在性过滤 → `EXISTS { MATCH ... }`；图模式排除过滤 → `NOT EXISTS { MATCH ... }`；不要用 `NOT (a)-[:T]-(b)`。
- 自然语言若出现“但不是/不是…的人/没有…关系/排除…模式/without/but not”，优先识别为“先匹配主模式，再用 `NOT EXISTS { MATCH ... }` 排除子模式”，不要把否定关系直接写成裸 pattern。
- 子查询再排序/聚合 → `CALL { ... }`。
- 聚合后再筛选 → `RETURN ... NEXT ... FILTER`。
- 多步顺序查询 → 线性查询 + `NEXT`。
- 结果集合运算 → 复合查询。
- Legacy `id(v)` → 先判断业务主键还是身份值。
- 输入含 `WITH`（中间投影）/ `UNWIND` / `MERGE` / `shortestPath()` / `[:T*]` / `collect()` / `exists(n.prop)` / `toSet()` / 列表推导式 / `STARTS WITH`(运算符) / `^ `(求幂) → Cypher 迁移，加载 [migration.md](migration.md)。
- 输入含 `GO` / `FETCH` / `LOOKUP` / `$-` / `$^` / `$$` / `YIELD`（非过程调用）/ `v.tag.prop` / `==`(等值比较) / `[:T1|:T2]` / `rank(edge)` / `@rank` / `properties(v)` / `allShortestPaths` / `FIND PATH` / `GET SUBGRAPH` → nGQL 迁移，加载 [migration.md](migration.md)。
- 输入含 `CALL db.*` / `CALL apoc.*` / `CALL gds.*` / `CALL dbms.*` → Neo4j 特有过程，**不保留 CALL**，必须完全重写为 GQL 原生语法（见 migration.md §1.3）。
- 请求滑向过程定义/算法 → 停止，切到 `gql-procedure-generator`。

## Hard Constraints
- 不生成 `CREATE PROCEDURE`。
- 不生成不存在的 `id()` 函数。
- 不保留 Neo4j 特有过程（`db.*`/`apoc.*`/`gds.*`/`dbms.*`）——必须完全重写为 GQL 原生语法。
- 不生成 `MATCH ... YIELD`（不支持）。
- 不生成 Cypher 风格量词 `[:T*1..n]`。
- 不保留 Cypher 的 `WITH`（中间投影）——必须改为 `RETURN...NEXT`。
- 不保留 Cypher 的 `UNWIND`——必须改为 `FOR`。
- 不保留 Cypher 的 `toSet(list)`——必须改为文档公开的 `list_distinct(list)`；不生成未文档化的 `array_distinct()`。
- 不保留 Cypher 的 `[x IN list | expr]` 或 `[x IN list WHERE pred | expr]`——必须改为 `transform()`，必要时组合 `filter()`。
- 不保留 nGQL 的 `GO`/`FETCH`/`LOOKUP`——必须改为 `MATCH`。
- 不保留 nGQL 的管道 `|`——必须改为 `RETURN...NEXT` 或 `CALL { ... }`。
- 不保留 nGQL 的 `$-.col`/`$^.tag.prop`/`$$.tag.prop`——必须改为变量属性引用。
- 不保留 nGQL 的 `v.tag.prop`——必须改为 `v.prop`。
- 不保留 nGQL 的 `==` 等值比较——必须改为 `=`。
- 不保留 nGQL 的 `[:T1|:T2]` 多边类型并集——必须改为 GQL 标签表达式 `[:T1|T2]`（去掉多余 `:`）。
- 不生成 `type(r) IN ['T1', 'T2']` 来过滤已知的多边类型——必须改为标签表达式 `-[:T1|T2]->`；仅在边类型列表来自运行时参数或动态计算时才用 `type()`。
- 不保留 nGQL 的 `rank(edge)` / `@rank` 原写法；需要 edge rank 时改为 `multiedge_id(edge)`。
- 不保留 nGQL 的 `properties(v)` / `keys(...)` / `src(edge)` / `dst(edge)`——必须改为逐属性返回或 pattern 绑定。
- 不保留 nGQL 的 `allShortestPaths(...)` / `shortestPath(...)` 函数包裹——必须改为 `ALL SHORTEST` / `ANY SHORTEST PATH`。
- 不保留 nGQL/Cypher 的 `exists(v.prop)`——常见属性检查改为文档公开的 `v.prop IS NOT NULL`；若必须区分属性缺失与 NULL，明确说明没有可靠等价构造，不生成未文档化的 `property_exists()`。
- 不保留 Cypher 的 `^` 求幂——必须改为 `power(x, y)`（不是 `pow`）。
- 不保留 Cypher/nGQL 的 `STARTS WITH` / `ENDS WITH` 运算符——必须改为 `like(str, 'prefix%')` / `like(str, '%suffix')`（GQL 无 `starts_with`/`ends_with` 函数）。
- 不保留 Cypher/nGQL 的 `CONTAINS` 运算符——必须改为 `contains(str, substr)`（小写函数形式）。
- 不在 `ACYCLIC` 路径中再用 `all_different()` 列出同一条路径的所有点——ACYCLIC 已保证点不重复，无需冗余。
- 不生成 `all_different(list)`——该函数要求至少两个显式图元素参数，不接受单个 LIST，也不能替代列表去重。
- 所有默认生成的函数都必须在 v5.3.0 用户文档中存在同名且同签名的证据；feature/代码只能验证实现边界，不能把未文档化函数加入白名单。只有用户明确提供的已安装 UDF 可以例外。
- 不保留 Cypher 的 `CALL { WITH n ... }`——GQL 子查询自动捕获外层变量，删除 `WITH`。
- 不机械把 `id(v)` 翻译成 `element_id(v)`——必须先判断语义。
- 不输出只有 `CALL` 没有结果语句的查询。
- 不在同层复合查询混用不同连接词。
- 不在 `CALL { ... }` 内放 DDL/DML。
- 不在没有聚合函数时生成 `GROUP BY`。
- 不把子查询表达式放 `ORDER BY`。
- 不在 `VALUE { ... }` 末尾省略 `RETURN`。
- 不打乱 pattern 填充器组件顺序。
- 不在没有图上下文时默认加 `USE`。
- 不在没有采样需求时默认加 `SAMPLE`。
- 不在 KNN 中拼 `APPROX` 或 ANN OPTIONS。
- 不把 `FOR` 误用成图遍历。
- 不把任何图模式中的单变量过滤留在外层 `WHERE`（必须下沉到对应 pattern）。
- 不生成裸图模式谓词作为布尔条件，例如 `WHERE NOT (a)-[:T]-(b)` 或 `WHERE (a)-[:T]-(b)`；必须改成 `NOT EXISTS { MATCH ... }` 或 `EXISTS { MATCH ... }`。
- 不把“但不是/不是…/没有…关系/排除…”这类自然语言排除条件翻译成裸 `NOT (pattern)`；必须生成 `NOT EXISTS { MATCH ... }`。
- 不跨 `NEXT` 引用未返回的列。
- 不假设 `OFFSET` 接受负数。
- 不生成不支持的路径语法（`|+|`、`|`、`?`、`KEEP`、`SHORTEST n GROUPS`、`IS DIRECTED`）。

## Quality Bar
完成前检查：
- 给出了完整 GQL（不只是解释）？
- 至少包含主干和结果语句？
- 占位符和假设写清楚了？
- 过滤放置遵循三级优先级？
- 图模式包含/排除过滤是否使用 `EXISTS { MATCH ... }` / `NOT EXISTS { MATCH ... }`？
- 若输入里有“但不是/不是…的人/没有…关系/排除…”这类排除语义，是否已经映射成 `NOT EXISTS { MATCH ... }` 而不是裸 `NOT (pattern)`？
- 聚合分组逻辑自洽？
- 排序分页顺序正确？
- `CALL` 后跟了结果语句？
- 未越界到过程定义/算法？
- （迁移场景）是否已消除所有 Cypher/nGQL 残留语法？
- （迁移场景）`id(v)` 是否已按语义正确改写？
- （迁移场景）nGQL `==` 是否已改为 `=`？
- （迁移场景）nGQL `v.tag.prop` 是否已去掉 tag 前缀？
- （迁移场景）nGQL `[:T1|T2]` 多边类型是否已拆分？
- （迁移场景）nGQL `rank(edge)` / `properties()` / `src()`/`dst()` 是否已消除？
- （迁移场景）Cypher `^` 求幂 / `exists()` / 运算符形式字符串匹配是否已改写？
- （迁移场景）所有函数是否均存在于 GQL 文档中（如 `power()` 而非 `pow()`，`like()` / `contains()` 而非 `starts_with()` / `ends_with()`）？
- （迁移场景）是否存在 ACYCLIC + all_different() 冗余？
- （迁移场景）Cypher Label / nGQL Tag 是否已正确映射为 GQL Label（名称可直接复用）？
- （迁移场景）是否附带了关键改写差异说明？

详细检查清单见 [validation.md](validation.md)。

## Output Preferences
- 先输出 GQL，再输出说明。
- 默认中文说明，关键字保留 GQL 原文。
- 信息不足时继续给草稿，不先停下来追问。

## Routing Guardrails
出现以下信号时停止扩展，改路由到 `gql-procedure-generator`：
- 要求 `CREATE/ALTER/DROP PROCEDURE`
- 要求 `WHILE` 主循环结合图计算
- 要求 `match_compute_statement`、`NODE VALUE`、`ACTIVE_SET`
- 要求逐轮 frontier 传播、BFS/SSSP 等算法过程体

仅出现 `CALL` / `OPTIONAL CALL` + 结果收口时保持在本 skill。
