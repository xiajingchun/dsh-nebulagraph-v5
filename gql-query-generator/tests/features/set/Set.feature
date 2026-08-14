# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: SetStatement

  Scenario: SetPropertyItem
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS test_type AS {
        NODE Person (LABEL Person {primary_id INT PRIMARY KEY, id INT, firstName STRING, lastName STRING, gender STRING}),
        NODE Organisation (LABELS University&Company {primary_id INT PRIMARY KEY, id INT, kind STRING, name STRING, url STRING}),
        EDGE WORK_AT (Person)-[:WORK_AT{workFrom INT, year INT}]->(Organisation)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS test_set TYPED test_type
      """
    Then the execution should be successful
    And graph "test_set" should be ready to use
    When executing query:
      """
      USE test_set
      INSERT
      (o_a@Organisation{primary_id:1, id:1, kind:"1", name:"org1", url:"https://org1.com"}),
      (o_b@Organisation{primary_id:2, id:2, kind:"2", name:"org2", url:"https://org2.com"}),
      (o_c@Organisation{primary_id:3, id:3, kind:"3", name:"org3", url:"https://org3.com"}),
      (o_d@Organisation{primary_id:4, id:4, kind:"4", name:"org4", url:"https://org4.com"}),
      (p_a@Person{primary_id:1, id:1, firstName:"Kyle", lastName:"cao", gender:"male"}),
      (p_b@Person{primary_id:2, id:2, firstName:"Tim", lastName:"Duncan", gender:"male"}),
      (p_c@Person{primary_id:3, id:3, firstName:"Ming", lastName:"Yao", gender:"male"}),
      (p_d@Person{primary_id:4, id:4, firstName:"Sophie", lastName:"Marceau", gender:"female"}),
      (p_a)-[@WORK_AT{workFrom:1, year:1}]->(o_a),
      (p_b)-[@WORK_AT{workFrom:2, year:2}]->(o_b),
      (p_c)-[@WORK_AT{workFrom:3, year:3}]->(o_c)
      """
    Then the execution should be successful
    When executing query:
      """
      USE test_set
      MATCH (v:Person)
      RETURN v.id
      """
    Then the result should be, in any order:
      | v.id |
      | 1    |
      | 3    |
      | 2    |
      | 4    |
    When executing query:
      """
      USE test_set
      MATCH (v:Person)
      SET v.id = v.id+5
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 4     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE test_set
      MATCH (v:Person)
      RETURN v
      """
    Then the result should be, in any order:
      | v                                                                           |
      | ({firstName:"Sophie",gender:"female",id:9,lastName:"Marceau",primary_id:4}) |
      | ({firstName:"Kyle",gender:"male",id:6,lastName:"cao",primary_id:1})         |
      | ({firstName:"Tim",gender:"male",id:7,lastName:"Duncan",primary_id:2})       |
      | ({firstName:"Ming",gender:"male",id:8,lastName:"Yao",primary_id:3})         |
    When executing query:
      """
      USE test_set
      MATCH (v:Person)
      SET v.id="str"
      """
    Then an Error should be raised: "[NS208]: The type of `\"str\"(STRING)` cannot be assigned to `v.id(INT64)`"
    When executing query:
      """
      USE test_set
      MATCH (v:Person)
      SET v.id=List[1,2,3]
      """
    Then an Error should be raised: "[NS208]: The type of `LIST[1, 2, 3](LIST<INT32>)` cannot be assigned to `v.id(INT64)`"
    When executing query:
      """
      USE test_set
      MATCH (v:Person)
      SET v.firstName=v.lastName,v.id=v.id+5
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 4     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE test_set
      MATCH (v:Person)
      RETURN v
      """
    Then the result should be, in any order:
      | v                                                                             |
      | ({firstName:"Duncan",gender:"male",id:12,lastName:"Duncan",primary_id:2})     |
      | ({firstName:"Marceau",gender:"female",id:14,lastName:"Marceau",primary_id:4}) |
      | ({firstName:"Yao",gender:"male",id:13,lastName:"Yao",primary_id:3})           |
      | ({firstName:"cao",gender:"male",id:11,lastName:"cao",primary_id:1})           |
    When executing query:
      """
      USE test_set
      MATCH (v:Person)-[e:WORK_AT]->(u)
      SET e.workFrom=1
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 3     |
    When executing query:
      """
      USE test_set
      MATCH (v:Person)-[e:WORK_AT]->(u)
      RETURN e
      """
    Then the result should be, in any order:
      | e                     |
      | [{workFrom:1,year:1}] |
      | [{workFrom:1,year:3}] |
      | [{workFrom:1,year:2}] |
    When executing query:
      """
      USE test_set
      MATCH (v:Person)-[e:WORK_AT]->(u)
      SET e.workFrom=v.id,v.lastName="x"
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 3     |
      | "num_affected_edges" | 3     |
    When executing query:
      """
      USE test_set
      MATCH (v:Person)-[e:WORK_AT]->(u)
      RETURN e,v
      """
    Then the result should be, in any order:
      | e                      | v                                                                    |
      | [{workFrom:13,year:3}] | ({firstName:"Yao",gender:"male",id:13,lastName:"x",primary_id:3})    |
      | [{workFrom:11,year:1}] | ({firstName:"cao",gender:"male",id:11,lastName:"x",primary_id:1})    |
      | [{workFrom:12,year:2}] | ({firstName:"Duncan",gender:"male",id:12,lastName:"x",primary_id:2}) |
    When executing query:
      """
      USE test_set
      MATCH (v)-[e:WORK_AT]-(u)
      RETURN e
      """
    Then the result should be, in any order:
      | e                      |
      | [{workFrom:11,year:1}] |
      | [{workFrom:11,year:1}] |
      | [{workFrom:12,year:2}] |
      | [{workFrom:12,year:2}] |
      | [{workFrom:13,year:3}] |
      | [{workFrom:13,year:3}] |
    When executing query:
      """
      USE test_set
      MATCH (v:Person{primary_id:1})
      SET v.primary_id = 2
      """
    Then an Error should be raised:
      """
      [NT105]: Set property `primary_id` failed. `v` may contain node type `Person`, whose primary key contains property `primary_id`
      """
    When executing query:
      """
      USE test_set
      MATCH (v:Person{primary_id:1})
      SET v.id = 2
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE test_set
      MATCH (v:Person{primary_id:1})
      RETURN v
      """
    Then the result should be, in any order:
      | v                                                                |
      | ({firstName:"cao",gender:"male",id:2,lastName:"x",primary_id:1}) |
    And drop the graph "test_set"
    And drop the graph type "test_type"

  Scenario: MultipleVariablesIntersections
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS test_multi_variable_type AS {
        NODE Person (LABEL Person {id INT PRIMARY KEY, age INT, firstName STRING, lastName STRING}),
        EDGE Follow (Person)-[LABEL Follow {followness INT, likeness INT}]->(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS test_set_1 TYPED test_multi_variable_type
      """
    Then the execution should be successful
    And graph "test_set_1" should be ready to use
    When executing query:
      """
      USE test_set_1
      INSERT
      (:Person{id:1, firstName:"Kyle", lastName:"cao",age:21}),
      (:Person{id:2, firstName:"Tim", lastName:"Duncan",age:22}),
      (:Person{id:3, firstName:"Ming", lastName:"Yao",age:23}),
      (:Person{id:4, firstName:"Sophie", lastName:"Marceau",age:24})
      """
    Then the execution should be successful
    When executing query:
      """
      USE test_set_1
      MATCH (a:Person),(b:Person)
      WHERE a.id < b.id
      INSERT (a)-[r:Follow{followness:a.id, likeness:b.id}]->(b)
      """
    Then the execution should be successful
    When executing query:
      """
      USE test_set_1
      MATCH (a{id:1}),(b{id:1})
      SET a.firstName="San",b.lastName="Zhang"
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE test_set_1
      MATCH (a{id:1})
      RETURN a
      """
    Then the result should be, in any order:
      | a                                                |
      | ({age:21,firstName:"San",id:1,lastName:"Zhang"}) |
    When executing query:
      """
      USE test_set_1
      MATCH (a)-[r]->(b)
      WHERE b.id = a.id + 1
      SET a.firstName="Start",b.lastName="End"
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 4     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE test_set_1
      MATCH (a)
      RETURN a
      """
    Then the result should be, in any order:
      | a                                                  |
      | ({age:23,firstName:"Start",id:3,lastName:"End"})   |
      | ({age:22,firstName:"Start",id:2,lastName:"End"})   |
      | ({age:21,firstName:"Start",id:1,lastName:"Zhang"}) |
      | ({age:24,firstName:"Sophie",id:4,lastName:"End"})  |
    When executing query:
      """
      USE test_set_1
      MATCH (a{id:1})-[r]->(b{id:2})
      MATCH (c{id:2})<-[e]-(q{id:1})
      SET r.followness=5,e.likeness=5
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE test_set_1
      MATCH (a{id:1})-[r]->(b{id:2})
      RETURN r
      """
    Then the result should be, in any order:
      | r                           |
      | [{followness:5,likeness:5}] |
    When executing query:
      """
      USE test_set_1
      MATCH (a{id:2})<-[r]-(b{id:1})
      RETURN r
      """
    Then the result should be, in any order:
      | r                           |
      | [{followness:5,likeness:5}] |
    When executing query:
      """
      USE test_set_1
      MATCH (a{id:2})<-[r]-(b{id:1})
      RETURN r
      """
    Then the result should be, in any order:
      | r                           |
      | [{followness:5,likeness:5}] |
    And drop the graph "test_set_1"
    And drop the graph type "test_multi_variable_type"

  Scenario: SetMultiTypes
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS set_multi_types AS {
        NODE Person (LABELS Person {pid INT PRIMARY KEY, score INT32, gender BOOL}),
        NODE PersonTest (LABELS Person&Test {pid INT PRIMARY KEY, score INT32}),
        NODE PersonWithoutProp (LABELS PersonWithoutProp {pid INT PRIMARY KEY}),
        EDGE Follow (Person)-[LABELS Follow {followness FLOAT, likeness INT}]->(Person),
        EDGE FollowTest (Person)-[LABELS Follow&Test {followness FLOAT}]->(Person),
        EDGE FollowWithoutProp (Person)-[LABELS FollowWithoutProp]->(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS set_graph TYPED set_multi_types
      """
    Then the execution should be successful
    And graph "set_graph" should be ready to use
    When executing query:
      """
      USE set_graph
      FOR i in  range(1,5)
      INSERT (:Person{pid:i,score:CAST (i as INT32),gender:true}),
      (:Person&Test{pid:i+5,score:CAST (i+5 as INT32)})
      """
    Then the execution should be successful
    When executing query:
      """
      USE set_graph
      MATCH (a:Person&!Test), (b:Person&!Test)
      WHERE a.pid < b.pid
      INSERT (a)-[:Follow{followness:CAST (a.pid as FLOAT),likeness:a.pid}]->(b),
      (a)-[:Follow&Test{followness:CAST (a.pid as FLOAT)}]->(b)
      """
    Then the execution should be successful
    When executing query:
      """
      USE set_graph
      MATCH (a:Person)
      SET a.score = a.score + 10
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 10    |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE set_graph
      MATCH (a:Person)
      RETURN a
      """
    Then the result should be, in any order:
      | a                              |
      | ({gender:true,pid:5,score:15}) |
      | ({pid:8,score:18})             |
      | ({pid:9,score:19})             |
      | ({gender:true,pid:3,score:13}) |
      | ({gender:true,pid:2,score:12}) |
      | ({gender:true,pid:1,score:11}) |
      | ({pid:6,score:16})             |
      | ({gender:true,pid:4,score:14}) |
      | ({pid:7,score:17})             |
      | ({pid:10,score:20})            |
    When executing query:
      """
      USE set_graph
      MATCH (a:Person)-[e:Follow]->(b:Person)
      SET e.followness = 1.0
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 20    |
    When executing query:
      """
      USE set_graph
      MATCH (a:Person)-[e:Follow]->(b:Person)
      RETURN e
      """
    Then the result should be, in any order:
      | e                             |
      | [{followness:1.0,likeness:1}] |
      | [{followness:1.0}]            |
      | [{followness:1.0}]            |
      | [{followness:1.0,likeness:2}] |
      | [{followness:1.0,likeness:1}] |
      | [{followness:1.0}]            |
      | [{followness:1.0}]            |
      | [{followness:1.0,likeness:3}] |
      | [{followness:1.0}]            |
      | [{followness:1.0,likeness:2}] |
      | [{followness:1.0,likeness:1}] |
      | [{followness:1.0}]            |
      | [{followness:1.0}]            |
      | [{followness:1.0,likeness:4}] |
      | [{followness:1.0}]            |
      | [{followness:1.0,likeness:3}] |
      | [{followness:1.0}]            |
      | [{followness:1.0,likeness:2}] |
      | [{followness:1.0,likeness:1}] |
      | [{followness:1.0}]            |
    When executing query:
      """
      USE set_graph
      MATCH (a:Person|PersonWithoutProp)
      SET a.score = a.score + 10
      """
    Then an Error should be raised:"[NS240]: Set property `score` failed. `a` may contain type `PersonWithoutProp`, which does not have property `score`"
    When executing query:
      """
      USE set_graph
      MATCH (a:Person)-[e:Follow|FollowWithoutProp]->(b:Person)
      SET e.followness = 1.0
      """
    Then an Error should be raised:"[NS240]: Set property `followness` failed. `e` may contain type `FollowWithoutProp`, which does not have property `followness`"
    And drop the graph "set_graph"
    And drop the graph type "set_multi_types"

  Scenario: SetNullValue
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS set_null_types AS {
        NODE Person (LABELS Person {pid INT PRIMARY KEY, score INT NOT NULL}),
        EDGE Follow (Person)-[LABELS Follow {followness DOUBLE NOT NULL}]->(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS set_null TYPED set_null_types
      """
    Then the execution should be successful
    And graph "set_null" should be ready to use
    When executing query:
      """
      USE set_null
      INSERT (:Person{pid:1,score:1})-[:Follow{followness:1.0}]->(:Person{pid:2,score:1})
      """
    Then the execution should be successful
    When executing query:
      """
      USE set_null
      MATCH (a:Person)
      SET a.score = null
      """
    Then an Error should be raised: "[ND008]: Property `score` of type `Person` is not nullable"
    When executing query:
      """
      USE set_null
      MATCH (a:Person)-[e:Follow]-(b)
      SET e.followness = null
      """
    Then an Error should be raised: "[ND008]: Property `followness` of type `Follow` is not nullable"
    And drop the graph "set_null"
    And drop the graph type "set_null_types"

  Scenario: SetMultiEdgeKey
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS set_multiedge_type AS {
        NODE Person (LABELS Person {pid INT PRIMARY KEY, score INT}),
        EDGE Follow (Person)-[LABELS Follow {followness INT, likeness INT, MULTIEDGE KEY(followness, likeness)}]->(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS set_multiedge TYPED set_multiedge_type
      """
    Then the execution should be successful
    And graph "set_multiedge" should be ready to use
    When executing query:
      """
      USE set_multiedge
      INSERT (:Person{pid:1,score:1})-[:Follow{followness:10, likeness:20}]->(:Person{pid:2,score:1})
      """
    Then the execution should be successful
    When executing query:
      """
      USE set_multiedge
      MATCH (a:Person)-[e:Follow]-(b)
      SET e.followness = 15
      """
    Then an Error should be raised:
      """
      [NT107]: Set property `followness` failed. `e` may contain edge type `Follow`, whose multiedge key contains property `followness`
      """
    When executing query:
      """
      USE set_multiedge
      MATCH (a:Person)-[e:Follow]-(b)
      SET e.likeness = 25
      """
    Then an Error should be raised:
      """
      [NT107]: Set property `likeness` failed. `e` may contain edge type `Follow`, whose multiedge key contains property `likeness`
      """
    And drop the graph "set_multiedge"
    And drop the graph type "set_multiedge_type"

  Scenario: SetWithoutMatch
    When executing query:
      """
      USE ldbc
      SET v.name=null
      """
    Then an Error should be raised: "[42N18]: Invalid syntax, variable `v` not defined"

  Scenario: SetNullGraphElement
    When executing query:
      """
      USE ldbc
      MATCH (a:Person{id:1})
      OPTIONAL MATCH (a)-[r:KNOWS&WORK_AT]->(b)
      SET r.name = null, b.name = null
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `-[r:(KNOWS) & (WORK_AT)]->` was found"

  Scenario: SetImplicitCast
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS set_cast_type AS {
        NODE Person (LABELS Person {pk INT PRIMARY KEY, prop_int INT8, prop_uint UINT8, prop_float FLOAT})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS set_cast TYPED set_cast_type
      """
    Then the execution should be successful
    And graph "set_cast" should be ready to use
    When executing query:
      """
      USE set_cast
      INSERT (:Person{pk:1,prop_int:1,prop_uint:2,prop_float:2.0})
      """
    Then the execution should be successful
    When executing query:
      """
      USE set_cast
      MATCH (a:Person)
      SET a.prop_int = 1, a.prop_uint = 0, a.prop_float = 0.0
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE set_cast
      MATCH (a:Person)
      SET a.prop_int = 10000
      """
    Then an Error should be raised: "[NS208]: The type of `10000(INT32)` cannot be assigned to `a.prop_int(INT8)`"
    When executing query:
      """
      USE set_cast
      MATCH (a:Person)
      SET a.prop_uint = -1
      """
    Then an Error should be raised: "[NS208]: The type of `-1(INT32)` cannot be assigned to `a.prop_uint(UINT8)`"
    And drop the graph "set_cast"
    And drop the graph type "set_cast_type"

  Scenario: NotInCurrentGraph
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS ldbc_set TYPED ldbc_type
      """
    Then the execution should be successful
    And graph "ldbc_set" should be ready to use
    When executing query:
      """
      USE ldbc
      MATCH (a@Person{id:1})
      RETURN a
      NEXT
      USE ldbc_set
      SET a.lastName = "L1"
      """
    Then an Error should be raised:
      """
      [NR212]: `(289107795020611588@Person)` of graph `ldbc` is not in current working graph `ldbc_set`
      """
    When executing query:
      """
      USE ldbc
      MATCH (a@Person{id:1})-[e@WORK_AT]->(b@Organisation{id:1})
      RETURN e
      NEXT
      USE ldbc_set
      SET e.workFrom = 1
      """
    Then an Error should be raised:
      """
      [NR212]: `(289107795020611588)-[0@WORK_AT]->(290233694927454216)` of graph `ldbc` is not in current working graph `ldbc_set`
      """
    And drop the graph "ldbc_set"

  Scenario: PropertyNotFound
    When executing query:
      """
      USE ldbc
      MATCH (a@Person)
      SET a.name = "test"
      """
    Then an Error should be raised: "[NS240]: Set property `name` failed. `a` may contain type `Person`, which does not have property `name`"
    When executing query:
      """
      USE ldbc
      MATCH (a)-[e@LIKES_1]->(b)
      SET e.test = "test"
      """
    Then an Error should be raised: "[NS240]: Set property `test` failed. `e` may contain type `LIKES_1`, which does not have property `test`"

  Scenario: SetUndirectedEdge
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS set_undirected_edge_type AS {
        NODE Person (LABELS Person {id INT64 PRIMARY KEY, name STRING, age INT}),
        EDGE Follow (Person)~[:Follow{prop INT, weight DOUBLE, strength INT}]~(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS set_undirected_edge TYPED set_undirected_edge_type
      """
    Then the execution should be successful
    And graph "set_undirected_edge" should be ready to use
    When executing query:
      """
      USE set_undirected_edge
      INSERT (x:Person{id:1, name:"Alice", age:25}),(y:Person{id:2, name:"Bob", age:30}),(z:Person{id:3, name:"Charlie", age:35})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 3     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE set_undirected_edge
      MATCH (x:Person{id:1}),(y:Person{id:2}),(z:Person{id:3})
      INSERT (x)~[:Follow{prop:1, weight:1.5, strength:10}]~(y), (y)~[:Follow{prop:2, weight:2.5, strength:20}]~(z)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 2     |
    When executing query:
      """
      USE set_undirected_edge
      MATCH (x)~[e]~(y)
      RETURN x.id, e.prop, e.weight, e.strength, y.id
      """
    Then the result should be, in any order:
      | x.id | e.prop | e.weight | e.strength | y.id |
      | 1    | 1      | 1.5      | 10         | 2    |
      | 2    | 1      | 1.5      | 10         | 1    |
      | 2    | 2      | 2.5      | 20         | 3    |
      | 3    | 2      | 2.5      | 20         | 2    |
    When executing query:
      """
      USE set_undirected_edge
      MATCH (x:Person{id:1})~[e:Follow]~(y:Person{id:2})
      SET e.prop = 5
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE set_undirected_edge
      MATCH (x:Person{id:1})~[e:Follow]~(y:Person{id:2})
      RETURN e.prop, e.weight, e.strength
      """
    Then the result should be, in any order:
      | e.prop | e.weight | e.strength |
      | 5      | 1.5      | 10         |
    When executing query:
      """
      USE set_undirected_edge
      MATCH (x)~[e:Follow]~(y)
      WHERE e.prop = 2
      SET e.weight = 3.0, e.strength = 25
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE set_undirected_edge
      MATCH (x)~[e]~(y)
      RETURN x.id, e.prop, e.weight, e.strength, y.id
      """
    Then the result should be, in any order:
      | x.id | e.prop | e.weight | e.strength | y.id |
      | 1    | 5      | 1.5      | 10         | 2    |
      | 2    | 5      | 1.5      | 10         | 1    |
      | 2    | 2      | 3.0      | 25         | 3    |
      | 3    | 2      | 3.0      | 25         | 2    |
    When executing query:
      """
      USE set_undirected_edge
      MATCH (x:Person)~[e:Follow]~(y:Person)
      WHERE x.id < y.id
      SET x.age = x.age + 1, e.prop = e.prop + 10
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 2     |
      | "num_affected_edges" | 2     |
    When executing query:
      """
      USE set_undirected_edge
      MATCH (x:Person)
      RETURN x.id, x.name, x.age
      """
    Then the result should be, in any order:
      | x.id | x.name    | x.age |
      | 1    | "Alice"   | 26    |
      | 2    | "Bob"     | 31    |
      | 3    | "Charlie" | 35    |
    When executing query:
      """
      USE set_undirected_edge
      MATCH (x)~[e]~(y)
      RETURN x.id, e.prop, e.weight, e.strength, y.id
      """
    Then the result should be, in any order:
      | x.id | e.prop | e.weight | e.strength | y.id |
      | 1    | 15     | 1.5      | 10         | 2    |
      | 2    | 15     | 1.5      | 10         | 1    |
      | 2    | 12     | 3.0      | 25         | 3    |
      | 3    | 12     | 3.0      | 25         | 2    |
    And drop the graph "set_undirected_edge"
    And drop the graph type "set_undirected_edge_type"

  Scenario: SetUndirectedEdgeComplex
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS set_undirected_complex_type AS {
        NODE Person (LABELS Person {id INT64 PRIMARY KEY, name STRING, score DOUBLE}),
        NODE Company (LABELS Company {id INT64 PRIMARY KEY, name STRING, revenue DOUBLE}),
        EDGE Follow (Person)~[:Follow{strength INT, since DATE}]~(Person),
        EDGE WorksAt (Person)-[:WorksAt{position STRING, salary DOUBLE}]->(Company)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS set_undirected_complex TYPED set_undirected_complex_type
      """
    Then the execution should be successful
    And graph "set_undirected_complex" should be ready to use
    When executing query:
      """
      USE set_undirected_complex
      INSERT (p1:Person{id:1, name:"Alice", score:85.5}),
             (p2:Person{id:2, name:"Bob", score:90.0}),
             (p3:Person{id:3, name:"Charlie", score:78.5}),
             (c1:Company{id:100, name:"Tech Corp", revenue:1000000.0})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 4     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE set_undirected_complex
      MATCH (p1:Person{id:1}),(p2:Person{id:2}),(p3:Person{id:3}),(c1:Company{id:100})
      INSERT (p1)~[:Follow{strength:5, since:date("2020-01-01")}]~(p2),
             (p2)~[:Follow{strength:3, since:date("2021-06-15")}]~(p3),
             (p1)-[:WorksAt{position:"Engineer", salary:80000.0}]->(c1),
             (p2)-[:WorksAt{position:"Manager", salary:95000.0}]->(c1)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 4     |
    When executing query:
      """
      USE set_undirected_complex
      MATCH (p:Person)~[f:Follow]~(other:Person)
      WHERE p.id = 2
      SET f.strength = f.strength + 5
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 2     |
    When executing query:
      """
      USE set_undirected_complex
      MATCH (p:Person)~[f:Follow]~(other:Person)
      RETURN p.id, f.strength, f.since, other.id
      """
    Then the result should be, in any order:
      | p.id | f.strength | f.since           | other.id |
      | 1    | 10         | DATE "2020-01-01" | 2        |
      | 2    | 10         | DATE "2020-01-01" | 1        |
      | 2    | 8          | DATE "2021-06-15" | 3        |
      | 3    | 8          | DATE "2021-06-15" | 2        |
    When executing query:
      """
      USE set_undirected_complex
      MATCH (p:Person)-[w:WorksAt]->(c:Company)
      SET w.salary = w.salary * 1.1
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 2     |
    When executing query:
      """
      USE set_undirected_complex
      MATCH (c:Company{id:100})
      SET c.revenue = c.revenue + 50000.0
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE set_undirected_complex
      MATCH (p:Person)-[w:WorksAt]->(c:Company)
      RETURN p.id, w.position, floor(w.salary), c.revenue
      """
    Then the result should be, in any order:
      | p.id | w.position | floor(w.salary) | c.revenue |
      | 2    | "Manager"  | 104500.0        | 1050000.0 |
      | 1    | "Engineer" | 88000.0         | 1050000.0 |
    When executing query:
      """
      USE set_undirected_complex
      MATCH (p:Person)~[f:Follow]~(other:Person), (p)-[w:WorksAt]->(c:Company)
      WHERE p.id = 1
      SET p.score = p.score + 5.0, f.since = date("2022-01-01")
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE set_undirected_complex
      MATCH (p:Person{id:1})
      RETURN p.score
      """
    Then the result should be, in any order:
      | p.score |
      | 90.5    |
    When executing query:
      """
      USE set_undirected_complex
      MATCH (p:Person{id:1})~[f:Follow]~(other:Person)
      RETURN f.since
      """
    Then the result should be, in any order:
      | f.since           |
      | DATE "2022-01-01" |
    And drop the graph "set_undirected_complex"
    And drop the graph type "set_undirected_complex_type"

  Scenario: SetPropertyValueExceedsLimit
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS set_limit_type AS {
        NODE Person (LABELS Person {id INT64 PRIMARY KEY, name STRING, description STRING})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS set_limit_graph TYPED set_limit_type
      """
    Then the execution should be successful
    And graph "set_limit_graph" should be ready to use
    When executing query:
      """
      USE set_limit_graph
      INSERT (p:Person{id:1, name:"Alice", description:"Normal description"})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE set_limit_graph
      MATCH (p:Person{id:1})
      SET p.description = repeat("x", 65536)
      """
    Then an Error should be raised: "[ND014]: Property `description` value STRING exceeds maximum byte length limit (actual: 65536, limit: 65535)"
    When executing query:
      """
      USE set_limit_graph
      MATCH (p:Person{id:1})
      SET p.name = repeat("a", 70000)
      """
    Then an Error should be raised: "[ND014]: Property `name` value STRING exceeds maximum byte length limit (actual: 70000, limit: 65535)"
    When executing query:
      """
      USE set_limit_graph
      MATCH (p:Person{id:1})
      SET p.description = repeat("y", 65535)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 0     |
    And drop the graph "set_limit_graph"
    And drop the graph type "set_limit_type"
