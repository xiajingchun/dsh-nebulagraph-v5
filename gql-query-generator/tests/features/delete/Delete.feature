# Copyright (c) 2023 vesoft inc. All rights reserved.
# TODO(yuxuan.wang): The current execution plan is unable to generate an EdgeScan independently without generating NodeScan,
# making it hard to test whether there are dangling edges after DETACH DELETE. Test dangling edge when JoinElimination is ready.
Feature: Delete

  Scenario: DeleteData
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS ldbc_copy TYPED ldbc_type
      """
    Then the execution should be successful
    And graph "ldbc_copy" should be ready to use
    When executing query:
      """
      USE ldbc_copy
      INSERT (:City&Country&Continent{id:5, name:"Beijing", url:"https://beijing.com", kind:"city"}),
        (:City&Country&Continent{id:6, name:"Shanghai", url:"https://shanghai.com", kind:"city"}),
        (:City&Country&Continent{id:7, name:"Hangzhou", url:"https://hangzhou.com", kind:"city"}),
        (:City&Country&Continent{id:8, name:"Chongqing", url:"https://chongqing.com", kind:"city"}),
        (:Person{id:1, firstName:"Kyle", lastName:"cao", gender:"male", birthday:date("1990-01-01", "%Y-%m-%d"), creationDate:local_datetime("2021-01-01T10:00:40.213", "%Y-%m-%dT%H:%M:%S"), locationIP:"192.168.1", browserUsed:"Chrome", vec:VECTOR<3,float>([1,2,3])}),
        (:Person{id:2, firstName:"Tim", lastName:"Duncan", gender:"male", birthday:date("2001-04-25", "%Y-%m-%d"), creationDate:local_datetime("2021-01-01T11:00:40.213", "%Y-%m-%dT%H:%M:%S"), locationIP:"192.168.2", browserUsed:"IE", vec:VECTOR<3,float>([4,5,6])}),
        (:Person{id:3, firstName:"Ming", lastName:"Yao", gender:"male", birthday:date("1995-06-12", "%Y-%m-%d"), creationDate:local_datetime("2021-01-01T12:00:40.213", "%Y-%m-%dT%H:%M:%S"), locationIP:"192.168.3", browserUsed:"Firefox"}),
        (:Person{id:4, firstName:"Sophie", lastName:"Marceau", gender:"female", birthday:date("1999-12-24", "%Y-%m-%d"), creationDate:local_datetime("2031-01-01T10:00:40.213", "%Y-%m-%dT%H:%M:%S"), locationIP:"192.168.4", browserUsed:"Chrome", vec:VECTOR<3,float>([10,11,12])}),
        (:Forum{id:9, title:"forum1", creationDate:local_datetime("2021-01-01T10:00:40.213", "%Y-%m-%dT%H:%M:%S")}),
        (:Forum{id:10, title:"forum2", creationDate:local_datetime("2021-01-02T10:00:40.213", "%Y-%m-%dT%H:%M:%S")}),
        (:Forum{id:11, title:"forum3", creationDate:local_datetime("2021-01-03T10:00:40.213", "%Y-%m-%dT%H:%M:%S")}),
        (:Forum{id:12, title:"forum4", creationDate:local_datetime("2021-01-04T10:00:40.213", "%Y-%m-%dT%H:%M:%S")})
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc_copy
      MATCH (a:Person),(b:City&Country&Continent)
      WHERE a.id = b.id - 4
      INSERT (a)-[:IS_LOCATED_IN{}]->(b)
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc_copy
      MATCH (a:Person{id:4})
      INSERT (a)-[:KNOWS{creationDate:local_datetime("2021-01-01T10:00:40.213", "%Y-%m-%dT%H:%M:%S"), vec:VECTOR<3,float>([1,2,3])}]->(a)
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc_copy
      MATCH (a:Person),(b:Forum)
      WHERE a.id = b.id - 8
      INSERT (a)<-[:HAS_MEMBER{}]-(b),(a)<-[:HAS_MODERATOR{}]-(b)
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc_copy
      MATCH (a:Person{id:1})
      DELETE a
      """
    Then an Error should be raised: "[G1000]: Dependent object error, node 289107795020611585 can not be deleted, 3 edge connected"
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE ldbc_copy
      MATCH (a:Person{id:1})-[r]->(b)
      DELETE a
      """
    Then an Error should be raised: "[G1000]: Dependent object error, node 289107795020611585 can not be deleted, 3 edge connected"
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE ldbc_copy
      MATCH (a:Person{id:1})-[r]-(b)
      DELETE a,r
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 3     |
    When executing query:
      """
      USE ldbc_copy
      MATCH (a)-[r]->(b)
        where inner_product(a.vec, b.vec) = 365.0 and a.id <> 2 and inner_product(a.vec, r.vec) = 68.0
      RETURN count(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 1   |
    When executing query:
      """
      USE ldbc_copy
      MATCH (a)-[r]->(b)
        where inner_product(a.vec, b.vec) = 365.0 and a.id <> 2 and inner_product(a.vec, r.vec) = 68.0
      DELETE r
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE ldbc_copy
      MATCH (a:Person{id:4})-[e:KNOWS]-()
      RETURN e
      """
    Then the result should be, in any order:
      | e |
    When executing query:
      """
      USE ldbc_copy
      MATCH (a:Person)
      RETURN a.id
      """
    Then the result should be, in any order:
      | a.id |
      | 3    |
      | 4    |
      | 2    |
    When executing query:
      """
      USE ldbc_copy
      MATCH (a:Person{id:2})-[r:IS_LOCATED_IN]->(b)
      DELETE r
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE ldbc_copy
      MATCH (a:Person)-[r:IS_LOCATED_IN]->(b)
      return a.id, r, b.id
      """
    Then the result should be, in any order:
      | a.id | r    | b.id |
      | 3    | [{}] | 7    |
      | 4    | [{}] | 8    |
    When executing query:
      """
      USE ldbc_copy
      MATCH (a:Person{id:2})
      DELETE a
      """
    Then an Error should be raised: "[G1000]: Dependent object error, node 289293960378056705 can not be deleted, 2 edge connected"
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE ldbc_copy
      MATCH (a:Person{id:2})<-[r]-(b)
      DELETE r
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 2     |
    When executing query:
      """
      USE ldbc_copy
      MATCH (a:Person)<-[r:HAS_MEMBER|HAS_MODERATOR]-(b)
      return a.id, r, b.id
      """
    Then the result should be, in any order:
      | a.id | r    | b.id |
      | 3    | [{}] | 11   |
      | 3    | [{}] | 11   |
      | 4    | [{}] | 12   |
      | 4    | [{}] | 12   |
    When executing query:
      """
      USE ldbc_copy
      MATCH (a:Person{id:2})
      DELETE a
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE ldbc_copy
      MATCH (a:Person{id:3})
      DETACH DELETE a
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 3     |
    When executing query:
      """
      USE ldbc_copy
      MATCH (a:Person)
      RETURN a.id
      """
    Then the result should be, in any order:
      | a.id |
      | 4    |
    When executing query:
      """
      USE ldbc_copy
      MATCH (a:Person)-[r:HAS_MEMBER|HAS_MODERATOR|IS_LOCATED_IN]-(b)
      RETURN a.id,r,b.id
      """
    Then the result should be, in any order:
      | a.id | r    | b.id |
      | 4    | [{}] | 12   |
      | 4    | [{}] | 12   |
      | 4    | [{}] | 8    |
    When executing query:
      """
      USE ldbc_copy
      MATCH (a:Person)-[r]-(b)
      DELETE a,r,b
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 3     |
      | "num_affected_edges" | 3     |
    When executing query:
      """
      USE ldbc_copy
      MATCH (a)
      RETURN a
      """
    Then the result should be, in any order:
      | a                                                                           |
      | ({creationDate:DATETIME "2021-01-02T10:00:40.213000",id:10,title:"forum2"}) |
      | ({id:6,kind:"city",name:"Shanghai",url:"https://shanghai.com"})             |
      | ({creationDate:DATETIME "2021-01-03T10:00:40.213000",id:11,title:"forum3"}) |
      | ({creationDate:DATETIME "2021-01-01T10:00:40.213000",id:9,title:"forum1"})  |
      | ({id:5,kind:"city",name:"Beijing",url:"https://beijing.com"})               |
      | ({id:7,kind:"city",name:"Hangzhou",url:"https://hangzhou.com"})             |
    When executing query:
      """
      USE ldbc_copy
      MATCH (a)
      DELETE a
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 6     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE ldbc_copy
      MATCH (a)
      RETURN a
      """
    Then the result should be, in any order:
      | a |
    And drop the graph "ldbc_copy"

  Scenario: DeleteWithoutMatch
    When executing query:
      """
      USE ldbc
      DELETE v
      """
    Then an Error should be raised: "[42N18]: Invalid syntax, variable `v` not defined"

  Scenario: DeleteNullGraphElement
    When executing query:
      """
      USE ldbc
      MATCH (a:Person{id:1})
      OPTIONAL MATCH  (a)-[r:KNOWS]->(b{id:10})
      DELETE r,b
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |

  Scenario: UnsupportedDML
    When executing query:
      """
      USE ldbc
      MATCH (v)-[e]->()
      RETURN v,e limit 1
      NEXT
      USE ldbc
      DETACH DELETE v
      NEXT
      USE ldbc
      DELETE e
      """
    Then an Error should be raised: "[NT103]: Only one DML allowed, must be last, optionally followed by FINISH"

  Scenario: NotInCurrentGraph
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS ldbc_delete TYPED ldbc_type
      """
    Then the execution should be successful
    And graph "ldbc_delete" should be ready to use
    When executing query:
      """
      USE ldbc
      MATCH (a@Person{id:1})
      RETURN a
      NEXT
      USE ldbc_delete
      DETACH DELETE a
      """
    Then an Error should be raised:
      """
      [NR212]: `(289107795020611588@Person)` of graph `ldbc` is not in current working graph `ldbc_delete`
      """
    When executing query:
      """
      USE ldbc
      MATCH (a@Person{id:1})-[e@WORK_AT]->(b@Organisation{id:1})
      RETURN e
      NEXT
      USE ldbc_delete
      DELETE e
      """
    Then an Error should be raised:
      """
      [NR212]: `(289107795020611588)-[0@WORK_AT]->(290233694927454216)` of graph `ldbc` is not in current working graph `ldbc_delete`
      """
    And drop the graph "ldbc_delete"

  Scenario: DetachDelete Only
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS detach_delete_g TYPED ldbc_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE detach_delete_g
      FOR i IN range(1,20)
      INSERT (a@Person{id:i}), (b@Organisation{id:i})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 40    |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE detach_delete_g
      FOR i IN range(1, 20)
      MATCH (a@Person{id:i})
      MATCH (b@Organisation{id:i})
      INSERT (a)-[@STUDY_AT]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 20    |
    When executing query:
      """
      USE detach_delete_g
      FOR i IN range(1, 17)
      MATCH (a@Person{id:i})
      MATCH (b@Person{id:i + 1})
      MATCH (c@Person{id:i + 2})
      MATCH (d@Person{id:i + 3})
      INSERT
      (a)-[@FOLLOWS]->(b),
      (a)-[@FOLLOWS]->(c),
      (a)-[@FOLLOWS]->(d)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 51    |
    When executing query:
      """
      USE detach_delete_g
      MATCH (a@Person{id:1})
      DETACH DELETE a
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 4     |
    When executing query:
      """
      USE detach_delete_g
      MATCH (a@Person) WHERE a.id < 4
      DETACH DELETE a
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 2     |
      | "num_affected_edges" | 8     |
    When executing query:
      """
      USE detach_delete_g
      MATCH (a@Person)
      DETACH DELETE a
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 17    |
      | "num_affected_edges" | 59    |
    And drop the graph "detach_delete_g"

  Scenario: DeleteUndirectedEdge
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS delete_undirected_edge_type AS {
        NODE Person (LABELS Person {id INT64 PRIMARY KEY, name STRING}),
        EDGE Follow (Person)~[:Follow{prop INT, weight DOUBLE}]~(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS delete_undirected_edge TYPED delete_undirected_edge_type
      """
    Then the execution should be successful
    And graph "delete_undirected_edge" should be ready to use
    When executing query:
      """
      USE delete_undirected_edge
      INSERT (x:Person{id:1, name:"Alice"}),(y:Person{id:2, name:"Bob"}),(z:Person{id:3, name:"Charlie"})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 3     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE delete_undirected_edge
      MATCH (x:Person{id:1}),(y:Person{id:2}),(z:Person{id:3})
      INSERT (x)~[:Follow{prop:1, weight:1.5}]~(y), (y)~[:Follow{prop:2, weight:2.5}]~(z)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 2     |
    When executing query:
      """
      USE delete_undirected_edge
      MATCH (x)~[e]~(y)
      RETURN x.id, e.prop, e.weight, y.id
      """
    Then the result should be, in any order:
      | x.id | e.prop | e.weight | y.id |
      | 1    | 1      | 1.5      | 2    |
      | 3    | 2      | 2.5      | 2    |
      | 2    | 2      | 2.5      | 3    |
      | 2    | 1      | 1.5      | 1    |
    When executing query:
      """
      USE delete_undirected_edge
      MATCH (x:Person{id:1})~[r:Follow]~(y:Person{id:2})
      DELETE r
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE delete_undirected_edge
      MATCH (x)~[e]~(y)
      RETURN x.id, e.prop, e.weight, y.id
      """
    Then the result should be, in any order:
      | x.id | e.prop | e.weight | y.id |
      | 2    | 2      | 2.5      | 3    |
      | 3    | 2      | 2.5      | 2    |
    When executing query:
      """
      USE delete_undirected_edge
      MATCH (x:Person{id:2})
      DELETE x
      """
    Then an Error should be raised: "[G1000]: Dependent object error, node 288449535447924737 can not be deleted, 1 edge connected"
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE delete_undirected_edge
      MATCH (x:Person{id:2})
      DETACH DELETE x
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE delete_undirected_edge
      MATCH (x)~[e]~(y)
      RETURN x.id, e.prop, e.weight, y.id
      """
    Then the result should be, in any order:
      | x.id | e.prop | e.weight | y.id |
    When executing query:
      """
      USE delete_undirected_edge
      MATCH (n:Person)
      RETURN n.id, n.name
      """
    Then the result should be, in any order:
      | n.id | n.name    |
      | 1    | "Alice"   |
      | 3    | "Charlie" |
    And drop the graph "delete_undirected_edge"
    And drop the graph type "delete_undirected_edge_type"

  Scenario: DeleteUndirectedEdgeComplex
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS delete_undirected_complex_type AS {
        NODE Person (LABELS Person {id INT64 PRIMARY KEY, name STRING}),
        NODE Company (LABELS Company {id INT64 PRIMARY KEY, name STRING}),
        EDGE Follow (Person)~[:Follow{strength INT}]~(Person),
        EDGE WorksAt (Person)-[:WorksAt{since DATE}]->(Company)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS delete_undirected_complex TYPED delete_undirected_complex_type
      """
    Then the execution should be successful
    And graph "delete_undirected_complex" should be ready to use
    When executing query:
      """
      USE delete_undirected_complex
      INSERT (p1:Person{id:1, name:"Alice"}),
             (p2:Person{id:2, name:"Bob"}),
             (p3:Person{id:3, name:"Charlie"}),
             (c1:Company{id:100, name:"Tech Corp"})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 4     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE delete_undirected_complex
      MATCH (p1:Person{id:1}),(p2:Person{id:2}),(p3:Person{id:3}),(c1:Company{id:100})
      INSERT (p1)~[:Follow{strength:5}]~(p2),
             (p2)~[:Follow{strength:3}]~(p3),
             (p1)-[:WorksAt{since:date("2020-01-01")}]->(c1),
             (p2)-[:WorksAt{since:date("2021-06-15")}]->(c1)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 4     |
    When executing query:
      """
      USE delete_undirected_complex
      MATCH (p:Person)~[f:Follow]~(other:Person)
      WHERE p.id = 2
      DELETE f
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 2     |
    When executing query:
      """
      USE delete_undirected_complex
      MATCH (p:Person)~[f:Follow]~(other:Person)
      RETURN p.id, f.strength, other.id
      """
    Then the result should be, in any order:
      | p.id | f.strength | other.id |
    When executing query:
      """
      USE delete_undirected_complex
      MATCH (p:Person)-[w:WorksAt]->(c:Company)
      RETURN p.id, w.since, c.id
      """
    Then the result should be, in any order:
      | p.id | w.since           | c.id |
      | 1    | DATE "2020-01-01" | 100  |
      | 2    | DATE "2021-06-15" | 100  |
    When executing query:
      """
      USE delete_undirected_complex
      MATCH (p:Person{id:2})-[w:WorksAt]->(c:Company)
      DELETE w
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE delete_undirected_complex
      MATCH (p:Person{id:2})
      DELETE p
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE delete_undirected_complex
      MATCH (p:Person)-[w:WorksAt]->(c:Company)
      RETURN p.id, c.id
      """
    Then the result should be, in any order:
      | p.id | c.id |
      | 1    | 100  |
    And drop the graph "delete_undirected_complex"
    And drop the graph type "delete_undirected_complex_type"
