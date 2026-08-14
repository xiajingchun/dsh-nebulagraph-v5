# Copyright (c) 2026 vesoft inc. All rights reserved.
Feature: KHop Expand Optimization

  Scenario: KHop Expand comprehensive tests
    # ============================================================
    # Setup: Create a rich test graph
    # ============================================================
    # #
    # Person nodes: p1..p8
    # City nodes: c1, c2
    # #
    # KNOWS edges (with weight property):
    # p1→p2(w:10), p1→p3(w:20)
    # p2→p3(w:30), p2→p4(w:40)
    # p3→p4(w:50), p3→p1(w:60)    (cycle)
    # p4→p5(w:70)
    # p5→p5(w:80)                   (self-loop)
    # p5→p6(w:90)
    # p6→p7(w:100)
    # p7→p8(w:110)
    # p8→p1(w:120)                  (long cycle back)
    # p6→p6(w:130)                  (self-loop)
    # #
    # FOLLOWS edges:
    # p1→p4, p2→p5, p3→p6
    # #
    # LIVES_IN edges:
    # p1→c1, p2→c1, p3→c2, p4→c2, p5→c1
    # #
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS khop_type AS {
        NODE Person (LABEL Person {id INT PRIMARY KEY, name STRING, age INT}),
        NODE City (LABEL City {id INT PRIMARY KEY, name STRING}),
        EDGE KNOWS (Person)-[:KNOWS{weight INT}]->(Person),
        EDGE FOLLOWS (Person)-[:FOLLOWS]->(Person),
        EDGE LIVES_IN (Person)-[:LIVES_IN]->(City)
      }
      """
    Then the execution should be successful
    And drop the graph "khop_test"
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS khop_test TYPED khop_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE khop_test
      INSERT
        (p1@Person{id: 1, name: 'Alice', age: 25}),
        (p2@Person{id: 2, name: 'Bob', age: 30}),
        (p3@Person{id: 3, name: 'Charlie', age: 35}),
        (p4@Person{id: 4, name: 'David', age: 28}),
        (p5@Person{id: 5, name: 'Eve', age: 22}),
        (p6@Person{id: 6, name: 'Frank', age: 40}),
        (p7@Person{id: 7, name: 'Grace', age: 33}),
        (p8@Person{id: 8, name: 'Hank', age: 45}),
        (c1@City{id: 101, name: 'Beijing'}),
        (c2@City{id: 102, name: 'Shanghai'}),
        (p1)-[@KNOWS{weight: 10}]->(p2),
        (p1)-[@KNOWS{weight: 20}]->(p3),
        (p2)-[@KNOWS{weight: 30}]->(p3),
        (p2)-[@KNOWS{weight: 40}]->(p4),
        (p3)-[@KNOWS{weight: 50}]->(p4),
        (p3)-[@KNOWS{weight: 60}]->(p1),
        (p4)-[@KNOWS{weight: 70}]->(p5),
        (p5)-[@KNOWS{weight: 80}]->(p5),
        (p5)-[@KNOWS{weight: 90}]->(p6),
        (p6)-[@KNOWS{weight: 100}]->(p7),
        (p7)-[@KNOWS{weight: 110}]->(p8),
        (p8)-[@KNOWS{weight: 120}]->(p1),
        (p6)-[@KNOWS{weight: 130}]->(p6),
        (p1)-[@FOLLOWS]->(p4),
        (p2)-[@FOLLOWS]->(p5),
        (p3)-[@FOLLOWS]->(p6),
        (p1)-[@LIVES_IN]->(c1),
        (p2)-[@LIVES_IN]->(c1),
        (p3)-[@LIVES_IN]->(c2),
        (p4)-[@LIVES_IN]->(c2),
        (p5)-[@LIVES_IN]->(c1)
      """
    Then the execution should be successful
    # ============================================================
    # Fixed-length: basic positive cases
    # ============================================================
    # 2-hop RETURN DISTINCT
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->(b:Person)-[:KNOWS]->(c:Person)
      RETURN DISTINCT c.id AS id
      ORDER BY id
      """
    Then the result should be, in order:
      | id |
      | 1  |
      | 3  |
      | 4  |
    # 3-hop RETURN DISTINCT
    # From p1: 3-hop paths produce destinations {p1, p2, p3, p4, p5}
    # p1→p2→p3→p4, p1→p2→p3→p1, p1→p2→p4→p5, p1→p3→p4→p5,
    # p1→p3→p1→p2, p1→p3→p1→p3
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->(b:Person)-[:KNOWS]->(c:Person)-[:KNOWS]->(d:Person)
      RETURN DISTINCT d.id AS id
      ORDER BY id
      """
    Then the result should be, in order:
      | id |
      | 1  |
      | 2  |
      | 3  |
      | 4  |
      | 5  |
    # RETURN DISTINCT with node string property
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->(b:Person)-[:KNOWS]->(c:Person)
      RETURN DISTINCT c.name AS name
      ORDER BY name
      """
    Then the result should be, in order:
      | name      |
      | "Alice"   |
      | "Charlie" |
      | "David"   |
    # COUNT DISTINCT
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->(b:Person)-[:KNOWS]->(c:Person)
      RETURN COUNT(DISTINCT c.id) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 3   |
    # ============================================================
    # Variable-length: lower=1
    # ============================================================
    # {1,3}
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->{1,3}(d:Person)
      RETURN DISTINCT d.id AS id
      ORDER BY id
      """
    Then the result should be, in order:
      | id |
      | 1  |
      | 2  |
      | 3  |
      | 4  |
      | 5  |
    # {1,1} equivalent to single hop
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->{1,1}(d:Person)
      RETURN DISTINCT d.id AS id
      ORDER BY id
      """
    Then the result should be, in order:
      | id |
      | 2  |
      | 3  |
    # {1,5} deep traversal
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->{1,5}(d:Person)
      RETURN DISTINCT d.id AS id
      ORDER BY id
      """
    Then the result should be, in order:
      | id |
      | 1  |
      | 2  |
      | 3  |
      | 4  |
      | 5  |
      | 6  |
      | 7  |
    # ============================================================
    # Variable-length: lower > 1 (Split mode)
    # ============================================================
    # {2,2} equivalent to fixed 2-hop
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->{2,2}(d:Person)
      RETURN DISTINCT d.id AS id
      ORDER BY id
      """
    Then the result should be, in order:
      | id |
      | 1  |
      | 3  |
      | 4  |
    # {2,4}
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->{2,4}(d:Person)
      RETURN DISTINCT d.id AS id
      ORDER BY id
      """
    Then the result should be, in order:
      | id |
      | 1  |
      | 2  |
      | 3  |
      | 4  |
      | 5  |
      | 6  |
    # {3,5}
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->{3,5}(d:Person)
      RETURN DISTINCT d.id AS id
      ORDER BY id
      """
    Then the result should be, in order:
      | id |
      | 1  |
      | 2  |
      | 3  |
      | 4  |
      | 5  |
      | 6  |
      | 7  |
    # {3,3} degenerates to Fixed when lower==upper (Split boundary)
    # From p5: hop1={p5,p6}, hop2={p5,p6,p7}, hop3={p5,p6,p7,p8}
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 5})-[:KNOWS]->{3,3}(d:Person)
      RETURN DISTINCT d.id AS id
      ORDER BY id
      """
    Then the result should be, in order:
      | id |
      | 5  |
      | 6  |
      | 7  |
      | 8  |
    # {2,3} Split from p5 (self-loop): phase1=hop1, phase2=hops 2-3
    # Collect = {p5,p6,p7} (hop2) ∪ {p8} (hop3)
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 5})-[:KNOWS]->{2,3}(d:Person)
      RETURN DISTINCT d.id AS id
      ORDER BY id
      """
    Then the result should be, in order:
      | id |
      | 5  |
      | 6  |
      | 7  |
      | 8  |
    # {3,3} from p6 (self-loop at p6): hop3 dsts = {p1,p6,p7,p8}
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 6})-[:KNOWS]->{3,3}(d:Person)
      RETURN DISTINCT d.id AS id
      ORDER BY id
      """
    Then the result should be, in order:
      | id |
      | 1  |
      | 6  |
      | 7  |
      | 8  |
    # ============================================================
    # Multi-edge-type variable-length
    # ============================================================
    # KNOWS|FOLLOWS {1,2} from p1: hop1={p2,p3,p4}, hop2 adds {p1,p5,p6}
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS|FOLLOWS]->{1,2}(d:Person)
      RETURN DISTINCT d.id AS id
      ORDER BY id
      """
    Then the result should be, in order:
      | id |
      | 1  |
      | 2  |
      | 3  |
      | 4  |
      | 5  |
      | 6  |
    # ============================================================
    # Mixed fixed-length + variable-length (should fallback, not KHop)
    # ============================================================
    # 1-hop fixed Extend then {1,3} VarLen: union of all walk dsts
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->(b:Person)-[:KNOWS]->{1,3}(c:Person)
      RETURN DISTINCT c.id AS id
      ORDER BY id
      """
    Then the result should be, in order:
      | id |
      | 1  |
      | 2  |
      | 3  |
      | 4  |
      | 5  |
      | 6  |
    # ============================================================
    # Walk mode: self-loops and cycles
    # ============================================================
    # Self-loop p5
    # From p5, 2-hop KNOWS: b ∈ {p5,p6}, then p5→{p5,p6}, p6→{p7,p6}
    # Deduped c = {p5, p6, p7}
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 5})-[:KNOWS]->(b:Person)-[:KNOWS]->(c:Person)
      RETURN DISTINCT c.id AS id
      ORDER BY id
      """
    Then the result should be, in order:
      | id |
      | 5  |
      | 6  |
      | 7  |
    # Isolated self-loop p6
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 6})-[:KNOWS]->{2,2}(d:Person)
      RETURN DISTINCT d.id AS id
      ORDER BY id
      """
    Then the result should be, in order:
      | id |
      | 6  |
      | 7  |
      | 8  |
    # Cycle detection: 3-hop walks from p2 end at {p5, p2, p3, p5, p6}
    # via p2->p3->p4->p5, p2->p3->p1->p2, p2->p3->p1->p3,
    # p2->p4->p5->p5, p2->p4->p5->p6
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 2})-[:KNOWS]->(b:Person)-[:KNOWS]->(c:Person)-[:KNOWS]->(d:Person)
      RETURN DISTINCT d.id AS id
      ORDER BY id
      """
    Then the result should be, in order:
      | id |
      | 2  |
      | 3  |
      | 5  |
      | 6  |
    # ============================================================
    # Empty results
    # ============================================================
    # Non-existent start node
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 999})-[:KNOWS]->(b:Person)-[:KNOWS]->(c:Person)
      RETURN DISTINCT c.id AS id
      """
    Then the result should be, in any order:
      | id |
    # ============================================================
    # Multiple edge types in same hop
    # ============================================================
    # KNOWS or FOLLOWS in 1 hop from p1
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS|FOLLOWS]->(b:Person)
      RETURN DISTINCT b.id AS id
      ORDER BY id
      """
    Then the result should be, in order:
      | id |
      | 2  |
      | 3  |
      | 4  |
    # KNOWS or FOLLOWS in 2 hops
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS|FOLLOWS]->(b:Person)-[:KNOWS|FOLLOWS]->(c:Person)
      RETURN DISTINCT c.id AS id
      ORDER BY id
      """
    Then the result should be, in order:
      | id |
      | 1  |
      | 3  |
      | 4  |
      | 5  |
      | 6  |
    # ============================================================
    # Cross-edge-type hops (different edge types per hop)
    # ============================================================
    # Person→KNOWS→Person→LIVES_IN→City
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->(b:Person)-[:LIVES_IN]->(c:City)
      RETURN DISTINCT c.id AS id
      ORDER BY id
      """
    Then the result should be, in order:
      | id  |
      | 101 |
      | 102 |
    # ============================================================
    # Incoming direction
    # ============================================================
    # Reverse: who knows p4?
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 4})<-[:KNOWS]-(b:Person)
      RETURN DISTINCT b.id AS id
      ORDER BY id
      """
    Then the result should be, in order:
      | id |
      | 2  |
      | 3  |
    # Reverse 2-hop: who reaches p4 in exactly 2 hops?
    # Incoming to p4 = {p2, p3}; then incoming to p2 = {p1},
    # incoming to p3 = {p1, p2}.  Deduped c = {p1, p2}.
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 4})<-[:KNOWS]-(b:Person)<-[:KNOWS]-(c:Person)
      RETURN DISTINCT c.id AS id
      ORDER BY id
      """
    Then the result should be, in order:
      | id |
      | 1  |
      | 2  |
    # ============================================================
    # Negative cases: must NOT trigger KHopExpand, must be correct
    # ============================================================
    # No DISTINCT: 2-hop walks from p1 are
    # p1->p2->p3 (c=p3), p1->p2->p4 (c=p4),
    # p1->p3->p4 (c=p4), p1->p3->p1 (c=p1)
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->(b:Person)-[:KNOWS]->(c:Person)
      RETURN c.id AS id
      ORDER BY id
      """
    Then the result should be, in order:
      | id |
      | 1  |
      | 3  |
      | 4  |
      | 4  |
    # COUNT DISTINCT on path variable: 4 distinct 2-hop walks from p1
    When executing query:
      """
      USE khop_test
      MATCH p = (a:Person{id: 1})-[:KNOWS]->(b:Person)-[:KNOWS]->(c:Person)
      RETURN COUNT(DISTINCT p) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 4   |
    # GROUP BY with aggregate: 4 walks give cid counts {1:1, 3:1, 4:2}
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->(b:Person)-[:KNOWS]->(c:Person)
      RETURN count(*) AS cnt, c.id AS cid
      GROUP BY cid
      ORDER BY cid
      """
    Then the result should be, in order:
      | cnt | cid |
      | 1   | 1   |
      | 1   | 3   |
      | 2   | 4   |
    # RETURN DISTINCT on edge variable
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[e1:KNOWS]->(b:Person)-[e2:KNOWS]->(c:Person)
      RETURN DISTINCT e2
      """
    Then the execution should be successful
    # Multi-variable DISTINCT
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->(b:Person)-[:KNOWS]->(c:Person)
      RETURN DISTINCT b.id AS bid, c.id AS cid
      ORDER BY bid, cid
      """
    Then the result should be, in order:
      | bid | cid |
      | 2   | 3   |
      | 2   | 4   |
      | 3   | 1   |
      | 3   | 4   |
    # ============================================================
    # Correctness: compare optimized vs non-optimized
    # ============================================================
    # DISTINCT count should match deduped non-DISTINCT count.
    # Six 3-hop walks from p1:
    # p1->p2->p3->p4, p1->p2->p3->p1, p1->p2->p4->p5,
    # p1->p3->p4->p5, p1->p3->p1->p2, p1->p3->p1->p3
    # d multiset = {1, 2, 3, 4, 5, 5} -> DISTINCT = 5.
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->(b:Person)-[:KNOWS]->(c:Person)-[:KNOWS]->(d:Person)
      RETURN COUNT(DISTINCT d.id) AS dcnt
      """
    Then the result should be, in any order:
      | dcnt |
      | 5    |
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->(b:Person)-[:KNOWS]->(c:Person)-[:KNOWS]->(d:Person)
      RETURN d.id AS id
      ORDER BY id
      """
    Then the result should be, in order:
      | id |
      | 1  |
      | 2  |
      | 3  |
      | 4  |
      | 5  |
      | 5  |
    # ============================================================
    # Node filter on intermediate/endpoint nodes
    # ============================================================
    # Node property filter on intermediate node
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->(b:Person WHERE b.age > 30)-[:KNOWS]->(c:Person)
      RETURN DISTINCT c.id AS id
      ORDER BY id
      """
    Then the result should be, in order:
      | id |
      | 1  |
      | 4  |
    # Node property filter on endpoint
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->(b:Person)-[:KNOWS]->(c:Person WHERE c.age < 30)
      RETURN DISTINCT c.id AS id
      ORDER BY id
      """
    Then the result should be, in order:
      | id |
      | 1  |
      | 4  |
    # Node property filter on intermediate node in 3-hop
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->(b:Person)-[:KNOWS]->(c:Person WHERE c.age >= 28)-[:KNOWS]->(d:Person)
      RETURN DISTINCT d.id AS id
      ORDER BY id
      """
    Then the result should be, in order:
      | id |
      | 1  |
      | 4  |
      | 5  |
    # ============================================================
    # Edge filter
    # ============================================================
    # Edge property filter: only high-weight edges
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[e1:KNOWS WHERE e1.weight > 15]->(b:Person)-[e2:KNOWS]->(c:Person)
      RETURN DISTINCT c.id AS id
      ORDER BY id
      """
    Then the result should be, in order:
      | id |
      | 1  |
      | 4  |
    # Edge filter on second hop
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[e1:KNOWS]->(b:Person)-[e2:KNOWS WHERE e2.weight >= 50]->(c:Person)
      RETURN DISTINCT c.id AS id
      ORDER BY id
      """
    Then the result should be, in order:
      | id |
      | 1  |
      | 4  |
    # ============================================================
    # Combined node filter + edge filter
    # ============================================================
    # Edge filter + node filter on same hop
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[e:KNOWS WHERE e.weight > 15]->(b:Person WHERE b.age > 30)-[:KNOWS]->(c:Person)
      RETURN DISTINCT c.id AS id
      ORDER BY id
      """
    Then the result should be, in order:
      | id |
      | 1  |
      | 4  |
    # Edge filter on first hop + node filter on endpoint
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[e:KNOWS WHERE e.weight <= 15]->(b:Person)-[:KNOWS]->(c:Person WHERE c.age < 30)
      RETURN DISTINCT c.id AS id
      """
    Then the result should be, in any order:
      | id |
      | 4  |
    # Multiple filters across hops
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[e1:KNOWS WHERE e1.weight <= 20]->(b:Person WHERE b.age <= 35)-[e2:KNOWS WHERE e2.weight >= 40]->(c:Person)
      RETURN DISTINCT c.id AS id
      ORDER BY id
      """
    Then the result should be, in order:
      | id |
      | 1  |
      | 4  |
    # ============================================================
    # SUM/AVG DISTINCT aggregate functions
    # ============================================================
    # SUM DISTINCT on node property
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->(b:Person)-[:KNOWS]->(c:Person)
      RETURN SUM(DISTINCT c.age) AS total
      """
    Then the result should be, in any order:
      | total |
      | 88    |
    # AVG DISTINCT on node property
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->(b:Person)-[:KNOWS]->(c:Person)
      RETURN AVG(DISTINCT c.age) AS avg_age
      """
    Then the execution should be successful
    # MIN DISTINCT on node id: deduped c ∈ {p1,p3,p4} → ids {1,3,4}
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->(b:Person)-[:KNOWS]->(c:Person)
      RETURN MIN(DISTINCT c.id) AS min_id
      """
    Then the result should be, in any order:
      | min_id |
      | 1      |
    # MAX DISTINCT on node id
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->(b:Person)-[:KNOWS]->(c:Person)
      RETURN MAX(DISTINCT c.id) AS max_id
      """
    Then the result should be, in any order:
      | max_id |
      | 4      |
    # MIN DISTINCT on node numeric property: ages {25,35,28} → min=25
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->(b:Person)-[:KNOWS]->(c:Person)
      RETURN MIN(DISTINCT c.age) AS min_age
      """
    Then the result should be, in any order:
      | min_age |
      | 25      |
    # MAX DISTINCT on node numeric property: ages {25,35,28} → max=35
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->(b:Person)-[:KNOWS]->(c:Person)
      RETURN MAX(DISTINCT c.age) AS max_age
      """
    Then the result should be, in any order:
      | max_age |
      | 35      |
    # MIN/MAX DISTINCT in a 3-hop: deduped c ∈ {p1..p5}, ids {1..5}
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->(b:Person)-[:KNOWS]->(c:Person)-[:KNOWS]->(d:Person)
      RETURN MIN(DISTINCT d.id) AS min_id, MAX(DISTINCT d.id) AS max_id
      """
    Then the result should be, in any order:
      | min_id | max_id |
      | 1      | 5      |
    # COLLECT DISTINCT on node id: unique destination count is 3
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->(b:Person)-[:KNOWS]->(c:Person)
      RETURN size(COLLECT(DISTINCT c.id)) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 3   |
    # Mixed DISTINCT + non-DISTINCT aggregates must not optimize
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->(b:Person)-[:KNOWS]->(c:Person)
      RETURN COUNT(DISTINCT c.id) AS dcnt, count(*) AS cnt GROUP BY ()
      """
    Then the execution should be successful
    # ============================================================
    # Negative: toNodeFilter patterns should fall back to normal plan
    # ============================================================
    # toNodeFilter on intermediate node must not crash
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->(b:Person WHERE b.age > 30)-[:KNOWS]->(c:Person)
      RETURN c.id AS id
      ORDER BY id
      """
    Then the result should be, in order:
      | id |
      | 1  |
      | 4  |
    # ============================================================
    # Middle-node pattern: both endpoints anchored, DISTINCT on
    # the middle variable.  CBO may produce a LogicalJoin plan
    # that triggers the middle-node KHopExpand rewrite (Pattern 3).
    # ============================================================
    # DISTINCT b.id (requires node property fetch)
    # a=p1→{p2,p3}; {p2,p3}→p4; intersection: b ∈ {p2, p3}
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->(b:Person)-[:KNOWS]->(c:Person{id: 4})
      RETURN DISTINCT b.id AS id
      ORDER BY id
      """
    Then the result should be, in order:
      | id |
      | 2  |
      | 3  |
    # DISTINCT b.name (string property, exercises node fetch)
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->(b:Person)-[:KNOWS]->(c:Person{id: 4})
      RETURN DISTINCT b.name AS name
      ORDER BY name
      """
    Then the result should be, in order:
      | name      |
      | "Bob"     |
      | "Charlie" |
    # DISTINCT b.age (numeric property)
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->(b:Person)-[:KNOWS]->(c:Person{id: 4})
      RETURN DISTINCT b.age AS age
      ORDER BY age
      """
    Then the result should be, in order:
      | age |
      | 30  |
      | 35  |
    # COUNT(DISTINCT b.id) with anchored endpoints
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->(b:Person)-[:KNOWS]->(c:Person{id: 4})
      RETURN COUNT(DISTINCT b.id) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 2   |
    # SUM(DISTINCT b.age) with anchored endpoints
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->(b:Person)-[:KNOWS]->(c:Person{id: 4})
      RETURN SUM(DISTINCT b.age) AS total
      """
    Then the result should be, in any order:
      | total |
      | 65    |
    # 3-hop middle node: a→b→c→d, a and d anchored, DISTINCT c.id
    # a=p1→{p2,p3}; b→c: {p3,p4,p4,p1}; c→p5: only p4→p5
    When executing query:
      """
      USE khop_test
      MATCH (a:Person{id: 1})-[:KNOWS]->(b:Person)-[:KNOWS]->(c:Person)-[:KNOWS]->(d:Person{id: 5})
      RETURN DISTINCT c.id AS id
      ORDER BY id
      """
    Then the result should be, in order:
      | id |
      | 4  |
    And drop the graph "khop_test"
    And drop the graph type "khop_type"

  # ============================================================
  # Concurrent scenarios on pre-loaded ldbc graph
  # These run in parallel with query_concurrency hints
  # ============================================================
  Scenario: Concurrent KHop fixed length on ldbc
    When executing query:
      """
      /*+ SET_VAR(query_concurrency=4) */
      USE ldbc
      MATCH (a:Person{id: 1})-[:KNOWS]->(b:Person)-[:KNOWS]->(c:Person)
      RETURN DISTINCT c.id AS id
      """
    Then the result should be, in any order:
      | id |
      | 1  |

  Scenario: Concurrent KHop COUNT DISTINCT on ldbc
    When executing query:
      """
      /*+ SET_VAR(query_concurrency=4) */
      USE ldbc
      MATCH (a:Person{id: 1})-[:KNOWS]->(b:Person)-[:KNOWS]->(c:Person)
      RETURN COUNT(DISTINCT c.id) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 1   |

  Scenario: Concurrent KHop varlen on ldbc
    When executing query:
      """
      /*+ SET_VAR(query_concurrency=4) */
      USE ldbc
      MATCH (a:Person{id: 1})-[:KNOWS]->{1,3}(d:Person)
      RETURN DISTINCT d.id AS id
      """
    Then the result should be, in any order:
      | id |
      | 1  |

  Scenario: Concurrent non-DISTINCT on ldbc
    When executing query:
      """
      /*+ SET_VAR(query_concurrency=4) */
      USE ldbc
      MATCH (a:Person{id: 1})-[:KNOWS]->(b:Person)-[:KNOWS]->(c:Person)
      RETURN c.id AS id
      """
    Then the result should be, in any order:
      | id |
      | 1  |

  Scenario: Concurrent COUNT DISTINCT path on ldbc
    When executing query:
      """
      /*+ SET_VAR(query_concurrency=4) */
      USE ldbc
      MATCH p = (a:Person{id: 1})-[:KNOWS]->(b:Person)
      RETURN COUNT(DISTINCT p) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 1   |

  Scenario: Concurrent DISTINCT node property on ldbc
    When executing query:
      """
      /*+ SET_VAR(query_concurrency=4) */
      USE ldbc
      MATCH (a:Person{id: 1})-[:KNOWS]->(b:Person)-[:KNOWS]->(c:Person)
      RETURN DISTINCT c.firstName AS name
      """
    Then the result should be, in any order:
      | name   |
      | "Kyle" |

  @sf01
  Scenario: DISTINCT property projection dedups final values on sf01
    When executing query:
      """
      USE sf01
      MATCH (v1:Post{id:343597487625})-[e:REPLY_OF]-(v2:Comment)
      RETURN DISTINCT v2.browserUsed AS browser
      ORDER BY browser
      """
    Then the result should be, in order:
      | browser             |
      | "Chrome"            |
      | "Firefox"           |
      | "Internet Explorer" |
    # FIX https://github.com/vesoft-inc/nebula-ng/issues/10732
    When executing query:
      """
      USE sf01 {
        MATCH (v:Person{id:26388279067671})-[e:KNOWS]->{1}(v1:Person)
        RETURN COLLECT(DISTINCT v1.birthday.year) as years
        NEXT
        FOR year IN years
        RETURN year
      }
      """
    Then the result should be, in any order:
      | year |
      | 1986 |
      | 1990 |
      | 1989 |
      | 1980 |
      | 1985 |
