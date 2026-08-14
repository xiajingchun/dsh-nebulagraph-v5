# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: Variadic Function

  Scenario: fmt
    When executing query:
      """
      RETURN fmt('hello %s', 'world') as a
      """
    Then the result should be, in any order:
      | a             |
      | "hello world" |
    When executing query:
      """
      RETURN fmt("He%s,%s%s", "llo","Ne","bula") AS log_strs
      """
    Then the result should be, in any order:
      | log_strs       |
      | "Hello,Nebula" |
    When executing query:
      """
      RETURN fmt("12%d,%d5%d,%d%d", 3,4,6,78,9) AS log_ints
      """
    Then the result should be, in any order:
      | log_ints      |
      | "123,456,789" |
    When executing query:
      """
      RETURN fmt("12%f,%f5%f,%f%f", 3.3f,4.3f,6.8f,78f,9f) AS log_floats
      """
    Then the result should be, in any order:
      | log_floats                                       |
      | "123.300000,4.30000056.800000,78.0000009.000000" |
    When executing query:
      """
      RETURN fmt("a:%b, b:%b", true, false) AS log_bools
      """
    Then the result should be, in any order:
      | log_bools         |
      | "a:true, b:false" |
    When executing query:
      """
      RETURN fmt(fmt(fmt("12%d%s,%d5%d%b,%d%d%b", 3,4,6,78,9),"xyz"),false,true) AS log_mixed
      """
    Then the result should be, in any order:
      | log_mixed                 |
      | "123xyz,456false,789true" |
    When executing query:
      """
      RETURN fmt("a:%b, b:%b") AS log_void
      """
    Then an Error should be raised: "[NR002]: Undefined function: `fmt(STRING)`"
    When executing query:
      """
      RETURN fmt() AS log_void
      """
    Then an Error should be raised: "[NR002]: Undefined function: `fmt()`"
    When executing query:
      """
      RETURN fmt("a:%b, b:%b","") AS log_mismatch
      """
    Then an Error should be raised: "[NR003]: Invalid function argument: The number of placeholders `%s` does not match the number of arguments: 0 vs 1, in expression: fmt(\"a:%b, b:%b\", \"\")"
    When executing query:
      """
      RETURN fmt("a:%b, b:%b","","a") AS log_mismatch
      """
    Then an Error should be raised: "[NR003]: Invalid function argument: The number of placeholders `%s` does not match the number of arguments: 0 vs 2, in expression: fmt(\"a:%b, b:%b\", \"\", \"a\")"
    When executing query:
      """
      RETURN fmt("a:%b, b:%b",3) AS log_mismatch
      """
    Then an Error should be raised: "[NR003]: Invalid function argument: The number of placeholders `%d` does not match the number of arguments: 0 vs 1, in expression: fmt(\"a:%b, b:%b\", 3)"

  Scenario: null case in fmt
    When executing query:
      """
      use ldbc
      match (v@Person)-[e]->{0,1}(v2)
      return fmt('%s-%s', type(e[0]), type(e[1])) as t
      """
    Then the result should be, in any order:
      | t                      |
      | "null-null"            |
      | "FOLLOWS-null"         |
      | "FOLLOWS-null"         |
      | "KNOWS-null"           |
      | "LIKES_1-null"         |
      | "HAS_INTEREST-null"    |
      | "LIKES_2-null"         |
      | "WORK_AT-null"         |
      | "STUDY_AT-null"        |
      | "IS_LOCATED_IN_1-null" |
      | "null-null"            |
      | "FOLLOWS-null"         |
      | "null-null"            |
      | "FOLLOWS-null"         |
      | "KNOWS-null"           |
      | "LIKES_1-null"         |
      | "HAS_INTEREST-null"    |
      | "LIKES_2-null"         |
      | "WORK_AT-null"         |
      | "STUDY_AT-null"        |
      | "IS_LOCATED_IN_1-null" |
      | "null-null"            |
      | "KNOWS-null"           |
      | "FOLLOWS-null"         |
      | "LIKES_1-null"         |
      | "HAS_INTEREST-null"    |
      | "LIKES_2-null"         |
      | "WORK_AT-null"         |
      | "STUDY_AT-null"        |
      | "IS_LOCATED_IN_1-null" |
