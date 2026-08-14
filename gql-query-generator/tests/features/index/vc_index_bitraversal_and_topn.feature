# Copyright (c) 2026 vesoft inc. All rights reserved.
Feature: Vertex-Centric Index BiTraversal KHop BiBFS and TopN Push-down

  Scenario: VC index with K-HOP Recursive EdgesScan variable-length expansion
    # Part 13 (extracted): Multi-hop variable-length traversal with VC index.
    # MATCH WALK ...->{N,M}(dst) with unfixed dst uses Recursive+EdgesScan (KHop path).
    # The VC index is visible as "vcIndex: ..." in the plan.
    # ============================================
    # Setup
    # ============================================
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS vc_bitraversal_graph_type AS {
        NODE user (LABEL user {id INT64 PRIMARY KEY, name STRING, age INT64}),
        NODE movie (LABEL movie {id INT64 PRIMARY KEY, title STRING, year INT64}),
        EDGE watch (user)-[LABEL watch {rate INT64, ts INT64}]->(movie),
        EDGE friend (user)-[LABEL friend {since INT64, weight INT64}]->(user)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH IF EXISTS vc_bitraversal_graph
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH vc_bitraversal_graph TYPED vc_bitraversal_graph_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_bitraversal_graph INSERT (@user{id:1, name:"Alice", age:25}), (@user{id:2, name:"Bob", age:30}), (@user{id:3, name:"Carol", age:28}), (@user{id:4, name:"David", age:35})
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_bitraversal_graph MATCH (u1:user WHERE u1.id = 1), (u2:user WHERE u2.id = 2), (u3:user WHERE u3.id = 3), (u4:user WHERE u4.id = 4) INSERT (u1)-[@friend{since:2020, weight:10}]->(u2), (u1)-[@friend{since:2021, weight:8}]->(u3), (u1)-[@friend{since:2019, weight:9}]->(u4), (u2)-[@friend{since:2022, weight:7}]->(u1), (u2)-[@friend{since:2023, weight:6}]->(u3), (u3)-[@friend{since:2024, weight:5}]->(u1), (u4)-[@friend{since:2021, weight:9}]->(u1), (u4)-[@friend{since:2022, weight:8}]->(u2), (u3)-[@friend{since:2023, weight:6}]->(u2)
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_bitraversal_graph CREATE INDEX friend_src_since_idx ON EDGE friend(_src, since)
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_bitraversal_graph CREATE INDEX friend_src_weight_idx ON EDGE friend(_src, weight)
      """
    Then the execution should be successful
    # ============================================
    # 13a: auto-select VC index for K-HOP (Recursive+EdgesScan, unfixed dst)
    # No hint; optimizer picks friend_src_since_idx because predicate is on since.
    # 1-hop with since>=2020: 1→2(2020), 1→3(2021). 2-hop reachable: {1,2,3}.
    # ============================================
    When executing query:
      """
      PROFILE USE vc_bitraversal_graph MATCH WALK (u1:user WHERE u1.id = 1)-[e:friend WHERE e.since >= 2020]->{1,2}(u2:user) RETURN DISTINCT u2.id AS to_user ORDER BY to_user
      """
    And the plan should contain "vcIndex: friend_src_since_idx"
    Then the result should be, in order:
      | to_user |
      | 1       |
      | 2       |
      | 3       |
    # ============================================
    # 13b: explicit INDEX hint on a non-matching VC index must not force VC rewrite
    # Dynamic-filter K-HOP already does an _src prefix scan; if the hint only matches
    # the anchor column and misses the actual filter predicate, we must stay on the
    # plain scan path.
    # ============================================
    When executing query:
      """
      PROFILE USE vc_bitraversal_graph MATCH WALK (u1:user WHERE u1.id = 1)-[e:friend WHERE e.since >= 2020 /*+ INDEX(friend_src_weight_idx) */]->{1,2}(u2:user) RETURN DISTINCT u2.id AS to_user ORDER BY to_user
      """
    And the plan should not contain "index: friend_src_since_idx"
    And the plan should not contain "index: friend_src_weight_idx"
    Then the result should be, in order:
      | to_user |
      | 1       |
      | 2       |
      | 3       |
    # ============================================
    # 13c: IGNORE_INDEX must not leave behind an anchor-only VC rewrite
    # Excluding friend_src_since_idx leaves friend_src_weight_idx, but that index still
    # does not match the since predicate, so no VC rewrite is allowed.
    # ============================================
    When executing query:
      """
      PROFILE USE vc_bitraversal_graph MATCH WALK (u1:user WHERE u1.id = 1)-[e:friend WHERE e.since >= 2020 /*+ IGNORE_INDEX(friend_src_since_idx) */]->{1,2}(u2:user) RETURN DISTINCT u2.id AS to_user ORDER BY to_user
      """
    And the plan should not contain "index: friend_src_since_idx"
    And the plan should not contain "index: friend_src_weight_idx"
    Then the result should be, in order:
      | to_user |
      | 1       |
      | 2       |
      | 3       |
    # ============================================
    # 13c1: undirected K-HOP must stay correct when only an _src VC index exists
    # The first hop can use the _src VC index, but incoming-compatible expansions must
    # fall back instead of incorrectly reusing the _src index for the reverse direction.
    # 2-hop undirected reachable with since>=2020: {1,2,3,4}.
    # ============================================
    When executing query:
      """
      PROFILE USE vc_bitraversal_graph MATCH WALK (u1:user WHERE u1.id = 1)-[e:friend WHERE e.since >= 2020 /*+ INDEX(friend_src_since_idx) */]-{2,2}(u2:user) RETURN DISTINCT u2.id AS to_user ORDER BY to_user
      """
    And the plan should contain "vcIndex: friend_src_since_idx"
    Then the result should be, in order:
      | to_user |
      | 1       |
      | 2       |
      | 3       |
      | 4       |
    # ============================================
    # 13c2: undirected K-HOP without VC index must return the same result
    # Excluding both VC indexes forces the plain scan path.
    # ============================================
    When executing query:
      """
      PROFILE USE vc_bitraversal_graph MATCH WALK (u1:user WHERE u1.id = 1)-[e:friend WHERE e.since >= 2020 /*+ IGNORE_INDEX(friend_src_since_idx, friend_src_weight_idx) */]-{2,2}(u2:user) RETURN DISTINCT u2.id AS to_user ORDER BY to_user
      """
    And the plan should not contain "index: friend_src_since_idx"
    And the plan should not contain "index: friend_src_weight_idx"
    Then the result should be, in order:
      | to_user |
      | 1       |
      | 2       |
      | 3       |
      | 4       |
    # ============================================
    # 13c3: BiVarLenExpand with INDEX hint on an undirected traversal
    # The runtime can only attach one scan method per side, so multidirectional
    # BiTraversal must not apply a single-direction VC index.
    # 3-hop trails from user 1 back to itself with since>=2020: 20.
    # ============================================
    When executing query:
      """
      PROFILE /*+ set_var(optimizer_rules="force_var_len_to_bi=on")*/
      USE vc_bitraversal_graph MATCH p=trail (u1:user WHERE u1.id IN [1])-[e:friend WHERE e.since >= 2020 /*+ INDEX(friend_src_since_idx) */]-{3,3}(u2:user WHERE u2.id IN [1]) RETURN count(e)
      """
    And the plan should contain "BiVarLenExpand"
    And the plan should not contain "index: friend_src_since_idx"
    And the plan should not contain "index: friend_src_weight_idx"
    Then the result should be, in order:
      | count(e) |
      | 20       |
    # ============================================
    # 13c4: BiVarLenExpand without VC index must match the INDEX-hinted query
    # ============================================
    When executing query:
      """
      PROFILE /*+ set_var(optimizer_rules="force_var_len_to_bi=on")*/
      USE vc_bitraversal_graph MATCH p=trail (u1:user WHERE u1.id IN [1])-[e:friend WHERE e.since >= 2020 /*+ IGNORE_INDEX(friend_src_since_idx, friend_src_weight_idx) */]-{3,3}(u2:user WHERE u2.id IN [1]) RETURN count(e)
      """
    And the plan should contain "BiVarLenExpand"
    And the plan should not contain "index: friend_src_since_idx"
    And the plan should not contain "index: friend_src_weight_idx"
    Then the result should be, in order:
      | count(e) |
      | 20       |
    # ============================================
    # Cleanup
    # ============================================
    When executing query:
      """
      USE vc_bitraversal_graph DROP INDEX friend_src_since_idx
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_bitraversal_graph DROP INDEX friend_src_weight_idx
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH IF EXISTS vc_bitraversal_graph
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE IF EXISTS vc_bitraversal_graph_type
      """
    Then the execution should be successful

  Scenario: VC index with SHORTEST PATH BiBFS bidirectional traversal
    # Part 13 (extracted, BiBFS part): BiBFS uses ApplyVcIndexToBiTraversalRule.
    # MATCH ANY SHORTEST with both endpoints fixed uses BiBFS;
    # the VC index shows as "vcIndex: ..." in the BiBFS plan node.
    # ============================================
    # Setup
    # ============================================
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS vc_bfs_graph_type AS {
        NODE user (LABEL user {id INT64 PRIMARY KEY, name STRING, age INT64}),
        EDGE friend (user)-[LABEL friend {since INT64, weight INT64}]->(user)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH IF EXISTS vc_bfs_graph
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH vc_bfs_graph TYPED vc_bfs_graph_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_bfs_graph INSERT (@user{id:1, name:"Alice", age:25}), (@user{id:2, name:"Bob", age:30}), (@user{id:3, name:"Carol", age:28}), (@user{id:4, name:"David", age:35})
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_bfs_graph MATCH (u1:user WHERE u1.id = 1), (u2:user WHERE u2.id = 2), (u3:user WHERE u3.id = 3), (u4:user WHERE u4.id = 4) INSERT (u1)-[@friend{since:2020, weight:10}]->(u2), (u1)-[@friend{since:2021, weight:8}]->(u3), (u1)-[@friend{since:2019, weight:9}]->(u4), (u2)-[@friend{since:2022, weight:7}]->(u1), (u2)-[@friend{since:2023, weight:6}]->(u3), (u3)-[@friend{since:2024, weight:5}]->(u1)
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_bfs_graph CREATE INDEX friend_src_since_idx ON EDGE friend(_src, since)
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_bfs_graph CREATE INDEX friend_src_weight_idx ON EDGE friend(_src, weight)
      """
    Then the execution should be successful
    # ============================================
    # 13d: SHORTEST PATH (BiBFS) with edge filter, auto-select VC index
    # ANY SHORTEST 1→3 with since>=2020: direct edge 1→3 (since:2021) satisfies filter.
    # ============================================
    When executing query:
      """
      PROFILE USE vc_bfs_graph MATCH p = ANY SHORTEST (u1:user WHERE u1.id = 1)-[e:friend WHERE e.since >= 2020]->*(u2:user WHERE u2.id = 3) RETURN length(p) AS hops
      """
    And the plan should contain "vcIndex: friend_src_since_idx"
    Then the result should be, in order:
      | hops |
      | 1    |
    # ============================================
    # 13e: SHORTEST PATH with explicit non-matching INDEX hint must not force VC rewrite
    # ============================================
    When executing query:
      """
      PROFILE USE vc_bfs_graph MATCH p = ANY SHORTEST (u1:user WHERE u1.id = 1)-[e:friend WHERE e.since >= 2020 /*+ INDEX(friend_src_weight_idx) */]->*(u2:user WHERE u2.id = 3) RETURN length(p) AS hops
      """
    And the plan should not contain "index: friend_src_since_idx"
    And the plan should not contain "index: friend_src_weight_idx"
    Then the result should be, in order:
      | hops |
      | 1    |
    # ============================================
    # 13f: SHORTEST PATH without edge filter — no VC index (BiBFS check() gate)
    # ============================================
    When executing query:
      """
      PROFILE USE vc_bfs_graph MATCH p = ANY SHORTEST (u1:user WHERE u1.id = 1)-[:friend]->*(u2:user WHERE u2.id = 3) RETURN length(p) AS hops
      """
    And the plan should not contain "index: friend_src_since_idx"
    And the plan should not contain "index: friend_src_weight_idx"
    Then the result should be, in order:
      | hops |
      | 1    |
    # ============================================
    # Cleanup
    # ============================================
    When executing query:
      """
      USE vc_bfs_graph DROP INDEX friend_src_since_idx
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_bfs_graph DROP INDEX friend_src_weight_idx
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH IF EXISTS vc_bfs_graph
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE IF EXISTS vc_bfs_graph_type
      """
    Then the execution should be successful

  @testmark
  Scenario: VC dst-only index should stay correct for undirected K-HOP
    # Only a _dst-leading VC index exists in this graph.
    # Undirected variable-length expansion must be able to use that index without crashing
    # storaged, and the IGNORE_INDEX fallback must return the same answer.
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS vc_dst_only_graph_type AS {
        NODE user (LABEL user {id INT64 PRIMARY KEY, name STRING}),
        EDGE friend (user)-[LABEL friend {since INT64}]->(user)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH IF EXISTS vc_dst_only_graph
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH vc_dst_only_graph TYPED vc_dst_only_graph_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_dst_only_graph INSERT (@user{id:1, name:"A"}), (@user{id:2, name:"B"}), (@user{id:3, name:"C"}), (@user{id:4, name:"D"})
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_dst_only_graph MATCH (u1:user WHERE u1.id = 1), (u2:user WHERE u2.id = 2), (u3:user WHERE u3.id = 3), (u4:user WHERE u4.id = 4) INSERT (u1)-[@friend{since:2020}]->(u2), (u2)-[@friend{since:2021}]->(u1), (u2)-[@friend{since:2022}]->(u3), (u3)-[@friend{since:2023}]->(u2), (u1)-[@friend{since:2019}]->(u4)
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_dst_only_graph CREATE INDEX friend_dst_since_idx ON EDGE friend(_dst, since)
      """
    Then the execution should be successful
    And index "friend_dst_since_idx" of "vc_dst_only_graph" should be ready to use
    When executing query:
      """
      PROFILE USE vc_dst_only_graph MATCH WALK (u1:user WHERE u1.id = 1)-[e:friend WHERE e.since >= 2020 /*+ INDEX(friend_dst_since_idx) */]-{1,2}(u2:user) RETURN COUNT(DISTINCT u2.id) AS cnt
      """
    And the plan should contain "vcIndex: friend_dst_since_idx"
    Then the result should be, in any order:
      | cnt |
      | 3   |
    When executing query:
      """
      PROFILE USE vc_dst_only_graph MATCH WALK (u1:user WHERE u1.id = 1)-[e:friend WHERE e.since >= 2020 /*+ IGNORE_INDEX(friend_dst_since_idx) */]-{1,2}(u2:user) RETURN COUNT(DISTINCT u2.id) AS cnt
      """
    And the plan should not contain "index: friend_dst_since_idx"
    Then the result should be, in any order:
      | cnt |
      | 3   |
    When executing query:
      """
      USE vc_dst_only_graph DROP INDEX friend_dst_since_idx
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH IF EXISTS vc_dst_only_graph
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE IF EXISTS vc_dst_only_graph_type
      """
    Then the execution should be successful

  @testmark
  Scenario: VC dst index remains correct after edge schema expands beyond the index
    # This is an isolated regression for incoming VC index scans that need to fetch
    # the base edge after the edge schema has more properties than the VC index covers.
    When executing query:
      """
      DROP GRAPH IF EXISTS vc_dst_multiget_regression_graph
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE IF EXISTS vc_dst_multiget_regression_type
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH TYPE vc_dst_multiget_regression_type AS {
        NODE Person (LABEL Person {id INT64 PRIMARY KEY}),
        EDGE PERSON_KNOWS_PERSON (Person)-[LABEL KNOWS {creationDate LOCAL DATETIME DEFAULT NULL}]->(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH vc_dst_multiget_regression_graph TYPED vc_dst_multiget_regression_type
      """
    Then the execution should be successful
    And graph "vc_dst_multiget_regression_graph" should be ready to use
    When executing query:
      """
      USE vc_dst_multiget_regression_graph INSERT (@Person{id:318}), (@Person{id:102})
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_dst_multiget_regression_graph MATCH (p1:Person WHERE p1.id = 102), (p2:Person WHERE p2.id = 318) INSERT (p1)-[@PERSON_KNOWS_PERSON{creationDate: local_datetime("2012-01-01T00:00:00")}]->(p2)
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_dst_multiget_regression_graph CREATE INDEX vc_dst_knows_creationdate_regression ON EDGE PERSON_KNOWS_PERSON(_dst, creationDate)
      """
    Then the execution should be successful
    And index "vc_dst_knows_creationdate_regression" of "vc_dst_multiget_regression_graph" should be ready to use
    When executing query:
      """
      ALTER GRAPH TYPE vc_dst_multiget_regression_type {ALTER EDGE TYPE PERSON_KNOWS_PERSON ADD PROPERTIES {likeness INT}}
      """
    Then the execution should be successful
    When executing query:
      """
      PROFILE USE vc_dst_multiget_regression_graph MATCH p=trail (v:Person WHERE v.id = 318)<-[e:KNOWS WHERE e.creationDate >= zoned_datetime("2010-01-01T00:00:00 +0000") /*+ ignore_index(vc_dst_knows_creationdate_regression)*/ ]-{1,3}(w:Person WHERE w.id = 102) RETURN length(p),v.id,w.id
      """
    And the plan should not contain "vc_dst_knows_creationdate_regression"
    Then the result should be, in any order:
      | length(p) | v.id | w.id |
      | 1         | 318  | 102  |
    When executing query:
      """
      PROFILE USE vc_dst_multiget_regression_graph MATCH p=trail (v:Person WHERE v.id = 318)<-[e:KNOWS WHERE e.creationDate >= zoned_datetime("2010-01-01T00:00:00 +0000") /*+ index(vc_dst_knows_creationdate_regression)*/ ]-{1,3}(w:Person WHERE w.id = 102) RETURN length(p),v.id,w.id
      """
    And the plan should contain "vc_dst_knows_creationdate_regression"
    Then the result should be, in any order:
      | length(p) | v.id | w.id |
      | 1         | 318  | 102  |
    When executing query:
      """
      PROFILE USE vc_dst_multiget_regression_graph MATCH p = ANY SHORTEST (v:Person where v.id = 318 )<-[e:KNOWS WHERE e.creationDate >= zoned_datetime("2010-01-01T00:00:00 +0000") /*+ ignore_index(vc_dst_knows_creationdate_regression)*/]-+(d:Person where d.id = 102) ORDER BY length(p),v.id,d.id limit 1 RETURN v.id,d.id,length(p)
      """
    And the plan should not contain "vc_dst_knows_creationdate_regression"
    Then the result should be, in any order:
      | v.id | d.id | length(p) |
      | 318  | 102  | 1         |
    When executing query:
      """
      PROFILE USE vc_dst_multiget_regression_graph MATCH p = ANY SHORTEST (v:Person where v.id = 318 )<-[e:KNOWS WHERE e.creationDate >= zoned_datetime("2010-01-01T00:00:00 +0000") /*+ index(vc_dst_knows_creationdate_regression)*/]-+(d:Person where d.id = 102) ORDER BY length(p),v.id,d.id limit 1 RETURN v.id,d.id,length(p)
      """
    And the plan should contain "vc_dst_knows_creationdate_regression"
    Then the result should be, in any order:
      | v.id | d.id | length(p) |
      | 318  | 102  | 1         |
    When executing query:
      """
      DROP GRAPH IF EXISTS vc_dst_multiget_regression_graph
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE IF EXISTS vc_dst_multiget_regression_type
      """
    Then the execution should be successful

  @testmark
  Scenario: VC index ORDER BY LIMIT push-down IndexOrderSatisfiesTopNWithVcRule
    # Part 14 (extracted): Single-hop ORDER BY + VC index LIMIT push-down.
    # IndexOrderSatisfiesTopNWithVcRule matches TopN → HashJoin → EdgesScan[VC index]
    # when the build side is a single-vertex point lookup, and pushes limit budget
    # into the IndexScanMethod for early-stop in storage.
    # (empty)
    # User 1's outgoing friend edges:
    # ->2 (since:2020, weight:10), ->3 (since:2021, weight:8),
    # ->4 (since:2019, weight:9), ->5 (since:NULL, weight:NULL).
    # ============================================
    # Setup
    # ============================================
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS vc_topn_graph_type AS {
        NODE user (LABEL user {id INT64 PRIMARY KEY, name STRING, age INT64}),
        EDGE friend (user)-[LABEL friend {since INT64, weight INT64}]->(user)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH IF EXISTS vc_topn_graph
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH vc_topn_graph TYPED vc_topn_graph_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_topn_graph INSERT (@user{id:1, name:"Alice", age:25}), (@user{id:2, name:"Bob", age:30}), (@user{id:3, name:"Carol", age:28}), (@user{id:4, name:"David", age:35}), (@user{id:5, name:"Eve", age:22})
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_topn_graph MATCH (u1:user WHERE u1.id = 1), (u2:user WHERE u2.id = 2), (u3:user WHERE u3.id = 3), (u4:user WHERE u4.id = 4), (u5:user WHERE u5.id = 5) INSERT (u1)-[@friend{since:2020, weight:10}]->(u2), (u1)-[@friend{since:2021, weight:8}]->(u3), (u1)-[@friend{since:2019, weight:9}]->(u4), (u1)-[@friend{since:NULL, weight:NULL}]->(u5), (u2)-[@friend{since:2018, weight:6}]->(u5), (u4)-[@friend{since:2019, weight:7}]->(u5)
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_topn_graph CREATE INDEX friend_src_since_idx ON EDGE friend(_src, since)
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_topn_graph CREATE INDEX friend_src_weight_idx ON EDGE friend(_src, weight)
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_topn_graph CREATE INDEX friend_dst_since_idx ON EDGE friend(_dst, since)
      """
    Then the execution should be successful
    # ============================================
    # 14a: ORDER BY e.since DESC LIMIT 2
    # VC index (_src, since ASC) is selected due to the e.since predicate.
    # IndexOrderSatisfiesTopNWithVcRule does NOT fire here: the index is ASC but
    # the ORDER BY is DESC, so the sort orders don't match and limit push-down is skipped.
    # Top 2 by since DESC: since:2021 (u2=3), since:2020 (u2=2).
    # ============================================
    When executing query:
      """
      PROFILE USE vc_topn_graph MATCH (u1:user WHERE u1.id = 1)-[e:friend WHERE e.since >= 0]->(u2:user) RETURN u2.id AS to_user, e.since AS since ORDER BY e.since DESC LIMIT 2
      """
    And the plan should contain "index: friend_src_since_idx"
    Then the result should be, in order:
      | to_user | since |
      | 3       | 2021  |
      | 2       | 2020  |
    # ============================================
    # 14b: ORDER BY e.since ASC LIMIT 2
    # Index order (since ASC) matches sort order;
    # IndexOrderSatisfiesTopNWithVcRule pushes limit=2 into the index scan for early-stop.
    # ============================================
    When executing query:
      """
      PROFILE USE vc_topn_graph MATCH (u1:user WHERE u1.id = 1)-[e:friend WHERE e.since >= 0]->(u2:user) RETURN u2.id AS to_user, e.since AS since ORDER BY e.since ASC LIMIT 2
      """
    And the plan should contain "index: friend_src_since_idx"
    Then the result should be, in order:
      | to_user | since |
      | 4       | 2019  |
      | 2       | 2020  |
    # ============================================
    # 14c: ORDER BY e.weight ASC LIMIT 2 without filter
    # No edge filter is present. The optimizer should still rewrite the anchored
    # edge scan to VC index, and because ORDER BY matches (_src, weight ASC),
    # it should choose friend_src_weight_idx directly.
    # ============================================
    When executing query:
      """
      PROFILE USE vc_topn_graph MATCH (u1:user WHERE u1.id = 1)-[e:friend]->(u2:user) RETURN u2.id AS to_user, e.weight AS weight ORDER BY e.weight ASC LIMIT 2
      """
    And the plan should contain "index: friend_src_weight_idx"
    Then the result should be, in order:
      | to_user | weight |
      | 3       | 8      |
      | 4       | 9      |
    # ============================================
    # 14d: ORDER BY e.weight ASC NULLS LAST LIMIT 2 without filter
    # Explicit NULLS LAST still matches the VC index definition, so the push-down remains valid.
    # ============================================
    When executing query:
      """
      PROFILE USE vc_topn_graph MATCH (u1:user WHERE u1.id = 1)-[e:friend]->(u2:user) RETURN u2.id AS to_user, e.weight AS weight ORDER BY e.weight ASC NULLS LAST LIMIT 2
      """
    And the plan should contain "index: friend_src_weight_idx"
    Then the result should be, in order:
      | to_user | weight |
      | 3       | 8      |
      | 4       | 9      |
    # ============================================
    # 14e: ORDER BY e.weight ASC NULLS FIRST LIMIT 2 without filter
    # Null order no longer matches the VC index ordering, so the optimizer must not
    # rewrite the table scan into an ordered VC index scan.
    # ============================================
    When executing query:
      """
      PROFILE USE vc_topn_graph MATCH (u1:user WHERE u1.id = 1)-[e:friend]->(u2:user) RETURN u2.id AS to_user, e.weight AS weight ORDER BY e.weight ASC NULLS FIRST LIMIT 2
      """
    And the plan should not contain "index: friend_src_weight_idx"
    Then the result should be, in order:
      | to_user | weight |
      | 5       | NULL   |
      | 3       | 8      |
    # ============================================
    # 14f: ORDER BY e.weight DESC LIMIT 2 without filter
    # DESC uses NULLS FIRST by default, and the sort direction does not match the
    # ascending VC index ordering, so no VC index order push-down should happen.
    # ============================================
    When executing query:
      """
      PROFILE USE vc_topn_graph MATCH (u1:user WHERE u1.id = 1)-[e:friend]->(u2:user) RETURN u2.id AS to_user, e.weight AS weight ORDER BY e.weight DESC LIMIT 2
      """
    And the plan should not contain "index: friend_src_weight_idx"
    Then the result should be, in order:
      | to_user | weight |
      | 5       | NULL   |
      | 2       | 10     |
    # ============================================
    # 14g: ORDER BY e.weight DESC NULLS LAST LIMIT 2 without filter
    # Explicit NULLS LAST changes the null ordering, but DESC still does not match the
    # VC index direction, so the rule must still be skipped.
    # ============================================
    When executing query:
      """
      PROFILE USE vc_topn_graph MATCH (u1:user WHERE u1.id = 1)-[e:friend]->(u2:user) RETURN u2.id AS to_user, e.weight AS weight ORDER BY e.weight DESC NULLS LAST LIMIT 2
      """
    And the plan should not contain "index: friend_src_weight_idx"
    Then the result should be, in order:
      | to_user | weight |
      | 2       | 10     |
      | 4       | 9      |
    # ============================================
    # 14h: incoming _dst VC TopN push-down with lazy edge property fetch
    # The ordering key e.since is covered by friend_dst_since_idx, but e.weight is not.
    # The optimizer still pushes TopN into the VC index scan, then FetchEdgeProps must
    # refill e.weight from the base edge without losing direction on the edge id.
    # ============================================
    When executing query:
      """
      PROFILE USE vc_topn_graph MATCH (u5:user WHERE u5.id = 5)<-[e:friend WHERE e.since >= 0]-(u:user) RETURN u.id AS from_user, e.weight AS weight ORDER BY e.since ASC LIMIT 2
      """
    And the plan should contain "index: friend_dst_since_idx"
    Then the result should be, in order:
      | from_user | weight |
      | 2         | 6      |
      | 4         | 7      |
    # ============================================
    # Cleanup
    # ============================================
    When executing query:
      """
      USE vc_topn_graph DROP INDEX friend_src_since_idx
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_topn_graph DROP INDEX friend_src_weight_idx
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_topn_graph DROP INDEX friend_dst_since_idx
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH IF EXISTS vc_topn_graph
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE IF EXISTS vc_topn_graph_type
      """
    Then the execution should be successful

  @sf01 @testmark
  Scenario: sf01 KNOWS queries stay correct with both src and dst VC creationDate indexes
    # Regression coverage for undirected/split-direction VC index scans on the sf01 fixture.
    # The first query exercises IndexOrderSatisfiesTopNWithVcRule on an undirected single-hop
    # pattern with ORDER BY + LIMIT. The second query exercises K-HOP / Recursive-style
    # expansion with a bidirectional KNOWS edge filter.
    When executing query:
      """
      USE sf01 CREATE INDEX IF NOT EXISTS vc_src_knows_creationdate ON EDGE PERSON_KNOWS_PERSON(_src, creationDate)
      """
    Then the execution should be successful
    When executing query:
      """
      USE sf01 CREATE INDEX IF NOT EXISTS vc_dst_knows_creationdate ON EDGE PERSON_KNOWS_PERSON(_dst, creationDate)
      """
    Then the execution should be successful
    And index "vc_src_knows_creationdate" of "sf01" should be ready to use
    And index "vc_dst_knows_creationdate" of "sf01" should be ready to use
    When executing query:
      """
      PROFILE USE sf01 MATCH (v@Person{id:318})-[e:KNOWS /*+ index(vc_src_knows_creationdate,vc_dst_knows_creationdate) */]-(d) ORDER BY e.creationDate limit 1000 RETURN count(distinct d.id)
      """
    And the plan should contain "vc_src_knows_creationdate"
    And the plan should contain "vc_dst_knows_creationdate"
    Then the result should be, in any order:
      | count(distinct d.id) |
      | 45                   |
    When executing query:
      """
      PROFILE USE sf01 MATCH (v@Person{id:318})-[e:KNOWS /*+ ignore_index(vc_src_knows_creationdate,vc_dst_knows_creationdate) */]-(d) ORDER BY e.creationDate limit 1000 RETURN count(distinct d.id)
      """
    And the plan should not contain "vc_src_knows_creationdate"
    And the plan should not contain "vc_dst_knows_creationdate"
    Then the result should be, in any order:
      | count(distinct d.id) |
      | 45                   |
    When executing query:
      """
      PROFILE USE sf01 MATCH (v@Person{id:318})<-[e:KNOWS where e.creationDate >= zoned_datetime("2001-09-01T10:10:10+0080") /*+ index(vc_src_knows_creationdate,vc_dst_knows_creationdate) */ ]->{1,3}(d) RETURN count(d)
      """
    And the plan should contain "vc_src_knows_creationdate"
    And the plan should contain "vc_dst_knows_creationdate"
    Then the result should be, in any order:
      | count(d) |
      | 93735    |
    When executing query:
      """
      PROFILE USE sf01 MATCH (v@Person{id:318})<-[e:KNOWS where e.creationDate >= zoned_datetime("2001-09-01T10:10:10+0080") /*+ ignore_index(vc_src_knows_creationdate,vc_dst_knows_creationdate) */ ]->{1,3}(d) RETURN count(d)
      """
    And the plan should not contain "vc_src_knows_creationdate"
    And the plan should not contain "vc_dst_knows_creationdate"
    Then the result should be, in any order:
      | count(d) |
      | 93735    |
    When executing query:
      """
      USE sf01 DROP INDEX vc_src_knows_creationdate
      """
    Then the execution should be successful
    When executing query:
      """
      USE sf01 DROP INDEX vc_dst_knows_creationdate
      """
    Then the execution should be successful
