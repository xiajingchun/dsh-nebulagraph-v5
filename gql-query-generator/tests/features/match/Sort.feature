# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: Sort

  Scenario: NullOrder
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS sort_graph_type AS {
      NODE Person (LABEL PERSON {id INT64 PRIMARY KEY, age INT32})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS sort_graph TYPED sort_graph_type
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {id,age} =
      (1, 10),
      (2, 20),
      (3, null)
      USE sort_graph
      FOR r IN t
      INSERT
      (a@Person{id:r.id,age:r.age})
      """
    Then the execution should be successful
    When executing query:
      """
      USE sort_graph MATCH(v) ORDER BY v.age return v.id, v.age
      """
    Then the result should be, in any order:
      | v.id | v.age |
      | 1    | 10    |
      | 2    | 20    |
      | 3    | null  |
    When executing query:
      """
      USE sort_graph MATCH(v) ORDER BY v.age DESC NULLS FIRST return v.id, v.age
      """
    Then the result should be, in any order:
      | v.id | v.age |
      | 3    | null  |
      | 2    | 20    |
      | 1    | 10    |
    When executing query:
      """
      USE sort_graph MATCH(v) ORDER BY v.age DESC NULLS LAST return v.id, v.age
      """
    Then the result should be, in any order:
      | v.id | v.age |
      | 2    | 20    |
      | 1    | 10    |
      | 3    | null  |
    When executing query:
      """
      USE sort_graph MATCH(v) ORDER BY v.age DESC return v.id, v.age
      """
    Then the result should be, in any order:
      | v.id | v.age |
      | 3    | null  |
      | 2    | 20    |
      | 1    | 10    |
    When executing query:
      """
      USE sort_graph MATCH(v) ORDER BY v.age ASC NULLS FIRST return v.id, v.age
      """
    Then the result should be, in any order:
      | v.id | v.age |
      | 3    | null  |
      | 1    | 10    |
      | 2    | 20    |
    When executing query:
      """
      USE sort_graph MATCH(v) ORDER BY v.age ASC NULLS LAST return v.id, v.age
      """
    Then the result should be, in any order:
      | v.id | v.age |
      | 1    | 10    |
      | 2    | 20    |
      | 3    | null  |
    When executing query:
      """
      USE sort_graph MATCH(v) ORDER BY v.age ASC return v.id, v.age
      """
    Then the result should be, in any order:
      | v.id | v.age |
      | 1    | 10    |
      | 2    | 20    |
      | 3    | null  |
    And drop the graph "sort_graph"
    And drop the graph type "sort_graph_type"
