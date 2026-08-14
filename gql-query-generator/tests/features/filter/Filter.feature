# Copyright (c) 2022 vesoft inc. All rights reserved.
Feature: Filter

  Scenario: FilterStatement
    When executing query:
      """
      FILTER true
      RETURN 1.0 AS a
      """
    Then the result should be, in any order:
      | a  |
      | 1M |
    When executing query:
      """
      FILTER false
      RETURN 1.0 AS a
      """
    Then the result should be, in any order:
      | a |
    When executing query:
      """
      FOR i IN LIST[0,10,-3,99.8]
      FILTER i > 9
      RETURN i
      """
    Then the result should be, in any order:
      | i     |
      | 10.0M |
      | 99.8M |
    When executing query:
      """
      FOR i IN SET{0,10,-3,99.8}
      FILTER i > 9
      RETURN i
      """
    Then the result should be, in any order:
      | i     |
      | 10.0M |
      | 99.8M |
    When executing query:
      """
      USE ldbc FILTER false
      MATCH (v:Person{id:100})
      RETURN 1.0 AS a
      """
    Then the result should be, in any order:
      | a |
    When executing query:
      """
      USE ldbc
      LET var0 = 5566
      MATCH (v:Person{id:100})
      RETURN v
      NEXT
      USE ldbc
      FILTER ((NOT ((69 / 39) > (-83))) OR (true AND (NOT (NOT false))))
      return v
      """
    Then the result should be, in any order:
      | v |
