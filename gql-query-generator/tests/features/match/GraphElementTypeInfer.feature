# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: Graph Element Type Inference

  Scenario: vesoft-inc/nebula-ng#4803
    When executing query:
      """
      USE ldbc MATCH (v)-[e]-{2,3}()-[e2]->(v) RETURN COUNT(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt  |
      | 4723 |

  Scenario: vesoft-inc/nebula-ng#5240
    When executing query:
      """
      USE ldbc MATCH (v1)-[e1]->{0,}(v2)-[e2]->{0, }(v3) RETURN COUNT(*) AS cnt GROUP BY ()
      """
    Then an Error should be raised:
      """
      [NS219]: Unbounded quantifiers in non-restrictive and non-selective path patterns may lead to infinite result sets. Consider using restrictive path modes (e.g., 'trail'), selective path search prefixes (e.g., 'any shortest'), 'different edges' match mode, or setting an upper bound
      """

  Scenario: vesoft-inc/nebula-ng#5122
    When executing query:
      """
      USE ldbc MATCH (v:Person{id:2})<-[e1:LIKES]->(v2:Comment)<-[e2:LIKES]->(v3:Person)
      RETURN COUNT(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 1   |
    When executing query:
      """
      USE ldbc MATCH (v:Person{id:2})<-[e:LIKES]->{2}(v3:Person)
      RETURN COUNT(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 2   |

  Scenario: vesoft-inc/nebula-ng#5873
    When executing query:
      """
      USE ldbc MATCH p = (s:Person{id:1})-[e]->{1,3}(t:Person{id:1})
      ORDER BY length(p)
      RETURN transform(nodes(p), x -> coalesce(x.firstName, x.imageFile)) AS a
      """
    Then the execution should be successful

  @sf01
  Scenario: vesoft-inc/nebula-ng#4695
    When executing query:
      """
      USE sf01
      MATCH (v:Person{id:318})-[e@[PERSON_LIKES_COMMENT,COMMENT_HAS_CREATOR_PERSON]]->{2}(v2:Person)
      WHERE v = v2
      RETURN length(e) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 2   |
      | 2   |
    When executing query:
      """
      USE sf01
      MATCH (v:Person{id:318})-[e@[PERSON_LIKES_COMMENT,COMMENT_HAS_CREATOR_PERSON]]->{1,2}(v2:Person)
      WHERE v = v2
      RETURN length(e) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 2   |
      | 2   |

  Scenario: validate label and element type
    When executing query:
      """
      USE ldbc
      MATCH (a:PeRson)
      RETURN a
      """
    Then an Error should be raised: "[NS228]: node label `PeRson` not found in graph type `ldbc_type`"
    When executing query:
      """
      USE ldbc
      MATCH (a:Person|tag)
      RETURN a
      """
    Then an Error should be raised: "[NS228]: node label `tag` not found in graph type `ldbc_type`"
    When executing query:
      """
      USE ldbc
      MATCH (a:Txg&PeRson)
      RETURN a
      """
    Then an Error should be raised: "[NS228]: node label `Txg` not found in graph type `ldbc_type`"
    When executing query:
      """
      USE ldbc
      MATCH (a:!person)
      RETURN a
      """
    Then an Error should be raised: "[NS228]: node label `person` not found in graph type `ldbc_type`"
    When executing query:
      """
      USE ldbc
      MATCH (a)-[e:KNOW]->()
      RETURN e
      """
    Then an Error should be raised: "[NS228]: edge label `KNOW` not found in graph type `ldbc_type`"
    When executing query:
      """
      USE ldbc
      MATCH (a@[Person,txg])
      RETURN a
      """
    Then an Error should be raised: "[NS229]: node type `txg` not found in graph type `ldbc_type`"
    When executing query:
      """
      USE ldbc
      MATCH (a@![Person,txg])
      RETURN a
      """
    Then an Error should be raised: "[NS229]: node type `txg` not found in graph type `ldbc_type`"
    When executing query:
      """
      USE ldbc
      MATCH (a)-[e@KNOW]->()
      RETURN e
      """
    Then an Error should be raised: "[NS229]: edge type `KNOW` not found in graph type `ldbc_type`"
    When executing query:
      """
      USE ldbc
      MATCH (a:Tag)
      RETURN a IS LABELED Comment
      """
    Then an Error should be raised: "[NS228]: node label `Comment` not found in NODE<(Tag)>"
    When executing query:
      """
      USE ldbc
      MATCH (a)-[e:KNOWS]->(b)
      WHERE e IS LABELED KNOW
      RETURN count(*) GROUP BY ()
      """
    Then an Error should be raised: "[NS228]: edge label `KNOW` not found in EDGE<(Person)-[KNOWS]->(Person)>"
    When executing query:
      """
      USE ldbc
      MATCH (a:Tag)
      RETURN a IS NOT ELEMENT TYPED Comment
      """
    Then an Error should be raised: "[NS229]: node type `Comment` not found in NODE<(Tag)>"
    When executing query:
      """
      USE ldbc
      MATCH (a)-[e:KNOWS]->(b)
      RETURN e IS ELEMENT TYPED KNOW
      """
    Then an Error should be raised: "[NS229]: edge type `KNOW` not found in EDGE<(Person)-[KNOWS]->(Person)>"

  Scenario: validate property
    When executing query:
      """
      USE ldbc
      MATCH (a)-[e:KNOWS]->(b)
      RETURN e.creationdate
      """
    Then an Error should be raised: "[NS230]: property `creationdate` not found in EDGE<(Person)-[KNOWS]->(Person)>"
    When executing query:
      """
      USE ldbc
      MATCH (a:Person)
      RETURN a.ag
      """
    Then an Error should be raised: "[NS230]: property `ag` not found in NODE<(Person)>"
    When executing query:
      """
      USE ldbc
      LET r = RECORD{prop_1:1,prop_2:2}
      RETURN r.prop_3
      """
    Then an Error should be raised: "[NS230]: property `prop_3` not found in RECORD{prop_1 INT32, prop_2 INT32}"
    When executing query:
      """
      USE ldbc
      MATCH (a:Person|Tag)
      RETURN a.url
      """
    Then the result should be, in any order:
      | a.url              |
      | null               |
      | "https://tag4.com" |
      | "https://tag2.com" |
      | null               |
      | "https://tag3.com" |
      | null               |
      | "https://tag1.com" |
      | null               |
    When executing query:
      """
      USE ldbc
      MATCH (a)-[e:KNOWS|WORK_AT]->(b)
      RETURN e.workFrom
      """
    Then the result should be, in any order:
      | e.workFrom |
      | null       |
      | 3          |
      | null       |
      | 2          |
      | null       |
      | 1          |
    When executing query:
      """
      RETURN RECORD{prop_1:1} as r
      UNION
      RETURN RECORD{prop_1:null} as r
      NEXT
      RETURN r.prop_1
      """
    Then the result should be, in any order:
      | r.prop_1 |
      | 1        |
      | null     |
    When executing query:
      """
      USE ldbc
      LET r = RECORD{null_p:null}
      RETURN r.null_p
      """
    Then the result should be, in any order:
      | r.null_p |
      | null     |

  Scenario: element type infer failed
    When executing query:
      """
      USE ldbc
      MATCH (a:Person&Comment)
      RETURN a
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `(a:(Person) & (Comment))` was found"
    When executing query:
      """
      USE ldbc
      MATCH (a)-[e:HAS_TYPE&FOLLOWS]->(b)
      RETURN e
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `-[e:(HAS_TYPE) & (FOLLOWS)]->` was found"
    When executing query:
      """
      USE ldbc
      MATCH (a:Person)-[e:FOLLOWS]->(b:Comment)
      RETURN e
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `(a:Person)-[e:FOLLOWS]->(b:Comment)` was found"
    When executing query:
      """
      USE ldbc
      MATCH (a:Person),(a:Comment)
      RETURN a
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `(a:Person),(a:Comment)` was found"
    When executing query:
      """
      USE ldbc
      MATCH (a)-[e:WORK_AT]->{2}(b)
      RETURN a
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `-[e:WORK_AT]->{2}` was found"
    When executing query:
      """
      USE ldbc
      MATCH (a:Person)((x:Comment)-[:FOLLOWS]->(y)){1}(b)
      RETURN a
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `(x:Comment)` was found"
    When executing query:
      """
      USE ldbc
      MATCH (a:Person)((x:Person)-[:FOLLOWS]->(y:Person)){1}(b:Comment)
      RETURN a
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `(WALK (x:Person)-[:FOLLOWS]->(y:Person)){1}` was found"

  # Issue vesoft-inc/nebula-ng#4938: Incorrect edge type inference
  # HAS_INTEREST only goes from Person to Tag, so undirected pattern from Person
  # should only match forward direction (Person->Tag), not backward
  Scenario: vesoft-inc/nebula-ng#4938 - Edge type filtering by connectivity
    # LDBC has 3 HAS_INTEREST edges: Person(1)->Tag(1), Person(2)->Tag(2), Person(3)->Tag(3)
    # When Person is the source, undirected edge should only scan forward direction
    # (not backward, since Tag cannot be source of HAS_INTEREST)
    When executing query:
      """
      USE ldbc MATCH (a:Person)-[r:HAS_INTEREST]-(b) RETURN count(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 3   |
    # Same test with explicit direction - should get same result (3 edges)
    When executing query:
      """
      USE ldbc MATCH (a:Person)-[r:HAS_INTEREST]->(b) RETURN count(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 3   |
    # Swapped node order: (:Tag)-[e]-(:Person) undirected should infer same edges
    When executing query:
      """
      USE ldbc MATCH (:Tag)-[e]-(:Person) RETURN count(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 3   |
    # Bidirectional syntax: (:Person)<-[e]->(:Tag) should infer same edges
    When executing query:
      """
      USE ldbc MATCH (:Person)<-[e]->(:Tag) RETURN count(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 3   |
    # Reverse direction: Tag cannot be source of HAS_INTEREST, so pattern is invalid
    # The system correctly detects no valid edge types and raises an error
    When executing query:
      """
      USE ldbc MATCH (a:Person)<-[r:HAS_INTEREST]-(b) RETURN count(*) AS cnt GROUP BY ()
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `(a:Person)<-[r:HAS_INTEREST]-(b)` was found"

  # Issue vesoft-inc/nebula-ng#4938: Test with sf01 dataset
  # Undirected edge between Person and Tag should only scan edges that can connect them
  @sf01
  Scenario: vesoft-inc/nebula-ng#4938 - Edge type filtering with sf01 Person-Tag pattern
    # PERSON_HAS_INTEREST only goes from Person to Tag, no Tag->Person edges exist
    # Undirected pattern should return same result as directed pattern
    When executing query:
      """
      USE sf01 MATCH (v:Person)-[e]->(t:Tag) RETURN count(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt   |
      | 35475 |
    # Undirected should get same count (no double counting from reverse direction)
    When executing query:
      """
      USE sf01 MATCH (v:Person)-[e]-(t:Tag) RETURN count(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt   |
      | 35475 |
