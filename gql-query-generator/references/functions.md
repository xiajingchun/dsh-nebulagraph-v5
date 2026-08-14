# Functions Reference

本文件是常用函数的选型与组合约束，不是完整函数白名单。保留或生成任意函数前，先在 [documented-functions.md](documented-functions.md) 中按完整函数名精确搜索并核对签名、Database/Analytics 范围、输入类型和前置条件。目录内函数即使未在本文件或 feature 中出现，也可按文档生成；目录外名称除用户明确提供的已安装 UDF 外不得生成。

## Function Family Selection
当用户没给明确函数名时，按需求落到函数家族：

| 需求域 | 优先函数家族 |
|--------|-------------|
| 聚合统计 | 聚合函数 + 检查 `GROUP BY` |
| 列表处理 | 列表函数或 `FOR` |
| 字符串清洗 | 字符串函数 |
| 数值计算 | 数学函数 |
| 日期时间 | temporal 函数 |
| 向量相似度 | vector 家族 |
| 全文检索 | fulltext 家族（需已建索引） |
| 地理计算 | ST_* 家族（需 Geography 类型） |
| 高阶列表处理 | lambda 家族 |

无法确认具体函数时，退回 `MATCH + WHERE + RETURN` 结构。

## Graph Element Functions
- `element_id(<node>)` — 节点内部身份值；不接受边
- `left_node_id(<edge>)` / `right_node_id(<edge>)` — 边的端点 ID
- `start_node_id(<edge>)` / `end_node_id(<edge>)` — 有向边的起点/终点内部 ID；无向边分别返回较小/较大内部 ID
- `multiedge_id(<edge>)` — 边的 multiedge key / rank；需要唯一定位边时还要结合端点与类型
- `labels(<element>)` — 元素标签列表
- `type(<element>)` — 节点或边的元素类型
- `nodes(<path>)` / `edges(<path>)` — 路径中的点/边列表
- `typeof(<expr>)` — 值类型名称字符串

**注意**：当前没有内置 `id()` 函数。节点身份用 `element_id(node)`；边没有 `element_id(edge)`，按需求使用 `start_node_id(edge)`、`end_node_id(edge)`、`type(edge)` 与 `multiedge_id(edge)`。代码中的 `property_exists()` 未被 v5.3.0 用户文档公开，不得默认生成；普通非 NULL 检查使用 `<element>.<prop> IS NOT NULL`。

## Temporal Functions
- `duration_between(<t1>, <t2>)` — 时间差；可附加 `DAY TO SECOND` / `YEAR TO MONTH`。
- 两侧应是相同时间类型。

## String Functions
- `NORMALIZE(<str>)` — Unicode 规范化（仅单参数形态）；`NORMALIZE(str, form)` 不支持。
- 只在用户明确要求时谨慎尝试。

## List Functions
- `list_distinct(<list>)` — 文档公开的列表去重函数。不要依赖返回元素顺序；适合成员或长度比较等与顺序无关的语义。
- `transform(<list>, x -> <expr>)` — 对列表逐项映射，替代 Cypher `[x IN list | expr]`。
- `filter(<list>, x -> <predicate>)` — 按条件保留元素，可与 `transform()` 组合替代带 `WHERE` 的 Cypher 列表推导式。

**迁移限制**：当前文档没有 `toSet()`。列表去重使用 `list_distinct()`；不要生成未文档化的 `array_distinct()` 别名。`all_different(<elem1>, <elem2>, ...)` 要求至少两个显式图元素参数，不接受单个 LIST，也不是 `toSet()` 的替代函数。

## Lambda Expressions
```gql
<variable> -> <value_expression>
```

只出现在接受 lambda 参数的函数中：
```gql
transform(<list>, x -> <expr>)
filter(<list>, x -> <predicate>)
reduce(<list>, <init>, (acc, x) -> <expr>)
```

规则：
- `transform` — 列表映射。
- `filter` — 按布尔条件保留元素。
- `reduce` — 累积折叠，只在用户明确要求时使用。
- 不生成嵌套 lambda；复杂需求退回普通查询结构。
- Lambda 主体不放聚合或子查询。

## Vector Functions
- 只在输入是向量值时使用。
- 两向量维度必须一致。
- `euclidean()` — 欧氏距离。
- `inner_product()` — 内积。
- `cosine()` — 余弦相似度（仅 KNN）。

## Fulltext Functions
- 只在用户明确要全文检索且已有全文索引时使用。
- 不要主动生成 `ftscore(...)` 一类调用。
- `ftscore()` 不支持 `OR` 组合：不能在同一 WHERE/FILTER 中写 `ftscore(n.a, q) > 0 OR ftscore(n.b, q) > 0`。
- 每个 MATCH 分支中只能对同一节点变量调用一次 `ftscore()`。
- 多属性全文搜索必须拆成多个 MATCH + UNION，最后用 `sum()` 聚合分数。

## Geo Functions
- 只在输入是 `Geography` / WKT 语义时使用。
- 不要把普通坐标条件伪装成 `ST_*` 调用。

## Legacy nGQL Migration
- `id(v)` / `id(e)` 承担业务主键语义 → 改写为 `{id: ...}` 或 `WHERE v.id ...`
- `id(v)` 承担节点身份值语义 → 改写为 `element_id(v)`
- `id(e)` / `rank(e)` 承担边标识语义 → 先明确是否只需要 multiedge key；需要完整定位时组合端点、`type(e)` 与 `multiedge_id(e)`
- 不要把 `id(e)` 机械翻译成不存在的 `element_id(e)`。
