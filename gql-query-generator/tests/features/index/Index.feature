# Copyright (c) 2022 vesoft inc. All rights reserved.
Feature: Index

  Scenario: create index
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS index_graph_type AS {
        NODE node_type_player ( LABEL player {id INT PRIMARY KEY, name STRING, vec VECTOR<3, float>}),
        EDGE edge_type_follow (node_type_player)-[ LABEL follow {followness INT, age INT, since LOCAL DATETIME, vec VECTOR<3, float>}]->(node_type_player)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS index_graph TYPED index_graph_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_graph CREATE INDEX IF NOT EXISTS i_player_single ON NODE node_type_player(name)
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_graph CREATE INDEX IF NOT EXISTS i_player_complex ON NODE node_type_player(name ASC, id)
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_graph CREATE INDEX IF NOT EXISTS i_follow_single ON EDGE edge_type_follow(followness)
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_graph CREATE INDEX IF NOT EXISTS i_follow_complex ON EDGE edge_type_follow(followness ASC, age)
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_graph CREATE INDEX IF NOT EXISTS i_follow_since ON EDGE edge_type_follow(since)
      """
    Then the execution should be successful
    And drop the index "i_follow_since" of "index_graph"
    And drop the index "i_follow_complex" of "index_graph"
    And drop the index "i_follow_single" of "index_graph"
    And drop the index "i_player_complex" of "index_graph"
    And drop the index "i_player_single" of "index_graph"
    And drop the graph "index_graph"
    And drop the graph type "index_graph_type"

  Scenario: drop index
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS drop_index_graph_type AS {
        NODE node_type_player ( LABEL player {id INT PRIMARY KEY, name STRING}),
        EDGE edge_type_follow (node_type_player)-[ LABEL follow {followness INT, age INT, since LOCAL DATETIME}]->(node_type_player)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS drop_index_graph TYPED drop_index_graph_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE drop_index_graph CREATE INDEX IF NOT EXISTS i_player_single ON NODE node_type_player(name)
      """
    Then the execution should be successful
    When executing query:
      """
      USE drop_index_graph CREATE INDEX IF NOT EXISTS `match` ON NODE node_type_player(name)
      """
    Then the execution should be successful
    When executing query:
      """
      USE drop_index_graph DROP INDEX i_player_single
      """
    Then the execution should be successful
    When executing query:
      """
      USE drop_index_graph DROP INDEX i_player_single
      """
    Then an Error should be raised: "[NC007]: Catalog index not found: `i_player_single`"
    When executing query:
      """
      USE drop_index_graph DROP INDEX IF EXISTS i_player_single
      """
    Then the execution should be successful
    And drop the graph "drop_index_graph"
    And drop the graph type "drop_index_graph_type"

  Scenario: create duplicated index
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS index_dup_graph_type AS {
        NODE node_type_player ( LABEL player {id INT PRIMARY KEY, name STRING}),
        EDGE edge_type_follow (node_type_player)-[ LABEL follow {followness INT, age INT, since LOCAL DATETIME}]->(node_type_player)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS index_dup_graph TYPED index_dup_graph_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_dup_graph CREATE INDEX i_player_single ON NODE node_type_player(name, name)
      """
    Then an Error should be raised: "[42N27]: Invalid syntax, duplicate index property names in `i_player_single`"
    When executing query:
      """
      USE index_dup_graph CREATE INDEX i_player_single ON NODE node_type_player(name)
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_dup_graph CREATE INDEX i_player_single ON NODE node_type_player(name)
      """
    Then an Error should be raised: "[NC107]: Node index already exists: i_player_single"
    When executing query:
      """
      USE index_dup_graph CREATE INDEX i_player_single ON NODE node_type_player(id, name)
      """
    Then an Error should be raised: "[NC107]: Node index already exists: i_player_single"
    # When executing query:
    # """
    # USE index_dup_graph CREATE INDEX IF NOT EXISTS i_player_single ON NODE node_type_player(name)
    # """
    # Then the execution should be successful
    # When executing query:
    # """
    # USE index_dup_graph CREATE INDEX IF NOT EXISTS i_player_single ON NODE node_type_player(id, name)
    # """
    # Then the execution should be successful
    # When executing query:
    # """
    # USE index_dup_graph CREATE INDEX IF NOT EXISTS i_player_single ON EDGE edge_type_follow(followness)
    # """
    # Then the execution should be successful
    When executing query:
      """
      USE index_dup_graph CREATE INDEX `test` ON EDGE edge_type_follow(followness)
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_dup_graph CREATE INDEX i_follow_single ON EDGE edge_type_follow(followness, followness)
      """
    Then an Error should be raised: "[42N27]: Invalid syntax, duplicate index property names in `i_follow_single`"
    When executing query:
      """
      USE index_dup_graph CREATE INDEX i_follow_single ON EDGE edge_type_follow(followness)
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_dup_graph CREATE INDEX i_follow_single ON EDGE edge_type_follow(followness)
      """
    Then an Error should be raised: "[NC108]: Edge index already exists: i_follow_single"
    When executing query:
      """
      USE index_dup_graph CREATE INDEX i_follow_single ON EDGE edge_type_follow(followness, age)
      """
    Then an Error should be raised: "[NC108]: Edge index already exists: i_follow_single"
    # When executing query:
    # """
    # CREATE INDEX IF NOT EXISTS i_follow_single FOR ()-[e:edge_type_follow]-() TYPED index_dup_graph ON (e.followness)
    # """
    # Then the execution should be successful
    # When executing query:
    # """
    # CREATE INDEX IF NOT EXISTS i_follow_single FOR ()-[e:edge_type_follow]-() TYPED index_dup_graph ON (e.followness, e.age)
    # """
    # Then the execution should be successful
    And drop the index "i_player_single" of "index_dup_graph"
    And drop the index "i_follow_single" of "index_dup_graph"
    And drop the graph "index_dup_graph"
    And drop the graph type "index_dup_graph_type"

  Scenario: query with index
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS index_query_type_9527 AS {
        NODE person ( LABEL person {id INT PRIMARY KEY, name STRING, age INT32, gender bool, money DOUBLE, score INT, luckyTime LOCAL DATETIME, vec VECTOR<3, float>}),
        NODE city ( LABEL city {id INT PRIMARY KEY, name STRING, vec VECTOR<3, float>}),
        EDGE follow (person)-[ LABEL follow {followness INT, vec1 VECTOR<2, float>}]->(person)
      }
      """
    Then the execution should be successful
    # And graph type "index_query_type_9527" should be ready to use
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS index_query_graph TYPED index_query_type_9527
      """
    Then the execution should be successful
    # And graph "index_query_graph" should be ready to use
    When executing query:
      """
      USE index_query_graph CREATE INDEX IF NOT EXISTS person_name_idx ON NODE person(name)
      """
    Then the execution should be successful
    And index "person_name_idx" of "index_query_graph" should be ready to use
    When executing query:
      """
      USE index_query_graph CREATE INDEX IF NOT EXISTS person_age_idx ON NODE person(age)
      """
    Then the execution should be successful
    And index "person_age_idx" of "index_query_graph" should be ready to use
    When executing query:
      """
      USE index_query_graph CREATE INDEX IF NOT EXISTS person_gender_idx ON NODE person(gender)
      """
    Then the execution should be successful
    And index "person_gender_idx" of "index_query_graph" should be ready to use
    When executing query:
      """
      USE index_query_graph CREATE INDEX IF NOT EXISTS person_money_idx ON NODE person(money)
      """
    Then the execution should be successful
    And index "person_money_idx" of "index_query_graph" should be ready to use
    When executing query:
      """
      USE index_query_graph CREATE INDEX IF NOT EXISTS person_score_desc_idx ON NODE person(score DESC)
      """
    Then the execution should be successful
    And index "person_score_desc_idx" of "index_query_graph" should be ready to use
    When executing query:
      """
      USE index_query_graph CREATE INDEX IF NOT EXISTS person_luckyTime_idx ON NODE person(luckyTime)
      """
    Then the execution should be successful
    And index "person_luckyTime_idx" of "index_query_graph" should be ready to use
    When executing query:
      """
      USE index_query_graph CREATE INDEX IF NOT EXISTS person_name_asc_age_asc_idx ON NODE person(name, age)
      """
    Then the execution should be successful
    And index "person_name_asc_age_asc_idx" of "index_query_graph" should be ready to use
    When executing query:
      """
      USE index_query_graph CREATE INDEX IF NOT EXISTS person_age_desc_score_asc_idx ON NODE person(age DESC, score ASC)
      """
    Then the execution should be successful
    And index "person_age_desc_score_asc_idx" of "index_query_graph" should be ready to use
    When executing query:
      """
      USE index_query_graph CREATE INDEX IF NOT EXISTS person_age_money_idx ON NODE person(age, money)
      """
    Then the execution should be successful
    And index "person_age_money_idx" of "index_query_graph" should be ready to use
    When executing query:
      """
      USE index_query_graph CREATE INDEX IF NOT EXISTS city_name_idx ON NODE city(name)
      """
    Then the execution should be successful
    And index "city_name_idx" of "index_query_graph" should be ready to use
    When executing query:
      """
      USE index_query_graph CREATE INDEX IF NOT EXISTS follow_followness ON EDGE follow(followness)
      """
    Then the execution should be successful
    And index "follow_followness" of "index_query_graph" should be ready to use
    When executing query:
      """
      CALL show_indexes("index_query_graph")
      RETURN name, state, index_type, graph_name, entity_type, element_type, properties
      """
    Then the result should be, in any order:
      | name                            | state   | index_type | graph_name          | entity_type | element_type | properties                    |
      | "city_name_idx"                 | "Valid" | "Normal"   | "index_query_graph" | "Node"      | "city"       | LIST ["name ASC"]             |
      | "person_age_desc_score_asc_idx" | "Valid" | "Normal"   | "index_query_graph" | "Node"      | "person"     | LIST ["age DESC","score ASC"] |
      | "person_luckyTime_idx"          | "Valid" | "Normal"   | "index_query_graph" | "Node"      | "person"     | LIST ["luckyTime ASC"]        |
      | "person_money_idx"              | "Valid" | "Normal"   | "index_query_graph" | "Node"      | "person"     | LIST ["money ASC"]            |
      | "person_age_idx"                | "Valid" | "Normal"   | "index_query_graph" | "Node"      | "person"     | LIST ["age ASC"]              |
      | "person_name_idx"               | "Valid" | "Normal"   | "index_query_graph" | "Node"      | "person"     | LIST ["name ASC"]             |
      | "person_gender_idx"             | "Valid" | "Normal"   | "index_query_graph" | "Node"      | "person"     | LIST ["gender ASC"]           |
      | "person_score_desc_idx"         | "Valid" | "Normal"   | "index_query_graph" | "Node"      | "person"     | LIST ["score DESC"]           |
      | "person_name_asc_age_asc_idx"   | "Valid" | "Normal"   | "index_query_graph" | "Node"      | "person"     | LIST ["name ASC","age ASC"]   |
      | "person_age_money_idx"          | "Valid" | "Normal"   | "index_query_graph" | "Node"      | "person"     | LIST ["age ASC","money ASC"]  |
      | "follow_followness"             | "Valid" | "Normal"   | "index_query_graph" | "Edge"      | "follow"     | LIST ["followness ASC"]       |
    When executing query:
      """
      USE index_query_graph SHOW INDEXES
      """
    Then the result should be, in any order:
      | name                            | state   | index_type | schema            | graph_name          | entity_type | element_type | properties                    |
      | "city_name_idx"                 | "Valid" | "Normal"   | "/default_schema" | "index_query_graph" | "Node"      | "city"       | LIST ["name ASC"]             |
      | "person_age_money_idx"          | "Valid" | "Normal"   | "/default_schema" | "index_query_graph" | "Node"      | "person"     | LIST ["age ASC","money ASC"]  |
      | "person_age_desc_score_asc_idx" | "Valid" | "Normal"   | "/default_schema" | "index_query_graph" | "Node"      | "person"     | LIST ["age DESC","score ASC"] |
      | "person_name_asc_age_asc_idx"   | "Valid" | "Normal"   | "/default_schema" | "index_query_graph" | "Node"      | "person"     | LIST ["name ASC","age ASC"]   |
      | "person_luckyTime_idx"          | "Valid" | "Normal"   | "/default_schema" | "index_query_graph" | "Node"      | "person"     | LIST ["luckyTime ASC"]        |
      | "person_name_idx"               | "Valid" | "Normal"   | "/default_schema" | "index_query_graph" | "Node"      | "person"     | LIST ["name ASC"]             |
      | "person_age_idx"                | "Valid" | "Normal"   | "/default_schema" | "index_query_graph" | "Node"      | "person"     | LIST ["age ASC"]              |
      | "person_gender_idx"             | "Valid" | "Normal"   | "/default_schema" | "index_query_graph" | "Node"      | "person"     | LIST ["gender ASC"]           |
      | "person_money_idx"              | "Valid" | "Normal"   | "/default_schema" | "index_query_graph" | "Node"      | "person"     | LIST ["money ASC"]            |
      | "person_score_desc_idx"         | "Valid" | "Normal"   | "/default_schema" | "index_query_graph" | "Node"      | "person"     | LIST ["score DESC"]           |
      | "follow_followness"             | "Valid" | "Normal"   | "/default_schema" | "index_query_graph" | "Edge"      | "follow"     | LIST ["followness ASC"]       |
    When executing query:
      """
      USE index_query_graph INSERT
      (a@person{id: 1, name: "Lee",   age: 16,   gender: true,  money: -123.45, score: 78,   luckyTime: local_datetime('2012-04-03T00:00:00.000', "%Y-%m-%dT%H:%M:%S"), vec:VECTOR<3, float>([1.0, 2.0, 3.0])}),
      (b@person{id: 2, name: "Tom",   age: 25,   gender: true,  money: 88888.0, score: 100,  luckyTime: local_datetime('2008-11-14T12:56:59.123', "%Y-%m-%dT%H:%M:%S"), vec:VECTOR<3, float>([11.0, 21.0, 31.0])}),
      (c@person{id: 3, name: "Jerry", age: 22,   gender: false, money: 666.6,   score: 99,   luckyTime: local_datetime('2023-01-11T08:08:08.008', "%Y-%m-%dT%H:%M:%S"), vec:VECTOR<3, float>([12.0, 22.0, 32.0])}),
      (d@person{id: 4, name: "Biden", age: 90,   gender: true,  money: 10000,   score: 14,   luckyTime: local_datetime('1992-04-13T12:12:12.012', "%Y-%m-%dT%H:%M:%S")}),
      (@person{id: 5, name:  NULL,   age: NULL, gender: NULL,  money: 123.45,  score: NULL, luckyTime: NULL, vec:VECTOR<3, float>([1.10, 2.20, 3.30])}),
      (@city{id: 1, name: "XiangYang", vec:VECTOR<3, float>([1.0, 2.0, 3.0])}),
      (@city{id: 2, name: "HangZhou", vec:VECTOR<3, float>([1.0, 2.0, 3.0])}),
      (a)-[@follow{followness:77, vec1:VECTOR<2, float>([1.0, 2.0])}]->(b),
      (d)-[@follow{followness:100, vec1:VECTOR<2, float>([2.0, 3.0])}]->(c)
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person {id:3})
      RETURN v.id AS id, v.name AS name, v.vec AS vec
      """
    Then the result should be, in any order:
      | id | name    | vec                       |
      | 3  | "Jerry" | VECTOR [12.0, 22.0, 32.0] |
    And the plan should contain "IndexScan"
    And the plan should contain "index: pkIndex_person"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.id = 1 OR v.id = 4 OR v.id = 5
      RETURN v.id AS id, v.name AS name, v.vec AS vec
      """
    Then the result should be, in any order:
      | id | name    | vec                       |
      | 1  | "Lee"   | VECTOR [1.0, 2.0, 3.0]    |
      | 4  | "Biden" | null                      |
      | 5  | NULL    | VECTOR [1.10, 2.20, 3.30] |
    And the plan should contain "IndexScan"
    And the plan should contain "index: pkIndex_person"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.id IN LIST[1, 4, 4, 8, 1]
      RETURN v.id AS id, v.name AS name
      """
    Then the result should be, in any order:
      | id | name    |
      | 1  | "Lee"   |
      | 4  | "Biden" |
    And the plan should contain "IndexScan"
    And the plan should contain "index: pkIndex_person"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.id > 1
      RETURN v.id AS id, v.name AS name
      """
    Then the result should be, in any order:
      | id | name    |
      | 2  | "Tom"   |
      | 3  | "Jerry" |
      | 4  | "Biden" |
      | 5  | NULL    |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.id <> 2 AND v.id <> 4
      RETURN v.id AS id, v.name AS name
      """
    Then the result should be, in any order:
      | id | name    |
      | 1  | "Lee"   |
      | 3  | "Jerry" |
      | 5  | NULL    |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.id <> 1 AND v.id > 2
      RETURN v.id AS id, v.name AS name
      """
    Then the result should be, in any order:
      | id | name    |
      | 3  | "Jerry" |
      | 4  | "Biden" |
      | 5  | NULL    |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.id <> 2 AND v.id <> 4 AND v.id <> 5
      RETURN v.id AS id, v.name AS name
      """
    Then the result should be, in any order:
      | id | name    |
      | 1  | "Lee"   |
      | 3  | "Jerry" |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.id <> 2 AND v.id <> 4 OR v.id >= 3
      RETURN v.id AS id, v.name AS name
      """
    Then the result should be, in any order:
      | id | name    |
      | 1  | "Lee"   |
      | 3  | "Jerry" |
      | 4  | "Biden" |
      | 5  | NULL    |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.id > 2 AND v.id <> 4
      RETURN v.id AS id, v.name AS name
      """
    Then the result should be, in any order:
      | id | name    |
      | 3  | "Jerry" |
      | 5  | NULL    |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.name IS NULL
      RETURN v.id AS id, v.name AS name
      """
    Then the result should be, in any order:
      | id | name |
      | 5  | NULL |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.name IS NOT NULL
      RETURN v.id AS id, v.name AS name
      """
    Then the result should be, in any order:
      | id | name    |
      | 1  | "Lee"   |
      | 2  | "Tom"   |
      | 3  | "Jerry" |
      | 4  | "Biden" |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.name = NULL
      RETURN v.id AS id, v.name AS name
      """
    Then the result should be, in any order:
      | id | name |
    And the plan should not contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.name <> NULL
      RETURN v.id AS id, v.name AS name
      """
    Then the result should be, in any order:
      | id | name |
    And the plan should not contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.name = "Jerry" OR v.name IS NULL
      RETURN v.id AS id, v.name AS name
      """
    Then the result should be, in any order:
      | id | name    |
      | 3  | "Jerry" |
      | 5  | NULL    |
    And the plan should contain "IndexScan"
    # TODO(jie): need to handle the case `v.name = "Jerry" OR NULL` in ConstraintExtractor.
    # Because `v.name = NULL` and `v.name <> NULL` is optimized to NULL by the SimplifyComparisonRule
    # When executing query:
    # """
    # USE index_query_graph
    # MATCH (v:person) WHERE v.name = "Jerry" OR v.name = NULL
    # RETURN v.id AS id, v.name AS name
    # """
    # Then the result should be, in any order:
    # | id | name    |
    # | 3  | "Jerry" |
    # When executing query:
    # """
    # USE index_query_graph
    # MATCH (v:person) WHERE v.name = "Jerry" OR v.name <> NULL
    # RETURN v.id AS id, v.name AS name
    # """
    # Then the result should be, in any order:
    # | id | name    |
    # | 3  | "Jerry" |
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.name > "ABC"
      RETURN v.id AS id, v.name AS name
      """
    Then the result should be, in any order:
      | id | name    |
      | 1  | "Lee"   |
      | 2  | "Tom"   |
      | 3  | "Jerry" |
      | 4  | "Biden" |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.name <= "ABC"
      RETURN v.id AS id, v.name AS name
      """
    Then the result should be, in any order:
      | id | name |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.age > 0
      RETURN v.id AS id, v.name AS name, v.age AS age
      """
    Then the result should be, in any order:
      | id | name    | age |
      | 1  | "Lee"   | 16  |
      | 2  | "Tom"   | 25  |
      | 3  | "Jerry" | 22  |
      | 4  | "Biden" | 90  |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.age >= 18 AND v.age < 25
      RETURN v.id AS id, v.name AS name, v.age AS age
      """
    Then the result should be, in any order:
      | id | name    | age |
      | 3  | "Jerry" | 22  |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.age < 18 OR v.age >= 22 AND v.age < 35
      RETURN v.id AS id, v.name AS name, v.age AS age
      """
    Then the result should be, in any order:
      | id | name    | age |
      | 1  | "Lee"   | 16  |
      | 2  | "Tom"   | 25  |
      | 3  | "Jerry" | 22  |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.age IS NULL
      RETURN v.id AS id, v.name AS name, v.age AS age
      """
    Then the result should be, in any order:
      | id | name | age  |
      | 5  | NULL | NULL |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.age IS NULL OR v.age IS NOT NULL
      RETURN v.id AS id, v.name AS name, v.age AS age
      """
    Then the result should be, in any order:
      | id | name    | age  |
      | 1  | "Lee"   | 16   |
      | 2  | "Tom"   | 25   |
      | 3  | "Jerry" | 22   |
      | 4  | "Biden" | 90   |
      | 5  | NULL    | NULL |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.gender
      RETURN v.id AS id, v.name AS name, v.gender AS gender
      """
    Then the result should be, in any order:
      | id | name    | gender |
      | 1  | "Lee"   | true   |
      | 2  | "Tom"   | true   |
      | 4  | "Biden" | true   |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person{age: 22})
      RETURN v.id AS id, v.name AS name, v.age AS age
      """
    Then the result should be, in any order:
      | id | name    | age |
      | 3  | "Jerry" | 22  |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person{age: 22} /*+ index(person_age_idx) */)
      RETURN v.id AS id, v.name AS name, v.age AS age
      """
    Then the result should be, in any order:
      | id | name    | age |
      | 3  | "Jerry" | 22  |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person{age: 22}/*+ index(person_age_money_idx) */)
      RETURN v.id AS id, v.name AS name, v.age AS age
      """
    Then the result should be, in any order:
      | id | name    | age |
      | 3  | "Jerry" | 22  |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person{age: 22} /*+ ignore_index(person_age_idx) */)
      RETURN v.id AS id, v.name AS name, v.age AS age
      """
    Then the result should be, in any order:
      | id | name    | age |
      | 3  | "Jerry" | 22  |
    # With INDEX(...), if none of the hinted indexes exists, no index will be considered
    # and the planner will fall back to a non-index scan.
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person{age: 22} /*+ INDEX(non_exist_index) */)
      RETURN v.id AS id, v.name AS name, v.age AS age
      """
    Then the result should be, in any order:
      | id | name    | age |
      | 3  | "Jerry" | 22  |
    And the plan should not contain "IndexScan"
    # With INDEX(...), if the hinted index is not applicable to this pattern, no index will be
    # considered and the planner will fall back to a non-index scan.
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person{age: 22} /*+ INDEX(city_name_idx) */)
      RETURN v.id AS id, v.name AS name, v.age AS age
      """
    Then the result should be, in any order:
      | id | name    | age |
      | 3  | "Jerry" | 22  |
    # If the index in the hint is only appliable to one of the node/edge types the pattern corresponds to,
    # the index hint will be ignored for other node/edge types in index selection.
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person|city{name: "Lee"} /*+ index(person_name_idx) */)
      RETURN v.id AS id, v.name AS name
      """
    Then the result should be, in any order:
      | id | name  |
      | 1  | "Lee" |
    # Because a index hint is a special comment which starts with `/*+` and ends with `*/`,
    # so if a hint forgets the `+` after `/*`, it will be treated as a regular comment.
    # There will be no errors or warnings.
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person{age: 22} /* INDEX(city_name_idx) */)
      RETURN v.id AS id, v.name AS name, v.age AS age
      """
    Then the result should be, in any order:
      | id | name    | age |
      | 3  | "Jerry" | 22  |
    # If a hint contains any syntax errors, it will simply be treated as a regular comment.
    # There will be no errors or warnings.
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person{age: 22} /* INDEX[city_name_idx) */)
      RETURN v.id AS id, v.name AS name, v.age AS age
      """
    Then the result should be, in any order:
      | id | name    | age |
      | 3  | "Jerry" | 22  |
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person /*+index(person_name_asc_age_asc_idx)*/) WHERE v.name >= "Jack" and v.age > 18
      RETURN v.id AS id, v.name AS name, v.age AS age
      """
    Then the result should be, in any order:
      | id | name    | age |
      | 2  | "Tom"   | 25  |
      | 3  | "Jerry" | 22  |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person /*+ IGNORE_INDEX(person_name_asc_age_asc_idx) */) WHERE v.name >= "Jack" and v.age > 18
      RETURN v.id AS id, v.name AS name, v.age AS age
      """
    Then the result should be, in any order:
      | id | name    | age |
      | 2  | "Tom"   | 25  |
      | 3  | "Jerry" | 22  |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person /*+ IGNORE_INDEX(person_name_idx, person_age_idx, person_name_asc_age_asc_idx, person_age_desc_score_asc_idx, person_age_money_idx) */) WHERE v.name >= "Jack" and v.age > 18
      RETURN v.id AS id, v.name AS name, v.age AS age
      """
    Then the execution should be successful
    And the plan should not contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.gender = false
      RETURN v.id AS id, v.name AS name, v.gender AS gender
      """
    Then the result should be, in any order:
      | id | name    | gender |
      | 3  | "Jerry" | false  |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE NOT v.gender
      RETURN v.id AS id, v.name AS name, v.gender AS gender
      """
    Then the result should be, in any order:
      | id | name    | gender |
      | 3  | "Jerry" | false  |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.money > 0.0
      RETURN v.id AS id, v.name AS name, v.money AS money
      """
    Then the result should be, in any order:
      | id | name    | money   |
      | 2  | "Tom"   | 88888.0 |
      | 3  | "Jerry" | 666.6   |
      | 4  | "Biden" | 10000.0 |
      | 5  | NULL    | 123.45  |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.money < 0.0
      RETURN v.id AS id, v.name AS name, v.money AS money
      """
    Then the result should be, in any order:
      | id | name  | money   |
      | 1  | "Lee" | -123.45 |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.money = 0.0
      RETURN v.id AS id, v.name AS name, v.money AS money
      """
    Then the result should be, in any order:
      | id | name | money |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.money = -123.45
      RETURN v.id AS id, v.name AS name, v.money AS money
      """
    Then the result should be, in any order:
      | id | name  | money   |
      | 1  | "Lee" | -123.45 |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.score >= 60
      RETURN v.id AS id, v.name AS name, v.score AS score
      """
    Then the result should be, in any order:
      | id | name    | score |
      | 1  | "Lee"   | 78    |
      | 2  | "Tom"   | 100   |
      | 3  | "Jerry" | 99    |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.score < 60
      RETURN v.id AS id, v.name AS name, v.score AS score
      """
    Then the result should be, in any order:
      | id | name    | score |
      | 4  | "Biden" | 14    |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.score > 78 AND v.score <= 99
      RETURN v.id AS id, v.name AS name, v.score AS score
      """
    Then the result should be, in any order:
      | id | name    | score |
      | 3  | "Jerry" | 99    |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.score >= 78 AND v.score <= 99
      RETURN v.id AS id, v.name AS name, v.score AS score
      """
    Then the result should be, in any order:
      | id | name    | score |
      | 1  | "Lee"   | 78    |
      | 3  | "Jerry" | 99    |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.score = 14 OR v.score > 78
      RETURN v.id AS id, v.name AS name, v.score AS score
      """
    Then the result should be, in any order:
      | id | name    | score |
      | 2  | "Tom"   | 100   |
      | 3  | "Jerry" | 99    |
      | 4  | "Biden" | 14    |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.name >= "Jack" and v.age > 18
      RETURN v.id AS id, v.name AS name, v.age AS age
      """
    Then the result should be, in any order:
      | id | name    | age |
      | 2  | "Tom"   | 25  |
      | 3  | "Jerry" | 22  |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.luckyTime > local_datetime('2010-01-01T00:00:00.000', "%Y-%m-%dT%H:%M:%S")
      RETURN v.id AS id, v.name AS name, v.luckyTime AS luckyTime
      """
    Then the result should be, in any order:
      | id | name    | luckyTime                          |
      | 1  | "Lee"   | DATETIME '2012-04-03T00:00:00.000' |
      | 3  | "Jerry" | DATETIME '2023-01-11T08:08:08.008' |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.luckyTime < local_datetime('2010-01-01T00:00:00.000', "%Y-%m-%dT%H:%M:%S")
      RETURN v.id AS id, v.name AS name, v.luckyTime AS luckyTime
      """
    Then the result should be, in any order:
      | id | name    | luckyTime                          |
      | 2  | "Tom"   | DATETIME '2008-11-14T12:56:59.123' |
      | 4  | "Biden" | DATETIME '1992-04-13T12:12:12.012' |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.luckyTime >= local_datetime('1992-04-13T12:12:12.012', "%Y-%m-%dT%H:%M:%S") AND v.luckyTime < local_datetime('2012-04-03T00:00:00.000', "%Y-%m-%dT%H:%M:%S")
      RETURN v.id AS id, v.name AS name, v.luckyTime AS luckyTime
      """
    Then the result should be, in any order:
      | id | name    | luckyTime                          |
      | 2  | "Tom"   | DATETIME '2008-11-14T12:56:59.123' |
      | 4  | "Biden" | DATETIME '1992-04-13T12:12:12.012' |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.name > "Lee" and v.age < 35
      RETURN v.id AS id, v.name AS name, v.age AS age
      """
    Then the result should be, in any order:
      | id | name  | age |
      | 2  | "Tom" | 25  |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.score >= 60 AND v.score < 100 AND v.age > 18 AND v.age < 35
      RETURN v.id AS id, v.name AS name, v.age AS age, v.score AS score
      """
    Then the result should be, in any order:
      | id | name    | age | score |
      | 3  | "Jerry" | 22  | 99    |
    And the plan should contain "IndexScan"
    When executing query:
      """
      /*+ SET_VAR(enable_reorder=true) */ USE index_query_graph
      MATCH (v:person)-[e:follow{followness:77}]->(v2:person)
      RETURN v.id as src, v2.id as dst, e.followness as followness, e.vec1 as vec
      """
    Then the result should be, in any order:
      | src | dst | followness | vec               |
      | 1   | 2   | 77         | VECTOR [1.0, 2.0] |
    And the plan should contain "IndexScan"
    When executing query:
      """
      /*+ SET_VAR(enable_reorder=true) */ USE index_query_graph
      MATCH (v:person)-[e:follow WHERE e.followness > 20 AND e.followness <= 100]->(v2:person)
      RETURN v.id as src, v2.id as dst, e.followness as followness, e.vec1 as vec
      """
    Then the result should be, in any order:
      | src | dst | followness | vec               |
      | 1   | 2   | 77         | VECTOR [1.0, 2.0] |
      | 4   | 3   | 100        | VECTOR [2.0, 3.0] |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person)-[e:follow WHERE e.followness is not null]->(v2:person)
      RETURN e
      """
    Then the result should be, in any order:
      | e                                          |
      | [{followness:100, vec1:VECTOR [2.0, 3.0]}] |
      | [{followness:77, vec1:VECTOR [1.0, 2.0]}]  |
    And the plan should contain "IndexScan"
    # Fall back to a non-index node scan.
    When executing query:
      """
      USE index_query_graph
      MATCH (v:person) WHERE v.age < -2147483647
      RETURN v
      """
    Then the result should be, in any order:
      | v |
    And drop the index "person_name_idx" of "index_query_graph"
    And drop the index "person_age_idx" of "index_query_graph"
    And drop the index "person_gender_idx" of "index_query_graph"
    And drop the index "person_money_idx" of "index_query_graph"
    And drop the index "person_score_desc_idx" of "index_query_graph"
    And drop the index "person_luckyTime_idx" of "index_query_graph"
    And drop the index "person_name_asc_age_asc_idx" of "index_query_graph"
    And drop the index "person_age_desc_score_asc_idx" of "index_query_graph"
    And drop the index "person_age_money_idx" of "index_query_graph"
    And drop the index "city_name_idx" of "index_query_graph"
    And drop the index "follow_followness" of "index_query_graph"
    And drop the graph "index_query_graph"
    And drop the graph type "index_query_type_9527"

  @skip
  # unsigned integer is not supported in thrift/grpc yet
  Scenario: unsigned integer index
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS uint_index_type AS GRAPH TYPE {
        NODE person LABEL person {id INT PRIMARY KEY, uid UINT}),
        EDGE follow (person)-[ LABEL follow {followness UINT}]->(person)
      }
      """
    Then the execution should be successful
    # And graph type "uint_index_type" should be ready to use
    When executing query:
      """
      USE uint_index_type CREATE INDEX person_uid IF NOT EXISTS ON NODE person(uid)
      """
    Then the execution should be successful
    And index "person_uid" of "uint_index_type" should be ready to use
    When executing query:
      """
      CREATE INDEX follow_followness IF NOT EXISTS FOR ()-[e:follow]-() TYPED uint_index_type ON (e.followness)
      """
    Then the execution should be successful
    And index "follow_followness" of "uint_index_type" should be ready to use
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS uint_index_graph TYPED uint_index_type
      """
    Then the execution should be successful
    # And graph "uint_index_graph" should be ready to use
    When executing query:
      """
      USE uint_index_graph INSERT
        (a@person{id: 0, uid: 0}),
        (b@person{id: 1, uid: 1}),
        (c@person{id: 2, uid: 4294967296}),
        (d@person{id: 3, uid: 9223372036854775807}),
        (e@person{id: 4, uid: 18446744073709551615}),
        (a)-[{followness:0}]->(a),
        (b)-[{followness:1}]->(b),
        (c)-[{followness:4294967296}]->(c),
        (d)-[{followness:9223372036854775807}]->(d),
        (e)-[{followness:18446744073709551615}]->(e)
      """
    Then the execution should be successful
    When executing query:
      """
      USE uint_index_graph
      MATCH (v:person) WHERE v.uid >= 1
      RETURN v.id AS id, v.uid AS uid
      """
    Then the result should be, in any order:
      | id | uid                  |
      | 1  | 1                    |
      | 2  | 4294967296           |
      | 3  | 9223372036854775807  |
      | 4  | 18446744073709551615 |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE uint_index_graph
      MATCH (v:person) WHERE v.uid > 2
      RETURN v.id AS id, v.uid AS uid
      """
    Then the result should be, in any order:
      | id | uid                  |
      | 2  | 4294967296           |
      | 3  | 9223372036854775807  |
      | 4  | 18446744073709551615 |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE uint_index_graph
      MATCH (v:person) WHERE v.uid > 18446744073709551615
      RETURN v.id AS id, v.uid AS uid
      """
    Then the result should be, in any order:
      | id | uid |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE uint_index_graph
      MATCH (v:person) WHERE v.uid < 0
      RETURN v.id AS id, v.uid AS uid
      """
    Then the result should be, in any order:
      | id | uid |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE uint_index_graph
      MATCH (v:person)-[e:follow WHERE e.followness >= 1]->(v2:person)
      RETURN v.id as src, v2.id as dst, e.followness as followness
      """
    Then the result should be, in any order:
      | src | dst | followness           |
      | 1   | 1   | 1                    |
      | 2   | 2   | 4294967296           |
      | 3   | 3   | 9223372036854775807  |
      | 4   | 4   | 18446744073709551615 |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE uint_index_graph
      MATCH (v:person)-[e:follow WHERE e.followness > 2]->(v2:person)
      RETURN v.id as src, v2.id as dst, e.followness as followness
      """
    Then the result should be, in any order:
      | src | dst | followness           |
      | 2   | 2   | 4294967296           |
      | 3   | 3   | 9223372036854775807  |
      | 4   | 4   | 18446744073709551615 |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE uint_index_graph
      MATCH (v:person)-[e:follow WHERE e.followness > 18446744073709551615]->(v2:person)
      RETURN v.id as src, v2.id as dst, e.followness as followness
      """
    Then the result should be, in any order:
      | src | dst | followness |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE uint_index_graph
      MATCH (v:person)-[e:follow WHERE e.followness < 0]->(v2:person)
      RETURN v.id as src, v2.id as dst, e.followness as followness
      """
    Then the result should be, in any order:
      | src | dst | followness |
    And drop the index "person_uid" of "uint_index_type"
    And drop the index "follow_followness" of "uint_index_type"
    And drop the graph "uint_index_graph"
    And drop the graph type "uint_index_type"

  Scenario: index about NULL and composite primary key
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS index_selector_type AS {
         NODE player ( LABEL player {id INT, name STRING, age INT, PRIMARY KEY (id, name)})
      }
      """
    Then the execution should be successful
    # And graph type "index_selector_type" should be ready to use
    When executing query:
      """
      CREATE GRAPH index_selector_graph TYPED index_selector_type
      """
    Then the execution should be successful
    # And graph "index_selector_graph" should be ready to use
    When executing query:
      """
      USE index_selector_graph CREATE INDEX player_age_idx ON NODE player(age)
      """
    Then the execution should be successful
    And index "player_age_idx" of "index_selector_graph" should be ready to use
    When executing query:
      """
      USE index_selector_graph INSERT (@player{id: 1, name: "t", age: NULL}), (@player{id: 1, name: "", age: 1})
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_selector_graph MATCH (v) WHERE v.age IS NOT NULL OR v.age IS NOT NULL RETURN v
      """
    Then the result should be, in any order:
      | v                           |
      | ({id: 1, name: "", age: 1}) |
    When executing query:
      """
      USE index_selector_graph MATCH (v) WHERE v.age IS NOT NULL OR v.age IS NULL RETURN v
      """
    Then the result should be, in any order:
      | v                               |
      | ({id: 1, name: "t", age: NULL}) |
      | ({id: 1, name: "", age: 1})     |
    When executing query:
      """
      USE index_selector_graph MATCH (v:player{id:1}) RETURN v
      """
    Then the result should be, in any order:
      | v                               |
      | ({id: 1, name: "t", age: NULL}) |
      | ({id: 1, name: "", age: 1})     |
    When executing query:
      """
      USE index_selector_graph MATCH (v:player{id:1, name:"t"}) RETURN v
      """
    Then the result should be, in any order:
      | v                               |
      | ({id: 1, name: "t", age: NULL}) |
    When executing query:
      """
      USE index_selector_graph MATCH (v:player{id:1, name:""}) RETURN v
      """
    Then the result should be, in any order:
      | v                           |
      | ({id: 1, name: "", age: 1}) |
    When executing query:
      """
      USE index_selector_graph MATCH (v:player) WHERE v.id > 0 AND v.id < 3 RETURN v
      """
    Then the result should be, in any order:
      | v                               |
      | ({id: 1, name: "t", age: NULL}) |
      | ({id: 1, name: "", age: 1})     |
    And drop the index "player_age_idx" of "index_selector_graph"
    And drop the graph "index_selector_graph"
    And drop the graph type "index_selector_type"

  @skip
  # GG24
  Scenario: same property name in different types
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS same_prop_gt AS {
        NODE player (LABEL player {id INT PRIMARY KEY, iVal double, jVal int, kVal int}),
        NODE joker (LABEL joker {id INT PRIMARY KEY, iVal INT})
      }
      """
    Then the execution should be successful
    # And graph type "same_prop_gt" should be ready to use
    When executing query:
      """
      CREATE GRAPH same_prop_gh TYPED same_prop_gt
      """
    Then the execution should be successful
    # And graph "same_prop_gh" should be ready to use
    When executing query:
      """
      CREATE INDEX player_iVal_idx FOR (n:player) TYPED same_prop_gh ON (n.iVal)
      """
    Then the execution should be successful
    And index "player_iVal_idx" of "same_prop_gh" should be ready to use
    When executing query:
      """
      CREATE INDEX player_jVal_idx FOR (n:player) TYPED same_prop_gh ON (n.jVal)
      """
    Then the execution should be successful
    And index "player_jVal_idx" of "same_prop_gh" should be ready to use
    When executing query:
      """
      CREATE INDEX player_iVal_jVal_idx FOR (n:player) TYPED same_prop_gh ON (n.iVal, n.jVal)
      """
    Then the execution should be successful
    And index "player_iVal_jVal_idx" of "same_prop_gh" should be ready to use
    When executing query:
      """
      CREATE INDEX joker_iVal_idx FOR (n:joker) TYPED same_prop_gh ON (n.iVal)
      """
    Then the execution should be successful
    And index "joker_iVal_idx" of "same_prop_gh" should be ready to use
    When executing query:
      """
      USE same_prop_gh INSERT (@player{id: 1, iVal: 1, jVal: null, kVal: 2}),  ({id: 2 , iVal: 1.1, jVal: 1, kVal: 2}), ({id: 3, iVal: 1.2, jVal: 1, kVal: 2})
      """
    Then the execution should be successful
    When executing query:
      """
      USE same_prop_gh INSERT (@joker{id: 1, iVal: 1})
      """
    Then the execution should be successful
    When executing query:
      """
      USE same_prop_gh MATCH (v WHERE v.iVal = 1) RETURN v
      """
    Then the result should be, in any order:
      | v                                       |
      | ({id: 1, iVal: 1, jVal: null, kVal: 2}) |
      | ({id: 1, iVal: 1})                      |
    When executing query:
      """
      USE same_prop_gh MATCH (v WHERE v.iVal <> 1) RETURN v
      """
    Then the result should be, in any order:
      | v                                      |
      | ({id: 2, iVal: 1.1, jVal: 1, kVal: 2}) |
      | ({id: 3, iVal: 1.2, jVal: 1, kVal: 2}) |
    When executing query:
      """
      USE same_prop_gh MATCH (v:player) WHERE (v.iVal = 1.1) AND (v.jVal IS NULL OR v.jVal IS NOT NULL) RETURN v
      """
    Then the result should be, in any order:
      | v                                      |
      | ({id: 2, iVal: 1.1, jVal: 1, kVal: 2}) |
    When executing query:
      """
      USE same_prop_gh MATCH (v:player) WHERE v.jVal IS NOT NULL RETURN v
      """
    Then the result should be, in any order:
      | v                                      |
      | ({id: 2, iVal: 1.1, jVal: 1, kVal: 2}) |
      | ({id: 3, iVal: 1.2, jVal: 1, kVal: 2}) |
    When executing query:
      """
      USE same_prop_gh MATCH (v:player) WHERE v.jVal IS NULL RETURN v
      """
    Then the result should be, in any order:
      | v                                       |
      | ({id: 1, iVal: 1, jVal: null, kVal: 2}) |
    When executing query:
      """
      USE same_prop_gh MATCH (v:player) WHERE v.iVal IN LIST[1, 2] RETURN v.id
      """
    Then the result should be, in any order:
      | v.id |
      | 1    |
    When executing query:
      """
      USE same_prop_gh MATCH (v:player) WHERE v.iVal IN LIST[1, 2, 2.3] RETURN v.id
      """
    Then the result should be, in any order:
      | v.id |
      | 1    |
    And drop the index "player_iVal_idx" of "same_prop_gt"
    And drop the index "player_jVal_idx" of "same_prop_gt"
    And drop the index "player_iVal_jVal_idx" of "same_prop_gt"
    And drop the index "joker_iVal_idx" of "same_prop_gt"
    And drop the graph "same_prop_gh"
    And drop the graph type "same_prop_gt"

  @zhs
  Scenario: composite index
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS overflow_query_type AS {
        NODE person (LABEL person {id INT PRIMARY KEY, age INT, score INT32})
      }
      """
    Then the execution should be successful
    # And graph type "overflow_query_type" should be ready to use
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS overflow_query_graph TYPED overflow_query_type
      """
    Then the execution should be successful
    # And graph "overflow_query_graph" should be ready to use
    When executing query:
      """
      USE overflow_query_graph CREATE INDEX IF NOT EXISTS age_score_index ON NODE person(age, score)
      """
    Then the execution should be successful
    And index "age_score_index" of "overflow_query_graph" should be ready to use
    When executing query:
      """
      USE overflow_query_graph INSERT
      (@person{id: 0, age: 8, score: 0}),
      (@person{id: 1, age: 9, score: -2147483648}),
      (@person{id: 2, age: 9, score: -1}),
      (@person{id: 3, age: 9, score: 0}),
      (@person{id: 4, age: 9, score: 1}),
      (@person{id: 5, age: 9, score: 2147483647}),
      (@person{id: 6, age: 9, score: NULL}),
      (@person{id: 7, age: 10, score: 0})
      """
    Then the execution should be successful
    When executing query:
      """
      USE overflow_query_graph
      MATCH (v:person) WHERE v.age = 9 and v.score = 1
      RETURN v.id AS id, v.age AS age, v.score AS score
      """
    Then the result should be, in any order:
      | id | age | score |
      | 4  | 9   | 1     |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE overflow_query_graph
      MATCH (v:person) WHERE v.age = 9 and v.score <> 1
      RETURN v.id AS id, v.age AS age, v.score AS score
      """
    Then the result should be, in any order:
      | id | age | score       |
      | 1  | 9   | -2147483648 |
      | 2  | 9   | -1          |
      | 3  | 9   | 0           |
      | 5  | 9   | 2147483647  |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE overflow_query_graph
      MATCH (v:person) WHERE v.age < 9
      RETURN v.id AS id, v.age AS age, v.score AS score
      """
    Then the result should be, in any order:
      | id | age | score |
      | 0  | 8   | 0     |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE overflow_query_graph
      MATCH (v:person) WHERE v.age <= 9
      RETURN v.id AS id, v.age AS age, v.score AS score
      """
    Then the result should be, in any order:
      | id | age | score       |
      | 0  | 8   | 0           |
      | 1  | 9   | -2147483648 |
      | 2  | 9   | -1          |
      | 3  | 9   | 0           |
      | 4  | 9   | 1           |
      | 5  | 9   | 2147483647  |
      | 6  | 9   | NULL        |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE overflow_query_graph
      MATCH (v:person) WHERE v.age > 9
      RETURN v.id AS id, v.age AS age, v.score AS score
      """
    Then the result should be, in any order:
      | id | age | score |
      | 7  | 10  | 0     |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE overflow_query_graph
      MATCH (v:person) WHERE v.age >= 9
      RETURN v.id AS id, v.age AS age, v.score AS score
      """
    Then the result should be, in any order:
      | id | age | score       |
      | 1  | 9   | -2147483648 |
      | 2  | 9   | -1          |
      | 3  | 9   | 0           |
      | 4  | 9   | 1           |
      | 5  | 9   | 2147483647  |
      | 6  | 9   | NULL        |
      | 7  | 10  | 0           |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE overflow_query_graph
      MATCH (v:person) WHERE v.age = 9 and v.score < 0
      RETURN v.id AS id, v.age AS age, v.score AS score
      """
    Then the result should be, in any order:
      | id | age | score       |
      | 1  | 9   | -2147483648 |
      | 2  | 9   | -1          |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE overflow_query_graph
      MATCH (v:person) WHERE v.age = 9 and v.score <= 0
      RETURN v.id AS id, v.age AS age, v.score AS score
      """
    Then the result should be, in any order:
      | id | age | score       |
      | 1  | 9   | -2147483648 |
      | 2  | 9   | -1          |
      | 3  | 9   | 0           |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE overflow_query_graph
      MATCH (v:person) WHERE v.age = 9 and v.score > 0
      RETURN v.id AS id, v.age AS age, v.score AS score
      """
    Then the result should be, in any order:
      | id | age | score      |
      | 4  | 9   | 1          |
      | 5  | 9   | 2147483647 |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE overflow_query_graph
      MATCH (v:person) WHERE v.age = 9 and v.score >= 0
      RETURN v.id AS id, v.age AS age, v.score AS score
      """
    Then the result should be, in any order:
      | id | age | score      |
      | 3  | 9   | 0          |
      | 4  | 9   | 1          |
      | 5  | 9   | 2147483647 |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE overflow_query_graph
      MATCH (v:person) WHERE v.age = 9 and v.score < -2147483648
      RETURN v.id AS id, v.age AS age, v.score AS score
      """
    Then the result should be, in any order:
      | id | age | score |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE overflow_query_graph
      MATCH (v:person) WHERE v.age = 9 and v.score <= -2147483648
      RETURN v.id AS id, v.age AS age, v.score AS score
      """
    Then the result should be, in any order:
      | id | age | score       |
      | 1  | 9   | -2147483648 |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE overflow_query_graph
      MATCH (v:person) WHERE v.age = 9 and v.score < 2147483647
      RETURN v.id AS id, v.age AS age, v.score AS score
      """
    Then the result should be, in any order:
      | id | age | score       |
      | 1  | 9   | -2147483648 |
      | 2  | 9   | -1          |
      | 3  | 9   | 0           |
      | 4  | 9   | 1           |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE overflow_query_graph
      MATCH (v:person) WHERE v.age = 9 and v.score <= 2147483647
      RETURN v.id AS id, v.age AS age, v.score AS score
      """
    Then the result should be, in any order:
      | id | age | score       |
      | 1  | 9   | -2147483648 |
      | 2  | 9   | -1          |
      | 3  | 9   | 0           |
      | 4  | 9   | 1           |
      | 5  | 9   | 2147483647  |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE overflow_query_graph
      MATCH (v:person) WHERE v.age = 9 and v.score > 2147483647
      RETURN v.id AS id, v.age AS age, v.score AS score
      """
    Then the result should be, in any order:
      | id | age | score |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE overflow_query_graph
      MATCH (v:person) WHERE v.age = 9 and v.score >= 2147483647
      RETURN v.id AS id, v.age AS age, v.score AS score
      """
    Then the result should be, in any order:
      | id | age | score      |
      | 5  | 9   | 2147483647 |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE overflow_query_graph
      MATCH (v:person) WHERE v.age = 9 and v.score > -2147483648
      RETURN v.id AS id, v.age AS age, v.score AS score
      """
    Then the result should be, in any order:
      | id | age | score      |
      | 2  | 9   | -1         |
      | 3  | 9   | 0          |
      | 4  | 9   | 1          |
      | 5  | 9   | 2147483647 |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE overflow_query_graph
      MATCH (v:person) WHERE v.age = 9 and v.score >= -2147483648
      RETURN v.id AS id, v.age AS age, v.score AS score
      """
    Then the result should be, in any order:
      | id | age | score       |
      | 1  | 9   | -2147483648 |
      | 2  | 9   | -1          |
      | 3  | 9   | 0           |
      | 4  | 9   | 1           |
      | 5  | 9   | 2147483647  |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE overflow_query_graph
      MATCH (v:person) WHERE v.age = 9 and v.score >= -2147483648 and v.score <= 2147483647
      RETURN v.id AS id, v.age AS age, v.score AS score
      """
    Then the result should be, in any order:
      | id | age | score       |
      | 1  | 9   | -2147483648 |
      | 2  | 9   | -1          |
      | 3  | 9   | 0           |
      | 4  | 9   | 1           |
      | 5  | 9   | 2147483647  |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE overflow_query_graph
      MATCH (v:person) WHERE v.age = 9 and v.score >= -2147483648 and v.score < 2147483647
      RETURN v.id AS id, v.age AS age, v.score AS score
      """
    Then the result should be, in any order:
      | id | age | score       |
      | 1  | 9   | -2147483648 |
      | 2  | 9   | -1          |
      | 3  | 9   | 0           |
      | 4  | 9   | 1           |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE overflow_query_graph
      MATCH (v:person) WHERE v.age = 9 and v.score > -2147483648 and v.score <= 2147483647
      RETURN v.id AS id, v.age AS age, v.score AS score
      """
    Then the result should be, in any order:
      | id | age | score      |
      | 2  | 9   | -1         |
      | 3  | 9   | 0          |
      | 4  | 9   | 1          |
      | 5  | 9   | 2147483647 |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE overflow_query_graph
      MATCH (v:person) WHERE v.age = 9 and v.score > -2147483648 and v.score < 2147483647
      RETURN v.id AS id, v.age AS age, v.score AS score
      """
    Then the result should be, in any order:
      | id | age | score |
      | 2  | 9   | -1    |
      | 3  | 9   | 0     |
      | 4  | 9   | 1     |
    And drop the index "age_score_index" of "overflow_query_graph"
    And drop the graph "overflow_query_graph"
    And drop the graph type "overflow_query_type"

  Scenario: index of float and integer fields
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS gtif AS {
        NODE player (LABEL player {id INT PRIMARY KEY, iVal INT, fVal FLOAT})
      }
      """
    Then the execution should be successful
    # And graph type "gtif" should be ready to use
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS gif TYPED gtif
      """
    Then the execution should be successful
    # And graph "gif" should be ready to use
    When executing query:
      """
      USE gif CREATE INDEX IF NOT EXISTS i_iVal ON NODE player(iVal)
      """
    Then the execution should be successful
    And index "i_iVal" of "gif" should be ready to use
    When executing query:
      """
      USE gif CREATE INDEX i_fVal ON NODE player(fVal)
      """
    Then the execution should be successful
    And index "i_fVal" of "gif" should be ready to use
    When executing query:
      """
      USE gif INSERT (@player{id: 1, iVal: 1, fVal: 1.0}), (@player{id: 2, iVal: 2, fVal: 2.0}), (@player{id: 3, iVal: 3, fVal: 3.0})
      """
    Then the execution should be successful
    When executing query:
      """
      use gif match (v) where v.iVal = 2.1 order by v.iVal return v.iVal
      """
    Then the result should be, in any order:
      | v.iVal |
    When executing query:
      """
      use gif match (v) where v.iVal <> 2.1 order by v.iVal return v.iVal
      """
    Then the result should be, in any order:
      | v.iVal |
      | 1      |
      | 2      |
      | 3      |
    When executing query:
      """
      use gif match (v) where v.iVal > 2.1 order by v.iVal return v.iVal
      """
    Then the result should be, in any order:
      | v.iVal |
      | 3      |
    When executing query:
      """
      use gif match (v) where v.iVal >= 2.1 order by v.iVal return v.iVal
      """
    Then the result should be, in any order:
      | v.iVal |
      | 3      |
    When executing query:
      """
      use gif match (v) where v.iVal < 2.1 order by v.iVal return v.iVal
      """
    Then the result should be, in any order:
      | v.iVal |
      | 1      |
      | 2      |
    When executing query:
      """
      use gif match (v) where v.iVal <= 2.1 order by v.iVal return v.iVal
      """
    Then the result should be, in any order:
      | v.iVal |
      | 1      |
      | 2      |
    When executing query:
      """
      use gif match (v) where v.fVal = 2.1 order by v.fVal return v.fVal
      """
    Then the result should be, in any order:
      | v.fVal |
    When executing query:
      """
      use gif match (v) where v.fVal <> 2.1 order by v.fVal return v.fVal
      """
    Then the result should be, in any order:
      | v.fVal |
      | 1.0    |
      | 2.0    |
      | 3.0    |
    When executing query:
      """
      use gif match (v) where v.fVal > 2.1 order by v.fVal return v.fVal
      """
    Then the result should be, in any order:
      | v.fVal |
      | 3.0    |
    When executing query:
      """
      use gif match (v) where v.fVal >= 2.1 order by v.fVal return v.fVal
      """
    Then the result should be, in any order:
      | v.fVal |
      | 3.0    |
    When executing query:
      """
      use gif match (v) where v.fVal < 2.1 order by v.fVal return v.fVal
      """
    Then the result should be, in any order:
      | v.fVal |
      | 1.0    |
      | 2.0    |
    When executing query:
      """
      use gif match (v) where v.fVal <= 2.1 order by v.fVal return v.fVal
      """
    Then the result should be, in any order:
      | v.fVal |
      | 1.0    |
      | 2.0    |
    And drop the index "i_iVal" of "gif"
    And drop the index "i_fVal" of "gif"
    And drop the graph "gif"
    And drop the graph type "gtif"

  Scenario: create index with nulls
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS index_graph_type_nulls AS {
        NODE node_type_player (LABEL player {id INT PRIMARY KEY, name STRING}),
        EDGE edge_type_follow (node_type_player)-[LABEL follow {followness INT, age INT, since LOCAL DATETIME}]->(node_type_player)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS index_graph_nulls TYPED index_graph_type_nulls
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_graph_nulls CREATE INDEX IF NOT EXISTS i_player_single ON NODE node_type_player(name)
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_graph_nulls CREATE INDEX IF NOT EXISTS i_player_complex ON NODE node_type_player(name ASC, id)
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_graph_nulls CREATE INDEX IF NOT EXISTS i_follow_single ON EDGE edge_type_follow(followness)
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_graph_nulls CREATE INDEX IF NOT EXISTS i_follow_complex ON EDGE edge_type_follow(followness ASC, age)
      """
    Then the execution should be successful
    And drop the index "i_follow_complex" of "index_graph_nulls"
    And drop the index "i_follow_single" of "index_graph_nulls"
    And drop the index "i_player_complex" of "index_graph_nulls"
    And drop the index "i_player_single" of "index_graph_nulls"
    And drop the graph "index_graph_nulls"
    And drop the graph type "index_graph_type_nulls"

  Scenario: int8 index
    # found in #3512 that we must do some value cast before encoding index
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS `int8gt1` AS {
        NODE `nt1` (LABEL `nt1`{`id` INT8, PRIMARY KEY (`id`)}),
        EDGE `et1` (`nt1`)-[:`et1`]->(`nt1`)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS int8g1 TYPED int8gt1
      """
    Then the execution should be successful
    # And graph "int8g1" should be ready to use
    When executing query:
      """
      USE int8g1 INSERT (a@nt1{id: 2}), (a)-[@et1]->(a)
      """
    Then the execution should be successful
    And drop the graph "int8g1"
    And drop the graph type "int8gt1"

  Scenario: zoned temporal pk index
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS zoned_dml_GraphType_d as {
        NODE Place1 (LABELS City1 {id INT, zdt ZONED DATETIME PRIMARY KEY}),
        NODE Place2 (LABELS City2 {id INT, zt ZONED TIME PRIMARY KEY})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS zdd TYPED zoned_dml_GraphType_d
      """
    Then the execution should be successful
    # And graph "zoned_dml_GraphType_d" should be ready to use
    When executing query:
      """
      SESSION SET timezone = "UTC"
      """
    Then the execution should be successful
    When executing query:
      """
      USE zdd INSERT (a IS City1 {id:1, zdt:zoned_datetime('2023-12-31T11:22:33.000', "%Y-%m-%dT%H:%M:%S")})
      """
    Then the execution should be successful
    When executing query:
      """
      USE zdd INSERT (a IS City2 {id:2, zt:zoned_time('11:22:33.000', "%H:%M:%S")})
      """
    Then the execution should be successful
    When executing query:
      """
      USE zdd MATCH (a:City1) WHERE a.zdt = zoned_datetime('2023-12-31T11:22:33.000', "%Y-%m-%dT%H:%M:%S") RETURN a
      """
    Then the result should be, in any order:
      | a                                                           |
      | ({id: 1, zdt: ZONED DATETIME "2023-12-31T11:22:33.000000"}) |
    When executing query:
      """
      USE zdd MATCH (a:City1) WHERE a.zdt > zoned_datetime('2023-12-31T00:00:00.000', "%Y-%m-%dT%H:%M:%S") RETURN a
      """
    Then the result should be, in any order:
      | a                                                           |
      | ({id: 1, zdt: ZONED DATETIME "2023-12-31T11:22:33.000000"}) |
    When executing query:
      """
      USE zdd MATCH (a:City1) WHERE a.zdt < zoned_datetime('2023-12-31T23:59:59.000', "%Y-%m-%dT%H:%M:%S") RETURN a
      """
    Then the result should be, in any order:
      | a                                                           |
      | ({id: 1, zdt: ZONED DATETIME "2023-12-31T11:22:33.000000"}) |
    When executing query:
      """
      USE zdd MATCH (a:City1) WHERE a.zdt <= zoned_datetime('2023-12-31T11:00:00.000', "%Y-%m-%dT%H:%M:%S") RETURN a
      """
    Then the result should be, in any order:
      | a |
    When executing query:
      """
      USE zdd MATCH (a:City1) WHERE a.zdt >= zoned_datetime('2023-12-31T12:00:00.000', "%Y-%m-%dT%H:%M:%S") RETURN a
      """
    Then the result should be, in any order:
      | a |
    When executing query:
      """
      USE zdd MATCH (a:City2) WHERE a.zt = zoned_time('11:22:33.000', "%H:%M:%S") RETURN a
      """
    Then the result should be, in any order:
      | a                                          |
      | ({id:2, zt: ZONED TIME "11:22:33.000000"}) |
    When executing query:
      """
      USE zdd MATCH (a:City2) WHERE a.zt > zoned_time('06:06:06.000', "%H:%M:%S") RETURN a
      """
    Then the result should be, in any order:
      | a                                          |
      | ({id:2, zt: ZONED TIME "11:22:33.000000"}) |
    When executing query:
      """
      USE zdd MATCH (a:City2) WHERE a.zt < zoned_time('12:12:12.000', "%H:%M:%S") RETURN a
      """
    Then the result should be, in any order:
      | a                                          |
      | ({id:2, zt: ZONED TIME "11:22:33.000000"}) |
    When executing query:
      """
      USE zdd MATCH (a:City2) WHERE a.zt <= zoned_time('11:00:00.000', "%H:%M:%S") RETURN a
      """
    Then the result should be, in any order:
      | a |
    When executing query:
      """
      USE zdd MATCH (a:City2) WHERE a.zt >= zoned_time('12:00:00.000', "%H:%M:%S") RETURN a
      """
    Then the result should be, in any order:
      | a |
    And drop the graph "zdd"
    And drop the graph type "zoned_dml_GraphType_d"

  @skip
  # GG24
  Scenario: index of float and unsigned integer
    When executing query:
      """
      create graph type if not exists uidx_type as {
        NODE u8 (label u8{id uint8 primary key, ival uint8}),
        NODE u16 (label u16{id uint16 primary key, ival uint16}),
        NODE u32 (label u32{id uint32 primary key, ival uint32}),
        NODE u64 (label u64{id uint64 primary key, ival uint64}),
        NODE f32 (label f32{id float primary key}),
        NODE f64 (label f64{id double primary key}),
        EDGE e1 (u8)-[label e1{weight uint8}]->(u8),
        EDGE e2 (u16)-[label e2{weight uint16}]->(u16),
        EDGE e3 (u32)-[label e3{weight uint32}]->(u32),
        EDGE e4 (u64)-[label e2{weight uint64}]->(u64),
        EDGE e5 (f32)-[label e3{weight float}]->(f32),
        EDGE e6 (f64)-[label e3{weight double}]->(f64)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE INDEX IF NOT EXISTS i_e1 FOR ()-[e:e1]-() TYPED uidx_type ON (e.weight)
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE INDEX IF NOT EXISTS i_e2 FOR ()-[e:e2]-() TYPED uidx_type ON (e.weight)
      """
    Then the execution should be successful
    When executing query:
      """
      create index if not exists i_e3 for ()-[e:e3]-() typed uidx_type on (e.weight)
      """
    Then the execution should be successful
    When executing query:
      """
      create index if not exists i_e4 for ()-[e:e4]-() typed uidx_type on (e.weight)
      """
    Then the execution should be successful
    When executing query:
      """
      create index if not exists i_e5 for ()-[e:e5]-() typed uidx_type on (e.weight)
      """
    Then the execution should be successful
    When executing query:
      """
      create index if not exists i_e6 for ()-[e:e6]-() typed uidx_type on (e.weight)
      """
    Then the execution should be successful
    When executing query:
      """
      create graph if not EXISTS uidx uidx_type
      """
    Then the execution should be successful
    # And graph "uidx" should be ready to use
    When executing query:
      """
      use uidx insert (@f32{id: 3.14})
      """
    Then the execution should be successful
    When executing query:
      """
      use uidx insert (@f64{id: 3.1415926})
      """
    Then the execution should be successful
    When executing query:
      """
      use uidx insert (@u8{id: 255, ival: 255})
      """
    Then the execution should be successful
    When executing query:
      """
      use uidx insert (@u16{id: 65535, ival: 255})
      """
    Then the execution should be successful
    When executing query:
      """
      use uidx insert (@u32{id: 4294967295, ival: 4294967295})
      """
    Then the execution should be successful
    # crash
    # When executing query:
    # """
    # use uidx insert edge e1 ({id: 255})-[e1{weight: 255}]->({id: 255})
    # """
    # Then the execution should be successful
    When executing query:
      """
      use uidx match (v:u32{id: 4294967295}) return v.id as vid
      """
    Then the result should be, in any order:
      | vid        |
      | 4294967295 |
    When executing query:
      """
      use uidx match (v:u32{ival: 4294967295}) return v.ival as ival
      """
    Then the result should be, in any order:
      | ival       |
      | 4294967295 |
    # crash
    # When executing query:
    # """
    # use uidx match (v{ival: 255}) return v.ival as ival
    # """
    # Then the result should be, in any order:
    # | ival |
    # | 255  |
    # When executing query:
    # """
    # use uidx match (v:f32{id: 3.14}) return v.id as vid
    # """
    # Then the result should be, in any order:
    # | vid  |
    # | 3.14 |
    And drop the index "i_e1" of "uidx_type"
    And drop the index "i_e2" of "uidx_type"
    And drop the index "i_e3" of "uidx_type"
    And drop the index "i_e4" of "uidx_type"
    And drop the index "i_e5" of "uidx_type"
    And drop the index "i_e6" of "uidx_type"
    And drop the graph "uidx"
    And drop the graph type "uidx_type"

  Scenario: index value overflow
    When executing query:
      """
      USE ldbc
      MATCH (v:Person) WHERE v.id < 9223372036854775808
      RETURN v.id as vid
      """
    Then the result should be, in any order:
      | vid |
      | 1   |
      | 2   |
      | 3   |
      | 4   |

  Scenario: zoned time index
    And create a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      SESSION SET timezone = "UTC"
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS test_alter_add_property as {
      NODE Person (LABELS Person{id int primary key, loginTime zoned time}),
      NODE Post (LABELS Post {id INT,title STRING, PRIMARY KEY(id,title)}),
      EDGE LIKES (Person)-[:LIKES{likeDatetime zoned datetime}]->(Post)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS test_alter_add_property test_alter_add_property
      """
    Then the execution should be successful
    And graph "test_alter_add_property" should be ready to use
    When executing query:
      """
      USE test_alter_add_property CREATE INDEX i2 ON EDGE LIKES(likeDatetime desc)
      """
    Then the execution should be successful
    When executing query:
      """
      USE test_alter_add_property CREATE INDEX i3 ON NODE Person(loginTime desc)
      """
    Then the execution should be successful
    When executing query:
      """
      use test_alter_add_property insert
      (a1@Person{id:1,loginTime:null}),
      (a2@Person{id:2,loginTime:zoned_time("15:06:07.0890Z", "%H:%M:%S%z")}),
      (a3@Person{id:3,loginTime:zoned_time("15:26:07.0890Z", "%H:%M:%S%z")}),
      (b1@Post{id:1,title:"钢铁是怎样练成的"}),
      (a1)-[@LIKES{likeDatetime:zoned_datetime("2011-03-04T11:06:08Z", "%Y-%m-%dT%H:%M:%S%z")}]->(b1),
      (a2)-[@LIKES{likeDatetime:zoned_datetime("2012-03-04T09:06:08 -01:00", "%Y-%m-%dT%H:%M:%S %Ez")}]->(b1),
      (a3)-[@LIKES{likeDatetime:null}]->(b1)
      """
    Then the execution should be successful
    When executing query:
      """
      USE test_alter_add_property
      MATCH (v1)-[e]->(v2)
      WHERE e.likeDatetime is not null
      RETURN v1.id, e.likeDatetime, v2.id
      """
    Then the result should be, in any order:
      | v1.id | e.likeDatetime                              | v2.id |
      | 2     | ZONED DATETIME "2012-03-04T10:06:08.000000" | 1     |
      | 1     | ZONED DATETIME "2011-03-04T11:06:08.000000" | 1     |
    When executing query:
      """
      USE test_alter_add_property
      MATCH (v1)-[e]->(v2)
      WHERE e.likeDatetime = zoned_datetime("2011-03-04T11:06:08Z", "%Y-%m-%dT%H:%M:%S%z")
      RETURN v1.id, e.likeDatetime, v2.id
      """
    Then the result should be, in any order:
      | v1.id | e.likeDatetime                              | v2.id |
      | 1     | ZONED DATETIME "2011-03-04T11:06:08.000000" | 1     |
    When executing query:
      """
      USE test_alter_add_property
      MATCH (v1)
      WHERE v1.loginTime is not null
      RETURN v1.id, v1.loginTime
      """
    Then the result should be, in any order:
      | v1.id | v1.loginTime                 |
      | 2     | ZONED TIME "15:06:07.089000" |
      | 3     | ZONED TIME "15:26:07.089000" |
    When executing query:
      """
      USE test_alter_add_property
      MATCH (v1@Person)
      WHERE v1.loginTime = zoned_time("15:06:07.0890Z", "%H:%M:%S%z")
      RETURN v1.id, v1.loginTime
      """
    Then the result should be, in any order:
      | v1.id | v1.loginTime                 |
      | 2     | ZONED TIME "15:06:07.089000" |
    And drop the graph "test_alter_add_property"
    And drop the graph type "test_alter_add_property"
    And close the current session

  Scenario: undirected edge index
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS undirected_test_type AS {
        NODE Person (LABELS Person {id INT PRIMARY KEY}),
        EDGE KNOWS (Person)-[:KNOWS{rate INT}]->(Person),
        EDGE UN_KNOWS (Person)~[:UN_KNOWS{rate INT}]~(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH test_undirected undirected_test_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE test_undirected CREATE INDEX IF NOT EXISTS idx_knows ON EDGE KNOWS ( rate ASC )
      """
    Then the execution should be successful
    When executing query:
      """
      USE test_undirected CREATE INDEX IF NOT EXISTS idx_un_knows ON EDGE UN_KNOWS ( rate ASC )
      """
    Then the execution should be successful
    When executing query:
      """
      USE test_undirected insert (a@Person{id:1})-[@KNOWS{rate:1}]->(b@Person{id:2}), (a)~[@UN_KNOWS{rate:1}]~(b)
      """
    Then the execution should be successful
    When executing query:
      """
      USE test_undirected MATCH (a)~[e@UN_KNOWS{rate:1}]~(b) return a.id, e.rate, b.id
      """
    Then the result should be, in any order:
      | a.id | e.rate | b.id |
      | 1    | 1      | 2    |
      | 2    | 1      | 1    |
    And drop the index "idx_knows" of "test_undirected"
    And drop the index "idx_un_knows" of "test_undirected"
    And drop the graph "test_undirected"
    And drop the graph type "undirected_test_type"

  Scenario: no graph for index
    And create a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      SESSION RESET GRAPH
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc CREATE INDEX idx_ldbc_no_graph_test ON NODE Person(firstName)
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc SHOW INDEXES
      """
    Then the result should contain:
      | name                     | state   | index_type | schema            | graph_name | entity_type | element_type | properties            |
      | "idx_ldbc_no_graph_test" | "Valid" | "Normal"   | "/default_schema" | "ldbc"     | "Node"      | "Person"     | LIST["firstName ASC"] |
    When executing query:
      """
      SHOW INDEXES
      """
    Then an Error should be raised: "[NS000]: Semantic error: Could not determine the graph to show indexes"
    When executing query:
      """
      SESSION SET GRAPH ldbc
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW INDEXES
      """
    Then the result should contain:
      | name                     | state   | index_type | schema            | graph_name | entity_type | element_type | properties            |
      | "idx_ldbc_no_graph_test" | "Valid" | "Normal"   | "/default_schema" | "ldbc"     | "Node"      | "Person"     | LIST["firstName ASC"] |
    When executing query:
      """
      DROP INDEX idx_ldbc_no_graph_test
      """
    Then the execution should be successful
    And close the current session

  Scenario: Support full index scan
    When executing query:
      """
      USE ldbc {
      let ua1 = 23
      MATCH
          p0 = (v0)
      WHERE
          ((ua1 > v0.id) or (v0.id >= 20))
      RETURN count(p0) AS c
      }
      """
    Then the result should be, in any order:
      | c  |
      | 34 |

  Scenario: Both IndexScan and TableScan coexist
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS test_coexist_type as {
        NODE Person (LABELS Person{id int primary key, name STRING}),
        NODE Post (LABELS Post {id INT primary key,title STRING}),
        EDGE LIKES (Person)-[:LIKES{lname STRING}]->(Post),
        EDGE USED (Post)-[:LIKES{lname STRING}]->(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH test_coexist test_coexist_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE test_coexist CREATE INDEX IF NOT EXISTS idx_like ON EDGE LIKES ( lname ASC )
      """
    Then the execution should be successful
    When executing query:
      """
      USE test_coexist CREATE INDEX IF NOT EXISTS idx_person ON NODE Person ( name ASC )
      """
    Then the execution should be successful
    When executing query:
      """
      USE test_coexist insert (a@Person{id:1, name:"Judge"})-[@LIKES{lname:"Very"}]->(b@Post{id:1, title:"hhhh"})
      """
    Then the execution should be successful
    When executing query:
      """
      USE test_coexist
      LET a = "sad"
      MATCH (x)
      WHERE x.name = "Judge"
      RETURN x.name AS name
      """
    Then the result should be, in any order:
      | name    |
      | "Judge" |
    When executing query:
      """
      USE test_coexist {
      MATCH
          ()-[e0@LIKES]->()
      MATCH
          (v4)
      WHERE
          (type(e0) = v4.name)
      RETURN
          true
      }
      """
    Then the result should be, in any order:
      | true |
    And drop the index "idx_like" of "test_coexist"
    And drop the index "idx_person" of "test_coexist"
    And drop the graph "test_coexist"
    And drop the graph type "test_coexist_type"
