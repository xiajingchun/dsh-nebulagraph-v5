# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: GQL User-defined function

  Scenario: GQL UDF test
    When executing graph analytic query:
      """
      CREATE FUNCTION IF NOT EXISTS _pi() RETURNS float AS {3.1415926} COMMENT "return Pi value"
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      RETURN -_pi()+1 AS res
      """
    Then the result should be, in any order:
      | res         |
      | -2.1415926M |
    When executing graph analytic query:
      """
      CREATE FUNCTION abs(a int, b float) RETURNS float AS {a+b}
      """
    Then an Error should be raised: "[NR141]: Create function `abs` failed: function already exists"
    When executing graph analytic query:
      """
      CREATE FUNCTION foo(a int, b float) RETURNS float AS {a+b+x}
      """
    Then an Error should be raised: "[NR141]: Create function `foo` failed: undefined binding variables: [x]"
    When executing graph analytic query:
      """
      CREATE FUNCTION foo(a int, b float) RETURNS float AS {1 + a}
      """
    Then an Error should be raised: "[NR141]: Create function `foo` failed: unused function parameters: [b]"
    When executing graph analytic query:
      """
      CREATE FUNCTION fi(a int, b float) RETURNS float AS {1 + a + b + @nodeAgg}
      """
    Then an Error should be raised: "[NR141]: Create function `fi` failed: GQL user-defined function cannot contain GlobalAgg expression `@nodeAgg`"
    When executing graph analytic query:
      """
      CREATE FUNCTION fi(a int, b float) RETURNS float AS {1 + a + b + @nodeAgg}
      """
    Then an Error should be raised: "[NR141]: Create function `fi` failed: GQL user-defined function cannot contain GlobalAgg expression `@nodeAgg`"
    When executing graph analytic query:
      """
      CREATE FUNCTION foo(a int, b float) RETURNS float AS {1 + foo(a)}
      """
    Then an Error should be raised: "[NR141]: Create function `foo` failed: the user-defined function `foo` can not be called inside the function definition"
    When executing graph analytic query:
      """
      CREATE FUNCTION foo(a int, b float) RETURNS float AS {1 + _pi(a)}
      """
    Then an Error should be raised: "[NR141]: Create function `foo` failed: the user-defined function `_pi` can not be called inside the function definition"
    When executing graph analytic query:
      """
      CREATE FUNCTION foo(a int, b float) RETURNS float AS {a-b + VALUE { USE ldbc MATCH (m)-[:IS_PART_OF]->(p)
      RETURN count(*) AS cnt GROUP BY () }}
      """
    Then an Error should be raised: "[NR141]: Create function `foo` failed: GQL user-defined function cannot contain Subquery expression `VALUE { USE ldbc MATCH (m)-[:IS_PART_OF]->(p) RETURN count(*) AS cnt GROUP BY  }`"
    When executing graph analytic query:
      """
      CREATE FUNCTION foo(a int, b float) RETURNS bool AS {a+b}
      """
    Then an Error should be raised: "[NR141]: Create function `foo` failed: return type mismatch: expected BOOL, but got FLOAT"
    When executing graph analytic query:
      """
      CREATE FUNCTION foo(a int, b float) RETURNS float AS {a+b}
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      FOR i in [1,_pi(),3,foo(null,1),4,foo(-15,1)]
      FILTER foo(i,3.3) < 7 OR i is null
      RETURN foo(i,3.3) AS res
      """
    Then the result should be, in any order:
      | res        |
      | 4.3M       |
      | 6.4415926M |
      | 6.3M       |
      | NULL       |
      | -10.7M     |
    When executing graph analytic query:
      """
      CREATE FUNCTION IF NOT EXISTS foo(a int) RETURNS float AS {a+b}
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      CREATE FUNCTION foo(a int) RETURNS float AS {a+b}
      """
    Then an Error should be raised: "[NR141]: Create function `foo` failed: function already exists"
    When executing query:
      """
      drop function foo(a int) RETURNS float AS {a+b}
      """
    Then an Error should be raised: "[NR142]: Drop function failed: The user-defined function `foo(a INT64) -> FLOAT { a+b }` not found"
    When executing query:
      """
      drop function IF EXISTS foo(a int) RETURNS float AS {a+b}
      """
    Then the execution should be successful
    When executing query:
      """
      FOR i in [1,_pi(),3,foo(null,1),4,foo(-15,1)]
      FILTER foo(i,3.3) < 7 OR i is null
      RETURN foo(i,3.3) AS res
      """
    Then the result should be, in any order:
      | res        |
      | 4.3M       |
      | 6.4415926M |
      | 6.3M       |
      | NULL       |
      | -10.7M     |
    When executing graph analytic query:
      """
      drop function foo(a int, b float) RETURNS float AS {a+b}
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      show GQL user defined function _pi verbose
      """
    Then the result should be, in any order:
      | name  | signature                      | comment           | category  | null_behavior |
      | "_pi" | "_pi() -> FLOAT { 3.1415926 }" | "return Pi value" | "GQL UDF" | "CUSTOM"      |
    When executing query:
      """
      show user defined function _pi
      """
    Then the result should contain:
      | name  | signature                      | comment           |
      | "_pi" | "_pi() -> FLOAT { 3.1415926 }" | "return Pi value" |
    When executing graph analytic query:
      """
      CREATE FUNCTION IF NOT EXISTS foo(a int, b float) RETURNS float AS {a+b}
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      CREATE FUNCTION bar(a int, b float...) RETURNS float AS {a+b}
      """
    Then an Error should be raised: "[NR141]: Create function `bar` failed: variadic GQL user-defined function is not supported yet"
    When executing graph analytic query:
      """
      CREATE FUNCTION bar(a int, b float) RETURNS float AS {a+foo(b)}
      """
    Then an Error should be raised: "[NR141]: Create function `bar` failed: the user-defined function `foo` can not be called inside the function definition"
    When executing query:
      """
      SESSION SET VALUE $i = 0, $i = 1
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE FUNCTION bar(b float) RETURNS float AS {b+$i}
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE FUNCTION bar(b float) RETURNS float AS {b+1}
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      FOR i in [1,bar(_pi()),3,foo(null,bar(1)),4,foo(-15,1)]
      FILTER foo(i,3.3) < 8 OR i is null
      RETURN foo(bar(i),3.3) AS res
      """
    Then the result should be, in any order:
      | res        |
      | 5.3M       |
      | 8.4415926M |
      | 7.3M       |
      | NULL       |
      | 8.3M       |
      | -9.7M      |
    When executing query:
      """
      VALUE x = foo(bar(2),_pi())
      FOR i in [1,bar(x),3,foo(null,bar(x)),4,foo(-15,x)]
      RETURN foo(bar(i),3.3) AS res
      """
    Then the result should be, in any order:
      | res         |
      | 5.3M        |
      | 11.4415926M |
      | 7.3M        |
      | NULL        |
      | 8.3M        |
      | -4.5584074M |
    When executing query:
      """
      VALUE x = foo(bar(2),_pi())
      USE ldbc MATCH (v:Person where v.id*bar(3) < foo(bar(x),foo(x,1)))-[e {src:cast(foo(bar(1),1.4) AS int)}]->(n)
      FILTER v.id=foo(bar(n.id),1)
      RETURN v.id AS vid, n.id AS nid
      """
    Then the result should be, in any order:
      | vid | nid |
      | 3   | 1   |
    When executing query:
      """
      VALUE x = foo(bar(2),_pi())
      VALUE y = bar(foo(_pi(), 3))
      LET z = foo(foo(bar(y), _pi()), foo(_pi(),x))
      RETURN x,y,z
      """
    Then the result should be, in any order:
      | x          | y          | z           |
      | 6.1415926M | 7.1415926M | 20.5663704M |
    When executing query:
      """
      FOR i in [1,2,3,4]
      RETURN i,foo(-bar(i),_PI()) AS orderFactor
      ORDER BY foo(-bar(i),_pi()) desc
      """
    Then the result should be, in any order:
      | i | orderFactor |
      | 1 | 1.1415926M  |
      | 2 | 0.1415926M  |
      | 3 | -0.8584074M |
      | 4 | -1.8584074M |
    # we need recreate function foo for analyticd bcz its schema if from another cluster
    When executing graph analytic query:
      """
      CREATE FUNCTION IF NOT EXISTS Bar(b float) RETURNS float AS {b+1}
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      CREATE OR REPLACE PROCEDURE foo_proc()  RETURNS (uid INT64, uname STRING, uscore INT64) AS {
      TABLE users TYPED TABLE {id INT64, name STRING} = (1, 'Alice'), (2, 'Bob')
      FOR u IN users RETURN u.id AS uid, u.name AS uname, foo(bar(u.id), _PI()+1) AS uscore ORDER BY uscore DESC
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      CALL foo_proc() RETURN *
      """
    Then the result should be, in any order:
      | uid | uname   | uscore |
      | 2   | "Bob"   | 7      |
      | 1   | "Alice" | 6      |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE active_set :: ACTIVE_SET
        VALUE ids ListAgg<INT64>

        SET active_set = [bar(1)]
        MATCH (s@Place) where s in active_set
        PER NODE(s) {
          SET @ids += s.id
        }
        RETURN @ids
      }
      """
    Then an Error should be raised: "[NR027]: Node with element id `2` does not exist"
    When executing query:
      """
      USE ldbc MATCH (v:Person)
      CALL {
       USE ldbc MATCH (v)->(m) FILTER m.id>foo(bar(-1),_PI()) RETURN m
      }
      RETURN distinct v.id as vid, m.id as mid
      """
    Then the result should be, in any order:
      | vid | mid |
      | 2   | 4   |
    When executing graph analytic query:
      """
      CREATE FUNCTION IF NOT EXISTS avg_sum(b float) RETURNS float AS {avg(b)+sum(abs(b))}
      """
    Then the execution should be successful
    When executing query:
      """
      FOR pair IN [[1,2],[1,3],[1,null],[2,3],[3,null],[3,null],[4,2]]
      RETURN pair[0] AS a, pair[1] AS b NEXT
      RETURN a, avg_sum(b) as avg_sum group by a
      """
    Then the result should be, in any order:
      | a | avg_sum |
      | 1 | 7.5M    |
      | 2 | 6.0M    |
      | 3 | null    |
      | 4 | 4.0M    |
    When executing graph analytic query:
      """
      CREATE FUNCTION IF NOT EXISTS custom_reduce_edge_meas(edge_name LIST<STRING>, tpnd_name LIST<STRING>,
               tpnd_Q_meas LIST<INT64>) RETURNS LIST<INT64> AS {
                         reduce(
                             edge_name,
                             [],
                             (state, n) -> state || reduce(
                                 tpnd_name,
                                 {l: [], idx: 0, tn: substring(n, CAST(indexesof(n, ".\\")[-1] AS INT32),
               CAST(indexesof(n, "_\\")[-1] AS INT32))},
                                 (si, ii) -> {
                                     l: si.l || [CASE WHEN si.tn = ii THEN tpnd_Q_meas[si.idx] ELSE 0 END],
                                     idx: si.idx + 1,
                                     tn: si.tn
                                 }
                             ).l
                         )
                     }
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN custom_reduce_edge_meas(["edge1","edge2","edge3"],["tpnd1","tpnd2"], [1,2,3,4,5,6,7,8]) AS edge_meas
      """
    Then the result should be, in any order:
      | edge_meas         |
      | LIST[0,0,0,0,0,0] |
    When executing query:
      """
      drop function bar
      """
    Then the execution should be successful
    When executing query:
      """
      drop function foo
      """
    Then the execution should be successful
    When executing query:
      """
      drop function IF EXISTS _pi
      """
    Then the execution should be successful
    When executing query:
      """
      drop function IF EXISTS custom_reduce_edge_meas
      """
    Then the execution should be successful
    When executing query:
      """
      show GQL user defined functions
      """
    Then the result should be, in any order:
      | name      | signature                                          | comment |
      | "avg_sum" | "avg_sum(b FLOAT) -> FLOAT { avg(b)+sum(abs(b)) }" | ""      |
    When executing query:
      """
      show user defined functions verbose
      """
    Then the result should contain:
      | name      | signature                                          | comment | category  | null_behavior |
      | "avg_sum" | "avg_sum(b FLOAT) -> FLOAT { avg(b)+sum(abs(b)) }" | ""      | "GQL UDF" | "CUSTOM"      |
