# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: User-defined function

  Scenario: UDF test
    When executing query:
      """
      RETURN _abs()
      """
    Then an Error should be raised: "[NR002]: Undefined function: `_abs()`"
    When executing query:
      """
      SHOW FUNCTION _abs
      """
    Then the result should be, in any order:
      | name | signature | comment |
    When executing query:
      """
      RETURN _abs(1)
      """
    Then an Error should be raised: "[NR002]: Undefined function: `_abs(INT32)`"
    When executing query:
      """
      RETURN _ceil(2.3)
      """
    Then an Error should be raised: "[NR002]: Undefined function: `_ceil(DECIMAL)`"
    When executing query:
      """
      RETURN _sum(1,2,3)
      """
    Then an Error should be raised: "[NR002]: Undefined function: `_sum(INT32, INT32, INT32)`"
    When executing query:
      """
      CREATE FUNCTION _abs(int32) RETURNS int32 EXTERNAL PLUGIN mathUdf
      """
    Then an Error should be raised: "[01G05]: Plugin not found: `mathUdf`"
    When executing query:
      """
      DROP FUNCTION _abs(int32) RETURNS int32 EXTERNAL PLUGIN mathUdf
      """
    Then an Error should be raised: "[01G05]: Plugin not found: `mathUdf`"
    When executing query:
      """
      CREATE FUNCTION _abs(int32) RETURNS int32 EXTERNAL PLUGIN dbms
      """
    Then an Error should be raised: "[NR104]: Invalid plugin type, expect: `FUNCTION`, got: `BUILT-IN`"
    When executing query:
      """
      DROP FUNCTION _abs(int32) RETURNS int32 EXTERNAL PLUGIN dbms
      """
    Then an Error should be raised: "[NR104]: Invalid plugin type, expect: `FUNCTION`, got: `BUILT-IN`"
    When executing query:
      """
      CREATE PLUGIN IF NOT EXISTS algo
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE FUNCTION _abs(int32) RETURNS int32 EXTERNAL PLUGIN algo
      """
    Then an Error should be raised: "[NR104]: Invalid plugin type, expect: `FUNCTION`, got: `PROCEDURE`"
    When executing query:
      """
      DROP FUNCTION _abs(int32) RETURNS int32 EXTERNAL PLUGIN algo
      """
    Then an Error should be raised: "[NR104]: Invalid plugin type, expect: `FUNCTION`, got: `PROCEDURE`"
    When executing query:
      """
      CREATE PLUGIN mathUdf
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE FUNCTION IF NOT EXISTS _abs(int32) RETURNS int32 EXTERNAL PLUGIN mathUdf COMMENT "return absolute value of an int32"
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE FUNCTION _abs(int32) RETURNS int32 EXTERNAL PLUGIN dbms_udf
      """
    Then an Error should be raised: "[01G05]: Plugin not found: `dbms_udf`"
    When executing query:
      """
      RETURN _abs(1)
      """
    Then the result should be, in any order:
      | _abs(1) |
      | 1       |
    When executing query:
      """
      DROP FUNCTION IF EXISTS _abs(int64) RETURNS int32 EXTERNAL PLUGIN mathUdf
      """
    Then the execution should be successful
    When executing query:
      """
      DROP FUNCTION _abs(int64) RETURNS int32 EXTERNAL PLUGIN mathUdf
      """
    Then an Error should be raised: "[NR142]: Drop function failed: The user-defined function `_abs(INT64) -> INT32` not found"
    When executing query:
      """
      CREATE FUNCTION IF NOT EXISTS _abs() RETURNS int64 EXTERNAL PLUGIN mathUdf
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW CPP USER DEFINED FUNCTION _abs
      """
    Then the result should be, in any order:
      | name   | signature              | comment                             |
      | "_abs" | "_abs() -> INT64"      | ""                                  |
      | ""     | "_abs(INT32) -> INT32" | "return absolute value of an int32" |
    When executing query:
      """
      SHOW USER DEFINED FUNCTION _abs VERBOSE
      """
    Then the result should contain:
      | name   | signature              | comment                             | category  | null_behavior |
      | "_abs" | "_abs() -> INT64"      | ""                                  | "CPP UDF" | "CUSTOM"      |
      | ""     | "_abs(INT32) -> INT32" | "return absolute value of an int32" | "CPP UDF" | "CUSTOM"      |
    When executing query:
      """
      RETURN _abs()
      """
    Then the result should be, in any order:
      | _abs() |
      | 0      |
    When executing query:
      """
      DROP FUNCTION IF EXISTS _abs() RETURNS int64 EXTERNAL PLUGIN mathUdf
      """
    Then the execution should be successful
    When executing query:
      """
      DROP FUNCTION IF EXISTS _abs FROM PLUGIN mathUdf
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN _abs(1)
      """
    Then an Error should be raised: "[NR002]: Undefined function: `_abs(INT32)`"
    When executing query:
      """
      CREATE FUNCTION IF NOT EXISTS _ceil(int64) RETURNS int64 EXTERNAL PLUGIN mathUdf
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN _ceil(1.2)
      """
    Then an Error should be raised: "[NR002]: Undefined function: `_ceil(DECIMAL)`"
    When executing query:
      """
      RETURN _ceil(1)
      """
    Then the result should be, in any order:
      | _ceil(1) |
      | 1        |
    When executing query:
      """
      CREATE FUNCTION _ceil(double) RETURNS double EXTERNAL PLUGIN mathUdf
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN _ceil(1.2)
      """
    Then the result should be, in any order:
      | _ceil(1.2) |
      | 2.0        |
    When executing query:
      """
      CREATE FUNCTION _sum(int32...) RETURNS int32 EXTERNAL PLUGIN mathUdf COMMENT "calculate the sum of a list of int32 numbers"
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN _sum(1) AS s
      """
    Then the result should be, in any order:
      | s |
      | 1 |
    When executing query:
      """
      RETURN _sum(1,2,3,4,5) AS s
      """
    Then the result should be, in any order:
      | s  |
      | 15 |
    When executing query:
      """
      RETURN _sum(1,2,3) AS s
      """
    Then the result should be, in any order:
      | s |
      | 6 |
    When executing query:
      """
      RETURN _sum(1,2,3,4) AS s
      """
    Then the result should be, in any order:
      | s  |
      | 10 |
    When executing query:
      """
      CREATE FUNCTION _ceil(double) RETURNS double EXTERNAL PLUGIN mathUdf
      """
    Then an Error should be raised: "[NC114]: Function already exist: _ceil"
    When executing query:
      """
      CREATE FUNCTION IF NOT EXISTS _ceil(double) RETURNS double EXTERNAL PLUGIN mathUdf
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN _ceil(1.2)
      """
    Then the result should be, in any order:
      | _ceil(1.2) |
      | 2.0        |
    When executing query:
      """
      RETURN _sum(1.1,2,3) AS s
      """
    Then an Error should be raised: "[NR002]: Undefined function: `_sum(DECIMAL, INT32, INT32)`"
    When executing query:
      """
      RETURN _sum(1.1,2.2,3.3) AS s
      """
    Then an Error should be raised: "[NR002]: Undefined function: `_sum(DECIMAL, DECIMAL, DECIMAL)`"
    When executing query:
      """
      CREATE FUNCTION _sum(double...) RETURNS int32 EXTERNAL PLUGIN mathUdf
      """
    Then an Error should be raised: "[NR141]: Create function `_sum(DOUBLE...) -> INT32` failed: function not defined"
    When executing query:
      """
      CREATE FUNCTION _sum(decimal...) RETURNS double EXTERNAL PLUGIN mathUdf COMMENT "calculate the sum of a list of decimal numbers"
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW CPP USER DEFINED FUNCTION `_sum`
      """
    Then the result should be, in any order:
      | name   | signature                    | comment                                          |
      | "_sum" | "_sum(DECIMAL...) -> DOUBLE" | "calculate the sum of a list of decimal numbers" |
      | ""     | "_sum(INT32...) -> INT32"    | "calculate the sum of a list of int32 numbers"   |
    When executing query:
      """
      DROP FUNCTION _sum FROM PLUGIN mathUdf
      """
    Then an Error should be raised: "[NR142]: Drop function failed: Dropping multiple functions with the same name is not allowed"
    When executing query:
      """
      RETURN _sum(1.1,2.2,3.3) AS s
      """
    Then the result should be, in any order:
      | s   |
      | 6.6 |
    When executing query:
      """
      RETURN _sum(1.1,2.2,3.3,4.4) AS s
      """
    Then the result should be, in any order:
      | s    |
      | 11.0 |
    When executing query:
      """
      DROP FUNCTION _sum(double...) RETURNS int32 EXTERNAL PLUGIN mathUdf
      """
    Then an Error should be raised: "[NR142]: Drop function failed: The user-defined function `_sum(DOUBLE...) -> INT32` not found"
    When executing query:
      """
      DROP FUNCTION IF EXISTS _sum(double...) RETURNS int32 FROM PLUGIN mathUdf
      """
    Then the execution should be successful
    When executing query:
      """
      DROP FUNCTION _sum(decimal...) RETURNS double EXTERNAL PLUGIN mathUdf
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN _sum(1.1,2.2,3.3) AS s
      """
    Then an Error should be raised: "[NR002]: Undefined function: `_sum(DECIMAL, DECIMAL, DECIMAL)`"
    When executing query:
      """
      RETURN _sum(1,2,3) AS s
      """
    Then the result should be, in any order:
      | s |
      | 6 |
    When executing query:
      """
      DROP FUNCTION _sum(int32...) RETURNS int32 FROM PLUGIN mathUdf
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN _sum(1,2,3) AS s
      """
    Then an Error should be raised: "[NR002]: Undefined function: `_sum(INT32, INT32, INT32)`"
    When executing query:
      """
      DROP FUNCTION IF EXISTS _abs(int32) RETURNS int32 FROM PLUGIN mathUdf
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN _abs(1) AS s
      """
    Then an Error should be raised: "[NR002]: Undefined function: `_abs(INT32)`"
    When executing query:
      """
      DROP FUNCTION _ceil(double) RETURNS double FROM PLUGIN mathUdf
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN _ceil(1.2) AS s
      """
    Then an Error should be raised: "[NR002]: Undefined function: `_ceil(DECIMAL)`"
    When executing query:
      """
      DROP FUNCTION IF EXISTS _ceil(int64) RETURNS int64 FROM PLUGIN mathUdf
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN _ceil(1) AS s
      """
    Then an Error should be raised: "[NR002]: Undefined function: `_ceil(INT32)`"
    When executing query:
      """
      DROP PLUGIN mathUdf
      """
    Then the execution should be successful
    When executing query:
      """
      DROP PLUGIN IF EXISTS mathUdf
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN _abs(1)
      """
    Then an Error should be raised: "[NR002]: Undefined function: `_abs(INT32)`"
    When executing query:
      """
      RETURN _ceil(2.3)
      """
    Then an Error should be raised: "[NR002]: Undefined function: `_ceil(DECIMAL)`"
    When executing query:
      """
      RETURN _sum(1,2,3)
      """
    Then an Error should be raised: "[NR002]: Undefined function: `_sum(INT32, INT32, INT32)`"
    When executing query:
      """
      CREATE FUNCTION _abs(int32) RETURNS int32 EXTERNAL PLUGIN mathUdf
      """
    Then an Error should be raised: "[01G05]: Plugin not found: `mathUdf`"
