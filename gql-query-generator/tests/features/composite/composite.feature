# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: Composite query statement

  Scenario: basic composite
    When executing query:
      """
      RETURN 1 AS v UNION RETURN 1 AS v
      """
    Then the result should be, in any order:
      | v |
      | 1 |
    When executing query:
      """
      RETURN 1 AS v UNION ALL RETURN 1 AS v
      """
    Then the result should be, in any order:
      | v |
      | 1 |
      | 1 |
    When executing query:
      """
      RETURN 1 AS v UNION RETURN 2 AS v
      """
    Then the result should be, in any order:
      | v |
      | 1 |
      | 2 |
    When executing query:
      """
      FOR i IN LIST[4,1,2,3,3] RETURN i
      UNION ALL
      FOR i IN LIST[11,2,2,22,33,33] RETURN i ORDER BY i OFFSET 1 LIMIT 2
      """
    Then the result should be, in any order:
      | i  |
      | 4  |
      | 1  |
      | 2  |
      | 3  |
      | 3  |
      | 2  |
      | 11 |
    When executing query:
      """
      FOR i IN LIST[4,1,2,3,3] RETURN i
      UNION
      FOR i IN LIST[11,2,2,22,33,33] RETURN i ORDER BY i OFFSET 1 LIMIT 2
      """
    Then the result should be, in any order:
      | i  |
      | 4  |
      | 1  |
      | 2  |
      | 3  |
      | 11 |
    When executing query:
      """
      RETURN 1 AS v INTERSECT RETURN 2 AS v
      """
    Then the result should be, in any order:
      | v |
    When executing query:
      """
      RETURN 1 AS v INTERSECT RETURN 1 AS v
      """
    Then the result should be, in any order:
      | v |
      | 1 |
    When executing query:
      """
      FOR i IN LIST[4,1,2,3,2,3] RETURN i
      INTERSECT ALL
      FOR i IN LIST[11,2,2,2,22,33,33] RETURN i ORDER BY i OFFSET 1 LIMIT 2
      """
    Then the result should be, in any order:
      | i |
      | 2 |
      | 2 |
    When executing query:
      """
      FOR i IN LIST[4,1,2,3,2,3] RETURN i
      INTERSECT
      FOR i IN LIST[11,2,2,2,22,33,33] RETURN i ORDER BY i OFFSET 1 LIMIT 2
      """
    Then the result should be, in any order:
      | i |
      | 2 |
    When executing query:
      """
      RETURN 1 AS v EXCEPT RETURN 2 AS v
      """
    Then the result should be, in any order:
      | v |
      | 1 |
    When executing query:
      """
      RETURN 1 AS v EXCEPT RETURN 1 AS v
      """
    Then the result should be, in any order:
      | v |
    When executing query:
      """
      FOR i IN LIST[4,1,2,3,2,3] RETURN i
      EXCEPT ALL
      FOR i IN LIST[11,2,2,2,22,33,33] RETURN i ORDER BY i OFFSET 1 LIMIT 2
      """
    Then the result should be, in any order:
      | i |
      | 4 |
      | 1 |
      | 3 |
      | 3 |
    When executing query:
      """
      FOR i IN LIST[4,1,2,3,2,3] RETURN i
      EXCEPT
      FOR i IN LIST[11,2,2,2,22,33,33] RETURN i ORDER BY i OFFSET 1 LIMIT 2
      """
    Then the result should be, in any order:
      | i |
      | 4 |
      | 1 |
      | 3 |
    When executing query:
      """
      RETURN 1 AS a
      UNION
      RETURN 2 AS a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
      | 2 |
    When executing query:
      """
      RETURN 1 AS a
      UNION
      RETURN 2 AS a
      NEXT
      RETURN a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
      | 2 |
    When executing query:
      """
      RETURN 1 AS a
      NEXT
      RETURN 2 AS a
      UNION ALL
      RETURN 3 AS a
      """
    Then the result should be, in any order:
      | a |
      | 2 |
      | 3 |
    When executing query:
      """
      RETURN 1 AS a
      UNION ALL
      RETURN 2 AS a
      NEXT
      RETURN 3 AS a
      """
    Then the result should be, in any order:
      | a |
      | 3 |
      | 3 |

  Scenario: implicit cast
    When executing query:
      """
      RETURN 1 AS a UNION  RETURN 2.2 AS a
      """
    Then the result should be, in any order:
      | a    |
      | 1M   |
      | 2.2M |
    When executing query:
      """
      RETURN [1, 2] AS a UNION  RETURN [3.5, 4.2] AS a
      """
    Then the result should be, in any order:
      | a                 |
      | LIST [1.0M, 2.0M] |
      | LIST [3.5M, 4.2M] |
    When executing query:
      """
      RETURN 1 AS a UNION  RETURN "1" AS a
      """
    Then an Error should be raised: "[NS010]: Semantic error, column `a` has incompatible types: INT32, STRING"
    When executing query:
      """
      FOR i IN [1, 2] RETURN i AS a
      UNION
      FOR i IN [2.0, 3.0] RETURN i AS a
      """
    Then the result should be, in any order:
      | a    |
      | 1M   |
      | 2.0M |
      | 3.0M |
    When executing query:
      """
      FOR i IN [1, 2] RETURN i AS a
      INTERSECT
      FOR i IN [2.0, 3.0] RETURN i AS a
      """
    Then the result should be, in any order:
      | a    |
      | 2.0M |
    When executing query:
      """
      FOR i IN [1, 2] RETURN i AS a
      EXCEPT
      FOR i IN [2.0, 3.0] RETURN i AS a
      """
    Then the result should be, in any order:
      | a    |
      | 1.0M |

  Scenario: composite match
    When executing query:
      """
      USE ldbc MATCH (v:City) RETURN v
      UNION
      USE ldbc MATCH (v:Comment) RETURN v
      """
    Then the result should be, in any order:
      | v                                                                                                                                    |
      | ({id:1,kind:"city",name:"Beijing",url:"https://beijing.com"})                                                                        |
      | ({browserUsed:"IE",content:"comment3",creationDate:DATETIME "2023-03-03T10:00:40.213000",extent:8,id:3,locationIP:"192.168.3"})      |
      | ({id:3,kind:"city",name:"Hangzhou",url:"https://hangzhou.com"})                                                                      |
      | ({browserUsed:"Chrome",content:"comment4",creationDate:DATETIME "2024-04-04T10:00:40.213000",extent:8,id:4,locationIP:"192.168.4"})  |
      | ({id:6,kind:"city",name:"Shenzhen",url:"https://shenzhen.com"})                                                                      |
      | ({id:2,kind:"city",name:"Shanghai",url:"https://shanghai.com"})                                                                      |
      | ({browserUsed:"Firefox",content:"comment2",creationDate:DATETIME "2002-02-02T10:00:40.213000",extent:8,id:2,locationIP:"192.168.2"}) |
      | ({id:4,kind:"city",name:"Chongqing",url:"https://chongqing.com"})                                                                    |
      | ({browserUsed:"Chrome",content:"comment1",creationDate:DATETIME "1991-01-01T10:00:40.213000",extent:8,id:1,locationIP:"192.168.1"})  |
      | ({id:5,kind:"city",name:"Chengdu",url:"https://chengdu.com"})                                                                        |
    When executing query:
      """
      USE ldbc MATCH (v:City) RETURN v
      UNION
      USE ldbc MATCH (v:Comment) RETURN v
      EXCEPT
      USE ldbc MATCH (v:City) RETURN v
      """
    Then an Error should be raised: "[42N42]: Invalid syntax, all directly contained query conjunctions within a composite query expression must be the same"
    When executing query:
      """
      USE ldbc
      CALL {
        MATCH (v:City) RETURN v
        UNION
        MATCH (v:Comment) RETURN v
      }
      RETURN v
      INTERSECT
      USE ldbc MATCH (v:Message&!Post) RETURN v
      """
    Then the result should be, in any order:
      | v                                                                                                                                    |
      | ({browserUsed:"IE",content:"comment3",creationDate:DATETIME "2023-03-03T10:00:40.213000",extent:8,id:3,locationIP:"192.168.3"})      |
      | ({browserUsed:"Chrome",content:"comment4",creationDate:DATETIME "2024-04-04T10:00:40.213000",extent:8,id:4,locationIP:"192.168.4"})  |
      | ({browserUsed:"Chrome",content:"comment1",creationDate:DATETIME "1991-01-01T10:00:40.213000",extent:8,id:1,locationIP:"192.168.1"})  |
      | ({browserUsed:"Firefox",content:"comment2",creationDate:DATETIME "2002-02-02T10:00:40.213000",extent:8,id:2,locationIP:"192.168.2"}) |
    When executing query:
      """
      USE ldbc MATCH (a:City)-[:IS_PART_OF]->(b:City) where a.id>1 RETURN a, b
      NEXT
      USE ldbc MATCH (v:City)-[:IS_PART_OF]-(a:City)  RETURN v
      UNION
      USE ldbc MATCH (v:Person)->(a) RETURN v
      """
    Then the result should be, in any order:
      | v                                                                                                                                                                                                       |
      | ({id:5,kind:"city",name:"Chengdu",url:"https://chengdu.com"})                                                                                                                                           |
      | ({id:6,kind:"city",name:"Shenzhen",url:"https://shenzhen.com"})                                                                                                                                         |
      | ({birthday:DATE "2001-04-25",browserUsed:"IE",creationDate:DATETIME "2021-01-01T11:00:40.213000",firstName:"Tim",gender:"male",id:2,lastName:"Duncan",locationIP:"192.168.2",vec:VECTOR [4.0,5.0,6.0]}) |
      | ({birthday:DATE "1995-06-12",browserUsed:"Firefox",creationDate:DATETIME "2021-01-01T12:00:40.213000",firstName:"Ming",gender:"male",id:3,lastName:"Yao",locationIP:"192.168.3",vec:VECTOR [7,8,9]})    |

  Scenario: errors
    When executing query:
      """
      USE ldbc MATCH (v:City)-[e:IS_PART_OF]-() RETURN v,e
      UNION
      USE ldbc MATCH (v:Comment) RETURN v
      """
    Then an Error should be raised: "[NS004]: Semantic error, column size `1` vs. `2` mismatched for the linear query of composite query statement: `USE ldbc MATCH (v:Comment) RETURN v`"
    When executing query:
      """
      USE ldbc MATCH (v:City)-[e:IS_PART_OF]-() RETURN e
      UNION
      USE ldbc MATCH (v:Comment) RETURN v
      """
    Then an Error should be raised: "[NS007]: Semantic error, column name `e` vs. `v` mismatched for the linear query of composite query statement: `USE ldbc MATCH (v:Comment) RETURN v`"

  Scenario: multiple union
    When executing query:
      """
      RETURN 1 UNION RETURN 1 UNION RETURN 1
      """
    Then the result should be, in any order:
      | 1 |
      | 1 |

  Scenario: bug fix union-next-let
    When executing query:
      """
      $tag="China",$startDate=DATETIME "2012-11-21T11:28:30.662",$endDate=DATETIME "2012-11-21T11:28:30.662"
      USE ldbc
      MATCH (tag:Tag {name: $tag})
      OPTIONAL MATCH (tag)<-[:HAS_TAG]-(message:Message)-[:HAS_CREATOR]->(person:Person)
      WHERE $startDate < message.creationDate
      AND message.creationDate < $endDate
      RETURN
        tag,
        person
      UNION
      USE ldbc
      OPTIONAL MATCH (tag)<-[:HAS_TAG]-(message:Message)-[:HAS_CREATOR]->(person:Person)
      WHERE $startDate < message.creationDate
        AND message.creationDate < $endDate
      RETURN
        DISTINCT tag,
        person
      NEXT
      USE ldbc
      LET score = CASE
        WHEN EXISTS ((tag)<-[interest:HAS_INTEREST]-(person)) THEN 100
        WHEN EXISTS (MATCH (tag)<-[:HAS_TAG]-(message:Message)-[:HAS_CREATOR]->(person:Person)
          WHERE $startDate < message.creationDate
            AND message.creationDate < $endDate) THEN 100
        ELSE 0 END
      RETURN
        tag,
        person,
        score
      """
    Then the execution should be successful

  Scenario: UnionInsideNestedSubquery
    When executing query:
      """
      LET a=1, b=2
      FILTER EXISTS {
        USE ldbc
        MATCH (v:Person) WHERE v.id>a AND v.id<b RETURN v.id AS id
        UNION
        USE ldbc
        MATCH (v:Person) WHERE v.id>a+1 AND v.id<b+2 RETURN v.id AS id
      }
      RETURN a,b
      """
    Then the result should be, in any order:
      | a | b |
      | 1 | 2 |
    When executing query:
      """
      LET a=1,b=2
      FILTER EXISTS {
        USE ldbc
        MATCH (v:Person) WHERE v.id>a RETURN v.id AS id
        UNION
        USE ldbc
        MATCH (v:Person) WHERE v.id<b+2 RETURN v.id AS id
      }
      RETURN a,b
      """
    Then the result should be, in any order:
      | a | b |
      | 1 | 2 |

  Scenario: Last composite statement
    When executing query:
      """
      LET id = 2
      RETURN EXISTS {
      RETURN 1 AS id UNION RETURN 2 AS id
      } AS c
      """
    Then the result should be, in any order:
      | c    |
      | true |
    When executing query:
      """
      LET id = 2
      RETURN EXISTS {
          RETURN 1 AS id UNION RETURN 2 AS id NEXT RETURN *
      } AS c
      """
    Then an Error should be raised: "[NS216]: The returned column `id` conflicts with parent scope variables. Please use a unique alias to distinguish them"
    When executing query:
      """
      LET id = 2
      RETURN EXISTS {
          RETURN 1 NEXT RETURN 1 AS id UNION RETURN 2 AS id
      } AS c
      """
    Then the result should be, in any order:
      | c    |
      | true |
