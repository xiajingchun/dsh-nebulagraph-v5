# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: OrderByAndPage

  Scenario: Order By
    When executing query:
      """
      ORDER BY 123
      RETURN 456 AS a
      """
    Then the result should be, in any order:
      | a   |
      | 456 |
    When executing query:
      """
      LET a = 1, b = 2
      ORDER BY a + b + 10
      RETURN a, b
      """
    Then the result should be, in any order:
      | a | b |
      | 1 | 2 |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      ORDER BY v.firstName
      RETURN v.firstName as name, v.id as id
      """
    Then the result should be, in any order:
      | name     | id |
      | "Kyle"   | 1  |
      | "Ming"   | 3  |
      | "Sophie" | 4  |
      | "Tim"    | 2  |
    When executing query:
      """
      PARAMETERS $_offset=2, $_limit=2
      USE ldbc
      MATCH (v:Person)
      ORDER BY v.firstName
      RETURN v.firstName as name, v.id as id
      OFFSET $_offset LIMIT $_limit
      """
    Then the result should be, in order:
      | name     | id |
      | "Sophie" | 4  |
      | "Tim"    | 2  |
    When executing query:
      """
      USE ldbc MATCH (v:Person) RETURN v LIMIT 8 ORDER BY v.id
      """
    Then an Error should be raised: "[42N47]: Invalid syntax, linear query should ends with RETURN or FINISH statement"
    When executing query:
      """
      PARAMETERS $_offset="abc", $_limit=2
      USE ldbc
      MATCH (v:Person)
      ORDER BY v.firstName
      RETURN v.firstName as name, v.id as id
      OFFSET $_offset LIMIT $_limit
      """
    Then an Error should be raised: "[NS212]: Invalid type OFFSET expression type: `STRING`, expect `unsigned integer"
    When executing query:
      """
      PARAMETERS $_offset=2, $_limit=3.14
      USE ldbc
      MATCH (v:Person)
      ORDER BY v.firstName
      RETURN v.firstName as name, v.id as id
      OFFSET $_offset LIMIT $_limit
      """
    Then an Error should be raised: "[NS213]: Invalid type LIMIT expression type: `DECIMAL`, expect `unsigned integer`"
    When executing query:
      """
      SESSION SET VALUE $_limit=1
      """
    Then the execution should be successful
    When executing query:
      """
      PARAMETERS $_offset=2
      USE ldbc
      MATCH (v:Person)
      ORDER BY v.firstName
      RETURN v.firstName as name, v.id as id
      OFFSET $_offset LIMIT $_limit
      """
    Then the result should be, in order:
      | name     | id |
      | "Sophie" | 4  |
    When executing query:
      """
      SESSION RESET $_limit
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      LET name = v.firstName
      ORDER BY name DESC, v.id
      RETURN name, v.firstName as nameCopy, v.id as id
      """
    Then the result should be, in any order:
      | name     | nameCopy | id |
      | "Tim"    | "Tim"    | 2  |
      | "Sophie" | "Sophie" | 4  |
      | "Ming"   | "Ming"   | 3  |
      | "Kyle"   | "Kyle"   | 1  |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)-[e:KNOWS]->(v2:Person)
      ORDER BY v.firstName DESC, v2.id ASC
      RETURN v.firstName as name, v.id as id
      """
    Then the result should be, in any order:
      | name   | id |
      | "Tim"  | 2  |
      | "Ming" | 3  |
      | "Kyle" | 1  |
    When executing query:
      """
      ORDER BY
      (((9 * 30) <> 48) AND (58 = ((+90) - (-36)))) ASC
      LET
      var0 = false, var1 = (NOT (NOT ((59 > 8) OR false)))
      RETURN
      ((+((63 * 24) + 31)) / (72 + 15)) AS b
      """
    Then the result should be, in any order:
      | b  |
      | 17 |
    When executing query:
      """
      USE ldbc
      ORDER BY 1
      MATCH (v:Person)
      LET name = v.firstName
      ORDER BY name DESC, v.id
      RETURN name, v.firstName as nameCopy, v.id as id
      """
    Then the result should be, in any order:
      | name     | nameCopy | id |
      | "Tim"    | "Tim"    | 2  |
      | "Sophie" | "Sophie" | 4  |
      | "Ming"   | "Ming"   | 3  |
      | "Kyle"   | "Kyle"   | 1  |
    When executing query:
      """
      USE ldbc
      FILTER WHERE TRUE
      ORDER BY 1
      MATCH (v:Person)
      LET name = v.firstName
      ORDER BY name DESC, v.id
      RETURN name, v.firstName as nameCopy, v.id as id
      """
    Then the result should be, in any order:
      | name     | nameCopy | id |
      | "Tim"    | "Tim"    | 2  |
      | "Sophie" | "Sophie" | 4  |
      | "Ming"   | "Ming"   | 3  |
      | "Kyle"   | "Kyle"   | 1  |
    When executing query:
      """
      FOR ua0 in range(0, 1)
      ORDER BY 92
      RETURN ua0
      """
    Then the result should be, in any order:
      | ua0 |
      | 0   |
      | 1   |
    # Order By Undefined Variable
    When executing query:
      """
      USE ldbc
      MATCH (v1)-[e:KNOWS]->(v2:Person)
      ORDER BY knowsDate
      RETURN e.creationDate AS knowsDate
      """
    Then an Error should be raised: "[42N18]: Invalid syntax, variable `knowsDate` not defined"
    When executing query:
      """
      use ldbc match (v1{id:1})-[e]->() return e ORDER BY e
      """
    Then an Error should be raised: "[22G04]: Values not comparable: invalid operation `ORDER BY EDGE` of `e`"
    When executing query:
      """
      use ldbc match (v) return v ORDER BY v
      """
    Then an Error should be raised: "[22G04]: Values not comparable: invalid operation `ORDER BY NODE` of `v`"
    When executing query:
      """
      FOR i IN [vector<3,float>([1,2,3.8f]), vector<3,float>([1,2,3.8f]), vector<3,float>([2,3,4.8f]), null]
      RETURN i order by i
      """
    Then an Error should be raised: "[22G04]: Values not comparable: invalid operation `ORDER BY VECTOR` of `i`"
    When executing query:
      """
      use ldbc match p=(v1{id:1})-[e]->() return p ORDER BY p
      """
    Then an Error should be raised: "[22G04]: Values not comparable: invalid operation `ORDER BY PATH` of `p`"
    When executing query:
      """
      use ldbc match p=(v1{id:1})-[e]->() return {a: p} AS r ORDER BY r
      """
    Then an Error should be raised: "[22G04]: Values not comparable: invalid operation `ORDER BY RECORD` of `r`"

  Scenario: Limit
    When executing query:
      """
      USE ldbc MATCH (v) SKIP 0 LIMIT 0 RETURN v
      """
    Then the result should be, in any order:
      | v |
    When executing query:
      """
      FOR i IN LIST[1,2,3,4,5] OFFSET 1 RETURN i
      """
    Then the result should be, in any order:
      | i |
      | 2 |
      | 3 |
      | 4 |
      | 5 |
    When executing query:
      """
      FOR i IN LIST[1,2,3,4,5] OFFSET 2 RETURN i
      """
    Then the result should be, in any order:
      | i |
      | 3 |
      | 4 |
      | 5 |
    When executing query:
      """
      FOR i IN LIST[1,2,3,4,5] OFFSET 5 RETURN i
      """
    Then the result should be, in any order:
      | i |
    When executing query:
      """
      FOR i IN LIST[1,2,3,4,5] OFFSET 4 LIMIT 1 RETURN i
      """
    Then the result should be, in any order:
      | i |
      | 5 |
    When executing query:
      """
      FOR i IN LIST[1,2,3,4,5] OFFSET 4 LIMIT 0 RETURN i
      """
    Then the result should be, in any order:
      | i |

  Scenario: ban subquery in ORDERBY clauses
    When executing query:
      """
      USE ldbc {
      LET var7 = VALUE {
      FINISH NEXT
      RETURN 1
      ORDER BY (NOT EXISTS {
      FINISH }
      ) ASC
      }
      FINISH
      }
      """
    Then an Error should be raised: "[NS248]: Semantic error: Invalid order by factor, ORDER BY factor can't be a subquery"
