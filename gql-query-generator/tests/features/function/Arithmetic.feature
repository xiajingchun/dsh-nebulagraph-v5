# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: Arithmetic Function

  Scenario: Addition Function
    When executing query:
      """
      RETURN 1 + 2 as a
      """
    Then the result should be, in any order:
      | a |
      | 3 |
    When executing query:
      """
      RETURN 1 + 2.5 as a
      """
    Then the result should be, in any order:
      | a    |
      | 3.5M |
    When executing query:
      """
      RETURN 1 + (-1) as a
      """
    Then the result should be, in any order:
      | a |
      | 0 |
    When executing query:
      """
      RETURN 2.5 + 1.7 as a
      """
    Then the result should be, in any order:
      | a    |
      | 4.2M |

  Scenario: Subtraction Function
    When executing query:
      """
      RETURN 1 - 2 as a
      """
    Then the result should be, in any order:
      | a  |
      | -1 |
    When executing query:
      """
      RETURN 1 - 2.5 as a
      """
    Then the result should be, in any order:
      | a     |
      | -1.5M |
    When executing query:
      """
      RETURN 1 - (-1) as a
      """
    Then the result should be, in any order:
      | a |
      | 2 |
    When executing query:
      """
      RETURN 2.5 - 1.7 as a
      """
    Then the result should be, in any order:
      | a    |
      | 0.8M |

  Scenario: Multiplication Function
    When executing query:
      """
      RETURN 1 * 2 as a
      """
    Then the result should be, in any order:
      | a |
      | 2 |
    When executing query:
      """
      RETURN 1 * 2.5 as a
      """
    Then the result should be, in any order:
      | a    |
      | 2.5M |
    When executing query:
      """
      RETURN 1 * (-1) as a
      """
    Then the result should be, in any order:
      | a  |
      | -1 |
    When executing query:
      """
      RETURN 2.5 * 1.7 as a
      """
    Then the result should be, in any order:
      | a     |
      | 4.25M |

  Scenario: Division Function
    When executing query:
      """
      RETURN 1 / 2 as a
      """
    Then the result should be, in any order:
      | a |
      | 0 |
    When executing query:
      """
      RETURN 1 / 2.5 as a
      """
    Then the result should be, in any order:
      | a    |
      | 0.4M |
    When executing query:
      """
      RETURN 1 / (-1) as a
      """
    Then the result should be, in any order:
      | a  |
      | -1 |
    When executing query:
      """
      RETURN 2.5 / 1.7 as a
      """
    Then the result should be, in any order:
      | a                       |
      | 1.47058823529411764706M |
    When executing query:
      """
      RETURN 1.0F / (2+2) as a
      """
    Then the result should be, in any order:
      | a    |
      | 0.25 |
    When executing query:
      """
      RETURN 1.0F/-0.5 AS a
      """
    Then the result should be, in any order:
      | a    |
      | -2.0 |

  Scenario: Error divide by 0
    # Error division by zero
    When executing query:
      """
      RETURN 1 / 0 as a
      """
    Then an Error should be raised: "[22012]: Division by zero: `1 / 0`, type: `INT32`, in expression: 1 / 0"
    When executing query:
      """
      RETURN 1 / 0.0d as a
      """
    Then the result should be, in any order:
      | a      |
      | +Inf.0 |

  Scenario: float mod
    When executing query:
      """
      RETURN 1 % 0.25d as ret
      """
    Then the result should be, in any order:
      | ret |
      | 0   |
    When executing query:
      """
      RETURN 1 % 0.3d as ret
      """
    Then the result should be, in any order:
      | ret                 |
      | 0.10000000000000003 |

  Scenario: signed and unsigned integer check
    When executing query:
      """
      RETURN CAST(255 AS UINT8) + CAST(255 AS UINT8)
      """
    Then an Error should be raised: "[22003]: Numeric value out of range: `255 + 255`, type: `UINT8`, in expression: 255 + 255"
    When executing query:
      """
      RETURN CAST(127 AS INT8) + CAST(127 AS INT8)
      """
    Then an Error should be raised: "[22003]: Numeric value out of range: `127 + 127`, type: `INT8`, in expression: 127 + 127"
    When executing query:
      """
      RETURN -CAST(255 AS UINT8) AS vid
      """
    Then the result should be, in any order:
      | vid  |
      | -255 |
    # promote uint64 to float
    When executing query:
      """
      RETURN -CAST(65536 AS UINT64) AS vid
      """
    Then the result should be, in any order:
      | vid     |
      | -65536M |
    When executing query:
      """
      RETURN  2147483647 * 2147483647 * 2147483647 * 2147483647 * 2147483647
      """
    Then an Error should be raised: "[22003]: Numeric value out of range: `2147483647 * 2147483647`, type: `INT32`, in expression: 2147483647 * 2147483647 * 2147483647 * 2147483647 * 2147483647"
    # TODO(Xuntao): Fix null-related issues while parsing tck.
    # https://github.com/vesoft-inc/nebula-ng/issues/5331
    # When executing query:
    # """
    # RETURN 1 / 0.0 * 0 AS ret
    # """
    # Then the result should be, in any order:
    # | ret   |
    # | NaN.0 |
    When executing query:
      """
      return 9223372036854775808 as val
      """
    Then the result should be, in any order:
      | val                  |
      | 9223372036854775808M |
    When executing query:
      """
      return -9223372036854775808 as val
      """
    Then the result should be, in any order:
      | val                   |
      | -9223372036854775808M |
    When executing query:
      """
      RETURN -9223372036854775809 as val
      """
    Then the result should be, in any order:
      | val                   |
      | -9223372036854775809M |

  Scenario: HashJoin arithmetic range overflow
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS hj_overflow_type AS {
        NODE player (LABEL player {id INT8 PRIMARY KEY})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS hj_overflow TYPED hj_overflow_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE hj_overflow INSERT (@player{id: 127})
      """
    Then the execution should be successful
    When executing query:
      """
      USE hj_overflow
      MATCH (v1:player)
      MATCH (v2:player)
      WHERE v1.id * v1.id = v2.id
      RETURN v2
      """
    Then an Error should be raised: "[22003]: Numeric value out of range: `127 * 127`, type: `INT8`, in expression: v1.id * v1.id"
    And drop the graph "hj_overflow"
    And drop the graph type "hj_overflow_type"
