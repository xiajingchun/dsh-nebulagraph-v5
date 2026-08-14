# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: Lambda Function

  Scenario: Transform Function
    When executing query:
      """
      RETURN transform(LIST[1, 2, 3], x -> 2 * x + 1) as a
      """
    Then the result should be, in any order:
      | a              |
      | LIST [3, 5, 7] |
    When executing query:
      """
      LET l = NULL
      RETURN transform(l, x -> 2 * x + 1) as a
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    When executing query:
      """
      RETURN transform(NULL, x -> 2 * x + 1) as a
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    When executing query:
      """
      RETURN transform(NULL, x -> 2 * x + 1) as a
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    When executing query:
      """
      FOR i IN [ [1, 2, 3], [4, 5], NULL, [] ]
      RETURN transform(i, x -> 2 * x + 1) as a
      """
    Then the result should be, in any order:
      | a              |
      | LIST [3, 5, 7] |
      | LIST [9, 11]   |
      | NULL           |
      | LIST []        |
    When executing query:
      """
      RETURN transform(LIST[1, 2, 3], x -> CASE WHEN x % 2 = 0 THEN 2 * x ELSE 0 END) as a
      """
    Then the result should be, in any order:
      | a              |
      | LIST [0, 4, 0] |
    When executing query:
      """
      RETURN LIST [1, 2, 3] as l
      UNION
      RETURN LIST [4, 5] as l
      NEXT
      RETURN CASE WHEN length(l) = 3 THEN transform(l, x -> x + 1) ELSE transform(l, x -> x - 1) END as a
      """
    Then the result should be, in any order:
      | a              |
      | LIST [2, 3, 4] |
      | LIST [3, 4]    |
    When executing query:
      """
      USE ldbc
      MATCH p = (v:Person{firstName:"Tim"})-[e1:KNOWS]-()
      RETURN transform(nodes(p), n -> element_id(n)) as a
      """
    Then the result should be, in any order:
      | a                                             |
      | LIST [289293960378056708, 289293960378056708] |
      | LIST [289293960378056708, 289293960378056708] |
    When executing query:
      """
      USE ldbc
      MATCH p = (v:Person{firstName:"Tim"})-[e1:KNOWS]-()
      RETURN transform(nodes(p), n -> n.firstName) as a
      """
    Then the result should be, in any order:
      | a                   |
      | LIST ["Tim", "Tim"] |
      | LIST ["Tim", "Tim"] |
    When executing query:
      """
      USE ldbc
      MATCH p = TRAIL (a:Person{id:1})-[e:KNOWS]->{1,5}(b)
      RETURN transform(nodes(p), n -> n.id) as a
      """
    Then the result should be, in any order:
      | a           |
      | LIST [1, 1] |
    When executing query:
      """
      LET r = 10
      FOR l IN [ [1,5], NULL, [6,2,8], []  ]
      RETURN transform(l, x -> x + r) AS a
      """
    Then the result should be, in any order:
      | a                 |
      | LIST [11, 15]     |
      | NULL              |
      | LIST [16, 12, 18] |
      | LIST []           |
    When executing query:
      """
      LET r = 10
      RETURN transform([], x -> x + r) AS a
      """
    Then the result should be, in any order:
      | a       |
      | LIST [] |
    When executing query:
      """
      LET r = 10, l = NULL
      RETURN transform(l, x -> x + r) AS a
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    # When executing query:
    # """
    # LET r = 10
    # RETURN transform(NULL, x -> x + r) AS a
    # """
    # Then the result should be, in any order:
    # | a    |
    # | NULL |
    When executing query:
      """
      LET r = 10, l = NULL
      RETURN transform(l, x -> x + r) AS a
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    When executing query:
      """
      let l = LIST [1, 2, 3]
      RETURN transform(transform(l, x -> x + 1), x -> x + 1) as a
      """
    Then the result should be, in any order:
      | a              |
      | LIST [3, 4, 5] |
    When executing query:
      """
      LET x = 1, l = [1, 2, 3]
      RETURN transform(l, x -> x + 1)
      """
    Then an Error should be raised: "[NS002]: Semantic error, duplicate defined variable: `x`"
    When executing query:
      """
      let l = 42
      RETURN transform(l, x -> x + 1) as a
      """
    Then an Error should be raised: "[NR002]: Undefined function: `transform(INT32)`"
    When executing query:
      """
      let l = LIST [1, 2, 3]
      RETURN transform(l, x -> not_exist_v + 1) as a
      """
    Then an Error should be raised: "[42N18]: Invalid syntax, variable `not_exist_v` not defined"
    When executing query:
      """
      USE ldbc
      MATCH (a:Person{id:1})
      RETURN transform([1, 2], x -> x + length(a.firstName)) AS a
      """
    Then the result should be, in any order:
      | a           |
      | LIST [5, 6] |
    When executing query:
      """
      USE ldbc
      MATCH (a:Person)
      WHERE size(transform([1], i -> a.firstName IS NOT NULL)) = 1
      RETURN count(1) AS c
      """
    Then the result should be, in any order:
      | c |
      | 4 |
    When executing query:
      """
      USE ldbc
      MATCH (a:Person)-[e:KNOWS]->(b:Person)
      WHERE size(transform([1], i -> e.creationDate IS NULL OR e.creationDate IS NOT NULL)) = 1
      RETURN count(1) AS c
      """
    Then the result should be, in any order:
      | c |
      | 3 |

  Scenario: Reduce with input function
    When executing query:
      """
      RETURN reduce(range(1,3), 100, (state, item) -> state + item) AS a
      """
    Then the result should be, in any order:
      | a   |
      | 106 |
    When executing query:
      """
      RETURN reduce([1, 2, 3], NULL, (state, item) -> state + item) AS a
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    When executing query:
      """
      RETURN reduce([1, 2, 3], NULL, (state, item) -> state) AS a
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    When executing query:
      """
      RETURN reduce([1, 2, 3], NULL, (state, item) -> item) AS a
      """
    Then the result should be, in any order:
      | a |
      | 3 |
    When executing query:
      """
      RETURN reduce([1, 2, 3], NULL, (state, item) -> state IS NULL) AS a
      """
    Then the result should be, in any order:
      | a     |
      | false |
    When executing query:
      """
      RETURN reduce([1, 2, 3], NULL, (state, item) -> item IS NULL) AS a
      """
    Then the result should be, in any order:
      | a     |
      | false |
    # result is null if the list is null
    When executing query:
      """
      RETURN reduce(NULL, 100, (state, item) ->state) AS a
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    When executing query:
      """
      LET a = NULL
      RETURN reduce(a, 100, (state, item) ->state) AS a
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    When executing query:
      """
      LET a = [ [1, 2], [1, 2, 3], [1], [1, 2, 3, 4], [], NULL]
      FOR l IN a
      RETURN reduce(l, 100, (state, item) -> state + item) AS a
      """
    Then the result should be, in any order:
      | a    |
      | 103  |
      | 106  |
      | 101  |
      | 110  |
      | 100  |
      | NULL |
    When executing query:
      """
      RETURN reduce([1, 2, 3], 0, (state, item) -> state + item, state -> state) AS a
      """
    Then the result should be, in any order:
      | a |
      | 6 |
    When executing query:
      """
      RETURN reduce([1, 2, 3], 0, (state, item) -> state + item, state -> state * 2) AS a
      """
    Then the result should be, in any order:
      | a  |
      | 12 |
    When executing query:
      """
      RETURN reduce([1, 2, 3], 0, (state, item) -> state + item, x -> x * 2) AS a
      """
    Then the result should be, in any order:
      | a  |
      | 12 |
    When executing query:
      """
      LET r = 3
      FOR l IN [ [1,5], NULL, [6,2,8], []  ]
      RETURN reduce(l, 100, (state, item) -> state + item + r) AS a
      """
    Then the result should be, in any order:
      | a    |
      | 112  |
      | null |
      | 125  |
      | 100  |
    When executing query:
      """
      LET r = 3
      FOR l IN [ [1,5], NULL, [6,2,8], []  ]
      RETURN reduce(l, 100, (state, item) -> state + item + r, state -> state * r) AS a
      """
    Then the result should be, in any order:
      | a    |
      | 336  |
      | null |
      | 375  |
      | 300  |
    When executing query:
      """
      RETURN reduce([1, 2, 3], 100, (state, item) -> (state + item), state -> CASE WHEN state is NULL THEN 0 ELSE state * 2 END) AS a
      """
    Then the result should be, in any order:
      | a   |
      | 212 |
    When executing query:
      """
      RETURN reduce([1, 2, 3], 100, (state, item) -> NULL, state -> CASE WHEN state is NULL THEN 0 ELSE state END) AS a
      """
    Then the result should be, in any order:
      | a |
      | 0 |
    When executing query:
      """
      LET r = 3, l = []
      RETURN reduce(l, 100, (state, item) -> item + r) AS a
      """
    Then the result should be, in any order:
      | a   |
      | 100 |
    When executing query:
      """
      LET r = 3, l = []
      RETURN reduce(l, 100, (state, item) -> item, state -> state + r) AS a
      """
    Then the result should be, in any order:
      | a   |
      | 103 |
    When executing query:
      """
      LET r = 3, l = NULL
      RETURN reduce(l, 100, (state, item) -> item + r) AS a
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    When executing query:
      """
      USE ldbc
      MATCH (s:Person)
      RETURN reduce(
        range(1, 10),
        0,
        (state, item) -> state + item + length(s.firstName)
      ) AS a
      """
    Then the result should be, in any order:
      | a   |
      | 85  |
      | 115 |
      | 95  |
      | 95  |
    When executing query:
      """
      USE ldbc
      MATCH (a:Person{id:1})
      RETURN reduce([1, 2], 0, (state, x) -> state + x + length(a.firstName)) AS a
      """
    Then the result should be, in any order:
      | a  |
      | 11 |
    When executing query:
      """
      USE ldbc
      MATCH (a:Person)
      WHERE reduce([1], false, (acc, i) -> acc OR (a.firstName IS NOT NULL))
      RETURN count(1) AS c
      """
    Then the result should be, in any order:
      | c |
      | 4 |
    When executing query:
      """
      USE ldbc
      MATCH (a:Person)-[e:KNOWS]->(b:Person)
      WHERE reduce([a], false, (acc, i) -> acc OR (e.creationDate IS NOT NULL))
      RETURN count(1) AS c
      """
    Then the result should be, in any order:
      | c |
      | 3 |
    # The type of inital state parameter is not compatible with the return type of the input function
    When executing query:
      """
      RETURN reduce([1, 2, 3], 100, (state, item) -> "abc") AS a
      """
    Then an Error should be raised: "[NR006]: Resolve function failed: `reduce(LIST[1, 2, 3], 100, (state, item) -> \"abc\")`"
    # Use reduce to calculate the average value of a list.
    # reduce(list: list<T>, state: S, input_function: (S,T) -> S, output_function: (S) -> R) -> R
    # The current function registration mechanism can only support the case where the type R is the same as the type S.
    # See https://github.com/vesoft-inc/nebula-ng/issues/4784
    When executing query:
      """
      RETURN reduce([1, 2, 3, 4],
                    {sum: 0.0, count: 0},
                    (state, item) -> {sum: state.sum + item, count: state.count + 1},
                    state -> CASE WHEN state.count = 0 THEN NULL ELSE state.sum / state.count END) AS a
      """
    Then an Error should be raised: "[NR006]: Resolve function failed: `reduce(LIST, RECORD) -> DECIMAL`"
    # Use reduce to implement insertion sort style accumulation
    When executing query:
      """
      RETURN reduce(
        [5, 2, 4, 6, 1, 3],
        [],
        (sorted, item) -> filter(sorted, x -> x <= item) || [item] || filter(sorted, x -> x > item)
      ) AS sorted
      """
    Then the result should be, in any order:
      | sorted                  |
      | LIST [1, 2, 3, 4, 5, 6] |
    When executing query:
      """
      FOR i IN [
      {names: ["first_long_name_A.X_part", null, null, "", "second_long_name_B.Y_part",null,null,"123"], items: ["first_long_name_A", "second_long_name_B", null, "first_long_name_A"]},
      {names: ["third_long_name_C.Z_part", "", null, "123"],                               items: ["third_long_name_C","",null]}
      ]
      RETURN reduce(
      i.names,
      [],
      (state, n) -> state || reduce(
        i.items,
        {r: [], tn: case when length(n)>0 then substring(n, 1, CAST(indexesof(n, ".")[-1] AS INT32)) else "invalid-substring" end},
        (acc, x) -> {r: acc.r || [CASE WHEN acc.tn = x THEN 1 ELSE 0 END], tn: acc.tn}
      ).r
      ) AS res
      """
    Then the result should be, in any order:
      | res                                                                   |
      | LIST[1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0] |
      | LIST[1,0,0,0,0,0,0,0,0,0,0,0]                                         |

  Scenario: Filter Function
    When executing query:
      """
      RETURN filter(LIST[1, -2, 3, NULL, 0], x -> x > 0) as a
      """
    Then the result should be, in any order:
      | a           |
      | LIST [1, 3] |
    When executing query:
      """
      RETURN filter(LIST[1, -2, 3, NULL, 0], x -> x is NULL) as a
      """
    Then the result should be, in any order:
      | a           |
      | LIST [NULL] |
    When executing query:
      """
      RETURN filter(LIST[1, -2, 3, NULL, 0], x -> x is NOT NULL) as a
      """
    Then the result should be, in any order:
      | a                  |
      | LIST [1, -2, 3, 0] |
    When executing query:
      """
      RETURN filter(transform(LIST[1, -2, 3, NULL, 0], x -> x + 1), x -> x > 0) as a
      """
    Then the result should be, in any order:
      | a              |
      | LIST [2, 4, 1] |
    # result is null if the list is null
    When executing query:
      """
      LET a = NULL
      RETURN filter(a, x -> x > 1) AS a
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    When executing query:
      """
      RETURN filter(NULL, x -> x > 1) AS a
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    When executing query:
      """
      FOR i IN [ [1], [-2, 3], [NULL, 0], NULL ]
      RETURN filter(i, x -> x > 0) as a
      """
    Then the result should be, in any order:
      | a        |
      | LIST [1] |
      | LIST [3] |
      | LIST []  |
      | NULL     |
    When executing query:
      """
      LET a = [3, 1, 2]
      FILTER filter(a, x -> x > 1) IS NOT NULL
      RETURN a
      """
    Then the result should be, in any order:
      | a              |
      | LIST [3, 1, 2] |
    When executing query:
      """
      LET r = 3
      FOR l IN [ [1,5], NULL, [6,2,8], []  ]
      RETURN filter(l, x -> x > r) AS a
      """
    Then the result should be, in any order:
      | a           |
      | LIST [5]    |
      | NULL        |
      | LIST [6, 8] |
      | LIST []     |
    When executing query:
      """
      LET r = 3
      RETURN filter([], x -> x > r) AS a
      """
    Then the result should be, in any order:
      | a       |
      | LIST [] |
    When executing query:
      """
      VALUE a = 2
      RETURN filter([1,2,3], x -> x % a = 0 ) AS a
      """
    Then the result should be, in any order:
      | a        |
      | LIST [2] |
    When executing query:
      """
      LET a = 2
      RETURN filter([1,2,3], x -> x % a = 0 ) AS a
      """
    Then the result should be, in any order:
      | a        |
      | LIST [2] |
    When executing query:
      """
      LET r = 3, l = []
      RETURN filter(l, x -> x > r) AS a
      """
    Then the result should be, in any order:
      | a       |
      | LIST [] |
    When executing query:
      """
      LET r = 3
      RETURN filter(NULL, x -> x > r) AS a
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    When executing query:
      """
      LET r = 3, l = NULL
      RETURN filter(l, x -> x > r) AS a
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    When executing query:
      """
      USE ldbc
      MATCH (a:Person)
      RETURN size(filter([1], i -> a.firstName IS NOT NULL)) > 0 as a
      """
    Then the result should be, in any order:
      | a    |
      | true |
      | true |
      | true |
      | true |
    When executing query:
      """
      USE ldbc
      MATCH (a:Person)-[e:KNOWS]->(b:Person)
      WHERE size(filter([a], i -> b.firstName is not Null)) > 0
      RETURN count(1) AS c
      """
    Then the result should be, in any order:
      | c |
      | 3 |
    When executing query:
      """
      USE ldbc
      MATCH (a:Person)
      WHERE size(filter([1], i -> a.firstName IS NOT NULL)) > 0
      RETURN count(1) AS c
      """
    Then the result should be, in any order:
      | c |
      | 4 |
    # Ensure the outer variable hold_time is correctly captured in the lambda function
    And use graph "ldbc"
    When executing query:
      """
      MATCH (v1:Person{id:1})
      RETURN v1, v1.creationDate AS hold_time
      NEXT
      MATCH p = TRAIL (v1)-[e:KNOWS]->{1,2}(v2:Person)
      RETURN v2, filter(edges(p), x -> x.creationDate - duration({days:1}) < hold_time) AS t
      NEXT
      FILTER size(t) > 0
      RETURN v2
      """
    Then the execution should be successful
    When executing query:
      """
      match (v:Person{id:1})-[e]->{1,2}(v2)
      return transform(e,x->x.creationDate),filter(transform(e,x->x.creationDate),x-> x is not null and x.year=2011) as a
      """
    Then the execution should be successful
    When executing query:
      """
      match p=(v@Person{id:1})-[e]-(v2)where size(filter(nodes(p),x->x.firstName <> "Tim"))=2 return nodes(p)
      """
    Then the execution should be successful

  # Nested lambda usage
  Scenario: Lambda nested in lambda body
    # Transform + Filter (captures x)
    When executing query:
      """
      RETURN transform([1, 2, 3], x -> x + size(filter([1, 3, 5, 7], i -> i > x))) AS a
      """
    Then the result should be, in any order:
      | a              |
      | LIST [4, 5, 5] |
    When executing query:
      """
      RETURN transform([1, 2, 3], x -> size(filter([0, 1, 2, 3], i -> i < x))) AS a
      """
    Then the result should be, in any order:
      | a              |
      | LIST [1, 2, 3] |
    When executing query:
      """
      RETURN transform([1, 2, 3], x -> size(filter([1, 4, 9, 16], i -> i > x * x))) AS a
      """
    Then the result should be, in any order:
      | a              |
      | LIST [3, 2, 1] |
    # Transform + Transform (captures x)
    When executing query:
      """
      RETURN transform([1, 2, 3], x -> size(transform([10, 20, 30], y -> y + x))) AS a
      """
    Then the result should be, in any order:
      | a              |
      | LIST [3, 3, 3] |
    # Filter + Filter (captures x)
    When executing query:
      """
      RETURN filter([1, 2, 3], x -> size(filter([1, 3, 5, 7], i -> i > x)) > 0) AS a
      """
    Then the result should be, in any order:
      | a              |
      | LIST [1, 2, 3] |
    # Reduce nested
    When executing query:
      """
      RETURN transform([1, 2, 3], x -> x + reduce([10, 20], 0, (s, y) -> s + y)) AS a
      """
    Then the result should be, in any order:
      | a                 |
      | LIST [31, 32, 33] |
    When executing query:
      """
      RETURN reduce([1, 2, 3], 0, (s, x) -> s + size(transform([x, x + 1], y -> y))) AS a
      """
    Then the result should be, in any order:
      | a |
      | 6 |
    And use graph "ldbc"
    # Nested lambda: outer variable list from nodes(), inner constant list
    When executing query:
      """
      MATCH p = (v:Person{id:1})-[e:FOLLOWS]->(v2)
      RETURN transform(nodes(p), n -> size(filter([1, 3, 5, 7], i -> i > n.id))) AS a
      """
    Then the result should be, in any order:
      | a           |
      | LIST [3, 3] |
    When executing query:
      """
      MATCH p = (v:Person{id:3})-[e:FOLLOWS]->(v2)
      WHERE size(transform(nodes(p), n -> size(filter([1, 3, 5, 7], i -> i > n.id)))) >= 0
      RETURN count(1) AS c
      """
    Then the result should be, in any order:
      | c |
      | 2 |
    When executing query:
      """
      MATCH p = (v:Person{id:2})-[e:FOLLOWS]->(v2)
      RETURN nodes(p) AS ns
      NEXT
      FILTER size(transform(ns, n -> size(filter([1, 3, 5, 7], i -> i > n.id)))) >= 0
      RETURN transform(ns, n -> n.id) as ids
      """
    Then the result should be, in any order:
      | ids         |
      | LIST [2, 3] |
      | LIST [2, 4] |
    # Nested lambda: both outer and inner are variable lists
    When executing query:
      """
      MATCH (v1:Person{id:2})-[e:FOLLOWS]->(v2:Person)
      RETURN collect(v2.id) AS ids
      NEXT
      RETURN transform(ids, f1 -> size(filter(ids, f2 -> f1 > f2))) AS counts
      """
    Then the execution should be successful
    # Two-level nested lambda: transform + filter (outer and inner both operate on variable list)
    When executing query:
      """
      MATCH (v1:Person{id:2})-[e:FOLLOWS]-{1,2}(v2)
      RETURN collect(v2.id) AS ids
      NEXT
      RETURN filter(transform(ids, x -> x + 100), val -> val > 101) AS filtered_ids
      """
    Then the execution should be successful
    # Three-level nested lambda: transform(filter(reduce))
    # Level 1 (outer): transform ids
    # Level 2 (middle): filter ids based on comparison with outer id
    # Level 3 (inner): reduce the filtered ids
    When executing query:
      """
      MATCH (v:Person{id:2})-[e:FOLLOWS]-{1,2}(v2)
      RETURN collect(v2.id) AS id_list
      NEXT
      RETURN transform(id_list, x -> reduce(filter(id_list, y -> y > x), 0, (sum, val) -> sum + val)) AS three_level_result
      NEXT
      // sort the list
      RETURN reduce(
        three_level_result,
        [],
        (sorted, item) -> filter(sorted, x -> x <= item) || [item] || filter(sorted, x -> x > item)
      ) AS sorted
      """
    Then the result should be, in any order:
      | sorted                                    |
      | LIST [0,4,4,4,13,13,13,13,13,13,25,25,25] |

  Scenario: Invalid lambda function usage
    # The number of lambda parameters passed does not match the expected count
    When executing query:
      """
      LET arr = [1,2,3]
      RETURN transform(arr, size(arr)) as a
      """
    Then an Error should be raised: "[NR002]: Undefined function: `transform(arr, size(arr))`"
    When executing query:
      """
      LET arr = [1,2,3]
      RETURN transform(arr, i -> i + 1, j -> j + 1) as a
      """
    Then an Error should be raised: "[NR002]: Undefined function: `transform(arr)`"
    When executing query:
      """
      LET arr = [1,2,3]
      RETURN filter(arr) as a
      """
    Then an Error should be raised: "[NR002]: Undefined function: `filter(arr)`"
    When executing query:
      """
      LET arr = [1,2,3]
      RETURN reduce(arr, 100, (state, item) -> state + item, i -> i + 1, j -> j + 1) AS a
      """
    Then an Error should be raised: "[NR002]: Undefined function: `reduce(arr, 100)`"
    # Lambda expression cannot contain aggregates or subqueries
    When executing query:
      """
      RETURN transform([1, 2, 3], x -> sum(x)) as a
      """
    Then an Error should be raised: "[NR023]: Lambda expression cannot contain aggregates or subqueries"
    When executing query:
      """
      RETURN transform([1, 2, 3], x -> abs(sum(x))) as a
      """
    Then an Error should be raised: "[NR023]: Lambda expression cannot contain aggregates or subqueries"
    When executing query:
      """
      RETURN transform([1, 2, 3], x -> VALUE { RETURN x LIMIT 1 }) as a
      """
    Then an Error should be raised: "[NR023]: Lambda expression cannot contain aggregates or subqueries"
    When executing query:
      """
      RETURN filter([1, 2, 3], x -> VALUE { RETURN COUNT(*) GROUP BY() }) as a
      """
    Then an Error should be raised: "[NR023]: Lambda expression cannot contain aggregates or subqueries"
    When executing query:
      """
      RETURN transform([1, 2, 3], x -> 100 + VALUE { RETURN COUNT(*) GROUP BY() }) as a
      """
    Then an Error should be raised: "[NR023]: Lambda expression cannot contain aggregates or subqueries"
    When executing query:
      """
      RETURN reduce([1, 2, 3], 0, (state, item) -> state + item + VALUE { RETURN COUNT(*) GROUP BY() }) as a
      """
    Then an Error should be raised: "[NR023]: Lambda expression cannot contain aggregates or subqueries"
