# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: Graph Function

  Scenario: Graph Function
    When executing query:
      """
      USE ldbc MATCH p=(v:Person{browserUsed:"Internet Explorer"})-[e]->()
      RETURN start_node(p)
      """
    Then an Error should be raised: "[NR002]: Undefined function: `start_node(PATH)`"
    # TODO(czp): We should support this function later, traced by issue #2515
    When executing query:
      """
      USE ldbc MATCH p=(v:Person{browserUsed:"Internet Explorer"})-[e]->()
      RETURN start_node(e)
      """
    Then an Error should be raised: "[NR002]: Undefined function: `start_node(EDGE)`"
    When executing query:
      """
      USE ldbc MATCH p=(v:Person{browserUsed:"Internet Explorer"})-[e]->()
      RETURN end_node(p)
      """
    Then an Error should be raised: "[NR002]: Undefined function: `end_node(PATH)`"
    When executing query:
      """
      USE ldbc MATCH p=(v:Person{id:318})-[e]->{3}(v:Person{id:28587302323722})
      RETURN elements(p)
      """
    Then an Error should be raised: "[NR002]: Undefined function: `elements(PATH)`"
    When executing query:
      """
      USE ldbc MATCH p=(v:Person{id:318})-[e]->{3}(v:Person{id:28587302323722})
      RETURN element(p)
      """
    Then an Error should be raised: "[NR002]: Undefined function: `element(PATH)`"
    # TODO(czp): We should support this function later, traced by issue #2515
    When executing query:
      """
      USE ldbc MATCH p=(v:Person{browserUsed:"Internet Explorer"})-[e]->()
      RETURN end_node(e)
      """
    Then an Error should be raised: "[NR002]: Undefined function: `end_node(EDGE)`"
    When executing query:
      """
      USE ldbc MATCH p=(v:Person{browserUsed:"Internet Explorer"})-[e]->()
      RETURN all_different(v)
      """
    Then an Error should be raised: "[NR002]: Undefined function: `all_different(v)`"
    When executing query:
      """
      USE ldbc MATCH p=(v:Person{browserUsed:"Internet Explorer"})-[e]->()
      RETURN all_different()
      """
    Then an Error should be raised: "[NR002]: Undefined function: `all_different()`"
    When executing query:
      """
      RETURN all_different(1,2,3,null,4)
      """
    Then an Error should be raised: "[NR002]: Undefined function: `all_different(INT32, INT32, INT32, NULL, INT32)`"
    When executing query:
      """
      RETURN all_different([1,2,3,null,4])
      """
    Then an Error should be raised: "[NR002]: Undefined function: `all_different(LIST[1, 2, 3, NULL, 4])`"
    When executing query:
      """
      USE ldbc MATCH p=(v:Person{browserUsed:"Internet Explorer"})-[e]->()
      RETURN same(e)
      """
    Then an Error should be raised: "[NR002]: Undefined function: `same(e)`"
    When executing query:
      """
      USE ldbc MATCH p=(v:Person{browserUsed:"Internet Explorer"})-[e]->()
      RETURN same()
      """
    Then an Error should be raised: "[NR002]: Undefined function: `same()`"
    When executing query:
      """
      RETURN same(1,2,3,null,4)
      """
    Then an Error should be raised: "[NR002]: Undefined function: `same(INT32, INT32, INT32, NULL, INT32)`"
    When executing query:
      """
      RETURN same([1,2,3,null,4])
      """
    Then an Error should be raised: "[NR002]: Undefined function: `same(LIST[1, 2, 3, NULL, 4])`"
    When executing query:
      """
      USE ldbc MATCH (v)->{1,3}(n)->(m)
      WHERE all_different(v,n,m)
      RETURN element_id(v)<>element_id(n) and element_id(v)<>element_id(m) and element_id(n)<>element_id(m) AS diff
      NEXT use ldbc
      RETURN count(case when diff then diff else null end) AS cnt
      """
    # the count of matched path is 2758, all `diff` is true
    Then the result should be, in any order:
      | cnt  |
      | 2758 |
    When executing query:
      """
      USE ldbc MATCH (v:City), (n)->(m:Continent)
      RETURN all_different(v,n,m) AS d
      NEXT
      USE ldbc
      RETURN sum(CASE WHEN d THEN 1 ELSE 2 END) AS s GROUP BY ()
      """
    Then the result should be, in any order:
      | s   |
      | 108 |
    When executing query:
      """
      USE ldbc MATCH (v:City), (n:Country)->(m:Continent)
      WHERE NOT all_different(v,n,m)
      RETURN element_id(v)=element_id(n) AS vn,element_id(v)=element_id(m) AS vm,element_id(n)=element_id(m) AS nm
      """
    Then the result should be, in any order:
      | vn    | vm    | nm    |
      | false | true  | false |
      | true  | false | false |
      | false | true  | false |
      | true  | false | false |
      | true  | false | false |
      | false | true  | false |
    When executing query:
      """
      USE ldbc MATCH (v)
      let n=v, m=n
      filter not same(n,m,v)
      RETURN v
      """
    Then the result should be, in any order:
      | v |
    When executing query:
      """
      USE ldbc MATCH (v:Person)->(n:City)
      filter same(n,v)
      RETURN v
      """
    Then the result should be, in any order:
      | v |
    When executing query:
      """
      USE ldbc MATCH (v:Person)->(n:City)
      let m=n, x=v, y=m
      filter same(n,v,x,m,y)
      RETURN v
      """
    Then the result should be, in any order:
      | v |
    When executing query:
      """
      USE ldbc MATCH (v:Person)->(n:Person)
      RETURN same(v,n) AS s, v.id AS vid, n.id AS nid
      """
    Then the result should be, in any order:
      | s     | vid | nid |
      | false | 3   | 1   |
      | true  | 1   | 1   |
      | false | 2   | 4   |
      | false | 2   | 3   |
      | true  | 3   | 3   |
      | true  | 2   | 2   |
      | false | 3   | 2   |
      | false | 1   | 2   |
    When executing query:
      """
      USE ldbc MATCH p= TRAIL (v:Person{id:1})-[e]->{1,2}(n:Person)
      RETURN path_length(p) AS _path_length, size(e)=path_length(p) AS alwaysTrue
      """
    Then the result should be, in any order:
      | _path_length | alwaysTrue |
      | 1            | true       |
      | 2            | true       |
      | 2            | true       |
      | 2            | true       |
      | 2            | true       |
      | 2            | true       |
      | 1            | true       |
      | 2            | true       |
    When executing query:
      # left_node_id/right_node_id return the storage-level edge endpoints (key src/dst), not the
      # logical direction that users expect for a->b.
      # Example: a directed edge a->b is stored twice: a->b on a's part and b<-a on b's part for scans.
      # If the planner scans the forward copy, left/right are a/b; if it scans the reverse copy,
      # left/right become b/a. The pattern MATCH (v)-[e]->(m) is the same in both cases, so results
      # should be equivalent, but these functions make them differ.
      # This makes the function semantics plan-dependent. Prefer logical src_id/dst_id for users.
      """
      /*+ set_var(enable_reorder=false) */ USE ldbc MATCH (v)-[e]->(m)
      LET l=left_node_id(e)=element_id(v), r=right_node_id(e)=element_id(m)
      RETURN collect(case when l then null else 1 end) AS left_falses,
                     count(case when r then null else false end) AS right_falses
      """
    Then the result should be, in any order:
      | left_falses | right_falses |
      | LIST[]      | 0            |
    When executing query:
      """
      /*+ set_var(enable_reorder=false) */ USE ldbc MATCH (v)-[e]->(m)
      LET l=left_node_id([e][0])=element_id(v), r=right_node_id(head([e]))=element_id(m)
      RETURN collect(case when l then null else 1 end) AS left_falses,
                     count(case when r then null else false end) AS right_falses
      """
    Then the result should be, in any order:
      | left_falses | right_falses |
      | LIST[]      | 0            |
    When executing query:
      """
      /*+ set_var(enable_reorder=false) */ USE ldbc MATCH (v)-[e]->{1,3}(m)
      LET l=left_node_id(e[0])=element_id(v), r=right_node_id(back(e))=element_id(m)
      RETURN collect(case when l then null else 1 end) AS left_falses,
                     count(case when r then null else false end) AS right_falses
      """
    Then the result should be, in any order:
      | left_falses | right_falses |
      | LIST[]      | 0            |
    When executing query:
      """
      RETURN left_node_id([null,1,2,null,3,4])
      """
    Then an Error should be raised: " [NR002]: Undefined function: `left_node_id(LIST)`"
    When executing query:
      """
      RETURN right_node_id([null,true,null,false])
      """
    Then an Error should be raised: " [NR002]: Undefined function: `right_node_id(LIST)`"

  Scenario: Property exists
    When executing query:
      """
      USE ldbc MATCH(v:Person | Forum) RETURN TYPE(v), PROPERTY_EXISTS(v, "gender") AS gender_prop_exists
      """
    Then the result should be, in any order:
      | TYPE(v)  | gender_prop_exists |
      | "Forum"  | false              |
      | "Person" | true               |
      | "Forum"  | false              |
      | "Person" | true               |
      | "Forum"  | false              |
      | "Person" | true               |
      | "Forum"  | false              |
      | "Person" | true               |
    When executing query:
      """
      USE ldbc MATCH(v:Person | Forum) WHERE PROPERTY_EXISTS(v, "gender") return v.id, v.gender
      """
    Then the result should be, in any order:
      | v.id | v.gender |
      | 4    | "female" |
      | 2    | "male"   |
      | 3    | "male"   |
      | 1    | "male"   |
    When executing query:
      """
      USE ldbc MATCH(v:Person | Forum) RETURN TYPE(v), PROPERTY_EXISTS(v, "gender") AS gender_prop_exists
      """
    Then the result should be, in any order:
      | TYPE(v)  | gender_prop_exists |
      | "Forum"  | false              |
      | "Person" | true               |
      | "Forum"  | false              |
      | "Person" | true               |
      | "Forum"  | false              |
      | "Person" | true               |
      | "Forum"  | false              |
      | "Person" | true               |
    When executing query:
      """
      USE ldbc MATCH(v:Person)-[e:KNOWS|FOLLOWS]-() WHERE PROPERTY_EXISTS(e, "creationDate") RETURN TYPE(e), PROPERTY_EXISTS(e, "creationDate")
      """
    Then the result should be, in any order:
      | TYPE(e) | PROPERTY_EXISTS(e, "creationDate") |
      | "KNOWS" | true                               |
      | "KNOWS" | true                               |
      | "KNOWS" | true                               |
      | "KNOWS" | true                               |
      | "KNOWS" | true                               |
      | "KNOWS" | true                               |
    When executing query:
      """
      USE ldbc MATCH p=(v:Person{id:1}) RETURN EDGES(p) AS e
      """
    Then the result should be, in any order:
      | e       |
      | LIST [] |
    When executing query:
      """
      USE ldbc MATCH p=(v:Person{id:1})-[:KNOWS]->() RETURN RELATIONSHIPS(p) AS e
      """
    Then the result should be, in any order:
      | e                                                                                     |
      | LIST[[{creationDate:DATETIME "2021-01-01T10:00:40.213000",vec:VECTOR [1.0,2.0,3.0]}]] |
    When executing query:
      """
      USE ldbc MATCH p=(v:Person{id:1})-[:KNOWS]->{0,3}() RETURN EDGES(p) AS e
      """
    Then the result should be, in any order:
      | e                                                                                                                                                                                                                                                      |
      | LIST []                                                                                                                                                                                                                                                |
      | LIST [[{creationDate:DATETIME "2021-01-01T10:00:40.213000",vec:VECTOR [1.0,2.0,3.0]}]]                                                                                                                                                                 |
      | LIST [[{creationDate:DATETIME "2021-01-01T10:00:40.213000",vec:VECTOR [1.0,2.0,3.0]}],[{creationDate:DATETIME "2021-01-01T10:00:40.213000",vec:VECTOR [1.0,2.0,3.0]}]]                                                                                 |
      | LIST [[{creationDate:DATETIME "2021-01-01T10:00:40.213000",vec:VECTOR [1.0,2.0,3.0]}],[{creationDate:DATETIME "2021-01-01T10:00:40.213000",vec:VECTOR [1.0,2.0,3.0]}],[{creationDate:DATETIME "2021-01-01T10:00:40.213000",vec:VECTOR [1.0,2.0,3.0]}]] |
