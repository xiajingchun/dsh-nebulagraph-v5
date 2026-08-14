# Graph Patterns Reference

## Contents

- Execution direction and anchor placement
- Node and edge pattern fillers
- Edge directions
- Path variables, quantifiers, and path groups
- Match modes and supported boundaries
- Filter placement

## Execution Direction (Performance)

除全路径/最短路径查询（使用双向 BFS）外，引擎**从左往右**执行图模式。

### 规则 1：锚点（带过滤条件的节点）放左侧

Preferred:
```gql
MATCH (v{id: 123})-[e]->(v2)
RETURN v2
```

Anti-pattern:
```gql
MATCH (v2)<-[e]-(v{id: 123})
RETURN v2
```

### 规则 2：已绑定变量放左侧

当同一 pattern 中同时存在已绑定（已确定值）的变量和未绑定变量时，已绑定变量必须放左侧。这包括所有场景：
- 外层 MATCH 已绑定的变量在子查询 pattern 中使用
- `NEXT` 连接的第二段语句中，第一段 RETURN 的变量与新变量同处一个 pattern
- 同一语句前面的 pattern 已绑定的变量在后续 pattern 中复用

**场景 A：子查询**

Preferred（已绑定变量 `n` 放左）:
```gql
MATCH p = ACYCLIC (n:DataPlatformTable)-[:DEPENDS_ON]->+(m:DataPlatformTable)
WHERE NOT EXISTS {
  MATCH (n)<-[:DEPENDS_ON]-(:DataPlatformTable)
}
RETURN p, length(p) AS L
ORDER BY L DESC
LIMIT 1
```

Anti-pattern（已绑定变量 `n` 放右，性能差）:
```gql
MATCH p = ACYCLIC (n:DataPlatformTable)-[:DEPENDS_ON]->+(m:DataPlatformTable)
WHERE NOT EXISTS {
  MATCH (:DataPlatformTable)-[:DEPENDS_ON]->(n)
}
RETURN p, length(p) AS L
ORDER BY L DESC
LIMIT 1
```

**场景 B：NEXT 连接的多段查询**

Preferred（第一段返回的 `src` 在第二段放左）:
```gql
MATCH (src:Person{id: 123})
RETURN src
NEXT
MATCH (src)-[:KNOWS]->(friend:Person)
RETURN friend
```

Anti-pattern（第一段返回的 `src` 放右，性能差）:
```gql
MATCH (src:Person{id: 123})
RETURN src
NEXT
MATCH (friend:Person)<-[:KNOWS]-(src)
RETURN friend
```

### 例外
`ALL SHORTEST`、`ANY SHORTEST`、`SHORTEST n` 使用双向 BFS，方向不影响性能。

## Node Pattern Filler
组件顺序（稳定）：点变量 → 标签表达式或点类型 → 点属性 → `WHERE`

```gql
(v)                        -- 仅变量
(v:Label)                  -- 标签表达式
(v IS Label)               -- IS 形式
(v @Type)                  -- 点类型
(v @[Type1, Type2])        -- 多点类型
(v {prop: expr})           -- 属性过滤
(v WHERE v.prop > 10)      -- pattern WHERE
```

- 至多使用三类组件：变量、标签/类型、属性/WHERE。

## Edge Pattern Filler
组件顺序（稳定）：边变量 → 标签表达式或边类型 → 边属性 → `SAMPLE` → `WHERE`

```gql
-[e:Label]->               -- 标签
-[e IS Label]->            -- IS 形式
-[e @Type]->               -- 边类型
-[e {prop: expr}]->        -- 属性过滤
-[e SAMPLE RIGHT 10]->     -- 采样
-[e WHERE e.weight > 0.5]-> -- pattern WHERE
```

- 至多使用四类组件：变量、标签/类型、属性/WHERE、SAMPLE。

## Edge Directions（7 种）
| 写法 | 含义 |
|------|------|
| `<-[...]-` | 左向 |
| `-[...]->` | 右向 |
| `~[...]~` | 无向 |
| `<~[...]~` | 左向无向 |
| `~[...]~>` | 无向右向 |
| `<-[...]->` | 双向 |
| `-[...]-` | 任意方向 |

## Path Patterns

### Path Variable
```gql
p = <path_pattern>
```
只在后续需引用整条路径时才声明路径变量。

### Quantifiers（量词）
位置：放在边方向片段之后。
```gql
-[e:T]->{1,3}     -- 1到3跳
-[e:T]->*         -- 0到无穷
-[e:T]->+         -- 1到无穷
-[e:T]->{3}       -- 恰好3跳
-[e:T]->{2,}      -- 2到无穷
-[e:T]->{,5}      -- 0到5跳
```

**禁止** Cypher 风格：`[:T*1..3]` — 必须改为 `-[:T]->{1,3}`。

### Quantified Path Groups
```gql
((inner_pattern)){m,n}
```
将一段内层路径整体量化，只在用户明确要对路径段整体重复时使用。

量化路径中边变量下标访问：`(e[0]).prop`、`(e[1]).prop`。

### Match Mode Prefix
- `REPEATABLE` — 允许重复边和点（默认）
- `DIFFERENT` — 不允许重复边

### Path Type Prefix
- `WALK` — 允许重复边和点（默认）
- `TRAIL` — 不允许重复边
- `ACYCLIC` — 不允许重复点
- `SIMPLE` — 起点可重复，其他点不重复

### Shortest Path Prefix
- `ALL SHORTEST` / `ANY SHORTEST` / `SHORTEST n`
- `ANY n` / `SHORTEST n` 的 `n` 是非负整数，未给出时默认取 1 条。

### 不支持的路径语法（运行时抛 UNSUPPORTED）
`|+|`、`|` 路径并集、`?`、`KEEP`、`SHORTEST n GROUPS`、`IS DIRECTED`

## Filter Placement Priority
按以下优先级放置过滤条件：

1. **单变量简单等值** → pattern 属性 `{prop: value}`
2. **单变量非等值**（IN、范围、CONTAINS、空值、时间比较） → pattern 内 `WHERE`
3. **跨变量关系或结果级约束** → 外层 `WHERE`

规则：
- `(v{id:1})` 与 `(v WHERE v.id = 1)` 视为等价；首选属性字面量。
- **所有图模式中的单变量过滤都必须下沉到对应变量所在的 pattern**，不要留在外层 `WHERE`。这包括普通 MATCH、shortest path、quantified path、variable-length 等所有模式。
- 只有会破坏可读性或语义时才保留单变量过滤在外层。

### Path Collection Predicate Normalization

迁移 Cypher/APOC 的路径集合断言时，先恢复它约束的 pattern 元素，再决定是否生成 lambda 后置检查。

- `ALL(r IN relationships(p) WHERE edge_predicate(r))`：当 `p` 只有一个对应的量化边段，且谓词只引用当前边 `r` 与常量/参数时，改为 `-[r:<edge_type> WHERE edge_predicate(r)]->{m,n}`。pattern 谓词会约束每次重复匹配，不要再生成 `length(filter(edges(p), ...)) = length(edges(p))`。
- 路径包含多个边段时，只有同一逐边条件能逐段等价放入所有相关 edge pattern 才下推；不能只约束其中一段。
- 谓词引用端点、其它边、边下标、路径位置、聚合值或子查询时，不是量化边 local filter，保留结果级条件或改写为可证明等价的结构。
- `ANY`、`NONE`、`SINGLE` 一般不能改成 edge pattern `WHERE`：pattern filler 会过滤候选边，而这些量词断言的是已匹配整条路径上的数量语义。

路径唯一性优先由 path type 表达：

- `size(apoc.coll.duplicates(nodes(p))) = 0` 或 `length(nodes(p)) = length(list_distinct(nodes(p)))` → `ACYCLIC`。
- 边零重复约束 → `TRAIL`；仅允许首尾点相同、其它点不重复时才用 `SIMPLE`。
- 若条件用于筛选**存在重复节点**的路径，例如去重前后长度不等，保留允许重复的 `WALK`/`TRAIL` 和后置条件；改成 `ACYCLIC` 会反转语义。

### General Filter Anti-pattern

Preferred（普通 MATCH）:
```gql
MATCH (a:Person WHERE a.age > 30)-[:KNOWS]->(b:Person WHERE b.city = 'Beijing')
RETURN a, b
```

Anti-pattern:
```gql
MATCH (a:Person)-[:KNOWS]->(b:Person)
WHERE a.age > 30 AND b.city = 'Beijing'
RETURN a, b
```

Preferred（shortest path）:
```gql
MATCH p = ANY SHORTEST PATH
  (src:facility WHERE src.id IN <source_ids>)
  -[:is_comp|is_leg]->*
  (dst:facility WHERE dst.id IN <dest_ids>)
RETURN p
```

Anti-pattern:
```gql
MATCH p = ANY SHORTEST PATH
  (src:facility)-[:is_comp|is_leg]->*(dst:facility)
WHERE src.id IN <source_ids>
  AND dst.id IN <dest_ids>
RETURN p
```

原因：`src.id` 只约束 `src`、`dst.id` 只约束 `dst`，它们是独立的单变量条件，必须分别写进各自所在的 pattern。外层 `WHERE` 只保留跨变量关系（如 `a.x = b.y`）。

## OPTIONAL MATCH
- 未命中时继续返回该行并产出 `null` 列。
- 不会吞掉 schema/type 级错误。
- 不要把它误写成"未知标签时返回 null"。

## SAMPLE（边模式采样）
```gql
SAMPLE [RIGHT] [FIRST_FETCH | RANDOM | UNIQUE_NEIGHBOR | UNQ_NBR] <sample_size>
```

- 只支持向右采样。
- `SAMPLE` 必须在同处边模式的 `WHERE` 之前。
- 省略方向默认向右；省略方法默认 `FIRST_FETCH`。
- `sample_size` 为正整数或 `[0,100]` 百分比整数。
- 只在用户明确要求时生成。
