# Copyright (c) 2024 vesoft inc. All rights reserved.
@dec
Feature: decimal datatype

  Scenario: basic decimal
    When executing query:
      """
      RETURN 1m AS val, 1f AS f32, 1d AS f64
      """
    Then the result should be, in any order:
      | val | f32 | f64 |
      | 1M  | 1.0 | 1.0 |
    When executing query:
      """
      RETURN 1.76E257M AS val
      """
    Then an Error should be raised: "[NR020]: Decimal out of range: required precision 256, scale 128 but got 1.76E257"
    When executing query:
      """
      RETURN 1.76E999 AS val
      """
    Then the result should be, in any order:
      | val    |
      | +Inf.0 |
    When executing query:
      """
      RETURN 1 AS v NEXT RETURN v * 1M AS val
      """
    Then the result should be, in any order:
      | val |
      | 1M  |
    When executing query:
      """
      LET _list = [0.2,1.22,980]
      RETURN REDUCE(_list,100,(x,y) -> x*y ) AS a
      """
    Then the result should be, in any order:
      | a          |
      | 23912.000M |
    When executing query:
      """
      RETURN CAST(0.00 AS DOUBLE) as a
      """
    Then the result should be, in any order:
      | a   |
      | 0.0 |
    # range check
    When executing query:
      """
      RETURN 0.7E256M AS val
      """
    Then the result should be, in any order:
      | val                                                                                                                                                                                                                                                               |
      | 7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000M |
    When executing query:
      """
      RETURN 0.7E257M
      """
    Then an Error should be raised: "[NR020]: Decimal out of range: required precision 256, scale 128 but got 0.7E257"
    When executing query:
      """
      RETURN 1E-128M AS val
      """
    Then the result should be, in any order:
      | val                                                                                                                                 |
      | 0.00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001M |
    When executing query:
      """
      RETURN 1E-129M
      """
    Then an Error should be raised: "[NR020]: Decimal out of range: required precision 256, scale 128 but got 1E-129"

  Scenario: decimal comparison
    When executing query:
      """
      RETURN CAST(1 as int8) < 2M as ret
      """
    Then the result should be, in any order:
      | ret  |
      | true |
    When executing query:
      """
      RETURN CAST(1 as int16) < 2M as ret
      """
    Then the result should be, in any order:
      | ret  |
      | true |
    When executing query:
      """
      RETURN CAST(1 as int32) < 2M as ret
      """
    Then the result should be, in any order:
      | ret  |
      | true |
    When executing query:
      """
      RETURN CAST(1 as int64) < 2M as ret
      """
    Then the result should be, in any order:
      | ret  |
      | true |
    When executing query:
      """
      RETURN CAST(1 as uint8) < 2M as ret
      """
    Then the result should be, in any order:
      | ret  |
      | true |
    When executing query:
      """
      RETURN CAST(1 as uint16) < 2M as ret
      """
    Then the result should be, in any order:
      | ret  |
      | true |
    When executing query:
      """
      RETURN CAST(1 as uint32) < 2M as ret
      """
    Then the result should be, in any order:
      | ret  |
      | true |
    When executing query:
      """
      RETURN CAST(1 as uint64) < 2M as ret
      """
    Then the result should be, in any order:
      | ret  |
      | true |
    When executing query:
      """
      RETURN CAST(1 as float) < 2M as ret
      """
    Then the result should be, in any order:
      | ret  |
      | true |
    When executing query:
      """
      RETURN CAST(1 as double) < 2M as ret
      """
    Then the result should be, in any order:
      | ret  |
      | true |
    When executing query:
      """
      RETURN 1M < 2M as ret
      """
    Then the result should be, in any order:
      | ret  |
      | true |
    When executing query:
      """
      LET lst = [9223372036854775807,9123372036854775807]
      RETURN 9223372036854775807 NOT IN lst AS r1,
            -9223372036854775808 NOT IN lst AS r2
      """
    Then the result should be, in any order:
      | r1    | r2   |
      | false | true |
    When executing query:
      """
      LET _list = RANGE(1, 6) RETURN REDUCE(_list, 100.09, (state,item)->item < 100) AS a
      """
    Then an Error should be raised: "[NR006]: Resolve function failed: `reduce(_list, 100.09, (state, item) -> item < 100)`"
    When executing query:
      """
      LET _list = RANGE(1, 6) RETURN REDUCE(_list, 100.09, (state,item)-> state + item ) AS a
      """
    Then the result should be, in any order:
      | a       |
      | 121.09M |

  Scenario: cast from decimal
    When executing query:
      """
      RETURN CAST(3.1415926M as double) as val
      """
    Then the result should be, in any order:
      | val       |
      | 3.1415926 |
    When executing query:
      """
      RETURN CAST(3.1415926M as float) as val
      """
    Then the result should be, in any order:
      | val        |
      | 3.1415926f |
    When executing query:
      """
      RETURN CAST(3.1415926M as string) as val
      """
    Then the result should be, in any order:
      | val         |
      | "3.1415926" |
    When executing query:
      """
      RETURN CAST (2147483647M as INT32) AS val
      """
    Then the result should be, in any order:
      | val        |
      | 2147483647 |
    When executing query:
      """
      RETURN CAST (2147483647M as INT16) AS val
      """
    Then an Error should be raised: "[22003]: Numeric value out of range: `2147483647`, type: `INT16`, in expression: CAST(2147483647 AS INT16)"
    When executing query:
      """
      RETURN CAST(3.1415926M as int8) as val
      """
    Then the result should be, in any order:
      | val |
      | 3   |
    When executing query:
      """
      RETURN CAST(3.5415926M as int8) as val
      """
    Then the result should be, in any order:
      | val |
      | 4   |
    When executing query:
      """
      RETURN CAST(3.1415926M as uint8) as val
      """
    Then the result should be, in any order:
      | val |
      | 3   |
    When executing query:
      """
      RETURN CAST(3.1415926M as uint16) as val
      """
    Then the result should be, in any order:
      | val |
      | 3   |
    When executing query:
      """
      RETURN CAST(3.1415926M as uint32) as val
      """
    Then the result should be, in any order:
      | val |
      | 3   |

  Scenario: cast to decimal
    When executing query:
      """
      RETURN CAST(3.1415926d as DECIMAL(128, 20)) as dval
      """
    Then the result should be, in any order:
      | dval                    |
      | 3.14159260000000000000M |
    When executing query:
      """
      RETURN CAST(3.1415926f as DECIMAL(128, 20)) as dval
      """
    Then the result should be, in any order:
      | dval       |
      | 3.1415925M |
    When executing query:
      """
      RETURN CAST("3.1415926" as DECIMAL(128, 20)) as dval
      """
    Then the result should be, in any order:
      | dval       |
      | 3.1415926M |
    When executing query:
      """
      RETURN CAST(2147483647 as DECIMAL(128, 20)) as dval
      """
    Then the result should be, in any order:
      | dval        |
      | 2147483647M |
    When executing query:
      """
      return cast(2147483648 as decimal(128, 20)) as dval
      """
    Then the result should be, in any order:
      | dval        |
      | 2147483648M |
    When executing query:
      """
      return cast(9223372036854775807 as decimal(128, 20)) as dval
      """
    Then the result should be, in any order:
      | dval                 |
      | 9223372036854775807M |
    When executing query:
      """
      return cast(18446744073709551615 as decimal(128, 20)) as dval
      """
    Then the result should be, in any order:
      | dval                  |
      | 18446744073709551615M |
    When executing query:
      """
      return cast(18446744073709551615 as decimal(128, 20)) as dval
      """
    Then the result should be, in any order:
      | dval                  |
      | 18446744073709551615M |
    When executing query:
      """
      RETURN CAST(CAST(1 as int8) as decimal(128, 20)) as dval
      """
    Then the result should be, in any order:
      | dval |
      | 1M   |
    When executing query:
      """
      RETURN CAST(CAST(1 as int16) as decimal(128, 20)) as dval
      """
    Then the result should be, in any order:
      | dval |
      | 1M   |
    When executing query:
      """
      RETURN CAST(CAST(1 as uint8) as decimal(128, 20)) as dval
      """
    Then the result should be, in any order:
      | dval |
      | 1M   |
    When executing query:
      """
      RETURN CAST(CAST(1 as uint32) as decimal(128, 20)) as dval
      """
    Then the result should be, in any order:
      | dval |
      | 1M   |
    When executing query:
      """
      RETURN CAST(CAST(1 as uint32) as decimal(128, 20)) as dval
      """
    Then the result should be, in any order:
      | dval |
      | 1M   |

  Scenario: decimal datatype tests
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS gt_illegal AS {
        NODE TYPE N1 (LABEL N1 {id INT PRIMARY KEY, dval DECIMAL(257)})
      }
      """
    Then an Error should be raised: "[NR024]: Invalid decimal type: precision out of range 257, should be within (0, 256]"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS gt_illegal AS {
        NODE TYPE N1 (LABEL N1 {id INT PRIMARY KEY, dval DECIMAL(256, 257)})
      }
      """
    Then an Error should be raised: "[NR024]: Invalid decimal type: scale out of range 257, should be within range (0, 128]"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS gt_illegal AS {
        NODE TYPE N1 (LABEL N1 {id INT PRIMARY KEY, dval DECIMAL(3, 1) DEFAULT 333.33M })
      }
      """
    Then an Error should be raised: "[NR020]: Decimal out of range: required precision 3, scale 1 but got 333.33"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS gt_decimal AS {
        NODE TYPE N1 (LABEL N1 {id INT PRIMARY KEY, dval DECIMAL(128, 22)}),
        NODE TYPE N2 (LABEL N2 {id INT PRIMARY KEY, fval FLOAT, lfval DOUBLE, ival INT64, dval DECIMAL(128, 20) }),
        NODE TYPE N3 (LABEL N3 {id INT PRIMARY KEY, dval DECIMAL(128, 20) }),
        NODE TYPE N4 (LABEL N4 {id INT PRIMARY KEY, dval DECIMAL(3, 1)}),
        NODE TYPE N5 (LABEL N5 {id INT PRIMARY KEY, dval DECIMAL(3, 1)}),
        EDGE TYPE E1 (N1)-[LABEL E1 {dval DECIMAL(128, 20)}]->(N1)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS g_decimal TYPED gt_decimal
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW CREATE GRAPH g_decimal
      """
    Then the result should be, in any order:
      | graph_name  | create_graph_statement                                      |
      | "g_decimal" | "CREATE GRAPH IF NOT EXISTS `g_decimal` TYPED `gt_decimal`" |
    When executing query:
      """
      SHOW CREATE GRAPH TYPE gt_decimal
      """
    Then the result should be, in any order:
      | graph_type_name | create_graph_type_statement                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
      | "gt_decimal"    | "CREATE GRAPH TYPE IF NOT EXISTS `gt_decimal` AS {\n  NODE TYPE `N1` (LABEL `N1`{`id` INT64 NOT NULL, `dval` DECIMAL(128, 22) DEFAULT NULL, PRIMARY KEY (`id`)}),\n  NODE TYPE `N2` (LABEL `N2`{`id` INT64 NOT NULL, `fval` FLOAT DEFAULT NULL, `lfval` DOUBLE DEFAULT NULL, `ival` INT64 DEFAULT NULL, `dval` DECIMAL(128, 20) DEFAULT NULL, PRIMARY KEY (`id`)}),\n  NODE TYPE `N3` (LABEL `N3`{`id` INT64 NOT NULL, `dval` DECIMAL(128, 20) DEFAULT NULL, PRIMARY KEY (`id`)}),\n  NODE TYPE `N4` (LABEL `N4`{`id` INT64 NOT NULL, `dval` DECIMAL(3, 1) DEFAULT NULL, PRIMARY KEY (`id`)}),\n  NODE TYPE `N5` (LABEL `N5`{`id` INT64 NOT NULL, `dval` DECIMAL(3, 1) DEFAULT NULL, PRIMARY KEY (`id`)}),\n  EDGE TYPE `E1` (`N1`)-[LABEL `E1`{`dval` DECIMAL(128, 20) DEFAULT NULL}]->(`N1`)\n}" |
    When executing query:
      """
      USE g_decimal INSERT (@N1{id: 1, dval: 3.1415926535897932384626M}), (@N1{id: 2, dval: 214748364721474836472147483647M}), (@N1{id: 3, dval: null})
      """
    Then the execution should be successful
    When executing query:
      """
      USE g_decimal
      MATCH (a@N1{id: 1}), (b@N1{id: 2})
      INSERT (a)-[@E1{dval: 556655665566.556655665566M}]->(b), (b)-[@E1{dval: 1234567890.0123456789M}]->(a)
      """
    Then the execution should be successful
    When executing query:
      """
      USE g_decimal MATCH (v:N1) RETURN v.dval as dval
      """
    Then the result should be, in any order:
      | dval                            |
      | 214748364721474836472147483647M |
      | 3.141592653589793238462600M     |
      | null                            |
    When executing query:
      """
      USE g_decimal MATCH (v:N1) RETURN -v.dval as dval
      """
    Then the result should be, in any order:
      | dval                             |
      | -214748364721474836472147483647M |
      | -3.141592653589793238462600M     |
      | null                             |
    When executing query:
      """
      USE g_decimal MATCH (v:N1) RETURN v.dval * v.dval AS dval
      """
    Then the result should be, in any order:
      | dval                                                         |
      | 9.869604401089358618834218414691801348011598760000M          |
      | 46116860150547578119648347022331959902987260098194132420609M |
      | null                                                         |
    When executing query:
      """
      USE g_decimal MATCH ()-[e]->() RETURN e.dval as dval
      """
    Then the result should be, in any order:
      | dval                       |
      | 1234567890.012345678900M   |
      | 556655665566.556655665566M |
    When executing query:
      """
      USE g_decimal MATCH (v) RETURN v.dval + v.dval as dval
      """
    Then the result should be, in any order:
      | dval                            |
      | 429496729442949672944294967294M |
      | 6.283185307179586476925200M     |
      | null                            |
    When executing query:
      """
      USE g_decimal MATCH (v:N1) RETURN v.dval + 1M as dval
      """
    Then the result should be, in any order:
      | dval                            |
      | 214748364721474836472147483648M |
      | 4.141592653589793238462600M     |
      | null                            |
    When executing query:
      """
      USE g_decimal MATCH (v:N1) RETURN v.dval - 1M as dval
      """
    Then the result should be, in any order:
      | dval                            |
      | 214748364721474836472147483646M |
      | 2.141592653589793238462600M     |
      | null                            |
    When executing query:
      """
      USE g_decimal MATCH (v:N1) RETURN v.dval * 2M as dval
      """
    Then the result should be, in any order:
      | dval                            |
      | 429496729442949672944294967294M |
      | 6.283185307179586476925200M     |
      | null                            |
    When executing query:
      """
      USE g_decimal MATCH (v:N1) RETURN v.dval / 2M as dval
      """
    Then the result should be, in any order:
      | dval                              |
      | 107374182360737418236073741823.5M |
      | 1.570796326794896619231300M       |
      | null                              |
    When executing query:
      """
      RETURN -107374182360737418236073741824M AS dval
      """
    Then the result should be, in any order:
      | dval                             |
      | -107374182360737418236073741824M |
    # double negation
    When executing query:
      """
      RETURN - -107374182360737418236073741824M AS dval
      """
    Then the result should be, in any order:
      | dval                            |
      | 107374182360737418236073741824M |
    When executing query:
      """
      RETURN 2000M % 8.37M AS dval
      """
    Then the result should be, in any order:
      | dval  |
      | 7.94M |
    When executing query:
      """
      RETURN -2000M % 8.37M AS dval
      """
    Then the result should be, in any order:
      | dval   |
      | -7.94M |
    When executing query:
      """
      USE g_decimal INSERT (@N2{id:1, fval: CAST(1.2M AS FLOAT), lfval: 1.2M, ival: -2147483648, dval: -9223372036854775809})
      """
    Then the execution should be successful
    When executing query:
      """
      USE g_decimal INSERT (@N2{id:2, fval: 1.3f, lfval: 1.3d, ival: CAST(-9223372036854775808 AS INT64), dval: 9223372036854775810M})
      """
    Then the execution should be successful
    # up cast float to decimal
    When executing query:
      """
      USE g_decimal MATCH (v:N2)
      RETURN v.dval as dval, v.fval as fval, v.dval + v.fval as total
      """
    Then the result should be, in any order:
      | dval                  | fval | total            |
      | 9223372036854775810M  | 1.3f | 9.22337204e+18f  |
      | -9223372036854775809M | 1.2f | -9.22337204e+18f |
    # up cast signed integer to decimal
    When executing query:
      """
      USE g_decimal MATCH (v:N2)
      RETURN v.dval + v.ival as total , v.dval as dval, v.ival as ival
      """
    Then the result should be, in any order:
      | total                 | dval                  | ival                 |
      | -9223372039002259457M | -9223372036854775809M | -2147483648          |
      | 2M                    | 9223372036854775810M  | -9223372036854775808 |
    # up cast unsigned integer to decimal
    When executing query:
      """
      USE g_decimal MATCH (v:N2)
      RETURN v.dval as dval, v.dval + cast(2 as uint) as total
      """
    Then the result should be, in any order:
      | dval                  | total                 |
      | -9223372036854775809M | -9223372036854775807M |
      | 9223372036854775810M  | 9223372036854775812M  |
    When executing query:
      """
      USE g_decimal MATCH (v) WHERE v.lfval < 2M RETURN v.id AS vid
      """
    Then the result should be, in any order:
      | vid |
      | 1   |
      | 2   |
    # decimal index test
    When executing query:
      """
      USE g_decimal CREATE INDEX IF NOT EXISTS idec ON NODE N1(dval)
      """
    Then the execution should be successful
    When executing query:
      """
      USE g_decimal MATCH (v:N1)
      WHERE v.dval <> 3
      RETURN v.dval as dval
      """
    Then the result should be, in any order:
      | dval                            |
      | 214748364721474836472147483647M |
      | 3.1415926535897932384626M       |
    And the plan should contain "IndexScan"
    And the plan should contain "index: idec"
    When executing query:
      """
      USE g_decimal MATCH (v:N1)
      WHERE v.dval = 3.1415926535897932384626M
      RETURN v.dval AS dval
      """
    Then the result should be, in any order:
      | dval                      |
      | 3.1415926535897932384626M |
    And the plan should contain "IndexScan"
    And the plan should contain "index: idec"
    When executing query:
      """
      USE g_decimal MATCH (v:N1)
      WHERE v.dval >= 3.1415926535897932384626M
      RETURN v.dval AS dval
      """
    Then the result should be, in any order:
      | dval                            |
      | 214748364721474836472147483647M |
      | 3.1415926535897932384626M       |
    And the plan should contain "IndexScan"
    And the plan should contain "index: idec"
    When executing query:
      """
      USE g_decimal MATCH (v:N1)
      WHERE v.dval > 3.1415926535897932384626M
      RETURN v.dval AS dval
      """
    Then the result should be, in any order:
      | dval                            |
      | 214748364721474836472147483647M |
    And the plan should contain "IndexScan"
    And the plan should contain "index: idec"
    When executing query:
      """
      USE g_decimal MATCH (v:N1)
      WHERE v.dval < 214748364721474836472147483647M
      RETURN v.dval AS dval
      """
    Then the result should be, in any order:
      | dval                      |
      | 3.1415926535897932384626M |
    And the plan should contain "IndexScan"
    And the plan should contain "index: idec"
    When executing query:
      """
      USE g_decimal MATCH (v:N1)
      WHERE v.dval <= 214748364721474836472147483647M
      RETURN v.dval AS dval
      """
    Then the result should be, in any order:
      | dval                            |
      | 214748364721474836472147483647M |
      | 3.1415926535897932384626M       |
    And the plan should contain "IndexScan"
    And the plan should contain "index: idec"
    When executing query:
      """
      USE g_decimal MATCH (v:N1 /*+ ignore_index(idec) */)
      WHERE v.dval IS NOT NULL
      RETURN v.dval AS dval
      """
    Then the result should be, in any order:
      | dval                            |
      | 214748364721474836472147483647M |
      | 3.1415926535897932384626M       |
    # test index null filter
    When executing query:
      """
      USE g_decimal MATCH (v:N1)
      WHERE v.dval IS NOT NULL
      RETURN v.dval AS dval
      """
    Then the result should be, in any order:
      | dval                            |
      | 214748364721474836472147483647M |
      | 3.1415926535897932384626M       |
    And the plan should contain "IndexScan"
    And the plan should contain "index: idec"
    When executing query:
      """
      USE g_decimal MATCH (v:N1 /*+ ignore_index(idec) */)
      WHERE v.dval IS NULL
      RETURN v.dval AS dval
      """
    Then the result should be, in any order:
      | dval |
      | null |
    When executing query:
      """
      USE g_decimal MATCH (v:N1)
      WHERE v.dval IS NULL
      RETURN v.dval AS dval
      """
    Then the result should be, in any order:
      | dval |
      | null |
    And the plan should contain "IndexScan"
    And the plan should contain "index: idec"
    When executing query:
      """
      USE g_decimal CREATE INDEX IF NOT EXISTS idec ON NODE N3(dval)
      """
    Then the execution should be successful
    When executing query:
      """
      USE g_decimal INSERT (@N3{id:1, dval: 1.2}), (@N3{id:2, dval: 1.2}), (@N3{id:3, dval: cast(1 as int32)})
      """
    Then the execution should be successful
    When executing query:
      """
      USE g_decimal MATCH (v:N3)
      WHERE v.dval = 1.2 OR v.dval = 1.20000005 OR v.dval = 1
      RETURN v.dval AS dval
      """
    Then the result should be, in any order:
      | dval                    |
      | 1.20000000000000000000M |
      | 1.20000000000000000000M |
      | 1.00000000000000000000M |
    When executing query:
      """
      USE g_decimal INSERT (@N4{id: 1, dval: 20M}), (@N4{id: 2, dval: 20.7M}), (@N4{id: 3, dval: 20.70M}), (@N4{id: 4, dval: 98.90M})
      """
    Then the execution should be successful
    When executing query:
      """
      USE g_decimal MATCH (v:N4) return v.dval AS dval
      """
    Then the result should be, in any order:
      | dval  |
      | 20.7M |
      | 98.9M |
      | 20.0M |
      | 20.7M |
    When executing query:
      """
      USE g_decimal CREATE INDEX IF NOT EXISTS idec2 ON NODE N5(dval)
      """
    Then the execution should be successful
    When executing query:
      """
      USE g_decimal INSERT (@N4{id: 5, dval: 201.7M})
      """
    Then an Error should be raised: "[NR020]: Decimal out of range: required precision 3, scale 1 but got 201.7, in expression: CAST(201.7 AS DECIMAL(3, 1))"
    When executing query:
      """
      USE g_decimal INSERT (@N4{id: 5, dval: 99.99M})
      """
    Then an Error should be raised: "[NR020]: Decimal out of range: required precision 3, scale 1 but got 99.99, in expression: CAST(99.99 AS DECIMAL(3, 1))"
    # check index constraint
    When executing query:
      """
      USE g_decimal INSERT (@N5{id: 1, dval: 20M}), (@N5{id: 2, dval: 20.7M}), (@N5{id: 3, dval: 20.70M}), (@N5{id: 4, dval: 98.90M})
      """
    Then the execution should be successful
    When executing query:
      """
      USE g_decimal MATCH (v:N5) return v.dval AS dval
      """
    Then the result should be, in any order:
      | dval  |
      | 98.9M |
      | 20M   |
      | 20.7M |
      | 20.7M |
    When executing query:
      """
      USE g_decimal INSERT (@N5{id: 5, dval: 201.7M})
      """
    Then an Error should be raised: "[NR020]: Decimal out of range: required precision 3, scale 1 but got 201.7, in expression: CAST(201.7 AS DECIMAL(3, 1))"
    When executing query:
      """
      USE g_decimal INSERT (@N4{id: 5, dval: 99.99M})
      """
    Then an Error should be raised: "[NR020]: Decimal out of range: required precision 3, scale 1 but got 99.99, in expression: CAST(99.99 AS DECIMAL(3, 1))"
    When executing query:
      """
      DROP GRAPH g_decimal
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE gt_decimal
      """
    Then the execution should be successful

  Scenario: decimal agg
    # sum dec
    When executing query:
      """
      LET lst = LIST[3.1415926535897932384626M, 3.1415926535897932384625M, 3.1415926535897932384625M]
      FOR e IN lst
      RETURN SUM(e) AS val GROUP BY()
      """
    Then the result should be, in any order:
      | val                       |
      | 9.4247779607693797153876M |
    When executing query:
      """
      LET lst = LIST[3.1415926535897932384626M, 3.1415926535897932384625M, 3.1415926535897932384625M]
      FOR e IN lst
      RETURN SUM(DISTINCT e) AS val GROUP BY()
      """
    Then the result should be, in any order:
      | val                       |
      | 6.2831853071795864769251M |
    When executing query:
      """
      LET lst = LIST[3.1415926535897932384626M, 3.1415926535897932384625M, 3.1415926535897932384625M]
      FOR e IN lst
      RETURN MAX(e) AS val GROUP BY()
      """
    Then the result should be, in any order:
      | val                       |
      | 3.1415926535897932384626M |
    When executing query:
      """
      LET lst = LIST[3.1415926535897932384626M, 3.1415926535897932384625M, 3.1415926535897932384625M]
      FOR e IN lst
      RETURN MAX(DISTINCT e) AS val GROUP BY()
      """
    Then the result should be, in any order:
      | val                       |
      | 3.1415926535897932384626M |
    When executing query:
      """
      LET lst = LIST[3.1415926535897932384626M, 3.1415926535897932384625M, 3.1415926535897932384625M]
      FOR e IN lst
      RETURN MIN(e) AS val GROUP BY()
      """
    Then the result should be, in any order:
      | val                       |
      | 3.1415926535897932384625M |
    When executing query:
      """
      LET lst = LIST[3.1415926535897932384626M, 3.1415926535897932384625M, 3.1415926535897932384625M]
      FOR e IN lst
      RETURN MIN(DISTINCT e) AS val GROUP BY()
      """
    Then the result should be, in any order:
      | val                       |
      | 3.1415926535897932384625M |
    When executing query:
      """
      LET lst = LIST[3.1415926535897932384626M, 3.1415926535897932384625M, 3.1415926535897932384625M]
      FOR e IN lst
      RETURN COUNT(e) AS val GROUP BY()
      """
    Then the result should be, in any order:
      | val |
      | 3   |
    When executing query:
      """
      LET lst = LIST[3.1415926535897932384626M, 3.1415926535897932384625M, 3.1415926535897932384625M]
      FOR e IN lst
      RETURN COUNT(DISTINCT e) AS val GROUP BY()
      """
    Then the result should be, in any order:
      | val |
      | 2   |
    When executing query:
      """
      LET lst = LIST[3.1415926535897932384626M, 3.1415926535897932384625M, 3.1415926535897932384625M]
      FOR e IN lst
      RETURN COLLECT(e) as lst group by ()
      NEXT
      FOR e IN lst
      RETURN e
      """
    Then the result should be, in any order:
      | e                         |
      | 3.1415926535897932384626M |
      | 3.1415926535897932384625M |
      | 3.1415926535897932384625M |
    When executing query:
      """
      LET lst = LIST[3.1415926535897932384626M, 3.1415926535897932384625M, 3.1415926535897932384625M]
      FOR e IN lst
      RETURN COLLECT(DISTINCT e) as lst group by ()
      NEXT
      FOR e IN lst
      RETURN e
      """
    Then the result should be, in any order:
      | e                         |
      | 3.1415926535897932384626M |
      | 3.1415926535897932384625M |
    When executing query:
      """
      LET lst = LIST[3.1415926535897932384626M, 3.1415926535897932384625M, 3.1415926535897932384620M, 3.1415926535897932384620M]
      FOR e IN lst
      RETURN AVG(DISTINCT e) as val group by ()
      """
    Then the result should be, in any order:
      | val                       |
      | 3.1415926535897932384624M |
    When executing query:
      """
      LET lst = LIST[3.1415926535897932384626M, 3.1415926535897932384625M, 3.1415926535897932384620M, 3.1415926535897932384620M]
      FOR e IN lst
      RETURN AVG(e) as val group by ()
      """
    Then the result should be, in any order:
      | val                       |
      | 3.1415926535897932384623M |
    When executing query:
      """
      FOR e IN [1M, 2M, 3M, 4M, 4M, 5M]
      RETURN PERCENTILE_CONT(e, 0.5) AS val GROUP BY ()
      """
    Then the result should be, in any order:
      | val  |
      | 3.5M |
    When executing query:
      """
      FOR e IN [1M, 2M, 3M, 4M, 4M, 5M]
      RETURN PERCENTILE_CONT(DISTINCT e, 0.5) AS val GROUP BY ()
      """
    Then the result should be, in any order:
      | val |
      | 3M  |
    When executing query:
      """
      FOR e IN [1M, 2M, 3M, 4M, 4M, 5M]
      RETURN PERCENTILE_DISC(DISTINCT e, 0.5) AS val GROUP BY ()
      """
    Then the result should be, in any order:
      | val |
      | 3M  |
    When executing query:
      """
      FOR e IN [1M, 2M, 3M, 4M, 4M, 5M]
      RETURN PERCENTILE_DISC(e, 0.5) AS val GROUP BY ()
      """
    Then the result should be, in any order:
      | val |
      | 3M  |
    When executing query:
      """
      FOR i IN LIST [5M, 5M, 5M, 5M, 5M]
      RETURN stddev_pop(i) AS val GROUP BY ()
      """
    Then the result should be, in any order:
      | val    |
      | 0.000M |
    When executing query:
      """
      FOR i IN LIST [1M, 2M, 3M, 4M, 5M, 6M]
      RETURN stddev_pop(i) AS val GROUP BY ()
      """
    Then the result should be, in any order:
      | val                |
      | 1.707825127659933M |
    When executing query:
      """
      FOR i IN LIST [1M, 1M, 2M, 3M, 4M, 5M, 6M, 6M]
      RETURN stddev_pop(distinct i) AS val GROUP BY ()
      """
    Then the result should be, in any order:
      | val                |
      | 1.707825127659933M |
    When executing query:
      """
      FOR i IN LIST [5M, 5M, 5M, 5M, 5M]
      RETURN stddev_samp(i) AS val GROUP BY ()
      """
    Then the result should be, in any order:
      | val                |
      | 0.000000000000000M |
    When executing query:
      """
      FOR i IN LIST [1M, 2M, 3M, 4M, 5M]
      RETURN stddev_samp(i) AS val GROUP BY ()
      """
    Then the result should be, in any order:
      | val                |
      | 1.581138830084190M |
    When executing query:
      """
      FOR i IN LIST [1M, 1M, 2M, 3M, 4M, 5M, 5M]
      RETURN stddev_samp(distinct i) AS val GROUP BY ()
      """
    Then the result should be, in any order:
      | val                |
      | 1.581138830084190M |

  Scenario: decimal math functions
    When executing query:
      """
      RETURN ABS(-2.00000000000002M) AS val
      """
    Then the result should be, in any order:
      | val               |
      | 2.00000000000002M |
    When executing query:
      """
      RETURN ABS(2.00000000000002M) AS val
      """
    Then the result should be, in any order:
      | val               |
      | 2.00000000000002M |
    When executing query:
      """
      RETURN FLOOR(2.000000000000000000000000002M) AS val
      """
    Then the result should be, in any order:
      | val |
      | 2M  |
    When executing query:
      """
      RETURN CEIL(2.000000000000000000000000002M) AS val
      """
    Then the result should be, in any order:
      | val |
      | 3M  |
    When executing query:
      """
      RETURN ln(8848091M) AS val
      """
    Then the result should be, in any order:
      | val                      |
      | 15.99571228750149137424M |
    When executing query:
      """
      RETURN sign(-8848M) AS val
      """
    Then the result should be, in any order:
      | val |
      | -1  |
    When executing query:
      """
      RETURN sign(8848M) AS val
      """
    Then the result should be, in any order:
      | val |
      | 1   |
    When executing query:
      """
      RETURN sign(-0M) AS val
      """
    Then the result should be, in any order:
      | val |
      | 0   |
    When executing query:
      """
      RETURN sign(0M) AS val
      """
    Then the result should be, in any order:
      | val |
      | 0   |
    When executing query:
      """
      RETURN round(1.49999999999999999M) AS val
      """
    Then the result should be, in any order:
      | val |
      | 1M  |
    When executing query:
      """
      RETURN round(1.500000000000000001M) AS val
      """
    Then the result should be, in any order:
      | val |
      | 2M  |
    When executing query:
      """
      RETURN ROUND(1.500000000000000005M, 17) AS val
      """
    Then the result should be, in any order:
      | val                  |
      | 1.50000000000000001M |
    When executing query:
      """
      RETURN ROUND(1.500000000000000005M, 17) AS val
      """
    Then the result should be, in any order:
      | val                  |
      | 1.50000000000000001M |
    When executing query:
      """
      RETURN ROUND(1.500000000000000005M, -1000) AS val
      """
    Then the result should be, in any order:
      | val |
      | 0M  |
    When executing query:
      """
      RETURN isnan(1M/2M) AS val
      """
    Then the result should be, in any order:
      | val   |
      | false |
    When executing query:
      """
      RETURN sqrt(2M) AS val
      """
    Then the result should be, in any order:
      | val                     |
      | 1.41421356237309504880M |
    When executing query:
      """
      RETURN ln(2M) AS val
      """
    Then the result should be, in any order:
      | val                     |
      | 0.69314718055994530942M |
    When executing query:
      """
      RETURN exp(2.2M) AS val
      """
    Then the result should be, in any order:
      | val                     |
      | 9.02501349943412092647M |
    When executing query:
      """
      RETURN log(2M, 9M) AS val
      """
    Then the result should be, in any order:
      | val                 |
      | 3.1699250014423124M |
    When executing query:
      """
      RETURN power(3.1415926M, 3.1415926M) AS val
      """
    Then the result should be, in any order:
      | val                 |
      | 36.462155416406842M |
    When executing query:
      """
      RETURN cast(666.66 AS FLOAT) = 666.66 as val
      """
    Then the result should be, in any order:
      | val  |
      | true |

  Scenario: default value
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS gtdec2 AS {
        NODE TYPE N1 (LABEL N1 {id INT PRIMARY KEY, dval DECIMAL(3, 1) DEFAULT 33.30M })
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS gdec2 TYPED gtdec2
      """
    Then the execution should be successful
    When executing query:
      """
      USE gdec2 INSERT (@N1{id: 1024})
      """
    Then the execution should be successful
    When executing query:
      """
      USE gdec2 MATCH (v) RETURN v.dval AS val
      """
    Then the result should be, in any order:
      | val      |
      | 33.3000M |
    When executing query:
      """
      DROP GRAPH gdec2
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE gtdec2
      """
    Then the execution should be successful

  Scenario: composite decimal index
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS gt_cidx AS {
        NODE TYPE N1 (LABEL N1 {id INT PRIMARY KEY, d1 DECIMAL(30), d2 DECIMAL(30), s1 string})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS gcidx TYPED gt_cidx
      """
    Then the execution should be successful
    When executing query:
      """
      USE gcidx CREATE INDEX IF NOT EXISTS i1 ON NODE N1(d1, d2)
      """
    Then the execution should be successful
    When executing query:
      """
      USE gcidx CREATE INDEX IF NOT EXISTS i2 ON NODE N1(d1, s1)
      """
    Then the execution should be successful
    When executing query:
      """
      USE gcidx CREATE INDEX IF NOT EXISTS i3 ON NODE N1(s1, d2)
      """
    Then the execution should be successful
    When executing query:
      """
      USE gcidx INSERT (@N1{id: 1, d1: 1234567812345678M, d2: 5678M, s1: "1234"}),
        (@N1{id: 2, d1: 5678M, d2: 5678567856785678M, s1: "5678567856785678"}),
        (@N1{id: 3, d1: 5678M, d2: 1233M, s1: "12345"})
      """
    Then the execution should be successful
    # decimal and string
    When executing query:
      """
      USE gcidx MATCH (v) WHERE v.d1 >= 12345M AND v.s1 >= "1234" RETURN v.d1 AS d1, v.s1 AS s1
      """
    Then the result should be, in any order:
      | d1                | s1     |
      | 1234567812345678M | "1234" |
    When executing query:
      """
      USE gcidx MATCH (v) WHERE v.d1 >= 1234M AND v.s1 >= "5678" RETURN v.d1 AS d1, v.s1 AS s1
      """
    Then the result should be, in any order:
      | d1    | s1                 |
      | 5678M | "5678567856785678" |
    # decimal and decimal
    When executing query:
      """
      USE gcidx MATCH (v) WHERE v.d1 >= 12345M AND v.d2 >= 5678M RETURN v.d1 AS d1, v.d2 AS d2
      """
    Then the result should be, in any order:
      | d1                | d2    |
      | 1234567812345678M | 5678M |
    When executing query:
      """
      USE gcidx MATCH (v) WHERE v.d1 >= 1234M AND v.d2 >= 56785M RETURN v.d1 AS d1, v.d2 AS d2
      """
    Then the result should be, in any order:
      | d1    | d2                |
      | 5678M | 5678567856785678M |
    # string adn decimal
    When executing query:
      """
      USE gcidx MATCH (v) WHERE v.s1 >= "12345" AND v.d2 >= 1234M RETURN v.s1 AS s1, v.d2 AS d2
      """
    Then the result should be, in any order:
      | s1                 | d2                |
      | "5678567856785678" | 5678567856785678M |
    When executing query:
      """
      USE gcidx MATCH (v) WHERE v.s1 >= "1234" AND v.d2 >= 5678M RETURN v.s1 AS s1, v.d2 AS d2
      """
    Then the result should be, in any order:
      | s1                 | d2                |
      | "5678567856785678" | 5678567856785678M |
      | "1234"             | 5678M             |
    When executing query:
      """
      DROP GRAPH gcidx
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE gt_cidx
      """
    Then the execution should be successful

  Scenario: check decimal precision
    # the result is check with a postgres query: SELECT SUM(SQRT(cast(i as numeric(50, 20)))) FROM generate_series(1, 100) AS s(i)
    When executing query:
      """
      FOR i IN range(1, 100)
      RETURN SUM(SQRT(CAST(i AS DECIMAL(50, 20)))) AS total GROUP BY ()
      """
    Then the result should be, in any order:
      | total                     |
      | 671.46294710314775393422M |

  Scenario: alter decimal type
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS modify_decimal_graph_type1 AS {
        NODE Person (LABEL Person {id INT8 PRIMARY KEY, salary DECIMAL (20, 10), salary2 DECIMAL(20, 10)})}
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS modify_decimal_graph1 modify_decimal_graph_type1
      """
    Then the execution should be successful
    When executing query:
      """
      USE modify_decimal_graph1 INSERT(person_1@Person{id:2, salary:1188888888.66, salary2:1188888888.66})
      """
    Then the execution should be successful
    When executing query:
      """
      ALTER GRAPH TYPE modify_decimal_graph_type1 {ALTER NODE TYPE Person modify properties { salary DECIMAL (5,2)}}
      """
    Then an Error should be raised: "[NR113]: Property `salary` of element type `Person` cannot be modified from `DECIMAL(20, 10)` to `DECIMAL(5, 2)`"
    When executing query:
      """
      USE modify_decimal_graph1 INSERT(person_1@Person{id:3, salary:88888888.66M, salary2:1188888888.66})
      """
    Then the execution should be successful
    When executing query:
      """
      ALTER GRAPH TYPE modify_decimal_graph_type1 {ALTER NODE TYPE Person modify properties { salary DOUBLE, salary2 FLOAT}}
      """
    Then the execution should be successful
    When executing query:
      """
      USE modify_decimal_graph1
      MATCH (v)
      RETURN v.salary AS salary, v.salary2 as salary2
      """
    Then the result should be, in any order:
      | salary            | salary2    |
      | 1.18888888866e+09 | 1188888832 |
      | 88888888.66       | 1188888832 |
    When executing query:
      """
      DROP GRAPH modify_decimal_graph1
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE modify_decimal_graph_type1
      """
    Then the execution should be successful

  Scenario: preserve scale
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS gt_scale AS {
        NODE Person (LABEL Person {id INT8 PRIMARY KEY, salary DECIMAL (20, 10), salary2 DECIMAL(10, 3), salary3 DECIMAL })}
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS g_scale gt_scale
      """
    Then the execution should be successful
    When executing query:
      """
      USE g_scale INSERT(person_1@Person{id:2, salary:1188888888.66, salary2: 123.400, salary3: 816})
      """
    Then the execution should be successful
    When executing query:
      """
      USE g_scale INSERT(person_1@Person{id:3, salary:1188888888.66, salary2: 123.400, salary3: 816.6})
      """
    Then an Error should be raised: "[NR020]: Decimal out of range: required precision 10, scale 0 but got 816.6, in expression: CAST(816.6 AS DECIMAL(10, 0))"
    When executing query:
      """
      USE g_scale
      MATCH (v)
      RETURN CAST(v.salary AS STRING) AS salary, CAST(v.salary2 AS STRING) AS salary2, CAST(v.salary3 AS STRING) AS salary3
      """
    Then the result should be, in any order:
      | salary                  | salary2   | salary3 |
      | "1188888888.6600000000" | "123.400" | "816"   |
    When executing query:
      """
      USE g_scale
      MATCH (v)
      WHERE v.salary = 1188888888.66
      RETURN CAST(v.salary AS STRING) AS salary, CAST(v.salary2 AS STRING) AS salary2
      """
    Then the result should be, in any order:
      | salary                  | salary2   |
      | "1188888888.6600000000" | "123.400" |
    When executing query:
      """
      USE g_scale
      MATCH (v)
      WHERE v.salary = 1188888888.660000
      RETURN CAST(v.salary AS STRING) AS salary, CAST(v.salary2 AS STRING) AS salary2
      """
    Then the result should be, in any order:
      | salary                  | salary2   |
      | "1188888888.6600000000" | "123.400" |
    When executing query:
      """
      USE g_scale CREATE INDEX IF NOT EXISTS idx_scale ON NODE Person(salary2)
      """
    Then the execution should be successful
    When executing query:
      """
      USE g_scale
      MATCH (v)
      WHERE v.salary2 = 123.400
      RETURN CAST(v.salary2 AS STRING) AS salary2
      """
    Then the result should be, in any order:
      | salary2   |
      | "123.400" |
    And the plan should contain "IndexScan"
    And the plan should contain "index: idx_scale"
    When executing query:
      """
      USE g_scale
      MATCH (v)
      WHERE v.salary2 = 123.4
      RETURN CAST(v.salary2 AS STRING) AS salary2
      """
    Then the result should be, in any order:
      | salary2   |
      | "123.400" |
    And the plan should contain "IndexScan"
    And the plan should contain "index: idx_scale"
    When executing query:
      """
      USE g_scale
      MATCH (v)
      WHERE v.salary2 = 123.400001
      RETURN CAST(v.salary2 AS STRING) AS salary2
      """
    Then the result should be, in any order:
      | salary2 |
    And the plan should contain "IndexScan"
    And the plan should contain "index: idx_scale"
    When executing query:
      """
      USE g_scale
      MATCH (v)
      WHERE v.salary2 = 123.4000000000
      RETURN CAST(v.salary2 AS STRING) AS salary2
      """
    Then the result should be, in any order:
      | salary2   |
      | "123.400" |
    And the plan should contain "IndexScan"
    And the plan should contain "index: idx_scale"
    When executing query:
      """
      DROP GRAPH g_scale
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE gt_scale
      """
    Then the execution should be successful
