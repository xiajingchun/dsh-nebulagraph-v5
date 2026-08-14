# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: BindingTable Function

  Scenario: basic
    When executing query:
      """
      TABLE t {s, d, id} = (1, 10, 1), (2, 20, 2)
      return size(t) as s
      """
    Then the result should be, in any order:
      | s |
      | 2 |
    When executing query:
      """
      TABLE t {s, d} =
      (0o1234567012345670123456701234567012345670, 0o7654321076543210765432107654321076543210),
      (0o7654321076543210765432107654321076543210, 0o1234567012345670123456701234567012345670)
      RETURN size(t) AS s
      """
    Then the result should be, in any order:
      | s |
      | 2 |
    When executing query:
      """
      TABLE t {s, d} =
      (0b1011000011111000000011011100110100101000011011110111011110001110100011110011000100010101100001100001110010111110000001101000000001011000000011101100010100001001,
       0b1101010000111011101010100010010011101010010100110101000110000001001001010101111101101100110101111011101000010001110110101011101011011111111010111010100111010001),
      (0b1101010000111011101010100010010011101010010100110101000110000001001001010101111101101100110101111011101000010001110110101011101011011111111010111010100111010001,
       0b1011000011111000000011011100110100101000011011110111011110001110100011110011000100010101100001100001110010111110000001101000000001011000000011101100010100001001)
      RETURN size(t) AS s
      """
    Then the result should be, in any order:
      | s |
      | 2 |
    When executing query:
      """
      TABLE t {s, d} =
      (0xb0f80dcd286f778e8f3115861cbe0680580ec509, 0xd43baa24ea535181255f6cd7ba11dabadfeba9d1),
      (0xd43baa24ea535181255f6cd7ba11dabadfeba9d1, 0xb0f80dcd286f778e8f3115861cbe0680580ec509)
      RETURN size(t) AS s
      """
    Then the result should be, in any order:
      | s |
      | 2 |
    When executing query:
      """
      GRAPH g TYPED GRAPH {
      NODE TYPE Place (LABELS City&Country&Continent {id INT PRIMARY KEY, name STRING, url STRING, kind STRING})
      } = GRAPH{ USE ldbc MATCH (a@Place) RETURN a } RETURN g AS gx
      NEXT
      return size(gx)
      """
    Then an Error should be raised: "[NR002]: Undefined function: `size(GRAPH_REF)`"
    When executing query:
      """
      TABLE t TYPED TABLE {prop1 INT8, prop2 FLOAT, prop3 STRING} =
      {prop1:1,prop2:1.0,prop3:"x"},
      {prop1:2,prop2:2.0,prop3:"y"},
      {prop1:2,prop2:2.0,prop3:"z"},
      {prop1:null,prop2:null,prop3:null}
      FOR rec in t
      RETURN size(t) as s
      """
    Then the result should be, in any order:
      | s |
      | 4 |
      | 4 |
      | 4 |
      | 4 |
    When executing query:
      """
      TABLE t {person_id, tag_id} =
      (1,1),
      (2,2),
      (3,3)
      USE ldbc
      FOR r IN t
      MATCH (a@Person) WHERE a.id = size(t)
      return a.id
      """
    Then the result should be, in any order:
      | a.id |
      | 3    |
      | 3    |
      | 3    |
    When executing analytic query:
      """
      USE #analytic_ldbc {
          TABLE result_table TYPED TABLE {id INT}
          MATCH (a)
          PER NODE (a) {
            EXPORT a.id INTO result_table
          }
          RETURN size(result_table) as sz
      }
      """
    Then the result should be, in any order:
      | sz |
      | 34 |
    When executing analytic query:
      """
      USE #analytic_ldbc {
          TABLE result_table TYPED TABLE {id INT}
          MATCH (a)
          PER NODE (a) {
            EXPORT a.id INTO result_table
          }
          RETURN size(result_table) as sz
      }
      """
    Then the result should be, in any order:
      | sz |
      | 34 |
    When executing analytic query:
      """
      USE #analytic_ldbc {
      TABLE result_table TYPED TABLE {id INT}
      VALUE i INT64 = 0
      MATCH (a)
      PER NODE (a) {
      EXPORT a.id INTO result_table
      }
      SET i = i + size(result_table)
      WHILE (i + size(result_table) < 1000) THEN {
        SET i = i + size(result_table)
      }
      RETURN i
      }
      """
    Then the result should be, in any order:
      | i   |
      | 986 |
    When executing analytic query:
      """
      USE #analytic_ldbc {
        TABLE result_table TYPED TABLE {id INT, sz INT64}
        MATCH (a)
        PER NODE (a) {
        EXPORT a.id, size(result_table) INTO result_table
        }

        FOR x IN result_table
        RETURN DISTINCT x.sz AS ori_size, size(result_table) AS now_size
      }
      """
    Then the result should be, in any order:
      | ori_size | now_size |
      | 0        | 34       |
    When executing query:
      """
      TABLE result_table TYPED TABLE {i INT, j INT}
      FOR i IN range(1, 100)
      FOR j IN range(1, 100)
      EXPORT i, j INTO result_table

      FOR t IN table_split(result_table)
      RETURN sum(size(t))
      """
    Then the result should be, in any order:
      | sum(size(t)) |
      | 10000        |
    When executing query:
      """
      TABLE result_table TYPED TABLE {i INT, j INT}
      FOR i IN range(1, 5)
      FOR j IN range(1, 5)
      EXPORT i, j INTO result_table

      FOR t IN table_split(result_table, cast(10 as UINT))
      RETURN size(t)
      """
    Then the result should be, in any order:
      | size(t) |
      | 10      |
      | 10      |
      | 5       |
    When executing query:
      """
      TABLE result_table TYPED TABLE {i INT, j INT}
      FOR i IN range(1, 3)
      FOR j IN range(1, 3)
      EXPORT i, j INTO result_table

      FOR t IN table_split(result_table, cast(10 as UINT))
      FOR r IN t
      RETURN r.i as i , r.j as j
      """
    Then the result should be, in any order:
      | i | j |
      | 1 | 1 |
      | 1 | 2 |
      | 1 | 3 |
      | 2 | 1 |
      | 2 | 2 |
      | 2 | 3 |
      | 3 | 1 |
      | 3 | 2 |
      | 3 | 3 |

  Scenario: clear
    # Basic clear test
    When executing query:
      """
      TABLE t TYPED TABLE {prop1 INT8, prop2 FLOAT, prop3 STRING} =
      {prop1:1,prop2:1.0,prop3:"x"},
      {prop1:2,prop2:2.0,prop3:"y"},
      {prop1:3,prop2:3.0,prop3:"z"}
      FOR rec in t
      RETURN size(t) as sz
      """
    Then the result should be, in any order:
      | sz |
      | 3  |
      | 3  |
      | 3  |
    When executing query:
      """
      TABLE t TYPED TABLE {prop1 INT8, prop2 FLOAT, prop3 STRING} =
      {prop1:1,prop2:1.0,prop3:"x"},
      {prop1:2,prop2:2.0,prop3:"y"}
      SET t.clear()
      RETURN size(t) as sz
      """
    Then the result should be, in any order:
      | sz |
      | 0  |
    # Clear empty table
    When executing query:
      """
      TABLE t TYPED TABLE {prop1 INT8, prop2 STRING}
      SET t.clear()
      RETURN size(t) as sz
      """
    Then the result should be, in any order:
      | sz |
      | 0  |
    # Clear and then insert
    When executing analytic query:
      """
      USE #analytic_ldbc {
        TABLE result_table TYPED TABLE {id INT, name STRING}
        MATCH (a@Person)
        PER NODE (a) {
          EXPORT a.id, a.firstName INTO result_table
        }
        SET result_table.clear()
        MATCH (b@Tag)
        PER NODE (b) {
          EXPORT b.id, b.name INTO result_table
        }
        RETURN size(result_table) as sz
      }
      """
    Then the result should be, in any order:
      | sz |
      | 4  |
    # Clear in loop
    When executing analytic query:
      """
      USE #analytic_ldbc {
        TABLE result_table TYPED TABLE {id INT}
        VALUE i INT64 = 0
        WHILE (i < 3) THEN {
          MATCH (a@Person)
          PER NODE (a) {
            EXPORT a.id INTO result_table
          }
          SET i = i + 1
          SET result_table.clear()
        }
        RETURN size(result_table) as sz, i
      }
      """
    Then the result should be, in any order:
      | sz | i |
      | 0  | 3 |
    # Clear and verify data is actually cleared
    When executing analytic query:
      """
      USE #analytic_ldbc {
        TABLE result_table TYPED TABLE {id INT, name STRING}
        MATCH (a@Person)
        PER NODE (a) {
          EXPORT a.id, a.firstName INTO result_table
        }
        SET result_table.clear()
        FOR rec IN result_table
        RETURN rec.id, rec.name
      }
      """
    Then the result should be, in any order:
      | rec.id | rec.name |
    # Clear multiple times
    When executing query:
      """
      TABLE t TYPED TABLE {id INT} = {id:1}, {id:2}
      SET t.clear()
      SET t.clear()
      SET t.clear()
      RETURN size(t) as sz
      """
    Then the result should be, in any order:
      | sz |
      | 0  |
    # Clear with table literal syntax
    When executing query:
      """
      TABLE t {id, name} = (1, "a"), (2, "b"), (3, "c")
      SET t.clear()
      RETURN size(t) as sz
      """
    Then the result should be, in any order:
      | sz |
      | 0  |
    # Clear and insert with FOR loop
    When executing query:
      """
      USE #analytic_ldbc {
        TABLE t TYPED TABLE {id INT, name STRING} = {id:1, name:"old"}
        TABLE t2 {id, name} = (10, "new1"), (20, "new2")
        SET t.clear()
        MATCH (a@Person)
        PER NODE (a) {
          EXPORT a.id, a.firstName INTO t
        }
        FOR rec IN t
        RETURN rec.id, rec.name
      }
      """
    Then the result should be, in any order:
      | rec.id | rec.name |
      | 2      | "Tim"    |
      | 3      | "Ming"   |
      | 4      | "Sophie" |
      | 1      | "Kyle"   |

  Scenario: Basic uncorrelated table subquery
    When executing query:
      """
      TABLE t = { RETURN 1 AS a, "hello" AS b }
      FOR rec IN t
      RETURN rec.a, rec.b
      """
    Then the result should be, in order:
      | rec.a | rec.b   |
      | 1     | "hello" |
    When executing query:
      """
      TABLE t = {
        RETURN 1 AS a, 2 AS b
        UNION ALL
        RETURN 3 AS a, 4 AS b
      }
      FOR rec IN t
      RETURN rec.a, rec.b
      """
    Then the result should be, in any order:
      | rec.a | rec.b |
      | 1     | 2     |
      | 3     | 4     |

  Scenario: Table subquery with graph data
    When executing query:
      """
      TABLE t = {
        USE ldbc
        MATCH (v:Person)
        RETURN v.id AS id, v.firstName AS name
        ORDER BY v.id
      }
      FOR rec IN t
      RETURN rec.id, rec.name
      """
    Then the result should be, in order:
      | rec.id | rec.name |
      | 1      | "Kyle"   |
      | 2      | "Tim"    |
      | 3      | "Ming"   |
      | 4      | "Sophie" |

  Scenario: Table subquery with explicit field names
    When executing query:
      """
      TABLE t {id, name} = {
        USE ldbc
        MATCH (v:Person)
        RETURN v.id, v.firstName
        ORDER BY v.id
        LIMIT 2
      }
      FOR rec IN t
      RETURN rec.id, rec.name
      """
    Then the result should be, in order:
      | rec.id | rec.name |
      | 1      | "Kyle"   |
      | 2      | "Tim"    |

  Scenario: Table subquery with explicit typed schema
    When executing query:
      """
      TABLE t TYPED TABLE {id INT64, name STRING} = {
        USE ldbc
        MATCH (v:Person)
        RETURN v.id, v.firstName
        ORDER BY v.id
        LIMIT 1
      }
      FOR rec IN t
      RETURN rec.id, rec.name
      """
    Then the result should be, in order:
      | rec.id | rec.name |
      | 1      | "Kyle"   |

  Scenario: Empty result from table subquery
    When executing query:
      """
      TABLE t = {
        USE ldbc
        MATCH (v:Person)
        WHERE v.id < 0
        RETURN v.id AS id, v.firstName AS name
      }
      FOR rec IN t
      RETURN rec.id, rec.name
      """
    Then the result should be, in order:
      | rec.id | rec.name |
    When executing query:
      """
      TABLE t TYPED TABLE {id INT64, name STRING} = {
        USE ldbc
        MATCH (v:Person)
        WHERE v.id < 0
        RETURN v.id, v.firstName
      }
      FOR rec IN t
      RETURN rec.id, rec.name
      """
    Then the result should be, in order:
      | rec.id | rec.name |

  Scenario: Table subquery error cases
    When executing query:
      """
      TABLE t {a, b, c} = {
        RETURN 1 AS x, 2 AS y
      }
      FOR rec IN t
      RETURN rec.a
      """
    Then an Error should be raised: "[NS236]: Invalid binding table variable definition: Declared 3 fields but subquery returns 2 columns"
    When executing query:
      """
      TABLE t TYPED TABLE {a STRING} = {
        RETURN 1 AS x
      }
      FOR rec IN t
      RETURN rec.a
      """
    Then an Error should be raised: "[NS236]: Invalid binding table variable definition: Column 0 type `INT"
    # Declared more fields than subquery returns (different count)
    When executing query:
      """
      TABLE t {a, b, c, d, e} = {
        RETURN 1 AS x, 2 AS y
      }
      FOR rec IN t
      RETURN rec.a
      """
    Then an Error should be raised: "[NS236]: Invalid binding table variable definition: Declared 5 fields but subquery returns 2 columns"
    # Declared fewer fields than subquery returns
    When executing query:
      """
      TABLE t {a} = {
        RETURN 1 AS x, 2 AS y, 3 AS z
      }
      FOR rec IN t
      RETURN rec.a
      """
    Then an Error should be raised: "[NS236]: Invalid binding table variable definition: Declared 1 fields but subquery returns 3 columns"
    # Multiple type mismatches in typed table
    When executing query:
      """
      TABLE t TYPED TABLE {a INT64, b STRING, c BOOL} = {
        RETURN "not_an_int" AS x, 123 AS y, "not_a_bool" AS z
      }
      FOR rec IN t
      RETURN rec.a
      """
    Then an Error should be raised: "[NS236]: Invalid binding table variable definition: Column 0 type `STRING` cannot be cast to declared type `INT64`"
    # Type mismatch: FLOAT to INT64 (no implicit downcast)
    When executing query:
      """
      TABLE t TYPED TABLE {a INT64} = {
        RETURN 3.14 AS x
      }
      FOR rec IN t
      RETURN rec.a
      """
    Then an Error should be raised: "[NS236]: Invalid binding table variable definition: Column 0 type `DECIMAL` cannot be cast to declared type `INT64`"
    # Type mismatch: complex type (LIST) to scalar
    When executing query:
      """
      TABLE t TYPED TABLE {a INT64} = {
        RETURN [1, 2, 3] AS x
      }
      FOR rec IN t
      RETURN rec.a
      """
    Then an Error should be raised: "[NS236]: Invalid binding table variable definition: Column 0 type `LIST<INT32>` cannot be cast to declared type `INT64`"
    # Type mismatch: MAP to scalar
    When executing query:
      """
      TABLE t TYPED TABLE {a STRING} = {
        RETURN {key: "value"} AS x
      }
      FOR rec IN t
      RETURN rec.a
      """
    Then an Error should be raised: "[NS236]: Invalid binding table variable definition: Column 0 type `RECORD{key STRING}` cannot be cast to declared type `STRING`"

  Scenario: Correlated table subquery with value variable
    When executing query:
      """
      VALUE minId = 2
      TABLE t = {
        USE ldbc
        MATCH (v:Person)
        WHERE v.id >= minId
        RETURN v.id AS id, v.firstName AS name
        ORDER BY v.id
        LIMIT 2
      }
      FOR rec IN t
      RETURN rec.id, rec.name
      """
    Then the result should be, in order:
      | rec.id | rec.name |
      | 2      | "Tim"    |
      | 3      | "Ming"   |

  Scenario: Nested TABLE definition inside subquery is not allowed
    # TABLE definitions are not DQL, so they cannot be used inside subqueries
    When executing query:
      """
      VALUE minId = 2
      TABLE t = {
        TABLE t2 = {
          USE ldbc
          MATCH (v:Person)
          WHERE v.id > minId
          RETURN v.id AS id
          ORDER BY v.id
        }
        FOR j IN t2
        RETURN j.id AS id
      }
      FOR i IN t
      RETURN i.id
      """
    Then an Error should be raised: "[NS241]: Only DQL is allowed in subquery"

  Scenario: Table subquery with aggregation
    When executing query:
      """
      TABLE t = {
        USE ldbc
        MATCH (v:Person)
        RETURN COUNT(v) AS cnt
        GROUP BY ()
      }
      FOR rec IN t
      RETURN rec.cnt
      """
    Then the result should be, in order:
      | rec.cnt |
      | 4       |

  Scenario: Table subquery with filtering
    When executing query:
      """
      TABLE t = {
        USE ldbc
        MATCH (v:Person)
        WHERE v.id > 2
        RETURN v.id AS id
        ORDER BY v.id
      }
      FOR rec IN t
      RETURN rec.id
      """
    Then the result should be, in order:
      | rec.id |
      | 3      |
      | 4      |

  Scenario: Multiple table subqueries
    When executing query:
      """
      TABLE t1 = { RETURN 1 AS a }
      TABLE t2 = { RETURN 2 AS b }
      FOR r1 IN t1
      FOR r2 IN t2
      RETURN r1.a, r2.b
      """
    Then the result should be, in order:
      | r1.a | r2.b |
      | 1    | 2    |

  Scenario: Duplicate field names error
    # Duplicate field names in literal table
    When executing query:
      """
      TABLE t {id, name, id} = (1, "a", 2), (3, "b", 4)
      FOR rec IN t
      RETURN rec.id
      """
    Then an Error should be raised: "[NS236]: Invalid binding table variable definition: Duplicate field name `id` in table"
    # Duplicate field names in typed table
    When executing query:
      """
      TABLE t TYPED TABLE {id INT64, name STRING, id INT64} = {id:1, name:"x", id:2}
      FOR rec IN t
      RETURN rec.id
      """
    Then an Error should be raised: "[NS236]: Invalid binding table variable definition: Duplicate field name `id` in table"
    # Duplicate field names in table subquery with declared schema
    When executing query:
      """
      TABLE t {a, b, a} = {
        RETURN 1 AS x, 2 AS y, 3 AS z
      }
      FOR rec IN t
      RETURN rec.a
      """
    Then an Error should be raised: "[NS236]: Invalid binding table variable definition: Duplicate field name `a` in table"

  Scenario: Literal table field mismatch errors
    # Too few values in tuple literal
    When executing query:
      """
      TABLE t {a, b, c} = (1, 2), (3, 4, 5)
      FOR rec IN t
      RETURN rec.a
      """
    Then an Error should be raised: "[42N36]: Invalid syntax, the number of fields"
    # Too many values in tuple literal
    When executing query:
      """
      TABLE t {a, b} = (1, 2, 3), (4, 5)
      FOR rec IN t
      RETURN rec.a
      """
    Then an Error should be raised: "[42N36]: Invalid syntax, the number of fields"
    # Unknown field in record literal
    When executing query:
      """
      TABLE t TYPED TABLE {id INT64, name STRING} = {id:1, unknown_field:"x"}
      FOR rec IN t
      RETURN rec.id
      """
    Then an Error should be raised: "[NS236]: Invalid binding table variable definition: field `unknown_field`"
    # Missing field in record literal
    When executing query:
      """
      TABLE t TYPED TABLE {id INT64, name STRING, amount FLOAT} = {id:1, name:"x"}
      FOR rec IN t
      RETURN rec.id
      """
    Then an Error should be raised: "[42N36]"

  Scenario: Literal table type mismatch errors
    # String value for INT field in typed table
    When executing query:
      """
      TABLE t TYPED TABLE {id INT64, name STRING} = {id:"not_a_number", name:"test"}
      FOR rec IN t
      RETURN rec.id
      """
    Then an Error should be raised: "[NS236]: Invalid binding table variable definition: The type of `\"not_a_number\"(STRING)` cannot be implicitly cast to the type `INT64` of field `id`"
    # Boolean value for STRING field in typed table
    When executing query:
      """
      TABLE t TYPED TABLE {id INT64, name STRING} = {id:1, name:true}
      FOR rec IN t
      RETURN rec.name
      """
    Then an Error should be raised: "[NS236]: Invalid binding table variable definition: The type of `true(BOOL)` cannot be implicitly cast to the type `STRING` of field `name`"
    # LIST value for scalar field in typed table
    When executing query:
      """
      TABLE t TYPED TABLE {id INT64, name STRING} = {id:[1,2,3], name:"test"}
      FOR rec IN t
      RETURN rec.id
      """
    Then an Error should be raised: "[NS236]: Invalid binding table variable definition: The type of `"
    # Float to Int downcast not allowed in typed table
    When executing query:
      """
      TABLE t TYPED TABLE {id INT64} = {id:3.14}
      FOR rec IN t
      RETURN rec.id
      """
    Then an Error should be raised: "[NS236]: Invalid binding table variable definition: The type of `3.14(DECIMAL)` cannot be implicitly cast to the type `INT64` of field `id`"

  Scenario: Table subquery with graph type mismatch
    # Subquery returns PATH when scalar expected
    When executing query:
      """
      TABLE t TYPED TABLE {p STRING} = {
        USE ldbc
        MATCH p = (a:Person)-[:KNOWS]->(b:Person)
        RETURN p
        LIMIT 1
      }
      FOR rec IN t
      RETURN rec.p
      """
    Then an Error should be raised: "[NS236]: Invalid binding table variable definition: Column 0 type `PATH` cannot be cast to declared type `STRING`"
    # Subquery returns NODE when scalar expected
    When executing query:
      """
      TABLE t TYPED TABLE {n INT64} = {
        USE ldbc
        MATCH (n:Person)
        RETURN n
        LIMIT 1
      }
      FOR rec IN t
      RETURN rec.n
      """
    Then an Error should be raised: "[NS236]: Invalid binding table variable definition: Column 0 type `NODE"
    # Subquery returns EDGE when scalar expected
    When executing query:
      """
      TABLE t TYPED TABLE {e STRING} = {
        USE ldbc
        MATCH ()-[e:KNOWS]->()
        RETURN e
        LIMIT 1
      }
      FOR rec IN t
      RETURN rec.e
      """
    Then an Error should be raised: "[NS236]: Invalid binding table variable definition: Column 0 type `EDGE<"

  Scenario: Table subquery with NULL type handling
    # NULL with explicit typed table should work (NULL is castable to any type)
    When executing query:
      """
      TABLE t TYPED TABLE {a INT64, b STRING} = {
        RETURN null AS x, null AS y
      }
      FOR rec IN t
      RETURN rec.a, rec.b
      """
    Then the result should be, in order:
      | rec.a | rec.b |
      | null  | null  |
    # NULL without explicit types should error (ambiguous type)
    When executing query:
      """
      TABLE t = {
        RETURN null AS x
      }
      FOR rec IN t
      RETURN rec.x
      """
    Then an Error should be raised: "[NS236]: Invalid binding table variable definition: Column `x` has NULL type"
    # Mixed NULL and non-NULL columns - only NULL column errors
    When executing query:
      """
      TABLE t = {
        RETURN 1 AS a, null AS b
      }
      FOR rec IN t
      RETURN rec.a, rec.b
      """
    Then an Error should be raised: "[NS236]: Invalid binding table variable definition: Column `b` has NULL type"
