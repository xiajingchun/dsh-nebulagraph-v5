# Copyright (c) 2026 vesoft inc. All rights reserved.
Feature: SideEffect

  Scenario: Aggregator clear in invalid contexts
    # Test clear() on aggregator in RETURN statement
    When executing analytic query:
      """
      USE #analytic_ldbc {
        VALUE map_agg MapAgg<INT, SumAgg<INT>>
        RETURN @map_agg.clear()
      }
      """
    Then an Error should be raised: "[NS250]: Semantic error: Invalid side effect expression, `@map_agg.clear()` can only appear in set statement"
    # Test clear() on aggregator in LET statement
    When executing analytic query:
      """
      USE #analytic_ldbc {
        VALUE map_agg MapAgg<INT, SumAgg<INT>>
        LET x = @map_agg.clear()
        RETURN x
      }
      """
    Then an Error should be raised: "[NS250]: Semantic error: Invalid side effect expression, `@map_agg.clear()` can only appear in set statement"
    # Test clear() on aggregator in EXPORT INTO
    When executing analytic query:
      """
      USE #analytic_ldbc {
        VALUE map_agg MapAgg<INT, SumAgg<INT>>
        TABLE result_table TYPED TABLE {id INT, val INT}
        MATCH (a@Person)
        PER NODE (a) {
          EXPORT a.id, @map_agg.clear() INTO result_table
        }
        FOR rec IN result_table
        RETURN rec.id
      }
      """
    Then an Error should be raised: "[NS238]: Invalid match compute block: GLOBAL aggregator mutable member function `@map_agg.clear()` is not allowed in the PER NODE clause"

  Scenario: Table clear in invalid contexts
    # Test clear() on table in RETURN statement
    When executing query:
      """
      TABLE t TYPED TABLE {id INT} = {id:1}, {id:2}
      RETURN clear(t)
      """
    Then an Error should be raised: "[NS250]: Semantic error: Invalid side effect expression, `clear(t)` can only appear in set statement"
    # Test clear() on table in LET statement
    When executing query:
      """
      TABLE t {id, name} = (1, "a"), (2, "b")
      LET x = clear(t)
      RETURN x
      """
    Then an Error should be raised: "[NS250]: Semantic error: Invalid side effect expression, `clear(t)` can only appear in set statement"
    # Test clear() on table in FILTER statement
    When executing query:
      """
      TABLE t TYPED TABLE {id INT, name STRING}
      TABLE t2 {id} = (1), (2), (3)
      FOR rec IN t2
      FILTER clear(t) = 0
      RETURN rec.id
      """
    Then an Error should be raised: "[NS250]: Semantic error: Invalid side effect expression, `clear(t)` can only appear in set statement"
    # Test clear() on table in WHERE clause
    When executing query:
      """
      TABLE t {id} = (1), (2), (3)
      USE ldbc
      MATCH (a@Person)
      WHERE clear(t) = 0
      RETURN a.id
      """
    Then an Error should be raised: "[NS250]: Semantic error: Invalid side effect expression, `clear(t)` can only appear in set statement"
    # Test clear() on table in EXPORT INTO
    When executing analytic query:
      """
      USE #analytic_ldbc {
        TABLE t TYPED TABLE {id INT, name STRING} = {id:1, name:"old"}
        TABLE t2 {id, name} = (10, "new1"), (20, "new2")
        MATCH (a@Person)
        PER NODE (a) {
          EXPORT a.id, clear(t2) INTO t
        }
        FOR rec IN t
        RETURN rec.name
      }
      """
    Then an Error should be raised: "[NS250]: Semantic error: Invalid side effect expression, `clear(t2)` can only appear in set statement"
    # Test clear() on table in FOR loop condition
    When executing query:
      """
      TABLE t {id} = (1), (2)
      TABLE result {val} = (10)
      FOR rec IN t
      FILTER clear(result) = 0
      RETURN rec.id
      """
    Then an Error should be raised: "[NS250]: Semantic error: Invalid side effect expression, `clear(result)` can only appear in set statement"
    # Test clear() on table in IF condition
    When executing query:
      """
      TABLE t {id} = (1), (2), (3)
      IF clear(t) = 0 THEN {
        RETURN 1 AS x
      } ELSE {
        RETURN 0 AS x
      }
      """
    Then an Error should be raised: "[NS250]: Semantic error: Invalid side effect expression, `clear(t)` can only appear in set statement"
    # Test clear() on table in WHILE condition
    When executing query:
      """
      TABLE t {id} = (1), (2), (3)
      WHILE clear(t) = 0 THEN {
        SET t.clear()
      }
      FINISH
      """
    Then an Error should be raised: "[NS250]: Semantic error: Invalid side effect expression, `clear(t)` can only appear in set statement"

  Scenario: Valid clear usage in SET statement
    # Test clear() on aggregator in SET statement (should succeed)
    When executing analytic query:
      """
      USE #analytic_ldbc {
        VALUE map_agg MapAgg<INT, SumAgg<INT>>
        SET @map_agg += TUPLE(1, 1)
        SET @map_agg.clear()
        RETURN size(@map_agg) AS sz
      }
      """
    Then the result should be, in any order:
      | sz |
      | 0  |
    # Test clear() on aggregator in IF body (should succeed)
    When executing analytic query:
      """
      USE #analytic_ldbc {
        VALUE map_agg MapAgg<INT, SumAgg<INT>>
        SET @map_agg += TUPLE(1, 1)
        IF true THEN {
          SET @map_agg.clear()
        }
        RETURN size(@map_agg) AS sz
      }
      """
    Then the result should be, in any order:
      | sz |
      | 0  |
    # Test clear() on aggregator in WHILE body (should succeed)
    When executing analytic query:
      """
      USE #analytic_ldbc {
        VALUE map_agg MapAgg<INT, SumAgg<INT>>
        VALUE iter = 0
        SET @map_agg += TUPLE(1, 1)
        WHILE iter < 1 THEN {
          SET @map_agg.clear()
          SET iter = iter + 1
        }
        RETURN size(@map_agg) AS sz
      }
      """
    Then the result should be, in any order:
      | sz |
      | 0  |
    # Test clear() on table in SET statement (should succeed)
    When executing query:
      """
      TABLE t TYPED TABLE {id INT} = {id:1}, {id:2}, {id:3}
      SET t.clear()
      RETURN size(t) AS sz
      """
    Then the result should be, in any order:
      | sz |
      | 0  |
