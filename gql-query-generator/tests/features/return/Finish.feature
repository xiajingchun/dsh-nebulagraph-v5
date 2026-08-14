# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: Finish

  Scenario: finish
    When executing query:
      """
      USE ldbc {
        MATCH (v) FINISH
        NEXT
        RETURN 1 AS a
      }
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      USE ldbc {
        MATCH (v:Person)
        CALL {
          MATCH (t) WHERE t.id = v.id
          FINISH
        }
        RETURN v.id AS a
      }
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
      MATCH (v) FINISH
      """
    Then the execution should be successful
    When executing query:
      """
      FINISH UNION FINISH
      """
    Then an Error should be raised: "[42N58]: Invalid syntax, when FINISH appears as a primitive result statement, a composite query can contain at most one query primary"
    When executing query:
      """
      USE ldbc MATCH (v:Person WHERE v.id in list [1,2] ) FINISH
      UNION
      USE ldbc MATCH (v:Person WHERE v.id in list [3,4] ) FINISH
      """
    Then an Error should be raised: "[42N58]: Invalid syntax, when FINISH appears as a primitive result statement, a composite query can contain at most one query primary"
    When executing query:
      """
      FINISH EXCEPT FINISH
      """
    Then an Error should be raised: "[42N58]: Invalid syntax, when FINISH appears as a primitive result statement, a composite query can contain at most one query primary"

  Scenario: subquery finish
    When executing query:
      """
      use ldbc {
      MATCH (v)
      FINISH  NEXT  RETURN
      EXISTS {
          FINISH
      } AS c
      LIMIT 1
      }
      """
    Then the result should be, in any order:
      | c    |
      | true |
