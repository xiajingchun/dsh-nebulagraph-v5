# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: binding table variable definition

  Scenario: binding table definition from literal
    When executing query:
      """
      TABLE t TYPED TABLE {prop1 INT8, prop2 FLOAT, prop3 STRING} =
      {prop1:1,prop2:1.0,prop3:"x"}
      RETURN t
      """
    Then an Error should be raised: "[42000]: Syntax error or access rule violation: Cannot use graph or table reference as the last return item: t"
    When executing query:
      """
      TABLE t TYPED TABLE {prop1 INT8, prop2 FLOAT, prop3 STRING} =
      {prop1:1,prop2:1.0,prop3:"x"},
      {prop1:2,prop2:2.0,prop3:"y"},
      {prop1:2,prop2:2.0,prop3:"z"},
      {prop1:null,prop2:null,prop3:null}
      FOR rec in t
      RETURN rec.prop1, rec.prop2, rec.prop3
      """
    Then the result should be, in order:
      | rec.prop1 | rec.prop2 | rec.prop3 |
      | 1         | 1.0f      | "x"       |
      | 2         | 2.0f      | "y"       |
      | 2         | 2.0f      | "z"       |
      | null      | null      | null      |
    When executing query:
      """
      TABLE t {prop1, prop2, prop3} =
      (1,1.0,"x"),
      (2,2.0,"y"),
      (3,3.0,"z"),
      (null,null,null)
      FOR rec in t
      RETURN rec.prop1, rec.prop2, rec.prop3
      """
    Then the result should be, in order:
      | rec.prop1 | rec.prop2 | rec.prop3 |
      | 1         | 1.0M      | "x"       |
      | 2         | 2.0M      | "y"       |
      | 3         | 3.0M      | "z"       |
      | null      | null      | null      |
    When executing query:
      """
      TABLE t TYPED TABLE {prop1 INT8, prop2 FLOAT, prop3 STRING} =
      {prop1:2,prop2:2.0}
      FOR rec in t
      RETURN rec.prop1, rec.prop2, rec.prop3
      """
    Then an Error should be raised: "[42N36]: Invalid syntax, the number of fields in `RECORD{prop1: 2, prop2: 2.0}` does not match with `{prop1,prop2,prop3}`"
    When executing query:
      """
      TABLE t TYPED TABLE {prop1 INT8, prop2 FLOAT, prop3 STRING} =
      {prop1:2,prop2:2, prop3:""},
      {prop1:2,prop2:2, prop3:1}
      FOR rec in t
      RETURN rec.prop1, rec.prop2, rec.prop3
      """
    Then an Error should be raised: "[NS236]: Invalid binding table variable definition: The type of `1(INT32)` cannot be implicitly cast to the type `STRING` of field `prop3`"
    When executing query:
      """
      TABLE t {prop1} =
      (1),
      ("x")
      FOR rec in t
      RETURN rec.prop1
      """
    Then an Error should be raised: "[NS236]: Invalid binding table variable definition: compatible type not found in field `prop1(INT32, STRING)`"
    When executing query:
      """
      TABLE t {prop1} =
      {prop2:1}
      FOR rec in t
      RETURN rec.prop1
      """
    Then an Error should be raised: "[NS236]: Invalid binding table variable definition: field `prop2` of `RECORD{prop2: 1}` not found in table"
    When executing query:
      """
      TABLE t TYPED TABLE {prop1 INT8, prop2 FLOAT, prop3 STRING} =
      (1,2)
      FOR rec in t
      RETURN rec.prop1, rec.prop2, rec.prop3
      """
    Then an Error should be raised: "[42N36]: Invalid syntax, the number of fields in `LIST[1, 2]` does not match with `{prop1,prop2,prop3}`"
    When executing query:
      """
      TABLE t TYPED TABLE {prop1 INT8, prop2 FLOAT, prop3 STRING} =
      (1,2,3)
      FOR rec in t
      RETURN rec.prop1, rec.prop2, rec.prop3
      """
    Then an Error should be raised: "[NS236]: Invalid binding table variable definition: The type of `3(INT32)` cannot be implicitly cast to the type `STRING` of field `prop3`"
    When executing query:
      """
      TABLE t {prop1, prop2, prop3} =
      (1,2,3),
      (1,2,3.0)
      FOR rec in t
      RETURN rec.prop1, rec.prop2, rec.prop3
      """
    Then the result should be, in order:
      | rec.prop1 | rec.prop2 | rec.prop3 |
      | 1         | 2         | 3.0M      |
      | 1         | 2         | 3.0M      |
    When executing query:
      """
      BINDING TABLE t TYPED TABLE {id int, name string} = {}
      FOR rec IN t
      RETURN rec.id, rec.name
      """
    Then an Error should be raised: "[42N36]: Invalid syntax, the number of fields in `RECORD{}` does not match with `{id,name}`"
    When executing query:
      """
      TABLE t TYPED TABLE { a UINT64 } = (13226281650791314802)
      FOR r IN t
      RETURN r.a
      """
    Then the result should be, in order:
      | r.a                   |
      | 13226281650791314802u |
    When executing query:
      """
      binding table t typed table {id int, name string}={id:1,name:"Abby"}  for rec in t return rec.id, rec.name
      """
    Then the result should be, in any order:
      | rec.id | rec.name |
      | 1      | "Abby"   |
    When executing query:
      """
      binding table t typed table {id int, name string}={id:1,fisrtName:"Abby"}  for rec in t return rec.id, rec.name
      """
    Then an Error should be raised: "[NS236]: Invalid binding table variable definition"
    When executing query:
      """
      TABLE t {prop1} =
      (x)
      FOR rec in t RETURN rec.prop1
      """
    Then an Error should be raised: "[42N18]: Invalid syntax, variable `x` not defined"
    When executing query:
      """
      TABLE t {prop1} =
      (rand())
      FOR rec in t RETURN rec.prop1
      """
    Then an Error should be raised:
      """
      [NS236]: Invalid binding table variable definition: `rand()` is not supported in binding table `t` definition. Only constant expressions are supported for now.
      """

  Scenario: batch dml
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS batch_dml TYPED ldbc_type
      """
    Then the execution should be successful
    And graph "batch_dml" should be ready to use
    When executing query:
      """
      TABLE t {id,firstName,lastName, tag_name} =
      (1, "f1", "l1", "tag1"),
      (2, "f2", "l2", "tag2"),
      (3, "f3", "l3", "tag3")
      USE batch_dml
      FOR r IN t
      INSERT (a@Person{id:r.id,firstName:r.firstName,lastName:r.lastName})-[@HAS_INTEREST{}]->(@Tag{id:r.id,name:r.tag_name})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 6     |
      | "num_affected_edges" | 3     |
    When executing query:
      """
      USE batch_dml
      MATCH (a@Person)-[e@HAS_INTEREST]->(b@Tag)
      RETURN a.id, a.firstName, a.lastName, b.id, b.name
      """
    Then the result should be, in any order:
      | a.id | a.firstName | a.lastName | b.id | b.name |
      | 3    | "f3"        | "l3"       | 3    | "tag3" |
      | 2    | "f2"        | "l2"       | 2    | "tag2" |
      | 1    | "f1"        | "l1"       | 1    | "tag1" |
    When executing query:
      """
      TABLE t {id,locationIP} =
      (1,"192.168.0.1"),
      (2,"192.168.0.2"),
      (3,"192.168.0.3")
      USE batch_dml
      FOR r IN t
      MATCH (a@Person) WHERE a.id = r.id
      SET a.locationIP = r.locationIP
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 3     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE batch_dml
      MATCH (a@Person)
      RETURN a.id, a.locationIP
      """
    Then the result should be, in any order:
      | a.id | a.locationIP  |
      | 2    | "192.168.0.2" |
      | 1    | "192.168.0.1" |
      | 3    | "192.168.0.3" |
    When executing query:
      """
      TABLE t {src_id, dst_id} =
      (1,1),
      (2,2),
      (3,3)
      USE batch_dml
      FOR r IN t
      MATCH (a@Person)-[e]->(b@Tag) WHERE a.id = r.src_id and b.id = r.dst_id
      DELETE e
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 3     |
    When executing query:
      """
      TABLE t {person_id, tag_id} =
      (1,1),
      (2,2),
      (3,3)
      USE batch_dml
      FOR r IN t
      MATCH (a@Person),(b@Tag) WHERE a.id = r.person_id and b.id = r.tag_id
      DELETE a, b
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 6     |
      | "num_affected_edges" | 0     |
    And drop the graph "batch_dml"

  Scenario: Empty table definition with explicit type
    # Empty table with explicit type
    When executing query:
      """
      TABLE t TYPED TABLE {prop1 INT8, prop2 STRING}
      FOR rec in t RETURN rec.prop1, rec.prop2
      """
    Then the result should be, in order:
      | rec.prop1 | rec.prop2 |
    When executing query:
      """
      TABLE t {prop1 INT8, prop2 STRING}
      FOR rec in t RETURN rec.prop1, rec.prop2
      """
    Then the result should be, in order:
      | rec.prop1 | rec.prop2 |
    When executing query:
      """
      TABLE t {prop1 INT8, prop2 STRING} = NULL
      FOR rec in t RETURN rec.prop1, rec.prop2
      """
    Then the result should be, in order:
      | rec.prop1 | rec.prop2 |

  Scenario: File definition
    When executing query:
      """
      create temp graph #ldbc_test_graph typed ldbc_type
      """
    Then the execution should be successful
    When executing query:
      """
      create or replace procedure proc_internal_scope_file() {
      value a int = 0
      if true then {
      file f {id int} = datafile {format:"csv", path:"file://${TEST_DIR}/dataset/external_source/pk_conflict/node.csv"}
      match(v@Person) where v.id < 150 per node(v){export v.id into f }
      }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      use #ldbc_test_graph call proc_internal_scope_file() finish
      """
    Then an Error should be raised: "[NS242]: Invalid variable definition: `f:File` can only be defined in the global scope"
    When executing query:
      """
      create or replace procedure proc_top_scope_file() {
      value a int = 0
      file f {id int} = datafile {format:"csv", path:"file://${TEST_DIR}/dataset/external_source/pk_conflict/node.csv"}
      finish
      }
      """
    Then the execution should be successful
    When executing query:
      """
      use #ldbc_test_graph call proc_top_scope_file() finish
      """
    Then the execution should be successful
    And drop the graph "#ldbc_test_graph"
    And drop the procedure "proc_internal_scope_file"
    And drop the procedure "proc_top_scope_file"
