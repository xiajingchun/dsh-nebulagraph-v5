# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: CaseExpr

  Scenario: basic
    When executing query:
      """
      RETURN CASE WHEN 8=7 THEN TRUE ELSE FALSE END AS a
      """
    Then the result should be, in any order:
      | a     |
      | FALSE |
    When executing query:
      """
      RETURN CASE WHEN 8= 7 THEN TRUE ELSE FALSE END AS a
      """
    Then the result should be, in any order:
      | a     |
      | FALSE |
    When executing query:
      """
      RETURN CASE WHEN 8=8 THEN TRUE ELSE FALSE END AS a
      """
    Then the result should be, in any order:
      | a    |
      | TRUE |
    # If an <else clause> is not specified, then `ELSE NULL` is implicit.
    When executing query:
      """
      RETURN CASE WHEN 8=7 THEN TRUE END AS a
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    When executing query:
      """
      RETURN CASE WHEN 8=7 THEN TRUE END AS a
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    When executing query:
      """
      RETURN CASE WHEN 8=8 THEN TRUE WHEN true THEN FALSE END AS a
      """
    Then the result should be, in any order:
      | a    |
      | TRUE |
    When executing query:
      """
      RETURN CASE WHEN NULL=NULL THEN TRUE ELSE FALSE END AS a
      """
    Then the result should be, in any order:
      | a     |
      | FALSE |
    When executing query:
      """
      RETURN CASE WHEN NULL IS NULL THEN TRUE ELSE FALSE END AS a
      """
    Then the result should be, in any order:
      | a    |
      | TRUE |
    When executing query:
      """
      RETURN CASE WHEN 1=1 THEN 1 ELSE 2.5 END AS a
      """
    Then the result should be, in any order:
      | a  |
      | 1M |
    When executing query:
      """
      table t {subtype,p}=("a",-1.8134d),("b",-0.982)
      for re in t
      let water_p = CASE WHEN re.subtype = "a" then abs(re.p) else 0 end,
      other_p = case when re.subtype <> "a" then abs(re.p) else 0 end
      return water_p, other_p
      """
    Then the result should be, in any order:
      | water_p | other_p |
      | 1.8134  | 0.0     |
      | 0.0     | 0.982   |
    When executing query:
      """
      RETURN CASE WHEN 1=1 THEN 1 ELSE LIST [2, 3] END AS a
      """
    Then an Error should be raised: "[NR014]: The then/else operands of case expression should have compatible types, but got: INT32, LIST<INT32>"

  Scenario: case expression vector size crash fix
    # FIX https://github.com/vesoft-inc/nebula-ng/issues/8383
    When executing query:
      """
      FOR ua0 IN RANGE(0, 1)
      RETURN
        CASE
          WHEN (ua0 > 0)
            THEN ua0
          WHEN (ua0 > -ua0) AND (ua0 > 0)
            THEN -ua0
          ELSE ua0 + 1
        END AS ri0
      """
    Then the result should be, in any order:
      | ri0 |
      | 1   |
      | 1   |

  Scenario: case expression short circuit
    When executing query:
      """
      FOR x IN [0, 1]
      RETURN CASE WHEN x <> 0 THEN 1/x ELSE 0 END AS a
      """
    Then the result should be, in any order:
      | a |
      | 0 |
      | 1 |
