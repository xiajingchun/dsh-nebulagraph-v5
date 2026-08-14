# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: Graph Variable

  Scenario: Basic match on graph variable
    # Test basic match query on graph variable
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      USE g
      MATCH (v)
      RETURN v.id, v.firstName
      """
    Then the result should be, in any order:
      | v.id | v.firstName |
      | 2    | "Tim"       |
      | 3    | "Ming"      |
      | 4    | "Sophie"    |
      | 1    | "Kyle"      |
    # Test match with WHERE clause
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      USE g
      MATCH (v)
      WHERE v.id = 1
      RETURN v.firstName
      """
    Then the result should be, in any order:
      | v.firstName |
      | "Kyle"      |
    # Test match with edge pattern
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person)-[e@KNOWS]-(b@Person) RETURN a,e,b }
      USE g
      MATCH (v1)-[e]-(v2)
      RETURN v1.id, v2.id
      """
    Then the result should be, in any order:
      | v1.id | v2.id |
      | 2     | 2     |
      | 2     | 2     |
      | 1     | 1     |
      | 1     | 1     |
      | 3     | 3     |
      | 3     | 3     |
    # Test match with label filter
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      USE g
      MATCH (v:Person)
      WHERE v.id > 2
      RETURN v.id, v.firstName
      """
    Then the result should be, in any order:
      | v.id | v.firstName |
      | 4    | "Sophie"    |
      | 3    | "Ming"      |

  Scenario: Multi-hop pattern on graph variable
    # Test 2-hop pattern
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a)-[e1]-(b) RETURN a,e1,b }
      USE g
      MATCH (v1)-[]->(v2)-[]->(v3)
      RETURN DISTINCT v1.id, v2.id, v3.id
      """
    Then the result should be, in any order:
      | v1.id | v2.id | v3.id |
      | 2     | 2     | 5     |
      | 1     | 1     | 4     |
      | 3     | 3     | 6     |
      | 2     | 2     | 2     |
      | 3     | 2     | 2     |
      | 1     | 2     | 2     |
      | 3     | 3     | 3     |
      | 2     | 3     | 3     |
      | 1     | 1     | 1     |
      | 3     | 1     | 1     |
      | 2     | 2     | 3     |
      | 3     | 2     | 3     |
      | 1     | 2     | 3     |
      | 2     | 2     | 4     |
      | 3     | 2     | 4     |
      | 1     | 2     | 4     |
      | 3     | 3     | 1     |
      | 2     | 3     | 1     |
      | 1     | 1     | 2     |
      | 3     | 1     | 2     |
      | 3     | 3     | 2     |
      | 2     | 3     | 2     |
    # Test 3-hop pattern
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 4) */
      GRAPH g = GRAPH{ USE ldbc MATCH (a)-[e1]-(b) RETURN a,e1,b }
      USE ldbc
      MATCH (v1)-[]->(v2)-[]->(v3)-[]->(v4)
      RETURN DISTINCT v1.id, v2.id, v3.id, v4.id
      """
    Then the result should be, in any order:
      | v1.id | v2.id | v3.id | v4.id |
      | 3     | 1     | 1     | 4     |
      | 1     | 1     | 1     | 4     |
      | 3     | 1     | 2     | 4     |
      | 1     | 1     | 2     | 4     |
      | 2     | 3     | 2     | 4     |
      | 3     | 3     | 2     | 4     |
      | 2     | 2     | 2     | 4     |
      | 3     | 2     | 2     | 4     |
      | 1     | 2     | 2     | 4     |
      | 2     | 3     | 3     | 6     |
      | 3     | 3     | 3     | 6     |
      | 2     | 2     | 2     | 5     |
      | 3     | 2     | 2     | 5     |
      | 1     | 2     | 2     | 5     |
      | 3     | 1     | 1     | 1     |
      | 1     | 1     | 1     | 1     |
      | 2     | 3     | 1     | 1     |
      | 3     | 3     | 1     | 1     |
      | 2     | 3     | 3     | 1     |
      | 3     | 3     | 3     | 1     |
      | 2     | 2     | 3     | 1     |
      | 3     | 2     | 3     | 1     |
      | 1     | 2     | 3     | 1     |
      | 2     | 3     | 3     | 3     |
      | 3     | 3     | 3     | 3     |
      | 2     | 2     | 3     | 3     |
      | 3     | 2     | 3     | 3     |
      | 1     | 2     | 3     | 3     |
      | 3     | 1     | 2     | 3     |
      | 1     | 1     | 2     | 3     |
      | 2     | 3     | 2     | 3     |
      | 3     | 3     | 2     | 3     |
      | 2     | 2     | 2     | 3     |
      | 3     | 2     | 2     | 3     |
      | 1     | 2     | 2     | 3     |
      | 2     | 2     | 2     | 2     |
      | 3     | 2     | 2     | 2     |
      | 1     | 2     | 2     | 2     |
      | 3     | 1     | 2     | 2     |
      | 1     | 1     | 2     | 2     |
      | 2     | 3     | 2     | 2     |
      | 3     | 3     | 2     | 2     |
      | 2     | 3     | 3     | 2     |
      | 3     | 3     | 3     | 2     |
      | 2     | 2     | 3     | 2     |
      | 3     | 2     | 3     | 2     |
      | 1     | 2     | 3     | 2     |
      | 3     | 1     | 1     | 2     |
      | 1     | 1     | 1     | 2     |
      | 2     | 3     | 1     | 2     |
      | 3     | 3     | 1     | 2     |

  Scenario: Variable length pattern on graph variable
    # Test basic variable length pattern
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person)-[e]-(b@Person) RETURN a,e,b }
      USE g
      MATCH p = (v1)-[e]->{1, 2}(v2)
      RETURN v1.id, v2.id, length(p) as path_len
      """
    Then the result should be, in any order:
      | v1.id | v2.id | path_len |
      | 3     | 1     | 1        |
      | 1     | 1     | 1        |
      | 2     | 1     | 2        |
      | 3     | 1     | 2        |
      | 3     | 1     | 2        |
      | 1     | 1     | 2        |
      | 3     | 2     | 1        |
      | 1     | 2     | 1        |
      | 2     | 2     | 1        |
      | 3     | 2     | 2        |
      | 1     | 2     | 2        |
      | 2     | 2     | 2        |
      | 3     | 2     | 2        |
      | 3     | 2     | 2        |
      | 1     | 2     | 2        |
      | 2     | 2     | 2        |
      | 2     | 4     | 1        |
      | 3     | 4     | 2        |
      | 1     | 4     | 2        |
      | 2     | 4     | 2        |
      | 2     | 3     | 1        |
      | 3     | 3     | 1        |
      | 3     | 3     | 2        |
      | 1     | 3     | 2        |
      | 2     | 3     | 2        |
      | 2     | 3     | 2        |
      | 3     | 3     | 2        |
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person)-[e]-(b@Person) RETURN a,e,b }
      USE g
      MATCH p = (v1@Place)-[e]->{0, 2}(v2)
      RETURN v1.id, v2.id, length(p) as path_len
      """
    Then the result should be, in any order:
      | v1.id | v2.id | path_len |
    # Test variable length with specific edge type
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person)-[e:KNOWS]-(b@Person) RETURN a,e,b }
      USE g
      MATCH p = (v1)-[e:KNOWS]->{0, 3}(v2)
      RETURN v1.id, v2.id, length(p) as path_len
      """
    Then the result should be, in any order:
      | v1.id | v2.id | path_len |
      | 2     | 2     | 0        |
      | 2     | 2     | 1        |
      | 2     | 2     | 2        |
      | 2     | 2     | 3        |
      | 3     | 3     | 0        |
      | 3     | 3     | 1        |
      | 3     | 3     | 2        |
      | 3     | 3     | 3        |
      | 1     | 1     | 0        |
      | 1     | 1     | 1        |
      | 1     | 1     | 2        |
      | 1     | 1     | 3        |

  Scenario: Quantified path pattern on graph variable
    # Test simple quantified pattern {1,2}
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person)-[e]-(b@Person) RETURN a,e,b }
      USE g
      MATCH (v1) (()-[]-()){1,2} (v2)
      RETURN DISTINCT v1.id, v2.id
      """
    Then the result should be, in any order:
      | v1.id | v2.id |
      | 2     | 3     |
      | 3     | 3     |
      | 1     | 3     |
      | 4     | 3     |
      | 2     | 4     |
      | 1     | 4     |
      | 3     | 4     |
      | 4     | 4     |
      | 3     | 1     |
      | 1     | 1     |
      | 2     | 1     |
      | 4     | 1     |
      | 1     | 2     |
      | 3     | 2     |
      | 2     | 2     |
      | 4     | 2     |

  Scenario: ORDER BY and LIMIT on graph variable
    # Test ORDER BY
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      USE g
      MATCH (v)
      ORDER BY v.firstName
      RETURN v.id, v.firstName
      """
    Then the result should be, in order:
      | v.id | v.firstName |
      | 1    | "Kyle"      |
      | 3    | "Ming"      |
      | 4    | "Sophie"    |
      | 2    | "Tim"       |

  Scenario: Aggregation on graph variable
    # Test COUNT
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      USE g
      MATCH (v)
      RETURN count(v) as cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 4   |
    # Test COUNT with GROUP BY
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person)-[e:KNOWS]-(b@Person) RETURN a,e,b }
      USE g
      MATCH (v1)-[]-(v2)
      RETURN v1.id, count(v2) as cnt
      """
    Then the result should be, in any order:
      | v1.id | cnt |
      | 2     | 2   |
      | 3     | 2   |
      | 1     | 2   |
    # Test SUM and AVG
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      USE g
      MATCH (v)
      RETURN sum(v.id) as sum_id, avg(v.id) as avg_id
      """
    Then the result should be, in any order:
      | sum_id | avg_id |
      | 10     | 2.5    |
    # Test OPTIONAL MATCH with no match
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      USE g
      MATCH (v)
      WHERE v.id = 999
      OPTIONAL MATCH (v)-[]-(v2)
      RETURN v.id, v2.id
      """
    Then the result should be, in any order:
      | v.id | v2.id |

  Scenario: Typed graph variable operations
    # Test typed graph variable basic match
    When executing query:
      """
      GRAPH g TYPED GRAPH {
        NODE TYPE Place (LABELS City&Country&Continent {id INT PRIMARY KEY, name STRING, url STRING, kind STRING})
      } = GRAPH{ USE ldbc MATCH (a@Place) RETURN a }
      USE g
      MATCH (v@Place)
      RETURN v.id
      """
    Then the result should be, in any order:
      | v.id |
      | 4    |
      | 5    |
      | 2    |
      | 3    |
      | 6    |
      | 1    |
    When executing query:
      """
      GRAPH g TYPED GRAPH {
        NODE TYPE Place (LABELS City&Country&Continent {id INT PRIMARY KEY, name STRING, url STRING})
      } = GRAPH{ USE ldbc MATCH (a@Place) RETURN a }
      USE g
      MATCH (v@Place)
      RETURN v.id
      """
    Then an Error should be raised: "[NC201]: Graph type mismatch: Node property `kind` from matched result does not exist in the declared graph type"

  Scenario: Complex match patterns on graph variable
    # Test multiple match patterns
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      USE g
      MATCH (v1), (v2)
      WHERE v1.id = 1 AND v2.id = 2
      RETURN v1.firstName, v2.firstName
      """
    Then the result should be, in any order:
      | v1.firstName | v2.firstName |
      | "Kyle"       | "Tim"        |
    # Test triangular pattern
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person)-[e1]-(b@Person)-[e2]-(c@Person)-[e3]-(a) RETURN a,e1,b,e2,c,e3 }
      USE g
      MATCH (v1)-[]-(v2)-[]-(v3)-[]-(v1)
      RETURN DISTINCT v1.id, v2.id, v3.id
      """
    Then the result should be, in any order:
      | v1.id | v2.id | v3.id |
      | 1     | 3     | 1     |
      | 1     | 1     | 1     |
      | 1     | 2     | 1     |
      | 1     | 1     | 2     |
      | 1     | 3     | 2     |
      | 1     | 2     | 2     |
      | 1     | 2     | 3     |
      | 1     | 3     | 3     |
      | 1     | 1     | 3     |
      | 3     | 2     | 3     |
      | 3     | 3     | 3     |
      | 3     | 1     | 3     |
      | 3     | 3     | 1     |
      | 3     | 1     | 1     |
      | 3     | 2     | 1     |
      | 3     | 1     | 2     |
      | 3     | 3     | 2     |
      | 3     | 2     | 2     |
      | 2     | 1     | 2     |
      | 2     | 3     | 2     |
      | 2     | 2     | 2     |
      | 2     | 4     | 2     |
      | 2     | 2     | 4     |
      | 2     | 2     | 3     |
      | 2     | 3     | 3     |
      | 2     | 1     | 3     |
      | 2     | 3     | 1     |
      | 2     | 1     | 1     |
      | 2     | 2     | 1     |
      | 4     | 2     | 2     |

  Scenario: Nested graph query on graph variable
    # Test nested graph query with graph variable
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      USE g {
        MATCH (v)
        WHERE v.id = 1
        RETURN v.firstName
      }
      """
    Then the result should be, in any order:
      | v.firstName |
      | "Kyle"      |

  Scenario: Error cases for graph variable
    # Test using graph variable as return item
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      RETURN g
      """
    Then an Error should be raised: "[42000]: Syntax error or access rule violation: Cannot use graph or table reference as the last return item: g"
    # Test undefined graph variable
    When executing query:
      """
      USE undefined_graph
      MATCH (v)
      RETURN v.id
      """
    Then an Error should be raised: "[01G03]: Graph `undefined_graph` not found in schema `/default_schema`"

  Scenario: Graph variable with unwind
    # Test graph variable in unwind
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      TABLE t {id INT} = (1), (2), (3)
      USE g
      FOR r IN t
      MATCH (v)
      WHERE v.id = r.id
      RETURN v.id, v.firstName
      """
    Then the result should be, in any order:
      | v.id | v.firstName |
      | 1    | "Kyle"      |
      | 2    | "Tim"       |
      | 3    | "Ming"      |
    Then an Error should be raised: "[NS209]: Current working graph not found"
    # Test multiple graph variables in same scope
    When executing query:
      """
      GRAPH g1 = GRAPH{ USE ldbc MATCH (a@Person{id:1}) RETURN a }
      GRAPH g2 = GRAPH{ USE ldbc MATCH (a@Person{id:2}) RETURN a }
      USE g1
      MATCH (v1)
      RETURN v1.id as id1
      NEXT
      USE g2
      MATCH (v2)
      RETURN id1, v2.id
      """
    Then the result should be, in any order:
      | id1 | v2.id |
      | 1   | 2     |

  Scenario: Subquery with graph variable
    # Test EXISTS with graph variable
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      USE g
      MATCH (v1)
      WHERE EXISTS { MATCH (v1)-[]-(v2) }
      RETURN v1.id, v1.firstName
      """
    Then the result should be, in any order:
      | v1.id | v1.firstName |
    # Test NOT EXISTS with graph variable
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      USE g
      MATCH (v1)
      WHERE NOT EXISTS { MATCH (v1)-[]-(v2) WHERE v2.id = 999 }
      RETURN v1.id, v1.firstName
      """
    Then the result should be, in any order:
      | v1.id | v1.firstName |
      | 2     | "Tim"        |
      | 4     | "Sophie"     |
      | 3     | "Ming"       |
      | 1     | "Kyle"       |

  Scenario: Graph variable definition using another graph variable
    # Test defining a graph variable using another graph variable
    When executing query:
      """
      GRAPH g1 = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      GRAPH g2 = GRAPH{ USE g1 MATCH (v) WHERE v.id > 2 RETURN v }
      USE g2
      MATCH (v)
      RETURN v.id, v.firstName
      """
    Then the result should be, in any order:
      | v.id | v.firstName |
      | 4    | "Sophie"    |
      | 3    | "Ming"      |
    # Test chaining multiple graph variables
    When executing query:
      """
      GRAPH g1 = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      GRAPH g2 = GRAPH{ USE g1 MATCH (v) WHERE v.id > 1 RETURN v }
      GRAPH g3 = GRAPH{ USE g2 MATCH (v) WHERE v.id < 4 RETURN v }
      USE g3
      MATCH (v)
      RETURN v.id, v.firstName
      """
    Then the result should be, in any order:
      | v.id | v.firstName |
      | 2    | "Tim"       |
      | 3    | "Ming"      |
    # Test using graph variable with edges
    When executing query:
      """
      GRAPH g1 = GRAPH{ USE ldbc MATCH (a@Person)-[e:KNOWS]-(b@Person) RETURN a,e,b }
      GRAPH g2 = GRAPH{ USE g1 MATCH (v1)-[e]-(v2) WHERE v1.id = 1 OR v2.id = 1 RETURN v1,e,v2 }
      USE g2
      MATCH (v1)-[e]-(v2)
      RETURN DISTINCT v1.id, v2.id
      """
    Then the result should be, in any order:
      | v1.id | v2.id |
      | 1     | 1     |
    # Test aggregation on derived graph variable
    When executing query:
      """
      GRAPH g1 = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      GRAPH g2 = GRAPH{ USE g1 MATCH (v) WHERE v.id > 1 RETURN v }
      USE g2
      MATCH (v)
      RETURN count(v) as cnt, sum(v.id) as sum_id
      """
    Then the result should be, in any order:
      | cnt | sum_id |
      | 3   | 9      |
    # Test order by on derived graph variable
    When executing query:
      """
      GRAPH g1 = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      GRAPH g2 = GRAPH{ USE g1 MATCH (v) RETURN v }
      USE g2
      MATCH (v)
      ORDER BY v.id DESC
      RETURN v.id, v.firstName
      """
    Then the result should be, in order:
      | v.id | v.firstName |
      | 4    | "Sophie"    |
      | 3    | "Ming"      |
      | 2    | "Tim"       |
      | 1    | "Kyle"      |
    # Test variable length pattern on derived graph variable
    When executing query:
      """
      GRAPH g1 = GRAPH{ USE ldbc MATCH (a@Person)-[e:KNOWS]-(b@Person) RETURN a,e,b }
      GRAPH g2 = GRAPH{ USE g1 MATCH (v1)-[e1]-(v2)-[e2]-(v3) RETURN v1,e1,v2,e2,v3 }
      USE g2
      MATCH p = (v1)-[e]->{1,2}(v2)
      WHERE v1.id = 1
      RETURN v2.id, length(p) as path_len
      """
    Then the result should be, in any order:
      | v2.id | path_len |
      | 1     | 1        |
      | 1     | 2        |
    # Test error: using undefined graph variable in definition
    When executing query:
      """
      GRAPH g2 = GRAPH{ USE g1 MATCH (v) RETURN v }
      USE g2
      MATCH (v)
      RETURN v.id
      """
    Then an Error should be raised: "[01G03]: Graph `g1` not found in schema `/default_schema`"

  Scenario: Graph variable with inline procedure
    # Test basic inline procedure with graph variable
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      USE g
      CALL {
        MATCH (v)
        WHERE v.id = 1
        RETURN v.id AS vid, v.firstName AS name
      }
      RETURN vid, name
      """
    Then the result should be, in any order:
      | vid | name   |
      | 1   | "Kyle" |
    # Test inline procedure with aggregation on graph variable
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person)-[e:KNOWS]-(b@Person) RETURN a,e,b }
      USE g
      CALL {
        MATCH (v1)-[]-(v2)
        RETURN v1.id as id, count(v2) AS cnt
      }
      RETURN id, cnt
      """
    Then the result should be, in any order:
      | id | cnt |
      | 2  | 2   |
      | 3  | 2   |
      | 1  | 2   |
    # Test nested inline procedure with graph variable
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      USE g
      CALL {
        MATCH (v1)
        WHERE v1.id < 3
        CALL {
          RETURN v1.id AS inner_id
        }
        RETURN inner_id
      }
      RETURN inner_id
      """
    Then the result should be, in any order:
      | inner_id |
      | 1        |
      | 2        |
    # Test optional inline procedure with graph variable
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      USE g
      MATCH (v1)
      WHERE v1.id = 1
      OPTIONAL CALL {
        MATCH (v1)-[]-(v2)
        WHERE v2.id = 999
        RETURN v2.id AS vid
      }
      RETURN v1.id, vid
      """
    Then the result should be, in any order:
      | v1.id | vid  |
      | 1     | null |

  Scenario: Graph variable with named procedure
    # Test basic named procedure with graph variable
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE proc_graph_var() RETURNS (vid INT, name STRING) AS {
        MATCH (v)
        WHERE v.id <= 2
        RETURN v.id AS vid, v.firstName AS name
      }
      """
    Then the execution should be successful
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      USE g
      CALL proc_graph_var() RETURN vid, name
      """
    Then the result should be, in any order:
      | vid | name   |
      | 1   | "Kyle" |
      | 2   | "Tim"  |
    # Test named procedure with parameter and graph variable
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE proc_graph_param(id_filter INT) RETURNS (vid INT, name STRING) AS {
        MATCH (v)
        WHERE v.id = id_filter
        RETURN v.id AS vid, v.firstName AS name
      }
      """
    Then the execution should be successful
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      USE g
      CALL proc_graph_param(3) RETURN vid, name
      """
    Then the result should be, in any order:
      | vid | name   |
      | 3   | "Ming" |
    # Test named procedure with aggregation on graph variable
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE proc_graph_agg() RETURNS (total INT) AS {
        MATCH (v)
        RETURN count(v) AS total
      }
      """
    Then the execution should be successful
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      USE g
      CALL proc_graph_agg() RETURN total
      """
    Then the result should be, in any order:
      | total |
      | 4     |
    And drop the procedure "proc_graph_var"
    And drop the procedure "proc_graph_param"
    And drop the procedure "proc_graph_agg"

  Scenario: Error cases for procedure with graph variable
    # Test error: procedure returning internally defined graph variable node
    When executing query:
      """
      GRAPH g_internal = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      USE g_internal
      MATCH (v)
      WHERE v.id = 1
      RETURN v
      """
    Then an Error should be raised: "[NP101]: Procedure error: Return graph element of variable `g_internal` defined within procedure is not supported"
    When executing query:
      """
      GRAPH g_internal = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      USE g_internal
      MATCH (v)-[e]->(v)
      WHERE v.id = 1
      RETURN e
      """
    Then an Error should be raised: "[NP101]: Procedure error: Return graph element of variable `g_internal` defined within procedure is not supported"
    When executing query:
      """
      GRAPH g_internal = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      USE g_internal
      MATCH p = (v)-[e]->(v)
      WHERE v.id = 1
      RETURN p
      """
    Then an Error should be raised: "[NP101]: Procedure error: Return graph element of variable `g_internal` defined within procedure is not supported"
    When executing query:
      """
      GRAPH g_internal = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      USE g_internal
      MATCH p = (v)-[e]->(v)
      WHERE v.id = 1
      RETURN LIST[p]
      """
    Then an Error should be raised: "[NP101]: Procedure error: Return graph element of variable `g_internal` defined within procedure is not supported"

  Scenario: Valid cases for procedure returning parent graph variable elements
    # Test valid: inline procedure using parent graph variable node
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      USE g
      MATCH (v)
      WHERE v.id = 2
      CALL {
        RETURN v.id AS vid, v.firstName AS name
      }
      RETURN vid, name
      """
    Then the result should be, in any order:
      | vid | name  |
      | 2   | "Tim" |
    # Test valid: inline procedure with parent graph variable edge
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person)-[r:KNOWS]-(b@Person) RETURN a,r,b }
      USE g
      MATCH (v1)-[e]-(v2)
      WHERE v1.id = 1
      CALL {
        RETURN v1 AS v3, v2 AS v4
      }
      RETURN v3.id AS src, v4.id AS dst
      """
    Then the result should be, in any order:
      | src | dst |
      | 1   | 1   |
      | 1   | 1   |

  Scenario: procedure visibility
    # Setup: Create base graph type and graph
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS procedure_visibility_gt AS {
        NODE TYPE Person (LABEL Person {id INT PRIMARY KEY, val DOUBLE})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE proc_graph_var_visibility(iter_id INT) RETURNS (cnt INT) AS {
        USE g_temp
        MATCH (v)
        RETURN COUNT(v)
      }
      """
    Then the execution should be successful
    # Test calling procedure in FOR loop - should raise error
    When executing query:
      """
      GRAPH g_temp TYPED procedure_visibility_gt
      FOR r IN RANGE(0, 100)
      CALL proc_graph_var_visibility(r) RETURN *
      """
    Then an Error should be raised: "[01G03]: Graph `g_temp` not found in schema `/default_schema`"
    # Cleanup
    And drop the procedure "proc_graph_var_visibility"
    And drop the graph type "procedure_visibility_gt"

  Scenario: concurrency import
    # Test error: calling procedure that uses graph variable in concurrent context (unwind/FOR loop)
    # Setup: Create base graph type and graph
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS concurrent_import_gt AS {
        NODE TYPE Person (LABEL Person {id INT PRIMARY KEY, val DOUBLE})
      }
      """
    Then the execution should be successful
    # Create procedure that uses graph variable with import
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE proc_graph_var_import(iter_id INT) AS {
        FILE node_file {f0 INT, f1 DOUBLE} = DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/csv_source/node",
          AUTOGENERATE_COLUMN_NAMES: true,
          DELIMITER:" "
        }
        IMPORT INTO GRAPH {
          NODE (@Person{id:f0, val:f1}) FROM node_file
        }
      }
      """
    Then the execution should be successful
    # Test calling procedure in FOR loop - should raise error
    When executing query:
      """
      GRAPH g_temp TYPED concurrent_import_gt
      USE g_temp
      FOR r IN RANGE(0, 100)
      CALL proc_graph_var_import(r) FINISH
      """
    Then an Error should be raised: "[NT501]: Unsupported temporary graph operation: Import to non-empty graph"
    # Cleanup
    And drop the procedure "proc_graph_var_import"
    And drop the graph type "concurrent_import_gt"

  Scenario: Unsupported
    When executing query:
      """
      GRAPH g TYPED GRAPH {
        NODE TYPE Place (LABELS City&Country&Continent {id INT PRIMARY KEY, name STRING, url STRING, kind STRING})
      }
      USE g
      MATCH (v@Place)
      RETURN v.id
      """
    Then an Error should be raised:  "[NS252]: Invalid graph variable: Constructing anonymous graph type for graph variable is not supported"
    # Test INSERT on graph variable - should raise error
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      USE g
      MATCH (v)
      WHERE v.id = 1
      INSERT (:Person{id:100, firstName:"New", lastName:"User", gender:"male"})
      """
    Then an Error should be raised: "[NT501]: Unsupported temporary graph operation: insert on query graph"
    # Test DELETE on graph variable - should raise error
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      USE g
      MATCH (v)
      WHERE v.id = 1
      DELETE v
      """
    Then an Error should be raised: "[NT501]: Unsupported temporary graph operation: delete on query graph"
    # Test SET on graph variable - should raise error
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      USE g
      MATCH (v)
      WHERE v.id = 1
      SET v.firstName = "Updated"
      """
    Then an Error should be raised: "[NT501]: Unsupported temporary graph operation: set on query graph"

  Scenario: Drop graph variable is not allowed
    # Test drop graph variable should raise error
    When executing query:
      """
      GRAPH g_drop = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      DROP GRAPH g_drop
      """
    Then an Error should be raised: "[NR100]: DDL failed: Query graph `g_drop` cannot be dropped."

  Scenario: Graph variable name same as existing graph
    # Test graph variable can shadow existing graph name
    When executing query:
      """
      GRAPH ldbc = GRAPH{ USE ldbc MATCH (a@Person) WHERE a.id = 1 RETURN a }
      USE ldbc
      MATCH (v)
      RETURN v.id, v.firstName
      """
    Then the result should be, in any order:
      | v.id | v.firstName |
      | 1    | "Kyle"      |
