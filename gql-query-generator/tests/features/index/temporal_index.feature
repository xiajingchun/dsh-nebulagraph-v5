# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: TemporalIndex

  Scenario: date index
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS date_index_graph_type AS {
        NODE node_type_date (LABEL player {id INT PRIMARY KEY, period DATE})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS date_index_graph TYPED date_index_graph_type
      """
    Then the execution should be successful
    And graph "date_index_graph" should be ready to use
    When executing query:
      """
      USE date_index_graph CREATE INDEX IF NOT EXISTS i_date ON NODE node_type_date(period)
      """
    Then the execution should be successful
    When executing query:
      """
      USE date_index_graph INSERT
      (@node_type_date{id: 1, period: date("1970-01-01", "%Y-%m-%d")}),
      (@node_type_date{id: 2, period: date("1999-01-01", "%Y-%m-%d")}),
      (@node_type_date{id: 3, period: date("1999-12-30", "%Y-%m-%d")}),
      (@node_type_date{id: 4, period: date("1999-12-31", "%Y-%m-%d")}),
      (@node_type_date{id: 5, period: date("2000-01-01", "%Y-%m-%d")}),
      (@node_type_date{id: 6, period: date("2022-04-28", "%Y-%m-%d")}),
      (@node_type_date{id: 7, period: NULL})
      """
    Then the execution should be successful
    When executing query:
      """
      USE date_index_graph
      MATCH (v:player {period:date("1999-12-31", "%Y-%m-%d")})
      RETURN v.id AS id, v.period AS period
      """
    Then the result should be, in any order:
      | id | period            |
      | 4  | DATE '1999-12-31' |
    And the plan should contain "IndexScan"
    And the plan should contain "index: i_date"
    When executing query:
      """
      USE date_index_graph
      MATCH (v:player) WHERE v.period = date("1999-12-31", "%Y-%m-%d") or v.period = date("2022-04-28", "%Y-%m-%d")
      RETURN v.id AS id, v.period AS period
      """
    Then the result should be, in any order:
      | id | period            |
      | 4  | DATE '1999-12-31' |
      | 6  | DATE '2022-04-28' |
    And the plan should contain "IndexScan"
    And the plan should contain "index: i_date"
    When executing query:
      """
      USE date_index_graph
      MATCH (v:player) WHERE v.period <> date("1999-12-31", "%Y-%m-%d") and v.period <> date("2022-04-28", "%Y-%m-%d")
      RETURN v.id AS id, v.period AS period
      """
    Then the result should be, in any order:
      | id | period            |
      | 1  | DATE '1970-01-01' |
      | 2  | DATE '1999-01-01' |
      | 3  | DATE '1999-12-30' |
      | 5  | DATE '2000-01-01' |
    And the plan should contain "IndexScan"
    And the plan should contain "index: i_date"
    When executing query:
      """
      USE date_index_graph
      MATCH (v:player) WHERE v.period IS NULL
      RETURN v.id AS id, v.period AS period
      """
    Then the result should be, in any order:
      | id | period |
      | 7  | NULL   |
    And the plan should contain "IndexScan"
    And the plan should contain "index: i_date"
    When executing query:
      """
      USE date_index_graph
      MATCH (v:player) WHERE v.period IS NOT NULL
      RETURN v.id AS id, v.period AS period
      """
    Then the result should be, in any order:
      | id | period            |
      | 1  | DATE '1970-01-01' |
      | 2  | DATE '1999-01-01' |
      | 3  | DATE '1999-12-30' |
      | 4  | DATE '1999-12-31' |
      | 5  | DATE '2000-01-01' |
      | 6  | DATE '2022-04-28' |
    And the plan should contain "IndexScan"
    And the plan should contain "index: i_date"
    When executing query:
      """
      USE date_index_graph
      MATCH (v:player) WHERE v.period < date("2000-01-01", "%Y-%m-%d")
      RETURN v.id AS id, v.period AS period
      """
    Then the result should be, in any order:
      | id | period            |
      | 1  | DATE '1970-01-01' |
      | 2  | DATE '1999-01-01' |
      | 3  | DATE '1999-12-30' |
      | 4  | DATE '1999-12-31' |
    And the plan should contain "IndexScan"
    And the plan should contain "index: i_date"
    When executing query:
      """
      USE date_index_graph
      MATCH (v:player) WHERE v.period <= date("2000-01-01", "%Y-%m-%d")
      RETURN v.id AS id, v.period AS period
      """
    Then the result should be, in any order:
      | id | period            |
      | 1  | DATE '1970-01-01' |
      | 2  | DATE '1999-01-01' |
      | 3  | DATE '1999-12-30' |
      | 4  | DATE '1999-12-31' |
      | 5  | DATE '2000-01-01' |
    And the plan should contain "IndexScan"
    And the plan should contain "index: i_date"
    When executing query:
      """
      USE date_index_graph
      MATCH (v:player) WHERE v.period > date("1999-12-31", "%Y-%m-%d")
      RETURN v.id AS id, v.period AS period
      """
    Then the result should be, in any order:
      | id | period            |
      | 5  | DATE '2000-01-01' |
      | 6  | DATE '2022-04-28' |
    And the plan should contain "IndexScan"
    And the plan should contain "index: i_date"
    When executing query:
      """
      USE date_index_graph
      MATCH (v:player) WHERE v.period >= date("1999-12-31", "%Y-%m-%d")
      RETURN v.id AS id, v.period AS period
      """
    Then the result should be, in any order:
      | id | period            |
      | 4  | DATE '1999-12-31' |
      | 5  | DATE '2000-01-01' |
      | 6  | DATE '2022-04-28' |
    And the plan should contain "IndexScan"
    And the plan should contain "index: i_date"
    When executing query:
      """
      USE date_index_graph
      MATCH (v:player) WHERE v.period >= date("1999-12-31", "%Y-%m-%d") and v.period <= date("2000-01-01", "%Y-%m-%d")
      RETURN v.id AS id, v.period AS period
      """
    Then the result should be, in any order:
      | id | period            |
      | 4  | DATE '1999-12-31' |
      | 5  | DATE '2000-01-01' |
    And the plan should contain "IndexScan"
    And the plan should contain "index: i_date"
    When executing query:
      """
      USE date_index_graph
      MATCH (v:player) WHERE v.period >= date("1999-12-31", "%Y-%m-%d") and v.period < date("2000-01-01", "%Y-%m-%d")
      RETURN v.id AS id, v.period AS period
      """
    Then the result should be, in any order:
      | id | period            |
      | 4  | DATE '1999-12-31' |
    And the plan should contain "IndexScan"
    And the plan should contain "index: i_date"
    When executing query:
      """
      USE date_index_graph
      MATCH (v:player) WHERE v.period > date("1999-12-31", "%Y-%m-%d") and v.period <= date("2000-01-01", "%Y-%m-%d")
      RETURN v.id AS id, v.period AS period
      """
    Then the result should be, in any order:
      | id | period            |
      | 5  | DATE '2000-01-01' |
    And the plan should contain "IndexScan"
    And the plan should contain "index: i_date"
    When executing query:
      """
      USE date_index_graph
      MATCH (v:player) WHERE v.period > date("1999-12-31", "%Y-%m-%d") and v.period < date("2000-01-01", "%Y-%m-%d")
      RETURN v.id AS id, v.period AS period
      """
    Then the result should be, in any order:
      | id | period |
    And drop the index "i_date" of "date_index_graph"
    And drop the graph "date_index_graph"
    And drop the graph type "date_index_graph_type"

  Scenario: local date time index
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS local_date_time_index_graph_type AS {
        NODE node_type_local_date_time (LABEL player {id INT PRIMARY KEY, period LOCAL DATETIME})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS local_date_time_index_graph TYPED local_date_time_index_graph_type
      """
    Then the execution should be successful
    And graph "local_date_time_index_graph" should be ready to use
    When executing query:
      """
      USE local_date_time_index_graph CREATE INDEX IF NOT EXISTS i_date ON NODE node_type_local_date_time(period)
      """
    Then the execution should be successful
    When executing query:
      """
      USE local_date_time_index_graph INSERT
      (@node_type_local_date_time{id: 1, period: local_datetime("1970-01-01T00:00:00.000000", "%Y-%m-%dT%H:%M:%S")}),
      (@node_type_local_date_time{id: 2, period: local_datetime("1999-12-31T23:59:59.000000", "%Y-%m-%dT%H:%M:%S")}),
      (@node_type_local_date_time{id: 3, period: local_datetime("1999-12-31T23:59:59.999999", "%Y-%m-%dT%H:%M:%S")}),
      (@node_type_local_date_time{id: 4, period: local_datetime("2000-01-01T00:00:00.000000", "%Y-%m-%dT%H:%M:%S")}),
      (@node_type_local_date_time{id: 5, period: local_datetime("2000-01-01T00:00:01.000000", "%Y-%m-%dT%H:%M:%S")}),
      (@node_type_local_date_time{id: 6, period: local_datetime("2022-04-28T23:40:01.234567", "%Y-%m-%dT%H:%M:%S")}),
      (@node_type_local_date_time{id: 7, period: NULL})
      """
    Then the execution should be successful
    When executing query:
      """
      USE local_date_time_index_graph
      MATCH (v:player {period:local_datetime("2000-01-01T00:00:00.000000", "%Y-%m-%dT%H:%M:%S")})
      RETURN v.id AS id, v.period AS period
      """
    Then the result should be, in any order:
      | id | period                                |
      | 4  | DATETIME "2000-01-01T00:00:00.000000" |
    And the plan should contain "IndexScan"
    And the plan should contain "index: i_date"
    When executing query:
      """
      USE local_date_time_index_graph
      MATCH (v:player) WHERE v.period = local_datetime("2000-01-01T00:00:00.000000", "%Y-%m-%dT%H:%M:%S") or v.period = local_datetime("2022-04-28T23:40:01.234567", "%Y-%m-%dT%H:%M:%S")
      RETURN v.id AS id, v.period AS period
      """
    Then the result should be, in any order:
      | id | period                                |
      | 4  | DATETIME "2000-01-01T00:00:00.000000" |
      | 6  | DATETIME "2022-04-28T23:40:01.234567" |
    And the plan should contain "IndexScan"
    And the plan should contain "index: i_date"
    When executing query:
      """
      USE local_date_time_index_graph
      MATCH (v:player) WHERE v.period <> local_datetime("2000-01-01T00:00:00.000000", "%Y-%m-%dT%H:%M:%S") and v.period <> local_datetime("2022-04-28T23:40:01.234567", "%Y-%m-%dT%H:%M:%S")
      RETURN v.id AS id, v.period AS period
      """
    Then the result should be, in any order:
      | id | period                                |
      | 1  | DATETIME "1970-01-01T00:00:00.000000" |
      | 2  | DATETIME "1999-12-31T23:59:59.000000" |
      | 3  | DATETIME "1999-12-31T23:59:59.999999" |
      | 5  | DATETIME "2000-01-01T00:00:01.000000" |
    And the plan should contain "IndexScan"
    And the plan should contain "index: i_date"
    When executing query:
      """
      USE local_date_time_index_graph
      MATCH (v:player) WHERE v.period IS NULL
      RETURN v.id AS id, v.period AS period
      """
    Then the result should be, in any order:
      | id | period |
      | 7  | NULL   |
    And the plan should contain "IndexScan"
    And the plan should contain "index: i_date"
    When executing query:
      """
      USE local_date_time_index_graph
      MATCH (v:player) WHERE v.period IS NOT NULL
      RETURN v.id AS id, v.period AS period
      """
    Then the result should be, in any order:
      | id | period                                |
      | 1  | DATETIME "1970-01-01T00:00:00.000000" |
      | 2  | DATETIME "1999-12-31T23:59:59.000000" |
      | 3  | DATETIME "1999-12-31T23:59:59.999999" |
      | 4  | DATETIME "2000-01-01T00:00:00.000000" |
      | 5  | DATETIME "2000-01-01T00:00:01.000000" |
      | 6  | DATETIME "2022-04-28T23:40:01.234567" |
    And the plan should contain "IndexScan"
    And the plan should contain "index: i_date"
    When executing query:
      """
      USE local_date_time_index_graph
      MATCH (v:player) WHERE v.period < local_datetime("2000-01-01T00:00:01.000000", "%Y-%m-%dT%H:%M:%S")
      RETURN v.id AS id, v.period AS period
      """
    Then the result should be, in any order:
      | id | period                                |
      | 1  | DATETIME "1970-01-01T00:00:00.000000" |
      | 2  | DATETIME "1999-12-31T23:59:59.000000" |
      | 3  | DATETIME "1999-12-31T23:59:59.999999" |
      | 4  | DATETIME "2000-01-01T00:00:00.000000" |
    And the plan should contain "IndexScan"
    And the plan should contain "index: i_date"
    When executing query:
      """
      USE local_date_time_index_graph
      MATCH (v:player) WHERE v.period <= local_datetime("2000-01-01T00:00:01.000000", "%Y-%m-%dT%H:%M:%S")
      RETURN v.id AS id, v.period AS period
      """
    Then the result should be, in any order:
      | id | period                                |
      | 1  | DATETIME "1970-01-01T00:00:00.000000" |
      | 2  | DATETIME "1999-12-31T23:59:59.000000" |
      | 3  | DATETIME "1999-12-31T23:59:59.999999" |
      | 4  | DATETIME "2000-01-01T00:00:00.000000" |
      | 5  | DATETIME "2000-01-01T00:00:01.000000" |
    And the plan should contain "IndexScan"
    And the plan should contain "index: i_date"
    When executing query:
      """
      USE local_date_time_index_graph
      MATCH (v:player) WHERE v.period > local_datetime("1999-12-31T23:59:59.999999", "%Y-%m-%dT%H:%M:%S")
      RETURN v.id AS id, v.period AS period
      """
    Then the result should be, in any order:
      | id | period                                |
      | 4  | DATETIME "2000-01-01T00:00:00.000000" |
      | 5  | DATETIME "2000-01-01T00:00:01.000000" |
      | 6  | DATETIME "2022-04-28T23:40:01.234567" |
    And the plan should contain "IndexScan"
    And the plan should contain "index: i_date"
    When executing query:
      """
      USE local_date_time_index_graph
      MATCH (v:player) WHERE v.period >= local_datetime("1999-12-31T23:59:59.999999", "%Y-%m-%dT%H:%M:%S")
      RETURN v.id AS id, v.period AS period
      """
    Then the result should be, in any order:
      | id | period                                |
      | 3  | DATETIME "1999-12-31T23:59:59.999999" |
      | 4  | DATETIME "2000-01-01T00:00:00.000000" |
      | 5  | DATETIME "2000-01-01T00:00:01.000000" |
      | 6  | DATETIME "2022-04-28T23:40:01.234567" |
    And the plan should contain "IndexScan"
    And the plan should contain "index: i_date"
    When executing query:
      """
      USE local_date_time_index_graph
      MATCH (v:player) WHERE v.period >= local_datetime("1999-12-31T23:59:59.000000", "%Y-%m-%dT%H:%M:%S") and v.period <= local_datetime("2000-01-01T00:00:00.000000", "%Y-%m-%dT%H:%M:%S")
      RETURN v.id AS id, v.period AS period
      """
    Then the result should be, in any order:
      | id | period                                |
      | 2  | DATETIME "1999-12-31T23:59:59.000000" |
      | 3  | DATETIME "1999-12-31T23:59:59.999999" |
      | 4  | DATETIME "2000-01-01T00:00:00.000000" |
    And the plan should contain "IndexScan"
    And the plan should contain "index: i_date"
    When executing query:
      """
      USE local_date_time_index_graph
      MATCH (v:player) WHERE v.period >= local_datetime("1999-12-31T23:59:59.000000", "%Y-%m-%dT%H:%M:%S") and v.period < local_datetime("2000-01-01T00:00:00.000000", "%Y-%m-%dT%H:%M:%S")
      RETURN v.id AS id, v.period AS period
      """
    Then the result should be, in any order:
      | id | period                                |
      | 2  | DATETIME "1999-12-31T23:59:59.000000" |
      | 3  | DATETIME "1999-12-31T23:59:59.999999" |
    And the plan should contain "IndexScan"
    And the plan should contain "index: i_date"
    When executing query:
      """
      USE local_date_time_index_graph
      MATCH (v:player) WHERE v.period > local_datetime("1999-12-31T23:59:59.000000", "%Y-%m-%dT%H:%M:%S") and v.period <= local_datetime("2000-01-01T00:00:00.000000", "%Y-%m-%dT%H:%M:%S")
      RETURN v.id AS id, v.period AS period
      """
    Then the result should be, in any order:
      | id | period                                |
      | 3  | DATETIME "1999-12-31T23:59:59.999999" |
      | 4  | DATETIME "2000-01-01T00:00:00.000000" |
    And the plan should contain "IndexScan"
    And the plan should contain "index: i_date"
    When executing query:
      """
      USE local_date_time_index_graph
      MATCH (v:player) WHERE v.period > local_datetime("1999-12-31T23:59:59.000000", "%Y-%m-%dT%H:%M:%S") and v.period < local_datetime("2000-01-01T00:00:00.000000", "%Y-%m-%dT%H:%M:%S")
      RETURN v.id AS id, v.period AS period
      """
    Then the result should be, in any order:
      | id | period                                |
      | 3  | DATETIME "1999-12-31T23:59:59.999999" |
    And the plan should contain "IndexScan"
    And the plan should contain "index: i_date"
    And drop the index "i_date" of "local_date_time_index_graph"
    And drop the graph "local_date_time_index_graph"
    And drop the graph type "local_date_time_index_graph_type"
