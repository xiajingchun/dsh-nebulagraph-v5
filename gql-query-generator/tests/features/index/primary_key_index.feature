# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: PrimaryKeyIndex

  Scenario: single pk and composite pk
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS pk_index_type AS {
        NODE Person (LABELS Person {id INT PRIMARY KEY}),
        NODE Employee (LABELS Employee&Person {id INT, name STRING, PRIMARY KEY(id,name)})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS pk_index_graph TYPED pk_index_type
      """
    Then the execution should be successful
    And graph "pk_index_graph" should be ready to use
    When executing query:
      """
      use pk_index_graph insert (:Employee&Person{id:1, name:"doodle"})
      """
    Then the execution should be successful
    When executing query:
      """
      use pk_index_graph insert (:Person{id:2})
      """
    Then the execution should be successful
    When executing query:
      """
      use pk_index_graph match (v{id:1}) return v.id as id
      """
    Then the result should be, in any order:
      | id |
      | 1  |
    When executing query:
      """
      use pk_index_graph match (v{id:2}) return v.id as id
      """
    Then the result should be, in any order:
      | id |
      | 2  |
    When executing query:
      """
      use pk_index_graph match (v:Employee{id:1}) return v.id as id
      """
    Then the result should be, in any order:
      | id |
      | 1  |
    When executing query:
      """
      use pk_index_graph match (v:Person{id:1}) return v.id as id
      """
    Then the result should be, in any order:
      | id |
      | 1  |
    When executing query:
      """
      use pk_index_graph match (v:Person{id:2}) return v.id as id
      """
    Then the result should be, in any order:
      | id |
      | 2  |
    And drop the graph "pk_index_graph"
    And drop the graph type "pk_index_type"
