# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: ShortestPath

  Scenario: Shortest path
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS path_mode_graph_type AS {
      NODE Person (LABEL PERSON {id INT64 PRIMARY KEY}),
      EDGE KNOWS (Person)-[:KNOWS{knowsyears INT}]->(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS ACYCLIC_path_test typed path_mode_graph_type
      """
    Then the execution should be successful
    # insert test data: 1->2->3->4->5,2->1,5->2,2->5
    When executing query:
      """
      USE ACYCLIC_path_test
      INSERT (a:PERSON{id:1})-[:KNOWS{knowsyears:1002}]->(b:PERSON{id:2}),
      (b)-[:KNOWS{knowsyears:2003}]->(c:PERSON{id:3}),
      (c)-[:KNOWS{knowsyears:3004}]->(d:PERSON{id:4}),
      (d)-[:KNOWS{knowsyears:4005}]->(e:PERSON{id:5}),
      (b)-[:KNOWS{knowsyears:2001}]->(a),
      (e)-[:KNOWS{knowsyears:5002}]->(b),
      (b)-[:KNOWS{knowsyears:2005}]->(e)
      """
    Then the execution should be successful
    When executing query:
      """
      USE ACYCLIC_path_test
      MATCH p = ANY SHORTEST ACYCLIC (a:PERSON where a.id in list[1,5])-[:KNOWS]->{4}(c:PERSON{id:5})
      RETURN "ACYCLIC" as path_mode, a.id as src, 5 as dst, length(p) as _path_length
      """
    Then the result should be, in any order:
      | path_mode | src | dst | _path_length |
      | "ACYCLIC" | 1   | 5   | 4            |
    When executing query:
      """
      USE ACYCLIC_path_test
      MATCH p = ANY SHORTEST ACYCLIC (a:PERSON where a.id in list[1,5])-[:KNOWS]->{1,4}(c:PERSON{id:5})
      RETURN "ACYCLIC" as path_mode, a.id as src, 5 as dst, length(p) as _path_length
      """
    Then the result should be, in any order:
      | path_mode | src | dst | _path_length |
      | "ACYCLIC" | 1   | 5   | 2            |
    When executing query:
      """
      USE ACYCLIC_path_test
      MATCH p = ANY SHORTEST ACYCLIC (a:PERSON where a.id in list[1,5])-[:KNOWS]->{0,4}(c:PERSON{id:5})
      RETURN "ACYCLIC" as path_mode, a.id as src, 5 as dst, length(p) as _path_length
      """
    Then the result should be, in any order:
      | path_mode | src | dst | _path_length |
      | "ACYCLIC" | 1   | 5   | 2            |
      | "ACYCLIC" | 5   | 5   | 0            |
    # Shortest walk is pruned to shortest simple.
    When executing query:
      """
      EXPLAIN CBO USE ACYCLIC_path_test
      MATCH ANY SHORTEST (v1:PERSON)-[e1:KNOWS]->*(v2:PERSON)
      RETURN v1.id AS src_id
      LIMIT 10
      """
    Then the execution should be successful
    And the plan should contain "VarLenExpand(All, SIMPLE,"
    And drop the graph "ACYCLIC_path_test"
    And drop the graph type "path_mode_graph_type"

  Scenario: Shortest path for undirected edge
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS shortest_test_graph_type AS {
       NODE Person (LABEL Person {id INT PRIMARY KEY,name STRING}),
       EDGE PERSON_KNOWS_PERSON (Person)~[:KNOWS{creationDate ZONED DATETIME DEFAULT current_timestamp}]~(Person)
       }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH shortest_test_graph shortest_test_graph_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE shortest_test_graph INSERT (person_11@Person{id:11,name:"person_11"})~[@PERSON_KNOWS_PERSON{}]~(person_13@Person{id:13,name:"person_13"})
      """
    Then the execution should be successful
    When executing query:
      """
      USE shortest_test_graph MATCH p = ALL SHORTEST PATH (v1:Person{id:11})-[e]-(v2:Person{id:13}) RETURN v1.id,type(v2),v2.id,length(p)
      """
    Then the result should be, in any order:
      | v1.id | type(v2) | v2.id | length(p) |
      | 11    | "Person" | 13    | 1         |
    When executing query:
      """
      USE shortest_test_graph MATCH p = ALL SHORTEST PATH (v1:Person{id:11})-[e]-*(v2:Person{id:13}) RETURN v1.id,type(v2),v2.id,length(p)
      """
    Then the result should be, in any order:
      | v1.id | type(v2) | v2.id | length(p) |
      | 11    | "Person" | 13    | 1         |
    And drop the graph "shortest_test_graph"
    And drop the graph type "shortest_test_graph_type"

  Scenario: basic shortest path
    When executing query:
      """
      USE ldbc
      MATCH SHORTEST 1 PATH (person1:Person{id:1})<-[e:FOLLOWS]->*(person2:Person{id:3})
      RETURN collect(e) AS l GROUP BY ()
      NEXT
      USE ldbc
      RETURN CASE WHEN size(l) = 0 THEN -1 ELSE size(l[0]) END AS shortestPathLength
      """
    Then the result should be, in any order:
      | shortestPathLength |
      | 1                  |
    When executing query:
      """
      PARAMETERS $n=1
      USE ldbc
      MATCH SHORTEST $n PATH (person1:Person{id:1})<-[e:FOLLOWS]->*(person2:Person{id:3})
      RETURN collect(e) AS l GROUP BY ()
      NEXT
      USE ldbc
      RETURN CASE WHEN size(l) = 0 THEN -1 ELSE size(l[0]) END AS shortestPathLength
      """
    Then the result should be, in any order:
      | shortestPathLength |
      | 1                  |
    When executing query:
      """
      PARAMETERS $n="a"
      USE ldbc
      MATCH SHORTEST $n PATH (person1:Person{id:1})<-[e:FOLLOWS]->*(person2:Person{id:3})
      RETURN collect(e) AS l GROUP BY ()
      NEXT
      USE ldbc
      RETURN CASE WHEN size(l) = 0 THEN -1 ELSE size(l[0]) END AS shortestPathLength
      """
    Then an Error should be raised: "[NS214]: Invalid type NUMBER OF PATHS expression type: `STRING`, expect `unsigned integer`"
    When executing query:
      """
      USE ldbc
      MATCH ANY 1 TRAIL (person1:Person{id:1})<-[e:FOLLOWS]->*(person2:Person{id:3})
      RETURN collect(e) AS l GROUP BY ()
      NEXT
      USE ldbc
      RETURN CASE WHEN size(l) = 0 THEN -1 ELSE size(l[0]) END AS shortestPathLength
      """
    Then the execution should be successful

  # shortest group search is not supported. The following test case may be not correct.
  @skip
  Scenario: Shortest group syntax
    When executing query:
      """
      USE ldbc
      MATCH SHORTEST 1 PATH GROUPS (person1:Person{id:1})<-[e:FOLLOWS]->*(person2:Person{id:3})
      RETURN collect(e) AS l GROUP BY ()
      NEXT
      RETURN CASE WHEN size(l) = 0 THEN -1 ELSE size(l[0]) END AS shortestPathLength
      """
    Then the result should be, in any order:
      | shortestPathLength |
      | 1                  |
    When executing query:
      """
      PARAMETERS $n=2
      USE ldbc
      MATCH SHORTEST $n PATH GROUPS (person1:Person{id:1})<-[e:FOLLOWS]->*(person2:Person{id:3})
      RETURN collect(e) AS l GROUP BY ()
      NEXT
      RETURN CASE WHEN size(l) = 0 THEN -1 ELSE size(l[0]) END AS shortestPathLength
      """
    Then the result should be, in any order:
      | shortestPathLength |
      | 1                  |
    When executing query:
      """
      PARAMETERS $n="nebula"
      USE ldbc
      MATCH SHORTEST $n PATH GROUPS (person1:Person{id:1})<-[e:FOLLOWS]->*(person2:Person{id:3})
      RETURN collect(e) AS l GROUP BY ()
      NEXT
      RETURN CASE WHEN size(l) = 0 THEN -1 ELSE size(l[0]) END AS shortestPathLength
      """
    Then an Error should be raised: "[NS215]: Invalid type NUMBER OF GROUPS expression type: `STRING`, expect `unsigned integer`"

  @sf01
  Scenario: complex shortest path
    # BiBFS
    When executing query:
      """
      use sf01
      match p= all shortest (v1:Person{id:318})-[e:KNOWS]->{1,3}(v2:Person where v2.id<100)
      return count(*) as cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 0   |
    And the plan should contain "BiBFS"
    When executing query:
      """
      use sf01
      match p= all shortest (v:Person where v.id > 100)<-[e:KNOWS]->{1,3}(v:Person where v.id <= 600)
      return count(*) as cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 618 |
    And the plan should contain "BiBFS"
    When executing query:
      """
      use sf01 match p = all shortest path (v:Person{id:318})->{1,2}(v) return count(*)
      """
    Then the result should be, in any order:
      | count(*) |
      | 2        |
    When executing query:
      """
      use sf01 match p = all shortest path (v:Person)->{1,2}(v{id:318}) return count(*)
      """
    Then the result should be, in any order:
      | count(*) |
      | 2        |
    When executing query:
      """
      use sf01
      match p = (v:Person{id:318})-[e:KNOWS]->{1,3}(v2:Person where v2.id<100) return count(*)
      """
    Then the result should be, in any order:
      | count(*) |
      | 0        |
    When executing query:
      """
      use sf01
      match p = all shortest path(v1:Person{id:318})-[e:KNOWS]->{1,3}(v2:Person where v2.id<100)
      return count(*)
      """
    Then the result should be, in any order:
      | count(*) |
      | 0        |
    When executing query:
      """
      USE sf01 {
      MATCH (p:Person{id : 24189255811707}), (friend:Person{firstName : "Jun"})
        WHERE p<>friend
      MATCH path = ANY SHORTEST PATH (p:Person)<-[:KNOWS]->{1,3}(friend:Person)
      RETURN count(path) as cnt
      }
      """
    Then the result should be, in any order:
      | cnt |
      | 20  |
    And the plan should contain "BiBFS"
    When executing query:
      """
      USE sf01 {
        MATCH (p:Person{id : 24189255811707})
        MATCH path = ANY SHORTEST PATH (p2:Person{id:583})<-[:KNOWS]->{1,3}(p)
        RETURN count(path) as cnt
      }
      """
    Then the result should be, in any order:
      | cnt |
      | 1   |
    When executing query:
      """
      USE sf01 {
        MATCH (p:Person{id : 24189255811707})
        MATCH path = ANY SHORTEST PATH (p)<-[:KNOWS]->{1,3}(p)
        RETURN count(path) as cnt
      }
      """
    Then the result should be, in any order:
      | cnt |
      | 1   |
    When executing query:
      """
      USE sf01 {
        MATCH p = ANY SHORTEST PATH
        (src:Person WHERE src.id IN [583,65,870,26388279067923])
        -[e:KNOWS where e.creationDate is not null ]->*
        (dst:Person WHERE dst.id IN [583,65,870,26388279067923])
        WHERE src <> dst
        RETURN src.id, dst.id, length(p) AS path_length
      }
      """
    Then the result should be, in any order:
      | src.id | dst.id         | path_length |
      | 870    | 26388279067923 | 2           |
      | 583    | 26388279067923 | 2           |
    # Fallback to Recursive+WorkTableScan
    When executing query:
      """
      use sf01 match p = SHORTEST 1
      PATH(src_person:Person{id:512})<-[e1:HAS_CREATOR]-(m:`Comment`)-[e2:REPLY_OF]->*(dst_post:`Post`)
      return length(p),src_person.id,dst_post.id
      """
    Then the execution should be successful
    And the plan should contain "Recursive"
    And the plan should not contain "BiBFS"
    # Edge filter pushdown on shortest path
    When executing query:
      """
      use sf01 MATCH p = ANY SHORTEST (person1:Person{id:2199023256586})<-[e:KNOWS where e.creationDate >= datetime "2010-04-04T12:27:43.212000"]->*(person2:Person{id:32985348833679}) return length(p)
      """
    Then the result should be, in any order:
      | length(p) |
      | 3         |
    And the plan should contain "BiBFS"
    # Sample pushdown on shortest path
    When executing query:
      """
      USE sf01 MATCH p = ALL SHORTEST PATH (v1:Person{id:512})-[e SAMPLE 1]->*(v2:Person{id:583}) RETURN length(p)
      """
    Then the execution should be successful
