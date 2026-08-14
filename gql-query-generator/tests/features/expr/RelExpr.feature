# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: RelExpr

  Scenario: not in
    # FIXME: VariadicView does not support VectorReader<T, Const>
    # When executing query:
    # """
    # LET a = 1 NOT IN LIST [2, 3] RETURN a
    # """
    # Then the result should be, in any order:
    # | a    |
    # | TRUE |
    When executing query:
      """
      LET b=2, c=3 LET a = 1 NOT IN LIST [b, c] RETURN a
      """
    Then the result should be, in any order:
      | a    |
      | TRUE |
    When executing query:
      """
      LET b=1, c=4, d=3 LET a = 1 NOT IN LIST [b, c, d] RETURN a
      """
    Then the result should be, in any order:
      | a     |
      | FALSE |
    When executing query:
      """
      RETURN null not in [null] as a
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    When executing query:
      """
      LET b=2, c=3 LET a = 1 NOT IN SET {b, c} RETURN a
      """
    Then the result should be, in any order:
      | a    |
      | TRUE |
    When executing query:
      """
      LET b=1, c=4, d=3 LET a = 1 NOT IN SET {b, c, d} RETURN a
      """
    Then the result should be, in any order:
      | a     |
      | FALSE |
    When executing query:
      """
      RETURN null not in SET{null} as a
      """
    Then the result should be, in any order:
      | a    |
      | NULL |

  Scenario: in
    When executing query:
      """
      LET b=1, c=3 LET a = 1 IN LIST [b, c] RETURN a
      """
    Then the result should be, in any order:
      | a    |
      | TRUE |
    When executing query:
      """
      LET b=2, c=4, d=3 LET a = 1 IN LIST [b, c, d] RETURN a
      """
    Then the result should be, in any order:
      | a     |
      | FALSE |
    When executing query:
      """
      RETURN null in [1, null] as a
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    When executing query:
      """
      RETURN 1 in [1, null] as a
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      RETURN null in [null] as a
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    When executing query:
      """
      RETURN 1 in [1.0] as a
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      RETURN 1.0 in [1] as a
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      RETURN 1 in Set{1.0} as a
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      RETURN 1.0 in Set{1} as a
      """
    Then the result should be, in any order:
      | a    |
      | true |
