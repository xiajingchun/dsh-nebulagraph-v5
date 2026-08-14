# Copyright (c) 2026 vesoft inc. All rights reserved.
Feature: Vertex-Centric Index

  @testmark
  Scenario: Vertex-centric index test
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS vc_index_graph_type AS {
        NODE user (LABEL user {id INT64 PRIMARY KEY, name STRING, age INT64}),
        NODE movie (LABEL movie {id INT64 PRIMARY KEY, title STRING, year INT64}),
        EDGE watch (user)-[LABEL watch {rate INT64, ts INT64}]->(movie),
        EDGE friend (user)-[LABEL friend {since INT64, weight INT64}]->(user),
        EDGE knows (user)~[LABEL knows {strength INT64}]~(user)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH IF EXISTS vc_index_graph
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH vc_index_graph TYPED vc_index_graph_type
      """
    Then the execution should be successful
    # ============================================
    # Part 1: Create vertex-centric index with correct syntax
    # ============================================
    # Create _src index (single property)
    When executing query:
      """
      USE vc_index_graph CREATE INDEX watch_src_rate_idx ON EDGE watch(_src, rate)
      """
    Then the execution should be successful
    # Create _dst index (single property)
    When executing query:
      """
      USE vc_index_graph CREATE INDEX watch_dst_rate_idx ON EDGE watch(_dst, rate)
      """
    Then the execution should be successful
    # Create _src index (composite properties)
    When executing query:
      """
      USE vc_index_graph CREATE INDEX watch_src_rate_time_idx ON EDGE watch(_src, rate, ts)
      """
    Then the execution should be successful
    # Create _dst index (composite properties)
    When executing query:
      """
      USE vc_index_graph CREATE INDEX watch_dst_rate_time_idx ON EDGE watch(_dst, rate DESC, ts ASC)
      """
    Then the execution should be successful
    # Create _src index (another edge type)
    When executing query:
      """
      USE vc_index_graph CREATE INDEX friend_src_since_idx ON EDGE friend(_src, since)
      """
    Then the execution should be successful
    # Verify indexes are created
    When executing query:
      """
      USE vc_index_graph SHOW INDEXES
      """
    Then the result should be, in any order:
      | name                      | state   | index_type | schema            | graph_name       | entity_type | element_type | properties                             |
      | "watch_src_rate_idx"      | "Valid" | "Normal"   | "/default_schema" | "vc_index_graph" | "Edge"      | "watch"      | LIST ["_src ASC","rate ASC"]           |
      | "watch_dst_rate_idx"      | "Valid" | "Normal"   | "/default_schema" | "vc_index_graph" | "Edge"      | "watch"      | LIST ["_dst ASC","rate ASC"]           |
      | "watch_src_rate_time_idx" | "Valid" | "Normal"   | "/default_schema" | "vc_index_graph" | "Edge"      | "watch"      | LIST ["_src ASC","rate ASC","ts ASC"]  |
      | "watch_dst_rate_time_idx" | "Valid" | "Normal"   | "/default_schema" | "vc_index_graph" | "Edge"      | "watch"      | LIST ["_dst ASC","rate DESC","ts ASC"] |
      | "friend_src_since_idx"    | "Valid" | "Normal"   | "/default_schema" | "vc_index_graph" | "Edge"      | "friend"     | LIST ["_src ASC","since ASC"]          |
    # Cleanup indexes for next part
    And drop the index "friend_src_since_idx" of "vc_index_graph"
    And drop the index "watch_dst_rate_time_idx" of "vc_index_graph"
    And drop the index "watch_src_rate_time_idx" of "vc_index_graph"
    And drop the index "watch_dst_rate_idx" of "vc_index_graph"
    And drop the index "watch_src_rate_idx" of "vc_index_graph"
    # ============================================
    # Part 2: Create vertex-centric index with invalid syntax
    # ============================================
    # Invalid: _src not at the first position
    When executing query:
      """
      USE vc_index_graph CREATE INDEX invalid_idx1 ON EDGE watch(rate, _src)
      """
    Then an Error should be raised: "[NC304]: Illegal DDL: System fields (_src, _dst) can only appear as the first indexed property"
    # Invalid: _dst not at the first position
    When executing query:
      """
      USE vc_index_graph CREATE INDEX invalid_idx2 ON EDGE watch(rate, _dst)
      """
    Then an Error should be raised: "[NC304]: Illegal DDL: System fields (_src, _dst) can only appear as the first indexed property"
    # Invalid: both _src and _dst are used
    When executing query:
      """
      USE vc_index_graph CREATE INDEX invalid_idx3 ON EDGE watch(_src, _dst, rate)
      """
    Then an Error should be raised: "[NC304]: Illegal DDL: System fields (_src, _dst) can only appear as the first indexed property"
    # Invalid: VC index cannot be created on undirected edge
    When executing query:
      """
      USE vc_index_graph CREATE INDEX invalid_idx4 ON EDGE knows(_src, strength)
      """
    Then an Error should be raised: "[NC304]: Illegal DDL: Vertex-Centric Index (with _src/_dst) is not supported for undirected edge type"
    # ============================================
    # Part 3: Query data using vertex-centric index with _src
    # ============================================
    # Create _src index
    When executing query:
      """
      USE vc_index_graph CREATE INDEX watch_src_rate_idx ON EDGE watch(_src, rate)
      """
    Then the execution should be successful
    # Insert test data
    When executing query:
      """
      USE vc_index_graph INSERT (@user{id:1, name:"Alice", age:25}), (@user{id:2, name:"Bob", age:30}), (@user{id:3, name:"Carol", age:28})
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_index_graph INSERT (@movie{id:101, title:"Movie A", year:2020}), (@movie{id:102, title:"Movie B", year:2021}), (@movie{id:103, title:"Movie C", year:2022})
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_index_graph MATCH (u1:user WHERE u1.id = 1), (u2:user WHERE u2.id = 2), (u3:user WHERE u3.id = 3), (m1:movie WHERE m1.id = 101), (m2:movie WHERE m2.id = 102), (m3:movie WHERE m3.id = 103) INSERT (u1)-[@watch{rate:85, ts:1000}]->(m1), (u1)-[@watch{rate:90, ts:2000}]->(m2), (u2)-[@watch{rate:75, ts:3000}]->(m1), (u2)-[@watch{rate:95, ts:4000}]->(m3), (u3)-[@watch{rate:88, ts:5000}]->(m2)
      """
    Then the execution should be successful
    # Use hint to force _src vc-index using outgoing edge pattern
    # _src index is outgoing edge index, use edge pattern: (u:user)-[e:watch]->(m:movie) or (u:user)-[e:watch]-(m:movie)
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user{id:1})-[e:watch /*+ INDEX(watch_src_rate_idx) */]->(v2:movie) WHERE e.rate > 0 ORDER BY e.rate DESC RETURN u.id AS user_id, v2.id AS movie_id, e.rate AS rate
      """
    Then the result should be, in order:
      | user_id | movie_id | rate |
      | 1       | 102      | 90   |
      | 1       | 101      | 85   |
    And the plan should contain "index: watch_src_rate_idx"
    # bidirectional edge pattern
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user{id:1})-[e:watch /*+ INDEX(watch_src_rate_idx) */]-(m:movie) WHERE e.rate > 0 ORDER BY e.rate ASC RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate
      """
    Then the result should be, in order:
      | user_id | movie_id | rate |
      | 1       | 101      | 85   |
      | 1       | 102      | 90   |
    And the plan should contain "index: watch_src_rate_idx"
    # Anchor vertex ID in WHERE clause (u.id = 2) rather than inline node constraint.
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user)-[e:watch /*+ INDEX(watch_src_rate_idx) */]->(m:movie) WHERE u.id = 2 AND e.rate > 70 RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate ORDER BY e.rate DESC
      """
    Then the result should be, in order:
      | user_id | movie_id | rate |
      | 2       | 103      | 95   |
      | 2       | 101      | 75   |
    And the plan should contain "index: watch_src_rate_idx"
    # Cleanup
    And drop the index "watch_src_rate_idx" of "vc_index_graph"
    # Create _src index again to verify RepairIndex
    When executing query:
      """
      USE vc_index_graph CREATE INDEX watch_src_rate_idx ON EDGE watch(_src, rate)
      """
    Then the execution should be successful
    # Rebuilt index (drop + re-create above) returns correct query results.
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user)-[e:watch /*+ INDEX(watch_src_rate_idx) */]->(m:movie) WHERE u.id = 1 AND e.rate > 0 RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate ORDER BY e.rate DESC
      """
    Then the result should be, in order:
      | user_id | movie_id | rate |
      | 1       | 102      | 90   |
      | 1       | 101      | 85   |
    And the plan should contain "index: watch_src_rate_idx"
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user{id:2})-[e:watch /*+ INDEX(watch_src_rate_idx) */]-(m:movie) WHERE e.rate > 70 RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate ORDER BY e.rate DESC
      """
    Then the result should be, in order:
      | user_id | movie_id | rate |
      | 2       | 103      | 95   |
      | 2       | 101      | 75   |
    And the plan should contain "index: watch_src_rate_idx"
    # Cleanup
    And drop the index "watch_src_rate_idx" of "vc_index_graph"
    # ============================================
    # Part 4: Query data using vertex-centric index with _dst
    # ============================================
    # Create _dst index
    When executing query:
      """
      USE vc_index_graph CREATE INDEX watch_dst_rate_idx ON EDGE watch(_dst, rate)
      """
    Then the execution should be successful
    # Insert more data
    When executing query:
      """
      USE vc_index_graph INSERT (@user{id:4, name:"David", age:35}), (@user{id:5, name:"Eve", age:27}), (@user{id:6, name:"Frank", age:32})
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_index_graph MATCH (u1:user WHERE u1.id = 1), (u2:user WHERE u2.id = 2), (u3:user WHERE u3.id = 3), (u4:user WHERE u4.id = 4), (u5:user WHERE u5.id = 5), (u6:user WHERE u6.id = 6), (m1:movie WHERE m1.id = 101), (m2:movie WHERE m2.id = 102), (m3:movie WHERE m3.id = 103) INSERT (u3)-[@watch{rate:92, ts:6000}]->(m1), (u4)-[@watch{rate:78, ts:7000}]->(m1), (u5)-[@watch{rate:88, ts:8000}]->(m1), (u2)-[@watch{rate:82, ts:9000}]->(m2), (u4)-[@watch{rate:85, ts:10000}]->(m2), (u6)-[@watch{rate:91, ts:11000}]->(m2), (u1)-[@watch{rate:88, ts:12000}]->(m3), (u3)-[@watch{rate:92, ts:13000}]->(m3), (u5)-[@watch{rate:87, ts:14000}]->(m3)
      """
    Then the execution should be successful
    # Use hint to force _dst index using incoming edge pattern
    # _dst index is incoming edge index, use pattern: (m:movie)-[e:watch]-(u:user) or (m:movie)<-[e:watch]-(u:user)
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (m:movie{id:101})<-[e:watch /*+ INDEX(watch_dst_rate_idx) */]-(u:user) WHERE e.rate > 0 RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate ORDER BY e.rate DESC
      """
    Then the result should be, in order:
      | user_id | movie_id | rate |
      | 3       | 101      | 92   |
      | 5       | 101      | 88   |
      | 1       | 101      | 85   |
      | 4       | 101      | 78   |
      | 2       | 101      | 75   |
    And the plan should contain "index: watch_dst_rate_idx"
    # bidirectional edge pattern
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (m:movie{id:102})-[e:watch /*+ INDEX(watch_dst_rate_idx) */]-(u:user) WHERE e.rate >= 80 RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate ORDER BY u.id ASC
      """
    Then the result should be, in order:
      | user_id | movie_id | rate |
      | 1       | 102      | 90   |
      | 2       | 102      | 82   |
      | 3       | 102      | 88   |
      | 4       | 102      | 85   |
      | 6       | 102      | 91   |
    And the plan should contain "index: watch_dst_rate_idx"
    # Destination anchor vertex ID in WHERE clause (m.id = 103) rather than inline node constraint.
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (m:movie)<-[e:watch /*+ INDEX(watch_dst_rate_idx) */]-(u:user) WHERE m.id = 103 AND e.rate > 0 RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate ORDER BY e.rate DESC
      """
    Then the result should be, in order:
      | user_id | movie_id | rate |
      | 2       | 103      | 95   |
      | 3       | 103      | 92   |
      | 1       | 103      | 88   |
      | 5       | 103      | 87   |
    And the plan should contain "index: watch_dst_rate_idx"
    # Cleanup
    And drop the index "watch_dst_rate_idx" of "vc_index_graph"
    # Create _dst index again to verify RepairIndex
    When executing query:
      """
      USE vc_index_graph CREATE INDEX watch_dst_rate_idx ON EDGE watch(_dst, rate)
      """
    Then the execution should be successful
    # Use hint to force _dst index
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (m:movie)-[e:watch /*+ INDEX(watch_dst_rate_idx) */]-(u:user) WHERE m.id = 101 AND e.rate > 0 RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate ORDER BY e.rate DESC
      """
    Then the result should be, in order:
      | user_id | movie_id | rate |
      | 3       | 101      | 92   |
      | 5       | 101      | 88   |
      | 1       | 101      | 85   |
      | 4       | 101      | 78   |
      | 2       | 101      | 75   |
    And the plan should contain "index: watch_dst_rate_idx"
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (m:movie)<-[e:watch /*+ INDEX(watch_dst_rate_idx) */]-(u:user) WHERE m.id = 103 AND e.rate > 0 RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate ORDER BY e.rate DESC
      """
    Then the result should be, in order:
      | user_id | movie_id | rate |
      | 2       | 103      | 95   |
      | 3       | 103      | 92   |
      | 1       | 103      | 88   |
      | 5       | 103      | 87   |
    And the plan should contain "index: watch_dst_rate_idx"
    # Cleanup
    And drop the index "watch_dst_rate_idx" of "vc_index_graph"
    # ============================================
    # Part 5: Query data using composite vertex-centric index
    # ============================================
    # Create composite _src index
    When executing query:
      """
      USE vc_index_graph CREATE INDEX watch_src_rate_time_idx ON EDGE watch(_src, rate, ts)
      """
    Then the execution should be successful
    # Clean up existing watch edges before inserting new ones
    When executing query:
      """
      USE vc_index_graph MATCH (u:user)-[e:watch]->(m:movie) WHERE u.id IN [1, 2, 3] OR m.id IN [101, 102, 103] DELETE e
      """
    Then the execution should be successful
    # Insert edge data for composite index testing
    When executing query:
      """
      USE vc_index_graph MATCH (u1:user WHERE u1.id = 1), (u2:user WHERE u2.id = 2), (m1:movie WHERE m1.id = 101), (m2:movie WHERE m2.id = 102), (m3:movie WHERE m3.id = 103) INSERT (u1)-[@watch{rate:85, ts:1000}]->(m1), (u1)-[@watch{rate:85, ts:2000}]->(m2), (u1)-[@watch{rate:90, ts:3000}]->(m3), (u2)-[@watch{rate:75, ts:4000}]->(m1)
      """
    Then the execution should be successful
    # Query with composite index (prefix match: _src + rate)
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user)-[e:watch /*+ INDEX(watch_src_rate_time_idx) */]->(m:movie) WHERE u.id = 1 AND e.rate = 85 RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate, e.ts AS ts ORDER BY e.ts ASC
      """
    Then the result should be, in order:
      | user_id | movie_id | rate | ts   |
      | 1       | 101      | 85   | 1000 |
      | 1       | 102      | 85   | 2000 |
    And the plan should contain "index: watch_src_rate_time_idx"
    # Query with composite index (full match: _src + rate + ts)
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user)-[e:watch /*+ INDEX(watch_src_rate_time_idx) */]-(m:movie) WHERE u.id = 1 AND e.rate >= 85 AND e.ts > 1500 RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate, e.ts AS ts ORDER BY e.ts ASC
      """
    Then the result should be, in order:
      | user_id | movie_id | rate | ts   |
      | 1       | 102      | 85   | 2000 |
      | 1       | 103      | 90   | 3000 |
    And the plan should contain "index: watch_src_rate_time_idx"
    # Query with composite index using only _src + ts.
    # The middle column rate is unconstrained, so the filter is not a usable prefix match for
    # watch_src_rate_time_idx even with an explicit hint.
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user)-[e:watch /*+ INDEX(watch_src_rate_time_idx) */]->(m:movie) WHERE u.id = 1 AND e.ts > 1500 RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate, e.ts AS ts ORDER BY e.ts ASC
      """
    Then the result should be, in order:
      | user_id | movie_id | rate | ts   |
      | 1       | 102      | 85   | 2000 |
      | 1       | 103      | 90   | 3000 |
    And the plan should not contain "index: watch_src_rate_time_idx"
    # Cleanup
    And drop the index "watch_src_rate_time_idx" of "vc_index_graph"
    # Create composite index again to verify RepairIndex
    When executing query:
      """
      USE vc_index_graph CREATE INDEX watch_src_rate_time_idx ON EDGE watch(_src, rate, ts)
      """
    Then the execution should be successful
    # Create composite incoming edge index to verify RepairIndex
    # Verify non-reserve and reserve index both exist
    When executing query:
      """
      USE vc_index_graph CREATE INDEX watch_dst_rate_time_idx ON EDGE watch(_dst, rate, ts)
      """
    Then the execution should be successful
    # Query with composite index (prefix match: _src + rate)
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user{id:1})-[e:watch /*+ INDEX(watch_src_rate_time_idx) */]-(m:movie) WHERE e.rate = 85 RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate, e.ts AS ts ORDER BY e.ts ASC
      """
    Then the result should be, in order:
      | user_id | movie_id | rate | ts   |
      | 1       | 101      | 85   | 1000 |
      | 1       | 102      | 85   | 2000 |
    And the plan should contain "index: watch_src_rate_time_idx"
    # Query with composite index (prefix match: _dst + rate)
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (m:movie{id:101})-[e:watch /*+ INDEX(watch_dst_rate_time_idx) */]-(u:user) WHERE e.rate = 85 RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate, e.ts AS ts ORDER BY e.ts ASC
      """
    Then the result should be, in order:
      | user_id | movie_id | rate | ts   |
      | 1       | 101      | 85   | 1000 |
    And the plan should contain "index: watch_dst_rate_time_idx"
    # Cleanup
    And drop the index "watch_src_rate_time_idx" of "vc_index_graph"
    And drop the index "watch_dst_rate_time_idx" of "vc_index_graph"
    # ============================================
    # Part 6: Query data using vertex-centric index on self-loop edge (_src)
    # ============================================
    # Clean up existing data before inserting
    When executing query:
      """
      USE vc_index_graph MATCH (u:user) WHERE u.id IN [1, 2, 3, 4] DETACH DELETE u
      """
    Then the execution should be successful
    # Create _src index on self-loop edge
    When executing query:
      """
      USE vc_index_graph CREATE INDEX friend_src_since_idx ON EDGE friend(_src, since)
      """
    Then the execution should be successful
    # Insert data
    When executing query:
      """
      USE vc_index_graph INSERT (@user{id:1, name:"Alice", age:25}), (@user{id:2, name:"Bob", age:30}), (@user{id:3, name:"Carol", age:28}), (@user{id:4, name:"David", age:35})
      """
    Then the execution should be successful
    # Insert friend edge data (user -> user self-loop)
    When executing query:
      """
      USE vc_index_graph MATCH (u1:user WHERE u1.id = 1), (u2:user WHERE u2.id = 2), (u3:user WHERE u3.id = 3), (u4:user WHERE u4.id = 4) INSERT (u1)-[@friend{since:2020, weight:10}]->(u2), (u1)-[@friend{since:2021, weight:8}]->(u3), (u1)-[@friend{since:2019, weight:9}]->(u4), (u2)-[@friend{since:2022, weight:7}]->(u1), (u2)-[@friend{since:2023, weight:6}]->(u3), (u3)-[@friend{since:2024, weight:5}]->(u1)
      """
    Then the execution should be successful
    # bidirectional edge pattern
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u1:user)-[e:friend /*+ INDEX(friend_src_since_idx) */]-(u2:user) WHERE u1.id = 1 AND e.since > 2018 RETURN u1.id AS from_user, u2.id AS to_user, e.since AS since ORDER BY e.since ASC
      """
    Then the result should be, in order:
      | from_user | to_user | since |
      | 1         | 4       | 2019  |
      | 1         | 2       | 2020  |
      | 1         | 3       | 2021  |
    And the plan should contain "index: friend_src_since_idx"
    # outgoing edge pattern
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u1:user)-[e:friend /*+ INDEX(friend_src_since_idx) */]->(u2:user) WHERE u1.id = 2 AND e.since >= 2022 RETURN u1.id AS from_user, u2.id AS to_user, e.since AS since ORDER BY e.since DESC
      """
    Then the result should be, in order:
      | from_user | to_user | since |
      | 2         | 3       | 2023  |
      | 2         | 1       | 2022  |
    And the plan should contain "index: friend_src_since_idx"
    # Cleanup
    And drop the index "friend_src_since_idx" of "vc_index_graph"
    # ============================================
    # Part 7: Query data using vertex-centric index on self-loop edge (_dst)
    # ============================================
    # Create _dst index on self-loop edge
    When executing query:
      """
      USE vc_index_graph CREATE INDEX friend_dst_weight_idx ON EDGE friend(_dst, weight)
      """
    Then the execution should be successful
    # Insert data
    When executing query:
      """
      USE vc_index_graph MATCH (u1:user WHERE u1.id = 1), (u2:user WHERE u2.id = 2), (u3:user WHERE u3.id = 3), (u4:user WHERE u4.id = 4) INSERT (u4)-[@friend{since:2021, weight:9}]->(u1), (u4)-[@friend{since:2022, weight:8}]->(u2), (u3)-[@friend{since:2023, weight:6}]->(u2)
      """
    Then the execution should be successful
    # bidirectional edge pattern
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u2:user)-[e:friend /*+ INDEX(friend_dst_weight_idx) */]-(u1:user) WHERE u2.id = 1 AND e.weight > 0 RETURN u1.id AS from_user, u2.id AS to_user, e.weight AS weight ORDER BY e.weight DESC
      """
    Then the result should be, in order:
      | from_user | to_user | weight |
      | 4         | 1       | 9      |
      | 2         | 1       | 7      |
      | 3         | 1       | 5      |
    And the plan should contain "index: friend_dst_weight_idx"
    # incoming edge pattern
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u2:user)<-[e:friend /*+ INDEX(friend_dst_weight_idx) */]-(u1:user) WHERE u2.id = 3 AND e.weight >= 6 RETURN u1.id AS from_user, u2.id AS to_user, e.weight AS weight ORDER BY e.weight ASC
      """
    Then the result should be, in order:
      | from_user | to_user | weight |
      | 2         | 3       | 6      |
      | 1         | 3       | 8      |
    And the plan should contain "index: friend_dst_weight_idx"
    # Cleanup
    And drop the index "friend_dst_weight_idx" of "vc_index_graph"
    # ============================================
    # Part 8: Drop inexistent vertex-centric index
    # ============================================
    # Dropping again should raise error
    When executing query:
      """
      USE vc_index_graph DROP INDEX friend_dst_weight_idx
      """
    Then an Error should be raised: "[NC007]: Catalog index not found: `friend_dst_weight_idx`"
    # ============================================
    # Part 9: Auto-select vertex-centric index without explicit hints
    # ============================================
    # Prepare: create both _src and _dst indexes on watch edge
    When executing query:
      """
      USE vc_index_graph CREATE INDEX watch_src_rate_idx ON EDGE watch(_src, rate)
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_index_graph CREATE INDEX watch_dst_rate_idx ON EDGE watch(_dst, rate)
      """
    Then the execution should be successful
    # Insert fresh data for this part
    When executing query:
      """
      USE vc_index_graph MATCH (u:user)-[e:watch]->(m:movie) DELETE e
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_index_graph MATCH (u1:user WHERE u1.id = 1), (u2:user WHERE u2.id = 2), (u3:user WHERE u3.id = 3), (m1:movie WHERE m1.id = 101), (m2:movie WHERE m2.id = 102), (m3:movie WHERE m3.id = 103) INSERT (u1)-[@watch{rate:85, ts:1000}]->(m1), (u1)-[@watch{rate:90, ts:2000}]->(m2), (u2)-[@watch{rate:75, ts:3000}]->(m1), (u2)-[@watch{rate:95, ts:4000}]->(m3), (u3)-[@watch{rate:88, ts:5000}]->(m2)
      """
    Then the execution should be successful
    # Auto-select _src VC index for outgoing edge pattern (no hint)
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user{id:1})-[e:watch]->(m:movie) WHERE e.rate > 0 ORDER BY e.rate DESC RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate
      """
    Then the result should be, in order:
      | user_id | movie_id | rate |
      | 1       | 102      | 90   |
      | 1       | 101      | 85   |
    And the plan should contain "index: watch_src_rate_idx"
    # Auto-select _src VC index - anchor vertex ID in WHERE clause instead of inline node filter.
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user)-[e:watch]->(m:movie) WHERE u.id = 2 AND e.rate > 70 ORDER BY e.rate DESC RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate
      """
    Then the result should be, in order:
      | user_id | movie_id | rate |
      | 2       | 103      | 95   |
      | 2       | 101      | 75   |
    And the plan should contain "index: watch_src_rate_idx"
    # Auto-select _dst VC index for incoming edge pattern (no hint)
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (m:movie{id:101})<-[e:watch]-(u:user) WHERE e.rate > 0 ORDER BY e.rate DESC RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate
      """
    Then the result should be, in order:
      | user_id | movie_id | rate |
      | 1       | 101      | 85   |
      | 2       | 101      | 75   |
    And the plan should contain "index: watch_dst_rate_idx"
    # Auto-select _dst VC index - anchor vertex ID in WHERE clause, incoming edge pattern.
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (m:movie)<-[e:watch]-(u:user) WHERE m.id = 103 AND e.rate > 0 ORDER BY e.rate DESC RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate
      """
    Then the result should be, in order:
      | user_id | movie_id | rate |
      | 2       | 103      | 95   |
    And the plan should contain "index: watch_dst_rate_idx"
    # ----- Part 9c: VC index beats plain edge-property index -----
    # Create a plain (non-VC) index on watch(rate) alongside watch_src_rate_idx.
    # The planner must prefer the VC index because it adds the _src constraint from the
    # anchor vertex, making it strictly more selective than the plain index.
    When executing query:
      """
      USE vc_index_graph CREATE INDEX watch_rate_only_idx ON EDGE watch(rate)
      """
    Then the execution should be successful
    # Both watch_src_rate_idx (_src,rate) and watch_rate_only_idx (rate) exist.
    # VC index watch_src_rate_idx should be preferred (more selective: _src + rate vs rate only).
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user{id:1})-[e:watch]->(m:movie) WHERE e.rate > 0 ORDER BY e.rate DESC RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate
      """
    Then the result should be, in order:
      | user_id | movie_id | rate |
      | 1       | 102      | 90   |
      | 1       | 101      | 85   |
    And the plan should contain "index: watch_src_rate_idx"
    # Explicit INDEX hint for the regular index: planner must honour the hint and use
    # watch_rate_only_idx despite watch_src_rate_idx (VC) also being available.
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user{id:1})-[e:watch /*+ INDEX(watch_rate_only_idx) */]->(m:movie) WHERE e.rate > 0 ORDER BY e.rate DESC RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate
      """
    Then the result should be, in order:
      | user_id | movie_id | rate |
      | 1       | 102      | 90   |
      | 1       | 101      | 85   |
    And the plan should contain "index: watch_rate_only_idx"
    # IGNORE_INDEX on the VC index only excludes that index. The default priority still prefers
    # TableScan + dynamic filter over an auto-selected plain edge index.
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user{id:1})-[e:watch /*+ IGNORE_INDEX(watch_src_rate_idx) */]->(m:movie) WHERE e.rate > 0 ORDER BY e.rate DESC RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate
      """
    Then the result should be, in order:
      | user_id | movie_id | rate |
      | 1       | 102      | 90   |
      | 1       | 101      | 85   |
    And the plan should not contain "index: watch_src_rate_idx"
    And the plan should not contain "index: watch_rate_only_idx"
    # ----- 9c-d: Hint picks a specific plain index regardless of score -----
    # watch_rate_ts_idx(rate,ts) scores higher than watch_rate_only_idx(rate) for a filter
    # e.rate > 0 AND e.ts = 1000: the two-column index covers both columns tightly (no remaining
    # filter), while the one-column index leaves e.ts=1000 as a remaining predicate.
    When executing query:
      """
      USE vc_index_graph CREATE INDEX watch_rate_ts_idx ON EDGE watch(rate, ts)
      """
    Then the execution should be successful
    # Auto-selection (no hint): VC index watch_src_rate_idx wins over both plain indexes because
    # it adds the _src anchor-vertex constraint at runtime.
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user{id:1})-[e:watch]->(m:movie) WHERE e.rate > 0 AND e.ts = 1000 RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate, e.ts AS ts
      """
    Then the result should be, in order:
      | user_id | movie_id | rate | ts   |
      | 1       | 101      | 85   | 1000 |
    And the plan should contain "index: watch_src_rate_idx"
    # INDEX hint on the higher-scoring plain index: watch_rate_ts_idx covers both columns → used.
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user{id:1})-[e:watch /*+ INDEX(watch_rate_ts_idx) */]->(m:movie) WHERE e.rate > 0 AND e.ts = 1000 RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate, e.ts AS ts
      """
    Then the result should be, in order:
      | user_id | movie_id | rate | ts   |
      | 1       | 101      | 85   | 1000 |
    And the plan should contain "index: watch_rate_ts_idx"
    # INDEX hint on the lower-scoring plain index: watch_rate_only_idx(rate) forced even though
    # watch_rate_ts_idx and watch_src_rate_idx would score higher without the hint.
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user{id:1})-[e:watch /*+ INDEX(watch_rate_only_idx) */]->(m:movie) WHERE e.rate > 0 AND e.ts = 1000 RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate, e.ts AS ts
      """
    Then the result should be, in order:
      | user_id | movie_id | rate | ts   |
      | 1       | 101      | 85   | 1000 |
    And the plan should contain "index: watch_rate_only_idx"
    # Plain IndexScan with a variable-valued residual filter: rate > 0 is extracted as the
    # index constraint for watch_rate_only_idx, while e.ts > cutoff remains a runtime filter.
    # This verifies the non-GetDstBySrc ordinary IndexScan path still returns correct results.
    When executing query:
      """
      PROFILE USE vc_index_graph FOR cutoff IN [1500] MATCH (u:user{id:1})-[e:watch /*+ INDEX(watch_rate_only_idx) */]->(m:movie) WHERE e.rate > 0 AND e.ts > cutoff RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate, e.ts AS ts ORDER BY movie_id ASC
      """
    Then the result should be, in order:
      | user_id | movie_id | rate | ts   |
      | 1       | 102      | 90   | 2000 |
    And the plan should contain "index: watch_rate_only_idx"
    And the plan should not contain "index: watch_src_rate_idx"
    # IGNORE_INDEX only excludes the listed indexes. With watch_src_rate_idx and watch_rate_ts_idx
    # ruled out, the optimizer should still prefer TableScan + dynamic filter over the remaining
    # plain watch_rate_only_idx.
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user{id:1})-[e:watch /*+ IGNORE_INDEX(watch_rate_ts_idx, watch_src_rate_idx) */]->(m:movie) WHERE e.rate > 0 AND e.ts = 1000 RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate, e.ts AS ts
      """
    Then the result should be, in order:
      | user_id | movie_id | rate | ts   |
      | 1       | 101      | 85   | 1000 |
    And the plan should not contain "index: watch_src_rate_idx"
    And the plan should not contain "index: watch_rate_ts_idx"
    And the plan should not contain "index: watch_rate_only_idx"
    When executing query:
      """
      USE vc_index_graph DROP INDEX watch_rate_ts_idx
      """
    Then the execution should be successful
    # ----- 9c-e: Hint picks a specific VC index regardless of score -----
    # watch_src_rate_ts_idx(_src,rate,ts) scores higher than watch_src_rate_idx(_src,rate) for a
    # filter with EQUALITY on both rate and ts: the three-column VC index is tight (covers all
    # three predicates via index spans, no remaining filter), while the two-column one leaves
    # e.ts = 1000 as a remaining predicate after the correlated _src + rate eq spans.
    When executing query:
      """
      USE vc_index_graph CREATE INDEX watch_src_rate_ts_idx ON EDGE watch(_src, rate, ts)
      """
    Then the execution should be successful
    # Auto-selection: watch_src_rate_ts_idx covers _src+rate+ts tightly → higher score → preferred.
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user{id:1})-[e:watch]->(m:movie) WHERE e.rate = 85 AND e.ts = 1000 RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate, e.ts AS ts
      """
    Then the result should be, in order:
      | user_id | movie_id | rate | ts   |
      | 1       | 101      | 85   | 1000 |
    And the plan should contain "index: watch_src_rate_ts_idx"
    # INDEX hint on the lower-scoring VC index: watch_src_rate_idx(_src,rate) forced even though
    # watch_src_rate_ts_idx would score higher in auto-selection.
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user{id:1})-[e:watch /*+ INDEX(watch_src_rate_idx) */]->(m:movie) WHERE e.rate = 85 AND e.ts = 1000 RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate, e.ts AS ts
      """
    Then the result should be, in order:
      | user_id | movie_id | rate | ts   |
      | 1       | 101      | 85   | 1000 |
    And the plan should contain "index: watch_src_rate_idx"
    # IGNORE_INDEX on the higher-scoring VC index: falls back to watch_src_rate_idx.
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user{id:1})-[e:watch /*+ IGNORE_INDEX(watch_src_rate_ts_idx) */]->(m:movie) WHERE e.rate = 85 AND e.ts = 1000 RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate, e.ts AS ts
      """
    Then the result should be, in order:
      | user_id | movie_id | rate | ts   |
      | 1       | 101      | 85   | 1000 |
    And the plan should contain "index: watch_src_rate_idx"
    When executing query:
      """
      USE vc_index_graph DROP INDEX watch_src_rate_ts_idx
      """
    Then the execution should be successful
    # Cleanup 9c
    When executing query:
      """
      USE vc_index_graph DROP INDEX watch_rate_only_idx
      """
    Then the execution should be successful
    # Part 10: Multi-hop queries; watch_src_rate_idx + watch_dst_rate_idx remain from Part 9
    # ----- 10a: friend -> watch (two different edge types) -----
    # friend_src_since_idx is new; watch_src_rate_idx already exists from Part 9
    When executing query:
      """
      USE vc_index_graph CREATE INDEX friend_src_since_idx ON EDGE friend(_src, since)
      """
    Then the execution should be successful
    # 2-hop outgoing pattern: (u1)-[e1:friend]->(u2)-[e2:watch]->(m)
    # e1 anchored by u1.id  → friend_src_since_idx auto-selected for hop 1
    # e2 anchored by u2.id (intermediate) → watch_src_rate_idx auto-selected for hop 2
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u1:user{id:1})-[e1:friend]->(u2:user)-[e2:watch]->(m:movie) WHERE e1.since > 2018 AND e2.rate > 70 ORDER BY u2.id ASC, m.id ASC RETURN u2.id AS friend_id, m.id AS movie_id, e1.since AS since, e2.rate AS rate
      """
    Then the result should be, in order:
      | friend_id | movie_id | since | rate |
      | 2         | 101      | 2020  | 75   |
      | 2         | 103      | 2020  | 95   |
      | 3         | 102      | 2021  | 88   |
    And the plan should contain "index: friend_src_since_idx"
    And the plan should contain "index: watch_src_rate_idx"
    And the plan should contain "IndexScan: {friend: {since}}"
    And the plan should contain "IndexScan: {watch: {rate}}"
    # Cleanup 10a (watch_src_rate_idx stays alive for 10b)
    When executing query:
      """
      USE vc_index_graph DROP INDEX friend_src_since_idx
      """
    Then the execution should be successful
    # ----- 10b: watch -> <-watch (diamond: same edge type, opposite directions) -----
    # watch_src_rate_idx and watch_dst_rate_idx both exist from Part 9; no creation needed
    # Diamond pattern: (u)-[e1:watch]->(m)<-[e2:watch]-(u2)
    # e1 anchored by u.id             → watch_src_rate_idx auto-selected for hop 1
    # e2 anchored by m.id (intermediate) → watch_dst_rate_idx auto-selected for hop 2
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user{id:1})-[e1:watch]->(m:movie)<-[e2:watch]-(u2:user) WHERE e1.rate > 0 AND e2.rate > 0 AND u.id <> u2.id ORDER BY m.id ASC, u2.id ASC RETURN m.id AS movie_id, u2.id AS co_watcher_id, e1.rate AS u1_rate, e2.rate AS u2_rate
      """
    Then the result should be, in order:
      | movie_id | co_watcher_id | u1_rate | u2_rate |
      | 101      | 2             | 85      | 75      |
      | 102      | 3             | 90      | 88      |
    And the plan should contain "index: watch_src_rate_idx"
    And the plan should contain "index: watch_dst_rate_idx"
    And the plan should contain "IndexScan: {watch: {rate}}"
    # Cleanup 10b
    When executing query:
      """
      USE vc_index_graph DROP INDEX watch_src_rate_idx
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_index_graph DROP INDEX watch_dst_rate_idx
      """
    Then the execution should be successful
    # ============================================
    # Part 11: Quantified-path {N,M} queries — VC index auto-selection
    # VC index auto-selection requires at least one edge property predicate on a
    # non-leading column.  Without an edge filter the index would only use _src,
    # providing no benefit over the edge-table prefix scan: the optimizer falls back
    # to TableScan + DynamicFilter prefix pushdown.
    # With an edge property filter (e.g. e.since > 2020) the VC index is auto-selected
    # and filters each hop via the index, providing correct results.
    # ============================================
    # ----- 11 pre-check: verify {2,2} works with table scan (no VC index) -----
    When executing query:
      """
      USE vc_index_graph MATCH WALK (u1:user{id:1})-[:friend]->{2,2}(u2:user) RETURN DISTINCT u2.id AS to_user ORDER BY to_user ASC
      """
    Then the result should be, in order:
      | to_user |
      | 1       |
      | 2       |
      | 3       |
    # friend_src_since_idx was dropped at Part 10a cleanup; recreate it for this part.
    # CREATE INDEX auto-populates from existing data.
    When executing query:
      """
      USE vc_index_graph CREATE INDEX friend_src_since_idx ON EDGE friend(_src, since)
      """
    Then the execution should be successful
    # ----- 11a: {1,1} — no edge filter → VC index NOT selected -----
    # 1-hop destinations of u1: {u2(2), u3(3), u4(4)}
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH WALK (u1:user{id:1})-[:friend]->{1,1}(u2:user) RETURN DISTINCT u2.id AS to_user ORDER BY to_user ASC
      """
    Then the result should be, in order:
      | to_user |
      | 2       |
      | 3       |
      | 4       |
    And the plan should not contain "index: friend_src_since_idx"
    # ----- 11b: {2,2} (exactly 2 hops) — no edge filter → VC index NOT selected -----
    # The Recursive operator:
    # - iter 1  frontier={1}       → edge-table prefix scan from node 1   → {2,3,4}
    # - iter 2  frontier={2,3,4}   → edge-table prefix scan from 2,3,4    → {1,3,1,2,1,2}
    # DISTINCT 2-hop destinations of u1: {1,2,3}
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH WALK (u1:user{id:1})-[:friend]->{2,2}(u2:user) RETURN DISTINCT u2.id AS to_user ORDER BY to_user ASC
      """
    Then the result should be, in order:
      | to_user |
      | 1       |
      | 2       |
      | 3       |
    And the plan should not contain "index: friend_src_since_idx"
    # ----- 11c: {1,2} (1 or 2 hops) — no edge filter → VC index NOT selected -----
    # 1-hop destinations of u1: {2,3,4}; 2-hop: {1,2,3}; union = {1,2,3,4}
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH WALK (u1:user{id:1})-[:friend]->{1,2}(u2:user) RETURN DISTINCT u2.id AS to_user ORDER BY to_user ASC
      """
    Then the result should be, in order:
      | to_user |
      | 1       |
      | 2       |
      | 3       |
      | 4       |
    And the plan should not contain "index: friend_src_since_idx"
    # ----- 11d/11e/11f: WITH edge property filter → VC index IS auto-selected -----
    # With e.since > 2020, only edges with since in {2021,2022,2023,2024} qualify.
    # friend edges with since > 2020 (from Parts 6 & 7):
    # - u1→u3(2021), u2→u1(2022), u2→u3(2023), u3→u1(2024), u3→u2(2023),
    # - u4→u1(2021), u4→u2(2022)
    # NOT included: u1→u2(2020 = not >), u1→u4(2019)
    # ----- 11d: {1,1} with e.since > 2020 → VC index selected -----
    # From u1 with since > 2020: only u1→u3(2021). Result: {3}
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH WALK (u1:user{id:1})-[e:friend WHERE e.since > 2020]->{1,1}(u2:user) RETURN DISTINCT u2.id AS to_user ORDER BY to_user ASC
      """
    And the plan should contain "vcIndex: friend_src_since_idx"
    Then the result should be, in order:
      | to_user |
      | 3       |
    # ----- 11e: {2,2} with e.since > 2020 → VC index selected -----
    # iter 1  frontier={1}  → VC index: since>2020 from 1 → {u3(2021)}
    # iter 2  frontier={3}  → VC index: since>2020 from 3 → {u1(2024), u2(2023)}
    # DISTINCT: {1,2}
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH WALK (u1:user{id:1})-[e:friend WHERE e.since > 2020]->{2,2}(u2:user) RETURN DISTINCT u2.id AS to_user ORDER BY to_user ASC
      """
    And the plan should contain "vcIndex: friend_src_since_idx"
    Then the result should be, in order:
      | to_user |
      | 1       |
      | 2       |
    # ----- 11f: {1,2} with e.since > 2020 → VC index selected -----
    # 1-hop: {3}; 2-hop: {1,2}; union = {1,2,3}
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH WALK (u1:user{id:1})-[e:friend WHERE e.since > 2020]->{1,2}(u2:user) RETURN DISTINCT u2.id AS to_user ORDER BY to_user ASC
      """
    And the plan should contain "vcIndex: friend_src_since_idx"
    Then the result should be, in order:
      | to_user |
      | 1       |
      | 2       |
      | 3       |
    # ----- 11g: {1,2} WALK without DISTINCT → Recursive path, VC index on inner EdgesScan -----
    # Unlike 11f (RETURN DISTINCT → KHopExpand path), a bare RETURN without DISTINCT
    # goes through Recursive + HashJoin(EdgesScan, WorkTableScan).
    # Before the fix the inner EdgesScan used TableScanMethod; after it uses IndexScanMethod.
    # 1-hop from u1 with since>2020: {u3(2021)}.
    # 2-hop from u3 with since>2020: {u1(2024), u2(2023)}.
    # All WALK rows (with duplicates across hops allowed): to_user ∈ {3, 1, 2} → sorted: 1, 2, 3.
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH WALK (u1:user{id:1})-[e:friend WHERE e.since > 2020]->{1,2}(u2:user) RETURN u2.id AS to_user ORDER BY to_user ASC
      """
    And the plan should contain "Recursive"
    And the plan should contain "index: friend_src_since_idx"
    Then the result should be, in order:
      | to_user |
      | 1       |
      | 2       |
      | 3       |
    # ----- 11h: {2,2} WALK without DISTINCT → Recursive path, VC index on inner EdgesScan -----
    # Exactly 2 hops:
    # iter 1  frontier={1} → VC index since>2020 from 1 → {u3(2021)}
    # iter 2  frontier={3} → VC index since>2020 from 3 → {u1(2024), u2(2023)}
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH WALK (u1:user{id:1})-[e:friend WHERE e.since > 2020]->{2,2}(u2:user) RETURN u2.id AS to_user ORDER BY to_user ASC
      """
    And the plan should contain "Recursive"
    And the plan should contain "index: friend_src_since_idx"
    Then the result should be, in order:
      | to_user |
      | 1       |
      | 2       |
    # ----- 11i: {1,2} WALK, non-matching INDEX hint must not force anchor-only VC rewrite -----
    # friend_src_weight_idx is (_src, weight), but this query only constrains since.
    # The optimizer must not force an anchor-only VC rewrite here; it should stay on the
    # Recursive + TableScan + dynamic filter path, consistent with the K-HOP/BiBFS cases.
    When executing query:
      """
      USE vc_index_graph CREATE INDEX friend_src_weight_idx ON EDGE friend(_src, weight)
      """
    Then the execution should be successful
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH WALK (u1:user{id:1})-[e:friend WHERE e.since > 2020 /*+ INDEX(friend_src_weight_idx) */]->{1,2}(u2:user) RETURN u2.id AS to_user ORDER BY to_user ASC
      """
    And the plan should contain "Recursive"
    And the plan should not contain "index: friend_src_weight_idx"
    And the plan should not contain "index: friend_src_since_idx"
    Then the result should be, in order:
      | to_user |
      | 1       |
      | 2       |
      | 3       |
    When executing query:
      """
      USE vc_index_graph DROP INDEX friend_src_weight_idx
      """
    Then the execution should be successful
    # Cleanup 11
    When executing query:
      """
      USE vc_index_graph DROP INDEX friend_src_since_idx
      """
    Then the execution should be successful
    # ============================================
    # Part 12: INDEX and IGNORE_INDEX hint behavior with VC indexes
    # Verifies that hints override and complement the auto-selection mechanism:
    # - IGNORE_INDEX prevents a VC index from being auto-selected
    # - Explicit INDEX hint forces a specific VC index even when another would
    # be chosen by auto-selection
    # Friend edges from Parts 6 & 7 (still in graph):
    # - u1→u2(since:2020,weight:10), u1→u3(since:2021,weight:8),
    # - u1→u4(since:2019,weight:9)
    # ============================================
    When executing query:
      """
      USE vc_index_graph CREATE INDEX friend_src_since_idx ON EDGE friend(_src, since)
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_index_graph CREATE INDEX friend_src_weight_idx ON EDGE friend(_src, weight)
      """
    Then the execution should be successful
    # ----- 12a: baseline — auto-selection picks the index whose column matches the predicate -----
    # e.since >= 2020 → friend_src_since_idx auto-selected (since column directly constrained).
    # Demonstrates auto-selection without any hint; 12b/12c/12d compare against this baseline.
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u1:user{id:1})-[e:friend]->(u2:user) WHERE e.since >= 2020 RETURN u2.id AS to_user, e.since AS since ORDER BY e.since ASC
      """
    Then the result should be, in order:
      | to_user | since |
      | 2       | 2020  |
      | 3       | 2021  |
    And the plan should contain "index: friend_src_since_idx"
    And the plan should contain "IndexScan: {friend: {since}}"
    And the plan node "[SP0]EdgesScan" containing "index: friend_src_since_idx" should have rows "2"
    # ----- 12a1: non-evaluable overall filter still runs via VC index + residual filter -----
    # The whole filter is not #sym:Evaluable because it depends on edge properties.
    # The since predicate is pushed into friend_src_since_idx, while e.weight > 8 remains
    # as a residual filter evaluated after the VC index scan.
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u1:user{id:1})-[e:friend /*+ INDEX(friend_src_since_idx) */]->(u2:user) WHERE e.since >= 2020 AND e.weight > 8 RETURN u2.id AS to_user, e.since AS since, e.weight AS weight ORDER BY to_user ASC
      """
    Then the result should be, in order:
      | to_user | since | weight |
      | 2       | 2020  | 10     |
    And the plan should contain "index: friend_src_since_idx"
    And the plan should not contain "index: friend_src_weight_idx"
    # ----- 12a2: variable cutoff is not #sym:Evaluable, so the query falls back -----
    # Here the RHS value comes from the binding variable i, so the predicate cannot be
    # constant-folded. validateEvaluableSubExprsForVcIndex() does not throw, but the current
    # planner also does not select friend_src_since_idx for this shape. The query still runs
    # correctly on the fallback path.
    When executing query:
      """
      PROFILE USE vc_index_graph FOR i IN [2020] MATCH (u1:user{id:1})-[e:friend /*+ INDEX(friend_src_since_idx) */]->(u2:user) WHERE e.since >= i RETURN u2.id AS to_user, e.since AS since ORDER BY to_user ASC
      """
    Then the result should be, in order:
      | to_user | since |
      | 2       | 2020  |
      | 3       | 2021  |
    And the plan should not contain "index: friend_src_since_idx"
    # ----- 12b: IGNORE_INDEX suppresses the auto-selected VC index -----
    # IGNORE_INDEX(friend_src_since_idx) excludes since_idx. The remaining friend_src_weight_idx
    # still does not match the since predicate, so the query must stay on the fallback path.
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u1:user{id:1})-[e:friend /*+ IGNORE_INDEX(friend_src_since_idx) */]->(u2:user) WHERE e.since >= 2020 RETURN u2.id AS to_user, e.since AS since ORDER BY e.since ASC
      """
    Then the result should be, in order:
      | to_user | since |
      | 2       | 2020  |
      | 3       | 2021  |
    And the plan should not contain "index: friend_src_since_idx"
    And the plan should not contain "index: friend_src_weight_idx"
    # ----- 12c: explicit INDEX hint selects a specific VC index, overriding auto-selection -----
    # Query has both since AND weight predicates; auto-selection would favor since_idx
    # (since column is directly constrained). INDEX(friend_src_weight_idx) forces weight_idx.
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u1:user{id:1})-[e:friend /*+ INDEX(friend_src_weight_idx) */]->(u2:user) WHERE e.since >= 2020 AND e.weight > 5 RETURN u2.id AS to_user, e.since AS since, e.weight AS weight ORDER BY e.weight DESC
      """
    Then the result should be, in order:
      | to_user | since | weight |
      | 2       | 2020  | 10     |
      | 3       | 2021  | 8      |
    And the plan should contain "index: friend_src_weight_idx"
    And the plan should not contain "index: friend_src_since_idx"
    And the plan should contain "IndexScan: {friend: {weight, since}}"
    And the plan node "[SP0]EdgesScan" containing "index: friend_src_weight_idx" should have rows "2"
    # ----- 12d: IGNORE_INDEX(since_idx) with both predicates → weight_idx or table scan -----
    # Confirm: ignoring the "ideal" index still yields correct results.
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u1:user{id:1})-[e:friend /*+ IGNORE_INDEX(friend_src_since_idx) */]->(u2:user) WHERE e.since >= 2020 AND e.weight > 5 RETURN u2.id AS to_user, e.since AS since, e.weight AS weight ORDER BY e.weight DESC
      """
    Then the result should be, in order:
      | to_user | since | weight |
      | 2       | 2020  | 10     |
      | 3       | 2021  | 8      |
    And the plan should contain "index: friend_src_weight_idx"
    And the plan should not contain "index: friend_src_since_idx"
    # ----- 12e: direction compatibility matrix for VC indexes -----
    # watch is a directed edge: user -[watch]-> movie
    # - _src VC index is compatible with -> and bidirectional (-) patterns anchored on user
    # - _dst VC index is compatible with <- and bidirectional (-) patterns anchored on movie
    # - _src must NOT be used for pure incoming (<-) queries
    # - _dst must NOT be used for pure outgoing (->) queries
    # The compatible cases below are paired with IGNORE_INDEX fallbacks to verify the result
    # set is identical even when VC index usage is disabled.
    When executing query:
      """
      USE vc_index_graph CREATE INDEX watch_src_rate_dir_idx ON EDGE watch(_src, rate)
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_index_graph CREATE INDEX watch_dst_rate_dir_idx ON EDGE watch(_dst, rate)
      """
    Then the execution should be successful
    # 12e1: _src index with outgoing pattern -> should use VC index.
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user{id:1})-[e:watch /*+ INDEX(watch_src_rate_dir_idx) */]->(m:movie) WHERE e.rate > 0 RETURN m.id AS movie_id, e.rate AS rate ORDER BY movie_id ASC
      """
    Then the result should be, in order:
      | movie_id | rate |
      | 101      | 85   |
      | 102      | 90   |
    And the plan should contain "index: watch_src_rate_dir_idx"
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user{id:1})-[e:watch /*+ IGNORE_INDEX(watch_src_rate_dir_idx, watch_dst_rate_dir_idx) */]->(m:movie) WHERE e.rate > 0 RETURN m.id AS movie_id, e.rate AS rate ORDER BY movie_id ASC
      """
    Then the result should be, in order:
      | movie_id | rate |
      | 101      | 85   |
      | 102      | 90   |
    And the plan should not contain "index: watch_src_rate_dir_idx"
    And the plan should not contain "index: watch_dst_rate_dir_idx"
    # 12e2: _src index with pure incoming pattern <- is direction-incompatible and must not be used.
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (m:movie{id:101})<-[e:watch /*+ INDEX(watch_src_rate_dir_idx) */]-(u:user) WHERE e.rate > 0 RETURN u.id AS user_id, e.rate AS rate ORDER BY user_id ASC
      """
    Then the result should be, in order:
      | user_id | rate |
      | 1       | 85   |
      | 2       | 75   |
    And the plan should not contain "index: watch_src_rate_dir_idx"
    And the plan should not contain "index: watch_dst_rate_dir_idx"
    # 12e3: _dst index with incoming pattern <- should use VC index.
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (m:movie{id:101})<-[e:watch /*+ INDEX(watch_dst_rate_dir_idx) */]-(u:user) WHERE e.rate > 0 RETURN u.id AS user_id, e.rate AS rate ORDER BY user_id ASC
      """
    Then the result should be, in order:
      | user_id | rate |
      | 1       | 85   |
      | 2       | 75   |
    And the plan should contain "index: watch_dst_rate_dir_idx"
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (m:movie{id:101})<-[e:watch /*+ IGNORE_INDEX(watch_src_rate_dir_idx, watch_dst_rate_dir_idx) */]-(u:user) WHERE e.rate > 0 RETURN u.id AS user_id, e.rate AS rate ORDER BY user_id ASC
      """
    Then the result should be, in order:
      | user_id | rate |
      | 1       | 85   |
      | 2       | 75   |
    And the plan should not contain "index: watch_src_rate_dir_idx"
    And the plan should not contain "index: watch_dst_rate_dir_idx"
    # 12e4: _dst index with pure outgoing pattern -> is direction-incompatible and must not be used.
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user{id:1})-[e:watch /*+ INDEX(watch_dst_rate_dir_idx) */]->(m:movie) WHERE e.rate > 0 RETURN m.id AS movie_id, e.rate AS rate ORDER BY movie_id ASC
      """
    Then the result should be, in order:
      | movie_id | rate |
      | 101      | 85   |
      | 102      | 90   |
    And the plan should not contain "index: watch_src_rate_dir_idx"
    And the plan should not contain "index: watch_dst_rate_dir_idx"
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user{id:1})-[e:watch /*+ IGNORE_INDEX(watch_src_rate_dir_idx, watch_dst_rate_dir_idx) */]->(m:movie) WHERE e.rate > 0 RETURN m.id AS movie_id, e.rate AS rate ORDER BY movie_id ASC
      """
    Then the result should be, in order:
      | movie_id | rate |
      | 101      | 85   |
      | 102      | 90   |
    And the plan should not contain "index: watch_src_rate_dir_idx"
    And the plan should not contain "index: watch_dst_rate_dir_idx"
    # 12e5: bidirectional pattern with user anchor may use the _src VC index.
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user{id:1})-[e:watch /*+ INDEX(watch_src_rate_dir_idx) */]-(m:movie) WHERE e.rate > 0 RETURN m.id AS movie_id, e.rate AS rate ORDER BY movie_id ASC
      """
    Then the result should be, in order:
      | movie_id | rate |
      | 101      | 85   |
      | 102      | 90   |
    And the plan should contain "index: watch_src_rate_dir_idx"
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user{id:1})-[e:watch /*+ IGNORE_INDEX(watch_src_rate_dir_idx, watch_dst_rate_dir_idx) */]-(m:movie) WHERE e.rate > 0 RETURN m.id AS movie_id, e.rate AS rate ORDER BY movie_id ASC
      """
    Then the result should be, in order:
      | movie_id | rate |
      | 101      | 85   |
      | 102      | 90   |
    And the plan should not contain "index: watch_src_rate_dir_idx"
    And the plan should not contain "index: watch_dst_rate_dir_idx"
    # 12e6: bidirectional pattern with movie anchor may use the _dst VC index.
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (m:movie{id:102})-[e:watch /*+ INDEX(watch_dst_rate_dir_idx) */]-(u:user) WHERE e.rate > 80 RETURN u.id AS user_id, e.rate AS rate ORDER BY user_id ASC
      """
    Then the result should be, in order:
      | user_id | rate |
      | 1       | 90   |
      | 3       | 88   |
    And the plan should contain "index: watch_dst_rate_dir_idx"
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (m:movie{id:102})-[e:watch /*+ IGNORE_INDEX(watch_src_rate_dir_idx, watch_dst_rate_dir_idx) */]-(u:user) WHERE e.rate > 80 RETURN u.id AS user_id, e.rate AS rate ORDER BY user_id ASC
      """
    Then the result should be, in order:
      | user_id | rate |
      | 1       | 90   |
      | 3       | 88   |
    And the plan should not contain "index: watch_src_rate_dir_idx"
    And the plan should not contain "index: watch_dst_rate_dir_idx"
    When executing query:
      """
      USE vc_index_graph DROP INDEX watch_src_rate_dir_idx
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_index_graph DROP INDEX watch_dst_rate_dir_idx
      """
    Then the execution should be successful
    # 12f: undirected edge type never uses VC index.
    # knows is declared as an undirected edge type, so CREATE INDEX ... (_src/_dst, ...)
    # is rejected in Part 2. This query is a runtime sanity check that undirected queries
    # still return correct results on the fallback path without any VC index.
    When executing query:
      """
      USE vc_index_graph MATCH (u1:user WHERE u1.id = 1), (u2:user WHERE u2.id = 2), (u3:user WHERE u3.id = 3) INSERT (u1)~[@knows{strength:7}]~(u2), (u1)~[@knows{strength:9}]~(u3)
      """
    Then the execution should be successful
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user{id:1})-[e:knows]-(v:user) WHERE e.strength >= 7 RETURN v.id AS other_user, e.strength AS strength ORDER BY other_user ASC
      """
    Then the result should be, in order:
      | other_user | strength |
      | 2          | 7        |
      | 3          | 9        |
    And the plan should not contain "index: friend_src_since_idx"
    And the plan should not contain "index: friend_src_weight_idx"
    # Cleanup 12
    When executing query:
      """
      USE vc_index_graph DROP INDEX friend_src_since_idx
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_index_graph DROP INDEX friend_src_weight_idx
      """
    Then the execution should be successful
    # ============================================
    # Cleanup
    # ============================================
    When executing query:
      """
      DROP GRAPH IF EXISTS vc_index_graph
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE IF EXISTS vc_index_graph_type
      """
    Then the execution should be successful

  @testmark
  Scenario: Vertex-centric edge index should be used for fixed source set
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS vc_corr_index_graph_type AS {
        NODE Person (LABEL Person {id INT, PRIMARY KEY (id)}),
        EDGE KNOWS (Person)-[ LABEL KNOWS {creationDate LOCAL DATETIME}]->(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH IF EXISTS vc_corr_index_graph
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH vc_corr_index_graph TYPED vc_corr_index_graph_type
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE persons {id} = (1), (2), (3)
      USE vc_corr_index_graph
      FOR r IN persons INSERT (@Person{id:r.id})
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE knows {src,dst,creationDate} =
        (1,1,local_datetime("2021-01-01T10:00:40.213", "%Y-%m-%dT%H:%M:%S")),
        (2,2,local_datetime("2021-01-01T10:00:40.213", "%Y-%m-%dT%H:%M:%S")),
        (3,3,local_datetime("2021-01-01T10:00:40.213", "%Y-%m-%dT%H:%M:%S"))
      USE vc_corr_index_graph
      FOR r IN knows
      MATCH (s@Person{id:r.src}), (t@Person{id:r.dst})
      INSERT (s)-[@KNOWS{creationDate:r.creationDate}]->(t)
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_corr_index_graph
      MATCH (s:Person WHERE s.id IN [1,2])-[e:KNOWS]->(t:Person)
      WHERE e.creationDate >= zoned_datetime("1981-07-03")
      RETURN s.id AS src, t.id AS dst
      ORDER BY src, dst
      """
    Then an Error should be raised: "[22009]: Parse ZonedDatetime: `1981-07-03` fail, in expression: CAST(e.creationDate AS ZONEDDATETIME) >= zoned_datetime(\"1981-07-03\", \"%Y-%m-%dT%H:%M:%S %z\")"
    When executing query:
      """
      USE vc_corr_index_graph
      CREATE INDEX IF NOT EXISTS knows_src_creation_tck_idx ON EDGE KNOWS(_src, creationDate)
      """
    Then the execution should be successful
    And index "knows_src_creation_tck_idx" of "vc_corr_index_graph" should be ready to use
    When executing query:
      """
      PROFILE USE vc_corr_index_graph
      FOR i IN range(1,2)
      MATCH (s:Person{id:i})-[e:KNOWS /*+ INDEX(knows_src_creation_tck_idx) */]->(t:Person)
      WHERE e.creationDate = local_datetime("2021-01-01T10:00:40.213", "%Y-%m-%dT%H:%M:%S")
      RETURN s.id AS src, t.id AS dst
      ORDER BY src, dst
      """
    Then the result should be, in any order:
      | src | dst |
      | 1   | 1   |
      | 2   | 2   |
    And the plan should contain "index: knows_src_creation_tck_idx"
    And the plan should contain "IndexScan: {KNOWS: {creationDate}}"
    And the plan should not contain "TableScan: {KNOWS: {creationDate}}"
    And the plan node "[SP0]EdgesScan" containing "index: knows_src_creation_tck_idx" should have rows "2"
    When executing query:
      """
      PROFILE USE vc_corr_index_graph
      MATCH (s:Person WHERE s.id IN [1,2])-[e:KNOWS /*+ INDEX(knows_src_creation_tck_idx) */]->(t:Person)
      WHERE e.creationDate = local_datetime("2021-01-01T10:00:40.213", "%Y-%m-%dT%H:%M:%S")
      RETURN s.id AS src, t.id AS dst
      ORDER BY src, dst
      """
    Then the result should be, in order:
      | src | dst |
      | 1   | 1   |
      | 2   | 2   |
    And the plan should contain "index: knows_src_creation_tck_idx"
    And the plan should contain "IndexScan: {KNOWS: {creationDate}}"
    And the plan should not contain "TableScan: {KNOWS: {creationDate}}"
    And the plan node "[SP0]EdgesScan" containing "index: knows_src_creation_tck_idx" should have rows "2"
    When executing query:
      """
      PROFILE USE vc_corr_index_graph
      MATCH (s:Person WHERE s.id IN [1,2])-[e:KNOWS /*+ INDEX(knows_src_creation_tck_idx) */]->(t:Person)
      WHERE e.creationDate >= zoned_datetime("1981-07-03")
      RETURN s.id AS src, t.id AS dst
      ORDER BY src, dst
      """
    Then an Error should be raised: "[22009]: Parse ZonedDatetime: `1981-07-03` fail, in expression: zoned_datetime(\"1981-07-03\", \"%Y-%m-%dT%H:%M:%S %z\")"
    And drop the index "knows_src_creation_tck_idx" of "vc_corr_index_graph"
    And drop the graph "vc_corr_index_graph"
    And drop the graph type "vc_corr_index_graph_type"

  @testmark
  Scenario: Vertex-centric edge index should report rows for each hop
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS vc_index_hop_rows_graph_type AS {
        NODE user (LABEL user {id INT64 PRIMARY KEY}),
        NODE movie (LABEL movie {id INT64 PRIMARY KEY}),
        EDGE friend (user)-[LABEL friend {since INT64}]->(user),
        EDGE watch (user)-[LABEL watch {rate INT64}]->(movie)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH IF EXISTS vc_index_hop_rows_graph
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH vc_index_hop_rows_graph TYPED vc_index_hop_rows_graph_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_index_hop_rows_graph
      INSERT (@user{id:1}), (@user{id:2}), (@user{id:3}), (@user{id:4}), (@user{id:5}), (@movie{id:101}), (@movie{id:102}), (@movie{id:103})
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_index_hop_rows_graph
      MATCH (u1:user{id:1}), (u2:user{id:2}), (u3:user{id:3}), (u4:user{id:4}), (u5:user{id:5}), (m1:movie{id:101}), (m2:movie{id:102}), (m3:movie{id:103})
      INSERT
        (u1)-[@friend{since:10}]->(u2),
        (u1)-[@friend{since:20}]->(u3),
        (u2)-[@friend{since:30}]->(u4),
        (u2)-[@friend{since:40}]->(u5),
        (u3)-[@friend{since:50}]->(u5),
        (u4)-[@watch{rate:80}]->(m1),
        (u5)-[@watch{rate:85}]->(m2),
        (u5)-[@watch{rate:90}]->(m3)
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_index_hop_rows_graph
      CREATE INDEX IF NOT EXISTS friend_src_since_rows_idx ON EDGE friend(_src, since)
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_index_hop_rows_graph
      CREATE INDEX IF NOT EXISTS watch_src_rate_rows_idx ON EDGE watch(_src, rate)
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_index_hop_rows_graph
      CREATE INDEX IF NOT EXISTS watch_src_rate_rows_idx ON EDGE watch(_src, rate)
      """
    Then the execution should be successful
    And index "friend_src_since_rows_idx" of "vc_index_hop_rows_graph" should be ready to use
    And index "watch_src_rate_rows_idx" of "vc_index_hop_rows_graph" should be ready to use
    When executing query:
      """
      USE vc_index_hop_rows_graph
      MATCH (u1:user{id:1})-[e1:friend]->(u2:user)
      RETURN u2.id AS mid_user
      ORDER BY mid_user
      """
    Then the result should be, in order:
      | mid_user |
      | 2        |
      | 3        |
    When executing query:
      """
      USE vc_index_hop_rows_graph
      MATCH (u1:user{id:1})-[e1:friend]->(u2:user),
            (u2:user)-[e2:friend]->(u3:user)
      RETURN u2.id AS mid_user, u3.id AS dst_user
      ORDER BY mid_user, dst_user
      """
    Then the result should be, in order:
      | mid_user | dst_user |
      | 2        | 4        |
      | 2        | 5        |
      | 3        | 5        |
    # ----- Fixed-hop KHopExpand: different hops use different VC indexes -----
    # The query only returns the final endpoint m, so ExpandToKHopRule can rewrite the
    # fixed 3-hop chain into a single KHopExpand(Fixed). Hop 1 and hop 2 are friend edges
    # filtered by since, while hop 3 is a watch edge filtered by rate. The fixed KHop plan
    # should therefore carry friend_src_since_rows_idx on the friend hops and
    # watch_src_rate_rows_idx on the watch hop.
    When executing query:
      """
      PROFILE USE vc_index_hop_rows_graph
      MATCH WALK (u1:user{id:1})-[e1:friend WHERE e1.since > 0]->(u2:user)-[e2:friend WHERE e2.since > 0]->(u3:user)-[e3:watch WHERE e3.rate > 0]->(m:movie)
      RETURN DISTINCT m.id AS movie_id
      ORDER BY movie_id
      """
    Then the result should be, in order:
      | movie_id |
      | 101      |
      | 102      |
      | 103      |
    And the plan should contain "KHopExpand"
    And the plan should contain "vcIndex: friend_src_since_rows_idx"
    And the plan should contain "vcIndex: watch_src_rate_rows_idx"
    When executing query:
      """
      PROFILE /*+ SET_VAR(enable_reorder=true) */ USE vc_index_hop_rows_graph
      MATCH (u1:user{id:1})-[e1:friend /*+ INDEX(friend_src_since_rows_idx) */]->(u2:user),
        (u2:user)-[e2:friend /*+ INDEX(friend_src_since_rows_idx) */]->(u3:user),
        (u3:user)-[e3:watch /*+ INDEX(watch_src_rate_rows_idx) */]->(m:movie)
      WHERE e1.since > 0 AND e2.since > 0 AND e3.rate > 0
      RETURN u2.id AS mid_user, u3.id AS dst_user, m.id AS movie_id
      ORDER BY mid_user, dst_user, movie_id
      """
    Then the result should be, in order:
      | mid_user | dst_user | movie_id |
      | 2        | 4        | 101      |
      | 2        | 5        | 102      |
      | 2        | 5        | 103      |
      | 3        | 5        | 102      |
      | 3        | 5        | 103      |
    And the plan should contain "index: friend_src_since_rows_idx"
    And the plan should contain "index: watch_src_rate_rows_idx"
    And the plan should contain "IndexScan: {friend: {since}}"
    And the plan should contain "IndexScan: {watch: {rate}}"
    And the plan node "[SP0]EdgesScan" containing "varName: e1, IndexScan: {friend: {since}}" should have rows "2"
    And the plan node "[SP0]EdgesScan" containing "varName: e2, IndexScan: {friend: {since}}" should have rows "3"
    And the plan node "[SP0]EdgesScan" containing "varName: e3, IndexScan: {watch: {rate}}" should have rows "3"
    # ----- Auto-selection: same 3-hop query without explicit INDEX hints -----
    # u1.id=1 is a point anchor → friend_src_since_rows_idx auto-selected for e1
    # u2 / u3 are correlated intermediate anchors → indexes auto-selected for e2 and e3
    When executing query:
      """
      PROFILE /*+ SET_VAR(enable_reorder=true) */ USE vc_index_hop_rows_graph
      MATCH (u1:user{id:1})-[e1:friend]->(u2:user),
        (u2:user)-[e2:friend]->(u3:user),
        (u3:user)-[e3:watch]->(m:movie)
      WHERE e1.since > 0 AND e2.since > 0 AND e3.rate > 0
      RETURN u2.id AS mid_user, u3.id AS dst_user, m.id AS movie_id
      ORDER BY mid_user, dst_user, movie_id
      """
    Then the result should be, in order:
      | mid_user | dst_user | movie_id |
      | 2        | 4        | 101      |
      | 2        | 5        | 102      |
      | 2        | 5        | 103      |
      | 3        | 5        | 102      |
      | 3        | 5        | 103      |
    And the plan should contain "index: friend_src_since_rows_idx"
    And the plan should contain "index: watch_src_rate_rows_idx"
    And the plan should contain "IndexScan: {friend: {since}}"
    And the plan should contain "IndexScan: {watch: {rate}}"
    And the plan node "[SP0]EdgesScan" containing "varName: e1, IndexScan: {friend: {since}}" should have rows "2"
    And the plan node "[SP0]EdgesScan" containing "varName: e2, IndexScan: {friend: {since}}" should have rows "3"
    And the plan node "[SP0]EdgesScan" containing "varName: e3, IndexScan: {watch: {rate}}" should have rows "3"
    When executing query:
      """
      PROFILE /*+ SET_VAR(enable_reorder=true) */ USE vc_index_hop_rows_graph
      MATCH (u1:user{id:1})-[e1:friend /*+ IGNORE_INDEX(friend_src_since_rows_idx) */]->(u2:user),
        (u2:user)-[e2:friend /*+ IGNORE_INDEX(friend_src_since_rows_idx) */]->(u3:user),
        (u3:user)-[e3:watch /*+ IGNORE_INDEX(watch_src_rate_rows_idx) */]->(m:movie)
      WHERE e1.since > 0 AND e2.since > 0 AND e3.rate > 0
      RETURN u2.id AS mid_user, u3.id AS dst_user, m.id AS movie_id
      ORDER BY mid_user, dst_user, movie_id
      """
    Then the result should be, in order:
      | mid_user | dst_user | movie_id |
      | 2        | 4        | 101      |
      | 2        | 5        | 102      |
      | 2        | 5        | 103      |
      | 3        | 5        | 102      |
      | 3        | 5        | 103      |
    And the plan should not contain "index: friend_src_since_rows_idx"
    And the plan should not contain "index: watch_src_rate_rows_idx"
    And the plan should not contain "IndexScan: {friend: {since}}"
    And the plan should not contain "IndexScan: {watch: {rate}}"
    And the plan should contain "TableScan: {friend: {since}}"
    And the plan should contain "TableScan: {watch: {rate}}"
    And the plan node "[SP0]EdgesScan" containing "varName: e1, TableScan: {friend: {since}}" should have rows "2"
    And the plan node "[SP0]EdgesScan" containing "varName: e2, TableScan: {friend: {since}}" should have rows "3"
    And the plan node "[SP0]EdgesScan" containing "varName: e3, TableScan: {watch: {rate}}" should have rows "3"
    And drop the index "friend_src_since_rows_idx" of "vc_index_hop_rows_graph"
    And drop the index "watch_src_rate_rows_idx" of "vc_index_hop_rows_graph"
    And drop the graph "vc_index_hop_rows_graph"
    And drop the graph type "vc_index_hop_rows_graph_type"
