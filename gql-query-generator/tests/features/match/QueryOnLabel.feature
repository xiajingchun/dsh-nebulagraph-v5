# Copyright (c) 2022 vesoft inc. All rights reserved.
Feature: Query on label

  Scenario: Node Pattern With Label Predicate
    When executing query:
      """
      USE ldbc {
        VALUE s = "Person"
        MATCH (v:s) WHERE v.id = 1 RETURN v.id, type(v)
      }
      """
    Then the result should be, in any order:
      | v.id | type(v)  |
      | 1    | "Person" |
    # constant-fold through constantStringValue: non-literal but evaluable VALUE initializer
    When executing query:
      """
      USE ldbc {
        VALUE s = CASE WHEN true THEN "Person" ELSE "Tag" END
        MATCH (v:s) WHERE v.id = 1 RETURN v.id, type(v)
      }
      """
    Then the result should be, in any order:
      | v.id | type(v)  |
      | 1    | "Person" |
    # constant-fold through constantStringValue inside a compound label expression
    When executing query:
      """
      USE ldbc {
        VALUE c = CASE WHEN true THEN "City" ELSE "Person" END
        VALUE m = CASE WHEN true THEN "Message" ELSE "Post" END
        VALUE q = CASE WHEN true THEN "Post" ELSE "Message" END
        VALUE p = CASE WHEN true THEN "Person" ELSE "City" END
        MATCH (v:c|m&!q|p)
        RETURN case when v.kind="city" then "city" else v.content end AS kind
      }
      """
    Then the result should be, in any order:
      | kind       |
      | "city"     |
      | "comment4" |
      | NULL       |
      | "city"     |
      | NULL       |
      | "city"     |
      | "comment2" |
      | "city"     |
      | "city"     |
      | "comment1" |
      | NULL       |
      | NULL       |
      | "city"     |
      | "comment3" |
    # runtime filter path: sv's initializer references a binding variable (label)
    When executing query:
      """
      USE ldbc {
        VALUE label = "Person"
        VALUE sv = label
        MATCH (v:sv) WHERE v.id = 1 RETURN v.id, type(v)
      }
      """
    Then the result should be, in any order:
      | v.id | type(v)  |
      | 1    | "Person" |
    # runtime filter path: each compound-label operand is resolved from a binding variable
    When executing query:
      """
      USE ldbc {
        VALUE city = "City"
        VALUE message = "Message"
        VALUE post = "Post"
        VALUE person = "Person"
        VALUE c = city
        VALUE m = message
        VALUE q = post
        VALUE p = person
        MATCH (v:c|m&!q|p)
        RETURN case when v.kind="city" then "city" else v.content end AS kind
      }
      """
    Then the result should be, in any order:
      | kind       |
      | "city"     |
      | "comment4" |
      | NULL       |
      | "city"     |
      | NULL       |
      | "city"     |
      | "comment2" |
      | "city"     |
      | "city"     |
      | "comment1" |
      | NULL       |
      | NULL       |
      | "city"     |
      | "comment3" |
    When executing query:
      """
      USE ldbc {
        VALUE Person SumAgg<INT> = 0
        MATCH (v:Person) WHERE v.id = 1 RETURN v.id, type(v)
      }
      """
    Then an Error should be raised: "[NS231]: Invalid variable access: `Person:Aggregator` cannot be used in label expressions"
    When executing query:
      """
      USE ldbc {
        FILE f {id INT64} = DATAFILE {FORMAT:"csv", PATH:"test"}
        MATCH (v:f) WHERE v.id = 1 RETURN v.id, type(v)
      }
      """
    Then an Error should be raised: "[NS231]: Invalid variable access: `f:File` cannot be used in label expressions"
    When executing query:
      """
      USE ldbc {
        TABLE t TYPED TABLE {id INT8} = {id:1}
        MATCH (v:t) WHERE v.id = 1 RETURN v.id, type(v)
      }
      """
    Then an Error should be raised: "[NS231]: Invalid variable access: `t:TABLE {id INT8}` cannot be used in label expressions"
    # negative: constant-folded VALUE with non-existent label name
    When executing query:
      """
      USE ldbc {
        VALUE s = "NonExistentLabel"
        MATCH (v:s) WHERE v.id = 1 RETURN v.id, type(v)
      }
      """
    Then an Error should be raised: "[NS228]: node label `NonExistentLabel` not found in graph type `ldbc_type`"
    # negative: non-string VALUE variable
    When executing query:
      """
      USE ldbc {
        VALUE n = 42
        MATCH (v:n) WHERE v.id = 1 RETURN v.id, type(v)
      }
      """
    Then an Error should be raised: "[NS210]: Invalid label expression input: `n`, expect NODE or EDGE type but got `INT32`"
    # negative: Tier 2 runtime path with non-existent label
    When executing query:
      """
      USE ldbc {
        VALUE label = "NonExistentLabel"
        VALUE sv = label
        MATCH (v:sv) WHERE v.id = 1 RETURN v.id, type(v)
      }
      """
    Then the result should be, in any order:
      | v.id | type(v) |

  Scenario: Edge Pattern With Label Predicate
    When executing query:
      """
      USE ldbc match (src:Person)-[e:KNOWS@KNOWS]->(dst) where src.id=1 return type(src), type(e), type(dst)
      """
    Then an Error should be raised: "[42N34]: Invalid syntax, label expression and type expression cannot coexist in single Edge pattern `-[e:KNOWS@KNOWS]->`"
    # negative: constant-folded VALUE with non-existent edge label
    When executing query:
      """
      USE ldbc {
        VALUE et = "NonExistentEdgeType"
        MATCH (src:Person)-[e:et]->(dst) WHERE src.id = 1 RETURN type(src), type(e), type(dst)
      }
      """
    Then an Error should be raised: "[NS228]: edge label `NonExistentEdgeType` not found in graph type `ldbc_type`"
    # negative: Tier 2 runtime path with non-existent edge label
    When executing query:
      """
      USE ldbc {
        VALUE edgeType = "NonExistentEdgeType"
        VALUE etv = edgeType
        MATCH (src:Person)-[e:etv]->(dst) WHERE src.id = 1 RETURN type(src), type(e), type(dst)
      }
      """
    Then the result should be, in any order:
      | type(src) | type(e) | type(dst) |
    # constant-fold through constantStringValue
    When executing query:
      """
      USE ldbc {
        VALUE et = CASE WHEN true THEN "KNOWS" ELSE "WORK_AT" END
        MATCH (src:Person)-[e:et]->(dst) WHERE src.id = 1 RETURN type(src), type(e), type(dst)
      }
      """
    Then the result should be, in any order:
      | type(src) | type(e) | type(dst) |
      | "Person"  | "KNOWS" | "Person"  |
    # runtime filter path: variable reference in edge label
    When executing query:
      """
      USE ldbc {
        VALUE edgeType = "KNOWS"
        VALUE etv = edgeType
        MATCH (src:Person)-[e:etv]->(dst) WHERE src.id = 1 RETURN type(src), type(e), type(dst)
      }
      """
    Then the result should be, in any order:
      | type(src) | type(e) | type(dst) |
      | "Person"  | "KNOWS" | "Person"  |
    # runtime filter path: iterated variable in FOR drives dynamic edge label reference
    When executing query:
      """
      USE ldbc {
        LET ets = LIST["KNOWS", "WORK_AT"]
        FOR et IN ets
        MATCH (src:Person{id:1})-[e:et]->(dst)
        RETURN type(src), type(e), type(dst)
      }
      """
    Then the result should be, in any order:
      | type(src) | type(e)   | type(dst)      |
      | "Person"  | "WORK_AT" | "Organisation" |
      | "Person"  | "KNOWS"   | "Person"       |
    # runtime filter path: iterated variable from NEXT pipeline drives dynamic edge label reference
    When executing query:
      """
      USE ldbc {
        MATCH (:Person{id:1})-[e:KNOWS]->(:Person) RETURN type(e) AS t
        NEXT
        MATCH (src:Person{id:1})-[e:t]->(dst) RETURN type(src), type(e), type(dst)
      }
      """
    Then the result should be, in any order:
      | type(src) | type(e) | type(dst) |
      | "Person"  | "KNOWS" | "Person"  |

  Scenario: Mixed Pattern With Label And Element Type Predicate
    When executing query:
      """
      USE ldbc match (src@Person)-[e:KNOWS]->(dst) where src.id=1 return type(src), type(e), type(dst)
      """
    Then the result should be, in any order:
      | type(src) | type(e) | type(dst) |
      | "Person"  | "KNOWS" | "Person"  |
    When executing query:
      """
      USE ldbc match (v:Person@Person) where v.id=1 return v.id, type(v)
      """
    Then an Error should be raised: "[42N34]: Invalid syntax, label expression and type expression cannot coexist in single Node pattern `(v:Person@Person)`"
