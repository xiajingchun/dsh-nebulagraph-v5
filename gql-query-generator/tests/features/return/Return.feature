# Copyright (c) 2022 vesoft inc. All rights reserved.
Feature: Return

  Scenario: ReturnData
    When executing query:
      """
      RETURN 1 AS a, -1 AS b, VECTOR<3,float>([1,2,3]) AS c
      """
    Then the result should be, in any order:
      | a | b  | c             |
      | 1 | -1 | VECTOR[1,2,3] |
    When executing query:
      """
      let l=LIST[1,2,3,null] RETURN head(l) AS a, back(l) AS b
      """
    Then the result should be, in any order:
      | a | b    |
      | 1 | NULL |
    When executing query:
      """
      LET a=3, b=0 RETURN a/b AS res
      """
    Then an Error should be raised: "[22012]: Division by zero: `3 / 0`, type: `INT32`, in expression: 3 / 0"
    When executing query:
      """
      FOR i IN LIST[LIST[1,2,3], List[-4,3,-4,5], LIST[3]]
      RETURN i[0] AS i0, i[-1] AS i_1, i[3] AS i3
      """
    Then the result should be, in any order:
      | i0 | i_1 | i3   |
      | 1  | 3   | NULL |
      | -4 | 5   | 5    |
      | 3  | 3   | NULL |
    When executing query:
      """
      RETURN case when true then 1 else null end AS res
      """
    Then the result should be, in any order:
      | res |
      | 1   |
    When executing query:
      """
      RETURN case when true then null else 1 end AS res
      """
    Then the result should be, in any order:
      | res  |
      | NULL |
    When executing query:
      """
      RETURN case when false then 1 else null end AS res
      """
    Then the result should be, in any order:
      | res  |
      | NULL |
    When executing query:
      """
      RETURN case when false then null else 1 end AS res
      """
    Then the result should be, in any order:
      | res |
      | 1   |
    When executing query:
      """
      RETURN case when 1<>1 then 1 else null end AS res
      """
    Then the result should be, in any order:
      | res  |
      | NULL |
    When executing query:
      """
      RETURN case when 1=1 then 1 else null end AS res
      """
    Then the result should be, in any order:
      | res |
      | 1   |
    When executing query:
      """
      FOR cnt IN LIST [3.3,4.4,2.22] RETURN cnt ,cnt + 1 AS cnt2 OFFSET 0 LIMIT 33
      """
    Then the result should be, in any order:
      | cnt   | cnt2  |
      | 3.3M  | 4.3M  |
      | 4.4M  | 5.4M  |
      | 2.22M | 3.22M |
    When executing query:
      """
      FOR cnt IN LIST [3.3,4.4,2.22] RETURN cnt ,cnt + 1 AS cnt2 ORDER BY cnt OFFSET 1
      """
    Then the result should be, in any order:
      | cnt  | cnt2 |
      | 3.3M | 4.3M |
      | 4.4M | 5.4M |
    When executing query:
      """
      FOR cnt IN LIST [3.3,4.4,2.22] RETURN cnt ,cnt + 1 AS cnt2 ORDER BY cnt LIMIT 1
      """
    Then the result should be, in any order:
      | cnt   | cnt2  |
      | 2.22M | 3.22M |
    When executing query:
      """
      FOR cnt IN LIST [3.3,4.4,2.22] RETURN cnt ,cnt + 1 AS cnt2 LIMIT 1
      """
    Then the result should be, in any order:
      | cnt  | cnt2 |
      | 3.3M | 4.3M |
    When executing query:
      """
      FOR cnt IN LIST [3.3,4.4,2.22] RETURN cnt ,cnt + 1 AS cnt2 ORDER BY cnt OFFSET 1 LIMIT 33
      """
    Then the result should be, in any order:
      | cnt  | cnt2 |
      | 3.3M | 4.3M |
      | 4.4M | 5.4M |

  Scenario: Return column name
    When executing query:
      """
      RETURN LIST[1,2,3][2]
      """
    Then the result should be, in any order:
      | LIST[1,2,3][2] |
      | 3.0            |
    When executing query:
      """
      RETURN 2 IN LIST [1,2,3,4]
      """
    Then the result should be, in any order:
      | 2 IN LIST [1,2,3,4] |
      | true                |
    When executing query:
      """
      RETURN COALESCE(1,2)
      """
    Then the result should be, in any order:
      | COALESCE(1,2) |
      | 1             |
    When executing query:
      """
      FOR i IN NULL
      RETURN *
      """
    Then the result should be, in any order:
      | i |
    When executing query:
      """
      USE ldbc MATCH (v:Comment)
      RETURN SUM(v.extent*10) AS a GROUP BY ()
      """
    Then the result should be, in any order:
      | a   |
      | 320 |
    When executing query:
      """
      USE ldbc MATCH (v:Comment)
      FOR i IN NULL
      RETURN v
      """
    Then the result should be, in any order:
      | v |
    When executing query:
      """
      RETURN NULL IS NULL
      """
    Then the result should be, in any order:
      | NULL IS NULL |
      | true         |
    When executing query:
      """
      RETURN "abc"
      """
    Then the result should be, in any order:
      | "abc" |
      | "abc" |
    When executing query:
      """
      RETURN 'abc'
      """
    Then the result should be, in any order:
      | 'abc' |
      | "abc" |
    # test some non-reserved keywords
    When executing query:
      """
      RETURN 1 AS ACYCLIC, 2 AS simple, 3 AS Walk, 4 AS tRail, 5 AS DIFFERENT, 6 AS repeatable
      """
    Then the result should be, in any order:
      | ACYCLIC | simple | Walk | tRail | DIFFERENT | repeatable |
      | 1       | 2      | 3    | 4     | 5         | 6          |

  Scenario: ReturnUndefinedVariable
    When executing query:
      """
      USE ldbc
      MATCH (m)-[e:IS_PART_OF]->(p)
      RETURN not_exist
      """
    Then an Error should be raised: "[42N18]: Invalid syntax, variable `not_exist` not defined"
    When executing query:
      """
      USE ldbc
      MATCH (m)-[e:IS_PART_OF]->(p)
      RETURN not_exist.prop
      """
    Then an Error should be raised: "[42N18]: Invalid syntax, variable `not_exist` not defined"
    When executing query:
      """
      FOR i IN 3 RETURN i
      """
    Then an Error should be raised: "[NS006]: Semantic error, invalid expression type, expect `LIST or SET` but got `INT32` at expression: `3`"
    When executing query:
      """
      RETURN case when 1 then 1 else null end AS res
      """
    Then an Error should be raised: "[NR011]: The when operand of case expression should be type of boolean, but got INT32: CASE WHEN 1 THEN 1 ELSE NULL END"

  Scenario: Return aggregate function
    When executing query:
      """
      USE ldbc MATCH (v) RETURN count(v) AS cnt, sum(v.id) + 1 AS s GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt | s  |
      | 34  | 92 |
    When executing query:
      """
      USE ldbc MATCH (v) RETURN count(v) AS cnt, sum(v) + 1 AS s
      """
    Then an Error should be raised: "[NT204]: Unknown aggregate function `sum(NODE)`"
    When executing query:
      """
      USE ldbc MATCH (v) RETURN count(v) AS cnt GROUP BY () NEXT USE ldbc RETURN cnt ,cnt + 1 AS cnt2
      """
    Then the result should be, in any order:
      | cnt | cnt2 |
      | 34  | 35   |
    When executing query:
      """
      VALUE l LIST<INT> =[1,2,3]
      VALUE i INT = 1
      VALUE l_int LISTAGG<INT>
      SET @l_int = l[1:3]
      SET @l_int += 1
      RETURN l AS ll
      NEXT
      RETURN l[i] AS l_i, @l_int AS l_int, ll[i] AS ll_i
      """
    Then the result should be, in any order:
      | l_i | l_int       | ll_i |
      | 2   | LIST[2,3,1] | 2    |
    When executing query:
      """
      VALUE l LIST<INT> =[1,2,3]
      VALUE i INT = 1
      VALUE l_int LISTAGG<INT>
      SET @l_int = l[1:3]
      SET @l_int += 1 FINISH
      RETURN l[i] AS l_i, @l_int AS l_int
      """
    Then the result should be, in any order:
      | l_i | l_int       |
      | 2   | LIST[2,3,1] |
    When executing query:
      """
      TABLE t {id INT}
      EXPORT 323 INTO t
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {id INT, name STRING}
      EXPORT 323 AS id, "323" AS name INTO t
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {id INT, name STRING}
      EXPORT 323 AS id, "323" AS name INTO t
      FOR i in t
      RETURN i.id AS id, i.name AS name
      """
    Then the result should be, in any order:
      | id  | name  |
      | 323 | "323" |
    When executing query:
      """
      VALUE l LIST<INT> =[1,2,3]
      VALUE i INT = 1
      VALUE l_int LISTAGG<INT>
      SET @l_int = l[1:3]
      SET @l_int += 1
      RETURN l AS ll
      RETURN ll
      """
    Then an Error should be raised: "[42N18]: Invalid syntax, variable `ll` not defined"
    When executing analytic query:
      """
      VALUE l LIST<INT> =[1,2,3]
      VALUE i INT = 1
      VALUE l_int LISTAGG<INT>
      SET @l_int = l[1:3]
      SET @l_int += 1
      RETURN l AS ll
      NEXT
      RETURN l[i] AS l_i, @l_int AS l_int, ll[i] AS ll_i
      """
    Then the result should be, in any order:
      | l_i | l_int       | ll_i |
      | 2   | LIST[2,3,1] | 2    |
    When executing analytic query:
      """
      VALUE l LIST<INT> =[1,2,3]
      VALUE i INT = 1
      VALUE l_int LISTAGG<INT>
      SET @l_int = l[1:3]
      SET @l_int += 1 FINISH
      RETURN l[i] AS l_i, @l_int AS l_int
      """
    Then the result should be, in any order:
      | l_i | l_int       |
      | 2   | LIST[2,3,1] |
    When executing analytic query:
      """
      TABLE t {id INT}
      EXPORT 323 INTO t
      """
    Then the execution should be successful
    When executing analytic query:
      """
      TABLE t {id INT, name STRING}
      EXPORT 323 AS id, "323" AS name INTO t
      """
    Then the execution should be successful
    When executing analytic query:
      """
      TABLE t {id INT, name STRING}
      EXPORT 323 AS id, "323" AS name INTO t
      FOR i in t
      RETURN i.id AS id, i.name AS name
      """
    Then the result should be, in any order:
      | id  | name  |
      | 323 | "323" |
    When executing analytic query:
      """
      VALUE l LIST<INT> =[1,2,3]
      VALUE i INT = 1
      VALUE l_int LISTAGG<INT>
      SET @l_int = l[1:3]
      SET @l_int += 1
      RETURN l AS ll
      RETURN ll
      """
    Then an Error should be raised: "[42N18]: Invalid syntax, variable `ll` not defined"

  Scenario: Return all
    When executing query:
      """
      LET a = 1 RETURN *
      UNION
      LET a = 2 RETURN *
      """
    Then the result should be, in any order:
      | a |
      | 1 |
      | 2 |
    When executing query:
      """
      LET a = 1 RETURN *
      UNION
      LET b = 2 RETURN *
      """
    Then an Error should be raised: "[NS007]: Semantic error, column name `a` vs. `b` mismatched for the linear query of composite query statement: `LET b=2 RETURN *`"
    When executing query:
      """
      USE ldbc MATCH () RETURN *
      """
    Then an Error should be raised: "[NS107]: RETURN * is not allowed when there are no iterated variables in scope"
    When executing query:
      """
      USE ldbc
      MATCH (v:Person{id: 2})-[:KNOWS]->{0,1}()
      RETURN *
      LIMIT 0
      """
    Then the result should be, in any order:
      | v |
    # sort columns by name in return all
    When executing query:
      """
      LET d = 1, c = 2, b = 3, a = 4 RETURN *
      """
    Then the result should be, in any order:
      | a | b | c | d |
      | 4 | 3 | 2 | 1 |
    When executing query:
      """
      FOR i IN LIST[1, 1, 1, 1, 2] RETURN DISTINCT i LIMIT 2
      """
    Then the result should be, in any order:
      | i |
      | 1 |
      | 2 |

  Scenario: Order by
    When executing query:
      """
      FOR i in LIST[7, 1, 2, 3, 4, 5, 7, 6]
      LET j = i
      RETURN i ORDER BY j
      """
    Then the result should be, in any order:
      | i |
      | 1 |
      | 2 |
      | 3 |
      | 4 |
      | 5 |
      | 6 |
      | 7 |
      | 7 |
    When executing query:
      """
      FOR i in LIST[1, 7, 1, 2, 3, 4, 5, 7, 6]
      LET j = i
      RETURN DISTINCT i ORDER BY i LIMIT 6
      """
    Then the result should be, in any order:
      | i |
      | 1 |
      | 2 |
      | 3 |
      | 4 |
      | 5 |
      | 6 |
    When executing query:
      """
      USE ldbc
      MATCH (v)
      LET vid = v.id
      RETURN v.id as id ORDER BY vid DESC LIMIT 4
      """
    Then the result should be, in any order:
      | id |
      | 6  |
      | 5  |
      | 4  |
      | 4  |
    When executing query:
      """
      FOR i IN LIST[6, 5, 4, 3, 2, 1, 1]
      LET b = i + 1
      RETURN DISTINCT b,
      VALUE {
        FOR j IN LIST[1, 1, 2, 3, 4, 5, 6]
        LET c = j + b
        RETURN DISTINCT c as d ORDER BY d LIMIT 1
      } AS val ORDER BY b, val LIMIT 3
      """
    Then the result should be, in any order:
      | b | val |
      | 2 | 3   |
      | 3 | 4   |
      | 4 | 5   |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      RETURN DISTINCT v.browserUsed ORDER BY v.id
      """
    Then an Error should be raised: "[NS248]: Semantic error: Invalid order by factor, for RETURN DISTINCT, ORDER BY can only reference columns in the RETURN statement: `v`"
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)-[]->()
      RETURN DISTINCT v.browserUsed ORDER BY POWER(v.id, 2)
      """
    Then an Error should be raised: "[NS248]: Semantic error: Invalid order by factor, for RETURN DISTINCT, ORDER BY can only reference columns in the RETURN statement: `v`"
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)-[]->()
      RETURN DISTINCT v.id ORDER BY v.id + 1
      """
    Then an Error should be raised: "[NS248]: Semantic error: Invalid order by factor, for RETURN DISTINCT, ORDER BY can only reference columns in the RETURN statement: `v`"
    When executing query:
      """
      FOR x in LIST[0, 1, 2, 3]
      LET y = 2.0
      LET z = y
      RETURN z, x AS y ORDER BY x
      NEXT
      RETURN DISTINCT y ORDER BY y
      """
    Then the result should be, in any order:
      | y |
      | 0 |
      | 1 |
      | 2 |
      | 3 |

  Scenario: Aggregate, Dedup And Orderby
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      RETURN DISTINCT v ORDER BY v.id DESC
      NEXT
      USE ldbc
      RETURN DISTINCT v.id AS id ORDER BY id ASC
      """
    Then the result should be, in any order:
      | id |
      | 1  |
      | 2  |
      | 3  |
      | 4  |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      RETURN DISTINCT v.firstName ORDER BY v.id DESC
      """
    Then an Error should be raised: "[NS248]: Semantic error: Invalid order by factor, for RETURN DISTINCT, ORDER BY can only reference columns in the RETURN statement: `v`"
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      RETURN DISTINCT v.id ORDER BY v.id DESC
      """
    Then an Error should be raised: "[NS248]: Semantic error: Invalid order by factor, for RETURN DISTINCT, ORDER BY can only reference columns in the RETURN statement: `v`"
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      LET name = v.firstName
      RETURN DISTINCT sum(v.id) as x GROUP BY name ORDER BY x + 1
      """
    Then the result should be, in any order:
      | x |
      | 1 |
      | 2 |
      | 3 |
      | 4 |
    When executing query:
      """
      USE ldbc
      MATCH (a:Person), (b:Person)
      RETURN DISTINCT a.id * 2 AS d, count(*) as c ORDER BY c
      """
    Then the result should be, in any order:
      | d | c |
      | 2 | 4 |
      | 4 | 4 |
      | 6 | 4 |
      | 8 | 4 |
    When executing query:
      """
      USE ldbc
      MATCH (a:Person), (b:Person)
      RETURN a.id * 2 as d, count(b.firstName) as c ORDER BY d
      """
    Then the result should be, in any order:
      | d | c |
      | 2 | 4 |
      | 4 | 4 |
      | 6 | 4 |
      | 8 | 4 |
    When executing query:
      """
      USE ldbc
      MATCH (a:Person), (b:Person)
      RETURN a.id * 2 as d, collect(b.firstName) as c ORDER BY a.id
      """
    Then an Error should be raised: "[NS248]: Semantic error: Invalid order by factor, for GROUP BY, ORDER BY can only reference columns in the RETURN statement and GROUP BY clause: `a`"
    When executing query:
      """
      USE ldbc
      MATCH (a:Person), (b:Person)
      RETURN a.id, count(b.firstName) as c ORDER BY a.id
      """
    Then an Error should be raised: "[NS248]: Semantic error: Invalid order by factor, for GROUP BY, ORDER BY can only reference columns in the RETURN statement and GROUP BY clause: `a`"
    When executing query:
      """
      USE ldbc
      MATCH (a:Person), (b:Person)
      RETURN DISTINCT a as d, collect(b.firstName) as c ORDER BY a.id * 2 + 1
      NEXT
      USE ldbc
      RETURN d.id as a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
      | 2 |
      | 3 |
      | 4 |
    When executing query:
      """
      USE ldbc
      MATCH (a:Person)
      LET firstName = a.firstName
      RETURN SUM(a.id) AS t, firstName GROUP BY firstName ORDER BY firstName, t
      """
    Then the result should be, in any order:
      | t | firstName |
      | 1 | "Kyle"    |
      | 3 | "Ming"    |
      | 4 | "Sophie"  |
      | 2 | "Tim"     |
    When executing query:
      """
      USE ldbc
      MATCH (a:Person)
      LET gender = a.gender
      RETURN DISTINCT SUM(a.id) * 2 AS t, gender GROUP BY gender ORDER BY gender, t
      """
    Then the result should be, in any order:
      | t  | gender   |
      | 8  | "female" |
      | 12 | "male"   |
    When executing query:
      """
      USE ldbc
      MATCH (a:Person)
      LET firstName = a.firstName
      RETURN DISTINCT SUM(a.id) AS t GROUP BY firstName ORDER BY firstName, t
      """
    Then an Error should be raised: "[NS248]: Semantic error: Invalid order by factor, for RETURN DISTINCT, ORDER BY can only reference columns in the RETURN statement: `firstName`"
    When executing query:
      """
      USE ldbc
      MATCH (a:Person)
      LET gender = a.gender
      RETURN SUM(a.id) * 2 AS t, gender GROUP BY gender ORDER BY gender, t, VALUE {RETURN 1 LIMIT 1}
      """
    Then an Error should be raised: "[NS248]: Semantic error: Invalid order by factor, ORDER BY factor can't be a subquery"
    When executing query:
      """
      USE ldbc
      MATCH (a:Person)
      LET c = a.id
      LET firstName = a.firstName
      RETURN SUM(a.id) AS t, firstName GROUP BY firstName ORDER BY firstName, t, c
      """
    Then an Error should be raised: "[NS248]: Semantic error: Invalid order by factor, for GROUP BY, ORDER BY can only reference columns in the RETURN statement and GROUP BY clause: `c`"
    When executing query:
      """
      LET x = 1 RETURN count(*) GROUP BY x ORDER BY x
      """
    Then the result should be, in any order:
      | count(*) |
      | 1        |

  Scenario: subquery implict GROUP BY
    When executing query:
      """
      use ldbc
      match (v)
      return count(v), value {return 1 limit 1} as c
      """
    Then the result should be, in any order:
      | count(v) | c |
      | 34       | 1 |
    When executing query:
      """
      use ldbc
      match (v)
      return count(v), exists {return 1 limit 1} as c
      """
    Then the result should be, in any order:
      | count(v) | c    |
      | 34       | true |

  Scenario: Aggregate format Dedup:
    When executing query:
      """
      use ldbc {
          match (v)
          let id = v.id
          return distinct id, count(id) group by id order by id
      }
      """
    Then the result should be, in any order:
      | id | count(id) |
      | 1  | 8         |
      | 2  | 8         |
      | 3  | 8         |
      | 4  | 8         |
      | 5  | 1         |
      | 6  | 1         |
