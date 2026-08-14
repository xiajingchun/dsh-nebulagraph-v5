# Query Skill Coverage

Compatibility baseline: NebulaGraph `5.3.0` documentation and feature corpus.

本文件说明 `gql-query-generator` 高频模板与专项约束的覆盖状态，不是公开能力白名单。完整函数能力以 [documented-functions.md](documented-functions.md) 为准，完整查询语法范围以 [documented-syntax.md](documented-syntax.md) 为准；目录内能力即使未列入下表也可以按文档生成。

状态说明：
- `supported`: 已内置为默认生成能力
- `partial`: 只支持保守子集，或仅用于识别/改写
- `documented-restricted`: 文档记录了该主题，但文档自身限制或明确实现边界要求条件化处理
- `out-of-scope`: 不属于本技能包职责

## Coverage table

| Topic | Status | Notes |
|---|---|---|
| 数据查询总览 | supported | 用于整体任务路由与查询主干选择 |
| `MATCH` | supported | 支持基础模式匹配主干 |
| K-hop expansion | supported | 支持固定链与边后量词 `{lower,upper}`；按请求决定是否对终点去重 |
| 动态标签表达式 | partial | 支持字符串 `VALUE`/绑定变量作为节点或边标签；禁止无效变量类型及同模式 `:`/`@` 混用 |
| 动态元素类型表达式 | partial | 支持字符串 `VALUE`、`FOR`/`NEXT` 绑定变量用于 `@t`、`@[t,u]`、`@!t` 和 `IS ELEMENT TYPED`；禁止表、聚合器、文件及非字符串值 |
| 路径 VC index hint | partial | 仅保留用户或 schema 明确提供的 hint，不臆造索引名 |
| legacy nGQL 迁移启发式 | supported | 支持 `id(v)` 语义分流、GO/FETCH/LOOKUP/管道 → MATCH、`v.tag.prop` → `v.prop`、`$^/$$/$ -` → 变量属性引用、单变量过滤下沉等完整映射，参见 [migration.md] |
| Cypher 迁移启发式 | supported | 支持 `WITH` → `RETURN...NEXT`、`UNWIND` → `FOR`、`[:T*1..n]` → `-[:T]->{1,n}`、`MERGE` → `INSERT OR UPDATE`、`shortestPath()` → `ANY SHORTEST PATH`、`collect()` → `collect_list()`、`relationships()` → `edges()` 等完整映射，参见 [migration.md] |
| 高级路径组合语法 | documented-restricted | 只生成完整语法目录中实际出现且文档未标记为不支持的形态；关键字列表、HTML 注释或标准占位语法不构成可执行能力 |
| `WHERE` | supported | 支持常见布尔过滤；图模式存在/排除过滤使用 `EXISTS { MATCH ... }` / `NOT EXISTS { MATCH ... }`，并覆盖“但不是/没有某关系/排除某模式”这类自然语言排除语义 |
| `RETURN` | supported | 支持别名、`*`、`DISTINCT`、聚合入口 |
| `GROUP BY` | partial | 仅在聚合查询中保守生成，含 `GROUP BY ()` 全局单组子集 |
| `ORDER BY` | supported | 支持基础排序项 |
| `OFFSET` | supported | 支持分页偏移 |
| `LIMIT` | supported | 支持分页大小 |
| 参数化查询 | partial | 支持 `PARAMETERS $x=...`、`$param` 引用与会话参数保守子集 |
| Unicode 规范化 | partial | 仅识别 `NORMALIZE(str)` 的谨慎尝试子集；`NORMALIZE(str, form)` 不生成 |
| 分页组合 | supported | 固定输出顺序 `ORDER BY -> OFFSET -> LIMIT` |
| 命名过程调用 | supported | 支持 `CALL` / `OPTIONAL CALL` / `YIELD` / `RETURN` |
| 内联过程调用 | supported | 支持 `CALL { ... }` 与 `OPTIONAL CALL { ... }`，且过程体仅保守支持 DQL 子集 |
| `YIELD` | supported | 仅用于过程调用后取列 |
| `FILTER` | partial | 支持 `FILTER [WHERE]` 保守子集及二次筛选场景 |
| 复合查询 | partial | 支持同层同连接词与列结构一致性的稳定子集 |
| 线性查询 | partial | 支持顺序语句组织与 `RETURN/FINISH` 收口约束 |
| primitive result | partial | 主要作为 `CALL` 后结果约束知识 |
| `USE` | partial | 仅在图上下文明确且不可省略时生成 |
| 图变量查询 | partial | 支持 `GRAPH g = GRAPH{...}` + `USE g` + 基础 `MATCH/WHERE/RETURN`，并要求显式 working graph 与唯一别名保守子集 |
| `FOR` | partial | 支持列表/表展开与 `WITH ORDINALITY/OFFSET` 保守子集 |
| 内联绑定表 | partial | 支持 `TABLE t {..} = ...` 与 `FOR` 遍历的稳定子集 |
| `LET` | partial | 支持中间变量定义、跨 `NEXT` 可见性，以及 `VALUE/EXISTS` 对外层变量的保守捕获子集 |
| `SAMPLE` | partial | 仅支持边模式中的保守采样子集 |
| 属性存在/非 NULL 检查 | partial | 常见迁移使用 `element.prop IS NOT NULL`；若必须区分属性缺失与 NULL，明确说明没有文档化等价构造，不生成内部 `property_exists()` |
| 节点/边内部标识 | supported | 节点用 `element_id(node)`；边用端点 ID、`type(edge)` 与 `multiedge_id(edge)` 按需求组合，禁止 `element_id(edge)` |
| 时间差函数 | partial | 支持 `DURATION_BETWEEN(t1, t2)` 的保守子集 |
| 类型诊断函数 | partial | 支持 `typeof(expr)` 作为显式诊断/调试用途 |
| 事务控制语句 | partial | 以识别/改写为主，默认不主动扩展复杂事务脚本 |
| REST 查询入口 | partial | 识别请求语义并生成查询体，不生成协议层封装 |
| 最近邻查询 | partial | 支持节点/边 KNN/ANN 查询骨架与函数-选项兼容性约束，不生成索引 DDL |
| 错误码导向改写 | partial | 支持高频查询错误码的最小修复映射，含 graph/table reference、变量重名与排序可见列约束 |
| 连接词结构修复 | partial | 支持 `42001` 的 `NEXT/UNION` 位置与连用错误最小修复 |
| 顶层命令独占修复 | partial | 支持 `42N57` 的命令语句混用收敛为单条顶层命令 |
| DDL 混用拆分修复 | partial | 支持 `42N48` 的 DDL 与非 DDL 混用拆分与收敛 |
| 多错误码冲突消解 | partial | 支持按优先级顺序执行修复并在冲突时保留主干查询 |
| 最小改写决策树 | partial | 支持按轮次执行“结构优先”的可执行化修复流程 |
| 错误码组合速查 | partial | 支持常见错误码集合到最小动作序列的快速映射 |

## Completion criteria
- `supported` 项必须在 `SKILL.md` 或 [examples.md](examples.md) 中有明确模板或决策规则。
- `partial` 项必须说明保守边界，不能假装完整支持。
- `documented-restricted` 项按文档自身的环境、前置条件和限制生成，不能仅凭关键字或注释扩展能力。

## Distribution rule
- 本表只表达高频模板和专项约束；生成的完整目录保存了本技能职责内的全部文档能力。
- 对外分发时，不要求接收方具备源码仓库或站点页面。

## Next expansion candidates
- 高级路径组合语法（`|`、`|+|`、`?`、`KEEP`、`SHORTEST n GROUPS`、`IS DIRECTED`）的可执行子集
- `MATCH ... YIELD` 能力（等待内核支持后再升级）
- Unicode 规范化能力（`NORMALIZE` 的稳定实现与验证）
