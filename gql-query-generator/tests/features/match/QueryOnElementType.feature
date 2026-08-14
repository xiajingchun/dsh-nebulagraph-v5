# Copyright (c) 2022 vesoft inc. All rights reserved.
Feature: Query on element type

  Scenario: Node Pattern With Element Type Predicate
    When executing query:
      """
      USE ldbc match (v@Person) where v.id=1 return v.id, type(v)
      """
    Then the result should be, in any order:
      | v.id | type(v)  |
      | 1    | "Person" |
    When executing query:
      """
      USE ldbc match (v@[Person,Tag]) where v.id=1 return v.id, type(v)
      """
    Then the result should be, in any order:
      | v.id | type(v)  |
      | 1    | "Tag"    |
      | 1    | "Person" |
    When executing query:
      """
      USE ldbc match (v@!Person) where v.id=1 return v.id, type(v)
      """
    Then the result should be, in any order:
      | v.id | type(v)        |
      | 1    | "TagClass"     |
      | 1    | "Comment"      |
      | 1    | "Post"         |
      | 1    | "Place"        |
      | 1    | "Tag"          |
      | 1    | "Forum"        |
      | 1    | "Organisation" |
    When executing query:
      """
      USE ldbc match (v@![Person,Tag]) where v.id=1 return v.id, type(v)
      """
    Then the result should be, in any order:
      | v.id | type(v)        |
      | 1    | "Post"         |
      | 1    | "Organisation" |
      | 1    | "TagClass"     |
      | 1    | "Place"        |
      | 1    | "Forum"        |
      | 1    | "Comment"      |
    When executing query:
      """
      USE ldbc {
        VALUE s = "Person"
        MATCH (v@s) WHERE v.id = 1 RETURN v.id, type(v)
      }
      """
    Then the result should be, in any order:
      | v.id | type(v)  |
      | 1    | "Person" |
    When executing query:
      """
      USE ldbc {
        VALUE s = "Person"
        MATCH (v@[s,Tag]) WHERE v.id = 1 RETURN type(v)
      }
      """
    Then the result should be, in any order:
      | type(v)  |
      | "Person" |
      | "Tag"    |
    # runtime filter path: iterated variable in FOR drives dynamic pattern type reference
    When executing query:
      """
      USE ldbc {
        LET a = LIST["Person", "Tag"]
        FOR i IN a
        MATCH (v@i {id:1}) RETURN type(v)
      }
      """
    Then the result should be, in any order:
      | type(v)  |
      | "Person" |
      | "Tag"    |
    # runtime filter path: iterated variable from NEXT pipeline drives dynamic pattern type reference
    When executing query:
      """
      USE ldbc {
        MATCH (v:Person {id:2}) RETURN type(v) AS t
        NEXT
        MATCH (v@t {id:1}) RETURN type(v)
      }
      """
    Then the result should be, in any order:
      | type(v)  |
      | "Person" |
    # runtime filter path: element-type set driven by dynamic NEXT variables
    When executing query:
      """
      USE ldbc {
        MATCH (v:Person {id:2}) RETURN type(v) AS t, "Tag" AS u
        NEXT
        MATCH (v@[t,u] {id:1}) RETURN type(v)
      }
      """
    Then the result should be, in any order:
      | type(v)  |
      | "Person" |
      | "Tag"    |
    # runtime + literal set mixed with static filter in the same query
    When executing query:
      """
      USE ldbc {
        MATCH (v:Person {id:2}) RETURN type(v) AS t, "Tag" AS u
        NEXT
        MATCH (v@[t,u] {id:1}) WHERE v IS ELEMENT TYPED [Person,Tag] RETURN type(v)
      }
      """
    Then the result should be, in any order:
      | type(v)  |
      | "Person" |
      | "Tag"    |

  Scenario: Edge Pattern With Element Type Predicate
    When executing query:
      """
      USE ldbc match (src:Person)-[e@KNOWS]->(dst) where src.id=1 return type(src), type(e), type(dst)
      """
    Then the result should be, in any order:
      | type(src) | type(e) | type(dst) |
      | "Person"  | "KNOWS" | "Person"  |
    When executing query:
      """
      USE ldbc match (src:Person)-[e@[KNOWS,WORK_AT]]->(dst) where src.id=1 return type(src), type(e), type(dst)
      """
    Then the result should be, in any order:
      | type(src) | type(e)   | type(dst)      |
      | "Person"  | "WORK_AT" | "Organisation" |
      | "Person"  | "KNOWS"   | "Person"       |
    When executing query:
      """
      USE ldbc match (src:Person)-[e@!KNOWS]->(dst) where src.id=1 return type(src), type(e), type(dst)
      """
    Then the result should be, in any order:
      | type(src) | type(e)           | type(dst)      |
      | "Person"  | "FOLLOWS"         | "Person"       |
      | "Person"  | "HAS_INTEREST"    | "Tag"          |
      | "Person"  | "STUDY_AT"        | "Organisation" |
      | "Person"  | "WORK_AT"         | "Organisation" |
      | "Person"  | "LIKES_1"         | "Post"         |
      | "Person"  | "LIKES_2"         | "Comment"      |
      | "Person"  | "IS_LOCATED_IN_1" | "Place"        |
    When executing query:
      """
      USE ldbc match (src:Person)-[e@![KNOWS,WORK_AT]]->(dst) where src.id=1 return type(src), type(e), type(dst)
      """
    Then the result should be, in any order:
      | type(src) | type(e)           | type(dst)      |
      | "Person"  | "FOLLOWS"         | "Person"       |
      | "Person"  | "LIKES_2"         | "Comment"      |
      | "Person"  | "STUDY_AT"        | "Organisation" |
      | "Person"  | "LIKES_1"         | "Post"         |
      | "Person"  | "IS_LOCATED_IN_1" | "Place"        |
      | "Person"  | "HAS_INTEREST"    | "Tag"          |
    When executing query:
      """
      USE ldbc {
        BINDING TABLE bt TYPED TABLE {id INT64, name STRING} = {id:1, name:"a"}
        MATCH (src:Person)-[e@bt]->(dst) WHERE src.id = 1 RETURN type(src), type(e), type(dst)
      }
      """
    Then an Error should be raised: "[NS231]: Invalid variable access: `bt:TABLE {id INT64, name STRING}` cannot be used in element type expressions"
    # negative: non-string VALUE variable; matching symbol is treated as a variable reference
    # and no longer falls back to the literal name "et"
    When executing query:
      """
      USE ldbc {
        VALUE et = 42
        MATCH (src:Person)-[e@et]->(dst) WHERE src.id = 1 RETURN type(src), type(e), type(dst)
      }
      """
    Then an Error should be raised: "[NS211]: Invalid type expression input: `et`, expect NODE or EDGE type but got `INT32`"
    # constant-fold + literal mixed in edge element-type set
    When executing query:
      """
      USE ldbc {
        VALUE et = CASE WHEN true THEN "KNOWS" ELSE "FOLLOWS" END
        MATCH (src:Person)-[e@[et,WORK_AT]]->(dst)
        WHERE src.id = 1
        RETURN type(src), type(e), type(dst)
      }
      """
    Then the result should be, in any order:
      | type(src) | type(e)   | type(dst)      |
      | "Person"  | "WORK_AT" | "Organisation" |
      | "Person"  | "KNOWS"   | "Person"       |
    # runtime filter path: iterated variable in FOR drives dynamic edge type reference
    When executing query:
      """
      USE ldbc {
        LET ets = LIST["KNOWS", "WORK_AT"]
        FOR et IN ets
        MATCH (src:Person{id:1})-[e@et]->(dst)
        RETURN type(src), type(e), type(dst)
      }
      """
    Then the result should be, in any order:
      | type(src) | type(e)   | type(dst)      |
      | "Person"  | "WORK_AT" | "Organisation" |
      | "Person"  | "KNOWS"   | "Person"       |
    # runtime filter path: iterated variable from NEXT pipeline drives dynamic edge type reference
    When executing query:
      """
      USE ldbc {
        MATCH (:Person{id:1})-[e:KNOWS]->(:Person) RETURN type(e) AS t
        NEXT
        MATCH (src:Person{id:1})-[e@t]->(dst) RETURN type(src), type(e), type(dst)
      }
      """
    Then the result should be, in any order:
      | type(src) | type(e) | type(dst) |
      | "Person"  | "KNOWS" | "Person"  |
    # runtime filter path: edge element-type set driven by dynamic NEXT variables
    When executing query:
      """
      USE ldbc {
        MATCH (:Person{id:1})-[e:KNOWS]->(:Person) RETURN type(e) AS t, "WORK_AT" AS u
        NEXT
        MATCH (src:Person{id:1})-[e@[t,u]]->(dst) RETURN type(src), type(e), type(dst)
      }
      """
    Then the result should be, in any order:
      | type(src) | type(e)   | type(dst)      |
      | "Person"  | "KNOWS"   | "Person"       |
      | "Person"  | "WORK_AT" | "Organisation" |
    # runtime + literal set mixed with static filter in the same query
    When executing query:
      """
      USE ldbc {
        MATCH (:Person{id:1})-[e:KNOWS]->(:Person) RETURN type(e) AS t, "WORK_AT" AS u
        NEXT
        MATCH (src:Person{id:1})-[e@[t,u]]->(dst) WHERE e @[KNOWS,WORK_AT]
        RETURN type(src), type(e), type(dst)
      }
      """
    Then the result should be, in any order:
      | type(src) | type(e)   | type(dst)      |
      | "Person"  | "KNOWS"   | "Person"       |
      | "Person"  | "WORK_AT" | "Organisation" |
    # constant-folded dynamic reference combined with a static element-type predicate
    When executing query:
      """
      USE ldbc {
        VALUE et = CASE WHEN true THEN "KNOWS" ELSE "FOLLOWS" END
        MATCH (src:Person)-[e@!et]->(dst)
        WHERE src.id = 1 AND type(e) <> "WORK_AT"
        RETURN type(src), type(e), type(dst)
      }
      """
    Then the result should be, in any order:
      | type(src) | type(e)           | type(dst)      |
      | "Person"  | "FOLLOWS"         | "Person"       |
      | "Person"  | "LIKES_2"         | "Comment"      |
      | "Person"  | "STUDY_AT"        | "Organisation" |
      | "Person"  | "LIKES_1"         | "Post"         |
      | "Person"  | "IS_LOCATED_IN_1" | "Place"        |
      | "Person"  | "HAS_INTEREST"    | "Tag"          |
    # runtime filter path: dynamic reference combined with a static element-type predicate
    When executing query:
      """
      USE ldbc {
        MATCH (:Person{id:1})-[e:KNOWS]->(:Person) RETURN type(e) AS t
        NEXT
        MATCH (src:Person)-[e@!t]->(dst)
        WHERE src.id = 1 AND type(e) <> "WORK_AT"
        RETURN type(src), type(e), type(dst)
      }
      """
    Then the result should be, in any order:
      | type(src) | type(e)           | type(dst)      |
      | "Person"  | "FOLLOWS"         | "Person"       |
      | "Person"  | "LIKES_2"         | "Comment"      |
      | "Person"  | "STUDY_AT"        | "Organisation" |
      | "Person"  | "LIKES_1"         | "Post"         |
      | "Person"  | "IS_LOCATED_IN_1" | "Place"        |
      | "Person"  | "HAS_INTEREST"    | "Tag"          |

  Scenario: Mixed Pattern With Element Type Predicate
    When executing query:
      """
      USE ldbc match (src@Person)-[e@KNOWS]->(dst) where src.id=1 return type(src), type(e), type(dst)
      """
    Then the result should be, in any order:
      | type(src) | type(e) | type(dst) |
      | "Person"  | "KNOWS" | "Person"  |
    When executing query:
      """
      USE ldbc match (src:Person)-[e@KNOWS]->(dst) where src.id=1 return type(src), type(e), type(dst)
      """
    Then the result should be, in any order:
      | type(src) | type(e) | type(dst) |
      | "Person"  | "KNOWS" | "Person"  |

  Scenario: Node Filter With Element Type Predicate
    When executing query:
      """
      USE ldbc MATCH (v) WHERE v.id=1 AND v IS ELEMENT TYPED Person RETURN v.id, type(v)
      """
    Then the result should be, in any order:
      | v.id | type(v)  |
      | 1    | "Person" |
    When executing query:
      """
      USE ldbc match (v) where v.id=1 AND v IS ELEMENT TYPED [Person,Tag] return v.id, type(v), v IS ELEMENT TYPED Person AS is_person
      """
    Then the result should be, in any order:
      | v.id | type(v)  | is_person |
      | 1    | "Tag"    | false     |
      | 1    | "Person" | true      |
    When executing query:
      """
      USE ldbc match (v) where v.id=1 AND v IS ELEMENT TYPED !Person return v.id, type(v)
      """
    Then the result should be, in any order:
      | v.id | type(v)        |
      | 1    | "TagClass"     |
      | 1    | "Comment"      |
      | 1    | "Post"         |
      | 1    | "Place"        |
      | 1    | "Tag"          |
      | 1    | "Forum"        |
      | 1    | "Organisation" |
    When executing query:
      """
      USE ldbc match (v) where v.id=1 AND v IS NOT ELEMENT TYPED Person return v.id, type(v), v @!Person as is_not_person
      """
    Then the result should be, in any order:
      | v.id | type(v)        | is_not_person |
      | 1    | "Place"        | true          |
      | 1    | "Tag"          | true          |
      | 1    | "Post"         | true          |
      | 1    | "Comment"      | true          |
      | 1    | "Organisation" | true          |
      | 1    | "Forum"        | true          |
      | 1    | "TagClass"     | true          |
    When executing query:
      """
      USE ldbc match (v) where v.id=1 AND v IS NOT ELEMENT TYPED !Person return v.id, type(v), v IS NOT ELEMENT TYPED Person as is_not_person
      """
    Then the result should be, in any order:
      | v.id | type(v)  | is_not_person |
      | 1    | "Person" | false         |
    When executing query:
      """
      USE ldbc match (v) where v.id=1 AND v@![Person,Tag] return v.id, type(v)
      """
    Then the result should be, in any order:
      | v.id | type(v)        |
      | 1    | "Post"         |
      | 1    | "Organisation" |
      | 1    | "TagClass"     |
      | 1    | "Place"        |
      | 1    | "Forum"        |
      | 1    | "Comment"      |
    # constant-fold + literal mixed in IS ELEMENT TYPED set filter
    When executing query:
      """
      USE ldbc {
        VALUE s = CASE WHEN true THEN "Person" ELSE "Forum" END
        MATCH (v) WHERE v.id=1 AND v IS ELEMENT TYPED [s,Tag]
        RETURN type(v)
      }
      """
    Then the result should be, in any order:
      | type(v)  |
      | "Person" |
      | "Tag"    |
    # runtime filter path: iterated variable in FOR drives dynamic IS ELEMENT TYPED filter
    When executing query:
      """
      USE ldbc {
        LET ts = LIST["Person", "Tag"]
        FOR t IN ts
        MATCH (v@t) WHERE v.id = 1
        RETURN type(v)
      }
      """
    Then the result should be, in any order:
      | type(v)  |
      | "Person" |
      | "Tag"    |
    # runtime filter path: iterated variable from NEXT pipeline drives dynamic IS ELEMENT TYPED filter
    When executing query:
      """
      USE ldbc {
        MATCH (v:Person{id:2}) RETURN type(v) AS t
        NEXT
        MATCH (v@t) WHERE v.id = 1
        RETURN type(v)
      }
      """
    Then the result should be, in any order:
      | type(v)  |
      | "Person" |
    # runtime filter path: negated iterated variable from NEXT pipeline drives dynamic IS ELEMENT TYPED filter
    When executing query:
      """
      USE ldbc {
        MATCH (v:Person{id:2}) RETURN type(v) AS t
        NEXT
        MATCH (v@!t) WHERE v.id = 1
        RETURN type(v)
      }
      """
    Then the result should be, in any order:
      | type(v)        |
      | "TagClass"     |
      | "Comment"      |
      | "Post"         |
      | "Place"        |
      | "Tag"          |
      | "Forum"        |
      | "Organisation" |
    When executing query:
      """
      USE ldbc LET v=1 FILTER WHERE v IS ELEMENT TYPED Person RETURN v
      """
    Then an Error should be raised: "[NS211]: Invalid type expression input: `v`, expect NODE or EDGE type but got `INT32`"

  Scenario: Edge Filter With Element Type Predicate
    When executing query:
      """
      USE ldbc match (src:Person)-[e]->(dst) where src.id=1 AND e IS ELEMENT TYPED KNOWS return type(src), type(e), type(dst)
      """
    Then the result should be, in any order:
      | type(src) | type(e) | type(dst) |
      | "Person"  | "KNOWS" | "Person"  |
    When executing query:
      """
      USE ldbc match (src:Person)-[e]->(dst) where src.id=1 AND e @KNOWS return type(src), type(e), type(dst)
      """
    Then the result should be, in any order:
      | type(src) | type(e) | type(dst) |
      | "Person"  | "KNOWS" | "Person"  |
    When executing query:
      """
      USE ldbc match (src:Person)-[e]->(dst) where src.id=1 AND e @[KNOWS,WORK_AT] return type(src), type(e), type(dst)
      """
    Then the result should be, in any order:
      | type(src) | type(e)   | type(dst)      |
      | "Person"  | "WORK_AT" | "Organisation" |
      | "Person"  | "KNOWS"   | "Person"       |
    When executing query:
      """
      USE ldbc match (src:Person)-[e]->(dst) where src.id=1 AND e @!KNOWS return type(src), type(e), type(dst)
      """
    Then the result should be, in any order:
      | type(src) | type(e)           | type(dst)      |
      | "Person"  | "FOLLOWS"         | "Person"       |
      | "Person"  | "HAS_INTEREST"    | "Tag"          |
      | "Person"  | "STUDY_AT"        | "Organisation" |
      | "Person"  | "WORK_AT"         | "Organisation" |
      | "Person"  | "LIKES_1"         | "Post"         |
      | "Person"  | "LIKES_2"         | "Comment"      |
      | "Person"  | "IS_LOCATED_IN_1" | "Place"        |
    When executing query:
      """
      USE ldbc match (src:Person)-[e]->(dst) where src.id=1 AND e@![KNOWS,WORK_AT] return type(src), type(e), type(dst)
      """
    Then the result should be, in any order:
      | type(src) | type(e)           | type(dst)      |
      | "Person"  | "FOLLOWS"         | "Person"       |
      | "Person"  | "LIKES_2"         | "Comment"      |
      | "Person"  | "STUDY_AT"        | "Organisation" |
      | "Person"  | "LIKES_1"         | "Post"         |
      | "Person"  | "IS_LOCATED_IN_1" | "Place"        |
      | "Person"  | "HAS_INTEREST"    | "Tag"          |
    # constant-fold + literal mixed in edge type filter set
    When executing query:
      """
      USE ldbc {
        VALUE et = CASE WHEN true THEN "KNOWS" ELSE "FOLLOWS" END
        MATCH (src:Person)-[e]->(dst)
        WHERE src.id=1 AND e @[et,WORK_AT]
        RETURN type(src), type(e), type(dst)
      }
      """
    Then the result should be, in any order:
      | type(src) | type(e)   | type(dst)      |
      | "Person"  | "WORK_AT" | "Organisation" |
      | "Person"  | "KNOWS"   | "Person"       |
    # runtime filter path: iterated variable in FOR drives dynamic edge IS ELEMENT TYPED filter
    When executing query:
      """
      USE ldbc {
        LET ets = LIST["KNOWS", "WORK_AT"]
        FOR et IN ets
        MATCH (src:Person)-[e@et]->(dst)
        WHERE src.id = 1
        RETURN type(src), type(e), type(dst)
      }
      """
    Then the result should be, in any order:
      | type(src) | type(e)   | type(dst)      |
      | "Person"  | "WORK_AT" | "Organisation" |
      | "Person"  | "KNOWS"   | "Person"       |
    # runtime filter path: iterated variable from NEXT pipeline drives dynamic edge IS ELEMENT TYPED filter
    When executing query:
      """
      USE ldbc {
        MATCH (:Person{id:1})-[e:KNOWS]->(:Person) RETURN type(e) AS t
        NEXT
        MATCH (src:Person)-[e@t]->(dst)
        WHERE src.id = 1
        RETURN type(src), type(e), type(dst)
      }
      """
    Then the result should be, in any order:
      | type(src) | type(e) | type(dst) |
      | "Person"  | "KNOWS" | "Person"  |
    # runtime filter path: negated iterated variable from NEXT pipeline drives dynamic edge IS ELEMENT TYPED filter
    When executing query:
      """
      USE ldbc {
        MATCH (:Person{id:1})-[e:KNOWS]->(:Person) RETURN type(e) AS t
        NEXT
        MATCH (src:Person)-[e@!t]->(dst)
        WHERE src.id = 1
        RETURN type(src), type(e), type(dst)
      }
      """
    Then the result should be, in any order:
      | type(src) | type(e)           | type(dst)      |
      | "Person"  | "FOLLOWS"         | "Person"       |
      | "Person"  | "HAS_INTEREST"    | "Tag"          |
      | "Person"  | "STUDY_AT"        | "Organisation" |
      | "Person"  | "WORK_AT"         | "Organisation" |
      | "Person"  | "LIKES_1"         | "Post"         |
      | "Person"  | "LIKES_2"         | "Comment"      |
      | "Person"  | "IS_LOCATED_IN_1" | "Place"        |
