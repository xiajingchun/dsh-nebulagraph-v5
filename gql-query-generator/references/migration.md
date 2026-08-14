# Query Migration Reference — Cypher / nGQL → GQL

本文件为 `gql-query-generator` 提供 Cypher（openCypher）和 nGQL（NebulaGraph 2.x/3.x）到当前 GQL 的语法映射。
当用户输入中包含 Cypher 或 nGQL 语句时，按此映射做最小改写。

## Contents

- Cypher-to-GQL mapping
- nGQL-to-GQL mapping
- Migration decision flow
- Common traps

---

## Migration Function Gate

迁移前先盘点所有函数、运算符和列表推导式，并逐项分类为“同名同签名可保留”“需要映射”或“不支持”。这个步骤也适用于已经含有 `TRAIL`、`LET`、`FILTER` 等 GQL 构造的混合方言输入；不能仅凭语句主体像 GQL 就跳过迁移审计。

同名函数只有在完整 [documented-functions.md](documented-functions.md) 中存在同名、同签名且环境匹配的条目时才能保留；[functions.md](functions.md) 只提供高频选型与组合约束，不是第二白名单。随包 feature 和代码只能验证实现边界，不能单独授权未文档化函数。没有文档证据时，映射为公开构造或明确说明不支持。

## 1. Cypher → GQL 映射

### 1.1 图模式与路径

| Cypher | GQL | 说明 |
|--------|-----|------|
| `(n:Label)` | `(n:Label)` 或 `(n IS Label)` | 两种写法等价；Cypher Label 名可直接作为 GQL Label 使用 |
| `(n:A:B)` | `(n:A&B)` 或 `(n:A:B)` | 多标签 |
| `-[:T*1..3]->` | `-[:T]->{1,3}` | 变长路径量词后置 |
| `-[:T*]->` | `-[:T]->*` | 零到无穷跳 |
| `-[:T*1..]->` | `-[:T]->+` | 一到无穷跳 |
| `-[:T*3]->` | `-[:T]->{3}` | 恰好 N 跳 |
| `-[:T*0..3]->` | `-[:T]->{0,3}` | 含零跳（匹配起点自身） |
| `[:T\|T2]` | `-[:T\|T2]->` | GQL 支持标签表达式析取 `\|`（等价语义），直接保留即可 |
| `shortestPath((a)-[*]->(b))` | `ANY SHORTEST PATH (a)-[]->*(b)` | 最短路 |
| `allShortestPaths((a)-[*]->(b))` | `ALL SHORTEST (a)-[]->*(b)` | 全部最短路 |
| `(a)-[*]-(b)` (任意方向) | `(a)-[]-*(b)` | 任意方向变长 |
| `(a)-[e:T*2]->(b) WHERE e[0].prop` | `(a)-[e:T]->{2}(b)` + `(e[0]).prop` | 变长边下标访问 |

**Label 映射说明**：Cypher 的 Label 名可直接作为 GQL Label 使用，无需改名。例如 `(n:Person)` 在 GQL 中仍写为 `(n:Person)`。

**路径模式前缀**：GQL 支持 `WALK`（默认）、`TRAIL`（不重复边）、`ACYCLIC`（不重复点）、`SIMPLE`（除起始点外不重复点）。

**ACYCLIC 与 all_different() 的关系**：
- `ACYCLIC` 是路径模式前缀，声明式地约束整条路径中所有点两两不同
- `all_different(v1, v2, ...)` 是 WHERE 子句中的谓词函数，手动检查指定变量两两不同
- `all_different(nodes(path))` 或 `all_different(pathNodes)` 无效：单个 LIST 不能代替至少两个显式图元素参数
- `size(apoc.coll.duplicates(nodes(path))) = 0` 或去重前后长度相等表示路径节点不重复，直接改为 `ACYCLIC`，不要物化 `nodes(path)` 再去重比较
- 当源查询用去重前后长度差来**筛选含重复节点的路径**时，保留 `WALK`/`TRAIL` 与该过滤条件；不要改成语义相反、会排除重复节点的 `ACYCLIC`
- 当 ACYCLIC 路径中的所有点变量都在 `all_different()` 中列出时，两者是**冗余**的，只需保留 `ACYCLIC` 即可
- 仅在需要跨多条路径或检查非路径中的变量时，才额外使用 `all_different()`

### 1.2 子句映射

| Cypher | GQL | 说明 |
|--------|-----|------|
| `WITH x, y` | `RETURN x, y NEXT` | 中间投影用 `RETURN...NEXT` 串联 |
| `WITH x ORDER BY x.a LIMIT 10` | `RETURN x ORDER BY x.a LIMIT 10 NEXT` | 含排序分页的中间投影 |
| `UNWIND list AS x` | `FOR x IN list` | 展开列表 |
| `UNWIND range(1,10) AS i` | `FOR i IN LIST[1,2,...,10]` 或 `FOR i IN range(1,10)` | 展开序列 |
| `RETURN ... SKIP n` | `RETURN ... OFFSET n` | 分页偏移（GQL 也接受 `SKIP`） |
| `OPTIONAL MATCH` | `OPTIONAL MATCH` | 相同 |
| `MATCH ... WHERE ... RETURN` | `MATCH ... WHERE ... RETURN` | 基础结构相同 |
| `MATCH ... YIELD` | **不支持** — 改用 `MATCH ... RETURN` | |
| `CALL proc() YIELD x` | `CALL proc() YIELD x RETURN x` | GQL 要求 `CALL` 后必须跟结果语句 |
| `CALL proc() YIELD x MATCH ...` | `CALL proc() YIELD x RETURN x NEXT MATCH ...` | CALL 输出需 RETURN...NEXT 传递给后续语句 |

### 1.3 Neo4j 过程与 APOC → GQL 原生替代

> **核心规则**：GQL 不支持 Neo4j 命名空间过程（`db.*`、`apoc.*`、`gds.*`、`dbms.*`）。遇到这些过程必须**完全重写**为 GQL 原生语法，而不是保留 CALL 并仅做格式调整。

| Neo4j 过程 | GQL 等价方案 | 说明 |
|-----------|-------------|------|
| `CALL db.index.fulltext.queryNodes('idx', 'text') YIELD node, score` | `MATCH (node@Type) LET score = ftscore(node.prop, 'text') WHERE score > 0 RETURN node, score` | 全文搜索用 `ftscore()` 函数（BM25 算法），不需 CALL |
| `CALL db.index.fulltext.queryRelationships(...)` | 类似 `ftscore(e.prop, 'text')` 在边模式中使用 | 边的全文搜索 |
| `CALL db.index.fulltext.createNodeIndex(...)` | `CREATE FULLTEXT INDEX name ON NODE type(prop)` | DDL，不是过程调用 |
| `CALL apoc.path.expandConfig(...)` | 改写为 MATCH + UNION ALL 分层展开（见下方详细示例） | 需分析 relationshipFilter 逐层展开 |
| `CALL apoc.path.subgraphAll(...)` | 改写为 MATCH 变长路径 | |

**apoc.path.expandConfig 转换详解**：

`relationshipFilter` 语法：`TYPE>` 出方向、`<TYPE` 入方向、`TYPE` 任意方向；`,` 分隔层级；`|` 同层级多类型析取。

转换规则：
1. 分析 `relationshipFilter` 的每个层级，识别边类型和方向
2. `uniqueness: "NODE_GLOBAL"` → 使用 `ACYCLIC` 路径模式前缀
3. `minLevel` ~ `maxLevel` → 对每个层级深度用 `UNION ALL` 合并
4. **同层级多边类型用标签表达式 `[:T1|T2]`**，不要用 `type(r) IN [...]`

```
-- Cypher: apoc.path.expandConfig 示例
MATCH (a:Application {code: 'MNR'})
CALL apoc.path.expandConfig(a, {
  relationshipFilter: 'HAS_SERVICE>,PUBLISH_MESSAGE>|SUBSCRIBE_QUEUE>|OWNS_BACKING_SERVICE>|DEPENDS_ON>,SUBSCRIBE_TOPIC,<PUBLISH_MESSAGE|<SUBSCRIBE_QUEUE',
  minLevel: 1, maxLevel: 4,
  uniqueness: 'NODE_GLOBAL'
})
YIELD path
RETURN path

-- ❌ 错误写法：用 type() IN [] 代替标签表达式
MATCH p = ACYCLIC (a:Application {code: 'MNR'})-[:HAS_SERVICE]->(n1)
  -[r2 WHERE type(r2) IN ['PUBLISH_MESSAGE','SUBSCRIBE_QUEUE','OWNS_BACKING_SERVICE','DEPENDS_ON']]->(n2)
RETURN p AS path

-- ✅ 正确写法：用标签表达式
MATCH p = ACYCLIC (a:Application {code: 'MNR'})-[:HAS_SERVICE]->(n1)
RETURN p AS path
UNION ALL
MATCH p = ACYCLIC (a:Application {code: 'MNR'})-[:HAS_SERVICE]->(n1)
  -[:PUBLISH_MESSAGE|SUBSCRIBE_QUEUE|OWNS_BACKING_SERVICE|DEPENDS_ON]->(n2)
RETURN p AS path
UNION ALL
MATCH p = ACYCLIC (a:Application {code: 'MNR'})-[:HAS_SERVICE]->(n1)
  -[:PUBLISH_MESSAGE|SUBSCRIBE_QUEUE|OWNS_BACKING_SERVICE|DEPENDS_ON]->(n2)
  -[:SUBSCRIBE_TOPIC]-(n3)
RETURN p AS path
UNION ALL
MATCH p = ACYCLIC (a:Application {code: 'MNR'})-[:HAS_SERVICE]->(n1)
  -[:PUBLISH_MESSAGE|SUBSCRIBE_QUEUE|OWNS_BACKING_SERVICE|DEPENDS_ON]->(n2)
  -[:SUBSCRIBE_TOPIC]-(n3)
  <-[:PUBLISH_MESSAGE|SUBSCRIBE_QUEUE]-(n4)
RETURN p AS path
```
| `CALL apoc.periodic.iterate(...)` | 无直接等价 — 业务层批处理 | |
| `CALL apoc.create.node(...)` | `INSERT (:Type{...})` | |
| `CALL apoc.merge.node(...)` | `INSERT OR UPDATE (:Type{...})` | |
| `CALL db.labels()` | `SHOW NODE TYPES` | |
| `CALL db.relationshipTypes()` | `SHOW EDGE TYPES` | |
| `CALL db.propertyKeys()` | 无直接等价 — 查 catalog | |
| `CALL dbms.components()` | `CALL version(true)` | |
| `CALL gds.*` | 无直接等价 — 用 UDP / procedure 实现 | |

**ftscore() 使用要点**：
- 语法：`ftscore(property_expr, query_string) -> DOUBLE`
- 必须先创建全文索引：`CREATE FULLTEXT INDEX idx ON NODE Type(prop)`
- 每个索引只覆盖**一个** STRING 属性；Neo4j 多属性索引需拆成多次 `ftscore()` 调用
- 返回 0.0 表示不匹配，> 0 表示匹配（BM25 得分）
- 用 `WHERE ftscore(...) > 0` 过滤，或用 `ORDER BY ftscore(...) DESC` 按相关性排序
- **`ftscore()` 不支持 `OR` 组合**：不能在同一 WHERE 中写 `ftscore(n.a, q) > 0 OR ftscore(n.b, q) > 0`。多属性搜索必须拆成多个 MATCH + UNION，最后用 `sum()` 聚合分数
- **每个 MATCH 子句中只能对同一节点变量调用一次 `ftscore()`**；需要搜索多个属性时，每个属性单独一个 MATCH 分支，通过 UNION 合并

**Neo4j 多属性全文索引的 GQL 等价模式**：
```
-- Neo4j: 索引覆盖 summary + description 两个属性
CALL db.index.fulltext.queryNodes("idx_name", "search text") YIELD node, score

-- ❌ 错误写法：ftscore 不支持 OR 组合
MATCH (node:<Type>)
LET s1 = ftscore(node.summary, 'search text')
LET s2 = ftscore(node.description, 'search text')
WHERE s1 > 0 OR s2 > 0
RETURN node, s1 + s2 AS score

-- ✅ 正确写法：每个属性单独 MATCH，用 UNION 合并后 sum 聚合
{
  MATCH (node:<Type>)
  LET score = ftscore(node.summary, 'search text')
  FILTER WHERE score > 0
  RETURN node, score
  UNION
  MATCH (node:<Type>)
  LET score = ftscore(node.description, 'search text')
  FILTER WHERE score > 0
  RETURN node, score
}
NEXT
RETURN DISTINCT node, sum(score) AS score
ORDER BY score DESC
```

**多属性全文搜索 + 后续图匹配的完整模式**：
```
-- 若搜索结果还需关联其他图模式，在 UNION 聚合之后用 NEXT 传递
{
  MATCH (node:<Type>)
  LET score = ftscore(node.summary, 'search text')
  FILTER WHERE score > 0
  RETURN node, score
  UNION
  MATCH (node:<Type>)
  LET score = ftscore(node.description, 'search text')
  FILTER WHERE score > 0
  RETURN node, score
}
NEXT
RETURN DISTINCT node, sum(score) AS score
NEXT
MATCH (node)-[]-(related:RelatedType)
RETURN node, related, score
ORDER BY score DESC
```

**CALL ... YIELD 后接 MATCH 的正确处理**：
- 若过程是 GQL 支持的（如 `show_graphs()`、用户自定义 UDP），保留 `CALL ... YIELD x RETURN x NEXT MATCH ...`
- 若过程是 Neo4j 特有的（`db.*`/`apoc.*`/`gds.*`/`dbms.*`），**不保留 CALL**，改写为 GQL 原生语句

### 1.4 写操作

| Cypher | GQL | 说明 |
|--------|-----|------|
| `CREATE (n:T {p:v})` | `INSERT (:T {p:v})` | 创建节点 |
| `CREATE (a)-[:T]->(b)` | `INSERT (a)-[:T]->(b)` | 创建边 |
| `MERGE (n:T {p:v})` | `INSERT OR UPDATE (:T {p:v})` | 不存在则创建，存在则更新 |
| `SET n.prop = val` | `SET n.prop = val` | 更新属性（相同） |
| `SET n:NewLabel` | `SET n:NewLabel` | 追加标签（相同） |
| `REMOVE n.prop` | `SET n.prop = NULL` | 删除属性 |
| `REMOVE n:Label` | 无直接等价 | |
| `DELETE n` | `NODETACH DELETE n` | 仅删除节点（有边报错） |
| `DETACH DELETE n` | `DETACH DELETE n` | 删除节点及其边 |

### 1.5 表达式与函数

| Cypher | GQL | 说明 |
|--------|-----|------|
| `id(n)` | `element_id(n)` | 图元素身份值 |
| `labels(n)` | `labels(n)` | 相同 |
| `type(r)` | `type(r)` | 相同 |
| `properties(n)` | 无直接等价 — 逐属性返回 | |
| `keys(n)` | 无直接等价 — 逐属性返回 | |
| `exists(n.prop)` | `n.prop IS NOT NULL` | 文档公开的 NULL 谓词；若必须区分属性缺失与 NULL，明确说明没有可靠等价构造 |
| `n.prop IS NOT NULL` | `n.prop IS NOT NULL` | 相同 |
| `coalesce(a, b)` | `COALESCE(a, b)` | 相同 |
| `toString(x)` | `CAST(x AS STRING)` | 类型转换 |
| `toInteger(x)` | `CAST(x AS INT64)` | 类型转换 |
| `toFloat(x)` | `CAST(x AS DOUBLE)` | 类型转换 |
| `toBoolean(x)` | `CAST(x AS BOOL)` | 类型转换 |
| `collect(x)` | `collect_list(x)` 或 `collect(x)` | 两者等价（GQL 中均为合法同义函数） |
| `count(x)` | `count(x)` | 相同 |
| `sum/avg/min/max` | `sum/avg/min/max` | 相同 |
| `size(list)` | `size(list)` | 相同 |
| `length(path)` | `length(path)` | 相同 |
| `nodes(path)` | `nodes(path)` | 相同 |
| `relationships(path)` | `relationships(path)` / `edges(path)` | GQL 两者均可 |
| `startNode(r)` | 无直接等价 — 用 pattern 绑定起终点 | |
| `endNode(r)` | 无直接等价 — 用 pattern 绑定起终点 | |
| `head(list)` | `head(list)` | 取首元素（GQL 同名函数） |
| `last(list)` | `back(list)` | 取尾元素（GQL 用 `back()`） |
| `tail(list)` | `tail(list)` | 去首元素后的剩余列表（GQL 同名函数） |
| `toSet(list)` | `list_distinct(list)` | 文档公开的列表去重函数；不要使用未文档化别名或 `all_different(list)` |
| `reverse(list)` | 无直接等价 — 用 lambda 或业务逻辑 | |
| `x STARTS WITH 'a'` | `like(x, 'a%')` | GQL 无 `starts_with` 函数，用 `like()` 替代 |
| `x ENDS WITH 'a'` | `like(x, '%a')` | GQL 无 `ends_with` 函数，用 `like()` 替代 |
| `x CONTAINS 'a'` | `contains(x, 'a')` | GQL 用小写 `contains()` 函数 |
| `x =~ 'regex'` | `regexp_like(x, 'regex')` | GQL 用 `regexp_like()` 函数 |
| `x ^ y` (求幂) | `power(x, y)` | Cypher 用 `^`，GQL 用 `power()` 函数 |
| `=` (等值比较) | `=` | Cypher 和 GQL 相同 |
| `[x IN list WHERE p \| expr]` | `transform(filter(list, x -> p), x -> expr)` | 列表推导 |
| `[x IN list \| expr]` | `transform(list, x -> expr)` | 列表映射 |
| `reduce(acc=init, x IN list \| expr)` | `reduce(list, init, (acc, x) -> expr)` | 累积折叠 |
| `any(x IN list WHERE pred)` | `filter(list, x -> pred)` + 判断非空 | 用 lambda 过滤后检查 |
| `all(r IN relationships(p) WHERE pred(r))` | 量化边段内 `-[r:T WHERE pred(r)]->{m,n}` | 仅当谓词 edge-local 且该段一一覆盖 `relationships(p)`；否则保留结果级检查 |
| `all(x IN list WHERE pred)` | 用 `filter()` + `length()` 检查 | 非路径边局部特例 |
| `none(x IN list WHERE pred)` | 用 `filter()` + `length() = 0` 检查 | |
| `single(x IN list WHERE pred)` | `length(filter(list, x -> pred)) = 1` | |

### 1.6 子查询与存在性

| Cypher | GQL | 说明 |
|--------|-----|------|
| `EXISTS { MATCH (n)-[]->(m) }` | `EXISTS { MATCH (n)-[]->(m) }` | 基本相同 |
| `WHERE EXISTS((n)-[:T]->())` | `WHERE EXISTS { MATCH (n)-[:T]->() }` | GQL 需完整子查询 |
| `WHERE NOT (a)-[:T]-(b)` | `WHERE NOT EXISTS { MATCH (a)-[:T]-(b) }` | 图模式排除用 `NOT EXISTS` 相关子查询 |
| `CALL { WITH n MATCH ... RETURN ... }` | `CALL { MATCH ... RETURN ... }` | GQL 子查询自动捕获外层变量，不需 `WITH` 导入 |

### 1.7 控制流

| Cypher | GQL | 说明 |
|--------|-----|------|
| `FOREACH (x IN list \| SET ...)` | `FOR x IN list SET ...` 或拆分为多步 | 视具体场景 |
| `UNION / UNION ALL` | `UNION [DISTINCT\|ALL]` | 相同语义 |

---

## 2. nGQL → GQL 映射

### 2.1 查询语句

| nGQL | GQL | 说明 |
|------|-----|------|
| `GO FROM "id" OVER edge_type YIELD dst(edge) AS id` | `MATCH (v{id:"id"})-[:edge_type]->(v2) RETURN v2` | GO → MATCH |
| `GO FROM "id" OVER edge_type REVERSELY` | `MATCH (v{id:"id"})<-[:edge_type]-(v2) RETURN v2` | 反向遍历 |
| `GO FROM "id" OVER edge_type BIDIRECT` | `MATCH (v{id:"id"})-[:edge_type]-(v2) RETURN v2` | 双向遍历 |
| `GO 1 TO 3 STEPS FROM "id" OVER T` | `MATCH (v{id:"id"})-[:T]->{1,3}(v2) RETURN v2` | 多跳遍历 |
| `GO FROM "id" OVER T WHERE properties(edge).p > 10` | `MATCH (v{id:"id"})-[e:T WHERE e.p > 10]->(v2) RETURN v2` | GO + 边属性过滤 |
| `GO FROM "id" OVER follow\|serve` | `MATCH (v{id:"id"})-[:follow\|serve]->(v2) RETURN v2` | 多边类型用标签表达式 |
| `FETCH PROP ON tag "id" YIELD ...` | `MATCH (v:tag{id:"id"}) RETURN v.prop ...` | FETCH → MATCH |
| `LOOKUP ON tag WHERE ... YIELD ...` | `MATCH (v:tag WHERE ...) RETURN ...` | LOOKUP → MATCH |
| `FIND SHORTEST PATH FROM "a" TO "b" OVER *` | `MATCH p = ANY SHORTEST PATH (a{id:"a"})-[]->*(b{id:"b"}) RETURN p` | 最短路 |
| `FIND ALL PATH FROM "a" TO "b" OVER * UPTO 5 STEPS` | `MATCH p = (a{id:"a"})-[]->{1,5}(b{id:"b"}) RETURN p` | 所有路径 |
| `GET SUBGRAPH FROM "id"` | `MATCH p = (v{id:"id"})-[]->*(v2) RETURN p` | 子图 → MATCH 路径 |
| `GET SUBGRAPH WITH PROP FROM "id" YIELD VERTICES AS v` | `MATCH (v{id:"id"})-[]->*(v2) RETURN v2` | 含属性子图 |
| `MATCH (v) WHERE id(v) == 'id'` | `MATCH (v{id: 'id'})` 或 `MATCH (v) WHERE element_id(v) = 'id'` | VID 匹配（注意 `==` → `=`） |
| `MATCH (v) WHERE id(v) IN ['a','b']` | `MATCH (v WHERE element_id(v) IN ['a','b'])` | 多 VID 匹配 |

### 2.2 结果子句与运算符

| nGQL | GQL | 说明 |
|------|-----|------|
| `YIELD` | `RETURN` | 结果投影 |
| `YIELD DISTINCT` | `RETURN DISTINCT` | 去重 |
| `\| (管道)` | `RETURN ... NEXT` 或 `CALL { ... }` | 管道改用 NEXT 或子查询 |
| `$-.column` | 直接用列别名 | 中间变量引用 |
| `$^.tag.prop` | 起点变量属性（如 `v.prop`） | 源点属性 |
| `$$.tag.prop` | 终点变量属性（如 `v2.prop`） | 目标点属性 |
| `==` (等值比较) | `=` | nGQL 用 `==`，GQL 用 `=` |
| `=` (赋值) | `=` (赋值) | 相同语义 |
| `WITH ... AS ...` | `RETURN ... AS ... NEXT` | nGQL 的 openCypher 兼容部分 |
| `UNWIND list AS x` | `FOR x IN list` | nGQL 的 openCypher 兼容部分 |

### 2.3 属性与标识

| nGQL | GQL | 说明 |
|------|-----|------|
| `id(v)` (业务主键) | `v.id` 或 `{id: ...}` | 先判断语义再改写 |
| `id(v)` (元素身份值) | `element_id(v)` | 仅在确认是身份值时使用 |
| `WHERE id(v) == 'player100'` | `MATCH (v{id: 'player100'})` | VID 过滤下沉到 pattern |
| `WHERE id(v) IN ['a','b']` | `MATCH (v WHERE element_id(v) IN ['a','b'])` | 多 VID 过滤 |
| `v.tag.prop` | `v.prop` | GQL 属性直接挂在元素上，不需 tag 前缀 |
| `v.player.name` | `v.name` | 去掉 tag 前缀 |
| `e.edge_type.prop` | `e.prop` | 边属性同理去前缀 |
| `Tag` | `Label` | 概念等价；nGQL Tag 名可直接作为 GQL Label 使用 |
| `Edge Type` | `Edge Label` 或 `Edge Type` | nGQL Edge Type 名可直接作为 GQL Edge Label 使用 |
| `src(edge)` | 用起点变量（如 `v`） | GO 场景特有函数 |
| `dst(edge)` | 用终点变量（如 `v2`） | GO 场景特有函数 |
| `rank(edge)` | `multiedge_id(edge)` | edge rank / multiedge key |
| `properties(v)` | 无直接等价 — 逐属性返回 | |
| `properties(edge)` | 无直接等价 — 用边变量属性 | |
| `keys(properties(v))` | 无直接等价 | |
| `exists(v.player.age)` | `v.age IS NOT NULL` | 属性存在检查（去 tag 前缀 + `IS NOT NULL`） |
| `v[toLower("AGE")]` | 无直接等价 — 用明确属性名 | 动态属性访问 |

### 2.4 写操作

| nGQL | GQL | 说明 |
|------|-----|------|
| `INSERT VERTEX t(p1,p2) VALUES "id":(v1,v2)` | `INSERT (:t{id:"id", p1:v1, p2:v2})` | 插入节点 |
| `INSERT EDGE e(p) VALUES "a"->"b":(v)` | `INSERT ({id:"a"})-[:e{p:v}]->({id:"b"})` | 插入边 |
| `UPDATE VERTEX "id" SET t.p = v` | `MATCH (v:t{id:"id"}) SET v.p = v_val` | 更新节点 |
| `UPSERT VERTEX "id" SET t.p = v` | `INSERT OR UPDATE (:t{id:"id", p:v})` | 存在则更新，不存在则创建 |
| `DELETE VERTEX "id"` | `MATCH (v{id:"id"}) DETACH DELETE v` | 删除节点 |
| `DELETE EDGE e "a"->"b"` | `MATCH ({id:"a"})-[e:e_type]->({id:"b"}) DELETE e` | 删除边 |

### 2.5 管理与 Schema

| nGQL | GQL | 说明 |
|------|-----|------|
| `CREATE TAG t(...)` | `CREATE NODE TYPE t(...)` 或对应 DDL | Schema 定义 |
| `CREATE EDGE TYPE e(...)` | `CREATE EDGE TYPE e(...)` | Schema 定义 |
| `USE space_name` | `USE graph_name` | nGQL 称 Space，GQL 称 Graph |
| `SHOW TAGS` | `SHOW NODE TYPES` 或对应 catalog 查询 | |
| `SHOW EDGES` | `SHOW EDGE TYPES` 或对应 catalog 查询 | |
| `DESCRIBE TAG t` | `DESCRIBE NODE TYPE t` 或对应 catalog 查询 | |
| `CREATE INDEX ON tag(prop)` | 对应 GQL 索引 DDL | |
| `REBUILD TAG INDEX idx` | 无直接等价 — GQL 索引自动生效 | |

### 2.6 nGQL 特有概念（无 GQL 等价）

| nGQL 概念 | 说明 |
|-----------|------|
| Edge Rank (`@rank`) | 改写为 `multiedge_id(e)`；完整边定位还需结合起点、终点与 `type(e)` |
| `CREATE SPACE` (Graph Space) | nGQL 的图空间概念，包含分区数、副本数等存储配置。GQL 中用 `CREATE GRAPH` 或直接 `USE` |
| `VID` (Vertex ID) | nGQL 中 VID 是用户指定的，等价于 GQL 中的业务主键属性（如 `id`）。不要与 `element_id()` 混淆 |
| `INNER JOIN` | nGQL 特有的表连接语法。GQL 中用 MATCH 多 pattern 或子查询替代 |
| `$var` (用户自定义变量) | nGQL 中 `$var = ...` 赋值后在管道中使用。GQL 中用 `LET` 或 `RETURN...NEXT` |

---

## 3. 迁移决策流程

```
输入语句
  ├─ 识别语言特征
  │   ├─ 含 GO/FETCH/LOOKUP/$-/$^/$$./YIELD → nGQL
  │   ├─ 含 WITH(中间投影)/UNWIND/MERGE/shortestPath()/[:T*] → Cypher
  │   ├─ 含 CALL db.*/apoc.*/gds.*/dbms.* → Neo4j 特有过程，需完全重写
  │   └─ 已是 GQL → 跳过迁移，直接优化
  │
  ├─ 按映射表逐条改写
  │   ├─ 结构改写（子句级）
  │   ├─ 函数改写
  │   └─ 表达式改写
  │
  ├─ 应用 GQL 规则
  │   ├─ 过滤条件下沉到 pattern（三级优先级）
  │   ├─ 锚点/已绑定变量放左侧
  │   └─ 线性查询以 RETURN/FINISH 收口
  │
  └─ 输出：GQL 查询 + 改写说明 + 假设/差异提示
```

## 4. 常见陷阱

| 陷阱 | 正确做法 |
|------|----------|
| 机械把 `id(v)` 翻译成 `element_id(v)` | 先判断是业务主键还是身份值 |
| 保留 Cypher 的 `WITH` | 改为 `RETURN ... NEXT` |
| 保留 `[:T*1..3]` 量词 | 改为 `-[:T]->{1,3}` |
| nGQL `v.tag.prop` 直接保留 | 去掉 tag 前缀，改为 `v.prop` |
| nGQL 管道 `\|` 直接保留 | 改为 `RETURN ... NEXT` 或 `CALL { ... }` |
| Cypher `CALL { WITH n ... }` 保留 `WITH` 导入 | GQL 子查询自动捕获外层变量，删除 `WITH` |
| Cypher `collect(x)` 直接保留 | 改为 `collect_list(x)` |
| YIELD 后无结果语句 | 补上 `RETURN` |
| nGQL `$-.col` 引用 | 改为直接使用列别名 |
| nGQL `==` 等值比较直接保留 | 改为 `=`（GQL 中 `=` 既是比较又是赋值） |
| nGQL `WHERE id(v) == 'x'` 留在外层 WHERE | 下沉到 pattern `{id: 'x'}` 或 pattern WHERE |
| nGQL `allShortestPaths` 直接保留 | 改为 `ALL SHORTEST`（去掉函数包装） |
| nGQL `properties(v)` / `keys(...)` 直接保留 | 改为逐属性返回，无直接等价函数 |
| nGQL `src(edge)` / `dst(edge)` 直接保留 | 改为 pattern 中绑定的起终点变量 |
| nGQL edge `@rank` 语法保留 | 改为 `multiedge_id(e)`；不要生成 `element_id(e)` |
| Cypher `^` 求幂直接保留 | 改为 `power(x, y)` |
| Cypher `STARTS WITH` 作为运算符保留 | 改为 `like(x, 'prefix%')` 或 `contains(x, 'sub')`；GQL 无 `starts_with` 函数 |
| 忽略 nGQL MATCH 中的 `v.player.name` | 必须去掉 tag 前缀改为 `v.name` |
| `ACYCLIC` 路径中再写 `all_different()` 列出所有点 | 仅保留 `ACYCLIC`，删除冗余的 `all_different()` |
| 使用 GQL 文档中不存在的函数（如 `pow()`、`starts_with()`） | 仅使用文档中存在的函数（如 `power()`、`like()`、`contains()`） |
| 改写 Cypher Label / nGQL Tag 时改名 | 直接复用原名作为 GQL Label |
| nGQL `exists(v.tag.prop)` 或 Cypher `exists(n.prop)` 直接保留 | 常见属性检查改为 `v.prop IS NOT NULL`；若必须区分属性缺失与 NULL，说明不支持，不调用未文档化的 `property_exists()` |
| Neo4j `CALL db.index.fulltext.queryNodes(...)` 直接保留 | GQL 不支持 `db.*` 过程；改为 `ftscore()` 函数 + MATCH |
| 多属性 `ftscore()` 用 `OR` 组合 | `ftscore()` 不支持 `OR`；必须拆成 UNION + `sum()` 聚合 |
| Neo4j `CALL apoc.*` 直接保留 | GQL 不支持 `apoc.*` 过程；必须完全重写为 GQL 原生语法 |
| 多边类型用 `type(r) IN [...]` 代替标签表达式 | 优先用标签表达式 `-[:T1\|T2]->`；仅在需要动态边类型列表时才用 `type()` |
| `CALL neo4j过程() YIELD x MATCH (x)` 直接加 `RETURN x NEXT` 桥接 | 若过程本身不存在，整个 CALL 需重写为 GQL 原生语句，不做机械桥接 |
