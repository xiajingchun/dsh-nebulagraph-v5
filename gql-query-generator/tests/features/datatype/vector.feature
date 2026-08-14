# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: vector datatype

  Scenario: basic vector literal
    When executing query:
      """
      RETURN vector(1,2,3) AS v1, VECTOR<2,float>([1.1,2]) AS v2
      """
    Then the result should be, in any order:
      | v1                     | v2                |
      | VECTOR [1.0, 2.0, 3.0] | VECTOR [1.1, 2.0] |
    When executing query:
      """
      RETURN vector(1,null,2,3)
      """
    Then an Error should be raised: "[42001]: The coordinate of vector can not be NULL near `1,null,2,3`"
    When executing query:
      """
      RETURN vector()
      """
    Then an Error should be raised: "[42001]: syntax error near `)`"
    When executing query:
      """
      RETURN vector(1,2.2,3e54)
      """
    Then an Error should be raised: "[NR021]: Float out of range: 3E54"
    When executing query:
      """
      RETURN vector(1,false,3.3)
      """
    Then an Error should be raised: "[NR022]: Invalid data type input: false"
