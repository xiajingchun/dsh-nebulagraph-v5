# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: Temporary graph

  Scenario: Subgraph
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS gt_tempoary_graph_pbd AS {
        NODE person (LABEL person {id INT PRIMARY KEY}),
        NODE dog (LABEL dog {id INT PRIMARY KEY}),
        EDGE bought (person)-[LABEL bought]->(dog)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS g_tempoary_graph_pbd TYPED gt_tempoary_graph_pbd
      """
    Then the execution should be successful
    When executing query:
      """
      USE g_tempoary_graph_pbd
      INSERT (@person {id:1}), (@person {id: 2}), (@dog {id: 3}), (@dog {id: 4})
      """
    Then the execution should be successful
    When executing query:
      """
      USE g_tempoary_graph_pbd
      MATCH (p:person {id:1}), (d3:dog {id:3}), (d4:dog {id:4})
      INSERT (p)-[@bought]->(d3), (p)-[@bought]->(d4)
      """
    Then the execution should be successful
    # without properties
    When executing query:
      """
      CREATE TEMPORARY GRAPH #p_tempoary_graph_pbd AS COPY OF g_tempoary_graph_pbd OPTIONS {without_properties: true, immutable: true}
      """
    Then the execution should be successful
    When executing query:
      """
      USE #p_tempoary_graph_pbd SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 4         |
      | "Edge Total" | "Edge"       | 2         |
    When executing query:
      """
      USE #p_tempoary_graph_pbd
      MATCH ()-[]->()
      RETURN count(*) AS num GROUP BY ()
      """
    Then the result should be, in any order:
      | num |
      | 2   |
    When executing query:
      """
      USE #p_tempoary_graph_pbd
      MATCH (v {id:1})
      RETURN v.id
      """
    Then the result should be, in any order:
      | v.id |
      | 1    |
    And drop the graph "#p_tempoary_graph_pbd"
    # all nodes
    When executing query:
      """
      CREATE TEMPORARY GRAPH #p_tempoary_graph_pbd AS COPY OF
      GRAPH { USE g_tempoary_graph_pbd MATCH (v) RETURN v } OPTIONS {immutable: true}
      """
    Then the execution should be successful
    When executing query:
      """
      USE #p_tempoary_graph_pbd
      MATCH ()
      RETURN count(*) AS num GROUP BY ()
      """
    Then the result should be, in any order:
      | num |
      | 4   |
    When executing query:
      """
      USE #p_tempoary_graph_pbd
      MATCH ()-[]->()
      RETURN count(*) AS num GROUP BY ()
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `-[]->` was found"
    And drop the graph "#p_tempoary_graph_pbd"
    # all dogs
    When executing query:
      """
      CREATE TEMPORARY GRAPH #p_tempoary_graph_pbd AS COPY OF
      GRAPH { USE g_tempoary_graph_pbd MATCH (d:dog) RETURN d } OPTIONS {immutable: true}
      """
    Then the execution should be successful
    When executing query:
      """
      USE #p_tempoary_graph_pbd
      MATCH ()
      RETURN count(*) AS num GROUP BY ()
      """
    Then the result should be, in any order:
      | num |
      | 2   |
    When executing query:
      """
      USE #p_tempoary_graph_pbd
      MATCH (v:person)
      RETURN count(*) AS num GROUP BY ()
      """
    # TODO(wuu): this error message may be confusing, because we use the same graph type name
    Then an Error should be raised: "[NS228]: node label `person` not found in graph type `gt_tempoary_graph_pbd`"
    And drop the graph "#p_tempoary_graph_pbd"
    # all person 1 related
    When executing query:
      """
      CREATE TEMPORARY GRAPH #p_tempoary_graph_pbd AS COPY OF
      GRAPH { USE g_tempoary_graph_pbd MATCH (p:person {id:1})-[b]->(d) RETURN p, b, d }
      """
    Then the execution should be successful
    When executing query:
      """
      USE #p_tempoary_graph_pbd
      MATCH (v)
      RETURN v.id AS id
      """
    Then the result should be, in any order:
      | id |
      | 1  |
      | 3  |
      | 4  |
    When executing query:
      """
      USE #p_tempoary_graph_pbd
      MATCH ()-[]->(d)
      RETURN d.id AS id
      """
    Then the result should be, in any order:
      | id |
      | 3  |
      | 4  |
    When executing query:
      """
      CALL temporary_graph_compact("#p_tempoary_graph_pbd")
      RETURN *
      """
    Then the execution should be successful
    When executing query:
      """
      CALL temporary_graph_compact("#p_tempoary_graph_pbd", 0)
      RETURN *
      """
    Then the execution should be successful
    When executing query:
      """
      CALL temporary_graph_compact("#p_tempoary_graph_pbd", 28)
      RETURN *
      """
    Then the execution should be successful
    When executing query:
      """
      CALL temporary_graph_compact("#p_tempoary_graph_pbd", 200)
      RETURN *
      """
    Then an Error should be raised: "[NP102]: Invalid argument for procedure `temporary_graph_compact`: score should be in range [0, 100]"
    When executing query:
      """
      CALL temporary_graph_compact("#not_exist_temp_graph")
      RETURN *
      """
    Then an Error should be raised: "[NR123]: Temporary graph not found: `#not_exist_temp_graph`"
    And drop the graph "#p_tempoary_graph_pbd"
    And drop the graph "g_tempoary_graph_pbd"
    And drop the graph type "gt_tempoary_graph_pbd"

  Scenario: Mutable Subgraph
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS gt_mutable_temp_graph_pbd AS {
        NODE person (LABEL person {id INT PRIMARY KEY, name string, age int}),
        NODE dog (LABEL dog {id INT PRIMARY KEY, name string}),
        EDGE bought (person)-[LABEL bought {year:: int}]->(dog)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS g_mutable_temp_graph_pbd TYPED gt_mutable_temp_graph_pbd
      """
    Then the execution should be successful
    When executing query:
      """
      USE g_mutable_temp_graph_pbd
      INSERT (@person {id:1, name: "alice", age: 20}), (@person {id: 2, name: "bob", age: 21}), (@dog {id: 3, name: "dog1"}), (@dog {id: 4, name: "dog2"})
      """
    Then the execution should be successful
    When executing query:
      """
      USE g_mutable_temp_graph_pbd
      MATCH (p:person {id:1}), (d3:dog {id:3}), (d4:dog {id:4})
      INSERT (p)-[@bought {year: 2023}]->(d3), (p)-[@bought {year: 2024}]->(d4)
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH #p_mutable_temp_graph_pbd AS COPY OF g_mutable_temp_graph_pbd
      """
    Then the execution should be successful
    When executing query:
      """
      USE #p_mutable_temp_graph_pbd SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 4         |
      | "Edge Total" | "Edge"       | 2         |
      | "person"     | "Node"       | 2         |
      | "dog"        | "Node"       | 2         |
      | "bought"     | "Edge"       | 2         |
    When executing query:
      """
      CREATE TEMPORARY GRAPH #p_mutable_temp_graph_pbd AS COPY OF g_mutable_temp_graph_pbd
      """
    Then an Error should be raised: "[NR122]: Temporary graph already existed"
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #p_mutable_temp_graph_pbd AS COPY OF g_mutable_temp_graph_pbd
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #mut_graph_without_properties AS COPY OF g_mutable_temp_graph_pbd OPTIONS {without_properties: true}
      """
    Then the execution should be successful
    # When without_properties is set, PK properties remain
    When executing query:
      """
      USE #mut_graph_without_properties
      MATCH (v) RETURN v.id
      """
    Then the result should be, in any order:
      | v.id |
      | 1    |
      | 2    |
      | 3    |
      | 4    |
    When executing query:
      """
      USE #p_mutable_temp_graph_pbd
      INSERT (a@person {id:5, name: "charlie", age: 22}), (b@dog {id:5, name: "dog3"}), (a)-[@bought {year: 2025}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 2     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #p_mutable_temp_graph_pbd SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 6         |
      | "Edge Total" | "Edge"       | 3         |
      | "person"     | "Node"       | 3         |
      | "dog"        | "Node"       | 3         |
      | "bought"     | "Edge"       | 3         |
    When executing query:
      """
      USE #p_mutable_temp_graph_pbd
      MATCH (v)-[e]->(v2) return v.id, v.name, v.age, e.year, v2.id, v2.name
      """
    Then the result should be, in any order:
      | v.id | v.name    | v.age | e.year | v2.id | v2.name |
      | 1    | "alice"   | 20    | 2023   | 3     | "dog1"  |
      | 1    | "alice"   | 20    | 2024   | 4     | "dog2"  |
      | 5    | "charlie" | 22    | 2025   | 5     | "dog3"  |
    When executing query:
      """
      USE #p_mutable_temp_graph_pbd
      MATCH (v)-[e]->(v2)
      SET v.age = v.age + 10, e.year = e.year + 20
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 2     |
      | "num_affected_edges" | 3     |
    When executing query:
      """
      USE #p_mutable_temp_graph_pbd
      MATCH (v)-[e]->(v2)
      RETURN v.id, v.name, v.age, e.year, v2.id, v2.name
      """
    Then the result should be, in any order:
      | v.id | v.name    | v.age | e.year | v2.id | v2.name |
      | 1    | "alice"   | 30    | 2043   | 3     | "dog1"  |
      | 1    | "alice"   | 30    | 2044   | 4     | "dog2"  |
      | 5    | "charlie" | 32    | 2045   | 5     | "dog3"  |
    When executing query:
      """
      USE #p_mutable_temp_graph_pbd
      INSERT (p@person {id:6, name: "david", age: 23}), (d@dog {id:6, name: "dog4"})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 2     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #p_mutable_temp_graph_pbd
      MATCH (a)
      DELETE a
      """
    Then an Error should be raised: "[G1000]: Dependent object error"
    When executing query:
      """
      USE #p_mutable_temp_graph_pbd
      MATCH (a)-[e]->(b)
      DELETE a, e, b
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 5     |
      | "num_affected_edges" | 3     |
    When executing query:
      """
      CREATE TEMPORARY GRAPH #mut_subquery_graph AS COPY OF
      GRAPH { USE g_mutable_temp_graph_pbd MATCH (p:person {id:1})-[b]->(d) RETURN p, b, d }
      """
    Then the execution should be successful
    When executing query:
      """
      USE #mut_subquery_graph
      MATCH (v)
      RETURN v.id AS id
      """
    Then the result should be, in any order:
      | id |
      | 1  |
      | 3  |
      | 4  |
    When executing query:
      """
      USE #mut_subquery_graph
      INSERT (v1@person {id:11, name: "alice11", age: 20}), (v2@person {id: 12, name: "bob12", age: 21}), (d1@dog {id: 13, name: "dog13"}),
             (v1)-[e:bought {year: 2023}]->(d1)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 3     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #mut_subquery_graph
      MATCH (v)-[e]->(v2)
      RETURN v.id, v2.id, e.year
      """
    Then the result should be, in any order:
      | v.id | v2.id | e.year |
      | 11   | 13    | 2023   |
      | 1    | 3     | 2023   |
      | 1    | 4     | 2024   |
    When executing query:
      """
      CREATE TEMPORARY GRAPH #mut_empty_graph TYPED gt_mutable_temp_graph_pbd
      """
    Then the execution should be successful
    When executing query:
      """
      USE #mut_empty_graph
      INSERT (v1@person {id:1, name: "alice", age: 20}), (v2@person {id: 2, name: "bob", age: 21}), (d1@dog {id: 3, name: "dog1"}),
             (v1)-[e:bought {year: 2023}]->(d1)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 3     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #mut_empty_graph
      MATCH (p)-[e]->(d)
      RETURN p.id, d.id, e.year
      """
    Then the result should be, in any order:
      | p.id | d.id | e.year |
      | 1    | 3    | 2023   |
    And drop the graph "#mut_graph_without_properties"
    And drop the graph "#mut_empty_graph"
    And drop the graph "#mut_subquery_graph"
    And drop the graph "#p_mutable_temp_graph_pbd"
    And drop the graph "g_mutable_temp_graph_pbd"
    And drop the graph type "gt_mutable_temp_graph_pbd"

  Scenario: Mutable temporary graph indexes
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS gt_temp_index_test AS {
        NODE person (LABEL person {id INT PRIMARY KEY, age INT, name STRING}),
        EDGE knows (person)-[LABEL knows {weight INT}]->(person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS g_temp_index_test TYPED gt_temp_index_test
      """
    Then the execution should be successful
    # Insert test data into disk graph
    When executing query:
      """
      USE g_temp_index_test
      INSERT (p1@person {id:1, age:25, name:"Alice"}),
             (p2@person {id:2, age:30, name:"Bob"}),
             (p3@person {id:3, age:25, name:"Charlie"}),
             (p4@person {id:4, age:35, name:"David"}),
             (p1)-[@knows {weight:80}]->(p2),
             (p2)-[@knows {weight:90}]->(p3),
             (p3)-[@knows {weight:85}]->(p4)
      """
    Then the execution should be successful
    When executing query:
      """
      USE g_temp_index_test CREATE INDEX IF NOT EXISTS person_name_idx ON NODE person(id)
      """
    Then the execution should be successful
    # Create mutable temporary graph from disk graph - should inherit primary key index automatically
    When executing query:
      """
      CREATE TEMPORARY GRAPH #temp_index_graph AS COPY OF g_temp_index_test
      """
    Then the execution should be successful
    # Note: Only primary key index of original graph is automatically inherited by temporary graph while `SHOW INDEXES` only show non-primary key indexes, so the result is empty
    When executing query:
      """
      USE #temp_index_graph SHOW INDEXES
      """
    Then the result should be, in any order:
      | name | state | index_type | schema | graph_name | entity_type | element_type | properties |
    # Create indexes directly on the temporary graph
    When executing query:
      """
      USE #temp_index_graph CREATE INDEX IF NOT EXISTS person_age_idx ON NODE person(age)
      """
    Then the execution should be successful
    When executing query:
      """
      USE #temp_index_graph CREATE INDEX IF NOT EXISTS person_non_exist_prop_idx ON NODE person(non_exist_prop)
      """
    Then an Error should be raised: "[NC006]: Property `non_exist_prop` of type `person` not found"
    When executing query:
      """
      USE #temp_index_graph CREATE INDEX IF NOT EXISTS person_age_name_idx ON NODE person(age, name)
      """
    Then the execution should be successful
    When executing query:
      """
      USE #temp_index_graph CREATE INDEX IF NOT EXISTS knows_weight_idx ON EDGE knows(weight)
      """
    Then the execution should be successful
    When executing query:
      """
      USE #temp_index_graph SHOW INDEXES
      """
    Then the result should be, in any order:
      | name                  | state   | index_type | schema        | graph_name          | entity_type | element_type | properties                  |
      | "person_age_idx"      | "Valid" | "Normal"   | "/tmp_schema" | "#temp_index_graph" | "Node"      | "person"     | LIST ["age ASC"]            |
      | "person_age_name_idx" | "Valid" | "Normal"   | "/tmp_schema" | "#temp_index_graph" | "Node"      | "person"     | LIST ["age ASC","name ASC"] |
      | "knows_weight_idx"    | "Valid" | "Normal"   | "/tmp_schema" | "#temp_index_graph" | "Edge"      | "knows"      | LIST ["weight ASC"]         |
    # Test primary key index query (should work automatically)
    When executing query:
      """
      USE #temp_index_graph
      MATCH (p:person {id:2})
      RETURN p.id, p.name, p.age
      """
    Then the result should be, in any order:
      | p.id | p.name | p.age |
      | 2    | "Bob"  | 30    |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE #temp_index_graph
      MATCH (p:person) WHERE p.age = 25
      RETURN p.id, p.name, p.age
      """
    Then the result should be, in any order:
      | p.id | p.name    | p.age |
      | 1    | "Alice"   | 25    |
      | 3    | "Charlie" | 25    |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE #temp_index_graph
      MATCH (p:person) WHERE p.age = 25 AND p.name = "Alice"
      RETURN p.id, p.name, p.age
      """
    Then the result should be, in any order:
      | p.id | p.name  | p.age |
      | 1    | "Alice" | 25    |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE #temp_index_graph
      MATCH (p1:person)-[k:knows WHERE k.weight = 90]->(p2:person)
      RETURN p1.name, p2.name, k.weight
      """
    Then the result should be, in any order:
      | p1.name | p2.name   | k.weight |
      | "Bob"   | "Charlie" | 90       |
    And the plan should contain "IndexScan"
    # Insert more data to test index updates
    When executing query:
      """
      USE #temp_index_graph
      INSERT (p5@person {id:5, age:28, name:"Eve"}),
             (p6@person {id:6, age:25, name:"Frank"}),
             (p5)-[@knows {weight:95}]->(p6)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 2     |
      | "num_affected_edges" | 1     |
    # Test index still works after insertion
    When executing query:
      """
      USE #temp_index_graph
      MATCH (p:person) WHERE p.age = 25
      RETURN p.id, p.name, p.age
      """
    Then the result should be, in any order:
      | p.id | p.name    | p.age |
      | 1    | "Alice"   | 25    |
      | 3    | "Charlie" | 25    |
      | 6    | "Frank"   | 25    |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE #temp_index_graph
      MATCH (p1:person)-[k:knows]->(p2:person) WHERE k.weight = 95
      RETURN p1.name, p2.name, k.weight
      """
    Then the result should be, in any order:
      | p1.name | p2.name | k.weight |
      | "Eve"   | "Frank" | 95       |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE #temp_index_graph
      MATCH (p:person) WHERE p.age >= 25 AND p.age <= 30
      RETURN p.id, p.name, p.age
      """
    Then the result should be, in any order:
      | p.id | p.name    | p.age |
      | 1    | "Alice"   | 25    |
      | 2    | "Bob"     | 30    |
      | 3    | "Charlie" | 25    |
      | 5    | "Eve"     | 28    |
      | 6    | "Frank"   | 25    |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE #temp_index_graph
      MATCH (p1:person)-[k:knows]->(p2:person) WHERE k.weight >= 85 AND k.weight <= 95
      RETURN p1.name, p2.name, k.weight
      """
    Then the result should be, in any order:
      | p1.name   | p2.name   | k.weight |
      | "Charlie" | "David"   | 85       |
      | "Bob"     | "Charlie" | 90       |
      | "Eve"     | "Frank"   | 95       |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE #temp_index_graph
      MATCH (p:person/*+ index(person_age_idx) */) WHERE p.age = 25
      RETURN p.id, p.name, p.age
      """
    Then the result should be, in any order:
      | p.id | p.name    | p.age |
      | 1    | "Alice"   | 25    |
      | 3    | "Charlie" | 25    |
      | 6    | "Frank"   | 25    |
    # drop and recreate same index name should succeed
    When executing query:
      """
      USE #temp_index_graph DROP INDEX person_age_idx
      """
    Then the execution should be successful
    When executing query:
      """
      USE #temp_index_graph CREATE INDEX person_age_idx ON NODE person(age)
      """
    Then the execution should be successful
    When executing query:
      """
      USE #temp_index_graph
      MATCH (p:person/*+ index(person_age_name_idx) */) WHERE p.age = 25
      RETURN p.id, p.name, p.age
      """
    Then the result should be, in any order:
      | p.id | p.name    | p.age |
      | 1    | "Alice"   | 25    |
      | 3    | "Charlie" | 25    |
      | 6    | "Frank"   | 25    |
    When executing query:
      """
      CREATE TEMPORARY GRAPH #empty_temp_index TYPED gt_temp_index_test
      """
    Then the execution should be successful
    # Create indexes on empty temporary graph
    When executing query:
      """
      USE #empty_temp_index CREATE INDEX IF NOT EXISTS empty_person_age_idx ON NODE person(age)
      """
    Then the execution should be successful
    When executing query:
      """
      USE #empty_temp_index CREATE INDEX IF NOT EXISTS empty_knows_weight_idx ON EDGE knows(weight)
      """
    Then the execution should be successful
    # Insert data into empty temporary graph
    When executing query:
      """
      USE #empty_temp_index
      INSERT (p1@person {id:1, age:20, name:"Alice"}),
             (p2@person {id:2, age:25, name:"Bob"}),
             (p1)-[@knows {weight:70}]->(p2)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 2     |
      | "num_affected_edges" | 1     |
    # Test indexes work on empty graph after data insertion
    When executing query:
      """
      USE #empty_temp_index
      MATCH (p:person) WHERE p.age = 20
      RETURN p.id, p.name, p.age
      """
    Then the result should be, in any order:
      | p.id | p.name  | p.age |
      | 1    | "Alice" | 20    |
    And the plan should contain "IndexScan"
    When executing query:
      """
      USE #empty_temp_index
      MATCH (p1:person)-[k:knows]->(p2:person) WHERE k.weight = 70
      RETURN p1.name, p2.name, k.weight
      """
    Then the result should be, in any order:
      | p1.name | p2.name | k.weight |
      | "Alice" | "Bob"   | 70       |
    And the plan should contain "IndexScan"
    When executing query:
      """
      CREATE TEMPORARY GRAPH #analytic_ldbc_immutable AS COPY OF ldbc OPTIONS {immutable:true}
      """
    Then the execution should be successful
    When executing query:
      """
      USE #analytic_ldbc_immutable CREATE INDEX IF NOT EXISTS dist_graph_person_last_name_idx ON NODE Person(lastName)
      """
    Then an Error should be raised: "[NC304]: Illegal DDL: Create index is not supported for immutable temporary graph"
    And drop the graph "#analytic_ldbc_immutable"
    And drop the graph "#empty_temp_index"
    And drop the graph "#temp_index_graph"
    And drop the graph "g_temp_index_test"
    And drop the graph type "gt_temp_index_test"

  @sf01
  Scenario: Mem set and delete on large data
    When executing query:
      """
      CREATE TEMPORARY GRAPH #mem_delete_sf01 AS COPY OF sf01
      """
    Then the execution should be successful
    # Check Person count (>1024) to ensure bulk update coverage
    When executing query:
      """
      USE #mem_delete_sf01
      MATCH (p:Person)
      RETURN count(*) AS num
      """
    Then the result should be, in any order:
      | num  |
      | 1528 |
    # Bulk Mem SET for all Person nodes; affected nodes should equal 1528
    When executing query:
      """
      USE #mem_delete_sf01
      MATCH (p:Person)
      SET p.browserUsed = "MemSetAgent"
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1528  |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE #mem_delete_sf01
      MATCH ()-[e]->()
      RETURN COUNT(*) AS cnt
      """
    Then the result should be, in any order:
      | cnt     |
      | 1477965 |
    # Delete all edges in the temporary graph
    When executing query:
      """
      USE #mem_delete_sf01
      MATCH ()-[e]->()
      DELETE e
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value   |
      | "num_affected_nodes" | 0       |
      | "num_affected_edges" | 1477965 |
    # Verify no edges remain
    When executing query:
      """
      USE #mem_delete_sf01
      MATCH ()-[]->()
      RETURN count(*) AS num
      """
    Then the result should be, in any order:
      | num |
      | 0   |
    # A second delete should affect 0 edges
    When executing query:
      """
      USE #mem_delete_sf01
      MATCH ()-[e]->()
      DELETE e
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    And drop the graph "#mem_delete_sf01"

  # Skipped because the element id generated by MutGraph is not stable
  @skip
  Scenario: Node id prefix scan on mutable temporary graph
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS gt_mem_graph_prefix_scan AS {
        NODE person (LABEL person {id INT PRIMARY KEY})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #mem_graph_prefix_scan TYPED gt_mem_graph_prefix_scan
      """
    Then the execution should be successful
    When executing query:
      """
      USE #mem_graph_prefix_scan
      INSERT (v1@person {id:1}), (v2@person {id:2}), (v3@person {id:3})
      """
    Then the execution should be successful
    When executing query:
      """
      USE #mem_graph_prefix_scan
      MATCH (v:person)
      RETURN v.id AS id, element_id(v) AS vid
      """
    Then the result should be, in any order:
      | id | vid                |
      | 3  | 288366431809568768 |
      | 2  | 288366431809568769 |
      | 1  | 288366431809568770 |
    When executing query:
      """
      USE #mem_graph_prefix_scan
      MATCH (v:person) WHERE element_id(v) = 288366431809568769
      RETURN v.id AS id, element_id(v) AS vid
      """
    Then the result should be, in any order:
      | id | vid                |
      | 2  | 288366431809568769 |
    When executing query:
      """
      USE #mem_graph_prefix_scan
      MATCH (v:person) WHERE element_id(v) IN [288366431809568770,288366431809568768]
      RETURN v.id AS id, element_id(v) AS vid
      """
    Then the result should be, in any order:
      | id | vid                |
      | 3  | 288366431809568768 |
      | 1  | 288366431809568770 |
    # element id range is not supported
    When executing query:
      """
      USE #mem_graph_prefix_scan
      MATCH (v:person) WHERE element_id(v) >= 288366431809568768 AND element_id(v) <= 288366431809568770
      RETURN v.id AS id, element_id(v) AS vid
      """
    Then the result should be, in any order:
      | id | vid                |
      | 3  | 288366431809568768 |
      | 2  | 288366431809568769 |
      | 1  | 288366431809568770 |

  Scenario: Invalid element id
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Person) WHERE element_id(v) = 12345678912345
      RETURN count(*) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 0   |

  Scenario: Name prefix check
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS gt_tempoary_graph_p AS {
        NODE person (LABEL person {id INT PRIMARY KEY})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS #g_tempoary_graph_base TYPED gt_tempoary_graph_p
      """
    Then an Error should be raised: "[42001]: syntax error near `#g_tempoary_graph_base`"
    When executing query:
      """
      CREATE TEMPORARY GRAPH g_tempoary_graph_p AS COPY OF
      GRAPH { USE g_tempoary_graph_base MATCH (v:person {id:1}) RETURN v } OPTIONS {immutable: true}
      """
    Then an Error should be raised: "[42001]: syntax error near `g_tempoary_graph_p`"
    And drop the graph "g_tempoary_graph_p"
    And drop the graph type "gt_tempoary_graph_p"

  Scenario: Unsupported
    When executing query:
      """
      CREATE TEMPORARY GRAPH #const_ldbc_mem AS COPY OF ldbc OPTIONS {immutable: true}
      """
    Then the execution should be successful
    # insert
    When executing query:
      """
      USE #const_ldbc_mem
      INSERT (@Person {id:11})
      """
    Then an Error should be raised: "[NT501]: Unsupported temporary graph operation: insert on immutable temporary graph"
    # set
    When executing query:
      """
      USE #const_ldbc_mem
      MATCH (v:Person)
      SET v.id = v.id+5
      """
    Then an Error should be raised: "[NT501]: Unsupported temporary graph operation: set on immutable temporary graph"
    # delete
    When executing query:
      """
      USE #const_ldbc_mem
      MATCH (a:Person{id:1})
      DELETE a
      """
    Then an Error should be raised: "[NT501]: Unsupported temporary graph operation: delete on immutable temporary graph"
    And drop the graph "#const_ldbc_mem"

  Scenario: Temp of temp
    When executing query:
      """
      CREATE TEMPORARY GRAPH #temp_of_temp AS COPY OF #analytic_ldbc OPTIONS {immutable: true}
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH #temp_of_temp_sub AS COPY OF
      GRAPH { USE #temp_of_temp MATCH (v) RETURN v } OPTIONS {immutable: true}
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW GRAPHS
      """
    Then the result should contain:
      | name                | graph_type  | schema        | owner  | extra               |
      | "#temp_of_temp"     | "ldbc_type" | "/tmp_schema" | "root" | "distributed:false" |
      | "#temp_of_temp_sub" | "ldbc_type" | "/tmp_schema" | "root" | "distributed:false" |
    And drop the graph "#temp_of_temp_sub"
    And drop the graph "#temp_of_temp"

  Scenario: Complicated
    # shortest path
    When executing query:
      """
      USE #analytic_ldbc
      MATCH p = ALL SHORTEST PATH (v:Person{id:1})->{1,3}(v)
      RETURN p
      """
    Then the execution should be successful

  Scenario: DDL on empty temp graph
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS temp_graph_type_ddl AS {
        NODE TYPE player (LABEL player {id INT PRIMARY KEY, name STRING}),
        EDGE TYPE follow (player)-[LABEL follow {score INT, MULTIEDGE KEY()}]->(player)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #empty_temp_graph TYPED temp_graph_type_ddl OPTIONS {immutable: true}
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW GRAPHS
      """
    Then the result should contain:
      | name                | graph_type            | schema        | owner  | extra               |
      | "#empty_temp_graph" | "temp_graph_type_ddl" | "/tmp_schema" | "root" | "distributed:false" |
    When executing query:
      """
      USE #empty_temp_graph SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 0         |
      | "Edge Total" | "Edge"       | 0         |
    When executing query:
      """
      USE #empty_temp_graph IMPORT INTO GRAPH
      {
        NODE (v@player{id:id, name:name}) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/mini_graph_csv_space/mini_graph_csv_space.v",
          delimiter: " "
        },
        EDGE (id:src_id)-[e@follow{score: score}]->(id:dst_id) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/mini_graph_csv_space/mini_graph_csv_space.e",
          delimiter: " "
        }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE #empty_temp_graph SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 5         |
      | "Edge Total" | "Edge"       | 6         |
    And drop the graph "#empty_temp_graph"
    And drop the graph type "temp_graph_type_ddl"

  Scenario: Import into mutable temporary graph from CSV
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS mut_graph_type_csv AS {
        NODE TYPE player (LABEL player {id INT PRIMARY KEY, name STRING}),
        EDGE TYPE follow (player)-[LABEL follow {score INT, MULTIEDGE KEY()}]->(player)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #mut_graph_csv TYPED mut_graph_type_csv
      """
    Then the execution should be successful
    When executing query:
      """
      USE #mut_graph_csv IMPORT INTO GRAPH
      {
        NODE (v@player{id:id, name:name}) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/empty_graph_csv_comma/empty_graph_csv_comma.v",
          delimiter: " "
        },
        EDGE (id:src_id)-[e@follow{score: score}]->(id:dst_id) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/empty_graph_csv_comma/empty_graph_csv_comma.e",
          delimiter: " "
        }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE #mut_graph_csv SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 0         |
      | "Edge Total" | "Edge"       | 0         |
      | "player"     | "Node"       | 0         |
      | "follow"     | "Edge"       | 0         |
    # Create non-PK indexes on the empty mutable temp graph, they must persist across IMPORT
    When executing query:
      """
      USE #mut_graph_csv CREATE INDEX IF NOT EXISTS player_name_idx ON NODE player(name)
      """
    Then the execution should be successful
    When executing query:
      """
      USE #mut_graph_csv CREATE INDEX IF NOT EXISTS follow_score_idx ON EDGE follow(score)
      """
    Then the execution should be successful
    # Verify indexes exist before import
    When executing query:
      """
      USE #mut_graph_csv SHOW INDEXES
      """
    Then the result should be, in any order:
      | name               | state   | index_type | schema        | graph_name       | entity_type | element_type | properties         |
      | "player_name_idx"  | "Valid" | "Normal"   | "/tmp_schema" | "#mut_graph_csv" | "Node"      | "player"     | LIST ["name ASC"]  |
      | "follow_score_idx" | "Valid" | "Normal"   | "/tmp_schema" | "#mut_graph_csv" | "Edge"      | "follow"     | LIST ["score ASC"] |
    When executing query:
      """
      USE #mut_graph_csv IMPORT INTO GRAPH
      {
        NODE (v@player{id:id, name:name}) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/mini_graph_csv_space/mini_graph_csv_space.v",
          delimiter: " "
        },
        EDGE (id:src_id)-[e@follow{score: score}]->(id:dst_id) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/mini_graph_csv_space/mini_graph_csv_space.e",
          delimiter: " "
        }
      }
      """
    Then the execution should be successful
    # Verify indexes still exist after import
    When executing query:
      """
      USE #mut_graph_csv SHOW INDEXES
      """
    Then the result should be, in any order:
      | name               | state   | index_type | schema        | graph_name       | entity_type | element_type | properties         |
      | "player_name_idx"  | "Valid" | "Normal"   | "/tmp_schema" | "#mut_graph_csv" | "Node"      | "player"     | LIST ["name ASC"]  |
      | "follow_score_idx" | "Valid" | "Normal"   | "/tmp_schema" | "#mut_graph_csv" | "Edge"      | "follow"     | LIST ["score ASC"] |
    When executing query:
      """
      USE #mut_graph_csv SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 5         |
      | "Edge Total" | "Edge"       | 6         |
      | "player"     | "Node"       | 5         |
      | "follow"     | "Edge"       | 6         |
    And drop the graph "#mut_graph_csv"
    And drop the graph type "mut_graph_type_csv"
    # Import into mutable temporary graph with wrong delimiter
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS mut_graph_type_csv_err AS {
        NODE TYPE player (LABEL player {id INT PRIMARY KEY, name STRING}),
        EDGE TYPE follow (player)-[LABEL follow {score INT, MULTIEDGE KEY()}]->(player)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #mut_graph_csv_wrong_delimiter TYPED mut_graph_type_csv_err
      """
    Then the execution should be successful
    When executing query:
      """
      USE #mut_graph_csv_wrong_delimiter IMPORT INTO GRAPH
      {
        NODE (v@player{id:id, name:name}) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/mini_graph_csv_comma/mini_graph_csv_comma.v",
          delimiter: " ",
          include_columns: ["id","name"]
        },
        EDGE (id:src_id)-[e@follow{score: score}]->(id:dst_id) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/mini_graph_csv_comma/mini_graph_csv_comma.e"
        }
      }
      """
    Then an Error should be raised: "error: Key error: Column 'id' in include_columns does not exist in CSV file"
    And drop the graph "#mut_graph_csv_wrong_delimiter"
    And drop the graph type "mut_graph_type_csv_err"

  Scenario: Invalid options for temporary graph
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS gt_temp_graph_opts AS {
        NODE person (LABEL person {id INT PRIMARY KEY})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS g_temp_graph_opts TYPED gt_temp_graph_opts
      """
    Then the execution should be successful
    # PRIMARY_KEY_AS_NODE_ID on non-CSR (mutable, single-machine)
    When executing query:
      """
      CREATE TEMPORARY GRAPH #opt_err_pk AS COPY OF g_temp_graph_opts OPTIONS { primary_key_as_node_id: true }
      """
    Then an Error should be raised: "[NI000]: Invalid parameter: PRIMARY_KEY_AS_NODE_ID"
    # WITHOUT_PROPERTIES with subquery projection
    When executing query:
      """
      CREATE TEMPORARY GRAPH #opt_err_drop_prop_sub AS COPY OF GRAPH { USE g_temp_graph_opts MATCH (v) RETURN v } OPTIONS { without_properties: true }
      """
    Then an Error should be raised: "[NI000]: Invalid parameter: WITHOUT_PROPERTIES is only allowed with full graph projection"
    # WITHOUT_PROPERTIES with empty projection
    When executing query:
      """
      CREATE TEMPORARY GRAPH #opt_err_drop_prop_empty TYPED gt_temp_graph_opts OPTIONS { without_properties: true }
      """
    Then an Error should be raised: "[NI000]: Invalid parameter: WITHOUT_PROPERTIES is only allowed with full graph projection"
    And drop the graph "g_temp_graph_opts"
    And drop the graph type "gt_temp_graph_opts"

  Scenario: Mutable graph computing with local id map rebuild
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS gt_mut_computing AS {
        NODE person (LABEL person {id INT PRIMARY KEY, name STRING, age INT}),
        NODE company (LABEL company {id INT PRIMARY KEY, name STRING}),
        EDGE works_at (person)-[LABEL works_at {since INT}]->(company),
        EDGE knows (person)-[LABEL knows {weight DOUBLE}]->(person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH #mut_computing_graph TYPED gt_mut_computing
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE PROCEDURE IF NOT EXISTS graph_stats() RETURNS (edges INT, persons INT) AS {
        VALUE total_edges SumAgg<INT> = 0
        VALUE total_persons SumAgg<INT> = 0

        // Count all edges and path information
        MATCH (p:person)-[e]->(target)
        PER PATH {
          SET @total_edges += 1
        }

        // Count all person nodes
        MATCH (person_node:person)
        PER NODE (person_node) {
          SET @total_persons += 1
        }

        RETURN @total_edges AS edges, @total_persons AS persons
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE PROCEDURE IF NOT EXISTS person_degrees() RETURNS (person_id INT, degree INT) AS {
        NODE VALUE out_degree SumAgg<INT> = 0
        TABLE result_table TYPED TABLE {person_id INT, degree INT}

        MATCH (p:person)-[e]->(target)
        PER PATH {
          SET p.@out_degree += 1
        }

        MATCH (result_person:person)
        PER NODE (result_person) {
          EXPORT result_person.id, result_person.@out_degree INTO result_table
        }

        FOR r IN result_table
        RETURN r.person_id, r.degree
      }
      """
    Then the execution should be successful
    # Insert initial data
    When executing query:
      """
      USE #mut_computing_graph
      INSERT (p1@person {id:1, name: "alice", age: 25}),
             (p2@person {id:2, name: "bob", age: 30}),
             (c1@company {id:101, name: "tech_corp"}),
             (p1)-[@works_at {since: 2020}]->(c1),
             (p1)-[@knows {weight: 0.8}]->(p2)
      """
    Then the execution should be successful
    # First run of graph computing - initial state
    When executing query:
      """
      USE #mut_computing_graph
      CALL graph_stats() RETURN *
      """
    Then the result should be, in any order:
      | edges | persons |
      | 2     | 2       |
    # Insert more data
    When executing query:
      """
      USE #mut_computing_graph
      MATCH (p1:person {id:1}), (p2:person {id:2})
      INSERT (p3@person {id:3, name: "charlie", age: 28}),
             (c2@company {id:102, name: "startup"}),
             (p2)-[@works_at {since: 2021}]->(c2),
             (p2)-[@knows {weight: 0.9}]->(p3),
             (p3)-[@knows {weight: 0.7}]->(p1)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 2     |
      | "num_affected_edges" | 3     |
    # Second run of same graph computing - after data insertion
    When executing query:
      """
      USE #mut_computing_graph
      CALL graph_stats() RETURN *
      """
    Then the result should be, in any order:
      | edges | persons |
      | 5     | 3       |
    # Check out-degree statistics for each person
    When executing query:
      """
      USE #mut_computing_graph
      CALL person_degrees() RETURN person_id, degree
      """
    Then the result should be, in any order:
      | person_id | degree |
      | 1         | 2      |
      | 2         | 2      |
      | 3         | 1      |
    # Delete some data
    When executing query:
      """
      USE #mut_computing_graph
      MATCH (p:person {id:3})-[e]->(target)
      DELETE e
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    # Third run of same graph computing - after edge deletion
    When executing query:
      """
      USE #mut_computing_graph
      CALL graph_stats() RETURN *
      """
    Then the result should be, in any order:
      | edges | persons |
      | 4     | 3       |
    When executing query:
      """
      USE #mut_computing_graph
      CALL person_degrees() RETURN person_id, degree
      """
    Then the result should be, in any order:
      | person_id | degree |
      | 1         | 2      |
      | 2         | 2      |
      | 3         | 0      |
    And drop the graph "#mut_computing_graph"
    And drop the graph type "gt_mut_computing"

  # Conflict actions on mutable temporary graph
  Scenario: Mem insert conflict actions on ldbc
    When executing query:
      """
      CREATE TEMPORARY GRAPH #ldbc_mem_conflict AS COPY OF ldbc
      """
    Then the execution should be successful
    # 1) First insertion: no conflicts
    When executing query:
      """
      USE #ldbc_mem_conflict
      INSERT (p1@Person {id: 7000, firstName: "Alice"}),
             (p2@Person {id: 7001, firstName: "Bob"}),
             (p1)-[@KNOWS {creationDate: local_datetime("2025-01-01T00:00:00", "%Y-%m-%dT%H:%M:%S") }]->(p2)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 2     |
      | "num_affected_edges" | 1     |
    # 2) Re-run with default THROW: should raise primary key violation on nodes
    When executing query:
      """
      USE #ldbc_mem_conflict
      INSERT (p1@Person {id: 7000, firstName: "Alice"}),
             (p2@Person {id: 7001, firstName: "Bob"}),
             (p1)-[@KNOWS {creationDate: local_datetime("2025-01-01T00:00:00", "%Y-%m-%dT%H:%M:%S") }]->(p2)
      """
    Then an Error should be raised: "[NR205]: Insert node failed, primary key constraint violation"
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    # 3) OR IGNORE: no data changes
    When executing query:
      """
      USE #ldbc_mem_conflict
      INSERT OR IGNORE (p1@Person {id: 7000, firstName: "Alice"}),
                        (p2@Person {id: 7001, firstName: "Bob"}),
                        (p1)-[@KNOWS {creationDate: local_datetime("2025-02-01T00:00:00", "%Y-%m-%dT%H:%M:%S") }]->(p2)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    # verify unchanged
    When executing query:
      """
      USE #ldbc_mem_conflict
      MATCH (a:Person)-[k:KNOWS]->(b:Person)
      WHERE a.id = 7000 AND b.id = 7001
      RETURN a.id, a.firstName, k.creationDate, b.id, b.firstName
      """
    Then the result should be, in any order:
      | a.id | a.firstName | k.creationDate                    | b.id | b.firstName |
      | 7000 | "Alice"     | DATETIME '2025-01-01T00:00:00000' | 7001 | "Bob"       |
    # 4) OR REPLACE: overwrite all properties
    When executing query:
      """
      USE #ldbc_mem_conflict
      INSERT OR REPLACE (p1@Person {id: 7000, firstName: "Alice_r"}),
                         (p2@Person {id: 7001, firstName: "Bob_r"}),
                         (p1)-[@KNOWS {creationDate: local_datetime("2025-03-01T00:00:00", "%Y-%m-%dT%H:%M:%S") }]->(p2)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 2     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #ldbc_mem_conflict
      MATCH (a:Person)-[k:KNOWS]->(b:Person)
      WHERE a.id = 7000 AND b.id = 7001
      RETURN a.firstName, k.creationDate, b.firstName
      """
    Then the result should be, in any order:
      | a.firstName | k.creationDate                    | b.firstName |
      | "Alice_r"   | DATETIME '2025-03-01T00:00:00000' | "Bob_r"     |
    # 5) OR UPDATE: update only specified properties
    When executing query:
      """
      USE #ldbc_mem_conflict
      MATCH (p2:Person {id: 7001})
      INSERT OR UPDATE (p1@Person {id: 7000, firstName: "Alice_u"}),
                        (p1)-[@KNOWS {creationDate: local_datetime("2025-04-01T00:00:00", "%Y-%m-%dT%H:%M:%S") }]->(p2)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #ldbc_mem_conflict
      MATCH (a:Person)-[k:KNOWS]->(b:Person)
      WHERE a.id = 7000 AND b.id = 7001
      RETURN a.firstName, k.creationDate, b.firstName
      """
    Then the result should be, in any order:
      | a.firstName | k.creationDate                    | b.firstName |
      | "Alice_u"   | DATETIME '2025-04-01T00:00:00000' | "Bob_r"     |
    And drop the graph "#ldbc_mem_conflict"

  Scenario: Mixed directed and undirected edges
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS gt_mut_undirected AS {
         NODE Person (LABEL Person {id INT PRIMARY KEY,name STRING}),
         NODE Post (LABEL Post {id INT PRIMARY KEY,title STRING}),
         EDGE PERSON_KNOWS_PERSON (Person)~[:KNOWS{degree int default 10}]~(Person),
         EDGE POST_CREATE_BY_PERSON (Post)<-[:CREATE_BY{degree int default 10}]-(Person),
         EDGE PERSON_LIKES_POST (Person)-[:LIKES{degree int default 10}]->(Post)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH g_mut_undirected gt_mut_undirected
      """
    Then the execution should be successful
    When executing query:
      """
      USE g_mut_undirected
      INSERT
      (post_10@Post{id:10,title:"测试tempGraph"})<-[@POST_CREATE_BY_PERSON{}]-(person_11@Person{id:11,name:"person_11"}),
      (person_12@Person{id:12,name:"person_12"})-[@PERSON_LIKES_POST{}]->(post_10),
      (person_13@Person{id:13,name:"person_13"})~[@PERSON_KNOWS_PERSON{}]~(person_11),
      (person_13)~[@PERSON_KNOWS_PERSON{}]~(person_12)
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH #g_mut_undirected
      AS COPY OF GRAPH { USE g_mut_undirected MATCH (s)-[e]-(d) RETURN * }
      """
    Then the execution should be successful
    When executing query:
      """
      USE #g_mut_undirected SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name              | element_type | total_num |
      | "Node Total"            | "Node"       | 4         |
      | "Edge Total"            | "Edge"       | 4         |
      | "Person"                | "Node"       | 3         |
      | "Post"                  | "Node"       | 1         |
      | "PERSON_KNOWS_PERSON"   | "Edge"       | 2         |
      | "POST_CREATE_BY_PERSON" | "Edge"       | 1         |
      | "PERSON_LIKES_POST"     | "Edge"       | 1         |
    And drop the graph "#g_mut_undirected"
    And drop the graph "g_mut_undirected"
    And drop the graph type "gt_mut_undirected"

  Scenario: temp graph property type validation
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS complex_prop_graph AS {
        NODE T (LABEL T {
          id INT PRIMARY KEY,
          l LIST<INT>,
          deci DECIMAL(20, 2),
          vec VECTOR<3, FLOAT>,
          geog GEOGRAPHY(POINT)
        })
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS g_csr_complex_prop TYPED complex_prop_graph
      """
    Then the execution should be successful
    When executing query:
      """
      USE g_csr_complex_prop
      INSERT (@T {id:1,
                  l: LIST [1,2,3],
                  deci: CAST(123.45 AS DECIMAL(20,2)),
                  vec: VECTOR<3,float>([1,2,3]),
                  geog: ST_GEOGFROMTEXT("POINT(1 1)")})
      """
    Then the execution should be successful
    # csr graph support all of the property types
    When executing query:
      """
      CREATE TEMPORARY GRAPH #csr_prop_ok AS COPY OF g_csr_complex_prop OPTIONS {immutable: true}
      """
    Then the execution should be successful
    When executing query:
      """
      USE #csr_prop_ok
      MATCH (v:T)
      RETURN v.id AS id, v.l AS l, v.vec AS vec, ST_ASTEXT(v.geog) AS geog_text
      """
    Then the result should be, in any order:
      | id | l            | vec           | geog_text    |
      | 1  | LIST [1,2,3] | VECTOR[1,2,3] | "POINT(1 1)" |
    And drop the graph "#csr_prop_ok"
    # mut graph doesn't support some complex property types
    When executing query:
      """
      CREATE TEMPORARY GRAPH #mut_typed_fail TYPED complex_prop_graph
      """
    Then an Error should be raised: "[NT502]: Unsupported property type `GEOGRAPHY(Point)` for mutable temporary graph property `geog`"
    When executing query:
      """
      CREATE TEMPORARY GRAPH #mut_subq_fail AS COPY OF
      GRAPH { USE g_csr_complex_prop MATCH (v:T) RETURN v }
      """
    Then an Error should be raised: "[NT502]: Unsupported property type `GEOGRAPHY(Point)` for mutable temporary graph property `geog`"
    And drop the graph "g_csr_complex_prop"
    And drop the graph type "complex_prop_graph"

  Scenario: Import null value into mutable temporary graph from CSV
    And drop the graph "#test_import_default_null"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS test_import_default_null AS {
            NODE person ({
                id int64 PRIMARY KEY,
                age int8 DEFAULT 18,
                name string
            })
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #test_import_default_null TYPED test_import_default_null
      """
    Then the execution should be successful
    When executing query:
      """
      FILE f1  {
              id int64,
              name string
          }  = DATAFILE {PATH:'file://${TEST_DIR}/test_import_default_dir',  FORMAT:'CSV'}
          FOR i IN RANGE(1,10)
          EXPORT
              i AS id,
              NULL AS name
          INTO f1
      """
    Then the execution should be successful
    Then the path "file://${TEST_DIR}/test_import_default_dir" should be a "directory" path
    When executing query:
      """
      USE #test_import_default_null IMPORT INTO GRAPH {
              NODE (v@person{id:id, name:name})
              FROM DATAFILE {
                      PATH:'file://${TEST_DIR}/test_import_default_dir',
                      FORMAT:'CSV'
                  }
              }
      """
    Then the execution should be successful
    When executing query:
      """
      USE #test_import_default_null SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 10        |
      | "Edge Total" | "Edge"       | 0         |
      | "person"     | "Node"       | 10        |
    When executing query:
      """
      USE #test_import_default_null
      MATCH (v)
      RETURN v.id, v.age, v.name
      """
    Then the result should be, in any order:
      | v.id | v.age | v.name |
      | 1    | 18    | null   |
      | 2    | 18    | null   |
      | 3    | 18    | null   |
      | 4    | 18    | null   |
      | 5    | 18    | null   |
      | 6    | 18    | null   |
      | 7    | 18    | null   |
      | 8    | 18    | null   |
      | 9    | 18    | null   |
      | 10   | 18    | null   |
    Then remove the temporary directory "${TEST_DIR}/test_import_default_dir"
    And drop the graph "#test_import_default_null"
    And drop the graph type "test_import_default_null"

  @non_tls
  Scenario: Import Unsupported edge types
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #test_import_unsupported TYPED ldbc_type
      """
    Then the execution should be successful
    When executing query:
      """
      /*+SET_VAR(query_concurrency = 4) */
      USE #test_import_unsupported IMPORT INTO GRAPH
      {
            NODE (v@Person{id:f0}) FROM DATAFILE {
              FORMAT:"csv",
              PATH:"file://${TEST_DIR}/dataset/external_source/csv_source/node",
              autogenerate_column_names: true,
              delimiter: " "
            },
            EDGE (id:f0)-[e@KNOWS{}]->(id:f1) FROM DATAFILE {
              FORMAT:"csv",
              PATH:"file://${TEST_DIR}/dataset/external_source/csv_source/edge",
              autogenerate_column_names: true,
              delimiter: " "
            }
      }
      """
    Then an Error should be raised:
      """
      [NR129]: Import into temporary graph failed: Only edge types with MULTIEDGE KEY() can be imported into a temporary graph for now. Unsupported edge type: KNOWS
      """
    When executing query:
      """
      /*+SET_VAR(query_concurrency = 4) */
      USE #test_import_unsupported IMPORT INTO GRAPH
      {
        NODE (v@Person{id:id, firstName:firstName}) FROM NEBULA {
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&node_type=Person"
        },
        EDGE (id:id)-[e@KNOWS{startDate:creationDate}]->(id:id) FROM NEBULA {
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&edge_type=KNOWS"
        }
      }
      """
    Then an Error should be raised:
      """
      [NR129]: Import into temporary graph failed: Only edge types with MULTIEDGE KEY() can be imported into a temporary graph for now. Unsupported edge type: KNOWS
      """
    And drop the graph "#test_import_unsupported"

  @sf01 @non_tls
  Scenario: without properties option
    # vesoft-inc/nebula-ng#9175
    When executing query:
      """
      create graph if not exists without_properties_import_g typed ldbc_sf01_type
      """
    Then the execution should be successful
    When executing query:
      """
      create temporary graph #without_properties_import_g as copy of without_properties_import_g options {without_properties:true}
      """
    Then the execution should be successful
    When executing query:
      """
      USE #without_properties_import_g IMPORT INTO GRAPH {
        NODE (@Person{id:id, firstName:firstName}) FROM NEBULA {
            FORMAT: "NEBULA",
            PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=sf01&node_type=Person"
        }
      }
      """
    Then an Error should be raised: "[NC006]: Property `firstName` of type `Person` not found"
    And drop the graph "#without_properties_import_g"
    And drop the graph "without_properties_import_g"

  Scenario: Option without_properties keeps primary key and multiedge key properties only
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS gt_multiedge_drop_props AS {
        NODE person (LABEL person {id INT PRIMARY KEY, name STRING}),
        EDGE follow (person)-[LABEL follow {degree INT MULTIEDGE KEY, score INT}]->(person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS g_multiedge_drop_props TYPED gt_multiedge_drop_props
      """
    Then the execution should be successful
    When executing query:
      """
      USE g_multiedge_drop_props
      INSERT (a@person {id:1, name:"alice"}), (b@person {id:2, name:"bob"}),
             (a)-[@follow {degree: 10, score: 100}]->(b)
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH #tmp_multiedge_drop_props AS COPY OF g_multiedge_drop_props OPTIONS {without_properties: true, immutable: true}
      """
    Then the execution should be successful
    # Node primary key remains while non-PK property is dropped
    When executing query:
      """
      USE #tmp_multiedge_drop_props
      MATCH (v:person)
      RETURN v.id AS id
      """
    Then the result should be, in any order:
      | id |
      | 1  |
      | 2  |
    When executing query:
      """
      USE #tmp_multiedge_drop_props
      MATCH (v:person)
      RETURN v.name
      """
    Then an Error should be raised: "[NS230]: property `name` not found in NODE<(person)>"
    # Edge multiedge key property remains while non-key property is dropped
    When executing query:
      """
      USE #tmp_multiedge_drop_props
      MATCH ()-[e:follow]->()
      RETURN e.degree AS degree
      """
    Then the result should be, in any order:
      | degree |
      | 10     |
    When executing query:
      """
      USE #tmp_multiedge_drop_props
      MATCH ()-[e:follow]->()
      RETURN e.score AS score
      """
    Then an Error should be raised: "[NS230]: property `score` not found in EDGE<(person)-[follow]->(person)>"
    And drop the graph "#tmp_multiedge_drop_props"
    And drop the graph "g_multiedge_drop_props"
    And drop the graph type "gt_multiedge_drop_props"

  @non_tls
  Scenario: Avoid different graph in Nebula import
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #cluster_diff_237 TYPED ldbc_type
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS ldbc_copy_graph TYPED ldbc_type
      """
    When executing query:
      """
      USE #cluster_diff_237 IMPORT INTO GRAPH {
        NODE (v@Person{id:id}) FROM NEBULA {
            FORMAT:"nebula",
            PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&node_type=Person"
        },
        NODE (d@Place{id:id}) FROM NEBULA {
            FORMAT:"nebula",
            PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc_copy_graph&node_type=Place"
        }
      }
      """
    Then an Error should be raised: "[NR129]: Import into temporary graph failed: The graph in the Nebula import list is different"
    When executing query:
      """
      USE #cluster_diff_237 IMPORT INTO GRAPH {
        NODE (v@Person{id:id}) FROM NEBULA {
            FORMAT:"nebula",
            PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&node_type=Person"
        },
        NODE (d@Place{id:id}) FROM NEBULA {
            FORMAT:"nebula",
            PATH:"nebula://root:NebulaGraph01@192.168.0.2/10020?graph=ldbc&node_type=Place"
        }
      }
      """
    Then an Error should be raised: "[NR129]: Import into temporary graph failed: The graph in the Nebula import list is different"
    When executing query:
      """
      USE #cluster_diff_237 IMPORT INTO GRAPH {
        NODE (v@Person{id:id}) FROM NEBULA {
            FORMAT:"nebula",
            PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&node_type=Person"
        },
        NODE (d@Place{id:id}) FROM NEBULA {
            FORMAT:"nebula",
            PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=other_schema/ldbc&node_type=Place"
        }
      }
      """
    Then an Error should be raised: "[NR129]: Import into temporary graph failed: The graph in the Nebula import list is different"
    And drop the graph "#cluster_diff_237"
    And drop the graph "ldbc_copy_graph"

  Scenario: Import datafile with format Nebula:
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #sf01_from_error TYPED ldbc_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE #sf01_from_error IMPORT INTO GRAPH {
       NODE(v@Person{id:id}) FROM DATAFILE {
           FORMAT:"nebula",
           PATH:"nebula://root:NebulaGraph01@192.168.8.5:10010?graph=sf0_1&tls_enable=false&node_type=Person"
       }
      }
      """
    Then an Error should be raised: "[NI000]: Invalid parameter: Invalid format, `nebula` is a DATABASE, expected: FILE"
    And drop the graph "#sf01_from_error"

  Scenario: Mixed read write
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE test_mut_graph_insert() RETURNS () AS {
        INSERT (a@Person{id:6})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #ldbc_mixed_test AS COPY OF ldbc
      """
    Then the execution should be successful
    When executing query:
      """
      USE #ldbc_mixed_test {
        VALUE s = 1
        VALUE l ListAgg<STRING>
        MATCH (a:Person)
        PER NODE (a) {
          LOG_INFO(a)
        }
        CALL test_mut_graph_insert() FINISH
      }
      """
    Then the execution should be successful
    And drop the procedure "test_mut_graph_insert"
    And drop the graph "#ldbc_mixed_test"

  Scenario: Import permission requires owner or admin
    And drop the graph "#dist_import_permission_root"
    And drop the graph "#dist_import_permission_non_root"
    And drop the user "user_import_permission"
    # root user create temporary graph
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_import_permission_root TYPED ldbc_type
      """
    Then the execution should be successful
    # Import as non-owner user
    And create a new user session with username "user_import_permission" and password "NebulaGraph01"
    And switch to a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      GRANT CREATE GRAPH ON SCHEMA /default_schema TO USER user_import_permission
      """
    Then the execution should be successful
    And action "CREATE_GRAPH" on "SCHEMA" for user "user_import_permission" should be granted
    And switch to a new session with username "user_import_permission" and password "NebulaGraph01"
    When executing graph query:
      """
      USE #dist_import_permission_root IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      }
      """
    Then an Error should be raised: "[NR129]: Import into temporary graph failed: Only the owner or admin can import temporary graph `#dist_import_permission_root`"
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_import_permission_non_root TYPED ldbc_type
      """
    Then the execution should be successful
    # Import as admin
    And switch to a new session with username "root" and password "NebulaGraph01"
    When executing graph query:
      """
      USE #dist_import_permission_non_root IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      }
      """
    Then the execution should be successful
    # check if the owner is unchanged
    When executing graph query:
      """
      CALL show_graphs() FILTER name = '#dist_import_permission_non_root' RETURN graph_type, name, owner
      """
    Then the result should be, in any order:
      | graph_type  | name                               | owner                    |
      | "ldbc_type" | "#dist_import_permission_non_root" | "user_import_permission" |
    And drop the graph "#dist_import_permission_non_root"
    And drop the graph "#dist_import_permission_root"
    And close current session and drop the user "user_import_permission"

  Scenario: Import graph from statement
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #tmp_import_test_format TYPED ldbc_type
      """
    Then the execution should be successful
    When executing graph query:
      """
      USE #tmp_import_test_format IMPORT INTO GRAPH {
      GRAPH FROM DATAFILE {
          PATH:'file:///tmp/knife_test/export/test_import_vector.csv',
          FORMAT:'CSV'
        }
      }
      """
    Then an Error should be raised: "[NR129]: Import into temporary graph failed: GRAPH FROM only supports NEBULA"
    When executing graph query:
      """
      USE #tmp_import_test_format IMPORT INTO GRAPH {
      GRAPH FROM DATAFILE {
          FORMAT: "NEBULA",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      }
      """
    Then an Error should be raised: "Invalid format, `NEBULA` is a DATABASE, expected: FILE"
    And drop the graph "#tmp_import_test_format"

  @sf01
  Scenario: export and import sf01 data to csv/parquet/orc
    And drop the graph "#import_export_multiple_format_file_g"
    And drop the graph type "import_export_multiple_format_file_gt"
    # Export from sf01
    When executing graph query:
      """
      FILE f_csv {id int, content string, creationDate string}
      = DATAFILE {PATH:"file://${TEST_DIR}/dataset/temp_test_files/sf01_post_csv",  FORMAT:'csv'}
      FILE f_parquet {id int, content string, creationDate string}
      = DATAFILE {PATH:"file://${TEST_DIR}/dataset/temp_test_files/sf01_post_parquet",  FORMAT:'parquet'}
      FILE f_orc  {id int, content string, creationDate string}
       = DATAFILE {PATH:"file://${TEST_DIR}/dataset/temp_test_files/sf01_post_orc",  FORMAT:'orc'}
      USE sf01 MATCH (v:Post) EXPORT
          v.id as id,
          v.content as content,
          cast(v.creationDate as string) as creationDate
      INTO f_csv
      USE sf01 MATCH (v:Post) EXPORT
          v.id as id,
          v.content as content,
          cast(v.creationDate as string) as creationDate
      INTO f_parquet
      USE sf01 MATCH (v:Post) EXPORT
          v.id as id,
          v.content as content,
          cast(v.creationDate as string) as creationDate
      INTO f_orc
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS import_export_multiple_format_file_gt AS {
            node post_csv (label  post{id int, content string, creationDate local datetime, length int, primary key(id,content,creationDate)}),
            node post_parquet (label  post{id int, content string, creationDate local datetime, length int, primary key(id,content,creationDate)}),
            node post_orc (label  post{id int, content string, creationDate local datetime, length int, primary key(id,content,creationDate)})
      }
      """
    Then the execution should be successful
    # Load from exported files
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH if not exists #import_export_multiple_format_file_g typed import_export_multiple_format_file_gt
      """
    Then the execution should be successful
    When executing graph query:
      """
      USE #import_export_multiple_format_file_g IMPORT INTO GRAPH {
        NODE (v@post_csv{id:id, content:content, creationDate:creationDate} )  FROM DATAFILE {
            PATH:"file://${TEST_DIR}/dataset/temp_test_files/sf01_post_csv",
            FORMAT:'csv',
            delimiter: ","
        },
        NODE (v@post_parquet{id:id, content:content, creationDate:creationDate} ) FROM DATAFILE {
            PATH:"file://${TEST_DIR}/dataset/temp_test_files/sf01_post_parquet",
            FORMAT:'parquet'
        },
        NODE (v@post_orc{id:id, content:content, creationDate:creationDate} )  FROM DATAFILE {
            PATH:"file://${TEST_DIR}/dataset/temp_test_files/sf01_post_orc",
            FORMAT:"orc"
        }
      } OPTIONS {PRIMARY_KEY_AS_NODE_ID:false}
      """
    Then the execution should be successful
    When executing graph query:
      """
      show stats  #import_export_multiple_format_file_g
      """
    Then the result should be, in any order:
      | entry_name     | element_type | total_num |
      | "Node Total"   | "Node"       | 407103    |
      | "Edge Total"   | "Edge"       | 0         |
      | "post_csv"     | "Node"       | 135701    |
      | "post_parquet" | "Node"       | 135701    |
      | "post_orc"     | "Node"       | 135701    |
    And drop the graph "#import_export_multiple_format_file_g"
    And drop the graph type "import_export_multiple_format_file_gt"
    Then remove the temporary directory "${TEST_DIR}/dataset/temp_test_files/sf01_post_csv"
    Then remove the temporary directory "${TEST_DIR}/dataset/temp_test_files/sf01_post_parquet"
    Then remove the temporary directory "${TEST_DIR}/dataset/temp_test_files/sf01_post_orc"
