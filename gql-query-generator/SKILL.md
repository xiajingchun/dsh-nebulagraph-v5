---
name: gql-query-generator
description: 根据自然语言生成、改写、补全或迁移 NebulaGraph 5.3.0 GQL 查询。Use for DQL, MATCH, FILTER, RETURN, WHERE, YIELD, ORDER BY, GROUP BY, LIMIT, OFFSET, CALL, graph patterns, expressions, variables, statement blocks, nearest-neighbor queries, parameterized queries, error-driven rewrites, and Cypher/openCypher or nGQL-to-GQL migration. Do not use for graph algorithms or traversal procedures that require match_compute_statement.
---

# GQL Query Generator

生成以 NebulaGraph `5.3.0` 为兼容基线的可执行 GQL 查询。优先输出查询本身；只在 schema、图名或业务语义不完整时补充最少假设。

## Workflow

1. 判断目标是查询还是过程。若用户要定义过程、实现图算法或使用 `match_compute_statement`，切换到 `gql-procedure-generator`。
2. 提取图名、节点/边类型与标签、属性、方向、过滤、聚合、排序、分页和返回列。未知标识符使用 `<graph_name>`、`<node_type>` 等占位符，不臆造 schema。
3. 选择最小查询骨架：单段 `MATCH ... RETURN`、线性查询、复合查询、命名/内联过程调用、DML 或 statement block。
4. 按下方路由只加载与请求相关的参考。函数先在完整函数目录中按名称精确检索；其它语法先在完整语法目录中按关键字精确检索，再按需读取专题参考。
5. 生成后逐项执行 [validation.md](references/validation.md) 的检查；文档目录内的能力不因缺少 feature 或常用示例而拒绝，只有文档限制或已确认的实现冲突才触发降级。

## Reference Routing

- 查询骨架、子句顺序、DML、statement block 与硬约束：读取 [query-language.md](references/query-language.md) 的相关章节。
- `MATCH`、节点/边/路径模式、方向、路径模式与性能锚点：读取 [patterns.md](references/patterns.md)。
- 动态标签、动态元素类型、K-hop 和 5.3.0 新边界：读取 [v5.3.md](references/v5.3.md)。
- 表达式、谓词、标签表达式或优先级：读取 [expressions.md](references/expressions.md)。
- 保留或生成任意函数，或使用函数页记录的非调用形态：先在 [documented-functions.md](references/documented-functions.md) 中精确搜索函数名、签名、运算符或关键字形式零参函数；再按需读取 [functions.md](references/functions.md) 的常用选型与组合约束。
- 不常见的子句、谓词、表达式、数据类型或 DML：先在 [documented-syntax.md](references/documented-syntax.md) 中精确搜索关键字，再读取对应专题参考。
- KNN/ANN：读取 [nearest-neighbor.md](references/nearest-neighbor.md)。
- Cypher/openCypher 或 nGQL 迁移：读取 [migration.md](references/migration.md)。
- 已有错误码驱动的最小改写：读取 [error-codes.md](references/error-codes.md)。
- 需要完整输出范式或负例时：读取 [examples.md](references/examples.md) 的对应小节。

不要一次性加载全部参考，也不要通读两个完整目录。始终用函数名、子句、谓词、表达式、数据类型或文档键精确定位；只有复杂迁移或多类语法组合时才组合多个参考。

## Core Generation Rules

- 使用 GQL 语法，不混入 Cypher 的 `*1..3`、`WITH`、`UNWIND`、`MERGE` 或 nGQL 的 `GO`、管道、`==`。
- 对生成、改写或迁移任务逐项盘点输入中的函数和源方言表达式，即使语句主体已经混用 GQL 语法。只有在 v5.3.0 用户文档中能确认**同名且同签名**时才原样保留；feature 和代码只能验证实现边界，不能单独授权默认生成未文档化函数。没有文档证据时必须映射为公开构造或明确说明不支持。
- 完整函数与语法目录中存在的能力，只要目标环境、签名、输入类型、前置条件和文档限制匹配，就允许生成；不得因为 [functions.md](references/functions.md)、feature 或示例未单独收录而判为不支持。
- Cypher `toSet(list)` 改写为文档公开的 `list_distinct(list)`；Cypher 列表推导式改写为 `transform()`/`filter()`。不要生成未文档化的 `array_distinct()`，也不要把单个 LIST 传给 `all_different()`。
- Cypher/nGQL `exists(element.prop)` 的常见属性检查改写为文档公开的 `element.prop IS NOT NULL`。若需求必须区分“属性缺失”和“属性值为 NULL”，明确说明 v5.3.0 用户文档没有可靠等价构造；不要调用代码中存在但未文档化的 `property_exists()`。
- 将有高选择性过滤条件的锚点放在模式左侧。单变量属性过滤优先下沉到该变量的 pattern filler；跨变量条件放在外层 `WHERE`。
- 迁移路径集合断言时，先判断能否由 pattern 直接表达：量化边段上的逐边 `ALL` 且谓词只引用当前边和常量/参数时，下推为 edge pattern `WHERE`；节点零重复约束改用 `ACYCLIC`。`ANY`/`NONE`/`SINGLE`、跨元素条件和“筛选含重复节点”的条件不得套用该优化。
- 使用边后量词表达可变长度路径，例如 `(a)-[:KNOWS]->{1,3}(d)`；不要生成 `[:KNOWS*1..3]`。
- 只在标签名来自字符串 `VALUE` 或绑定变量时生成动态标签表达式。不要把聚合器、文件、表或非字符串值当作标签。
- 用户要求精确元素类型、类型集合或类型否定时使用 `@Type`、`@[Type1,Type2]` 或 `@!Type`；动态类型项也必须来自字符串值或绑定变量。
- 不要在同一个节点或边模式中同时使用标签表达式 `:` 和元素类型表达式 `@`。
- 区分内部标识与业务属性。`element_id()` 只接受节点；边要按需要组合端点 ID、`type(e)` 与 `multiedge_id(e)`，不要生成 `element_id(e)`。
- 在线性查询中保证末尾是 `RETURN`、`FINISH` 或更新语句；跨段传递结果时明确使用 `NEXT`。
- 参数化查询使用 `$name`，不要把参数名写成字符串字面量。
- 用户要求“只给查询”时只输出代码块；否则最多补充关键假设和必要说明。
- **默认返回完整图元素**：自然语言提到“返回某节点/边类型”（例如“返回导演和演员”），RETURN 默认回传 pattern 中的节点变量与边变量（或路径变量），不擅自降级为只返回某个属性（如 name）；只有用户明确指定返回某个属性（例如“返回导演的 name”）时才投影该属性列。这保证 Web Client 能用 G6 渲染完整的点与边。

## Evidence Policy

将 v5.3.0 用户文档作为完整公开能力清单，将随包携带的 `.feature` 正反例和代码作为实现边界验证。目录内能力不需要 feature 或高频示例二次授权；目录外能力不得由 feature/代码单独授权。文档与已确认实现边界冲突时，按目标环境说明限制并回退，不用内部别名绕过。
