# Query Skill Examples

本文件给出 `gql-query-generator` 的高频正例与边界例。示例已按 NebulaGraph 5.3.0 文档与 feature 语料刷新，用于稳定输出风格。

分发约束：示例必须自解释，不依赖“见某页”或“参考某文档”。

## Contents

- Positive query patterns and 5.3.0 capabilities
- Error-code rewrite snippets
- Cypher-to-GQL migration patterns
- nGQL-to-GQL migration patterns
- Negative patterns and placeholder policy

## Positive patterns

### 1. Basic match with filter
Input intent:
- 查找 2024 年后创建的用户，返回姓名和邮箱

Output skeleton:
```gql
MATCH (u:<UserTag>)
WHERE u.<created_at> > <date_value>
RETURN u.<name> AS name, u.<email> AS email
```

### 1A. Anchor node on the left (performance)
Input intent:
- 从指定起点出发查一跳邻居

Output skeleton（锚点在左，性能优）:
```gql
MATCH (v{id: 123})-[e]->(v2)
RETURN v2
```

Anti-pattern（锚点在右，性能差）:
```gql
MATCH (v2)<-[e]-(v{id: 123})
RETURN v2
```

注意：shortest path 使用双向 BFS，方向不影响性能。

### 1A-2. Bound variable on the left (performance)
Input intent:
- 已绑定变量在子查询、NEXT 后续段或同语句后续 pattern 中使用时放左侧

Output skeleton — 子查询场景（已绑定变量 `n` 放左）:
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

Output skeleton — NEXT 场景（第一段返回的 `src` 在第二段放左）:
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

### 1B. Element identity query
Input intent:
- 返回点的元素标识，不要使用不存在的 `id()`

Output skeleton:
```gql
MATCH (v:<Tag>)
RETURN element_id(v) AS vid, v
```

### 1C. Legacy `id(v)` as business key
Input intent:
- 旧 nGQL 里用 `id(v)` 查业务主键，改写成当前 GQL

Output skeleton:
```gql
MATCH (v:<Tag>{id: <business_id>})
RETURN v
```

Output skeleton:
```gql
MATCH (v:<Tag> WHERE v.id IN <id_list>)
RETURN v
```

### 1D. Single-variable filter sinks into pattern
Input intent:
- 单变量过滤条件优先放到 pattern，而不是外层 `WHERE`

Output skeleton:
```gql
MATCH (c:<CityTag> WHERE CONTAINS(c.<name>, <keyword>))
RETURN c
```

Output skeleton:
```gql
MATCH (u:<UserTag> WHERE u.<score> >= <min_score> AND u.<score> <= <max_score>)
RETURN u
```

### 1E. Keep only cross-variable predicates in outer WHERE
Input intent:
- 同时有单变量条件和跨变量关系条件时，单变量下沉到 pattern，外层只保留跨变量关系

Output skeleton:
```gql
MATCH (a:<TagA> WHERE a.<status> = 'active')-[:<EDGE_TYPE>]->(b:<TagB> WHERE b.<score> >= <min_score>)
WHERE a.<tenant_id> = b.<tenant_id>
RETURN a, b
```

### 1F. Prefer property-literal over single-variable pattern WHERE
Input intent:
- 单变量等值过滤优先使用 pattern 属性字面量短写

Preferred:
```gql
MATCH (src{id: "{from_id}"})
MATCH (dst{id: "{to_id}"})
RETURN src, dst
```

Avoid when equivalent:
```gql
MATCH (src WHERE src.id = "{from_id}")
MATCH (dst WHERE dst.id = "{to_id}")
RETURN src, dst
```

### 1G. Keep only multi-variable predicates in outer WHERE
Input intent:
- 所有可下沉的单变量条件都下沉，外层 `WHERE` 仅保留多变量关系

Output skeleton:
```gql
MATCH (src:<SrcTag>{id: "{from_id}"})-[e:<EDGE_TYPE>]->(dst:<DstTag>{id: "{to_id}"})
WHERE src.<tenant_id> = dst.<tenant_id>
RETURN e
```

### 1H. Pattern existence filters use EXISTS subqueries
Input intent:
- 查询所有人中，是队友但不是好友的人
- “但不是/不是好友” 表达的是排除某个图模式，不是裸 pattern 否定

Output skeleton:
```gql
MATCH (p1:player)-[s1:serve]->(t:team)<-[s2:serve]-(p2:player)
WHERE p1.id <> p2.id
  AND s1.start_year <= s2.end_year
  AND s2.start_year <= s1.end_year
  AND NOT EXISTS {
    MATCH (p1)-[:follow]-(p2)
  }
RETURN DISTINCT p1.id AS player_id,
       p1.name AS player_name,
       p2.id AS teammate_id,
       p2.name AS teammate_name
ORDER BY player_id ASC, teammate_id ASC
LIMIT 100
```

Anti-pattern（不要生成）:
```gql
MATCH (p1:player)-[s1:serve]->(t:team)<-[s2:serve]-(p2:player)
WHERE p1.id <> p2.id
  AND NOT (p1)-[:follow]-(p2)
RETURN p1, p2
```

改写要点：`WHERE` 中的图模式包含/排除过滤用 `EXISTS { MATCH ... }` / `NOT EXISTS { MATCH ... }`，不要把裸 pattern 当成布尔条件。凡是自然语言里出现“但不是/不是…的人/没有…关系/排除…模式/without/but not”，都先识别成“主模式 + `NOT EXISTS` 排除子模式”。

### 1I. Default return of complete graph elements (G6 visualization)
Input intent:
- 返回星球大战的导演和演员
- 提到节点/边类型时，默认返回完整元素（含全部属性与边），供 Web Client 以 G6 图渲染

Output skeleton:
```gql
MATCH (m:<MovieTag>{title: 'Star Wars'})<-[e1:<ACTED_IN>]-(a:<ActorTag>),
      (m)<-[e2:<DIRECTED>]-(d:<DirectorTag>)
RETURN DISTINCT m, a, d, e1, e2
```

Input intent（明确要求属性列时才投影）:
- 只返回导演的 name

Output skeleton:
```gql
MATCH (m:<MovieTag>{title: 'Star Wars'})<-[e2:<DIRECTED>]-(d:<DirectorTag>)
RETURN DISTINCT d.<name> AS name
```

Anti-pattern（不要生成——用户要“导演和演员”时不能擅自只返回名字，会丢失点与边，G6 无法完整渲染）:
```gql
MATCH (m:<MovieTag>{title: 'Star Wars'})<-[e1:<ACTED_IN>]-(a:<ActorTag>),
      (m)<-[e2:<DIRECTED>]-(d:<DirectorTag>)
RETURN d.<name> AS director_name, a.<name> AS actor_name
```

改写要点：自然语言提到“返回 <节点/边类型>”（如导演、演员、边）时，RETURN 默认回传完整图元素——pattern 的节点变量、边变量（或路径变量），Web Client 会自动把它们渲染成可交互的 G6 图；只有明确说“返回 X 的 <属性>”（如“导演的 name”）时才投影属性列。

### 2. Sorted page query
Input intent:
- 查最近创建的 20 条订单，跳过前 40 条

Output skeleton:
```gql
MATCH (o:<OrderTag>)
RETURN o.<id> AS id, o.<created_at> AS created_at
ORDER BY o.<created_at> DESC
OFFSET 40
LIMIT 20
```

### 3. Aggregate query
Input intent:
- 按城市统计用户数

Output skeleton:
```gql
MATCH (u:<UserTag>)
RETURN u.<city> AS city, count(u) AS user_count
GROUP BY u.<city>
```

### 3A. Global aggregate with `GROUP BY ()`
Input intent:
- 把所有匹配行归为同一组，只返回全局聚合结果

Output skeleton:
```gql
MATCH (u:<UserTag>)
RETURN count(u) AS total_users
GROUP BY ()
```

### 4. Named procedure call
Input intent:
- 调用某个过程并返回全部结果

Output skeleton:
```gql
CALL <procedure_name>(<arg_1>, <arg_2>)
RETURN *
```

### 5. Named procedure call with yield
Input intent:
- 调用过程后只取 name 和 score 两列

Output skeleton:
```gql
CALL <procedure_name>(<arg_1>) YIELD name, score
RETURN name, score
ORDER BY score DESC
```

### 6. Inline procedure composition
Input intent:
- 先执行一段查询，再对结果做外层排序和分页

Output skeleton:
```gql
CALL {
  MATCH (n:<Tag>)
  RETURN n.<field> AS field, n.<score> AS score
}
RETURN field, score
ORDER BY score DESC
LIMIT 10
```

### 7. FOR with offset/ordinality
Input intent:
- 展开列表并保留下标

Output skeleton:
```gql
LET vals = [10, 20, 30]
FOR v, idx IN vals WITH OFFSET
RETURN v, idx
```

Output skeleton:
```gql
LET vals = [10, 20, 30]
FOR v, ord IN vals WITH ORDINALITY
RETURN v, ord
```

### 7A. Inline binding table with `FOR`
Input intent:
- 先定义内联表，再逐行展开并返回列值

Output skeleton:
```gql
TABLE t {name, score} = ('alice', 98), ('bob', 87)
FOR r IN t
RETURN r.name AS name, r.score AS score
```

### 8. Match edge sampling
Input intent:
- 对每个点的出边做随机采样

Output skeleton:
```gql
MATCH (a:<TagA>)-[e:<EDGE_TYPE> SAMPLE RIGHT RANDOM 20]->(b:<TagB>)
RETURN a, b, e
```

### 8A. Single-variable filters must sink into pattern (all patterns)
Input intent:
- 所有图模式中，只约束单个变量的过滤条件都必须写进该变量所在的 pattern

Output skeleton（普通 MATCH）:
```gql
MATCH (a:<TagA> WHERE a.<score> > <min>)-[:<EDGE_TYPE>]->(b:<TagB> WHERE b.<city> = <city>)
RETURN a, b
```

Anti-pattern（不要生成）:
```gql
MATCH (a:<TagA>)-[:<EDGE_TYPE>]->(b:<TagB>)
WHERE a.<score> > <min> AND b.<city> = <city>
RETURN a, b
```

Output skeleton（shortest path）:
```gql
MATCH p = ANY SHORTEST PATH
  (src:<SrcTag> WHERE src.id IN <src_ids>)
  -[:<EDGE_TYPE>]->*
  (dst:<DstTag> WHERE dst.id IN <dst_ids>)
RETURN p AS p
```

Anti-pattern（不要生成）:
```gql
MATCH p = ANY SHORTEST PATH
  (src:<SrcTag>)-[:<EDGE_TYPE>]->*(dst:<DstTag>)
WHERE src.id IN <src_ids>
  AND dst.id IN <dst_ids>
RETURN p
```

### 8B. Quantified path range syntax (non-Cypher)
Input intent:
- 需要 1 到 N 跳区间匹配，避免 Cypher 风格 `*1..N`

Output skeleton:
```gql
MATCH p = ALL WALK
  (s:<SrcTag> WHERE s.id IN <src_ids>)
  -[:<EDGE_TYPE>]->{1,<max_hops>}
  (d:<DstTag> WHERE d.id IN <dst_ids>)
RETURN p
```

Anti-pattern (do not generate):
```gql
MATCH p = ALL WALK (s)-[:<EDGE_TYPE>*1..<max_hops>]->(d)
RETURN p
```

### 9. Value subquery in let
Input intent:
- 用子查询得到一个标量阈值并在外层复用

Output skeleton:
```gql
LET threshold = VALUE {
  MATCH (n:<Tag>)
  RETURN avg(n.<score>)
}
MATCH (m:<Tag>)
WHERE m.<score> > threshold
RETURN m
```

### 9A. Correlated subquery captures outer let
Input intent:
- 在 `VALUE` / `EXISTS` 子查询里复用外层 `LET` 变量，但不重定义同名变量

Output skeleton:
```gql
LET a = 1
LET b = a + 1, c = VALUE {
  USE <graph_name>
  MATCH (v:<Tag> WHERE v.<id> > a + b)
  RETURN v.<id>
  LIMIT 1
}
RETURN a, b, c
```

### 10. Parameterized query
Input intent:
- 生成可复用查询，用参数传入城市和最小分数

Output skeleton:
```gql
PARAMETERS $city='Hangzhou', $min_score=80
MATCH (u:<UserTag>)
WHERE u.<city> = $city AND u.<score> >= $min_score
RETURN u
```

### 10A. Property existence predicate
Input intent:
- 只返回确实包含某个属性的图元素

Output skeleton:
```gql
MATCH (v:<Tag>)
WHERE v.email IS NOT NULL
RETURN v
```

### 10B. Temporal difference query
Input intent:
- 计算两个时间值之间的持续时间差

Output skeleton:
```gql
MATCH (e:<EventTag>)
RETURN DURATION_BETWEEN(e.<end_time>, e.<start_time>) AS gap
```

### 10C. Type inspection query
Input intent:
- 调试或诊断某个表达式的值类型

Output skeleton:
```gql
MATCH (u:<UserTag>)
RETURN typeof(u.<score>) AS score_type, u.<score> AS score
```

### 11. Filter on current result
Input intent:
- 对前一步展开结果做二次筛选

Output skeleton:
```gql
FOR i IN LIST[0,10,-3,99.8]
FILTER i > 9
RETURN i
```

### 12. Composite with same conjunction
Input intent:
- 合并两个同结构结果集并保留重复行

Output skeleton:
```gql
RETURN 1 AS v
UNION ALL
RETURN 1 AS v
```

### 13. Linear-query end rule
Input intent:
- 生成线性查询并确保合法收口

Output skeleton:
```gql
USE <graph_name>
MATCH (n:<Tag>)
ORDER BY n.<id>
RETURN n
```

Input intent:
- 执行查询但不返回结果

Output skeleton:
```gql
USE <graph_name>
MATCH (n:<Tag>)
FINISH
```

### 13A. Query on graph variable
Input intent:
- 先构造派生图，再切到该图继续查询

Output skeleton:
```gql
GRAPH g = GRAPH{
  USE <graph_name>
  MATCH (n:<Tag>)
  RETURN n
}
USE g
MATCH (v)
RETURN v.<id>, v.<name>
```

### 14. Transaction-scoped intent (query-body first)
Input intent:
- 在事务中执行查询，但先要稳定查询语句本体

Output skeleton:
```gql
MATCH (o:<OrderTag>)
WHERE o.<status> = 'PENDING'
RETURN o
```

### 15. REST /gql intent (query-body only)
Input intent:
- 通过 REST `/gql` 执行查询，先生成查询体

Output skeleton:
```gql
MATCH (n:<Tag>)
RETURN n
LIMIT 10
```

### 16. KNN nearest-neighbor query
Input intent:
- 对向量属性做 KNN 检索

Output skeleton:
```gql
USE <graph_name>
MATCH (v:<Tag>)
ORDER BY euclidean(v.<vector_prop>, VECTOR<3,float>([1.0, 2.0, 3.0])) ASC
LIMIT 3
RETURN v, euclidean(v.<vector_prop>, VECTOR<3,float>([1.0, 2.0, 3.0])) AS distance
```

### 17. ANN nearest-neighbor query
Input intent:
- 使用 ANN 做近邻检索（已具备向量索引前提）

Output skeleton:
```gql
USE <graph_name>
MATCH (v:<Tag>)
ORDER BY inner_product(v.<vector_prop>, VECTOR<3,float>([1.0, 2.0, 3.0])) DESC
APPROXIMATE
LIMIT 3
OPTIONS { METRIC: IP, TYPE: HNSW, EFSEARCH: 16 }
RETURN v, inner_product(v.<vector_prop>, VECTOR<3,float>([1.0, 2.0, 3.0])) AS score
```

### 18. Edge KNN nearest-neighbor query
Input intent:
- 对边向量属性做 KNN 检索

Output skeleton:
```gql
USE <graph_name>
MATCH (s)-[e:<EDGE_TYPE>]->(d)
ORDER BY euclidean(e.<vector_prop>, VECTOR<3,float>([1.0, 2.0, 3.0])) ASC
LIMIT 5
RETURN s, e, d, euclidean(e.<vector_prop>, VECTOR<3,float>([1.0, 2.0, 3.0])) AS distance
```

### 19. Edge ANN nearest-neighbor query
Input intent:
- 对边向量属性做 ANN 检索（已具备向量索引前提）

Output skeleton:
```gql
USE <graph_name>
MATCH (s)-[e:<EDGE_TYPE>]->(d)
ORDER BY inner_product(e.<vector_prop>, VECTOR<3,float>([1.0, 2.0, 3.0])) DESC
APPROX
LIMIT 5
OPTIONS { METRIC: IP, TYPE: IVF, NPROBE: 8 }
RETURN s, e, d, inner_product(e.<vector_prop>, VECTOR<3,float>([1.0, 2.0, 3.0])) AS score
```

### 20. Error-code-oriented rewrite snippets
Input intent:
- 用户给出报错并要求快速修复查询

Rewrite hints:
```gql
-- [42N45] MATCH YIELD 不支持 -> 用 RETURN 投影替代
MATCH (v:<Tag>)
RETURN v

-- [42001] 连接词位置非法 -> 去掉块首/块尾/连续连接词
RETURN 1 AS a
NEXT
RETURN 2 AS a

-- [42N47] 线性查询未收口 -> 补 RETURN/FINISH
CALL <procedure_name>()
RETURN *

-- [42N09] VALUE 子查询收口非法 -> 改成单列 RETURN，必要时 LIMIT 1
RETURN VALUE {
  MATCH (v:<Tag>)
  RETURN v.<id>
  LIMIT 1
} AS value_id

-- [42N57] 命令语句混用 -> 改成单条顶层命令
SHOW INDEXES

-- [NS103] 量词上界非法 -> 上界改为大于 0
MATCH (v:<Tag>)-[e:<EDGE_TYPE>]->{0,1}(b)
RETURN v, b

-- [NS228] 标签不存在 -> 修正标签或图上下文
USE <graph_name>
MATCH (v:<ExistingTag>)
RETURN v

-- [42000] 图/表引用不能直接直返 -> 先消费引用再返回字段
TABLE t {id, name} = (1, 'alice'), (2, 'bob')
FOR r IN t
RETURN r.id, r.name

-- [NS002] 子查询内部不要 LET 重定义外层同名变量
LET a = 1
RETURN EXISTS {
  RETURN a
} AS ok

-- [NS209] 图变量作为过程参数不会自动切换 working graph -> 显式 USE
GRAPH g = GRAPH{ USE <graph_name> MATCH (v:<Tag>) RETURN v }
USE <graph_name>
MATCH (v:<Tag>)
CALL <procedure_name>(g, element_id(v))
YIELD <metric>
RETURN v.<id>, <metric>

-- [NS216] NEXT 透传图变量时使用唯一别名
GRAPH g = GRAPH{ USE <graph_name> MATCH (v:<Tag>) RETURN v } RETURN g AS gx
NEXT
CALL <procedure_name>(gx)
RETURN *

-- [42N36] 绑定表字段数不匹配 -> 对齐表头与每行字段数
TABLE t {id, name} = (1, 'alice'), (2, 'bob')
FOR r IN t
RETURN r.id, r.name

-- [NS236] 绑定表字段名/类型不兼容 -> 修正为兼容字段和值类型
TABLE t TYPED TABLE {id INT64, name STRING} =
{id: 1, name: 'alice'},
{id: 2, name: 'bob'}
FOR r IN t
RETURN r.id, r.name

-- [NR014] CASE 分支类型不兼容 -> 统一类型或 CAST
RETURN CASE WHEN <cond> THEN CAST(1 AS DOUBLE) ELSE 2.0 END AS x

-- [42N48] DDL 与非 DDL 混用 -> 拆分并仅保留查询体
MATCH (v:<Tag>)
RETURN v

-- [NS248] ORDER BY 因子不可见或是子查询 -> 先落列，再只按可见返回列排序
LET k = VALUE {
  MATCH (n:<Tag>)
  RETURN count(n)
}
MATCH (m:<Tag>)
RETURN m, k
ORDER BY k DESC

-- [42016] SAMPLE 与 ANN 混用 -> 去掉 SAMPLE（保留 ANN）
MATCH (s)-[e:<EDGE_TYPE>]->(d)
ORDER BY euclidean(e.<vector_prop>, VECTOR<3,float>([1.0, 2.0, 3.0])) ASC
APPROX
LIMIT 10
OPTIONS { TYPE: IVF, NPROBE: 8 }
RETURN e

-- [42001 + 42N47] 先修连接词结构，再补收口
RETURN 1 AS a
NEXT
RETURN 2 AS a

-- [42N57 + 42001] 命令语句优先独占，删除混用链
SHOW INDEXES

-- [NS248 + NS212] 先落排序列，再修 OFFSET 类型
LET k = VALUE {
  MATCH (n:<Tag>)
  RETURN count(n)
}
MATCH (m:<Tag>)
RETURN m, k
ORDER BY k DESC
OFFSET 0
LIMIT 10

-- [决策树模板] 第 1 轮先修结构（42001）
RETURN 1 AS a
NEXT
RETURN 2 AS a

-- [决策树模板] 第 2 轮再修可见性（42N18）
MATCH (v:<Tag>)
RETURN v.id AS vid
NEXT
RETURN vid

-- [决策树模板] 第 3 轮修排序分页（NS248 + NS213）
LET s = VALUE {
  MATCH (n:<Tag>)
  RETURN count(n)
}
MATCH (m:<Tag>)
RETURN m, s
ORDER BY s DESC
LIMIT 10

-- [bundle: 42N42 + NS004 + NS007] 统一连接词并对齐列结构
RETURN 1 AS a, 2 AS b
UNION
RETURN 3 AS a, 4 AS b

-- [bundle: NS241 + NS251 + 42N47] 先清子查询边界，再补外层收口
CALL {
  MATCH (v:<Tag>)
  RETURN v.id AS vid
}
RETURN vid

-- [bundle: NS248 + NS212 + 22G04] 先改可比较排序因子，再修分页类型
MATCH (v:<Tag>)
RETURN v.id AS vid, v.<property> AS score
ORDER BY score DESC
OFFSET 0
LIMIT 10

-- [bundle: 42N48 + 42N57] 去掉 DDL/查询混用并收敛为单条顶层语句
SHOW INDEXES

-- [bundle: 42N48 + 42N47] 先拆混用，再补线性收口
MATCH (v:<Tag>)
RETURN v
```

### 21. Dynamic node label from a value variable (5.3.0)
Input intent:
- 在运行时选择节点标签后查询

Output:
```gql
USE <graph_name> {
  VALUE label_name = "Person"
  MATCH (v:label_name{id: <id>})
  RETURN v.id, type(v)
}
```

Key rule:
- `label_name` 必须产生字符串标签名；不要使用聚合器、文件、表或非字符串值，也不要生成 `(v:label_name@Person)` 这种标签与元素类型混用。

### 21A. Dynamic exact element type (5.3.0)
Input intent:
- 在运行时选择精确节点类型和边类型

Output:
```gql
USE <graph_name> {
  VALUE node_type = "Person"
  VALUE edge_type = "KNOWS"
  MATCH (src@node_type{id: <id>})-[e@edge_type]->(dst)
  RETURN type(src), type(e), type(dst)
}
```

Key rule:
- `@` 表达精确元素类型，不等同于 `:` 标签；动态类型必须来自字符串值或绑定变量，也可以用于 `@[type_a,TypeB]` 与 `@!excluded_type`。

### 21B. Edge direction and multiedge identity (5.3.0)
Input intent:
- 返回边的内部端点、类型和 multiedge key

Output:
```gql
MATCH (src)-[e]->(dst)
RETURN start_node_id(e) AS start_id,
       end_node_id(e) AS end_id,
       type(e) AS edge_type,
       multiedge_id(e) AS edge_key
```

Key rule:
- `element_id()` 只接受节点。需要定位边时组合端点、类型和 `multiedge_id(e)`；不要生成 `element_id(e)`。

### 22. K-hop endpoint query (5.3.0)
Input intent:
- 查询某人 2 到 4 跳 `KNOWS` 可达的去重终点

Output:
```gql
MATCH (src:Person{id: <id>})-[:KNOWS]->{2,4}(dst:Person)
RETURN DISTINCT dst.id AS id
ORDER BY id
```

Key rule:
- 量词位于边方向之后；不要生成 Cypher 的 `[:KNOWS*2..4]`。只有业务要求终点去重时才添加 `DISTINCT`。

## Cypher → GQL migration patterns

### M1. Cypher variable-length path
Input (Cypher):
```cypher
MATCH (a:Person)-[:KNOWS*1..3]->(b:Person)
WHERE a.name = 'Alice'
RETURN b
```

Output (GQL):
```gql
MATCH (a:Person{name: 'Alice'})-[:KNOWS]->{1,3}(b:Person)
RETURN b
```

改写要点：`*1..3` → `->{1,3}`；单变量等值过滤下沉到属性字面量。

### M2. Cypher WITH intermediate projection
Input (Cypher):
```cypher
MATCH (u:User)-[:BOUGHT]->(p:Product)
WITH u, count(p) AS cnt
WHERE cnt > 5
RETURN u.name, cnt
ORDER BY cnt DESC
```

Output (GQL):
```gql
MATCH (u:User)-[:BOUGHT]->(p:Product)
RETURN u, count(p) AS cnt
GROUP BY u
NEXT
FILTER cnt > 5
RETURN u.name AS name, cnt
ORDER BY cnt DESC
```

改写要点：`WITH` → `RETURN...NEXT`；聚合后筛选用 `NEXT` + `FILTER`。

### M3. Cypher UNWIND
Input (Cypher):
```cypher
UNWIND [1, 2, 3] AS x
MATCH (n:Node{id: x})
RETURN n
```

Output (GQL):
```gql
FOR x IN LIST[1, 2, 3]
MATCH (n:Node{id: x})
RETURN n
```

改写要点：`UNWIND` → `FOR`。

### M4. Cypher shortestPath
Input (Cypher):
```cypher
MATCH p = shortestPath((a:Person{name:'Alice'})-[:KNOWS*]->(b:Person{name:'Bob'}))
RETURN p, length(p)
```

Output (GQL):
```gql
MATCH p = ANY SHORTEST PATH (a:Person{name:'Alice'})-[:KNOWS]->*(b:Person{name:'Bob'})
RETURN p, length(p)
```

改写要点：`shortestPath(...)` → `ANY SHORTEST PATH`；`*` → `->*`。

### M5. Cypher MERGE
Input (Cypher):
```cypher
MERGE (u:User{id: 'u1'})
ON CREATE SET u.created = datetime()
ON MATCH SET u.updated = datetime()
RETURN u
```

Output (GQL):
```gql
INSERT OR UPDATE (:User{id: 'u1'})
```

改写要点：`MERGE` → `INSERT OR UPDATE`；`ON CREATE/ON MATCH` 条件无直接等价，需要用户确认语义。

### M6. Cypher list comprehension
Input (Cypher):
```cypher
MATCH (u:User)
RETURN [x IN u.tags WHERE x STARTS WITH 'vip' | upper(x)] AS vip_tags
```

Output (GQL):
```gql
MATCH (u:User)
RETURN transform(filter(u.tags, x -> like(x, 'vip%')), x -> upper(x)) AS vip_tags
```

改写要点：列表推导 → `transform(filter(...))`。

### M6A. Cypher toSet and list projection
Input (Cypher/GQL hybrid):
```cypher
MATCH path = TRAIL (n1:Corporation)-[:股权出资]->{1,10}(n2:Corporation {eid: $eid})
LET pathNodes = nodes(path), pathLength = length(path)
FILTER WHERE length(pathNodes) <> length(toSet(pathNodes))
RETURN [node IN pathNodes | node.name] AS companyPath, pathLength
ORDER BY pathLength ASC
LIMIT 5
```

Output (GQL):
```gql
MATCH path = TRAIL (n1:Corporation)-[:股权出资]->{1,10}(n2:Corporation {eid: $eid})
LET pathNodes = nodes(path), pathLength = length(path)
FILTER WHERE length(pathNodes) <> length(list_distinct(pathNodes))
RETURN transform(pathNodes, node -> node.name) AS companyPath, pathLength
ORDER BY pathLength ASC
LIMIT 5
```

改写要点：`toSet(pathNodes)` → 文档公开的 `list_distinct(pathNodes)`；`[node IN pathNodes | node.name]` → `transform(pathNodes, node -> node.name)`。不要保留 `toSet()`、使用未文档化的 `array_distinct()` 或保留 Cypher 列表推导式，也不要改成签名无效的 `all_different(pathNodes)`。这里要筛选含重复节点的 `TRAIL`，不能改成会排除重复节点的 `ACYCLIC`。

### M6B. Cypher path predicates to pattern constraints
Input (Cypher):
```cypher
MATCH p = (person:Person)-[:股权出资*..6]->(company:Corporation)
WHERE company.uid = $uid
  AND ALL(rel IN relationships(p) WHERE rel.percent > 0)
  AND size(apoc.coll.duplicates(nodes(p))) = 0
WITH
    person,
    REDUCE(
        acc = 1.0,
        rel IN relationships(p) |
        acc * rel.percent / 100
    ) AS total_percent
WITH person, SUM(total_percent) AS total_percent
WHERE total_percent > 0.25
RETURN person, total_percent
ORDER BY total_percent DESC
```

Output (GQL optimized):
```gql
MATCH p = ACYCLIC
  (person:Person)
  -[r:股权出资 WHERE r.percent > 0]->{1,6}
  (company:Corporation {uid: $uid})
RETURN person,
       reduce(edges(p), 1.0, (acc, rel) -> acc * rel.percent / 100) AS total_percent
NEXT
RETURN person, sum(total_percent) AS total_percent
GROUP BY person
NEXT
FILTER WHERE total_percent > 0.25
RETURN person, total_percent
ORDER BY total_percent DESC
```

改写要点：终点等值条件下沉到属性字面量；逐边 `ALL` 条件下沉到量化 edge pattern；节点零重复条件提升为 `ACYCLIC`。不要再生成 `filter(edges(p))` 全量计数或 `list_distinct(nodes(p))` 后置检查。若原条件是筛选存在重复节点，则不能使用 `ACYCLIC`。

### M7. Cypher CALL subquery WITH import
Input (Cypher):
```cypher
MATCH (n:Person)
CALL {
  WITH n
  MATCH (n)-[:FRIEND]->(f)
  RETURN count(f) AS fc
}
RETURN n.name, fc
```

Output (GQL):
```gql
MATCH (n:Person)
CALL {
  MATCH (n)-[:FRIEND]->(f)
  RETURN count(f) AS fc
}
RETURN n.name AS name, fc
```

改写要点：GQL 子查询自动捕获外层变量，删除 `WITH n`。

### M8. Cypher collect → collect_list
Input (Cypher):
```cypher
MATCH (u:User)-[:BOUGHT]->(p:Product)
RETURN u.name AS name, collect(p.name) AS products
```

Output (GQL):
```gql
MATCH (u:User)-[:BOUGHT]->(p:Product)
RETURN u.name AS name, collect_list(p.name) AS products
GROUP BY u.name
```

改写要点：`collect()` → `collect_list()`；GQL 聚合需显式 `GROUP BY`。

### M9. Cypher relationships()
Input (Cypher):
```cypher
MATCH p = (a)-[*]->(b)
RETURN nodes(p), relationships(p)
```

Output (GQL):
```gql
MATCH p = (a)-[]->*(b)
RETURN nodes(p), edges(p)
```

改写要点：`relationships()` → `edges()`；`[*]` → `[]->*`。

## nGQL → GQL migration patterns

### N1. nGQL GO basic
Input (nGQL):
```ngql
GO FROM "player100" OVER serve YIELD dst(edge) AS team_id, serve.start_year
```

Output (GQL):
```gql
MATCH (v{id: "player100"})-[e:serve]->(t)
RETURN element_id(t) AS team_id, e.start_year
```

改写要点：`GO FROM ... OVER` → `MATCH` 模式；`dst(edge)` → 终点变量；`serve.start_year` → 边变量属性 `e.start_year`。

### N2. nGQL GO multi-hop
Input (nGQL):
```ngql
GO 1 TO 3 STEPS FROM "player100" OVER follow YIELD dst(edge) AS id
```

Output (GQL):
```gql
MATCH (v{id: "player100"})-[:follow]->{1,3}(dst)
RETURN element_id(dst) AS id
```

改写要点：`GO n TO m STEPS` → `->{n,m}`。

### N3. nGQL GO REVERSELY
Input (nGQL):
```ngql
GO FROM "team1" OVER serve REVERSELY YIELD src(edge) AS player
```

Output (GQL):
```gql
MATCH (t{id: "team1"})<-[e:serve]-(p)
RETURN element_id(p) AS player
```

改写要点：`REVERSELY` → 反向箭头 `<-[]-`。

### N4. nGQL pipe chain
Input (nGQL):
```ngql
GO FROM "player100" OVER follow YIELD dst(edge) AS id
| GO FROM $-.id OVER serve YIELD $-.id AS player, dst(edge) AS team
```

Output (GQL):
```gql
MATCH (v{id: "player100"})-[:follow]->(p)-[:serve]->(t)
RETURN element_id(p) AS player, element_id(t) AS team
```

改写要点：管道 `|` + `$-.id` → 合并为连续 MATCH 模式；两跳可在同一 pattern 表达。

### N5. nGQL FETCH PROP
Input (nGQL):
```ngql
FETCH PROP ON player "player100" YIELD player.name, player.age
```

Output (GQL):
```gql
MATCH (v:player{id: "player100"})
RETURN v.name, v.age
```

改写要点：`FETCH PROP ON tag "id"` → `MATCH (v:tag{id: "id"})`；`tag.prop` → `v.prop`（去 tag 前缀）。

### N6. nGQL LOOKUP
Input (nGQL):
```ngql
LOOKUP ON player WHERE player.age > 30 YIELD player.name, player.age
```

Output (GQL):
```gql
MATCH (v:player WHERE v.age > 30)
RETURN v.name, v.age
```

改写要点：`LOOKUP ON tag WHERE tag.prop ...` → `MATCH (v:tag WHERE v.prop ...)`。

### N7. nGQL FIND SHORTEST PATH
Input (nGQL):
```ngql
FIND SHORTEST PATH FROM "player100" TO "player200" OVER *
```

Output (GQL):
```gql
MATCH p = ANY SHORTEST PATH (a{id: "player100"})-[]->*(b{id: "player200"})
RETURN p
```

改写要点：`FIND SHORTEST PATH` → `ANY SHORTEST PATH`；`OVER *` → `-[]->*`。

### N8. nGQL v.tag.prop
Input (nGQL):
```ngql
MATCH (v:player) RETURN v.player.name AS name, v.player.age AS age
```

Output (GQL):
```gql
MATCH (v:player)
RETURN v.name AS name, v.age AS age
```

改写要点：`v.tag.prop` → `v.prop`（GQL 属性直接挂在元素上）。

### N9. nGQL INSERT VERTEX
Input (nGQL):
```ngql
INSERT VERTEX player(name, age) VALUES "player999":("Neo", 25)
```

Output (GQL):
```gql
INSERT (:player{id: "player999", name: "Neo", age: 25})
```

改写要点：`INSERT VERTEX tag(props) VALUES "id":(vals)` → `INSERT (:tag{id: "id", ...})`。

### N10. nGQL $^ and $$
Input (nGQL):
```ngql
GO FROM "player100" OVER serve YIELD $^.player.name AS player, $$.team.name AS team
```

Output (GQL):
```gql
MATCH (p:player{id: "player100"})-[:serve]->(t:team)
RETURN p.name AS player, t.name AS team
```

改写要点：`$^.tag.prop` → 起点变量属性；`$$.tag.prop` → 终点变量属性。

### N11. nGQL equality operator `==`
Input (nGQL):
```ngql
MATCH (v:player) WHERE v.player.name == "Tim Duncan" RETURN v
```

Output (GQL):
```gql
MATCH (v:player{name: "Tim Duncan"})
RETURN v
```

改写要点：nGQL 中 `==` 是等值比较符，GQL 中 `=` 既用于比较也用于赋值；单属性等值过滤下沉到属性字面量。

### N12. nGQL multi-edge type with `|`
Input (nGQL):
```ngql
MATCH (v:player{name:"Tim Duncan"})-[e:follow|:serve]->(v2) RETURN e
```

Output (GQL):
```gql
MATCH (v:player{name: 'Tim Duncan'})-[e:follow|serve]->(v2)
RETURN e
```

改写要点：nGQL `[e:T1|:T2]` 多边类型并集 → GQL 支持标签表达式析取 `[e:T1|T2]`（去掉多余的 `:`）。

### N13. nGQL edge rank
Input (nGQL):
```ngql
GO FROM "1" OVER e1 WHERE rank(edge) > 2
YIELD src(edge), dst(edge), rank(edge) AS Rank, properties(edge).p1
```

Output (GQL):
```gql
MATCH (a{id: "1"})-[e:e1]->(b)
RETURN element_id(a) AS src, element_id(b) AS dst, e.p1
```

改写要点：nGQL `rank(edge)` / `@rank` 改为 `multiedge_id(e)`。若需要完整定位边，还要结合起点、终点和 `type(e)`。

### N14. nGQL allShortestPaths
Input (nGQL):
```ngql
MATCH p = allShortestPaths((a:player{name:"Tim Duncan"})-[e*..5]-(b:player{name:"Tony Parker"}))
RETURN p
```

Output (GQL):
```gql
MATCH p = ALL SHORTEST (a:player{name: "Tim Duncan"})-[]-{1,5}(b:player{name: "Tony Parker"})
RETURN p
```

改写要点：`allShortestPaths((...))` → `ALL SHORTEST`；`[e*..5]` → `-[]-{1,5}`；去掉函数包裹。

### N15. nGQL properties() and keys()
Input (nGQL):
```ngql
MATCH (v:player{name:"Tim Duncan"})
WITH v, properties(v) AS props, keys(properties(v)) AS kk
RETURN props, kk
```

Output (GQL):
```gql
MATCH (v:player{name: "Tim Duncan"})
RETURN v.name, v.age
```

改写要点：GQL 无 `properties()` / `keys()` 函数直接等价——需逐属性显式返回。若需动态属性列表，需在业务层处理。

### N16. nGQL exists()
Input (nGQL):
```ngql
MATCH (v:player) WHERE exists(v.player.age) RETURN v.player.name, v.player.age
```

Output (GQL):
```gql
MATCH (v:player)
WHERE v.age IS NOT NULL
RETURN v.name, v.age
```

改写要点：常见属性检查 `exists(v.tag.prop)` → 文档公开的 `v.prop IS NOT NULL`；同时去掉 nGQL tag 前缀。若需求必须区分属性缺失与 NULL，明确说明没有文档化等价构造。

### N17. nGQL multi-hop edge filtering
Input (nGQL):
```ngql
MATCH p=(v:player{name:"Tim Duncan"})-[e:follow*2]->(v2)
WHERE e[0].degree > 98
RETURN DISTINCT v2
```

Output (GQL):
```gql
MATCH (v:player{name: "Tim Duncan"})-[e1:follow WHERE e1.degree > 98]->(mid)-[e2:follow]->(v2)
RETURN DISTINCT v2
```

改写要点：nGQL 中 `e` 是边列表，`e[0].degree` 访问第一跳。GQL 中需拆解为多段，每段一个边变量，分别过滤。

### N18. nGQL multi-hop edge ALL predicate
Input (nGQL):
```ngql
MATCH p=(v:player{name:"Tim Duncan"})-[e:follow*2]->(v2)
WHERE ALL(e_ in e WHERE e_.degree > 0)
RETURN DISTINCT v2
```

Output (GQL):
```gql
MATCH (v:player{name: "Tim Duncan"})-[e1:follow WHERE e1.degree > 0]->(mid)-[e2:follow WHERE e2.degree > 0]->(v2)
RETURN DISTINCT v2
```

改写要点：nGQL `ALL(e_ in e WHERE pred)` 对多跳边列表断言 → GQL 拆为逐段 pattern-level WHERE。

### N19. nGQL STARTS WITH / ENDS WITH / CONTAINS
Input (nGQL):
```ngql
MATCH (v:player)
WHERE v.player.name STARTS WITH "T"
RETURN v.player.name, v.player.age
```

Output (GQL):
```gql
MATCH (v:player)
WHERE like(v.name, 'T%')
RETURN v.name, v.age
```

改写要点：nGQL/Cypher `STARTS WITH` → GQL `like(str, 'prefix%')`；`ENDS WITH` → `like(str, '%suffix')`；`CONTAINS` → `contains(str, substr)`（GQL 无 `starts_with`/`ends_with` 函数）。

### N20. nGQL GO multi-edge with pipe
Input (nGQL):
```ngql
GO FROM "player100" OVER follow
WHERE properties(edge).degree > 90
YIELD dst(edge) AS id |
GO FROM $-.id OVER serve
YIELD $-.id AS player, dst(edge) AS team, properties(edge).start_year AS year
```

Output (GQL):
```gql
MATCH (v{id: "player100"})-[e1:follow WHERE e1.degree > 90]->(p)-[e2:serve]->(t)
RETURN element_id(p) AS player, element_id(t) AS team, e2.start_year AS year
```

改写要点：两段 `GO` + `|` + `$-.id` → 单条多跳 MATCH pattern；`properties(edge).prop` → `e.prop`。

### M10. Cypher ^ exponentiation
Input (Cypher):
```cypher
MATCH (n:Metric)
RETURN n.name, n.value ^ 2 AS squared
```

Output (GQL):
```gql
MATCH (n:Metric)
RETURN n.name, power(n.value, 2) AS squared
```

改写要点：Cypher `^` 求幂运算符 → GQL `power(x, y)` 函数。

### M11. Cypher any-direction variable-length
Input (Cypher):
```cypher
MATCH p = (a:Person{name:'Alice'})-[*1..4]-(b:Person{name:'Bob'})
RETURN p, length(p)
```

Output (GQL):
```gql
MATCH p = (a:Person{name: 'Alice'})-[]-{1,4}(b:Person{name: 'Bob'})
RETURN p, length(p)
```

改写要点：任意方向 `[*1..4]` → `-[]-{1,4}`（无箭头 = 任意方向）。

### M12. Cypher exists() property check
Input (Cypher):
```cypher
MATCH (n:Person)
WHERE exists(n.email)
RETURN n.name, n.email
```

Output (GQL):
```gql
MATCH (n:Person)
WHERE n.email IS NOT NULL
RETURN n.name, n.email
```

改写要点：常见 Cypher 属性检查 `exists(n.prop)` → GQL `n.prop IS NOT NULL`。若需求必须区分属性缺失与 NULL，不调用未文档化内部函数，而是明确说明能力缺口。

### M13. Cypher STARTS WITH / CONTAINS
Input (Cypher):
```cypher
MATCH (u:User)
WHERE u.name STARTS WITH 'A' AND u.email CONTAINS '@gmail'
RETURN u
```

Output (GQL):
```gql
MATCH (u:User)
WHERE like(u.name, 'A%') AND contains(u.email, '@gmail')
RETURN u
```

改写要点：`STARTS WITH` → `like(str, 'prefix%')`；`CONTAINS` → `contains(str, substr)`。GQL 无 `starts_with`/`ends_with` 函数。

### M14. ACYCLIC vs all_different redundancy
Input (GQL with redundancy):
```gql
MATCH p = ACYCLIC (a:App{code:'MNR'})-[:HAS]->(n1)-[r2]->(n2)-[:SUB]-(n3)
WHERE all_different(a, n1, n2, n3)
RETURN p
```

Output (GQL simplified):
```gql
MATCH p = ACYCLIC (a:App{code: 'MNR'})-[:HAS]->(n1)-[r2]->(n2)-[:SUB]-(n3)
RETURN p
```

改写要点：`ACYCLIC` 已经保证路径中所有点两两不同，再用 `all_different()` 列出同一条路径的所有点是冗余的。仅在跨多条路径或检查非路径变量时才需要 `all_different()`。

### M15. Neo4j fulltext search → GQL ftscore()
Input (Cypher/Neo4j):
```cypher
CALL db.index.fulltext.queryNodes("WebAPI_summary_and_description", "get equipment") YIELD node, score
MATCH (a:Application)--(s:Service)--(node)
WHERE s.technology = 'kongapig'
RETURN a.project_code, s.service_name, s.technology, node.path, score, node.summary, node.description
```

Output (GQL):
```gql
MATCH (a:Application)-[]-(s:Service{technology: 'kongapig'})-[]-(node)
LET score_summary = ftscore(node.summary, 'get equipment')
LET score_desc = ftscore(node.description, 'get equipment')
WHERE score_summary > 0 OR score_desc > 0
RETURN a.project_code, s.service_name, s.technology, node.path,
       score_summary + score_desc AS score, node.summary, node.description
ORDER BY score DESC
```

改写要点：
1. `db.index.fulltext.queryNodes` 是 Neo4j 内置过程，GQL 不支持 `db.*`/`apoc.*` 命名空间的过程，必须完全重写。
2. GQL 全文搜索用 `ftscore(property, query)` 函数（BM25 算法），直接嵌入 MATCH/LET/WHERE。
3. Neo4j 多属性全文索引需拆成多次 `ftscore()` 调用（每个索引只覆盖一个属性）。
4. **不要**机械地保留 `CALL` 再加 `RETURN...NEXT` 桥接；整个过程调用需替换为原生函数。
5. 单属性过滤 `s.technology = 'kongapig'` 下沉到 pattern 属性字面量。

### M16. Neo4j apoc.path.expandConfig → GQL MATCH
Input (Cypher/Neo4j):
```cypher
MATCH (a:Application {code: "MNR"})
CALL apoc.path.expandConfig(a, {
  relationshipFilter: "HAS_SERVICE>,PUBLISH_MESSAGE>|SUBSCRIBE_QUEUE>",
  minLevel: 1, maxLevel: 2,
  uniqueness: "NODE_GLOBAL"
}) YIELD path
RETURN path
```

Output (GQL):
```gql
MATCH path = ACYCLIC (a:Application{code: 'MNR'})-[:HAS_SERVICE]->(n1)
RETURN path
UNION ALL
MATCH path = ACYCLIC (a:Application{code: 'MNR'})-[:HAS_SERVICE]->(n1)-[:PUBLISH_MESSAGE|SUBSCRIBE_QUEUE]->(n2)
RETURN path
```

改写要点：
1. `apoc.path.expandConfig` 是 Neo4j APOC 过程，GQL 不支持。
2. `uniqueness: "NODE_GLOBAL"` → `ACYCLIC`（路径中点不重复）。
3. `relationshipFilter` 的 `>` 表示方向、`|` 分隔多类型 → GQL 标签析取 `[:T1|T2]->`。
4. `minLevel`/`maxLevel` 决定分层 UNION ALL 展开（每层一个 MATCH pattern）。

## Negative patterns
- 不要把普通检索需求改写成 `CREATE PROCEDURE`。
- 不要生成不存在的 `id()` 内置函数。
- 不要把 legacy `id(v)`、`id(e)` 机械改成 `element_id(...)`；业务主键查询优先改写成属性 `id` 过滤，且 `element_id()` 只接受节点。
- 不要保留 Neo4j `db.*`/`apoc.*`/`gds.*`/`dbms.*` 命名空间的过程调用；必须完全重写为 GQL 原生语法（如 `ftscore()`、MATCH 变长路径等）。
- 不要对 Neo4j 特有过程做机械的 `CALL...YIELD...RETURN...NEXT` 桥接；若过程本身不存在于 GQL，整个 CALL 语句需重写。
- 不要保留 Cypher 的 `WITH`（中间投影）、`UNWIND`、`[:T*1..3]` 等语法；必须改写为对应 GQL 形式。
- 不要保留 nGQL 的 `GO`、`FETCH`、`LOOKUP`、管道 `|`、`$-.col`、`$^.tag.prop`、`$$.tag.prop`、`v.tag.prop` 等语法。
- 不要保留 Cypher 子查询中的 `WITH n` 变量导入；GQL 自动捕获外层变量。
- 不要把 Cypher `collect()` 原样保留；改为 `collect_list()`。
- 不要把 Cypher `relationships()` 原样保留；改为 `edges()`。
- 不要把 nGQL `==` 等值比较直接保留；GQL 中等值比较用 `=`。
- 不要保留 nGQL `[:T1|:T2]` 多边类型并集语法；GQL 支持标签析取 `[:T1|T2]`（去掉多余的 `:`）。
- 不要保留 nGQL `rank(edge)` 或 `@rank` 原写法；需要 edge rank 时改为 `multiedge_id(edge)`。
- 不要保留 nGQL `properties(v)` / `properties(edge)` / `keys(properties(v))`；GQL 无直接等价。
- 不要保留 nGQL `src(edge)` / `dst(edge)`；用 pattern 中的起终点变量替代。
- 不要保留 nGQL/Cypher `exists(v.tag.prop)` 或 `exists(v.prop)`；常见属性检查改为 `v.prop IS NOT NULL`。若必须区分属性缺失与 NULL，明确说明没有文档化等价构造。
- 不要保留 nGQL/Cypher `STARTS WITH` / `ENDS WITH` / `CONTAINS` 运算符形式；改为 `like(str, 'prefix%')` / `like(str, '%suffix')` / `contains(str, substr)`（GQL 无 `starts_with`/`ends_with` 函数）。
- 不要保留 Cypher `^` 求幂运算符；改为 `power(x, y)`。
- 不要保留 Cypher `toSet(list)`；改为文档公开的 `list_distinct(list)`，不要生成未文档化的 `array_distinct()`。
- 不要保留 Cypher `[x IN list | expr]` 或 `[x IN list WHERE pred | expr]`；改为 `transform()`，必要时组合 `filter()`。
- 不要生成 `all_different(list)`；该函数要求至少两个显式图元素参数，不接受单个 LIST。
- 不要同时使用 `ACYCLIC` 和 `all_different()` 列出同一条路径的所有点；`ACYCLIC` 已足够，不需冗余。
- 不要保留 nGQL 多跳边列表下标 `e[0].prop`；拆为多段 pattern 逐段过滤。
- 不要保留 nGQL `ALL(e_ in e WHERE pred)` 对边列表的断言；拆为逐段 pattern-level WHERE。
- 不要保留 nGQL `allShortestPaths(...)` / `shortestPath(...)` 函数包裹形式；改为 `ALL SHORTEST` / `ANY SHORTEST PATH`。
- 不要把只涉及单个变量的过滤机械留在外层 `WHERE`；优先用 pattern 属性或 pattern `WHERE`。
- 不要把裸图模式写成 `WHERE` 布尔条件，例如 `AND NOT (p1)-[:follow]-(p2)`；排除模式用 `NOT EXISTS { MATCH ... }`，包含模式用 `EXISTS { MATCH ... }`。
- 不要生成 `MATCH ... YIELD ...`（当前内核版本不支持）。
- 不要直接写 `RETURN t` 这类绑定表引用直返；先 `FOR r IN t` 再返回字段列。
- 不要在 `TABLE ... = ...` 里放 `rand()`、未定义变量或其他非常量表达式。
- 不要生成 `|`、`|+|`、`?`、`KEEP`、`SHORTEST n GROUPS` 或 `IS DIRECTED` 这类当前未实现的高级路径语法；回退到单一路径模式。
- 不要默认生成 `NORMALIZE(...)`；若用户未明确要求 Unicode 规范化，直接使用原字段比较或过滤；不要生成 `NORMALIZE(str, NFC)` 这类双参数形式。
- 不要输出只有 `CALL` 没有结果语句的查询。
- 不要在无明确意图时默认扩展 `USE`、`LET`、`FOR`、`SAMPLE`。
- 不要把子查询表达式放到 `ORDER BY` 因子里。
- 不要让 `VALUE { ... }` 以非 `RETURN` 语句收尾。
- 不要把图算法或逐轮遍历需求伪装成普通查询。
- 不要输出 `WHILE`、`NODE VALUE`、`ACTIVE_SET` 或 `match_compute_statement` 风格代码。
- 不要在 `CALL { ... }` 内写 DDL 或 DML。
- 不要把 HTTP 协议细节、请求头或 SDK 样板代码混进 GQL 查询输出。
- 不要在同一层复合查询中混用 `UNION`、`EXCEPT`、`INTERSECT`。
- 不要把 `PARAMETERS` 写成未覆盖的块结构语法。
- 不要在 KNN 查询里附加 `APPROX`、`APPROXIMATE` 或 ANN `OPTIONS`。
- 不要在 ANN 中把 `NPROBE` 与 `TYPE: HNSW`、或把 `EFSEARCH` 与 `TYPE: IVF` 混用。
- 不要把最近邻查询与 `CREATE VECTOR INDEX` 混在同一个 query skill 输出里。
- 不要在节点近邻查询中引用边向量属性，或在边近邻查询中引用节点向量属性。
- 不要忽略用户提供的错误码而做无关重写。

## Placeholder policy
- 标签未知时使用 `<Tag>`。
- 边类型未知时使用 `<EDGE_TYPE>`。
- 属性未知时使用 `<property>`。
- 过程名未知时使用 `<procedure_name>`。
- 参数未知时使用 `<arg_1>`、`<arg_2>`。
