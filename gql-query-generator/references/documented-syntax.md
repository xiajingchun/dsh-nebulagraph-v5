# Documented Syntax Catalog

Generated from NebulaGraph `5.3.0` user documentation by `scripts/refresh_documented_capabilities.py`. Do not edit manually.

This is the complete documented language-page index for `gql-query-generator` within the skill's declared scope. A listed capability must not be rejected merely because it lacks a vendored feature or a dedicated example. Apply its documented grammar, environment, prerequisites, and restrictions; feature/code evidence may only narrow a verified implementation boundary.

Search this file by exact keyword, clause, predicate, expression, data type, or documentation key. Pages without a standalone grammar block remain documented capabilities; use their summary and the specialized skill references for constraints.

## Coverage

- Documented pages: `64`
- Extracted syntax blocks: `47`

## data-types

### 数据类型

- Documentation key: `database-gql-reference/data-types/`
- Summary: 数据类型是变量的值的类型。在创建图类型时，需要指定每个属性值的数据类型。属性值的数据类型决定了该属性可以存储的值类型。在 GQL 中，数据类型通常也被称为值类型。本文介绍悦数图数据库支持的数据类型以及值的约束。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### 布尔

- Documentation key: `database-gql-reference/data-types/boolean-type/`
- Summary: 布尔类型通过BOOL或BOOLEAN关键字声明，可以设置为以下值：TRUE、FALSE和UNKNOWN。其中，UNKNOWN等同于NULL，表示未知。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### 字符串

- Documentation key: `database-gql-reference/data-types/c-string-type/`
- Summary: 字符串类型使用STRING关键字声明，用于存储字符序列。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### 地理空间

- Documentation key: `database-gql-reference/data-types/geo-type/`
- Summary: 地理空间类型是由经度和纬度坐标组成的复合数据类型，用于表示地理空间数据。GQL 支持三种地理空间类型：Point、LineString 和 Polygon。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### 列表

- Documentation key: `database-gql-reference/data-types/list-type/`
- Summary: 列表类型是一个复合数据类型，可使用关键字LIST<E>或ARRAY<E>声明。其中，E代表列表元素的数据类型。列表元素可以是任意预定义数据类型，也可以是除记录和路径外的复合数据类型。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### 映射

- Documentation key: `database-gql-reference/data-types/map-type/`
- Summary: 映射类型是一种复合数据类型，用于存储一组无序的键值对。映射中的每个键都是唯一的，并与特定的值相关联。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### 数值

- Documentation key: `database-gql-reference/data-types/numeric-type/`
- Summary: GQL 支持整数、浮点数和任意精度数。整数可以有符号或无符号，而浮点数和任意精度数都是有符号的。
- Documented syntax:

```text
arbitrary_precision_number ::=
    ( 'DECIMAL' | 'DEC' ) (precision (',' scale)? )?
```

### 路径

- Documentation key: `database-gql-reference/data-types/path-type/`
- Summary: 路径类型是一个复合数据类型，可通过路径模式来定义路径类型的值。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### 记录

- Documentation key: `database-gql-reference/data-types/record-type/`
- Summary: 记录类型是一个复合数据类型，可通过构造表达式定义记录类型的值。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### 集合

- Documentation key: `database-gql-reference/data-types/set-type/`
- Summary: 集合类型是一种复合数据类型，用于存储一组无序且不重复的元素集合。与列表不同，集合中的元素没有索引概念，且自动去重。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### 日期和时间

- Documentation key: `database-gql-reference/data-types/temporal-type/`
- Summary: 日期和时间类型的值用于存储、操作和检索日期和时间信息。GQL 内置支持日期和时间类型，可以将其存储为点和边上的属性值。本文介绍日期和时间类型及其用法。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### 向量

- Documentation key: `database-gql-reference/data-types/vector-type/`
- Summary: 向量类型用于描述向量数据，通过指定的维度数和坐标的数据类型来定义。
- Documented syntax:

```text
vector ::=
    'VECTOR' '<' dimension ',' coordinate_type '>'
```

## dml

### 数据操作概述

- Documentation key: `database-gql-reference/dml/`
- Summary: 数据操作语言（Data Manipulation Language，简称 DML）用于修改数据库中的数据，例如，插入、更新或删除数据。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### DELETE

- Documentation key: `database-gql-reference/dml/delete/`
- Summary: DELETE语句用于删除一个或多个图或临时图中的元素。
- Documented syntax:

```text
delete_statement ::=
    ( 'DETACH' | 'NODETACH' )? 'DELETE' value_expression ( ',' value_expression )*
```

### INSERT

- Documentation key: `database-gql-reference/dml/insert/`
- Summary: INSERT语句用于往图或临时图中插入点和边。
- Documented syntax:

```text
insert_statement ::=
    ( 'INSERT' | 'INSERT' 'OR' 'REPLACE' | 'INSERT' 'OR' 'IGNORE' | 'INSERT' 'OR' 'UPDATE' ) insert_path_pattern ( ',' insert_path_pattern )*

insert_path_pattern ::=
    '(' insert_element_pattern_filler ')' ( insert_edge_pattern '(' insert_element_pattern_filler ')' )*

insert_element_pattern_filler ::=
  (element_variable_declaration?
  (
    ( ('IS' | ':') label_name ( '&' label_name )* )
    |
    ( ( 'TYPED' | '@' ) element_type_name )
  )
  '{' property_name ':' value_expression ( ',' property_name ':' value_expression )* '}')
  | element_variable_declaration

insert_edge_pattern ::=
    '<-[' ( insert_element_pattern_filler )? ']-'
  | '-[' ( insert_element_pattern_filler )? ']->'
  | '~[' ( insert_element_pattern_filler )? ']~'
```

### SET

- Documentation key: `database-gql-reference/dml/set/`
- Summary: SET语句用于修改图或临时图中元素的属性。
- Documented syntax:

```text
set_statement ::=
    'SET' variable_reference '.' property_name '=' value_expression ( ',' variable_reference '.' property_name '=' value_expression )*
```

## dql

### 数据查询概述

- Documentation key: `database-gql-reference/dql/`
- Summary: 数据查询语言（Data query language，简称 DQL）用于从数据库中获取信息。您可以使用查询语句读取持久性数据，并执行过滤、聚合和选择操作，而不会对数据进行更改。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### 使用 CALL 调用内联过程

- Documentation key: `database-gql-reference/dql/call/call-inline-procedure/`
- Summary: 在 GQL 中，为了实现更复杂的查询组合和结果处理，可以使用 CALL 语句将一组语句封装成一个语句块，然后对该语句块的结果进行进一步的操作，如排序、限制、聚合等。这种方式类似于在表达式中使用圆括号将子表达式括起来，以确保其结果可以被引用和处理。这种语句块被称为内联过程。本文描述如何使用CALL调用内联过程。
- Documented syntax:

```text
call_inline_procedure_statement ::=
    'OPTIONAL'? 'CALL' '{' procedure_body '}'
```

### 使用 CALL 调用命名过程

- Documentation key: `database-gql-reference/dql/call/call-procedure/`
- Summary: 本文介绍如何使用CALL语句调用命名过程。
- Documented syntax:

```text
call_procedure_statement ::=
    'OPTIONAL'? 'CALL' procedure_name '(' argument_list? ')' ('YIELD' yield_clause)?
```

### GROUP BY

- Documentation key: `database-gql-reference/dql/clauses/group-by/`
- Summary: GROUP BY子句基于指定的列对行进行分组。列的取值相同的行被分为同一组，并对每个组执行聚合计算。
- Documented syntax:

```text
group_by_clause ::=
    'GROUP BY' ( '()' | variable_value_expression ( ',' variable_value_expression )* )
```

### LIMIT

- Documentation key: `database-gql-reference/dql/clauses/limit/`
- Summary: LIMIT子句指定返回行数的上限。
- Documented syntax:

```text
limit_clause ::=
    'LIMIT' number_of_rows
```

### OFFSET

- Documentation key: `database-gql-reference/dql/clauses/offset/`
- Summary: OFFSET子句在返回结果时跳过一定数量的行。
- Documented syntax:

```text
offset_clause ::=
    ( 'OFFSET' | 'SKIP' ) number_of_rows_to_skip
```

### ORDER BY

- Documentation key: `database-gql-reference/dql/clauses/order-by/`
- Summary: ORDER BY子句基于一个或多个列对行进行排序。
- Documented syntax:

```text
order_by_clause ::=
    'ORDER BY' (value_expression ( 'ASC' | 'ASCENDING' | 'DESC' | 'DESCENDING' )? ('NULLS FIRST' | 'NULLS LAST')?) ( ',' (value_expression ( 'ASC' | 'ASCENDING' | 'DESC' | 'DESCENDING' )? ('NULLS FIRST' | 'NULLS LAST')?) )*
```

### SAMPLE

- Documentation key: `database-gql-reference/dql/clauses/sample/`
- Summary: SAMPLE子句用于在遍历过程中对边采样。在处理超大数据集时，可通过该子句选取较小且易于处理的样本进行分析。
- Documented syntax:

```text
sample_clause ::=
    'SAMPLE' 'RIGHT'? sampling_method? sample_size

sampling_method ::=
    'FIRST_FETCH' | 'RANDOM' | 'UNIQUE_NEIGHBOR' | 'UNQ_NBR'

sample_size ::=
    unsigned_integer '%'?
```

### USE

- Documentation key: `database-gql-reference/dql/clauses/use-graph/`
- Summary: USE子句用于声明查询的工作图。工作图是执行查询时使用的图或临时图。
- Documented syntax:

```text
use_clause ::=
    'USE' ((schema_reference '/')? graph_name | temp_graph_name)
```

### WHERE

- Documentation key: `database-gql-reference/dql/clauses/where/`
- Summary: WHERE子句以布尔表达式的形式声明一个或多个过滤条件。该子句通常指定点或边的多个属性值以过滤由前模式匹配子句或语句生成的结果。
- Documented syntax:

```text
where_clause ::=
    'WHERE' value_expression
```

### YIELD

- Documentation key: `database-gql-reference/dql/clauses/yield/`
- Summary: YIELD子句用于选定或重命名后续语句使用的列。
- Documented syntax:

```text
yield_clause ::=
    'YIELD' yield_item_name ( 'AS' variable )? ( ',' yield_item_name ( 'AS' variable )? )*
```

### 复合查询

- Documentation key: `database-gql-reference/dql/composite-query/`
- Summary: 复合查询语句将多个线性查询语句的结果集合并在一起。
- Documented syntax:

```text
composite_query_statement ::=
  linear_query_statement query_conjunction linear_query_statement ( query_conjunction linear_query_statement )*

query_conjunction ::=
    'UNION' ('DISTINCT' | 'ALL')?
  | 'EXCEPT' ('DISTINCT' | 'ALL')?
  | 'INTERSECT' ('DISTINCT' | 'ALL')?
```

### FILTER

- Documentation key: `database-gql-reference/dql/filter/`
- Summary: FILTER语句用于选择前一个语句生成的数据集的子集。FILTER语句的参数是一个布尔表达式，该表达式用于确定是否将数据传递到下一个语句。
- Documented syntax:

```text
filter_statement ::=
  'FILTER' 'WHERE'? search_condition
```

### FOR

- Documentation key: `database-gql-reference/dql/for/`
- Summary: FOR语句通过遍历的方式展开列表或表中的所有元素，使得后续语句可以逐个处理这些元素。
- Documented syntax:

```text
for_statement ::=
        'FOR' variable_name 'IN' ( list_value_expression ('||' list_value_expression)* | table_reference_value_expression ) for_ordinality_or_offset?

for_ordinality_or_offset ::=
        ('WITH ORDINALITY' | 'WITH OFFSET') index_variable_name
```

### LET

- Documentation key: `database-gql-reference/dql/let/`
- Summary: LET语句用于声明可以在后续语句中使用的变量。
- Documented syntax:

```text
let_statement ::=
    'LET' variable_name '=' value_expression (',' variable_name '=' value_expression)*
```

### 线性查询

- Documentation key: `database-gql-reference/dql/linear-query/`
- Summary: 线性查询语句由一组简单查询语句组成。这些简单查询语句按顺序依次执行后，最终返回一个结果集。
- Documented syntax:

```text
linear_query_statement ::=
    ((use_graph_clause simple_query_statement+)+)? use_graph_clause simple_query_statement+ primitive_result_statement
  | use_graph_clause primitive_result_statement
  | ( simple_query_statement+)? primitive_result_statement
  | use_graph_clause? '{' procedure_body '}'

simple_query_statement ::=
   match_statement
  | let_statement
  | for_statement
  | filter_statement
  | paging_statement
  | call_procedure_statement
```

### MATCH

- Documentation key: `database-gql-reference/dql/match/`
- Summary: MATCH语句通过模式匹配从图或临时图中检索数据。
- Documented syntax:

```text
match_statement ::=
    ( 'OPTIONAL' )? 'MATCH' graph_pattern graph_pattern_yield_clause?

graph_pattern ::= match_mode? path_pattern ( ',' path_pattern )* ( 'WHERE' search_condition )?

match_mode ::=
      'REPEATABLE' ('ELEMENTS' | 'ELEMENT' 'BINDINGS'?)
    | 'DIFFERENT' ( ('EDGE' | 'RELATIONSHIP') 'BINDINGS'? | ('EDGES' | 'RELATIONSHIPS') )

path_pattern ::=
    ( path_variable '=' )? ( path_mode_prefix | path_search_prefix )? path_term

path_mode_prefix ::=
    ( 'WALK' | 'TRAIL' | 'ACYCLIC' | 'SIMPLE' ) ( 'PATH' | 'PATHS' )?

path_search_prefix ::=
      'ALL' ( 'WALK' | 'TRAIL' | 'ACYCLIC' | 'SIMPLE' )? ( 'PATH' | 'PATHS' )?
    | 'ANY' ( number_of_paths )? ( 'WALK' | 'TRAIL' | 'ACYCLIC' | 'SIMPLE')? ( 'PATH' | 'PATHS' )?
    | 'ALL SHORTEST' ( 'WALK' | 'TRAIL' | 'ACYCLIC' | 'SIMPLE' )? ( 'PATH' | 'PATHS' )?
    | 'ANY SHORTEST' ( 'WALK' | 'TRAIL' | 'ACYCLIC' | 'SIMPLE')? ( 'PATH' | 'PATHS' )?
    | 'SHORTEST' number_of_paths ( 'WALK' | 'TRAIL' | 'ACYCLIC' | 'SIMPLE' )? ( 'PATH' | 'PATHS' )?

path_term ::=
      path_factor path_factor*

path_factor ::=
      element_pattern index_hint?
    | edge_pattern index_hint? graph_pattern_quantifier
    | parenthesized_path_pattern graph_pattern_quantifier

parenthesized_path_pattern ::=
    '(' ( path_variable '=' )? path_mode_prefix? path_term ( 'WHERE' search_condition )? ')'

element_pattern ::=
      node_pattern
    | edge_pattern

graph_pattern_yield_clause ::=
    'YIELD' ( element_variable_reference | path_variable_reference) ( ',' (element_variable_reference | path_variable_reference) )*
```

### 最近邻查询

- Documentation key: `database-gql-reference/dql/nearest-neighbor/`
- Summary: 最近邻查询语句用于在图中搜索向量的最近邻。该语句支持两种搜索类型：K 最近邻（k-nearest neighbor，简称 KNN）搜索和近似最近邻（Approximate Nearest Neighbor，简称 ANN）搜索。
- Documented syntax:

```text
knn_search_statement ::= order_by_clause limit_clause

ann_search_statement ::= order_by_clause ('APPROX'| 'APPROXIMATE') limit_clause ('OPTIONS' '{' ann_search_option (',' ann_search_option)* '}' )

ann_search_option::=
    'METRIC' ':' ( 'L2' | 'IP' )
  | 'TYPE' ':' ( 'IVF' | 'HNSW' )
  | 'NPROBE' ':' int_value
  | 'EFSEARCH' ':' int_value
```

### 分页

- Documentation key: `database-gql-reference/dql/order-by-page/`
- Summary: ORDER BY、OFFSET和LIMIT子句可以一起使用，将查询结果数据集划分为离散的子集或页面。这种过程通常称为分页。
- Documented syntax:

```text
paging_statement ::=
    order_by_clause offset_clause? limit_clause?
  | offset_clause limit_clause?
  | limit_clause
```

### 最终输出语句

- Documentation key: `database-gql-reference/dql/primitive-result/`
- Summary: 最终输出语句定义线性查询的最终输出行为：
- Documented syntax:

```text
primitive_result ::=
    return_statement paging_statement?
  | FINISH
```

### RETURN

- Documentation key: `database-gql-reference/dql/return/`
- Summary: RETURN语句用于选择输出列，或在输出前完成聚合计算。
- Documented syntax:

```text
return_statement ::=
    'RETURN' ( 'ALL' | 'DISTINCT' )?  ( ( (value_expression ('AS' identifier)? ) ( ',' (value_expression ('AS' identifier)? ) )* )
      | '*' ) group_by_clause?
```

## executions

### 查询配置

- Documentation key: `database-gql-reference/executions/`
- Summary: 悦数图数据库 提供以下配置用于控制查询的解析和执行方式：
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### 配置提示（Hints）

- Documentation key: `database-gql-reference/executions/hints/`
- Summary: 提示（Hints）是以特殊注释形式添加到查询中的指令，用于建议查询优化器如何执行查询。提示使用/*+ ... */语法。
- Documented syntax:

```text
index_hint ::=
    '/*+' 'INDEX' '(' index_name (',' index_name)* ')' '*/'
    | '/*+' 'IGNORE_INDEX' '(' index_name (',' index_name)* ')' '*/'
```

```text
no_reorder_hint ::=
    '/*+' 'NO_REORDER' '*/'
```

```text
MATCH /*+ NO_REORDER */ (a)-[e0]->(b)-[e1]->(c)
...
```

### 配置资源限制

- Documentation key: `database-gql-reference/executions/limits/`
- Summary: GQL 支持在查询中使用变量设置提示SET_VAR来配置资源用量限制。这些限制作用于当前查询，仅在当前查询中生效。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### 配置参数

- Documentation key: `database-gql-reference/executions/parameters/`
- Summary: 每个参数均由一个名称和一个值组成。GQL 支持配置会话参数和查询参数。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

## fe

### 聚合表达式

- Documentation key: `database-gql-reference/fe/expressions/aggregate/`
- Summary: 聚合表达式包含一个聚合函数实例，并返回聚合函数的执行结果。
- Documented syntax:

```text
aggregate_value_expression ::=
    aggregate_function '(' ( 'DISTINCT' | 'ALL' )? value_expression ( ',' value_expression )* ')'
```

### 变量表达式

- Documentation key: `database-gql-reference/fe/expressions/binding-variable/`
- Summary: 变量表达式引用当前数据集中单个或多个记录的字段。
- Documented syntax:

```text
variable_value_expression ::=
    variable
```

### 条件表达式

- Documentation key: `database-gql-reference/fe/expressions/case/`
- Summary: 条件表达式根据一个或多个条件的真假返回一个值。
- Documented syntax:

```text
case_value_expression ::=
    'CASE' ( 'WHEN' search_condition 'THEN' value_expression )+ ( 'ELSE' value_expression )? 'END'
  | 'coalesce' '(' value_expression ( ',' value_expression )+ ')'
```

### 类型转换表达式

- Documentation key: `database-gql-reference/fe/expressions/cast/`
- Summary: 类型转换表达式将表达式的数据类型转换为指定的目标数据类型。
- Documented syntax:

```text
cast_value_expression ::=
    'CAST' '(' (value_expression | 'NULL') 'AS' target_data_type ')'
```

### 常量表达式

- Documentation key: `database-gql-reference/fe/expressions/constant/`
- Summary: 常量表达式返回一个常量字面量。常量字面量是可以在查询中直接使用的固定值，并且在操作过程中不会被改变。
- Documented syntax:

```text
constant_value_expression ::=
    literal
```

### 构造表达式

- Documentation key: `database-gql-reference/fe/expressions/construct/`
- Summary: 构造表达式是用于创建复合数据类型（例如，列表和记录）的表达式。关于数据类型LIST和RECORD的更多信息，请参见数据类型。
- Documented syntax:

```text
construct_value_expression ::=
    'LIST' '[' value_expression ( ',' value_expression )* ']'
  | ( 'RECORD' )? '{' ( (field_name ':' value_expression) ( ',' (field_name ':' value_expression) )* )? '}'
```

### 函数表达式

- Documentation key: `database-gql-reference/fe/expressions/function/`
- Summary: 函数表达式包含一个函数实例并返回该函数的执行结果。
- Documented syntax:

```text
function_value_expression ::=
    function_name '(' value_expression ( ',' value_expression )* ')'
  | function_name '()'
```

### 标签表达式

- Documentation key: `database-gql-reference/fe/expressions/label/`
- Summary: 标签表达式可以引用图元素的标签。
- Documented syntax:

```text
label_expression ::=
    (label_factor ( '&' label_factor )* ) ( '|' (label_factor ( '&' label_factor )*) )*

label_factor ::=
    label_name
    | '%'
    | '(' label_expression ')'
    | '!' label_name
    | '!' '%'
    | '!' '(' label_expression ')'
```

### 匿名表达式

- Documentation key: `database-gql-reference/fe/expressions/lambda/`
- Summary: 匿名表达式（也被称作 Lambda 表达式）用于定义作用于列表中每个元素的操作。匿名表达式采用x -> expr的形式，其中x是输入参数，expr是表达式主体。
- Documented syntax:

```text
lambda_value_expression ::=
    variable '->' value_expression
```

### 逻辑表达式

- Documentation key: `database-gql-reference/fe/expressions/logical/`
- Summary: 逻辑表达式执行逻辑操作并返回布尔类型的结果。
- Documented syntax:

```text
logical_value_expression ::=
    value_expression ( 'AND' | 'OR' ) value_expression
```

### 属性表达式

- Documentation key: `database-gql-reference/fe/expressions/property/`
- Summary: 属性表达式用于引用图元素的属性或记录的字段。
- Documented syntax:

```text
property_value_expression ::=
    node_variable '.' property_name
  | edge_variable '.' property_name
  | record_value_expression '.' property_name
```

### 子查询表达式

- Documentation key: `database-gql-reference/fe/expressions/subquery/`
- Summary: 子查询表达式返回从某个查询中提取出的单个值或布尔值。
- Documented syntax:

```text
subquery_value_expression ::=
    'VALUE' '{' procedure_body '}'
  | 'EXISTS' '{' procedure_body '}'
```

### ALL_DIFFERENT 谓词

- Documentation key: `database-gql-reference/fe/predicates/all_different/`
- Summary: ALL_DIFFERENT谓词检查图元素列表中的所有图元素是否两两不同。
- Documented syntax:

```text
all_different_predicate ::=
    ALL_DIFFERENT '(' element_variable_reference (',' element_variable_reference)+ ')'
```

### 比较谓词

- Documentation key: `database-gql-reference/fe/predicates/comparison/`
- Summary: 比较谓词比较两个值，并在比较为真时返回true，为假时返回false。在任一值为null时，返回null。
- Documented syntax:

```text
comparison_predicate ::=
    comparison_predicand comp_op comparison_predicand

comp_op ::= '=' | '<>'  | '<' | '>' | '<=' | '>='
```

### EXISTS 谓词

- Documentation key: `database-gql-reference/fe/predicates/exists/`
- Summary: EXISTS谓词检查某个图模式是否存在或某个查询的结果是否非空。
- Documented syntax:

```text
exists_predicate ::=
    EXISTS ( '{' graph_pattern '}' | '(' graph_pattern ')' | '{' match_statement+ '}' | '{' procedure_body '}' )
```

### 标签谓词

- Documentation key: `database-gql-reference/fe/predicates/labeled/`
- Summary: 标签谓词检查图元素是否具有特定标签。
- Documented syntax:

```text
labeled_predicate ::=
    element_variable_reference ( ('IS' 'NOT'? 'LABELED') | ':') label_expression
```

### NULL 谓词

- Documentation key: `database-gql-reference/fe/predicates/null/`
- Summary: NULL 谓词检查值是否为null。
- Documented syntax:

```text
null_predicate ::=
    value_expression 'IS' 'NOT'? 'NULL'
```

### SAME 谓词

- Documentation key: `database-gql-reference/fe/predicates/same/`
- Summary: SAME谓词检查图元素列表中的所有图元素是否相同。
- Documented syntax:

```text
same_predicate ::=
    SAME '(' element_variable_reference (',' element_variable_reference)+ ')'
```

## patterns

### 图模式

- Documentation key: `database-gql-reference/patterns/`
- Summary: 图模式匹配是通过将 GQL 标准定义的正则表达式与属性图进行匹配，以获得简化后的匹配结果的过程。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### 边模式

- Documentation key: `database-gql-reference/patterns/edge-patterns/`
- Summary: 边模式是用于从属性图中匹配边的模式。边模式分为两种类型：完整边模式和简略边模式。完整边模式包含详细的匹配规则，而简略边模式仅包含边的方向。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### 点模式

- Documentation key: `database-gql-reference/patterns/node-patterns/`
- Summary: 点模式是用于从属性图中匹配点的常用模式。每个点模式由使用圆括号（()）包围的一个点模式填充器组成。点模式填充器指定要匹配的点的详细信息，包括点的标签和属性等。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### 路径模式

- Documentation key: `database-gql-reference/patterns/path-patterns/`
- Summary: 路径模式用于从图中匹配路径。一个路径模式由以下部分组成：
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

## set

### 变量操作

- Documentation key: `database-gql-reference/set/`
- Summary: SET语句用于对变量执行赋值、聚合和函数调用等操作。
- Documented syntax:

```text
assignment_statement ::=
    'SET' ( primitive_value_variable | aggregator_value_variable | active_set_variable ) '=' value_expression

aggregation_statement ::=
    'SET' aggregator_value_variable '+=' value_expression

function_call_statement ::=
    'SET' (aggregator_value_variable | table_variable) '.' member_function '(' ( argument (',' argument)* )? ')'
```
