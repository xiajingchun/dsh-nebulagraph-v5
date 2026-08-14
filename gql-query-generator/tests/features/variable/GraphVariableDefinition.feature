# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: graph variable definition

  Scenario: nested graph query specification
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a) RETURN a } RETURN g
      """
    Then an Error should be raised: "[42000]: Syntax error or access rule violation: Cannot use graph or table reference as the last return item: g"
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a) RETURN a } RETURN g + 1
      """
    Then an Error should be raised: "[NR002]: Undefined function: `+(GRAPH_REF, INT32)`"
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a)-[e]-(b) RETURN e } RETURN 1
      """
    Then an Error should be raised: "[NR124]: Failed to build temporary graph: There're dangling edges"

  Scenario: duplicate binding variable definition
    When executing query:
      """
      GRAPH g= GRAPH{ USE ldbc MATCH (a) RETURN a }
      GRAPH g= GRAPH{ USE ldbc MATCH (a:Person) RETURN a }
      return 1
      """
    Then an Error should be raised: "[NS002]: Semantic error, duplicate defined variable: `g`"

  Scenario: closed typed variable definition
    When executing query:
      """
      CREATE PLUGIN IF NOT EXISTS algo
      """
    Then the execution should be successful
    When executing query:
      """
      GRAPH g TYPED GRAPH {
      NODE TYPE Place (LABELS City&Country&Continent {id INT PRIMARY KEY, name STRING, url STRING, kind STRING})
      } = GRAPH{ USE ldbc MATCH (a@Place) RETURN a } RETURN g
      NEXT
      CALL algo.graph_stats(g)
      return total_node_number
      """
    Then an Error should be raised: "[NS216]: The returned column `g` conflicts with parent scope variables. Please use a unique alias to distinguish them"
    When executing query:
      """
      GRAPH g TYPED GRAPH {
      NODE TYPE Place (LABELS City&Country&Continent {id INT PRIMARY KEY, name STRING, url STRING, kind STRING})
      } = GRAPH{ USE ldbc MATCH (a@Place) RETURN a } RETURN g AS gx
      NEXT
      CALL algo.graph_stats(gx)
      return total_node_number
      """
    Then the execution should be successful
    # ## type name mismatch ###
    # node type name missing
    When executing query:
      """
      GRAPH g TYPED GRAPH {
      NODE TYPE node_type (LABEL player{id INT PRIMARY KEY, name STRING})} =
      GRAPH{ USE ldbc MATCH (a) RETURN a } RETURN g
      """
    Then the execution should be failed
    # edge type name missing
    When executing query:
      """
      GRAPH g TYPED GRAPH {
      NODE TYPE Place (LABELS City&Country&Continent {id INT PRIMARY KEY, name STRING, url STRING, kind STRING}),
      EDGE TYPE edge_type (Place)-[:IS_PART_OF]->(Place)
      } = GRAPH{ USE ldbc MATCH (v@Place)-[e@IS_PART_OF]-(v2) RETURN v,e } RETURN g
      """
    Then the execution should be failed
    # ## prop name missing ###
    # node prop name missing
    When executing query:
      """
      GRAPH g TYPED GRAPH {
      NODE TYPE Place (LABELS City&Country&Continent {id INT PRIMARY KEY, name STRING, url STRING}),
      EDGE TYPE IS_PART_OF (Place)-[:IS_PART_OF]->(Place)
      } = GRAPH{ USE ldbc MATCH (v@Place)-[e@IS_PART_OF]-(v2) RETURN v,e } RETURN g
      """
    Then the execution should be failed
    # edge prop name missing
    When executing query:
      """
      GRAPH g TYPED GRAPH {
      NODE Person (LABEL Person {id INT PRIMARY KEY, firstName STRING, lastName STRING, gender STRING, birthday DATE, creationDate LOCAL DATETIME, locationIP STRING, browserUsed STRING, vec VECTOR<3, FLOAT>}),
      EDGE KNOWS (Person)-[:KNOWS]->(Person)
      } = GRAPH{ USE ldbc MATCH (v@Person)-[e@KNOWS]-(v2) RETURN v,e } RETURN g
      """
    Then the execution should be failed
    # ## prop type mismatch ###
    # node prop type mismatch
    When executing query:
      """
      GRAPH g TYPED GRAPH {
      NODE TYPE Place (LABELS City&Country&Continent {id INT PRIMARY KEY, name STRING, url INT, kind STRING})
      } = GRAPH{ USE ldbc MATCH (a@Place) RETURN a } RETURN g
      """
    Then the execution should be failed
    # edge prop type mismatch
    When executing query:
      """
      GRAPH g TYPED GRAPH {
      NODE Person (LABEL Person {id INT PRIMARY KEY, firstName STRING, lastName STRING, gender STRING, birthday DATE, creationDate LOCAL DATETIME, locationIP STRING, browserUsed STRING}),
      EDGE KNOWS (Person)-[:KNOWS{creationDate STRING}]->(Person)
      } = GRAPH{ USE ldbc MATCH (v@Person)-[e@KNOWS]-(v2) RETURN v,e } RETURN g
      """
    Then the execution should be failed
    # Fix issue #6416
    # Different edge directions
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS `issue6416` AS {
      NODE TYPE `Person` (LABEL `Person`{`id` INT64 NOT NULL, `name` STRING DEFAULT NULL, PRIMARY KEY (`id`)}),
      NODE TYPE `City` (LABEL `City`{`id` INT64 NOT NULL, `name` STRING DEFAULT NULL, PRIMARY KEY (`id`)}),
      EDGE TYPE `Live` (`Person`)-[LABEL `Live`{}]->(`City`)}
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS g_issue6416 issue6416
      """
    Then the execution should be successful
    When executing query:
      """
      USE g_issue6416 INSERT (@Person{id:1, name:"Bob"})-[:Live]->(@City{id:1, name:"bj"})
      """
    Then the execution should be successful
    When executing query:
      """
      GRAPH g TYPED GRAPH {
      NODE TYPE Person (LABEL Person {id INT PRIMARY KEY, name STRING}),
      NODE TYPE City (LABEL City {id INT PRIMARY KEY, name STRING }),
      EDGE TYPE Live (Person)<-[:Live]-(City)}
      = GRAPH{ USE g_issue6416 MATCH (p@Person)-[e@Live]-(c@City) RETURN p,e,c}
      CALL algo.graph_stats(g)
      RETURN *
      """
    Then an Error should be raised: "[NC201]: Graph type mismatch: Edge direction of `Live` from matched result does not match the declared graph type, expect: (City)-[Live]->(Person), actual: (Person)-[Live]->(City)"
    # issue 7403 undirected edge
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS issue_7403 as {
         NODE Person (LABEL Person {id INT PRIMARY KEY}), EDGE Know (Person)~[label Know]~(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS g_issue_7403 issue_7403
      """
    Then the execution should be successful
    When executing query:
      """
      GRAPH g TYPED GRAPH {
       NODE TYPE Person (LABEL Person {id INT PRIMARY KEY}),
       EDGE TYPE Know (Person)~[label Know]~(Person)}
       = GRAPH{ USE g_issue_7403 MATCH (n1@Person)~[e@Know]~(n2@Person) RETURN n1, e}
       CALL algo.graph_stats(g)
       RETURN *
      """
    Then the result should be, in any order:
      | total_edge_number | total_node_number |
      | 0                 | 0                 |
    And drop the graph "g_issue6416"
    And drop the graph type "issue6416"
    And drop the graph "g_issue_7403"
    And drop the graph type "issue_7403"

  Scenario: scope of working graph
    When executing query:
      """
      CREATE PLUGIN IF NOT EXISTS algo
      """
    Then the execution should be successful
    # The graph used by a nested procedure will not be passed to the following statements.
    When executing query:
      """
      GRAPH g = GRAPH {USE ldbc MATCH (v) RETURN v}
      MATCH (v:Person)
      CALL algo.bfs(g, element_id(v)) YIELD distance
      FILTER distance > 0
      RETURN v.id, distance
      """
    Then an Error should be raised: "[NS209]: Current working graph not found"
    When executing query:
      """
      GRAPH g = GRAPH {USE ldbc MATCH (v) RETURN v}
      USE ldbc
      MATCH (v:Person)
      CALL algo.bfs(g, element_id(v)) YIELD distance
      FILTER distance > 0
      RETURN v.id, distance
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS gt_subquery_graph_varies AS {
        NODE TYPE N1 (LABEL N1 {id INT PRIMARY KEY})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS g_subquery_graph_varies TYPED gt_subquery_graph_varies
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION SET graph g_subquery_graph_varies
      """
    Then the execution should be successful
    # When the graph is set to a subquery graph, the graph stats should be the stats of the subquery graph
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (v)-[e]-(v2) RETURN v,e,v2 } RETURN g AS gx
      NEXT
      CALL algo.graph_stats(gx)
      RETURN total_edge_number, total_node_number
      """
    Then the result should be, in any order:
      | total_edge_number | total_node_number |
      | 74                | 28                |
    And drop the graph "g_subquery_graph_varies"
    And drop the graph type "gt_subquery_graph_varies"
    And reset graph

  Scenario: Graph variable in interpreter
    When executing query:
      """
      CREATE PLUGIN IF NOT EXISTS algo
      """
    Then the execution should be successful
    When executing query:
      """
      GRAPH g = GRAPH { USE ldbc MATCH (v1)-[e]->(v2) RETURN v1,e,v2 }
      GRAPH gx = GRAPH { USE ldbc MATCH (v)-[e]-(v2) RETURN v,e,v2 }
      VALUE i INT = 3
      TABLE t typed table {id int, name string} = (50, "Lip")
      while i > 0 then {
         USE ldbc MATCH (src:Person{id:1})
         CALL algo.bfs(g, element_id(src)) YIELD node_id AS _dst, distance
         MATCH (v WHERE element_id(v)=_dst)
         FINISH
         SET i = i - 1
      }
      CALL algo.graph_stats(gx)
      RETURN total_edge_number, total_node_number
      """
    Then the result should be, in any order:
      | total_edge_number | total_node_number |
      | 74                | 28                |
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS g_graph_variable_edge_type AS {
          NODE Person (LABEL Person {id INT64 PRIMARY KEY , name STRING})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS g_graph_variable_edge TYPED g_graph_variable_edge_type
      """
    Then the execution should be successful
    When executing query:
      """
      graph g typed graph {node type Person(label Person  {id int primary key, name string})}
      = graph {use g_graph_variable_edge match (n@Person) return n}

      table t typed table {id int, name string} = (50, "Lip")
      use ldbc match (v)
      order by v.id desc return v.id, v.name
      """
    Then the execution should be successful
    And drop the graph "g_graph_variable_edge"
    And drop the graph type "g_graph_variable_edge_type"
