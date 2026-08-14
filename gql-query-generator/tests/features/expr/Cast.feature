# Copyright (c) 2024 vesoft inc. All rights reserved.
@cast
Feature: Cast Function

  Scenario: Numeric casting
    When executing query:
      """
      RETURN CAST (5e30f as string) AS a
      """
    Then the result should be, in any order:
      | a       |
      | "5e+30" |
    When executing query:
      """
      RETURN CAST (5e50d as string) AS a
      """
    Then the result should be, in any order:
      | a       |
      | "5e+50" |
    When executing query:
      """
      RETURN CAST (5e50d as decimal(128, 20)) AS a
      """
    Then the result should be, in any order:
      | a                                                    |
      | 500000000000000000000000000000000000000000000000000M |
    When executing query:
      """
      RETURN CAST (5e30f as decimal(128, 20)) AS a
      """
    Then the result should be, in any order:
      | a                                |
      | 5000000000000000000000000000000M |
    When executing query:
      """
      RETURN CAST (abs(1) AS INT8) AS a
      """
    Then the result should be, in any order:
      | a   |
      | 1.0 |
    When executing query:
      """
      RETURN CAST (1.3 AS INT8) AS a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      RETURN CAST (1.3 AS INT16) AS a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      RETURN CAST (1.3 AS INT32) AS a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      RETURN CAST (1.3 AS INT64) AS a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      RETURN CAST (1 AS FLOAT32) AS a
      """
    Then the result should be, in any order:
      | a   |
      | 1.0 |
    When executing query:
      """
      RETURN CAST (1 AS FLOAT64) AS a
      """
    Then the result should be, in any order:
      | a   |
      | 1.0 |
    When executing query:
      """
      RETURN CAST (abs(1) AS UINT8) AS a
      """
    Then the result should be, in any order:
      | a   |
      | 1.0 |
    When executing query:
      """
      RETURN CAST (1.3 AS UINT8) AS a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      RETURN CAST (1.3 AS UINT16) AS a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      RETURN CAST (1.3 AS UINT32) AS a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      RETURN CAST (1.3 AS UINT64) AS a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      RETURN CAST (-9223372036854775801 as FLOAT) AS a
      """
    Then the execution should be successful

  Scenario: Boolean casting
    When executing query:
      """
      RETURN CAST (TRUE AS bool) AS a
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      RETURN CAST (False AS bool) AS a
      """
    Then the result should be, in any order:
      | a     |
      | false |
    When executing query:
      """
      RETURN CAST ("True" AS bool) AS a
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      RETURN CAST (CAST (true AS STRING) AS bool) AS a
      """
    Then the result should be, in any order:
      | a    |
      | true |

  Scenario: String casting
    When executing query:
      """
      RETURN CAST ("true" AS bool) AS a
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      RETURN CAST ("1" AS INT8) AS a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      RETURN CAST ("1" AS INT16) AS a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      RETURN CAST ("1" AS INT32) AS a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      RETURN CAST ("1" AS INT64) AS a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      RETURN CAST ("1" AS UINT8) AS a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      RETURN CAST ("1" AS UINT16) AS a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      RETURN CAST ("1" AS UINT32) AS a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      RETURN CAST ("1" AS UINT64) AS a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      RETURN CAST ("1" AS STRING) AS a
      """
    Then the result should be, in any order:
      | a   |
      | "1" |
    When executing query:
      """
      RETURN CAST ("1" AS DOUBLE) AS a
      """
    Then the result should be, in any order:
      | a   |
      | 1.0 |
    When executing query:
      """
      RETURN CAST ("1" AS FLOAT32) AS a
      """
    Then the result should be, in any order:
      | a   |
      | 1.0 |
    When executing query:
      """
      RETURN CAST ("3.40282e038" AS FLOAT32) AS a
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN CAST (CAST (1 AS INT8) AS STRING) AS a
      """
    Then the result should be, in any order:
      | a   |
      | "1" |
    When executing query:
      """
      RETURN CAST (CAST (1 AS INT16) AS STRING) AS a
      """
    Then the result should be, in any order:
      | a   |
      | "1" |
    When executing query:
      """
      RETURN CAST (CAST (1 AS INT32) AS STRING) AS a
      """
    Then the result should be, in any order:
      | a   |
      | "1" |
    When executing query:
      """
      RETURN CAST (CAST (1 AS INT64) AS STRING) AS a
      """
    Then the result should be, in any order:
      | a   |
      | "1" |
    When executing query:
      """
      RETURN CAST (CAST (1 AS UINT8) AS STRING) AS a
      """
    Then the result should be, in any order:
      | a   |
      | "1" |
    When executing query:
      """
      RETURN CAST (CAST (1 AS UINT16) AS STRING) AS a
      """
    Then the result should be, in any order:
      | a   |
      | "1" |
    When executing query:
      """
      RETURN CAST (CAST (1 AS UINT32) AS STRING) AS a
      """
    Then the result should be, in any order:
      | a   |
      | "1" |
    When executing query:
      """
      RETURN CAST (CAST (1 AS UINT64) AS STRING) AS a
      """
    Then the result should be, in any order:
      | a   |
      | "1" |
    When executing query:
      """
      RETURN CAST (CAST (1 AS FLOAT32) AS STRING) AS a
      """
    Then the result should be, in any order:
      | a   |
      | "1" |
    When executing query:
      """
      RETURN CAST (CAST (1 AS FLOAT64) AS STRING) AS a
      """
    Then the result should be, in any order:
      | a   |
      | "1" |
    When executing query:
      """
      RETURN CAST (CAST (1 AS DOUBLE) AS STRING) AS a
      """
    Then the result should be, in any order:
      | a   |
      | "1" |
    When executing query:
      """
      RETURN CAST (1.20 AS STRING) AS a
      """
    Then the result should be, in any order:
      | a      |
      | "1.20" |
    When executing query:
      """
      RETURN CAST (CAST (true AS STRING) AS STRING) AS a
      """
    Then the result should be, in any order:
      | a      |
      | "true" |
    When executing query:
      """
      RETURN CAST (CAST (false AS STRING) AS STRING) AS a
      """
    Then the result should be, in any order:
      | a       |
      | "false" |
    When executing query:
      """
      RETURN CAST (DURATION 'P1D' AS STRING) AS a
      """
    Then the result should be, in any order:
      | a                   |
      | "P1DT0H0M0.000000S" |
    When executing query:
      """
      RETURN CAST (DURATION 'P1Y2M' AS STRING) AS a
      """
    Then the result should be, in any order:
      | a       |
      | "P1Y2M" |

  Scenario: List casting
    When executing query:
      """
      RETURN CAST ([1, 2] AS LIST<FLOAT>) as a
      """
    Then the result should be, in any order:
      | a               |
      | LIST [1.0, 2.0] |
    When executing query:
      """
      RETURN CAST ([1.4, 1.5] AS LIST<INT8>) as a
      """
    Then the result should be, in any order:
      | a           |
      | LIST [1, 2] |
    When executing query:
      """
      RETURN CAST ([[1.4], [1.5]] AS LIST<LIST<INT8>>) as a
      """
    Then the result should be, in any order:
      | a                          |
      | LIST [ LIST [1], LIST [2]] |

  Scenario: Set casting
    When executing query:
      """
      RETURN CAST (SET{1, 2} AS SET<DOUBLE>) as a
      """
    Then the result should be, in any order:
      | a              |
      | SET {1.0, 2.0} |
    When executing query:
      """
      RETURN CAST (SET{1.4, 1.5} AS SET<INT8>) as a
      """
    Then the result should be, in any order:
      | a          |
      | SET {1, 2} |
    When executing query:
      """
      RETURN CAST (SET{SET{1.4}, SET{1.5}} AS SET<SET<INT8>>) as a
      """
    Then the result should be, in any order:
      | a                       |
      | SET { SET {1}, SET {2}} |

  Scenario: Map casting
    When executing query:
      """
      RETURN CAST (Map{1.0:1, 2.0:2} AS MAP<INT8, DOUBLE>) as a
      """
    Then the result should be, in any order:
      | a                  |
      | MAP {1:1.0, 2:2.0} |
    When executing query:
      """
      RETURN CAST (MAP{1.5 : SET {1.4, 1.5}} AS MAP<INT8, SET<INT8>>) as a
      """
    Then the result should be, in any order:
      | a                   |
      | MAP {2 : SET {1,2}} |
    When executing query:
      """
      RETURN CAST (MAP{MAP{1:1, 2:2} : MAP{1.1:"1.1", 2.6:"2.2"}} AS MAP<MAP<DOUBLE, DOUBLE>, MAP<INT8, STRING>>) as a
      """
    Then the result should be, in any order:
      | a                                                  |
      | MAP{MAP{1.0:1.0, 2.0:2.0} : MAP{1:"1.1", 3:"2.2"}} |

  Scenario: Record casting
    When executing query:
      """
      RETURN CAST ({p1: 1, p2: 1.5, p3: "42"} AS RECORD {p1 FLOAT, p2 INT8, p3 INT32}) as a
      """
    Then the result should be, in any order:
      | a                            |
      | RECORD {p1:1.0, p2:2, p3:42} |
    When executing query:
      """
      RETURN CAST ({p: LIST [1.4, 1.5]} AS RECORD {p LIST<INT32>}) as a
      """
    Then the result should be, in any order:
      | a                      |
      | RECORD {p: LIST [1,2]} |

  Scenario: Invalid casting
    When executing query:
      """
      RETURN CAST (abs(1) AS BOOLEAN)
      """
    Then an Error should be raised:"[NR008]: Invalid cast expression: `CAST(abs(1) AS BOOL)`"
    When executing query:
      """
      RETURN CAST (1.3 AS DURATION)
      """
    # Then an Error should be raised:"[NR008]: Invalid cast expression: `CAST(1.3 AS Duration)`, can not cast from `DOUBLE` to `Duration`"
    Then an Error should be raised:"[NT000]: duration does not support directly specifying a certain field"
    When executing query:
      """
      RETURN CAST (-3.0 AS DATE)
      """
    Then an Error should be raised:"[NR008]: Invalid cast expression: `CAST(-3.0 AS DATE)`, can not cast from `DECIMAL` to `DATE`"
    When executing query:
      """
      RETURN CAST (-3.0 AS LOCAL DATETIME)
      """
    Then an Error should be raised:"[NR008]: Invalid cast expression: `CAST(-3.0 AS LOCALDATETIME)`, can not cast from `DECIMAL` to `LOCALDATETIME`"
    When executing query:
      """
      RETURN CAST (-3.0 AS LIST<int>)
      """
    Then an Error should be raised:"[NR008]: Invalid cast expression: `CAST(-3.0 AS LIST<INT64>)`, can not cast from `DECIMAL` to `LIST<INT64>`"
    When executing query:
      """
      RETURN CAST (-3.0 AS LIST<float32>)
      """
    Then an Error should be raised:"[NR008]: Invalid cast expression: `CAST(-3.0 AS LIST<FLOAT>)`, can not cast from `DECIMAL` to `LIST<FLOAT>`"
    When executing query:
      """
      RETURN CAST (-3.0 AS BOOL)
      """
    Then an Error should be raised:"[NR008]: Invalid cast expression: `CAST(-3.0 AS BOOL)`, can not cast from `DECIMAL` to `BOOL`"
    When executing query:
      """
      RETURN CAST (CAST (3 AS INT16) AS BOOL)
      """
    Then an Error should be raised:"[NR008]: Invalid cast expression: `CAST(CAST(3 AS INT16) AS BOOL)`, can not cast from `INT16` to `BOOL`"
    When executing query:
      """
      RETURN CAST (CAST (3.3 AS INT32) AS BOOL)
      """
    Then an Error should be raised:"[NR008]: Invalid cast expression: `CAST(CAST(3.3 AS INT32) AS BOOL)`, can not cast from `INT32` to `BOOL`"
    When executing query:
      """
      RETURN CAST (CAST (3.3 AS INT8) AS BOOL)
      """
    Then an Error should be raised:"[NR008]: Invalid cast expression: `CAST(CAST(3.3 AS INT8) AS BOOL)`, can not cast from `INT8` to `BOOL`"
    When executing query:
      """
      RETURN CAST (CAST (3.3 AS UINT8) AS BOOL)
      """
    Then an Error should be raised:"[NR008]: Invalid cast expression: `CAST(CAST(3.3 AS UINT8) AS BOOL)`, can not cast from `UINT8` to `BOOL`"
    When executing query:
      """
      RETURN CAST (CAST (3.3 AS UINT16) AS BOOL)
      """
    Then an Error should be raised:"[NR008]: Invalid cast expression: `CAST(CAST(3.3 AS UINT16) AS BOOL)`, can not cast from `UINT16` to `BOOL`"
    When executing query:
      """
      RETURN CAST (CAST (3.3 AS UINT32) AS BOOL)
      """
    Then an Error should be raised:"[NR008]: Invalid cast expression: `CAST(CAST(3.3 AS UINT32) AS BOOL)`, can not cast from `UINT32` to `BOOL`"
    When executing query:
      """
      RETURN CAST (CAST (3.3 AS UINT64) AS BOOL)
      """
    Then an Error should be raised:"[NR008]: Invalid cast expression: `CAST(CAST(3.3 AS UINT64) AS BOOL)`, can not cast from `UINT64` to `BOOL`"
    When executing query:
      """
      RETURN CAST (CAST (3.3 AS FLOAT32) AS BOOL)
      """
    Then an Error should be raised:"[NR008]: Invalid cast expression: `CAST(CAST(3.3 AS FLOAT) AS BOOL)`, can not cast from `FLOAT` to `BOOL`"
    When executing query:
      """
      RETURN CAST (CAST (3.3 AS FLOAT64) AS BOOL)
      """
    Then an Error should be raised:"[NR008]: Invalid cast expression: `CAST(CAST(3.3 AS DOUBLE) AS BOOL)`, can not cast from `DOUBLE` to `BOOL`"
    When executing query:
      """
      RETURN CAST (CAST ("truex" AS STRING) AS BOOL)
      """
    Then an Error should be raised:"[22018]: Invalid character value cast from `truex`:`STRING` to `BOOL`, in expression: CAST(\"truex\" AS BOOL)"

  Scenario: Casting errors
    When executing query:
      """
      RETURN CAST (127+1 AS INT8)
      """
    Then an Error should be raised:"[22003]: Numeric value out of range: `128`, type: `INT8`, in expression: CAST(128 AS INT8)"
    When executing query:
      """
      RETURN CAST (-129.0 AS INT8)
      """
    Then an Error should be raised:"[22003]: Numeric value out of range: `-129.0`, type: `INT8`, in expression: CAST(-129.0 AS INT8)"
    When executing query:
      """
      RETURN CAST (-1 AS UINT8)
      """
    Then an Error should be raised:"[22003]: Numeric value out of range: `-1`, type: `UINT8`, in expression: CAST(-1 AS UINT8)"
    When executing query:
      """
      RETURN CAST (256 AS UINT8)
      """
    Then an Error should be raised:"[22003]: Numeric value out of range: `256`, type: `UINT8`, in expression: CAST(256 AS UINT8)"
    When executing query:
      """
      RETURN CAST (32768 AS INT16)
      """
    Then an Error should be raised:"[22003]: Numeric value out of range: `32768`, type: `INT16`, in expression: CAST(32768 AS INT16)"
    When executing query:
      """
      RETURN CAST (-32768.9 AS INT16)
      """
    Then an Error should be raised:"[22003]: Numeric value out of range: `-32768.9`, type: `INT16`, in expression: CAST(-32768.9 AS INT16)"
    When executing query:
      """
      RETURN CAST (-1 AS UINT16)
      """
    Then an Error should be raised:"[22003]: Numeric value out of range: `-1`, type: `UINT16`, in expression: CAST(-1 AS UINT16)"
    When executing query:
      """
      RETURN CAST (65536 AS UINT16)
      """
    Then an Error should be raised:"[22003]: Numeric value out of range: `65536`, type: `UINT16`, in expression: CAST(65536 AS UINT16)"
    When executing query:
      """
      RETURN CAST (2147483648 AS INT32)
      """
    Then an Error should be raised:"[22003]: Numeric value out of range: `2147483648`, type: `INT32`, in expression: CAST(2147483648 AS INT32)"
    When executing query:
      """
      RETURN CAST (-2147483648.9 AS INT32)
      """
    Then an Error should be raised:"[22003]: Numeric value out of range: `-2147483648.9`, type: `INT32`, in expression: CAST(-2147483648.9 AS INT32)"
    When executing query:
      """
      RETURN CAST (-1 AS UINT32)
      """
    Then an Error should be raised:"[22003]: Numeric value out of range: `-1`, type: `UINT32`, in expression: CAST(-1 AS UINT32)"
    When executing query:
      """
      RETURN CAST (4294967295+1 AS UINT32)
      """
    Then an Error should be raised:"[22003]: Numeric value out of range: `4294967296`, type: `UINT32`, in expression: CAST(4294967296 AS UINT32)"
    When executing query:
      """
      RETURN CAST (9223372036854775807+1 AS INT64)
      """
    Then an Error should be raised:"[22003]: Numeric value out of range: `9223372036854775807 + 1`, type: `INT64`, in expression: 9223372036854775807 + 1"
    # When executing query:
    # """
    # RETURN CAST (-9223372036854775808 AS INT64)
    # """
    # Then an Error should be raised:"[22003]: DATA EXCEPTION: NUMERIC VALUE OUT OF RANGE, numeric value out of range: -9223372036854775808"
    When executing query:
      """
      RETURN CAST (18446744073709551615+1 AS UINT64)
      """
    Then an Error should be raised:"[22003]: Numeric value out of range: `18446744073709551616`, type: `UINT64`, in expression: CAST(18446744073709551616 AS UINT64)"
    When executing query:
      """
      RETURN CAST (-1 AS UINT64)
      """
    Then an Error should be raised:"[22003]: Numeric value out of range: `-1`, type: `UINT64`, in expression: CAST(-1 AS UINT64)"
    When executing query:
      """
      LET v = CAST(-129 AS int16) RETURN CAST (v AS UINT8) as _result
      """
    Then an Error should be raised:"[22003]: Numeric value out of range: `-129`, type: `UINT8`, in expression: CAST(-129 AS UINT8)"
    When executing query:
      """
      LET v = CAST(-129 AS int16) RETURN CAST (v AS UINT16) as _result
      """
    Then an Error should be raised:"[22003]: Numeric value out of range: `-129`, type: `UINT16`, in expression: CAST(-129 AS UINT16)"
    When executing query:
      """
      LET v = CAST(-129 AS int16) RETURN CAST (v AS UINT32) as _result
      """
    Then an Error should be raised:"[22003]: Numeric value out of range: `-129`, type: `UINT32`, in expression: CAST(-129 AS UINT32)"
    When executing query:
      """
      LET v = CAST(-129 AS int16) RETURN CAST (v AS UINT) as _result
      """
    Then an Error should be raised:"[22003]: Numeric value out of range: `-129`, type: `UINT64`, in expression: CAST(-129 AS UINT64)"
    When executing query:
      """
      RETURN CAST ("128" AS INT8)
      """
    Then an Error should be raised:"[22018]: Invalid character value cast from `128`:`STRING` to `INT8`, in expression: CAST(\"128\" AS INT8)"
    When executing query:
      """
      RETURN CAST ("-129" AS INT8)
      """
    Then an Error should be raised:"[22018]: Invalid character value cast from `-129`:`STRING` to `INT8`, in expression: CAST(\"-129\" AS INT8)"
    When executing query:
      """
      RETURN CAST ("-1" AS UINT8)
      """
    Then an Error should be raised:"[22018]: Invalid character value cast from `-1`:`STRING` to `UINT8`, in expression: CAST(\"-1\" AS UINT8)"
    When executing query:
      """
      RETURN CAST ("256" AS UINT8)
      """
    Then an Error should be raised:"[22018]: Invalid character value cast from `256`:`STRING` to `UINT8`, in expression: CAST(\"256\" AS UINT8)"
    When executing query:
      """
      RETURN CAST ("32768" AS INT16)
      """
    Then an Error should be raised:"[22018]: Invalid character value cast from `32768`:`STRING` to `INT16`, in expression: CAST(\"32768\" AS INT16)"
    When executing query:
      """
      RETURN CAST ("-32768.9" AS INT16)
      """
    Then an Error should be raised:"[22018]: Invalid character value cast from `-32768.9`:`STRING` to `INT16`, in expression: CAST(\"-32768.9\" AS INT16)"
    When executing query:
      """
      RETURN CAST ("-1" AS UINT16)
      """
    Then an Error should be raised:"[22018]: Invalid character value cast from `-1`:`STRING` to `UINT16`, in expression: CAST(\"-1\" AS UINT16)"
    When executing query:
      """
      RETURN CAST ("65536" AS UINT16)
      """
    Then an Error should be raised:"[22018]: Invalid character value cast from `65536`:`STRING` to `UINT16`, in expression: CAST(\"65536\" AS UINT16)"
    When executing query:
      """
      RETURN CAST ("2147483648" AS INT32)
      """
    Then an Error should be raised:"[22018]: Invalid character value cast from `2147483648`:`STRING` to `INT32`, in expression: CAST(\"2147483648\" AS INT32)"
    When executing query:
      """
      RETURN CAST ("-2147483648.9" AS INT32)
      """
    Then an Error should be raised:"[22018]: Invalid character value cast from `-2147483648.9`:`STRING` to `INT32`, in expression: CAST(\"-2147483648.9\" AS INT32)"
    When executing query:
      """
      RETURN CAST ("-1" AS UINT32)
      """
    Then an Error should be raised:"[22018]: Invalid character value cast from `-1`:`STRING` to `UINT32`, in expression: CAST(\"-1\" AS UINT32)"
    When executing query:
      """
      RETURN CAST ("4294967296" AS UINT32)
      """
    Then an Error should be raised:"[22018]: Invalid character value cast from `4294967296`:`STRING` to `UINT32`, in expression: CAST(\"4294967296\" AS UINT32)"
    When executing query:
      """
      RETURN CAST ([1,2,3] AS VECTOR<3,float>)
      """
    Then an Error should be raised:"[NR008]: Invalid cast expression: `CAST(LIST[1, 2, 3] AS VECTOR<3, FLOAT>)`, can not cast from `LIST<INT32>` to `VECTOR<3, FLOAT>`"
    When executing query:
      """
      RETURN CAST (VECTOR<3,float>([1,2,3]) AS LIST<int>)
      """
    Then an Error should be raised:"[NR008]: Invalid cast expression: `CAST([1.000000, 2.000000, 3.000000] AS LIST<INT64>)`, can not cast from `VECTOR<3, FLOAT>` to `LIST<INT64>`"
    # issue #2844
    # When executing query:
    # """
    # RETURN CAST ("9223372036854775807+1" AS INT64)
    # """
    # Then an Error should be raised:"[22018]: DATA EXCEPTION: INVALID CHARACTER VALUE FOR CAST, Unable to parse specified numeric type value from string: 9223372036854775807+1"
    # When executing query:
    # """
    # RETURN CAST ("-9223372036854775808" AS INT64)
    # """
    # Then an Error should be raised:"[22018]: DATA EXCEPTION: INVALID CHARACTER VALUE FOR CAST, Unable to parse specified numeric type value from string: -9223372036854775808"
    # When executing query:
    # """
    # RETURN CAST ("18446744073709551615+1" AS UINT64)
    # """
    # Then an Error should be raised:"[22018]: DATA EXCEPTION: INVALID CHARACTER VALUE FOR CAST, Unable to parse specified numeric type value from string: 18446744073709551615+1"
    When executing query:
      """
      RETURN CAST ("-3.40283e038" AS FLOAT32)
      """
    Then an Error should be raised:"[22018]: Invalid character value cast from `-3.40283e038`:`STRING` to `FLOAT`, in expression: CAST(\"-3.40283e038\" AS FLOAT)"
    When executing query:
      """
      RETURN CAST ("3.40283e038" AS FLOAT32)
      """
    Then an Error should be raised:"[22018]: Invalid character value cast from `3.40283e038`:`STRING` to `FLOAT`, in expression: CAST(\"3.40283e038\" AS FLOAT)"
    When executing query:
      """
      RETURN CAST ("-1.79779e0308" AS FLOAT64)
      """
    Then an Error should be raised:"[22018]: Invalid character value cast from `-1.79779e0308`:`STRING` to `DOUBLE`, in expression: CAST(\"-1.79779e0308\" AS DOUBLE)"
    When executing query:
      """
      RETURN CAST ("1.79779e0308" AS FLOAT64)
      """
    Then an Error should be raised:"[22018]: Invalid character value cast from `1.79779e0308`:`STRING` to `DOUBLE`, in expression: CAST(\"1.79779e0308\" AS DOUBLE)"
    When executing query:
      """
      RETURN CAST ([1, 255] AS LIST<INT8>)
      """
    Then an Error should be raised:"[22003]: Numeric value out of range: `255`, type: `INT8`, in expression: CAST([1,255] AS LIST<INT8>)"
    When executing query:
      """
      RETURN CAST ([[1.4], [1.5]] AS LIST<INT8>)
      """
    Then an Error should be raised:"[NR008]: Invalid cast expression: `CAST(LIST[LIST[1.4], LIST[1.5]] AS LIST<INT8>)`, can not cast from `LIST<LIST<DECIMAL>>` to `LIST<INT8>`"
    When executing query:
      """
      RETURN CAST ({p1: 1, p2: 128} AS RECORD {p1 INT8, p2 INT8})
      """
    Then an Error should be raised:"[22003]: Numeric value out of range: `128`, type: `INT8`, in expression: CAST({p1:1,p2:128} AS RECORD{p1 INT8, p2 INT8})"
    When executing query:
      """
      RETURN CAST ({p1: 1} AS RECORD {p2 INT8})
      """
    Then an Error should be raised:"[NR008]: Invalid cast expression: `CAST(RECORD{p1: 1} AS RECORD{p2 INT8})`, can not cast from `RECORD{p1 INT32}` to `RECORD{p2 INT8}`"

  Scenario: more casts with strings
    When executing query:
      """
      RETURN CAST ("2147483647" as INT32) as large_int32,
        CAST ("-2147483647" as INT32) as n_large_int32,
        CAST ("9223372036854775807" as INT64) as large_int64,
        CAST ("-9223372036854775807" as int64) as n_large_int64,
        CAST ("18446744073709551615" as UINT64) as large_uint64,
        CAST ("18446744073709551616" as DECIMAL(128, 20)) as large_decimal
      """
    Then the result should be, in any order:
      | large_int32 | n_large_int32 | large_int64         | n_large_int64        | large_uint64          | large_decimal         |
      | 2147483647  | -2147483647   | 9223372036854775807 | -9223372036854775807 | 18446744073709551615u | 18446744073709551616M |
    When executing query:
      """
      RETURN
        CAST ("-1.797693134862315e308" as FLOAT64) as n_large_float64,
        CAST ("-2.225073858507201e-308" as FLOAT64) as n_small_float64,
        CAST ("2.225073858507201e-308" as FLOAT64) as small_float64,
        CAST ("1.797693134862315e308" as FLOAT64) as large_float64
      """
    Then the result should be, in any order:
      | n_large_float64          | n_small_float64          | small_float64           | large_float64           |
      | -1.7976931348623149e+308 | -2.2250738585072009e-308 | 2.2250738585072009e-308 | 1.7976931348623149e+308 |
    # strings -> approximate numeric
    # TODO(Xuntao): https://github.com/vesoft-inc/nebula-ng/issues/4398
    When executing query:
      """
      RETURN CAST ("3.40282347e038" as FLOAT32) as large_float32,
        CAST ("1.17549435e-038" as FLOAT32) as small_float32,
        CAST ("-1.17549435e-038" as FLOAT32) as n_small_float32,
        CAST ("-3.40282347e038" as FLOAT32) as n_large_float32
      """
    Then the execution should be successful

  Scenario: Special value casting - Infinity and NaN to FLOAT/DOUBLE
    When executing query:
      """
      RETURN CAST ("Inf" AS FLOAT32) AS f32_inf,
        CAST ("inf" AS FLOAT64) AS f64_inf,
        CAST ("+Inf" AS FLOAT32) AS f32_plus_inf,
        CAST ("+infinity" AS FLOAT64) AS f64_plus_infinity
      """
    Then the result should be, in any order:
      | f32_inf | f64_inf | f32_plus_inf | f64_plus_infinity |
      | +Inf.0  | +Inf.0  | +Inf.0       | +Inf.0            |
    When executing query:
      """
      RETURN CAST ("-Inf" AS FLOAT32) AS f32_ninf,
        CAST ("-inf" AS FLOAT64) AS f64_ninf,
        CAST ("-Infinity" AS FLOAT32) AS f32_ninfinity,
        CAST ("-infinity" AS FLOAT64) AS f64_ninfinity
      """
    Then the result should be, in any order:
      | f32_ninf | f64_ninf | f32_ninfinity | f64_ninfinity |
      | -Inf.0   | -Inf.0   | -Inf.0        | -Inf.0        |
    When executing query:
      """
      RETURN CAST ("NaN" AS FLOAT32) AS f32_nan,
        CAST ("nan" AS FLOAT64) AS f64_nan,
        CAST ("NAN" AS FLOAT32) AS f32_NAN
      """
    Then the result should be, in any order:
      | f32_nan | f64_nan | f32_NAN |
      | NaN.0   | NaN.0   | NaN.0   |
    # Test with leading/trailing spaces
    When executing query:
      """
      RETURN CAST ("  Inf  " AS FLOAT64) AS space_inf,
        CAST ("  -Inf  " AS FLOAT64) AS space_ninf,
        CAST ("  NaN  " AS FLOAT64) AS space_nan
      """
    Then the result should be, in any order:
      | space_inf | space_ninf | space_nan |
      | +Inf.0    | -Inf.0     | NaN.0     |

  Scenario: Special value casting - Infinity and NaN to DECIMAL
    When executing query:
      """
      RETURN CAST ("Inf" AS DECIMAL) AS inf,
        CAST ("inf" AS DECIMAL(128, 10)) AS inf_with_scale,
        CAST ("+Inf" AS DECIMAL) AS plus_inf,
        CAST ("+infinity" AS DECIMAL) AS plus_infinity
      """
    Then the result should be, in any order:
      | inf    | inf_with_scale | plus_inf | plus_infinity |
      | +Inf.0 | +Inf.0         | +Inf.0   | +Inf.0        |
    When executing query:
      """
      RETURN CAST ("-Inf" AS DECIMAL) AS ninf,
        CAST ("-inf" AS DECIMAL(128, 20)) AS ninf_with_scale,
        CAST ("-Infinity" AS DECIMAL) AS ninfinity,
        CAST ("-infinity" AS DECIMAL) AS ninfinity2
      """
    Then the result should be, in any order:
      | ninf   | ninf_with_scale | ninfinity | ninfinity2 |
      | -Inf.0 | -Inf.0          | -Inf.0    | -Inf.0     |
    When executing query:
      """
      RETURN CAST ("NaN" AS DECIMAL) AS "nan",
        CAST ("nan" AS DECIMAL(128, 10)) AS "nan_with_scale",
        CAST ("NAN" AS DECIMAL) AS "NAN"
      """
    Then the result should be, in any order:
      | nan   | nan_with_scale | NAN   |
      | NaN.0 | NaN.0          | NaN.0 |
    # Test with leading/trailing spaces
    When executing query:
      """
      RETURN CAST ("  Inf  " AS DECIMAL) AS space_inf,
        CAST ("  -Infinity  " AS DECIMAL) AS space_ninf,
        CAST ("  NaN  " AS DECIMAL) AS space_nan
      """
    Then the result should be, in any order:
      | space_inf | space_ninf | space_nan |
      | +Inf.0    | -Inf.0     | NaN.0     |
    # Test case variations (mixed case)
    When executing query:
      """
      RETURN CAST ("INF" AS DECIMAL) AS upper_inf,
        CAST ("iNf" AS DECIMAL) AS mixed_inf,
        CAST ("InFiNiTy" AS DECIMAL) AS mixed_infinity,
        CAST ("NaN" AS DECIMAL) AS mixed_nan
      """
    Then the result should be, in any order:
      | upper_inf | mixed_inf | mixed_infinity | mixed_nan |
      | +Inf.0    | +Inf.0    | +Inf.0         | NaN.0     |

  Scenario: Special value casting - Operations with special values
    # Infinity arithmetic
    When executing query:
      """
      RETURN CAST ("Inf" AS DECIMAL) + 100M AS inf_plus,
        CAST ("-Inf" AS DECIMAL) + 100M AS ninf_plus,
        CAST ("Inf" AS DECIMAL) * -1M AS inf_negate
      """
    Then the result should be, in any order:
      | inf_plus | ninf_plus | inf_negate |
      | +Inf.0   | -Inf.0    | -Inf.0     |
    # NaN arithmetic
    When executing query:
      """
      RETURN CAST ("NaN" AS DECIMAL) + 100M AS nan_plus,
        CAST ("NaN" AS FLOAT64) * 5.0 AS nan_mult
      """
    Then the result should be, in any order:
      | nan_plus | nan_mult |
      | NaN.0    | NaN.0    |
    # String conversion back - verify consistency between DECIMAL and FLOAT
    When executing query:
      """
      RETURN CAST (CAST ("Inf" AS DECIMAL) AS STRING) AS decimal_inf_str,
        CAST (CAST ("Inf" AS FLOAT64) AS STRING) AS float_inf_str,
        CAST (CAST ("-Infinity" AS DECIMAL) AS STRING) AS decimal_ninf_str,
        CAST (CAST ("-Infinity" AS FLOAT64) AS STRING) AS float_ninf_str,
        CAST (CAST ("NaN" AS DECIMAL) AS STRING) AS decimal_nan_str,
        CAST (CAST ("NaN" AS FLOAT64) AS STRING) AS float_nan_str
      """
    Then the result should be, in any order:
      | decimal_inf_str | float_inf_str | decimal_ninf_str | float_ninf_str | decimal_nan_str | float_nan_str |
      | "Infinity"      | "Infinity"    | "-Infinity"      | "-Infinity"    | "NaN"           | "NaN"         |
    # Verify FLOAT32 also produces the same string format
    When executing query:
      """
      RETURN CAST (CAST ("Inf" AS FLOAT32) AS STRING) AS f32_inf,
        CAST (CAST ("-Inf" AS FLOAT32) AS STRING) AS f32_ninf,
        CAST (CAST ("NaN" AS FLOAT32) AS STRING) AS f32_nan
      """
    Then the result should be, in any order:
      | f32_inf    | f32_ninf    | f32_nan |
      | "Infinity" | "-Infinity" | "NaN"   |
