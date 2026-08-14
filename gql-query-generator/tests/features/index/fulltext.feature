# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: fulltext index

  Scenario: test node fulltext index
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS fulltext_node_index_gt AS {
        NODE node_type_player ( LABEL player {id INT PRIMARY KEY, str STRING}),
        EDGE edge_type_follow (node_type_player)-[ LABEL follow {followness INT, age INT, since LOCAL DATETIME}]->(node_type_player)
      }
      """
    Then the execution should be successful
    And drop the graph "fulltext_node_index_g"
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS fulltext_node_index_g TYPED fulltext_node_index_gt
      """
    Then the execution should be successful
    And drop the index "player_ft_node_index" of "fulltext_node_index_g"
    When executing query:
      """
      USE fulltext_node_index_g CREATE FULLTEXT INDEX IF NOT EXISTS player_ft_node_index ON NODE node_type_player(str)
      """
    Then the execution should be successful
    When executing query:
      """
      USE fulltext_node_index_g SHOW INDEXES
      """
    Then the result should contain:
      | name                   | state   | index_type | schema            | graph_name              | entity_type | element_type       | properties  |
      | "player_ft_node_index" | "Valid" | "Fulltext" | "/default_schema" | "fulltext_node_index_g" | "Node"      | "node_type_player" | LIST["str"] |
    When executing query:
      """
      USE fulltext_node_index_g INSERT
        (@node_type_player{id: 1, str: "南京市长江大桥"}),
        (@node_type_player{id: 2, str: "两块五一套，三块八一斤，四块七一本，五块六一条"}),
        (@node_type_player{id: 3, str: "小和尚留了一个像大和尚一样的和尚头"}),
        (@node_type_player{id: 4, str: "C++和c#是什么关系？11+122=133，是吗？PI=3.14159"}),
        (@node_type_player{id: 5, str: "I love你，不以为耻，反以为rong"})
      """
    Then the execution should be successful
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH (v:player)
      WHERE ftscore(v.str, "长江") > 0
      RETURN v.id
      """
    Then the result should be, in any order:
      | v.id |
      | 1    |
    And the plan should contain "index: player_ft_node_index"
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH ()-[]->(v:player)
      WHERE ftscore(v.str, "长江") > 0
      RETURN v.id
      """
    Then the result should be, in any order:
      | v.id |
    And the plan should contain "index: player_ft_node_index"
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH ()-[]->{0,3}(v:player)
      WHERE ftscore(v.str, "长江") > 0
      RETURN v.id
      """
    Then the result should be, in any order:
      | v.id |
      | 1    |
    And the plan should contain "index: player_ft_node_index"
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH (v:player)
      WHERE ftscore(v.str, "长江") > 0
      RETURN element_id(v) IS NOT NULL AS t
      """
    Then the result should be, in any order:
      | t    |
      | true |
    And the plan should contain "index: player_ft_node_index"
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH (v:player)
      WHERE ftscore(v.str, "长江") > 0
      RETURN v.str
      """
    Then the result should be, in any order:
      | v.str            |
      | "南京市长江大桥" |
    And the plan should contain "index: player_ft_node_index"
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH (v:player)
      WHERE ftscore(v.str, "长江") > 0 AND v.id = 1
      RETURN v.id
      """
    Then the result should be, in any order:
      | v.id |
      | 1    |
    And the plan should contain "index: player_ft_node_index"
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH (v:player)
      WHERE ftscore(v.str, "长江") > 0 AND v.id <> 1
      RETURN v.id
      """
    Then the result should be, in any order:
      | v.id |
    And the plan should contain "index: player_ft_node_index"
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH (v:player /*+ IGNORE_INDEX(player_ft_node_index) */)
      WHERE ftscore(v.str, "长江") > 0
      RETURN v.id
      """
    Then an Error should be raised:
      """
      [NT000]: Full-text search is not supported in current query: ftscore(v.str, "长江")
      """
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH (v:player WHERE ftscore(v.str, "长江") > 0.1)
      RETURN v.id
      """
    Then the result should be, in any order:
      | v.id |
      | 1    |
    # vesoft-inc/nebula-ng#8831
    And the plan should contain "index: player_ft_node_index"
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH (v:player)
      WHERE ftscore(v.str, "长江") > 0.1
      RETURN v.id
      """
    Then the result should be, in any order:
      | v.id |
      | 1    |
    # test score as src
    And the plan should contain "index: player_ft_node_index"
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH (v:player)
      LET score = ftscore(v.str, "长江")
      FILTER score > 0.1
      RETURN element_id(v) IS NOT NULL AS t
      """
    Then the result should be, in any order:
      | t    |
      | true |
    And the plan should contain "index: player_ft_node_index"
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH (v:player)
      LET score = ftscore(v.str, "长江")
      FILTER score > 0.1
      RETURN v.id
      """
    Then the result should be, in any order:
      | v.id |
      | 1    |
    And the plan should contain "index: player_ft_node_index"
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH (v:player)
      LET score = ftscore(v.str, "长江")
      FILTER score > 0.1
      RETURN v.id, score
      """
    Then the result should be, in any order:
      | v.id | score               |
      | 1    | 0.28768207245178085 |
    And the plan should contain "index: player_ft_node_index"
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH (v:player)
      LET score = ftscore(v.str, "长江")
      FILTER score > 0.1
      RETURN score
      """
    Then the result should be, in any order:
      | score               |
      | 0.28768207245178085 |
    And the plan should contain "index: player_ft_node_index"
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH (v:player)
      LET score = ftscore(v.str, "长江")
      RETURN v.id, score
      ORDER BY score
      LIMIT 10
      """
    Then the result should be, in any order:
      | v.id | score               |
      | 1    | 0.28768207245178085 |
    And the plan should contain "index: player_ft_node_index"
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH (v:player)
      LET score = ftscore(v.str, "长江")
      RETURN v.id AS vid, score
      ORDER BY score, vid
      LIMIT 10
      """
    Then the result should be, in any order:
      | vid | score               |
      | 1   | 0.28768207245178085 |
    And the plan should contain "index: player_ft_node_index"
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH (v:player)
      LET score = ftscore(v.str, "长江")
      RETURN v.id AS vid, score
      ORDER BY vid, score
      LIMIT 10
      """
    Then the result should be, in any order:
      | vid | score               |
      | 1   | 0.28768207245178085 |
    And the plan should contain "index: player_ft_node_index"
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH (v:player)
      LET score = ftscore(v.str, "长江")
      RETURN v.id AS vid, score
      ORDER BY score DESC
      LIMIT 10
      """
    Then the result should be, in any order:
      | vid | score               |
      | 1   | 0.28768207245178085 |
    And the plan should contain "index: player_ft_node_index"
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH (v:player)
      LET score = ftscore(v.str, "长江")
      RETURN v.id AS vid, score
      ORDER BY vid
      LIMIT 10
      """
    Then an Error should be raised:
      """
      [NT000]: Full-text search is not supported in current query: ftscore(v.str, "长江")
      """
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH (v:player)
      LET score = ftscore(v.str, "长江")
      RETURN v.id AS vid, score
      ORDER BY score
      APPROX LIMIT 10
      """
    Then an Error should be raised:
      """
      [NT000]: Full-text search is not supported in current query: ftscore(v.str, "长江")
      """
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH (v:player)
      LET score = ftscore(v.str, "长江")
      RETURN v.id, score
      ORDER BY score
      """
    Then an Error should be raised:
      """
      [NT000]: Full-text search is not supported in current query: ftscore(v.str, "长江")
      """
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH (v:player)
      LET score = ftscore(v.str, "长江")
      RETURN v.id AS vid
      ORDER BY vid
      LIMIT 10
      """
    Then an Error should be raised:
      """
      [NT000]: Full-text search is not supported in current query: ftscore(v.str, "长江")
      """
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH (v:player)
      LET score = ftscore(v.str, "长江")
      RETURN v.id, score
      LIMIT 10
      """
    Then the result should be, in any order:
      | v.id | score               |
      | 1    | 0.28768207245178085 |
    And the plan should contain "index: player_ft_node_index"
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH (v:player)
      LET score = ftscore(v.str, "长江")
      RETURN v.id
      LIMIT 10
      """
    Then the result should be, in any order:
      | v.id |
      | 1    |
    # test score as dst
    And the plan should contain "index: player_ft_node_index"
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH ()-[]->(v:player)
      LET score = ftscore(v.str, "长江")
      RETURN v.id, score
      """
    Then an Error should be raised:
      """
      [NT000]: Full-text search is not supported in current query: ftscore(v.str, "长江")
      """
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH ()-[]->(v:player)
      LET score = ftscore(v.str, "长江")
      FILTER score > 1
      RETURN element_id(v) AS vid
      """
    Then an Error should be raised:
      """
      [NT000]: Full-text search is not supported in current query: ftscore(v.str, "长江")
      """
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH ()-[]->(v:player)
      LET score = ftscore(v.str, "长江")
      FILTER score > 1
      RETURN v.id
      """
    Then an Error should be raised:
      """
      [NT000]: Full-text search is not supported in current query: ftscore(v.str, "长江")
      """
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH ()-[]->(v:player)
      LET score = ftscore(v.str, "长江")
      FILTER score > 1
      RETURN v.id, score
      """
    Then an Error should be raised:
      """
      [NT000]: Full-text search is not supported in current query: ftscore(v.str, "长江")
      """
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH ()-[]->(v:player)
      LET score = ftscore(v.str, "长江")
      RETURN v.id, score
      ORDER BY score
      LIMIT 10
      """
    Then an Error should be raised:
      """
      [NT000]: Full-text search is not supported in current query: ftscore(v.str, "长江")
      """
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH ()-[]->(v:player)
      LET score = ftscore(v.str, "长江")
      RETURN v.id AS vid, score
      ORDER BY score, vid
      LIMIT 10
      """
    Then an Error should be raised:
      """
      [NT000]: Full-text search is not supported in current query: ftscore(v.str, "长江")
      """
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH ()-[]->(v:player)
      LET score = ftscore(v.str, "长江")
      RETURN v.id AS vid, score
      ORDER BY vid, score
      LIMIT 10
      """
    Then an Error should be raised:
      """
      [NT000]: Full-text search is not supported in current query: ftscore(v.str, "长江")
      """
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH ()-[]->(v:player)
      LET score = ftscore(v.str, "长江")
      RETURN v.id, score
      ORDER BY score
      """
    Then an Error should be raised:
      """
      [NT000]: Full-text search is not supported in current query: ftscore(v.str, "长江")
      """
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH ()-[]->(v:player)
      LET score = ftscore(v.str, "长江")
      RETURN v.id AS vid
      ORDER BY vid
      LIMIT 10
      """
    Then an Error should be raised:
      """
      [NT000]: Full-text search is not supported in current query: ftscore(v.str, "长江")
      """
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH ()-[]->(v:player)
      LET score = ftscore(v.str, "长江")
      RETURN v.id, score
      LIMIT 10
      """
    Then an Error should be raised:
      """
      [NT000]: Full-text search is not supported in current query: ftscore(v.str, "长江")
      """
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH ()-[]->(v:player)
      LET score = ftscore(v.str, "长江")
      RETURN v.id
      LIMIT 10
      """
    Then an Error should be raised:
      """
      [NT000]: Full-text search is not supported in current query: ftscore(v.str, "长江")
      """
    # test score as dst of variable length paths
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH ()-[]->{0,3}(v:player)
      LET score = ftscore(v.str, "长江")
      RETURN v.id, score
      """
    Then an Error should be raised:
      """
      [NT000]: Full-text search is not supported in current query: ftscore(v.str, "长江")
      """
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH ()-[]->{0,3}(v:player)
      LET score = ftscore(v.str, "长江")
      FILTER score > 0.1
      RETURN element_id(v) AS vid
      """
    Then an Error should be raised:
      """
      [NT000]: Full-text search is not supported in current query: ftscore(v.str, "长江")
      """
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH ()-[]->{0,3}(v:player)
      LET score = ftscore(v.str, "长江")
      FILTER score > 0.1
      RETURN v.id, score
      """
    Then an Error should be raised:
      """
      [NT000]: Full-text search is not supported in current query: ftscore(v.str, "长江")
      """
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH ()-[]->{0,3}(v:player)
      LET score = ftscore(v.str, "长江")
      RETURN v.id, score
      ORDER BY score
      LIMIT 10
      """
    Then an Error should be raised:
      """
      [NT000]: Full-text search is not supported in current query: ftscore(v.str, "长江")
      """
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH ()-[]->{0,3}(v:player)
      LET score = ftscore(v.str, "长江")
      RETURN v.id AS vid, score
      ORDER BY score, vid
      LIMIT 10
      """
    Then an Error should be raised:
      """
      [NT000]: Full-text search is not supported in current query: ftscore(v.str, "长江")
      """
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH ()-[]->{0,3}(v:player)
      LET score = ftscore(v.str, "长江")
      RETURN v.id AS vid, score
      ORDER BY vid, score
      LIMIT 10
      """
    Then an Error should be raised:
      """
      [NT000]: Full-text search is not supported in current query: ftscore(v.str, "长江")
      """
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH ()-[]->{0,3}(v:player)
      LET score = ftscore(v.str, "长江")
      RETURN v.id, score
      ORDER BY score
      """
    Then an Error should be raised:
      """
      [NT000]: Full-text search is not supported in current query: ftscore(v.str, "长江")
      """
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH ()-[]->{0,3}(v:player)
      LET score = ftscore(v.str, "长江")
      RETURN v.id AS vid
      ORDER BY vid
      LIMIT 10
      """
    Then an Error should be raised:
      """
      [NT000]: Full-text search is not supported in current query: ftscore(v.str, "长江")
      """
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH ()-[]->{0,3}(v:player)
      LET score = ftscore(v.str, "长江")
      RETURN v.id, score
      LIMIT 10
      """
    Then an Error should be raised:
      """
      [NT000]: Full-text search is not supported in current query: ftscore(v.str, "长江")
      """
    When executing query:
      """
      USE fulltext_node_index_g
      MATCH (v:player /*+ IGNORE_INDEX(player_ft_node_index_score) */)
      LET score = ftscore(v.str, "长江")
      RETURN v.id, score
      """
    Then an Error should be raised:
      """
      [NT000]: Full-text search is not supported in current query: ftscore(v.str, "长江")
      """
    And drop the index "player_ft_node_index" of "fulltext_node_index_g"
    And drop the graph "fulltext_node_index_g"
    And drop the graph type "fulltext_node_index_gt"

  Scenario: test edge fulltext index
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS fulltext_edge_index_gt AS {
        NODE node_type_player ( LABEL player {id INT PRIMARY KEY}),
        EDGE edge_type_follow (node_type_player)-[LABEL follow {str STRING, id INT}]->(node_type_player)
      }
      """
    Then the execution should be successful
    And drop the graph "fulltext_edge_index_g"
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS fulltext_edge_index_g TYPED fulltext_edge_index_gt
      """
    Then the execution should be successful
    And drop the index "player_ft_edge_index" of "fulltext_edge_index_g"
    When executing query:
      """
      USE fulltext_edge_index_g CREATE FULLTEXT INDEX IF NOT EXISTS player_ft_edge_index ON EDGE edge_type_follow(str)
      """
    Then the execution should be successful
    When executing query:
      """
      USE fulltext_edge_index_g SHOW INDEXES
      """
    Then the result should contain:
      | name                   | state   | index_type | schema            | graph_name              | entity_type | element_type       | properties  |
      | "player_ft_edge_index" | "Valid" | "Fulltext" | "/default_schema" | "fulltext_edge_index_g" | "Edge"      | "edge_type_follow" | LIST["str"] |
    When executing query:
      """
      USE fulltext_edge_index_g INSERT
        (@node_type_player{id: 1}),
        (@node_type_player{id: 2}),
        (@node_type_player{id: 3}),
        (@node_type_player{id: 4}),
        (@node_type_player{id: 5})
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t TYPED TABLE {src INT, dst INT, str STRING} =
        (1, 2, "南京市长江大桥"),
        (2, 3, "两块五一套，三块八一斤，四块七一本，五块六一条"),
        (2, 4, "小和尚留了一个像大和尚一样的和尚头"),
        (3, 4, "C++和c#是什么关系？11+122=133，是吗？PI=3.14159"),
        (4, 1, "I love你，不以为耻，反以为rong")
      USE fulltext_edge_index_g
      FOR r IN t
      INSERT OR REPLACE (@node_type_player{id: r.src})-[@edge_type_follow{str: r.str, id: r.src}]->(@node_type_player{id: r.dst})
      """
    Then the execution should be successful
    When executing query:
      """
      USE fulltext_edge_index_g
      MATCH (v)-[e:follow]->()
      WHERE ftscore(e.str, "长江") > 0
      RETURN v.id
      """
    Then the result should be, in any order:
      | v.id |
      | 1    |
    And the plan should contain "index: player_ft_edge_index"
    When executing query:
      """
      USE fulltext_edge_index_g
      MATCH (v)-[e:follow]->()
      WHERE ftscore(e.str, "长江") > 0
      RETURN e.str
      """
    Then the result should be, in any order:
      | e.str            |
      | "南京市长江大桥" |
    And the plan should contain "index: player_ft_edge_index"
    When executing query:
      """
      USE fulltext_edge_index_g
      MATCH (v)-[e:follow]->()
      WHERE ftscore(e.str, "长江") > 0
      RETURN right_node_id(e) IS NOT NULL AS t
      """
    Then the result should be, in any order:
      | t    |
      | true |
    And the plan should contain "index: player_ft_edge_index"
    When executing query:
      """
      USE fulltext_edge_index_g
      MATCH ()-[e:follow WHERE ftscore(e.str, "长江") > 0]->{0,3}(v:player)
      RETURN v.id
      """
    Then the result should be, in any order:
      | v.id |
      | 5    |
      | 1    |
      | 3    |
      | 4    |
      | 2    |
      | 2    |
    # vesoft-inc/nebula-ng#8831
    And the plan should contain "index: player_ft_edge_index"
    When executing query:
      """
      USE fulltext_edge_index_g
      MATCH (v)-[e:follow]->()
      WHERE ftscore(e.str, "长江") > 0.1
      RETURN e.id AS vid
      """
    Then the result should be, in any order:
      | vid |
      | 1   |
    # test score
    And the plan should contain "index: player_ft_edge_index"
    When executing query:
      """
      USE fulltext_edge_index_g
      MATCH (v)-[e:follow]->()
      LET score = ftscore(e.str, "长江")
      FILTER score > 0.1
      RETURN e.id AS vid
      """
    Then the result should be, in any order:
      | vid |
      | 1   |
    And the plan should contain "index: player_ft_edge_index"
    When executing query:
      """
      USE fulltext_edge_index_g
      MATCH (v)-[e:follow]->()
      LET score = ftscore(e.str, "长江")
      FILTER score > 0.1
      RETURN e.id, score
      """
    Then the result should be, in any order:
      | e.id | score               |
      | 1    | 0.28768207245178085 |
    And the plan should contain "index: player_ft_edge_index"
    When executing query:
      """
      USE fulltext_edge_index_g
      MATCH (v)-[e:follow]->()
      LET score = ftscore(e.str, "长江")
      FILTER score > 0.1
      RETURN score
      """
    Then the result should be, in any order:
      | score               |
      | 0.28768207245178085 |
    And the plan should contain "index: player_ft_edge_index"
    When executing query:
      """
      USE fulltext_edge_index_g
      MATCH ()-[e:follow]->()
      LET score = ftscore(e.str, "长江")
      RETURN e.id, score
      ORDER BY score
      LIMIT 10
      """
    Then the result should be, in any order:
      | e.id | score               |
      | 1    | 0.28768207245178085 |
    And the plan should contain "index: player_ft_edge_index"
    When executing query:
      """
      USE fulltext_edge_index_g
      MATCH ()-[e:follow]->()
      LET score = ftscore(e.str, "长江")
      RETURN e.id AS eid, score
      ORDER BY score, eid
      LIMIT 10
      """
    Then the result should be, in any order:
      | eid | score               |
      | 1   | 0.28768207245178085 |
    And the plan should contain "index: player_ft_edge_index"
    When executing query:
      """
      USE fulltext_edge_index_g
      MATCH ()-[e:follow]->()
      LET score = ftscore(e.str, "长江")
      RETURN e.id AS eid, score
      ORDER BY eid, score
      LIMIT 10
      """
    Then the result should be, in any order:
      | eid | score               |
      | 1   | 0.28768207245178085 |
    And the plan should contain "index: player_ft_edge_index"
    When executing query:
      """
      USE fulltext_edge_index_g
      MATCH ()-[e:follow]->()
      LET score = ftscore(e.str, "长江")
      RETURN e.id AS eid, score
      ORDER BY eid
      LIMIT 10
      """
    Then an Error should be raised:
      """
      [NT000]: Full-text search is not supported in current query: ftscore(e.str, "长江")
      """
    When executing query:
      """
      USE fulltext_edge_index_g
      MATCH ()-[e:follow]->()
      LET score = ftscore(e.str, "长江")
      RETURN e.id, score
      ORDER BY score
      APPROX LIMIT 10
      """
    Then an Error should be raised:
      """
      [NT000]: Full-text search is not supported in current query: ftscore(e.str, "长江")
      """
    When executing query:
      """
      USE fulltext_edge_index_g
      MATCH ()-[e:follow]->()
      LET score = ftscore(e.str, "长江")
      RETURN e.id AS eid, score
      ORDER BY score DESC
      LIMIT 10
      """
    Then the result should be, in any order:
      | eid | score               |
      | 1   | 0.28768207245178085 |
    And the plan should contain "index: player_ft_edge_index"
    When executing query:
      """
      USE fulltext_edge_index_g
      MATCH ()-[e:follow]->()
      LET score = ftscore(e.str, "长江")
      RETURN e.id, score
      ORDER BY score
      """
    Then an Error should be raised:
      """
      [NT000]: Full-text search is not supported in current query: ftscore(e.str, "长江")
      """
    When executing query:
      """
      USE fulltext_edge_index_g
      MATCH ()-[e:follow]->()
      LET score = ftscore(e.str, "长江")
      RETURN e.id AS eid
      ORDER BY eid
      LIMIT 10
      """
    Then an Error should be raised:
      """
      [NT000]: Full-text search is not supported in current query: ftscore(e.str, "长江")
      """
    When executing query:
      """
      USE fulltext_edge_index_g
      MATCH ()-[e:follow]->()
      LET score = ftscore(e.str, "长江")
      RETURN e.id, score
      LIMIT 10
      """
    Then the result should be, in any order:
      | e.id | score               |
      | 1    | 0.28768207245178085 |
    And the plan should contain "index: player_ft_edge_index"
    When executing query:
      """
      USE fulltext_edge_index_g
      MATCH ()-[e:follow]->()
      LET score = ftscore(e.str, "长江")
      RETURN e.id
      LIMIT 10
      """
    Then the result should be, in any order:
      | e.id |
      | 1    |
    And the plan should contain "index: player_ft_edge_index"
    When executing query:
      """
      USE fulltext_edge_index_g
      MATCH (v)-[e:follow WHERE ftscore(e.str, "长江") > 0 /*+ IGNORE_INDEX(player_ft_edge_index) */]->()
      RETURN v.id
      """
    Then an Error should be raised:
      """
      [NT000]: Full-text search is not supported in current query: ftscore(e.str, "长江")
      """
    When executing query:
      """
      USE fulltext_edge_index_g
      MATCH (v)-[e:follow WHERE ftscore(e.str, "长江") > 0.1]->()
      RETURN e.id
      """
    Then the result should be, in any order:
      | e.id |
      | 1    |
    And the plan should contain "index: player_ft_edge_index"
    And drop the index "player_ft_edge_index" of "fulltext_edge_index_g"
    And drop the graph "fulltext_edge_index_g"
    And drop the graph type "fulltext_edge_index_gt"

  Scenario: unsupported parameter type for full text search
    When executing query:
      """
      USE ldbc MATCH (v:Person)
      LET name = v.firstName
      FILTER WHERE ftscore(name, "长江") > 0
      RETURN v.id
      """
    Then an Error should be raised:
      """
      [NR006]: Resolve function failed: `the ftscore function `ftscore(name, "长江")` only supports property reference and constant string expressions as its arguments`
      """
    When executing query:
      """
      USE ldbc MATCH (v:Person)
      LET str = "长江"
      FILTER WHERE ftscore(v.firstName, str) > 0
      RETURN v.id
      """
    Then an Error should be raised:
      """
      [NR006]: Resolve function failed: `the ftscore function `ftscore(v.firstName, str)` only supports property reference and constant string expressions as its arguments`
      """

  Scenario: vesoft-inc/nebula-ng#8773
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS fulltext_test_gt_8773 AS {
          NODE TYPE person({ id int primary key}),
          NODE TYPE post({ id int primary key}),
          EDGE person_like_post (person)-[ {_comment string multiedge key}]->(post)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      create graph fulltext_test_g_8773 fulltext_test_gt_8773
      """
    Then the execution should be successful
    When executing query:
      """
      use fulltext_test_g_8773 create fulltext index ft_idx_8773 on edge person_like_post(_comment)
      """
    Then the execution should be successful
    When executing query:
      """
      use fulltext_test_g_8773
      insert
        (a@person{id:1})-[@person_like_post{_comment:"全文索引极大地提升了大数据量下的查询性能，避免了低效的‘LIKE %...%’操作。"}]->(b@post{id:1}),
        (@person{id:2})-[@person_like_post{_comment:"这是一个用于测试全文索引的中文句子，它包含了关键词如‘数据库’和‘搜索’。"}]->(@post{id:2})
      """
    Then the execution should be successful
    When executing query:
      """
      use fulltext_test_g_8773 match (s)-[e]->(d) where ftscore(e._comment,"全文索引") > 0 return e._comment
      """
    Then the execution should be successful
    And the plan should contain "index: ft_idx_8773"
    When executing query:
      """
      use fulltext_test_g_8773 match (s)-[e]->(d) let score= ftscore(e._comment,"全文索引") filter where score> 0 return e._comment
      """
    Then the execution should be successful
    And the plan should contain "index: ft_idx_8773"
    When executing query:
      """
      use fulltext_test_g_8773 match (s)-[e]->(d) where ftscore(e._comment,"全文索引") > 0.001 return e._comment
      """
    Then the execution should be successful
    And the plan should contain "index: ft_idx_8773"
    When executing query:
      """
      use fulltext_test_g_8773 match (s)-[e]->(d) let score= ftscore(e._comment,"全文索引") filter where score> 0.001 return e._comment
      """
    Then the execution should be successful
    And the plan should contain "index: ft_idx_8773"
    And drop the index "ft_idx_8773" of "fulltext_test_g_8773"
    And drop the graph "fulltext_test_g_8773"
    And drop the graph type "fulltext_test_gt_8773"

  Scenario: vesoft-inc/nebula-ng#8736
    When executing query:
      """
      create graph type ft_gt_8736 as {node person ({id int primary key, name string})}
      """
    Then the execution should be successful
    When executing query:
      """
      create graph ft_g_8736 typed ft_gt_8736
      """
    Then the execution should be successful
    When executing query:
      """
      use ft_g_8736 create fulltext index ft_idx_8736 on node person(name)
      """
    Then the execution should be successful
    When executing query:
      """
      use ft_g_8736 insert (@person{id:1,name:"test"})
      """
    Then the execution should be successful
    When executing query:
      """
      use ft_g_8736 match (v) where ftscore(v.name,"test") > 0 return v.name
      """
    Then the result should be, in any order:
      | v.name |
      | "test" |
    And the plan should contain "index: ft_idx_8736"
    When executing query:
      """
      use ft_g_8736 match (v) where ftscore(v.name,"test") > 0 return v.id,v.name
      """
    Then the result should be, in any order:
      | v.id | v.name |
      | 1    | "test" |
    And the plan should contain "index: ft_idx_8736"
    And drop the index "ft_idx_8736" of "ft_g_8736"
    And drop the graph "ft_g_8736"
    And drop the graph type "ft_gt_8736"

  @skip
  Scenario: fulltext index selection
    When executing query:
      """
      USE ldbc MATCH (v:Person)
      WHERE ftscore(v.name, "长江") > 0 AND ftscore(v.name, "杭州") > 0 OR ftscore(v.name, "浙江") > 0
      RETURN v.id
      """
    Then an Error should be raised:
      """
      [NR000] Invalid fulltext index access: Cannot find fulltext index for NODE property `v.name` in expression `ftscore(v.name, "长江") > 0`
      """

  Scenario: vesoft-inc/nebula-ng#8654
    When executing query:
      """
      create graph type if not exists ft_gt_8654 as {
        node person({id int primary key, name string}),
        edge knows (person)-[{name string}]->(person)
      }
      """
    Then the execution should be successful
    And drop the graph "ft_g_8654"
    When executing query:
      """
      create graph ft_g_8654 typed ft_gt_8654
      """
    Then the execution should be successful
    When executing query:
      """
      use ft_g_8654 create fulltext index ft_idx_8654 on node person(name)
      """
    Then the execution should be successful
    When executing query:
      """
      use ft_g_8654 create fulltext index ft_eidx_8654 on edge knows(name)
      """
    Then the execution should be successful
    When executing query:
      """
      use ft_g_8654 insert
        (@person{id:1, name:"这是一条测试数据"}),
        (@person{id:2, name:"这是一句测试数据"})
      """
    Then the execution should be successful
    When executing query:
      """
      use ft_g_8654
      match (s{id:1}), (d{id:2})
      insert (s)-[@knows{name: "这还是一条测试数据"}]->(d)
      """
    Then the execution should be successful
    When executing query:
      """
      use ft_g_8654 match (v) where ftscore(v.name, "这") > 0 return v.name
      """
    Then the result should be, in any order:
      | v.name |
    And the plan should contain "index: ft_idx_8654"
    When executing query:
      """
      use ft_g_8654 match (v) where ftscore(v.name, "一条") > 0 return v.name
      """
    Then the result should be, in any order:
      | v.name             |
      | "这是一条测试数据" |
    And the plan should contain "index: ft_idx_8654"
    When executing query:
      """
      use ft_g_8654 match ()-[e]->() where ftscore(e.name, "这") > 0 return e.name
      """
    Then the result should be, in any order:
      | e.name |
    And the plan should contain "index: ft_eidx_8654"
    When executing query:
      """
      use ft_g_8654 match ()-[e]->() where ftscore(e.name, "一条") > 0 return e.name
      """
    Then the result should be, in any order:
      | e.name               |
      | "这还是一条测试数据" |
    And the plan should contain "index: ft_eidx_8654"
    And drop the index "ft_idx_8654" of "ft_g_8654"
    And drop the index "ft_eidx_8654" of "ft_g_8654"
    And drop the graph "ft_g_8654"
    And drop the graph type "ft_gt_8654"

  Scenario: vesoft-inc/nebula-ng#8770
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS fulltext_gt_8770 AS {
        NODE TYPE Comment(:Message { id int primary key, title string default "无标题的Comment"}),
        NODE TYPE Post(:Message { id int primary key, title string default "无标题的Post"})
      }
      """
    Then the execution should be successful
    And drop the graph "fulltext_g_8770"
    When executing query:
      """
      CREATE GRAPH fulltext_g_8770 TYPED fulltext_gt_8770
      """
    Then the execution should be successful
    When executing query:
      """
      USE fulltext_g_8770 CREATE FULLTEXT INDEX i1_8770 ON NODE Comment(title)
      """
    Then the execution should be successful
    When executing query:
      """
      USE fulltext_g_8770 CREATE FULLTEXT INDEX i2_8770 ON NODE Post(title)
      """
    Then the execution should be successful
    When executing query:
      """
      USE fulltext_g_8770 INSERT (@Post{id:1}),(@Comment{id:2})
      """
    Then the execution should be successful
    When executing query:
      """
      USE fulltext_g_8770 MATCH (v) FILTER ftscore(v.title,"标题") > 0 RETURN v.title
      """
    Then the result should be, in any order:
      | v.title           |
      | "无标题的Comment" |
      | "无标题的Post"    |
    And the plan should contain "index: i1_8770"
    And the plan should contain "index: i2_8770"
    When executing query:
      """
      USE fulltext_g_8770
      MATCH (v)
      LET score = ftscore(v.title,"标题")
      FILTER score>0
      RETURN v.title
      """
    Then the result should be, in any order:
      | v.title           |
      | "无标题的Comment" |
      | "无标题的Post"    |
    And the plan should contain "index: i1_8770"
    And the plan should contain "index: i2_8770"
    And drop the index "i1_8770" of "fulltext_g_8770"
    And drop the index "i2_8770" of "fulltext_g_8770"
    And drop the graph "fulltext_g_8770"
    And drop the graph type "fulltext_gt_8770"

  Scenario: test topK with ORDER BY score DESC
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS fulltext_topk_gt AS {
        NODE node_type_doc ( LABEL doc {id INT PRIMARY KEY, content STRING})
      }
      """
    Then the execution should be successful
    And drop the graph "fulltext_topk_g"
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS fulltext_topk_g TYPED fulltext_topk_gt
      """
    Then the execution should be successful
    And drop the index "doc_ft_index" of "fulltext_topk_g"
    When executing query:
      """
      USE fulltext_topk_g CREATE FULLTEXT INDEX IF NOT EXISTS doc_ft_index ON NODE node_type_doc(content)
      """
    Then the execution should be successful
    When executing query:
      """
      USE fulltext_topk_g INSERT
        (@node_type_doc{id: 1, content: "人工智能机器学习深度学习神经网络"}),
        (@node_type_doc{id: 2, content: "机器学习算法优化模型训练"}),
        (@node_type_doc{id: 3, content: "深度学习神经网络卷积神经网络"}),
        (@node_type_doc{id: 4, content: "人工智能技术发展迅速"}),
        (@node_type_doc{id: 5, content: "机器学习是人工智能的重要分支"}),
        (@node_type_doc{id: 6, content: "神经网络在深度学习中广泛应用"}),
        (@node_type_doc{id: 7, content: "人工智能机器学习深度学习"}),
        (@node_type_doc{id: 8, content: "机器学习模型训练和优化"}),
        (@node_type_doc{id: 9, content: "深度学习框架TensorFlow PyTorch"}),
        (@node_type_doc{id: 10, content: "人工智能应用场景丰富多样"})
      """
    Then the execution should be successful
    When executing query:
      """
      USE fulltext_topk_g
      MATCH (v:doc)
      LET score = ftscore(v.content, "机器学习")
      RETURN v.id AS vid, score
      ORDER BY score DESC
      LIMIT 5
      """
    Then the execution should be successful
    Then the result should be, in any order:
      | vid |
      | 1   |
      | 2   |
      | 5   |
      | 7   |
      | 8   |
    And the plan should contain "index: doc_ft_index"
    When executing query:
      """
      USE fulltext_topk_g
      MATCH (v:doc)
      LET score = ftscore(v.content, "人工智能")
      RETURN v.id AS vid, score
      ORDER BY score DESC
      LIMIT 3
      """
    Then the execution should be successful
    Then the result should be, in any order:
      | vid |
      | 1   |
      | 4   |
      | 7   |
    And the plan should contain "index: doc_ft_index"
    When executing query:
      """
      USE fulltext_topk_g
      MATCH (v:doc)
      LET score = ftscore(v.content, "深度学习")
      RETURN v.id AS vid, score
      ORDER BY score DESC
      LIMIT 4
      """
    Then the execution should be successful
    Then the result should be, in any order:
      | vid |
      | 1   |
      | 3   |
      | 6   |
      | 7   |
    And the plan should contain "index: doc_ft_index"
    And drop the index "doc_ft_index" of "fulltext_topk_g"
    And drop the graph "fulltext_topk_g"
    And drop the graph type "fulltext_topk_gt"
