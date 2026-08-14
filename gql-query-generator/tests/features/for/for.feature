# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: For

  Scenario: ForStatement
    When executing query:
      """
      /*+ SET_VAR(unwind_min_batch_size = 102400) */
      TABLE t TYPED TABLE {prop1 INT8} = {prop1:1}, {prop1:2}, {prop1:2}, {prop1:null}
      FOR rec in t
      RETURN rec.prop1 AS prop1
      """
    Then the result should be, in any order:
      | prop1 |
      | 1     |
      | 2     |
      | 2     |
      | null  |
    When executing query:
      """
      /*+ SET_VAR(unwind_min_batch_size = 102400) */
      TABLE t TYPED TABLE {prop1 INT8} = {prop1:1}
      FOR rec in t
      RETURN rec.prop1 AS prop1
      """
    Then the result should be, in any order:
      | prop1 |
      | 1     |
    When executing query:
      """
      /*+ SET_VAR(unwind_min_batch_size = 1) */
      TABLE t TYPED TABLE {prop1 INT8} = {prop1:1}, {prop1:2}, {prop1:2}, {prop1:null}
      FOR rec in t
      RETURN rec.prop1 AS prop1
      """
    Then the result should be, in any order:
      | prop1 |
      | 1     |
      | 2     |
      | 2     |
      | null  |
    When executing query:
      """
      /*+ SET_VAR(unwind_min_batch_size = 1) */
      TABLE t TYPED TABLE {prop1 INT8} = {prop1:1}
      FOR rec in t
      RETURN rec.prop1 AS prop1
      """
    Then the result should be, in any order:
      | prop1 |
      | 1     |
    When executing query:
      """
      /*+ SET_VAR(unwind_min_batch_size = 1) */
      LET a = LIST[1, 2, 3], b = 3
      FOR i IN a
      RETURN i, b
      """
    Then the result should be, in any order:
      | i | b |
      | 1 | 3 |
      | 2 | 3 |
      | 3 | 3 |
    When executing query:
      """
      /*+ SET_VAR(unwind_min_batch_size = 1) */
      LET a = LIST[1], b = 3
      FOR i IN a
      RETURN i, b
      """
    Then the result should be, in any order:
      | i | b |
      | 1 | 3 |
    When executing query:
      """
      /*+ SET_VAR(unwind_min_batch_size = 1) */
      LET a = LIST[], b = 3
      FOR i IN a
      RETURN i, b
      """
    Then the result should be, in any order:
      | i | b |
    When executing query:
      """
      /*+ SET_VAR(unwind_min_batch_size = 10000) */
      LET a = LIST[1, 2, 3], b = 3
      FOR i IN a
      RETURN i, b
      """
    Then the result should be, in any order:
      | i | b |
      | 1 | 3 |
      | 2 | 3 |
      | 3 | 3 |
    # FIX https://github.com/vesoft-inc/nebula-ng/issues/8563
    When executing query:
      """
      USE ldbc
      OPTIONAL MATCH (v)-[e]->(t)
      WHERE e.workFrom  = v.id
      FOR ua0 IN LIST[]
      MATCH (v)
      RETURN e LIMIT 10
      """
    Then the result should be, in any order:
      | e |
    When executing query:
      """
      /*+ SET_VAR(unwind_min_batch_size = 100) */
      LET a = SET{1, 2, 3}, b = 3
      FOR i IN a
      RETURN i, b
      """
    Then the result should be, in any order:
      | i | b |
      | 1 | 3 |
      | 2 | 3 |
      | 3 | 3 |
    When executing query:
      """
      /*+ SET_VAR(unwind_min_batch_size = 1) */
      LET a = SET{1, 2, 3}, b = 3
      FOR i IN a
      RETURN i, b
      """
    Then the result should be, in any order:
      | i | b |
      | 1 | 3 |
      | 2 | 3 |
      | 3 | 3 |

  Scenario: ForStatement with ORDINALITY - 1-based index
    When executing query:
      """
      /*+ SET_VAR(unwind_min_batch_size = 1) */
      LET a = LIST['x', 'y', 'z']
      FOR i IN a WITH ORDINALITY idx
      RETURN i, idx
      """
    Then the result should be, in order:
      | i   | idx |
      | "x" | 1   |
      | "y" | 2   |
      | "z" | 3   |
    When executing query:
      """
      /*+ SET_VAR(unwind_min_batch_size = 10000) */
      LET a = LIST['x', 'y', 'z']
      FOR i IN a WITH ORDINALITY idx
      RETURN i, idx
      """
    Then the result should be, in order:
      | i   | idx |
      | "x" | 1   |
      | "y" | 2   |
      | "z" | 3   |
    When executing query:
      """
      /*+ SET_VAR(unwind_min_batch_size = 1) */
      LET a = LIST[]
      FOR i IN a WITH ORDINALITY idx
      RETURN i, idx
      """
    Then the result should be, in order:
      | i | idx |

  Scenario: ForStatement with OFFSET - 0-based index
    When executing query:
      """
      /*+ SET_VAR(unwind_min_batch_size = 1) */
      LET a = LIST['x', 'y', 'z']
      FOR i IN a WITH OFFSET idx
      RETURN i, idx
      """
    Then the result should be, in order:
      | i   | idx |
      | "x" | 0   |
      | "y" | 1   |
      | "z" | 2   |
    When executing query:
      """
      /*+ SET_VAR(unwind_min_batch_size = 10000) */
      LET a = LIST['x', 'y', 'z']
      FOR i IN a WITH OFFSET idx
      RETURN i, idx
      """
    Then the result should be, in order:
      | i   | idx |
      | "x" | 0   |
      | "y" | 1   |
      | "z" | 2   |
    When executing query:
      """
      /*+ SET_VAR(unwind_min_batch_size = 1) */
      LET a = LIST[]
      FOR i IN a WITH OFFSET idx
      RETURN i, idx
      """
    Then the result should be, in order:
      | i | idx |

  Scenario: ForStatement with LIST and ORDINALITY/OFFSET - different batch sizes
    When executing query:
      """
      /*+ SET_VAR(unwind_min_batch_size = 1) */
      LET a = LIST[10, 20, 30]
      FOR i IN a WITH ORDINALITY idx
      RETURN i, idx
      """
    Then the result should be, in order:
      | i  | idx |
      | 10 | 1   |
      | 20 | 2   |
      | 30 | 3   |
    When executing query:
      """
      /*+ SET_VAR(unwind_min_batch_size = 10000) */
      LET a = LIST[10, 20, 30]
      FOR i IN a WITH OFFSET idx
      RETURN i, idx
      """
    Then the result should be, in order:
      | i  | idx |
      | 10 | 0   |
      | 20 | 1   |
      | 30 | 2   |

  Scenario: ForStatement with TABLE and ORDINALITY/OFFSET
    When executing query:
      """
      /*+ SET_VAR(unwind_min_batch_size = 1) */
      TABLE t TYPED TABLE {prop1 INT8} = {prop1:1}, {prop1:2}, {prop1:3}
      FOR rec IN t WITH ORDINALITY idx
      RETURN rec.prop1 AS prop1, idx
      """
    Then the result should be, in order:
      | prop1 | idx |
      | 1     | 1   |
      | 2     | 2   |
      | 3     | 3   |
    When executing query:
      """
      /*+ SET_VAR(unwind_min_batch_size = 10000) */
      TABLE t TYPED TABLE {prop1 INT8} = {prop1:1}, {prop1:2}, {prop1:3}
      FOR rec IN t WITH OFFSET idx
      RETURN rec.prop1 AS prop1, idx
      """
    Then the result should be, in order:
      | prop1 | idx |
      | 1     | 0   |
      | 2     | 1   |
      | 3     | 2   |

  Scenario: ForStatement with ORDINALITY/OFFSET and other projections
    When executing query:
      """
      /*+ SET_VAR(unwind_min_batch_size = 1) */
      LET items = LIST['a', 'b', 'c'], prefix = 'item_'
      FOR val IN items WITH ORDINALITY pos
      RETURN prefix || val AS name, pos
      """
    Then the result should be, in order:
      | name     | pos |
      | "item_a" | 1   |
      | "item_b" | 2   |
      | "item_c" | 3   |
    When executing query:
      """
      /*+ SET_VAR(unwind_min_batch_size = 1) */
      LET items = LIST['a', 'b', 'c']
      FOR val IN items WITH OFFSET idx
      FILTER idx > 0
      RETURN val, idx
      """
    Then the result should be, in order:
      | val | idx |
      | "b" | 1   |
      | "c" | 2   |

  Scenario: ForStatement with OFFSET - cross batch with concurrency
    # Test that OFFSET works correctly when data spans multiple batches with concurrent execution
    # range(0, 10239) generates 10240 elements which is greater than default batch size (1024)
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 2) */
      FOR i IN range(0, 10239) WITH OFFSET o
      RETURN i, o ORDER BY i DESC LIMIT 5
      """
    Then the result should be, in order:
      | i     | o     |
      | 10239 | 10239 |
      | 10238 | 10238 |
      | 10237 | 10237 |
      | 10236 | 10236 |
      | 10235 | 10235 |
    # Also test with ORDINALITY (1-based)
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 2) */
      FOR i IN range(0, 10239) WITH ORDINALITY o
      RETURN i, o ORDER BY i DESC LIMIT 5
      """
    Then the result should be, in order:
      | i     | o     |
      | 10239 | 10240 |
      | 10238 | 10239 |
      | 10237 | 10238 |
      | 10236 | 10237 |
      | 10235 | 10236 |

  Scenario: ForStatement with OFFSET - multiple rows with concurrency
    # Test OFFSET with multiple input rows to verify concurrent partition handling
    # Each row generates a separate list, and offset should be independent per list
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 2) */
      FOR row_idx IN range(0, 99)
      LET items = range(0, 99)
      FOR item IN items WITH OFFSET o
      RETURN row_idx, item, o ORDER BY row_idx, item LIMIT 10
      """
    Then the result should be, in order:
      | row_idx | item | o |
      | 0       | 0    | 0 |
      | 0       | 1    | 1 |
      | 0       | 2    | 2 |
      | 0       | 3    | 3 |
      | 0       | 4    | 4 |
      | 0       | 5    | 5 |
      | 0       | 6    | 6 |
      | 0       | 7    | 7 |
      | 0       | 8    | 8 |
      | 0       | 9    | 9 |
    # Verify offset is consistent at the end of each list
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 2) */
      FOR row_idx IN range(0, 99)
      LET items = range(0, 99)
      FOR item IN items WITH OFFSET o
      FILTER item = 99
      RETURN row_idx, item, o ORDER BY row_idx LIMIT 5
      """
    Then the result should be, in order:
      | row_idx | item | o  |
      | 0       | 99   | 99 |
      | 1       | 99   | 99 |
      | 2       | 99   | 99 |
      | 3       | 99   | 99 |
      | 4       | 99   | 99 |
