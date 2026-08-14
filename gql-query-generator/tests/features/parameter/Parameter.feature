# Copyright (c) 2022 vesoft inc. All rights reserved.
Feature: Parameter

  Scenario: Request Parameters
    When executing query:
      """
      PARAMETERS $i=1
      USE ldbc MATCH (n:Person WHERE n.id = 1)
      RETURN n.browserUsed
      """
    Then the result should be, in any order:
      | n.browserUsed |
      | "Chrome"      |
    When executing query:
      """
      PARAMETERS $x=1,$y=2
      USE ldbc MATCH (n:Person WHERE n.id = 1)
      RETURN n.browserUsed
      """
    Then the result should be, in any order:
      | n.browserUsed |
      | "Chrome"      |
    When executing query:
      """
      $i=1
      USE ldbc MATCH (n:Person WHERE n.id = $i)
      RETURN n.browserUsed
      """
    Then the result should be, in any order:
      | n.browserUsed |
      | "Chrome"      |
    When executing query:
      """
      $x=1,$y=2
      USE ldbc MATCH (n:Person WHERE n.id = $x OR n.id=$y)
      RETURN n.browserUsed
      """
    Then the result should be, in any order:
      | n.browserUsed |
      | "Chrome"      |
      | "IE"          |
    When executing query:
      """
      PARAMETERS $x=1,$y=2
      USE ldbc MATCH (n:Person WHERE n.id = $x OR n.id=$z)
      RETURN n.browserUsed
      """
    Then an Error should be raised: "[NS003]: Semantic error, undefined parameter: `z`"
    When executing query:
      """
      PARAMETERS $l = [1,"x"]
      USE ldbc MATCH (a:Person where a.id in $l)
      RETURN a.id
      """
    Then an Error should be raised: "[NR013]: All elements of list constructor must have compatible types"
    When executing query:
      """
      PARAMETERS $l = [1]
      USE ldbc MATCH (a:Person where a.id in $l)
      RETURN a.id
      """
    Then the result should be, in any order:
      | a.id |
      | 1    |

  Scenario: Config Params
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 1)
          SET_VAR(optimizer_rules = "property_pruner=off") */
      PARAMETERS $x=1,$y=2
      USE ldbc MATCH (n:Person WHERE n.id = 1)
      RETURN n.browserUsed
      """
    Then the result should be, in any order:
      | n.browserUsed |
      | "Chrome"      |
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 1) */
      PARAMETERS $i=1
      USE ldbc MATCH (n:Person WHERE n.id = $i)
      RETURN n.browserUsed
      """
    Then the result should be, in any order:
      | n.browserUsed |
      | "Chrome"      |

  Scenario: Session Parameters
    When executing query:
      """
      SESSION SET VALUE $i = 0, $i = 1
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW PARAMETERS
      """
    Then the result should be, in any order:
      | parameter_name | parameter_value |
      | "i"            | 1               |
    When executing query:
      """
      USE ldbc MATCH (n:Person WHERE n.id = $i)
      RETURN n.browserUsed
      """
    Then the result should be, in any order:
      | n.browserUsed |
      | "Chrome"      |
    When executing query:
      """
      $i=2
      USE ldbc MATCH (n:Person WHERE n.id = $i)
      RETURN n.browserUsed
      """
    Then the result should be, in any order:
      | n.browserUsed |
      | "IE"          |
    When executing query:
      """
      SESSION SET VALUE $j=2
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW PARAMETERS
      """
    Then the result should be, in any order:
      | parameter_name | parameter_value |
      | "i"            | 1               |
      | "j"            | 2               |
    When executing query:
      """
      SESSION SET VALUE $j=LIST [1, 2]
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION SET VALUE $j=RECORD {a:1, b:true, c:"test"}, $j=RECORD {}, $j = 2
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION RESET $i
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW PARAMETER $i
      """
    Then an Error should be raised: "[NS003]: Semantic error, undefined parameter: `i`"
    When executing query:
      """
      SESSION RESET $x
      """
    Then an Error should be raised: "[NS003]: Semantic error, undefined parameter: `x`"
    When executing query:
      """
      SHOW PARAMETER $j
      """
    Then the result should be, in any order:
      | parameter_name | parameter_value |
      | "j"            | 2               |
    When executing query:
      """
      SHOW $j
      """
    Then the result should be, in any order:
      | parameter_name | parameter_value |
      | "j"            | 2               |
    When executing query:
      """
      SHOW PARAMETER $x
      """
    Then an Error should be raised: "[NS003]: Semantic error, undefined parameter: `x`"
    When executing query:
      """
      SESSION RESET ALL PARAMETERS
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW PARAMETERS
      """
    Then the result should be, in any order:
      | parameter_name | parameter_value |
    When executing query:
      """
      SESSION SET VALUE $l = [1,2,"x"]
      """
    Then an Error should be raised: "[NR013]: All elements of list constructor must have compatible types"
    When executing query:
      """
      SESSION SET VALUE $l = [1,2,3]
      """
    Then the execution should be successful

  Scenario: Log slow query bug
    # https://github.com/vesoft-inc/nebula-ng/issues/9784
    And create a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      PARAMETERS $s="asdasfsdfaesadfasdfr"
      USE ldbc {
        VALUE x SumAgg<INT> = 0

        SET @x = 1

        MATCH p = TRAIL (a)-[]-{4}()
        RETURN count(*) + length($s)
      }
      """
    Then the execution should be successful
    And close the current session
