# Expressions and Predicates Reference

## Contents

- Literals, variables, and properties
- Comparison, logical, membership, null, and element predicates
- `CASE`, `CAST`, construct, and subquery expressions
- Label expressions and predicates
- Operator precedence

## Literals
稳定可用的字面量类型：数值、布尔、字符串、日期时间、列表、记录、向量、`NULL`、`UNKNOWN`、`NAN`。

- `UNKNOWN` 与 `NULL` 在值层语义等价。
- `NAN` 是浮点非数字值。
- 当用户只是要固定值时，优先直接用字面量，不要额外包函数或 `CAST`。

## Variable and Property Expressions

```gql
<node_variable>.<property_name>
<edge_variable>.<property_name>
<record_expression>.<field_name>
```

- 变量表达式只应引用当前作用域中已可见的列、别名或绑定变量。
- 属性表达式引用对象必须是点、边或记录。

## Comparison Predicates
支持 `=`, `<>`, `<`, `>`, `<=`, `>=`。

- 两侧应是相同值类型；类型不一致时不要强行生成比较。
- 任一侧为 `null` 时结果为 `null`。

## Logical Expressions
```gql
<expr> AND <expr>
<expr> OR <expr>
<expr> XOR <expr>
NOT <expr>
```

- 遵循三值逻辑（TRUE/FALSE/NULL）。
- `AND` 一侧为 `false` → `false`；无 `false` 且有 `null` → `null`。
- `OR` 一侧为 `true` → `true`；无 `true` 且有 `null` → `null`。
- `XOR` 任一侧为 `null` → `null`。

## Membership and Pattern Predicates
- `<expr> IN <list_or_set>` / `<expr> NOT IN <list_or_set>`
- `<expr> LIKE <pattern>` — `%` 任意序列，`_` 单字符
- `<string> || <string>` — 字符串拼接

## IS Predicates（二值布尔，不服从三值逻辑）
- `<expr> IS TRUE` / `IS FALSE` / `IS UNKNOWN`
- `<expr> IS NOT TRUE` / `IS NOT FALSE` / `IS NOT UNKNOWN`
- `IS UNKNOWN` 与 `IS NULL` 等价。

## Null Check
```gql
<expr> IS NULL
<expr> IS NOT NULL
```

## COALESCE
`COALESCE(<expr1>, <expr2>, ...)` — 返回第一个非 null 参数。

## CASE Expression
```gql
CASE
   WHEN <condition> THEN <value>
   [WHEN <condition> THEN <value>] ...
   [ELSE <value>]
END
```

按从上到下匹配第一个为真的 `WHEN`；无匹配则返回 `ELSE`；省略 `ELSE` 结果为 `NULL`。

## CAST
```gql
CAST(<expr> AS <target_type>)
```

只在明确需要类型转换时使用；不要无理由包裹。

## Construct Expressions
```gql
LIST [<expr>, ...]
SET { <expr>, ... }
MAP { <field>: <expr>, ... }
{ <field>: <expr>, ... }
PATH [<node>, <edge>, <node>, ...]
```

- `LIST` 方括号不可省略。
- `PATH` 必须按"点、边、点"交替组织。
- 只在用户明确要构造复合值时使用。

## Subquery Expressions
```gql
VALUE { <procedure_body> }   -- 收敛为单值
EXISTS { MATCH ... }         -- 图模式存在性判断
EXISTS { <procedure_body> }  -- 查询结果非空判断
```

- `VALUE { ... }` 内部 `RETURN` 应含聚合或 `LIMIT 1`；结果为空时返回 `NULL`。
- `EXISTS { ... }` 非空 → `true`，空 → `false`。
- 子查询可捕获外层变量；不要在内部用 `LET` 重定义同名变量。
- 在 `WHERE` / `FILTER` 中判断已绑定变量之间是否存在某个图模式，使用 `EXISTS { MATCH ... }`；排除某个图模式，使用 `NOT EXISTS { MATCH ... }`。不要生成 `NOT (a)-[:T]-(b)` 或 Cypher 风格 `EXISTS((a)-[:T]->(b))`。
- 如果自然语言是“是 A，但不是 B”“不是好友”“没有某关系”“排除某模式”“without ...”“but not ...”，其中被否定的关系/模式要写进 `NOT EXISTS { MATCH ... }` 子查询，而不是外层裸 pattern 布尔表达式。

## Label Expressions
```gql
<label_name>           -- 单标签
%                      -- 任意标签
!<label_name>          -- 排除
<factor> & <factor>    -- 交集
<factor> | <factor>    -- 并集
```

## Label Predicates
```gql
<element> IS LABELED <label_expression>
<element> IS NOT LABELED <label_expression>
<element> : <label_expression>
```

## Element Predicates
```gql
ALL_DIFFERENT(<elem1>, <elem2>, ...)
SAME(<elem1>, <elem2>, ...)
```

要求至少两个图元素变量；适合放在 `WHERE` 中。

## Operator Precedence（由高到低）
`.` > `[]` > `*`/`/` > `+`/`-` > 比较 > `IN`/`LIKE` > `IS NULL`/`IS NOT NULL` > `NOT` > `AND` > `OR`/`XOR`

混合使用时优先显式加括号。
