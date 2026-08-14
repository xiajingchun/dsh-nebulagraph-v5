# Documented Function Catalog

Generated from NebulaGraph `5.3.0` user documentation by `scripts/refresh_documented_capabilities.py`. Do not edit manually.

This is the complete public function allowlist for `gql-query-generator`. Every listed function may be generated when its documented signature, target environment, input types, and prerequisites match. Absence from feature files or high-frequency examples is not a reason to reject a listed function.

Use exact-name search in this file before retaining or generating a function. If a name is absent, do not generate it unless the user explicitly provides an installed UDF.
The final non-call section preserves documented operators, expressions, and keyword-form zero-argument functions; search it by exact keyword when relevant.

## Coverage

- Database documented callable names: `146`
- Analytics documented callable names: `143`
- Shared names: `143`
- Documented non-call forms: `3`
- Database-only names: `edges()`, `ftscore()`, `nodes()`
- Analytics-only names: none

## aggregate

### `any_value()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/aggregate/`, `database-gql-reference/fe/functions/aggregate/`
- Signatures:

```text
any_value(n: E) -> E
```

### `avg()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/aggregate/`, `database-gql-reference/fe/functions/aggregate/`
- Signatures:

```text
avg(num: Numeric) -> DOUBLE | DECIMAL
```

### `collect()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/aggregate/`, `database-gql-reference/fe/functions/aggregate/`
- Signatures:

```text
collect(n: E) -> LIST
```

### `collect_list()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/aggregate/`, `database-gql-reference/fe/functions/aggregate/`
- Signatures:

```text
collect_list(n: E) -> LIST
```

### `count()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/aggregate/`, `database-gql-reference/fe/functions/aggregate/`
- Signatures:

```text
count(n: E) -> INT64
```

### `max()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/aggregate/`, `database-gql-reference/fe/functions/aggregate/`
- Signatures:

```text
max(n: E) -> E
```

### `min()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/aggregate/`, `database-gql-reference/fe/functions/aggregate/`
- Signatures:

```text
min(n: E) -> E
```

### `percentile_cont()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/aggregate/`, `database-gql-reference/fe/functions/aggregate/`
- Signatures:

```text
percentile_cont(num: Numeric, percentile: DOUBLE) -> DOUBLE | DECIMAL
```

### `percentile_disc()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/aggregate/`, `database-gql-reference/fe/functions/aggregate/`
- Signatures:

```text
percentile_disc(num: Numeric, percentile: DOUBLE) -> DOUBLE | DECIMAL
```

### `stddev_pop()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/aggregate/`, `database-gql-reference/fe/functions/aggregate/`
- Signatures:

```text
stddev_pop(num: Numeric) -> DOUBLE | DECIMAL
```

### `stddev_samp()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/aggregate/`, `database-gql-reference/fe/functions/aggregate/`
- Signatures:

```text
stddev_samp(num: Numeric) -> DOUBLE | DECIMAL
```

### `sum()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/aggregate/`, `database-gql-reference/fe/functions/aggregate/`
- Signatures:

```text
sum(num: Numeric) -> UINT64 | INT64 | DOUBLE | DECIMAL
```

## conditional

### `coalesce()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/expressions/case/`, `database-gql-reference/fe/expressions/case/`
- Signatures:

```text
coalesce(value_expression, value_expression, ...) -> first non-NULL value
```

## fulltext

### `ftscore()`

- Scope: Database only
- Documentation keys: `database-gql-reference/fe/functions/fulltext/`
- Signatures:

```text
ftscore(property_value_expression String, query String) -> DOUBLE
```

## geo

### `s2_cellidfrompoint()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/geo/`, `database-gql-reference/fe/functions/geo/`
- Signatures:

```text
S2_CellIdFromPoint(g Geography(Point)) -> UINT64
```

### `s2_coveringcellids()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/geo/`, `database-gql-reference/fe/functions/geo/`
- Signatures:

```text
S2_CoveringCellIds(g Geography) -> LIST<UINT64>
```

### `st_astext()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/geo/`, `database-gql-reference/fe/functions/geo/`
- Signatures:

```text
ST_ASText(g Geography) -> String
```

### `st_centroid()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/geo/`, `database-gql-reference/fe/functions/geo/`
- Signatures:

```text
ST_Centroid(g Geography) -> Geography(Point)
```

### `st_coveredby()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/geo/`, `database-gql-reference/fe/functions/geo/`
- Signatures:

```text
ST_CoveredBy(g1 Geography, g2 Geography) -> Boolean
```

### `st_covers()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/geo/`, `database-gql-reference/fe/functions/geo/`
- Signatures:

```text
ST_Covers(g1 Geography, g2 Geography) -> Boolean
```

### `st_distance()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/geo/`, `database-gql-reference/fe/functions/geo/`
- Signatures:

```text
ST_Distance(g1 Geography, g2 Geography) -> DOUBLE
```

### `st_dwithin()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/geo/`, `database-gql-reference/fe/functions/geo/`
- Signatures:

```text
ST_DWithin(g1 Geography, g2 Geography, distance DOUBLE) -> Boolean
```

### `st_geogfromtext()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/geo/`, `database-gql-reference/fe/functions/geo/`
- Signatures:

```text
ST_GeogFromText(wkt String) -> Geography(Any)
```

### `st_geogfromwkt()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/geo/`, `database-gql-reference/fe/functions/geo/`
- Signatures:

```text
ST_GeogFromWKT(wkt String) -> Geography(Any)
```

### `st_intersectionpoints()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/geo/`, `database-gql-reference/fe/functions/geo/`
- Signatures:

```text
ST_IntersectionPoints(g1 Geography, g2 Geography) -> LIST<Geography(Point)>
```

### `st_intersects()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/geo/`, `database-gql-reference/fe/functions/geo/`
- Signatures:

```text
ST_Intersects(g1 Geography, g2 Geography) -> Boolean
```

### `st_isvalid()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/geo/`, `database-gql-reference/fe/functions/geo/`
- Signatures:

```text
ST_ISValid(g Geography) -> Boolean
```

### `st_point()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/geo/`, `database-gql-reference/fe/functions/geo/`
- Signatures:

```text
ST_Point(longitude Numeric, latitude Numeric) -> Geography(Point)
```

## graph

### `cardinality()`

- Scope: Database only
- Documentation keys: `database-gql-reference/fe/functions/graph/`
- Signatures:

```text
cardinality(input: PATH) -> INT32
```

### `edges()`

- Scope: Database only
- Documentation keys: `database-gql-reference/fe/functions/graph/`
- Signatures:

```text
edges(p: PATH) | relationships(p: PATH) -> LIST<EDGE>
```

### `element_id()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/graph/`, `database-gql-reference/fe/functions/graph/`
- Signatures:

```text
element_id(n: NODE) -> INT64
```

### `end_node_id()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/graph/`, `database-gql-reference/fe/functions/graph/`
- Signatures:

```text
end_node_id(e: EDGE) -> INT64
```

### `labels()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/graph/`, `database-gql-reference/fe/functions/graph/`
- Signatures:

```text
labels(e: EDGE) -> LIST<STRING>
```

```text
labels(n: NODE) -> LIST<STRING>
```

### `left_node_id()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/graph/`, `database-gql-reference/fe/functions/graph/`
- Signatures:

```text
left_node_id(e: EDGE) -> INT64
```

### `length()`

- Scope: Database only
- Documentation keys: `database-gql-reference/fe/functions/graph/`
- Signatures:

```text
length(p: PATH) -> INT32
```

### `multiedge_id()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/graph/`, `database-gql-reference/fe/functions/graph/`
- Signatures:

```text
multiedge_id(e: EDGE) -> INT64
```

### `nodes()`

- Scope: Database only
- Documentation keys: `database-gql-reference/fe/functions/graph/`
- Signatures:

```text
nodes(p: PATH) -> LIST<NODE>
```

### `right_node_id()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/graph/`, `database-gql-reference/fe/functions/graph/`
- Signatures:

```text
right_node_id(e: EDGE) -> INT64
```

### `start_node_id()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/graph/`, `database-gql-reference/fe/functions/graph/`
- Signatures:

```text
start_node_id(e: EDGE) -> INT64
```

### `type()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/graph/`, `database-gql-reference/fe/functions/graph/`
- Signatures:

```text
type(e: EDGE) -> STRING
```

```text
type(n: NODE) -> STRING
```

## lambda

### `filter()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/lambda/`, `database-gql-reference/fe/functions/lambda/`
- Signatures:

```text
filter(l: List<E>, lambda: lambda_value_expr) -> List<E>
```

### `reduce()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/lambda/`, `database-gql-reference/fe/functions/lambda/`
- Signatures:

```text
reduce( l: list<E>, state: S, input_function: (S, E) -> S ) -> S
```

```text
reduce( l: list<E>, state: S, input_function: (S, E) -> S, output_function: (S) -> R ) -> R
```

### `transform()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/lambda/`, `database-gql-reference/fe/functions/lambda/`
- Signatures:

```text
transform(l: List<E>, lambda: lambda_value_expr) -> List<U>
```

## list

### `back()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/list/`, `database-gql-reference/fe/functions/list/`
- Signatures:

```text
back(l: LIST) -> E
```

### `cardinality()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/list/`, `database-gql-reference/fe/functions/list/`
- Signatures:

```text
cardinality(input: LIST | RECORD) -> INT32
```

### `head()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/list/`, `database-gql-reference/fe/functions/list/`
- Signatures:

```text
head(l: LIST) -> E
```

### `length()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/list/`, `database-gql-reference/fe/functions/list/`
- Signatures:

```text
length(l: LIST) -> INT32
```

### `list_distinct()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/list/`, `database-gql-reference/fe/functions/list/`
- Signatures:

```text
list_distinct(l: LIST) -> LIST
```

### `list_except()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/list/`, `database-gql-reference/fe/functions/list/`
- Signatures:

```text
list_except(x: LIST, y: LIST) -> LIST
```

### `list_intersect()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/list/`, `database-gql-reference/fe/functions/list/`
- Signatures:

```text
list_intersect(x: LIST, y: LIST) -> LIST
```

### `list_join()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/list/`, `database-gql-reference/fe/functions/list/`
- Signatures:

```text
list_join(l: LIST, delimiter: STRING, replace_null: STRING) -> STRING
```

### `list_max()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/list/`, `database-gql-reference/fe/functions/list/`
- Signatures:

```text
list_max(l: LIST) -> E
```

### `list_min()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/list/`, `database-gql-reference/fe/functions/list/`
- Signatures:

```text
list_min(l: LIST) -> E
```

### `list_slice()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/list/`, `database-gql-reference/fe/functions/list/`
- Signatures:

```text
list_slice(l: LIST<E>, start: INT32, end: INT32 [, step: INT32]) -> LIST<E>
```

### `list_sort()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/list/`, `database-gql-reference/fe/functions/list/`
- Signatures:

```text
list_sort(l: LIST) -> LIST
```

### `list_sum()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/list/`, `database-gql-reference/fe/functions/list/`
- Signatures:

```text
list_sum(l: LIST) -> UINT64 | INT64 | DOUBLE | DECIMAL
```

### `list_union()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/list/`, `database-gql-reference/fe/functions/list/`
- Signatures:

```text
list_union(x: LIST, y: LIST) -> LIST
```

### `range()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/list/`, `database-gql-reference/fe/functions/list/`
- Signatures:

```text
range(start: INT, end: INT [, step: INT]) -> LIST<INT>
```

### `remove_nulls()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/list/`, `database-gql-reference/fe/functions/list/`
- Signatures:

```text
remove_nulls(l: LIST) -> LIST
```

### `size()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/list/`, `database-gql-reference/fe/functions/list/`
- Signatures:

```text
size(list) -> INT32
size(set) -> INT32
size(map) -> INT32
size(table) -> INT64
```

### `tail()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/list/`, `database-gql-reference/fe/functions/list/`
- Signatures:

```text
tail(l: LIST) -> LIST
```

### `trim()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/list/`, `database-gql-reference/fe/functions/list/`
- Signatures:

```text
trim(l: LIST, trim_num: INT32) -> LIST
```

### `zip()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/list/`, `database-gql-reference/fe/functions/list/`
- Signatures:

```text
zip(l1: LIST, l2: LIST) -> LIST
```

## map

### `element_at()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/map/`, `database-gql-reference/fe/functions/map/`
- Signatures:

```text
element_at(target_map, key) -> ANY
```

### `map_append()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/map/`, `database-gql-reference/fe/functions/map/`
- Signatures:

```text
map_append(target_map, key, value) -> MAP
```

### `map_except()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/map/`, `database-gql-reference/fe/functions/map/`
- Signatures:

```text
map_except(map1, map2) -> MAP
```

### `map_filter()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/map/`, `database-gql-reference/fe/functions/map/`
- Signatures:

```text
map_filter(target_map, predicate) -> MAP
```

### `map_intersect()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/map/`, `database-gql-reference/fe/functions/map/`
- Signatures:

```text
map_intersect(map1, map2) -> MAP
```

### `map_keys()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/map/`, `database-gql-reference/fe/functions/map/`
- Signatures:

```text
map_keys(target_map) -> LIST
```

### `map_remove()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/map/`, `database-gql-reference/fe/functions/map/`
- Signatures:

```text
map_remove(target_map, key) -> MAP
```

### `map_replace()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/map/`, `database-gql-reference/fe/functions/map/`
- Signatures:

```text
map_replace(target_map, key, value) -> MAP
```

### `map_union()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/map/`, `database-gql-reference/fe/functions/map/`
- Signatures:

```text
map_union(map1, map2) -> MAP
```

### `map_values()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/map/`, `database-gql-reference/fe/functions/map/`
- Signatures:

```text
map_values(target_map) -> LIST
```

### `remove_nulls()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/map/`, `database-gql-reference/fe/functions/map/`
- Signatures:

```text
remove_nulls(target_map) -> MAP
```

## math

### `abs()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/math/`, `database-gql-reference/fe/functions/math/`
- Signatures:

```text
abs(num: Numeric) -> Numeric
```

### `acos()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/math/`, `database-gql-reference/fe/functions/math/`
- Signatures:

```text
acos(num: Numeric) -> DOUBLE
```

### `asin()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/math/`, `database-gql-reference/fe/functions/math/`
- Signatures:

```text
asin(num: Numeric) -> DOUBLE
```

### `atan()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/math/`, `database-gql-reference/fe/functions/math/`
- Signatures:

```text
atan(num: Numeric) -> DOUBLE
```

### `ceil()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/math/`, `database-gql-reference/fe/functions/math/`
- Signatures:

```text
ceil(num: Numeric) -> Numeric
```

### `ceiling()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/math/`, `database-gql-reference/fe/functions/math/`
- Signatures:

```text
ceiling(num: Numeric) -> Numeric
```

### `cos()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/math/`, `database-gql-reference/fe/functions/math/`
- Signatures:

```text
cos(num: Numeric) -> DOUBLE
```

### `cosh()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/math/`, `database-gql-reference/fe/functions/math/`
- Signatures:

```text
cosh(num: Numeric) -> DOUBLE
```

### `cot()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/math/`, `database-gql-reference/fe/functions/math/`
- Signatures:

```text
cot(num: Numeric) -> DOUBLE
```

### `exp()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/math/`, `database-gql-reference/fe/functions/math/`
- Signatures:

```text
exp(num: Numeric) ->  DOUBLE | DECIMAL
```

### `floor()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/math/`, `database-gql-reference/fe/functions/math/`
- Signatures:

```text
floor(num: Numeric) -> Numeric
```

### `haversin()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/math/`, `database-gql-reference/fe/functions/math/`
- Signatures:

```text
haversin(num: Numeric) -> DOUBLE
```

### `isnan()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/math/`, `database-gql-reference/fe/functions/math/`
- Signatures:

```text
isnan(num: Numeric) -> BOOLEAN
```

### `ln()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/math/`, `database-gql-reference/fe/functions/math/`
- Signatures:

```text
ln(num: Numeric) ->  DOUBLE | DECIMAL
```

### `log()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/math/`, `database-gql-reference/fe/functions/math/`
- Signatures:

```text
log(b: Numeric, num: Numeric) ->  DOUBLE | DECIMAL
```

### `log10()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/math/`, `database-gql-reference/fe/functions/math/`
- Signatures:

```text
log10(num: Numeric) -> DOUBLE
```

### `mod()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/math/`, `database-gql-reference/fe/functions/math/`
- Signatures:

```text
mod(dividend: Numeric, divisor: Numeric) -> Numeric
```

### `pi()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/math/`, `database-gql-reference/fe/functions/math/`
- Signatures:

```text
pi() -> DOUBLE | FLOAT
```

### `power()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/math/`, `database-gql-reference/fe/functions/math/`
- Signatures:

```text
power(base: Numeric, exponent: Numeric) -> DOUBLE | DECIMAL
```

### `rand()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/math/`, `database-gql-reference/fe/functions/math/`
- Signatures:

```text
rand() -> DOUBLE | FLOAT
```

### `round()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/math/`, `database-gql-reference/fe/functions/math/`
- Signatures:

```text
round(num: Numeric [, precision: INT32 ]) ->  DOUBLE | DECIMAL
```

### `sign()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/math/`, `database-gql-reference/fe/functions/math/`
- Signatures:

```text
sign(num: Numeric) -> INT8
```

### `sin()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/math/`, `database-gql-reference/fe/functions/math/`
- Signatures:

```text
sin(num: Numeric) -> DOUBLE
```

### `sinh()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/math/`, `database-gql-reference/fe/functions/math/`
- Signatures:

```text
sinh(num: Numeric) -> DOUBLE
```

### `sqrt()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/math/`, `database-gql-reference/fe/functions/math/`
- Signatures:

```text
sqrt(num: Numeric) -> DOUBLE | DECIMAL
```

### `tan()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/math/`, `database-gql-reference/fe/functions/math/`
- Signatures:

```text
tan(num: Numeric) -> DOUBLE
```

### `tanh()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/math/`, `database-gql-reference/fe/functions/math/`
- Signatures:

```text
tanh(num: Numeric) -> DOUBLE
```

## set

### `remove_nulls()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/set/`, `database-gql-reference/fe/functions/set/`
- Signatures:

```text
remove_nulls(target_set) -> SET
```

### `set_append()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/set/`, `database-gql-reference/fe/functions/set/`
- Signatures:

```text
set_append(target_set, value) -> SET
```

### `set_except()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/set/`, `database-gql-reference/fe/functions/set/`
- Signatures:

```text
set_except(set1, set2) -> SET
```

### `set_filter()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/set/`, `database-gql-reference/fe/functions/set/`
- Signatures:

```text
set_filter(target_set, predicate) -> SET
```

### `set_intersect()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/set/`, `database-gql-reference/fe/functions/set/`
- Signatures:

```text
set_intersect(set1, set2) -> SET
```

### `set_max()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/set/`, `database-gql-reference/fe/functions/set/`
- Signatures:

```text
set_max(target_set) -> NUMERIC | NULL
```

### `set_min()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/set/`, `database-gql-reference/fe/functions/set/`
- Signatures:

```text
set_min(target_set) -> NUMERIC | NULL
```

### `set_remove()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/set/`, `database-gql-reference/fe/functions/set/`
- Signatures:

```text
set_remove(target_set, value) -> SET
```

### `set_sum()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/set/`, `database-gql-reference/fe/functions/set/`
- Signatures:

```text
set_sum(target_set) -> NUMERIC
```

### `set_union()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/set/`, `database-gql-reference/fe/functions/set/`
- Signatures:

```text
set_union(set1, set2) -> SET
```

## string

### `contains()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/string/`, `database-gql-reference/fe/functions/string/`
- Signatures:

```text
contains(str: STRING, substr: STRING) -> BOOL
```

### `fmt()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/string/`, `database-gql-reference/fe/functions/string/`
- Signatures:

```text
fmt(str: STRING, value: STRING | Numeric | BOOLEAN [, value...]) -> STRING
```

### `index_of()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/string/`, `database-gql-reference/fe/functions/string/`
- Signatures:

```text
index_of(str: STRING, substr: STRING[, from: INT, to: INT]) -> INT
```

### `indexes_of()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/string/`, `database-gql-reference/fe/functions/string/`
- Signatures:

```text
indexes_of(str: STRING, substr: STRING[, from: INT, to: INT]) -> LIST<INT>
```

### `left()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/string/`, `database-gql-reference/fe/functions/string/`
- Signatures:

```text
left(str: STRING, len: INT32) -> STRING
```

### `length()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/string/`, `database-gql-reference/fe/functions/string/`
- Signatures:

```text
length(str: STRING) -> INT32
```

### `like()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/string/`, `database-gql-reference/fe/functions/string/`
- Signatures:

```text
like(str: STRING, pattern: STRING) -> BOOLEAN
```

### `lower()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/string/`, `database-gql-reference/fe/functions/string/`
- Signatures:

```text
lower(str: STRING) -> STRING
```

### `ltrim()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/string/`, `database-gql-reference/fe/functions/string/`
- Signatures:

```text
ltrim( source_str: STRING [ , trim_str: STRING ] ) -> STRING
```

### `md5()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/string/`, `database-gql-reference/fe/functions/string/`
- Signatures:

```text
md5(str: STRING | l: LIST<STRING>) -> STRING
```

### `regexp_like()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/string/`, `database-gql-reference/fe/functions/string/`
- Signatures:

```text
regexp_like(str: STRING, pattern: STRING [, options: STRING]) -> BOOLEAN
```

### `repeat()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/string/`, `database-gql-reference/fe/functions/string/`
- Signatures:

```text
repeat(str: STRING, count: INT32) -> STRING
```

### `right()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/string/`, `database-gql-reference/fe/functions/string/`
- Signatures:

```text
right(str: STRING, len: INT32) -> STRING
```

### `rtrim()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/string/`, `database-gql-reference/fe/functions/string/`
- Signatures:

```text
rtrim( source_str: STRING [, trim_str: STRING] ) -> STRING
```

### `split()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/string/`, `database-gql-reference/fe/functions/string/`
- Signatures:

```text
split(str: STRING, regex: STRING[, limit: UINT]) -> LIST<STRING>
```

### `substring()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/string/`, `database-gql-reference/fe/functions/string/`
- Signatures:

```text
substring(str: STRING, idx: INT32, len: INT32) -> STRING
```

### `to_literal()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/string/`, `database-gql-reference/fe/functions/string/`
- Signatures:

```text
to_literal(input: E) -> STRING
```

### `trim()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/string/`, `database-gql-reference/fe/functions/string/`
- Signatures:

```text
trim( [ [ LEADING | TRAILING | BOTH ] [ trim_char: STRING ] FROM ] source_str: STRING ) -> STRING
```

### `upper()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/string/`, `database-gql-reference/fe/functions/string/`
- Signatures:

```text
upper(str: STRING) -> STRING
```

## system

### `typeof()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/system/`, `database-gql-reference/fe/functions/system/`
- Signatures:

```text
typeof(input: E) -> STRING
```

## table

### `table_split()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/table/`, `database-gql-reference/fe/functions/table/`
- Signatures:

```text
table_split(t: TABLE) -> LIST
```

```text
table_split(t: TABLE, size: UINT64) -> LIST
```

## temporal

### `date()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/temporal/`, `database-gql-reference/fe/functions/temporal/`
- Signatures:

```text
date(s: STRING) -> DATE
```

### `duration()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/temporal/`, `database-gql-reference/fe/functions/temporal/`
- Signatures:

```text
duration({years: int = 0, months: int = 0, days: int = 0, hours: int = 0, minutes: int = 0, seconds: int = 0, milliseconds: int = 0, microseconds: int = 0}) -> str
```

### `duration_between()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/temporal/`, `database-gql-reference/fe/functions/temporal/`
- Signatures:

```text
duration_between(start: TEMPORAL_INSTANT, end: TEMPORAL_INSTANT) [ DAY TO SECOND | YEAR TO MONTH ] -> str
```

### `from_epoch()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/temporal/`, `database-gql-reference/fe/functions/temporal/`
- Signatures:

```text
from_epoch(unix timestamp: INT64) -> ZONEDDATETIME
```

### `local_datetime()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/temporal/`, `database-gql-reference/fe/functions/temporal/`
- Signatures:

```text
local_datetime(datetime: str, format: str) -> LOCAL DATETIME
```

### `local_time()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/temporal/`, `database-gql-reference/fe/functions/temporal/`
- Signatures:

```text
local_time(time: str, format: str) -> LOCAL TIME
```

### `to_epoch()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/temporal/`, `database-gql-reference/fe/functions/temporal/`
- Signatures:

```text
to_epoch(time: ZONEDDATETIME) -> INT64
```

### `zoned_datetime()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/temporal/`, `database-gql-reference/fe/functions/temporal/`
- Signatures:

```text
zoned_datetime(datetime: str, format: str) -> ZONED DATETIME
```

### `zoned_time()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/temporal/`, `database-gql-reference/fe/functions/temporal/`
- Signatures:

```text
zoned_time(time: str, format: str) -> ZONED TIME
```

## vector

### `abs()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/vector/`, `database-gql-reference/fe/functions/vector/`
- Signatures:

```text
abs(v: VECTOR) -> VECTOR
```

### `abs2()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/vector/`, `database-gql-reference/fe/functions/vector/`
- Signatures:

```text
abs2(v: VECTOR) -> VECTOR
```

### `accum()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/vector/`, `database-gql-reference/fe/functions/vector/`
- Signatures:

```text
accum(v: VECTOR) ->  FLOAT
```

### `cosine()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/vector/`, `database-gql-reference/fe/functions/vector/`
- Signatures:

```text
cosine(v1: VECTOR, v2: VECTOR) -> FLOAT
```

### `euclidean()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/vector/`, `database-gql-reference/fe/functions/vector/`
- Signatures:

```text
euclidean(v1: VECTOR, v2: VECTOR) -> FLOAT
```

### `exp()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/vector/`, `database-gql-reference/fe/functions/vector/`
- Signatures:

```text
exp(v: VECTOR) ->  VECTOR
```

### `inner_product()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/vector/`, `database-gql-reference/fe/functions/vector/`
- Signatures:

```text
inner_product(v1: VECTOR, v2: VECTOR) -> FLOAT
```

### `ln()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/vector/`, `database-gql-reference/fe/functions/vector/`
- Signatures:

```text
ln(v: VECTOR) ->  VECTOR
```

### `log10()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/vector/`, `database-gql-reference/fe/functions/vector/`
- Signatures:

```text
log10(v: VECTOR) ->  VECTOR
```

### `mean()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/vector/`, `database-gql-reference/fe/functions/vector/`
- Signatures:

```text
mean(v: VECTOR) ->  FLOAT
```

### `norm()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/vector/`, `database-gql-reference/fe/functions/vector/`
- Signatures:

```text
norm(v: VECTOR) ->  FLOAT
```

### `normalize()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/vector/`, `database-gql-reference/fe/functions/vector/`
- Signatures:

```text
normalize(v: VECTOR) ->  VECTOR
```

### `prod()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/vector/`, `database-gql-reference/fe/functions/vector/`
- Signatures:

```text
prod(v: VECTOR) ->  FLOAT
```

### `sqrt()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/vector/`, `database-gql-reference/fe/functions/vector/`
- Signatures:

```text
sqrt(num: VECTOR) -> VECTOR
```

### `squared_norm()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/vector/`, `database-gql-reference/fe/functions/vector/`
- Signatures:

```text
squared_norm(v: VECTOR) ->  FLOAT
```

### `vector_distance()`

- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/vector/`, `database-gql-reference/fe/functions/vector/`
- Signatures:

```text
vector_distance(v1: VECTOR, v2: VECTOR COSINE) -> FLOAT
```

```text
vector_distance(v1: VECTOR, v2: VECTOR DOT) -> FLOAT
```

```text
vector_distance(v1: VECTOR, v2: VECTOR [EUCLIDEAN]) -> FLOAT
```

## Documented Non-Call Forms

These public forms are documented beside functions but are operators, expressions, or keyword-form zero-argument functions rather than ordinary calls.

### `str: STRING LIKE pattern: STRING -> BOOLEAN`

- Family: string
- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/string/`, `database-gql-reference/fe/functions/string/`
- Documented form:

```text
str: STRING LIKE pattern: STRING -> BOOLEAN
```

### `CURRENT_TIME`

- Family: temporal
- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/temporal/`, `database-gql-reference/fe/functions/temporal/`
- Documented form:

```text
CURRENT_TIME
```

### `CURRENT_TIMESTAMP`

- Family: temporal
- Scope: Database and Analytics
- Documentation keys: `analytics-gql-reference/fe/functions/temporal/`, `database-gql-reference/fe/functions/temporal/`
- Documented form:

```text
CURRENT_TIMESTAMP
```
