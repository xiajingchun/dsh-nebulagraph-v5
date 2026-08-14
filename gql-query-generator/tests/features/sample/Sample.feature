# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: Sample

  Scenario: Sampling on storage graph
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS sample_type AS {
      NODE Person (LABEL Person {id INT64 PRIMARY KEY, firstName STRING, lastName STRING, gender STRING, birthday DATE, creationDate LOCAL DATETIME, locationIP STRING, browserUsed STRING, vec VECTOR<3,float> NOT NULL}),
      NODE Organisation (LABELS University&Company {id INT64 PRIMARY KEY, kind STRING, name STRING, url STRING}),
      EDGE WORK_AT (Person)-[:WORK_AT{workFrom INT32}]->(Organisation),
      EDGE KNOWS (Person)-[:KNOWS{creationDate LOCAL DATETIME  MULTIEDGE KEY, vec VECTOR<3,float>}]->(Person),
      EDGE KNOWS_EACHOTHER (Person)~[:KNOWS{id INT MULTIEDGE KEY}]~(Person),
      EDGE STUDY_AT (Person)-[:STUDY_AT{classYear INT32}]->(Organisation)}
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS sample_test sample_type
      """
    Then the execution should be successful
    And graph "sample_test" should be ready to use
    When executing query:
      """
      USE sample_test
      FOR i IN range(1,10)
      INSERT (a@Person{id:i, vec: case when i>5 then vector(1,2,3) else vector(4,5,6) end})
      """
    Then the execution should be successful
    When executing query:
      """
      USE sample_test
      FOR i IN range(1,10)
      INSERT (a@Organisation{id:i})
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {src, dst} =
      (1,1),
      (2,1), (2,2),
      (3,1), (3,2), (3,3),
      (4,1), (4,2), (4,3), (4,4),
      (5,1), (5,2), (5,3), (5,4), (5,5),
      (6,1), (6,2), (6,3), (6,4), (6,5), (6,6),
      (7,1), (7,2), (7,3), (7,4), (7,5), (7,6), (7, 7),
      (8,1), (8,2), (8,3), (8,4),
      (9,1), (9,2), (9,3),
      (10,1), (10,2)
      USE sample_test
      FOR r IN t
      MATCH (a@Person) WHERE a.id = r.src
      MATCH (b@Person) WHERE b.id = r.dst
      INSERT (a)-[:KNOWS{creationDate: local_datetime('2025-07-23T00:00:00.000')+duration({days:r.src,hours:r.dst}), vec: case when r.src>5 then vector(1,2,3) else vector(4,5,6) end}]->(b)
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {src, dst} =
      (1,1), (1,3),
      (2,1), (2,2), (2,3), (2,6),
      (3,1), (3,4),  (3,7),
      (4,2),
      (5,1), (5,5),
      (6,2), (6,6), (6,10),
      (7,3), (7,7),
      (8,4),
      (9,5), (9,9), (9,10),
      (10,6), (10,7), (10,8), (10,9), (10,10), (10,1), (10,2)
      USE sample_test
      FOR r IN t
      MATCH (a@Person) WHERE a.id = r.src
      MATCH (b@Organisation) WHERE b.id = r.dst
      INSERT (a)-[:WORK_AT]->(b)
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {src, dst} =
      (1,1), (1,2), (1,3), (1,4), (1,5), (1,6), (1,7), (1,8), (1,9), (1,10),
      (2,1), (2,2), (2,3), (2,4), (2,5), (2,6), (2,7), (2,8), (2,9),
      (3,1), (3,2), (3,3), (3,4), (3,5), (3,6), (3,7), (3,8),
      (4,1), (4,2), (4,3), (4,4), (4,5), (4,6), (4,7),
      (5,1), (5,2), (5,3), (5,4), (5,5), (5,6),
      (6,1), (6,2), (6,3), (6,4), (6,5),
      (7,1), (7,2), (7,3), (7,4),
      (8,1), (8,2), (8,3),
      (9,1), (9,2),
      (10,1)
      USE sample_test
      FOR r IN t
      MATCH (a@Person) WHERE a.id = r.src
      MATCH (b@Organisation) WHERE b.id = r.dst
      INSERT (a)-[:STUDY_AT]->(b)
      """
    Then the execution should be successful
    # first_fetch sampling by default
    When executing query:
      """
      USE sample_test
      MATCH (src:Person)-[:KNOWS SAMPLE RIGHT 100]->(dst)
      RETURN src.id AS srcId, size(collect(dst.id)) AS dstCnt
      ORDER BY srcId
      """
    Then the result should be, in order:
      | srcId | dstCnt |
      | 1     | 1      |
      | 2     | 2      |
      | 3     | 3      |
      | 4     | 4      |
      | 5     | 5      |
      | 6     | 6      |
      | 7     | 7      |
      | 8     | 4      |
      | 9     | 3      |
      | 10    | 2      |
    When executing query:
      """
      USE sample_test
      MATCH (src:Person)-[:KNOWS SAMPLE RIGHT 1]->(dst)
      RETURN src.id AS srcId, size(collect(dst.id)) AS dstCnt
      ORDER BY srcId
      """
    Then the result should be, in order:
      | srcId | dstCnt |
      | 1     | 1      |
      | 2     | 1      |
      | 3     | 1      |
      | 4     | 1      |
      | 5     | 1      |
      | 6     | 1      |
      | 7     | 1      |
      | 8     | 1      |
      | 9     | 1      |
      | 10    | 1      |
    When executing query:
      """
      USE sample_test
      MATCH (src:Person)-[:KNOWS SAMPLE RIGHT 4]->(dst)
      RETURN src.id AS srcId, size(collect(dst.id)) AS dstCnt
      ORDER BY srcId
      """
    Then the result should be, in order:
      | srcId | dstCnt |
      | 1     | 1      |
      | 2     | 2      |
      | 3     | 3      |
      | 4     | 4      |
      | 5     | 4      |
      | 6     | 4      |
      | 7     | 4      |
      | 8     | 4      |
      | 9     | 3      |
      | 10    | 2      |
    When executing query:
      """
      USE sample_test
      MATCH (src:Person)-[:KNOWS SAMPLE RIGHT 33.3%]->(dst)
      RETURN src.id AS srcId, size(collect(dst.id)) AS dstCnt
      ORDER BY srcId
      """
    Then the result should be, in order:
      | srcId | dstCnt |
      | 1     | 1      |
      | 2     | 1      |
      | 3     | 1      |
      | 4     | 2      |
      | 5     | 2      |
      | 6     | 2      |
      | 7     | 3      |
      | 8     | 2      |
      | 9     | 1      |
      | 10    | 1      |
    When executing query:
      """
      USE sample_test
      MATCH (dst:Person)<-[:KNOWS SAMPLE RIGHT FIRST_FETCH 40]-(src)
      RETURN dst.id AS dstId, size(collect(src.id)) AS srcCnt
      ORDER BY dstId
      """
    Then the result should be, in order:
      | dstId | srcCnt |
      | 1     | 10     |
      | 2     | 9      |
      | 3     | 7      |
      | 4     | 5      |
      | 5     | 3      |
      | 6     | 2      |
      | 7     | 1      |
    When executing query:
      """
      USE sample_test
      MATCH (dst:Person)<-[:KNOWS SAMPLE RIGHT FIRST_FETCH 4]-(src)
      RETURN dst.id AS dstId, size(collect(src.id)) AS srcCnt
      ORDER BY dstId
      """
    Then the result should be, in order:
      | dstId | srcCnt |
      | 1     | 4      |
      | 2     | 4      |
      | 3     | 4      |
      | 4     | 4      |
      | 5     | 3      |
      | 6     | 2      |
      | 7     | 1      |
    When executing query:
      """
      USE sample_test
      MATCH (dst:Person)<-[:KNOWS SAMPLE RIGHT FIRST_FETCH 50%]-(src)
      RETURN dst.id AS dstId, size(collect(src.id)) AS srcCnt
      ORDER BY dstId
      """
    Then the result should be, in order:
      | dstId | srcCnt |
      | 1     | 5      |
      | 2     | 5      |
      | 3     | 4      |
      | 4     | 3      |
      | 5     | 2      |
      | 6     | 1      |
      | 7     | 1      |
    # sampling by edge type operator(no node variable)
    When executing query:
      """
      USE sample_test
      MATCH ()-[e:KNOWS SAMPLE RIGHT 3]->()
      RETURN count(*) AS cnt
      """
    # 1+2+3*7+2
    Then the result should be, in order:
      | cnt |
      | 26  |
    When executing query:
      """
      USE sample_test
      MATCH ()-[e:KNOWS SAMPLE RIGHT 50%]->()
      RETURN count(*) AS cnt
      """
    # 1+1+2+2+3+3+4+2+2+1
    Then the result should be, in order:
      | cnt |
      | 21  |
    When executing query:
      """
      USE sample_test
      MATCH ()<-[e:KNOWS SAMPLE RIGHT 3]-()
      RETURN count(*) AS cnt
      """
    # 3*5+2+1
    Then the result should be, in order:
      | cnt |
      | 18  |
    When executing query:
      """
      USE sample_test
      MATCH ()<-[e:KNOWS SAMPLE RIGHT 33.33%]-()
      RETURN count(*) AS cnt
      """
    # 4+3+3+2+1+1+1
    Then the result should be, in order:
      | cnt |
      | 15  |
    When executing query:
      """
      USE sample_test
      MATCH ()<-[e:KNOWS SAMPLE RIGHT 3]->()
      RETURN count(*) AS cnt
      """
    # 26+18
    Then the result should be, in order:
      | cnt |
      | 44  |
    When executing query:
      """
      USE sample_test
      MATCH ()<-[e:KNOWS SAMPLE RIGHT 3]->()
      RETURN count(*) AS cnt
      """
    # 26+18
    Then the result should be, in order:
      | cnt |
      | 44  |
    When executing query:
      """
      USE sample_test
      MATCH ({id:10})-[e:KNOWS SAMPLE RIGHT 3]->()
      RETURN count(*) AS cnt
      """
    Then the result should be, in order:
      | cnt |
      | 2   |
    When executing query:
      """
      USE sample_test
      MATCH ({id:7})-[e:KNOWS SAMPLE RIGHT 3]->()
      RETURN count(*) AS cnt
      """
    Then the result should be, in order:
      | cnt |
      | 3   |
    When executing query:
      """
      USE sample_test
      MATCH ({id:3})-[e:KNOWS SAMPLE RIGHT 3]->(n)
      RETURN n.id AS dstId
      """
    Then the result should be, in any order:
      | dstId |
      | 3     |
      | 1     |
      | 2     |
    # random sampling
    When executing query:
      """
      USE sample_test
      MATCH (src:Person)-[:KNOWS SAMPLE RIGHT RANDOM 1000]->(dst)
      RETURN src.id AS srcId, size(collect(dst.id)) AS dstCnt
      ORDER BY srcId
      """
    Then the result should be, in order:
      | srcId | dstCnt |
      | 1     | 1      |
      | 2     | 2      |
      | 3     | 3      |
      | 4     | 4      |
      | 5     | 5      |
      | 6     | 6      |
      | 7     | 7      |
      | 8     | 4      |
      | 9     | 3      |
      | 10    | 2      |
    When executing query:
      """
      USE sample_test
      MATCH (src:Person)-[:KNOWS SAMPLE RIGHT RANDOM 1]->(dst)
      RETURN src.id AS srcId, size(collect(dst.id)) AS dstCnt
      ORDER BY srcId
      """
    Then the result should be, in order:
      | srcId | dstCnt |
      | 1     | 1      |
      | 2     | 1      |
      | 3     | 1      |
      | 4     | 1      |
      | 5     | 1      |
      | 6     | 1      |
      | 7     | 1      |
      | 8     | 1      |
      | 9     | 1      |
      | 10    | 1      |
    When executing query:
      """
      USE sample_test
      MATCH (src:Person)-[:KNOWS SAMPLE RIGHT RANDOM 4]->(dst)
      RETURN src.id AS srcId, size(collect(dst.id)) AS dstCnt
      ORDER BY srcId
      """
    Then the result should be, in order:
      | srcId | dstCnt |
      | 1     | 1      |
      | 2     | 2      |
      | 3     | 3      |
      | 4     | 4      |
      | 5     | 4      |
      | 6     | 4      |
      | 7     | 4      |
      | 8     | 4      |
      | 9     | 3      |
      | 10    | 2      |
    When executing query:
      """
      USE sample_test
      MATCH (src:Person)-[:KNOWS SAMPLE RIGHT RANDOM 80%]->(dst)
      RETURN src.id AS srcId, size(collect(dst.id)) AS dstCnt
      ORDER BY srcId
      """
    Then the result should be, in order:
      | srcId | dstCnt |
      | 1     | 1      |
      | 2     | 2      |
      | 3     | 3      |
      | 4     | 4      |
      | 5     | 4      |
      | 6     | 5      |
      | 7     | 6      |
      | 8     | 4      |
      | 9     | 3      |
      | 10    | 2      |
    When executing query:
      """
      USE sample_test
      MATCH (dst:Person)<-[:KNOWS SAMPLE RIGHT RANDOM 499999]-(src)
      RETURN dst.id AS dstId, size(collect(src.id)) AS srcCnt
      ORDER BY dstId
      """
    Then the result should be, in order:
      | dstId | srcCnt |
      | 1     | 10     |
      | 2     | 9      |
      | 3     | 7      |
      | 4     | 5      |
      | 5     | 3      |
      | 6     | 2      |
      | 7     | 1      |
    When executing query:
      """
      USE sample_test
      MATCH (dst:Person)<-[:KNOWS SAMPLE RIGHT RANDOM 4]-(src)
      RETURN dst.id AS dstId, size(collect(src.id)) AS srcCnt
      ORDER BY dstId
      """
    Then the result should be, in order:
      | srcId | dstCnt |
      | 1     | 4      |
      | 2     | 4      |
      | 3     | 4      |
      | 4     | 4      |
      | 5     | 3      |
      | 6     | 2      |
      | 7     | 1      |
    When executing query:
      """
      USE sample_test
      MATCH (dst:Person)<-[:KNOWS SAMPLE RIGHT RANDOM 60%]-(src)
      RETURN dst.id AS dstId, size(collect(src.id)) AS srcCnt
      ORDER BY dstId
      """
    Then the result should be, in order:
      | dstId | srcCnt |
      | 1     | 6      |
      | 2     | 6      |
      | 3     | 5      |
      | 4     | 3      |
      | 5     | 2      |
      | 6     | 2      |
      | 7     | 1      |
    # sampling by edge type operator(no node variable)
    When executing query:
      """
      USE sample_test
      MATCH ()-[e:KNOWS SAMPLE RIGHT RANDOM 3]->()
      RETURN count(*) AS cnt
      """
    # 1+2+3*7+2
    Then the result should be, in order:
      | cnt |
      | 26  |
    When executing query:
      """
      USE sample_test
      MATCH ()-[e:KNOWS SAMPLE RIGHT RANDOM 50%]->()
      RETURN count(*) AS cnt
      """
    # 1+1+2+2+3+3+4+2+2+1
    Then the result should be, in order:
      | cnt |
      | 21  |
    When executing query:
      """
      USE sample_test
      MATCH ()<-[e:KNOWS SAMPLE RIGHT RANDOM 3]-()
      RETURN count(*) AS cnt
      """
    # 3*5+2+1
    Then the result should be, in order:
      | cnt |
      | 18  |
    When executing query:
      """
      USE sample_test
      MATCH ()<-[e:KNOWS SAMPLE RIGHT RANDOM 33.33%]-()
      RETURN count(*) AS cnt
      """
    # 4+3+3+2+1+1+1
    Then the result should be, in order:
      | cnt |
      | 15  |
    When executing query:
      """
      USE sample_test
      MATCH ()<-[e:KNOWS SAMPLE RIGHT RANDOM 3]->()
      RETURN count(*) AS cnt
      """
    # 26+18
    Then the result should be, in order:
      | cnt |
      | 44  |
    When executing query:
      """
      USE sample_test
      MATCH ()<-[e:KNOWS SAMPLE RIGHT RANDOM 3]->()
      RETURN count(*) AS cnt
      """
    # 26+18
    Then the result should be, in order:
      | cnt |
      | 44  |
    When executing query:
      """
      USE sample_test
      MATCH ({id:10})-[e:KNOWS SAMPLE RIGHT RANDOM 3]->()
      RETURN count(*) AS cnt
      """
    Then the result should be, in order:
      | cnt |
      | 2   |
    When executing query:
      """
      USE sample_test
      MATCH ({id:7})-[e:KNOWS SAMPLE RIGHT RANDOM 3]->()
      RETURN count(*) AS cnt
      """
    Then the result should be, in order:
      | cnt |
      | 3   |
    When executing query:
      """
      USE sample_test
      MATCH ({id:3})-[e:KNOWS SAMPLE RIGHT RANDOM 3]->(n)
      RETURN n.id AS dstId
      """
    Then the result should be, in any order:
      | dstId |
      | 3     |
      | 1     |
      | 2     |
    # multiple edge types
    # first_fetch sampling by default
    When executing query:
      """
      USE sample_test
      MATCH (src:Person)-[:WORK_AT SAMPLE RIGHT 100]->(dst)
      RETURN src.id AS srcId, size(collect(dst.id)) AS dstCnt
      ORDER BY srcId
      """
    Then the result should be, in order:
      | srcId | dstCnt |
      | 1     | 2      |
      | 2     | 4      |
      | 3     | 3      |
      | 4     | 1      |
      | 5     | 2      |
      | 6     | 3      |
      | 7     | 2      |
      | 8     | 1      |
      | 9     | 3      |
      | 10    | 7      |
    When executing query:
      """
      USE sample_test
      MATCH (src:Person)-[:STUDY_AT SAMPLE RIGHT 100]->(dst)
      RETURN src.id AS srcId, size(collect(dst.id)) AS dstCnt
      ORDER BY srcId
      """
    Then the result should be, in order:
      | srcId | dstCnt |
      | 1     | 10     |
      | 2     | 9      |
      | 3     | 8      |
      | 4     | 7      |
      | 5     | 6      |
      | 6     | 5      |
      | 7     | 4      |
      | 8     | 3      |
      | 9     | 2      |
      | 10    | 1      |
    When executing query:
      """
      USE sample_test
      MATCH (src:Person)-[:WORK_AT|STUDY_AT SAMPLE RIGHT 100]->(dst)
      RETURN src.id AS srcId, size(collect(dst.id)) AS dstCnt
      ORDER BY srcId
      """
    Then the result should be, in order:
      | srcId | dstCnt |
      | 1     | 12     |
      | 2     | 13     |
      | 3     | 11     |
      | 4     | 8      |
      | 5     | 8      |
      | 6     | 8      |
      | 7     | 6      |
      | 8     | 4      |
      | 9     | 5      |
      | 10    | 8      |
    When executing query:
      """
      USE sample_test
      MATCH (src:Person)-[:WORK_AT|STUDY_AT SAMPLE RIGHT 1]->(dst)
      RETURN src.id AS srcId, size(collect(dst.id)) AS dstCnt
      ORDER BY srcId
      """
    Then the result should be, in order:
      | srcId | dstCnt |
      | 1     | 2      |
      | 2     | 2      |
      | 3     | 2      |
      | 4     | 2      |
      | 5     | 2      |
      | 6     | 2      |
      | 7     | 2      |
      | 8     | 2      |
      | 9     | 2      |
      | 10    | 2      |
    When executing query:
      """
      USE sample_test
      MATCH (src:Person)-[:WORK_AT|STUDY_AT SAMPLE RIGHT 3]->(dst)
      RETURN src.id AS srcId, size(collect(dst.id)) AS dstCnt
      ORDER BY srcId
      """
    Then the result should be, in order:
      | srcId | dstCnt |
      | 1     | 5      |
      | 2     | 6      |
      | 3     | 6      |
      | 4     | 4      |
      | 5     | 5      |
      | 6     | 6      |
      | 7     | 5      |
      | 8     | 4      |
      | 9     | 5      |
      | 10    | 4      |
    When executing query:
      """
      USE sample_test
      MATCH (src:Person)-[:WORK_AT|STUDY_AT SAMPLE RIGHT 33.3%]->(dst)
      RETURN src.id AS srcId, size(collect(dst.id)) AS dstCnt
      ORDER BY srcId
      """
    Then the result should be, in order:
      | srcId | dstCnt |
      | 1     | 5      |
      | 2     | 5      |
      | 3     | 4      |
      | 4     | 4      |
      | 5     | 3      |
      | 6     | 3      |
      | 7     | 3      |
      | 8     | 2      |
      | 9     | 2      |
      | 10    | 4      |
    When executing query:
      """
      USE sample_test
      MATCH (dst)<-[:WORK_AT|STUDY_AT SAMPLE RIGHT FIRST_FETCH 40]-(src)
      RETURN dst.id AS dstId, size(collect(src.id)) AS srcCnt
      ORDER BY dstId
      """
    Then the result should be, in order:
      | dstId | srcCnt |
      | 1     | 15     |
      | 2     | 13     |
      | 3     | 11     |
      | 4     | 9      |
      | 5     | 8      |
      | 6     | 8      |
      | 7     | 7      |
      | 8     | 4      |
      | 9     | 4      |
      | 10    | 4      |
    When executing query:
      """
      USE sample_test
      MATCH (dst)<-[:WORK_AT|STUDY_AT SAMPLE RIGHT FIRST_FETCH 4]-(src)
      RETURN dst.id AS dstId, size(collect(src.id)) AS srcCnt
      ORDER BY dstId
      """
    Then the result should be, in order:
      | dstId | srcCnt |
      | 1     | 8      |
      | 2     | 8      |
      | 3     | 7      |
      | 4     | 6      |
      | 5     | 6      |
      | 6     | 7      |
      | 7     | 7      |
      | 8     | 4      |
      | 9     | 4      |
      | 10    | 4      |
    When executing query:
      """
      USE sample_test
      MATCH (dst)<-[:WORK_AT|STUDY_AT SAMPLE RIGHT FIRST_FETCH 50%]-(src)
      RETURN dst.id AS dstId, size(collect(src.id)) AS srcCnt
      ORDER BY dstId
      """
    Then the result should be, in order:
      | dstId | srcCnt |
      | 1     | 8      |
      | 2     | 7      |
      | 3     | 6      |
      | 4     | 5      |
      | 5     | 4      |
      | 6     | 5      |
      | 7     | 4      |
      | 8     | 3      |
      | 9     | 2      |
      | 10    | 3      |
    # sampling by edge type operator(no node variable)
    When executing query:
      """
      USE sample_test
      MATCH ()-[e:WORK_AT|STUDY_AT SAMPLE RIGHT 3]->()
      RETURN count(*) AS cnt
      """
    # (2+3)+(3+3)+(3+3)+(1+3)+(2+3)+(3+3)+(2+3)+(1+3)+(3+2)+(3+1)=50
    Then the result should be, in order:
      | cnt |
      | 50  |
    When executing query:
      """
      USE sample_test
      MATCH ()-[e:WORK_AT|STUDY_AT SAMPLE RIGHT 50%]->()
      RETURN count(*) AS cnt
      """
    # (1+5)+(2+5)+(2+4)+(1+4)+(1+3)+(2+3)+(1+2)+(1+2)+(2+1)+(4+1)=47
    Then the result should be, in order:
      | cnt |
      | 47  |
    When executing query:
      """
      USE sample_test
      MATCH ()<-[e:WORK_AT|STUDY_AT SAMPLE RIGHT 3]-()
      RETURN count(*) AS cnt
      """
    # (3+3)+(3+3)+(3+3)+(2+3)+(2+3)+(3+3)+(3+3)+(1+3)+(2+2)+(3+1)=52
    Then the result should be, in order:
      | cnt |
      | 52  |
    When executing query:
      """
      USE sample_test
      MATCH ()<-[e:WORK_AT|STUDY_AT SAMPLE RIGHT 33.33%]-()
      RETURN count(*) AS cnt
      """
    # (2+4)+(2+3)+(1+3)+(1+3)+(1+2)+(1+2)+(1+2)+(1+1)+(1+1)+(1+1)=34
    Then the result should be, in order:
      | cnt |
      | 34  |
    When executing query:
      """
      USE sample_test
      MATCH ()<-[e:WORK_AT|STUDY_AT SAMPLE RIGHT 3]->()
      RETURN count(*) AS cnt
      """
    # 52+50
    Then the result should be, in order:
      | cnt |
      | 102 |
    When executing query:
      """
      USE sample_test
      MATCH ()<-[e:WORK_AT|STUDY_AT SAMPLE RIGHT 3]->()
      RETURN count(*) AS cnt
      """
    Then the result should be, in order:
      | cnt |
      | 102 |
    When executing query:
      """
      USE sample_test
      MATCH ({id:10})-[e:WORK_AT|STUDY_AT SAMPLE RIGHT 3]->()
      RETURN count(*) AS cnt
      """
    Then the result should be, in order:
      | cnt |
      | 4   |
    When executing query:
      """
      USE sample_test
      MATCH ({id:7})-[e:WORK_AT|STUDY_AT SAMPLE RIGHT 3]->()
      RETURN count(*) AS cnt
      """
    Then the result should be, in order:
      | cnt |
      | 5   |
    When executing query:
      """
      USE sample_test
      MATCH ({id:9})-[e:WORK_AT|STUDY_AT SAMPLE RIGHT 3]->(n)
      RETURN n.id AS dstId
      """
    Then the result should be, in any order:
      | dstId |
      | 9     |
      | 2     |
      | 1     |
      | 5     |
      | 10    |
    # multiple edge types
    # sampling random
    When executing query:
      """
      USE sample_test
      MATCH (src:Person)-[:WORK_AT SAMPLE RIGHT RANDOM 100]->(dst)
      RETURN src.id AS srcId, size(collect(dst.id)) AS dstCnt
      ORDER BY srcId
      """
    Then the result should be, in order:
      | srcId | dstCnt |
      | 1     | 2      |
      | 2     | 4      |
      | 3     | 3      |
      | 4     | 1      |
      | 5     | 2      |
      | 6     | 3      |
      | 7     | 2      |
      | 8     | 1      |
      | 9     | 3      |
      | 10    | 7      |
    When executing query:
      """
      USE sample_test
      MATCH (src:Person)-[:STUDY_AT SAMPLE RIGHT RANDOM 100]->(dst)
      RETURN src.id AS srcId, size(collect(dst.id)) AS dstCnt
      ORDER BY srcId
      """
    Then the result should be, in order:
      | srcId | dstCnt |
      | 1     | 10     |
      | 2     | 9      |
      | 3     | 8      |
      | 4     | 7      |
      | 5     | 6      |
      | 6     | 5      |
      | 7     | 4      |
      | 8     | 3      |
      | 9     | 2      |
      | 10    | 1      |
    When executing query:
      """
      USE sample_test
      MATCH (src:Person)-[:WORK_AT|STUDY_AT SAMPLE RIGHT RANDOM 100]->(dst)
      RETURN src.id AS srcId, size(collect(dst.id)) AS dstCnt
      ORDER BY srcId
      """
    Then the result should be, in order:
      | srcId | dstCnt |
      | 1     | 12     |
      | 2     | 13     |
      | 3     | 11     |
      | 4     | 8      |
      | 5     | 8      |
      | 6     | 8      |
      | 7     | 6      |
      | 8     | 4      |
      | 9     | 5      |
      | 10    | 8      |
    When executing query:
      """
      USE sample_test
      MATCH (src:Person)-[:WORK_AT|STUDY_AT SAMPLE RIGHT RANDOM 1]->(dst)
      RETURN src.id AS srcId, size(collect(dst.id)) AS dstCnt
      ORDER BY srcId
      """
    Then the result should be, in order:
      | srcId | dstCnt |
      | 1     | 2      |
      | 2     | 2      |
      | 3     | 2      |
      | 4     | 2      |
      | 5     | 2      |
      | 6     | 2      |
      | 7     | 2      |
      | 8     | 2      |
      | 9     | 2      |
      | 10    | 2      |
    When executing query:
      """
      USE sample_test
      MATCH (src:Person)-[:WORK_AT|STUDY_AT SAMPLE RIGHT RANDOM 3]->(dst)
      RETURN src.id AS srcId, size(collect(dst.id)) AS dstCnt
      ORDER BY srcId
      """
    Then the result should be, in order:
      | srcId | dstCnt |
      | 1     | 5      |
      | 2     | 6      |
      | 3     | 6      |
      | 4     | 4      |
      | 5     | 5      |
      | 6     | 6      |
      | 7     | 5      |
      | 8     | 4      |
      | 9     | 5      |
      | 10    | 4      |
    When executing query:
      """
      USE sample_test
      MATCH (src:Person)-[:WORK_AT|STUDY_AT SAMPLE RIGHT RANDOM 33.3%]->(dst)
      RETURN src.id AS srcId, size(collect(dst.id)) AS dstCnt
      ORDER BY srcId
      """
    Then the result should be, in order:
      | srcId | dstCnt |
      | 1     | 5      |
      | 2     | 5      |
      | 3     | 4      |
      | 4     | 4      |
      | 5     | 3      |
      | 6     | 3      |
      | 7     | 3      |
      | 8     | 2      |
      | 9     | 2      |
      | 10    | 4      |
    When executing query:
      """
      USE sample_test
      MATCH (dst)<-[:WORK_AT|STUDY_AT SAMPLE RIGHT RANDOM 40]-(src)
      RETURN dst.id AS dstId, size(collect(src.id)) AS srcCnt
      ORDER BY dstId
      """
    Then the result should be, in order:
      | dstId | srcCnt |
      | 1     | 15     |
      | 2     | 13     |
      | 3     | 11     |
      | 4     | 9      |
      | 5     | 8      |
      | 6     | 8      |
      | 7     | 7      |
      | 8     | 4      |
      | 9     | 4      |
      | 10    | 4      |
    When executing query:
      """
      USE sample_test
      MATCH (dst)<-[:WORK_AT|STUDY_AT SAMPLE RIGHT RANDOM  4]-(src)
      RETURN dst.id AS dstId, size(collect(src.id)) AS srcCnt
      ORDER BY dstId
      """
    Then the result should be, in order:
      | dstId | srcCnt |
      | 1     | 8      |
      | 2     | 8      |
      | 3     | 7      |
      | 4     | 6      |
      | 5     | 6      |
      | 6     | 7      |
      | 7     | 7      |
      | 8     | 4      |
      | 9     | 4      |
      | 10    | 4      |
    When executing query:
      """
      USE sample_test
      MATCH (dst)<-[:WORK_AT|STUDY_AT SAMPLE RIGHT RANDOM  50%]-(src)
      RETURN dst.id AS dstId, size(collect(src.id)) AS srcCnt
      ORDER BY dstId
      """
    Then the result should be, in order:
      | dstId | srcCnt |
      | 1     | 8      |
      | 2     | 7      |
      | 3     | 6      |
      | 4     | 5      |
      | 5     | 4      |
      | 6     | 5      |
      | 7     | 4      |
      | 8     | 3      |
      | 9     | 2      |
      | 10    | 3      |
    # sampling by edge type operator(no node variable)
    When executing query:
      """
      USE sample_test
      MATCH ()-[e:WORK_AT|STUDY_AT SAMPLE RIGHT RANDOM 3]->()
      RETURN count(*) AS cnt
      """
    # (2+3)+(3+3)+(3+3)+(1+3)+(2+3)+(3+3)+(2+3)+(1+3)+(3+2)+(3+1)=50
    Then the result should be, in order:
      | cnt |
      | 50  |
    When executing query:
      """
      USE sample_test
      MATCH ()-[e:WORK_AT|STUDY_AT SAMPLE RIGHT RANDOM 50%]->()
      RETURN count(*) AS cnt
      """
    # (1+5)+(2+5)+(2+4)+(1+4)+(1+3)+(2+3)+(1+2)+(1+2)+(2+1)+(4+1)=47
    Then the result should be, in order:
      | cnt |
      | 47  |
    When executing query:
      """
      USE sample_test
      MATCH ()<-[e:WORK_AT|STUDY_AT SAMPLE RIGHT RANDOM 3]-()
      RETURN count(*) AS cnt
      """
    # (3+3)+(3+3)+(3+3)+(2+3)+(2+3)+(3+3)+(3+3)+(1+3)+(2+2)+(3+1)=52
    Then the result should be, in order:
      | cnt |
      | 52  |
    When executing query:
      """
      USE sample_test
      MATCH ()<-[e:WORK_AT|STUDY_AT SAMPLE RIGHT RANDOM 33.33%]-()
      RETURN count(*) AS cnt
      """
    # (2+4)+(2+3)+(1+3)+(1+3)+(1+2)+(1+2)+(1+2)+(1+1)+(1+1)+(1+1)=34
    Then the result should be, in order:
      | cnt |
      | 34  |
    When executing query:
      """
      USE sample_test
      MATCH ()<-[e:WORK_AT|STUDY_AT SAMPLE RIGHT RANDOM 3]->()
      RETURN count(*) AS cnt
      """
    # 52+50
    Then the result should be, in order:
      | cnt |
      | 102 |
    When executing query:
      """
      USE sample_test
      MATCH ()<-[e:WORK_AT|STUDY_AT SAMPLE RIGHT RANDOM 3]->()
      RETURN count(*) AS cnt
      """
    Then the result should be, in order:
      | cnt |
      | 102 |
    When executing query:
      """
      USE sample_test
      MATCH ({id:10})-[e:WORK_AT|STUDY_AT SAMPLE RIGHT RANDOM 3]->()
      RETURN count(*) AS cnt
      """
    Then the result should be, in order:
      | cnt |
      | 4   |
    When executing query:
      """
      USE sample_test
      MATCH ({id:7})-[e:WORK_AT|STUDY_AT SAMPLE RIGHT RANDOM 3]->()
      RETURN count(*) AS cnt
      """
    Then the result should be, in order:
      | cnt |
      | 5   |
    When executing query:
      """
      USE sample_test
      MATCH ({id:9})-[e:WORK_AT|STUDY_AT SAMPLE RIGHT RANDOM 3]->(n)
      RETURN n.id AS dstId
      """
    Then the result should be, in any order:
      | dstId |
      | 9     |
      | 2     |
      | 1     |
      | 5     |
      | 10    |
    When executing query:
      """
      USE sample_test
      MATCH (v)-[e:KNOWS SAMPLE RIGHT 1]->(n) order by euclidean(e.vec, vector(1,2,3)) approx limit 55 options {type:IVF}
      RETURN count(*) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 10  |
    When executing query:
      """
      USE sample_test CREATE VECTOR INDEX IF NOT EXISTS sample_edge_ivf_l2 ON EDGE KNOWS::vec OPTIONS {metric: L2, dim: 3,type:IVF, nlist:8}
      """
    Then the execution should be successful
    When executing query:
      """
      USE sample_test CREATE VECTOR INDEX IF NOT EXISTS sample_node_ivf_l2 ON NODE Person::vec OPTIONS {metric: L2, dim: 3,type:IVF, nlist:8}
      """
    Then the execution should be successful
    When executing query:
      """
      USE sample_test
      MATCH (v)-[e:KNOWS SAMPLE RIGHT 1]->(n) order by euclidean(e.vec, vector(1,2,3)) approx limit 55 options {type:IVF}
      RETURN count(*) AS cnt
      """
    Then an Error should be raised: "[42016]: Invalid syntax for ANN search: mixed sampling and ANN search are not allowed"
    When executing query:
      """
      USE sample_test
      MATCH (v)-[e:KNOWS SAMPLE RIGHT 1]->(n) order by euclidean(e.vec, vector(1,2,3)) approx limit 9 options {type:IVF}
      RETURN count(*) AS cnt
      """
    Then an Error should be raised: "[42016]: Invalid syntax for ANN search: mixed sampling and ANN search are not allowed"
    When executing query:
      """
      USE sample_test
      MATCH (v)-[e:KNOWS SAMPLE RIGHT 2]->(n) order by euclidean(e.vec, vector(1,2,3)) approx limit 55 options {type:IVF}
      RETURN count(*) AS cnt
      """
    Then an Error should be raised: "[42016]: Invalid syntax for ANN search: mixed sampling and ANN search are not allowed"
    # multi-hop pattern
    When executing query:
      """
      USE sample_test
      MATCH p=(src:Person where src.id=10)-[e:KNOWS]-{0,2}(dst)
      RETURN
         src.id AS srcId,
         dst.id AS dstId,
         length(p) AS hopCnt,
         transform(nodes(p), x -> x.id) as nodes,
         range(0, length(p)) as hops
      ORDER BY srcId, dstId, hopCnt
      NEXT use sample_test
      RETURN reduce(hops,
      "",
      (state, i) -> state || (CAST(nodes[i] AS STRING) || case when i+1=size(hops) then "" else "-" end)) AS multi_hop_paths
            order by multi_hop_paths
      """
    Then the result should be, in any order:
      | multi_hop_paths |
      | "10"            |
      | "10-1"          |
      | "10-1-1"        |
      | "10-1-1"        |
      | "10-1-10"       |
      | "10-1-2"        |
      | "10-1-3"        |
      | "10-1-4"        |
      | "10-1-5"        |
      | "10-1-6"        |
      | "10-1-7"        |
      | "10-1-8"        |
      | "10-1-9"        |
      | "10-2"          |
      | "10-2-1"        |
      | "10-2-2"        |
      | "10-2-10"       |
      | "10-2-2"        |
      | "10-2-3"        |
      | "10-2-4"        |
      | "10-2-5"        |
      | "10-2-6"        |
      | "10-2-7"        |
      | "10-2-8"        |
      | "10-2-9"        |
    When executing query:
      """
      USE sample_test
      MATCH p=(src:Person where src.id=10)<-[e:KNOWS sample RIGHT 1]->{0,2}(dst)
      RETURN
         src.id AS srcId,
         dst.id AS dstId,
         length(p) AS hopCnt,
         transform(nodes(p), x -> x.id) as nodes,
         range(0, length(p)) as hops
      ORDER BY srcId, dstId, hopCnt
      NEXT use sample_test
      RETURN reduce(hops,
      "",
      (state, i) -> state || (CAST(nodes[i] AS STRING) || case when i+1=size(hops) then "" else "-" end)) AS multi_hop_paths
            order by multi_hop_paths
      """
    Then the result should be, in any order:
      | multi_hop_paths |
      | "10"            |
      | "10-1"          |
      | "10-1-1"        |
      | "10-1-6"        |
    When executing query:
      """
      USE sample_test
      MATCH p=(src:Person where src.id=10)<-[e:KNOWS sample RIGHT 2]->{0,2}(dst)
      RETURN
         src.id AS srcId,
         dst.id AS dstId,
         length(p) AS hopCnt,
         transform(nodes(p), x -> x.id) as nodes,
         range(0, length(p)) as hops
      ORDER BY srcId, dstId, hopCnt
      NEXT use sample_test
      RETURN reduce(hops,
      "",
      (state, i) -> state || (CAST(nodes[i] AS STRING) || case when i+1=size(hops) then "" else "-" end)) AS multi_hop_paths
            order by multi_hop_paths
      """
    # "10->1->1" only has one path
    Then the result should be, in any order:
      | multi_hop_paths |
      | "10"            |
      | "10-1"          |
      | "10-1-1"        |
      | "10-1-1"        |
      | "10-1-6"        |
      | "10-2"          |
      | "10-2-1"        |
      | "10-2-2"        |
      | "10-2-10"       |
      | "10-2-6"        |
    When executing query:
      """
      USE sample_test
      MATCH p=(src:Person where src.id=10)<-[e:KNOWS sample RIGHT 3]->{0,2}(dst)
      RETURN
         src.id AS srcId,
         dst.id AS dstId,
         length(p) AS hopCnt,
         transform(nodes(p), x -> x.id) as nodes,
         range(0, length(p)) as hops
      ORDER BY srcId, dstId, hopCnt
      NEXT use sample_test
      RETURN reduce(hops,
      "",
      (state, i) -> state || (CAST(nodes[i] AS STRING) || case when i+1=size(hops) then "" else "-" end)) AS multi_hop_paths
      order by multi_hop_paths
      """
    # "10->1->1" only has one path
    Then the result should be, in any order:
      | multi_hop_paths |
      | "10"            |
      | "10-1"          |
      | "10-1-1"        |
      | "10-1-1"        |
      | "10-1-10"       |
      | "10-1-6"        |
      | "10-2"          |
      | "10-2-1"        |
      | "10-2-2"        |
      | "10-2-10"       |
      | "10-2-3"        |
      | "10-2-6"        |
    # UNQ_NGB sampling
    When executing query:
      # generate some duplicate edges with different rank(different multiedge key value)
      """
      TABLE t {src, dst} =
      (1,1),
      (2,1), (2,2),
      (3,1), (3,2), (3,3),
      (4,1), (4,2), (4,3), (4,4),
      (5,1), (5,2), (5,3), (5,4), (5,5),
      (6,1), (6,2), (6,3), (6,4), (6,5), (6,6),
      (7,1), (7,2), (7,3), (7,4), (7,5), (7,6), (7, 7),
      (8,1), (8,2), (8,3), (8,4),
      (9,1), (9,2), (9,3),
      (10,1), (10,2)
      USE sample_test
      FOR r IN t
      MATCH (a@Person) WHERE a.id = r.src
      MATCH (b@Person) WHERE b.id = r.dst
      INSERT (a)-[:KNOWS{creationDate: local_datetime('2025-08-23T00:00:00.000')+duration({days:r.src,hours:r.dst}), vec: case when r.src>5 then vector(1,2,3) else vector(4,5,6) end}]->(b)
      """
    Then the execution should be successful
    When executing query:
      """
      USE sample_test
      MATCH (src:Person)-[:KNOWS SAMPLE 1000]->(dst)
      RETURN src.id AS srcId, size(collect(dst.id)) AS dstCnt
      ORDER BY srcId
      """
    # ensure the duplicate edges were inserted and non-UNQ_NBR sampling return the double count which causes by the duplicate edges
    Then the result should be, in order:
      | srcId | dstCnt |
      | 1     | 2      |
      | 2     | 4      |
      | 3     | 6      |
      | 4     | 8      |
      | 5     | 10     |
      | 6     | 12     |
      | 7     | 14     |
      | 8     | 8      |
      | 9     | 6      |
      | 10    | 4      |
    When executing query:
      """
      USE sample_test
      MATCH (src:Person)-[:KNOWS SAMPLE RIGHT UNQ_NBR 1000]->(dst)
      RETURN src.id AS srcId, size(collect(dst.id)) AS dstCnt
      ORDER BY srcId
      """
    Then the result should be, in order:
      | srcId | dstCnt |
      | 1     | 1      |
      | 2     | 2      |
      | 3     | 3      |
      | 4     | 4      |
      | 5     | 5      |
      | 6     | 6      |
      | 7     | 7      |
      | 8     | 4      |
      | 9     | 3      |
      | 10    | 2      |
    When executing query:
      """
      USE sample_test
      MATCH (src:Person)-[:KNOWS SAMPLE RIGHT UNQ_NBR 1]->(dst)
      RETURN src.id AS srcId, size(collect(dst.id)) AS dstCnt
      ORDER BY srcId
      """
    Then the result should be, in order:
      | srcId | dstCnt |
      | 1     | 1      |
      | 2     | 1      |
      | 3     | 1      |
      | 4     | 1      |
      | 5     | 1      |
      | 6     | 1      |
      | 7     | 1      |
      | 8     | 1      |
      | 9     | 1      |
      | 10    | 1      |
    When executing query:
      """
      USE sample_test
      MATCH (src:Person)-[:KNOWS SAMPLE RIGHT UNQ_NBR 4]->(dst)
      RETURN src.id AS srcId, size(collect(dst.id)) AS dstCnt
      ORDER BY srcId
      """
    Then the result should be, in order:
      | srcId | dstCnt |
      | 1     | 1      |
      | 2     | 2      |
      | 3     | 3      |
      | 4     | 4      |
      | 5     | 4      |
      | 6     | 4      |
      | 7     | 4      |
      | 8     | 4      |
      | 9     | 3      |
      | 10    | 2      |
    When executing query:
      """
      USE sample_test
      MATCH (src:Person)-[:KNOWS SAMPLE RIGHT UNQ_NBR 80%]->(dst)
      RETURN src.id AS srcId, size(collect(dst.id)) AS dstCnt
      ORDER BY srcId
      """
    Then the result should be, in order:
      | srcId | dstCnt |
      | 1     | 1      |
      | 2     | 2      |
      | 3     | 3      |
      | 4     | 4      |
      | 5     | 4      |
      | 6     | 5      |
      | 7     | 6      |
      | 8     | 4      |
      | 9     | 3      |
      | 10    | 2      |
    When executing query:
      """
      USE sample_test
      MATCH (dst:Person)<-[:KNOWS SAMPLE RIGHT UNQ_NBR 499999]-(src)
      RETURN dst.id AS dstId, size(collect(src.id)) AS srcCnt
      ORDER BY dstId
      """
    Then the result should be, in order:
      | dstId | srcCnt |
      | 1     | 10     |
      | 2     | 9      |
      | 3     | 7      |
      | 4     | 5      |
      | 5     | 3      |
      | 6     | 2      |
      | 7     | 1      |
    When executing query:
      """
      USE sample_test
      MATCH (dst:Person)<-[:KNOWS SAMPLE RIGHT UNQ_NBR 4]-(src)
      RETURN dst.id AS dstId, size(collect(src.id)) AS srcCnt
      ORDER BY dstId
      """
    Then the result should be, in order:
      | srcId | dstCnt |
      | 1     | 4      |
      | 2     | 4      |
      | 3     | 4      |
      | 4     | 4      |
      | 5     | 3      |
      | 6     | 2      |
      | 7     | 1      |
    When executing query:
      """
      USE sample_test
      MATCH (dst:Person)<-[:KNOWS SAMPLE RIGHT UNQ_NBR 60%]-(src)
      RETURN dst.id AS dstId, size(collect(src.id)) AS srcCnt
      ORDER BY dstId
      """
    Then the result should be, in order:
      | dstId | srcCnt |
      | 1     | 6      |
      | 2     | 6      |
      | 3     | 5      |
      | 4     | 3      |
      | 5     | 2      |
      | 6     | 2      |
      | 7     | 1      |
    # sampling by edge type operator(no node variable)
    When executing query:
      """
      USE sample_test
      MATCH ()-[e:KNOWS SAMPLE RIGHT UNQ_NBR 3]->()
      RETURN count(*) AS cnt
      """
    # 1+2+3*7+2
    Then the result should be, in order:
      | cnt |
      | 26  |
    When executing query:
      """
      USE sample_test
      MATCH ()-[e:KNOWS SAMPLE RIGHT UNQ_NBR 50%]->()
      RETURN count(*) AS cnt
      """
    # 1+1+2+2+3+3+4+2+2+1
    Then the result should be, in order:
      | cnt |
      | 21  |
    When executing query:
      """
      USE sample_test
      MATCH ()<-[e:KNOWS SAMPLE RIGHT UNQ_NBR 3]-()
      RETURN count(*) AS cnt
      """
    # 3*5+2+1
    Then the result should be, in order:
      | cnt |
      | 18  |
    When executing query:
      """
      USE sample_test
      MATCH ()<-[e:KNOWS SAMPLE RIGHT UNQ_NBR 33.33%]-()
      RETURN count(*) AS cnt
      """
    # 4+3+3+2+1+1+1
    Then the result should be, in order:
      | cnt |
      | 15  |
    When executing query:
      """
      USE sample_test
      MATCH ()<-[e:KNOWS SAMPLE RIGHT UNQ_NBR 3]->()
      RETURN count(*) AS cnt
      """
    # 26+18
    Then the result should be, in order:
      | cnt |
      | 44  |
    When executing query:
      """
      USE sample_test
      MATCH ()<-[e:KNOWS SAMPLE RIGHT UNQ_NBR 3]->()
      RETURN count(*) AS cnt
      """
    # 26+18
    Then the result should be, in order:
      | cnt |
      | 44  |
    When executing query:
      """
      USE sample_test
      MATCH ({id:10})-[e:KNOWS SAMPLE RIGHT UNQ_NBR 3]->()
      RETURN count(*) AS cnt
      """
    Then the result should be, in order:
      | cnt |
      | 2   |
    When executing query:
      """
      USE sample_test
      MATCH ({id:7})-[e:KNOWS SAMPLE RIGHT UNQ_NBR 3]->()
      RETURN count(*) AS cnt
      """
    Then the result should be, in order:
      | cnt |
      | 3   |
    When executing query:
      """
      USE sample_test
      MATCH ({id:3})-[e:KNOWS SAMPLE RIGHT UNQ_NBR 3]->(n)
      RETURN n.id AS dstId
      """
    Then the result should be, in any order:
      | dstId |
      | 3     |
      | 1     |
      | 2     |
    # sampling unique neighbors
    When executing query:
      """
      USE sample_test
      MATCH (src:Person)-[:WORK_AT SAMPLE RIGHT UNQ_NBR 100]->(dst)
      RETURN src.id AS srcId, size(collect(dst.id)) AS dstCnt
      ORDER BY srcId
      """
    Then the result should be, in order:
      | srcId | dstCnt |
      | 1     | 2      |
      | 2     | 4      |
      | 3     | 3      |
      | 4     | 1      |
      | 5     | 2      |
      | 6     | 3      |
      | 7     | 2      |
      | 8     | 1      |
      | 9     | 3      |
      | 10    | 7      |
    When executing query:
      """
      USE sample_test
      MATCH (src:Person)-[:STUDY_AT SAMPLE RIGHT UNQ_NBR 100]->(dst)
      RETURN src.id AS srcId, size(collect(dst.id)) AS dstCnt
      ORDER BY srcId
      """
    Then the result should be, in order:
      | srcId | dstCnt |
      | 1     | 10     |
      | 2     | 9      |
      | 3     | 8      |
      | 4     | 7      |
      | 5     | 6      |
      | 6     | 5      |
      | 7     | 4      |
      | 8     | 3      |
      | 9     | 2      |
      | 10    | 1      |
    When executing query:
      """
      USE sample_test
      MATCH (src:Person)-[:WORK_AT|STUDY_AT SAMPLE RIGHT UNQ_NBR 100]->(dst)
      RETURN src.id AS srcId, size(collect(dst.id)) AS dstCnt
      ORDER BY srcId
      """
    Then the result should be, in order:
      | srcId | dstCnt |
      | 1     | 12     |
      | 2     | 13     |
      | 3     | 11     |
      | 4     | 8      |
      | 5     | 8      |
      | 6     | 8      |
      | 7     | 6      |
      | 8     | 4      |
      | 9     | 5      |
      | 10    | 8      |
    When executing query:
      """
      USE sample_test
      MATCH (src:Person)-[:WORK_AT|STUDY_AT SAMPLE RIGHT UNQ_NBR 1]->(dst)
      RETURN src.id AS srcId, size(collect(dst.id)) AS dstCnt
      ORDER BY srcId
      """
    Then the result should be, in order:
      | srcId | dstCnt |
      | 1     | 2      |
      | 2     | 2      |
      | 3     | 2      |
      | 4     | 2      |
      | 5     | 2      |
      | 6     | 2      |
      | 7     | 2      |
      | 8     | 2      |
      | 9     | 2      |
      | 10    | 2      |
    When executing query:
      """
      USE sample_test
      MATCH (src:Person)-[:WORK_AT|STUDY_AT SAMPLE RIGHT UNQ_NBR 3]->(dst)
      RETURN src.id AS srcId, size(collect(dst.id)) AS dstCnt
      ORDER BY srcId
      """
    Then the result should be, in order:
      | srcId | dstCnt |
      | 1     | 5      |
      | 2     | 6      |
      | 3     | 6      |
      | 4     | 4      |
      | 5     | 5      |
      | 6     | 6      |
      | 7     | 5      |
      | 8     | 4      |
      | 9     | 5      |
      | 10    | 4      |
    When executing query:
      """
      USE sample_test
      MATCH (src:Person)-[:WORK_AT|STUDY_AT SAMPLE RIGHT UNQ_NBR 33.3%]->(dst)
      RETURN src.id AS srcId, size(collect(dst.id)) AS dstCnt
      ORDER BY srcId
      """
    Then the result should be, in order:
      | srcId | dstCnt |
      | 1     | 5      |
      | 2     | 5      |
      | 3     | 4      |
      | 4     | 4      |
      | 5     | 3      |
      | 6     | 3      |
      | 7     | 3      |
      | 8     | 2      |
      | 9     | 2      |
      | 10    | 4      |
    When executing query:
      """
      USE sample_test
      MATCH (dst)<-[:WORK_AT|STUDY_AT SAMPLE RIGHT UNQ_NBR 40]-(src)
      RETURN dst.id AS dstId, size(collect(src.id)) AS srcCnt
      ORDER BY dstId
      """
    Then the result should be, in order:
      | dstId | srcCnt |
      | 1     | 15     |
      | 2     | 13     |
      | 3     | 11     |
      | 4     | 9      |
      | 5     | 8      |
      | 6     | 8      |
      | 7     | 7      |
      | 8     | 4      |
      | 9     | 4      |
      | 10    | 4      |
    When executing query:
      """
      USE sample_test
      MATCH (dst)<-[:WORK_AT|STUDY_AT SAMPLE RIGHT UNQ_NBR  4]-(src)
      RETURN dst.id AS dstId, size(collect(src.id)) AS srcCnt
      ORDER BY dstId
      """
    Then the result should be, in order:
      | dstId | srcCnt |
      | 1     | 8      |
      | 2     | 8      |
      | 3     | 7      |
      | 4     | 6      |
      | 5     | 6      |
      | 6     | 7      |
      | 7     | 7      |
      | 8     | 4      |
      | 9     | 4      |
      | 10    | 4      |
    When executing query:
      """
      USE sample_test
      MATCH (dst)<-[:WORK_AT|STUDY_AT SAMPLE RIGHT UNQ_NBR  50%]-(src)
      RETURN dst.id AS dstId, size(collect(src.id)) AS srcCnt
      ORDER BY dstId
      """
    Then the result should be, in order:
      | dstId | srcCnt |
      | 1     | 8      |
      | 2     | 7      |
      | 3     | 6      |
      | 4     | 5      |
      | 5     | 4      |
      | 6     | 5      |
      | 7     | 4      |
      | 8     | 3      |
      | 9     | 2      |
      | 10    | 3      |
    # sampling by edge type operator(no node variable)
    When executing query:
      """
      USE sample_test
      MATCH ()-[e:WORK_AT|STUDY_AT SAMPLE RIGHT UNQ_NBR 3]->()
      RETURN count(*) AS cnt
      """
    # (2+3)+(3+3)+(3+3)+(1+3)+(2+3)+(3+3)+(2+3)+(1+3)+(3+2)+(3+1)=50
    Then the result should be, in order:
      | cnt |
      | 50  |
    When executing query:
      """
      USE sample_test
      MATCH ()-[e:WORK_AT|STUDY_AT SAMPLE RIGHT UNQ_NBR 50%]->()
      RETURN count(*) AS cnt
      """
    # (1+5)+(2+5)+(2+4)+(1+4)+(1+3)+(2+3)+(1+2)+(1+2)+(2+1)+(4+1)=47
    Then the result should be, in order:
      | cnt |
      | 47  |
    When executing query:
      """
      USE sample_test
      MATCH ()<-[e:WORK_AT|STUDY_AT SAMPLE RIGHT UNQ_NBR 3]-()
      RETURN count(*) AS cnt
      """
    # (3+3)+(3+3)+(3+3)+(2+3)+(2+3)+(3+3)+(3+3)+(1+3)+(2+2)+(3+1)=52
    Then the result should be, in order:
      | cnt |
      | 52  |
    When executing query:
      """
      USE sample_test
      MATCH ()<-[e:WORK_AT|STUDY_AT SAMPLE RIGHT UNQ_NBR 33.33%]-()
      RETURN count(*) AS cnt
      """
    # (2+4)+(2+3)+(1+3)+(1+3)+(1+2)+(1+2)+(1+2)+(1+1)+(1+1)+(1+1)=34
    Then the result should be, in order:
      | cnt |
      | 34  |
    When executing query:
      """
      USE sample_test
      MATCH ()<-[e:WORK_AT|STUDY_AT SAMPLE RIGHT UNQ_NBR 3]->()
      RETURN count(*) AS cnt
      """
    # 52+50
    Then the result should be, in order:
      | cnt |
      | 102 |
    When executing query:
      """
      USE sample_test
      MATCH ()<-[e:WORK_AT|STUDY_AT SAMPLE RIGHT UNQ_NBR 3]->()
      RETURN count(*) AS cnt
      """
    Then the result should be, in order:
      | cnt |
      | 102 |
    When executing query:
      """
      USE sample_test
      MATCH ({id:10})-[e:WORK_AT|STUDY_AT SAMPLE RIGHT UNQ_NBR 3]->()
      RETURN count(*) AS cnt
      """
    Then the result should be, in order:
      | cnt |
      | 4   |
    When executing query:
      """
      USE sample_test
      MATCH ({id:7})-[e:WORK_AT|STUDY_AT SAMPLE RIGHT UNQ_NBR 3]->()
      RETURN count(*) AS cnt
      """
    Then the result should be, in order:
      | cnt |
      | 5   |
    When executing query:
      """
      USE sample_test
      MATCH ({id:9})-[e:WORK_AT|STUDY_AT SAMPLE RIGHT UNQ_NBR 3]->(n)
      RETURN n.id AS dstId
      """
    Then the result should be, in any order:
      | dstId |
      | 9     |
      | 2     |
      | 1     |
      | 5     |
      | 10    |
    When executing query:
      """
      DROP GRAPH IF EXISTS sample_test
      """
    Then the execution should be successful

  # FIXME(czp-sample): the grouped sampling for dst nodes depends post-sampling
  # https://github.com/vesoft-inc/nebula-ng/issues/8299
  @skip
  Scenario: Sampling right
    When executing query:
      """
      USE sample_test
      MATCH ({id:9})-[e:WORK_AT|STUDY_AT SAMPLE RIGHT UNQ_NBR 3 Right]->(n)
      RETURN n.id AS dstId
      """
    Then the result should be, in any order:
      | dstId |
      | 9     |
      | 2     |
      | 1     |
      | 5     |
      | 10    |
    When executing query:
      """
      DROP GRAPH IF EXISTS sample_test
      """
    Then the execution should be successful

  # FIXME(czp-sample): Currently, the sampling of undirected edges may not guarantee sampling semantics due to randomness on the storage side, and post-sampling is required.
  # https://github.com/vesoft-inc/nebula-ng/issues/8299
  # multi-hop and mixed-graph cases
  @skip
  Scenario: Sampling on storage graph
    When executing query:
      """
      ALTER GRAPH TYPE ldbc_type {
        ADD EDGE TYPE IF NOT EXISTS KNOWS_EACHOTHER (Person)~[LABEL KNOWS{id INT DEFAULT 0}]~(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE sample_test
      FOR i IN range(11,13)
      INSERT (a@Person{id:i})
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {src, dst} =
      (1,8),
      (2,8),(2,9),
      (3,3),
      (4,3),(4,7),
      (9,11),(9,13),
      (10,11),(10,12),(10,13)
      USE sample_test
      FOR r IN t
      MATCH (a@Person) WHERE a.id = r.src
      MATCH (b@Person) WHERE b.id = r.dst
      INSERT (a)~[@KNOWS_EACHOTHER]~(b)
      """
    Then the execution should be successful
    When executing query:
      """
      USE sample_test
      MATCH p=(src:Person where src.id>9)-[e:KNOWS]-{0,2}(dst)
      RETURN
         src.id AS srcId,
         dst.id AS dstId,
         length(p) AS hopCnt,
         transform(nodes(p), x -> x.id) as nodes,
         transform(edges(p), x -> type(x)="KNOWS") as isDirect,
         range(0, length(p)) as hops
      ORDER BY srcId, dstId, hopCnt
      NEXT use sample_test
      RETURN reduce(hops,
      "",
      (state, i) -> state || (CAST(nodes[i] AS STRING) || case when i+1=size(hops) then "" else case when isDirect[i] then "->" else "~" end end)) AS multi_hop_mixed_paths
      """
    Then the result should be, in any order:
      | multi_hop_mixed_paths |
      | "11~10->1"            |
      | "11~9->1"             |
      | "11~10->2"            |
      | "11~9~2"              |
      | "11~9->2"             |
      | "11~9->3"             |
      | "11~9"                |
      | "11~10"               |
      | "11"                  |
      | "11~9~11"             |
      | "11~10~11"            |
      | "11~10~12"            |
      | "11~9~13"             |
      | "11~10~13"            |
      | "12~10->1"            |
      | "12~10->2"            |
      | "12~10"               |
      | "12~10~11"            |
      | "12"                  |
      | "12~10~12"            |
      | "12~10~13"            |
      | "13~9->1"             |
      | "13~10->1"            |
      | "13~9->2"             |
      | "13~9~2"              |
      | "13~10->2"            |
      | "13~9->3"             |
      | "13~9"                |
      | "13~10"               |
      | "13~10~11"            |
      | "13~9~11"             |
      | "13~10~12"            |
      | "13"                  |
      | "13~9~13"             |
      | "13~10~13"            |
    When executing query:
      """
      USE sample_test
      MATCH p=(src:Person where src.id=10)~[e:KNOWS SAMPLE 1]~{0,2}(dst)
      RETURN
         src.id AS srcId,
         dst.id AS dstId,
         length(p) AS hopCnt,
         transform(nodes(p), x -> x.id) as nodes,
         transform(edges(p), x -> type(x)="KNOWS") as isDirect,
         range(0, length(p)) as hops
      ORDER BY srcId, dstId, hopCnt
      NEXT use sample_test
      RETURN
         reduce(hops, "", (state, i) -> state || (CAST(nodes[i] AS STRING) || case when i+1=size(hops) then "" else case when isDirect[i] then "->" else "~" end end)) AS multi_hop_mixed_paths
      """
    Then the result should be, in any order:
      | multi_hop_mixed_paths |
      | 11                    |
      | 12                    |
      | 13                    |
    When executing query:
      """
      USE sample_test
      MATCH p=(src:Person where src.id>10)-[e:KNOWS SAMPLE 1]-{0,2}(dst)
      RETURN
         src.id AS srcId,
         dst.id AS dstId,
         length(p) AS hopCnt,
         transform(nodes(p), x -> x.id) as nodes,
         transform(edges(p), x -> type(x)="KNOWS") as isDirect,
         range(0, length(p)) as hops
      ORDER BY srcId, dstId, hopCnt
      NEXT use sample_test
      RETURN
         reduce(hops, "", (state, i) -> state || (CAST(nodes[i] AS STRING) || case when i+1=size(hops) then "" else case when isDirect[i] then "->" else "~" end end)) AS multi_hop_mixed_paths
      """
    Then the result should be, in any order:
      | multi_hop_mixed_paths |
      | 11                    |
      | 12                    |
      | 13                    |
    When executing query:
      """
      USE sample_test
      MATCH p=(src:Person where src.id>10)-[e:KNOWS SAMPLE 2]-{0,2}(dst)
      RETURN
         src.id AS srcId,
         dst.id AS dstId,
         length(p) AS hopCnt,
         transform(nodes(p), x -> x.id) as nodes,
         transform(edges(p), x -> type(x)="KNOWS") as isDirect,
         range(0, length(p)) as hops
      ORDER BY srcId, dstId, hopCnt
      NEXT use sample_test
      RETURN reduce(hops,
      "",
      (state, i) -> state || (CAST(nodes[i] AS STRING) || case when i+1=size(hops) then "" else case when isDirect[i] then "->" else "~" end end)) AS multi_hop_mixed_paths
      """
    Then the result should be, in any order:
      | multi_hop_mixed_paths |
      | 11                    |
      | 12                    |
      | 13                    |

  # these test cases will get unstable results bcz we disable edge index sampling for now, so skip this scenario
  @skip
  Scenario: index sampling
    # we only test outging edges bcz the edge index only storage for outgoing edges by design
    When executing query:
      """
      USE sample_test CREATE INDEX IF NOT EXISTS edge_index1 ON EDGE KNOWS(creationDate)
      """
    Then the execution should be successful
    When executing query:
      """
      USE sample_test
      MATCH ()-[e:KNOWS SAMPLE RIGHT 3]->() where e.creationDate > local_datetime('2025-07-23T03:00:00.000')
      RETURN count(*) AS cnt
      """
    # 1+2+3*7+2
    Then the result should be, in order:
      | cnt |
      | 26  |
    When executing query:
      """
      USE sample_test
      MATCH ()-[e:KNOWS SAMPLE RIGHT 50%]->() where e.creationDate > local_datetime('2025-07-23T03:00:00.000')
      RETURN count(*) AS cnt
      """
    # 1+1+2+2+3+3+4+2+2+1
    Then the result should be, in order:
      | cnt |
      | 21  |
    # edge scan & edge index scan sampling
    When executing query:
      """
      USE sample_test
      MATCH ()<-[e:KNOWS SAMPLE RIGHT RANDOM 3]->() where e.creationDate > local_datetime('2025-07-23T03:00:00.000')
      RETURN count(*) AS cnt
      """
    # 26+18
    Then the result should be, in order:
      | cnt |
      | 44  |
    When executing query:
      """
      USE sample_test
      MATCH ({id:10})-[e:KNOWS SAMPLE RIGHT 3]->() where e.creationDate > local_datetime('2025-07-23T03:00:00.000')
      RETURN count(*) AS cnt
      """
    Then the result should be, in order:
      | cnt |
      | 2   |
    When executing query:
      """
      USE sample_test
      MATCH ({id:7})-[e:KNOWS SAMPLE RIGHT 3]->() where e.creationDate > local_datetime('2025-07-23T03:00:00.000')
      RETURN count(*) AS cnt
      """
    Then the result should be, in order:
      | cnt |
      | 3   |
    When executing query:
      """
      USE sample_test
      MATCH ({id:3})-[e:KNOWS SAMPLE RIGHT 3]->(n) where e.creationDate > local_datetime('2025-07-26T01:00:00.000')
      RETURN n.id AS dstId
      """
    Then the result should be, in any order:
      | dstId |
      | 3     |
      | 2     |
    When executing query:
      """
      USE sample_test
      MATCH ({id:3})-[e:KNOWS SAMPLE RIGHT RANDOM 1]->(n) where e.creationDate > local_datetime('2025-07-26T01:00:00.000')
      RETURN count(*) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 1   |

  Scenario: errors
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS directed_graph_type AS {
      NODE Person (LABEL Person {id INT64 PRIMARY KEY}),
      EDGE KNOWS (Person)-[:KNOWS{creationDate LOCAL DATETIME  MULTIEDGE KEY, vec VECTOR<3,float>}]->(Person)}
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS directed_graph directed_graph_type
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS undirected_graph_type AS {
      NODE Person (LABEL Person {id INT64 PRIMARY KEY}),
      EDGE KNOWS (Person)-[:KNOWS{creationDate LOCAL DATETIME  MULTIEDGE KEY, vec VECTOR<3,float>}]->(Person),
      EDGE KNOWS_EACHOTHER (Person)~[:KNOWS{id INT MULTIEDGE KEY}]~(Person)}
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS undirected_graph undirected_graph_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE directed_graph
      MATCH p = (src:Person)-[e:KNOWS SAMPLE RIGHT 1.3%]-{0,2}(dst)
      RETURN
         src.id AS srcId,
         dst.id AS dstId
      """
    Then the execution should be successful
    When executing query:
      """
      USE directed_graph
      MATCH p = (src:Person)-[e:KNOWS SAMPLE RIGHT 1.3]-{0,2}(dst)
      RETURN
         src.id AS srcId,
         dst.id AS dstId
      """
    Then an Error should be raised: "[42001]: Invalid sample quantity `1.3`, expected integer but got DECIMAL near `1.3`, at [L2:52-L2:54]"
    When executing query:
      """
      USE directed_graph
      MATCH p = (src:Person)-[e:KNOWS SAMPLE RIGHT 1e03]-{0,2}(dst)
      RETURN
         src.id AS srcId,
         dst.id AS dstId
      """
    Then an Error should be raised: "[42001]: Invalid sample quantity `1000`, expected integer but got DOUBLE near `1e03`, at [L2:52-L2:55]"
    When executing query:
      """
      USE directed_graph
      MATCH p = (src:Person)-[e:KNOWS SAMPLE RIGHT 139%]-{0,2}(dst)
      RETURN
         src.id AS srcId,
         dst.id AS dstId
      """
    Then an Error should be raised: "[42001]: Invalid sample quantity `139`, expected percentage in range (0, 100] but got 139.000000 near `139`, at [L2:52-L2:54]"
    When executing query:
      """
      USE directed_graph
      MATCH p = (src:Person)~[e:KNOWS SAMPLE RIGHT 3]~{0,2}(dst)
      RETURN
         src.id AS srcId,
         dst.id AS dstId
      """
    Then the execution should be successful
    When executing query:
      """
      USE undirected_graph
      MATCH p = (src:Person)~[e:KNOWS SAMPLE RIGHT 3]~{0,2}(dst)
      RETURN
         src.id AS srcId,
         dst.id AS dstId
      """
    Then an Error should be raised: "[NS235]: Invalid sample: Sampling on undirected edge type `KNOWS_EACHOTHER` is not supported yet"
    When executing query:
      """
      USE directed_graph
      MATCH p = (src:Person)<~[e:KNOWS SAMPLE RIGHT 3]~{0,2}(dst)
      RETURN
         src.id AS srcId,
         dst.id AS dstId
      """
    Then the execution should be successful
    When executing query:
      """
      USE undirected_graph
      MATCH p = (src:Person)<~[e:KNOWS SAMPLE RIGHT 3]~{0,2}(dst)
      RETURN
         src.id AS srcId,
         dst.id AS dstId
      """
    Then an Error should be raised: "[NS235]: Invalid sample: Sampling on undirected edge type `KNOWS_EACHOTHER` is not supported yet"
    When executing query:
      """
      USE directed_graph
      MATCH p = (src:Person)~[e:KNOWS SAMPLE RIGHT 3]~>{0,2}(dst)
      RETURN
         src.id AS srcId,
         dst.id AS dstId
      """
    Then the execution should be successful
    When executing query:
      """
      USE undirected_graph
      MATCH p = (src:Person)~[e:KNOWS SAMPLE RIGHT 3]~>{0,2}(dst)
      RETURN
         src.id AS srcId,
         dst.id AS dstId
      """
    Then an Error should be raised: "[NS235]: Invalid sample: Sampling on undirected edge type `KNOWS_EACHOTHER` is not supported yet"
    When executing query:
      """
      USE directed_graph
      MATCH p = (src:Person)-[e:KNOWS SAMPLE RIGHT 3]-{0,2}(dst)
      RETURN
         src.id AS srcId,
         dst.id AS dstId
      """
    Then the execution should be successful
    When executing query:
      """
      USE undirected_graph
      MATCH p = (src:Person)-[e:KNOWS SAMPLE RIGHT 3]-{0,2}(dst)
      RETURN
         src.id AS srcId,
         dst.id AS dstId
      """
    Then an Error should be raised: "[NS235]: Invalid sample: Sampling on undirected edge type `KNOWS_EACHOTHER` is not supported yet"
    When executing query:
      """
      USE undirected_graph
      MATCH p = (src:Person)-[e@KNOWS SAMPLE RIGHT 3]-{0,2}(dst)
      RETURN
         src.id AS srcId,
         dst.id AS dstId
      """
    Then the execution should be successful
    When executing query:
      """
      USE directed_graph
      MATCH p = (src:Person)~[e:KNOWS where e.creationDate > local_datetime('2025-07-23T03:00:00.000') SAMPLE RIGHT 3]~>{0,2}(dst)
      RETURN
         src.id AS srcId,
         dst.id AS dstId
      """
    Then an Error should be raised: "[NT000]: The `SAMPLE` clause after `WHERE` clause is not supported yet"

  Scenario: fix #10413
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS sample_10413_gt AS {
      NODE Person (LABEL Person {
        id INT64 PRIMARY KEY,
        firstName STRING,
        birthday DATE,
        creationDate LOCAL DATETIME,
        vec VECTOR<3,float> ,
        geog GEOGRAPHY default st_point(0,0)
        }),
      NODE Organisation (LABELS University&Company {id INT64 PRIMARY KEY, kind STRING, name STRING, url STRING}),
      EDGE WORK_AT (Person)-[:AFFILIATED_WITH{workFrom INT32}]->(Organisation),
      EDGE STUDY_AT (Person)-[:AFFILIATED_WITH{classYear INT32}]->(Organisation),
      EDGE KNOWS (Person)-[:KNOWS{
            creationDate LOCAL DATETIME MULTIEDGE KEY,
            vec VECTOR<3,float>,
            geog GEOGRAPHY default st_point(0,0)
        }]->(Person),
      EDGE KNOWS_EACHOTHER (Person)~[:KNOWS{id INT}]~(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS sample_10413_g sample_10413_gt
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION SET GRAPH sample_10413_g
      """
    Then the execution should be successful
    When executing query:
      """
      for i in range (1,3)
      insert (@Person{id:i}),(@Organisation{id:i})
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {src, dst} =
        (1,1),(1,2),(1,3),
        (2,1),(2,2),
        (3,1)
        FOR r IN t
        MATCH (a@Person WHERE a.id = r.src), (b@Person WHERE b.id = r.dst)
        INSERT OR REPLACE(a)-[:KNOWS{creationDate:local_timestamp}]->(b)
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {src, dst} =
        (1,1),(1,2)
        FOR r IN t
        MATCH (a@Person WHERE a.id = r.src), (b@Organisation WHERE b.id = r.dst)
        INSERT OR REPLACE(a)-[@STUDY_AT{}]->(b)
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {src, dst} =
        (1,1)
        FOR r IN t
        MATCH (a@Person WHERE a.id = r.src), (b@Organisation WHERE b.id = r.dst)
        INSERT OR REPLACE(a)-[@WORK_AT{}]->(b)
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {src, dst} =
        (1,1),(1,2),(1,3),
        (2,1),(2,2),
        (3,1)
        FOR r IN t
        MATCH (a@Person WHERE a.id = r.src), (b@Person WHERE b.id = r.dst)
        INSERT OR REPLACE(a)-[:KNOWS{creationDate:local_timestamp+duration'P1Y'}]->(b)
      """
    Then the execution should be successful
    When executing query:
      """
      MATCH (dst)<-[e]-(src)
      ORDER BY type(e),dst.id
      RETURN dst.id AS dst,type(e) AS et,count(*) AS cnt
      """
    Then the result should be, in any order:
      | dst | et         | cnt |
      | 1   | "KNOWS"    | 6   |
      | 2   | "KNOWS"    | 4   |
      | 3   | "KNOWS"    | 2   |
      | 1   | "STUDY_AT" | 1   |
      | 2   | "STUDY_AT" | 1   |
      | 1   | "WORK_AT"  | 1   |
    When executing query:
      """
      MATCH (dst)<-[e sample right 5]-(src)
      ORDER BY type(e),dst.id
      RETURN dst.id AS dst,type(e) AS et,count(*) AS cnt
      """
    Then the result should be, in any order:
      | dst | et         | cnt |
      | 1   | "KNOWS"    | 5   |
      | 2   | "KNOWS"    | 4   |
      | 3   | "KNOWS"    | 2   |
      | 1   | "STUDY_AT" | 1   |
      | 2   | "STUDY_AT" | 1   |
      | 1   | "WORK_AT"  | 1   |
    When executing query:
      """
      MATCH (dst where dst.id<3)<-[e sample right 5]-(src)
      ORDER BY type(e),dst.id
      RETURN dst.id AS dst,type(e) AS et,count(*) AS cnt
      """
    Then the result should be, in any order:
      | dst | et         | cnt |
      | 1   | "KNOWS"    | 5   |
      | 2   | "KNOWS"    | 4   |
      | 1   | "STUDY_AT" | 1   |
      | 2   | "STUDY_AT" | 1   |
      | 1   | "WORK_AT"  | 1   |
    When executing query:
      """
      MATCH (dst)<-[e sample right random 3]-(src)
      ORDER BY type(e),dst.id
      RETURN dst.id AS dst,type(e) AS et,count(*) AS cnt
      """
    Then the result should be, in any order:
      | dst | et         | cnt |
      | 1   | "KNOWS"    | 3   |
      | 2   | "KNOWS"    | 3   |
      | 3   | "KNOWS"    | 2   |
      | 1   | "STUDY_AT" | 1   |
      | 2   | "STUDY_AT" | 1   |
      | 1   | "WORK_AT"  | 1   |
    When executing query:
      """
      MATCH (dst)<-[e sample right 33.4%]-(src)
      ORDER BY type(e),dst.id
      RETURN dst.id AS dst,type(e) AS et,count(*) AS cnt
      """
    Then the result should be, in any order:
      | dst | et         | cnt |
      | 1   | "KNOWS"    | 3   |
      | 2   | "KNOWS"    | 2   |
      | 3   | "KNOWS"    | 1   |
      | 1   | "STUDY_AT" | 1   |
      | 2   | "STUDY_AT" | 1   |
      | 1   | "WORK_AT"  | 1   |
    When executing query:
      """
      MATCH (dst)<-[e sample right random 25%]-(src)
      ORDER BY type(e),dst.id
      RETURN dst.id AS dst,type(e) AS et,count(*) AS cnt
      """
    Then the result should be, in any order:
      | dst | et         | cnt |
      | 1   | "KNOWS"    | 2   |
      | 2   | "KNOWS"    | 1   |
      | 3   | "KNOWS"    | 1   |
      | 1   | "STUDY_AT" | 1   |
      | 2   | "STUDY_AT" | 1   |
      | 1   | "WORK_AT"  | 1   |
    When executing query:
      """
      MATCH (dst)<-[e]-(src)
      ORDER BY type(e),dst.id
      RETURN dst.id AS dst,type(e) AS et,count(*) AS cnt, count(distinct src) AS dcnt
      """
    Then the result should be, in any order:
      | dst | et         | cnt | dcnt |
      | 1   | "KNOWS"    | 6   | 3    |
      | 2   | "KNOWS"    | 4   | 2    |
      | 3   | "KNOWS"    | 2   | 1    |
      | 1   | "STUDY_AT" | 1   | 1    |
      | 2   | "STUDY_AT" | 1   | 1    |
      | 1   | "WORK_AT"  | 1   | 1    |
    When executing query:
      """
      MATCH (dst)<-[e sample right UNQ_NBR 2]-(src)
      ORDER BY type(e),dst.id
      RETURN dst.id AS dst,type(e) AS et,count(*) AS cnt, count(distinct src) AS dcnt
      """
    Then the result should be, in any order:
      | dst | et         | cnt | dcnt |
      | 1   | "KNOWS"    | 2   | 2    |
      | 2   | "KNOWS"    | 2   | 2    |
      | 3   | "KNOWS"    | 1   | 1    |
      | 1   | "STUDY_AT" | 1   | 1    |
      | 2   | "STUDY_AT" | 1   | 1    |
      | 1   | "WORK_AT"  | 1   | 1    |
    And drop the graph "sample_10413_g"
    And drop the graph type "sample_10413_gt"

  Scenario: fix #10897
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS sample_10897_gt AS {
                     NODE Person (LABEL Person {
                       id INT64 PRIMARY KEY,
                       firstName STRING,
                       birthday DATE,
                       creationDate LOCAL DATETIME,
                       vec VECTOR<3,float> ,
                       geog GEOGRAPHY default st_point(0,0)
                       }),
                     NODE Organisation (LABELS University&Company {id INT64 PRIMARY
               KEY, kind STRING, name STRING, url STRING}),
                     EDGE WORK_AT (Person)-[:AFFILIATED_WITH{workFrom
               INT32}]->(Organisation),
                     EDGE STUDY_AT (Person)-[:AFFILIATED_WITH{classYear
               INT32}]->(Organisation),
                     EDGE KNOWS (Person)-[:KNOWS{
                           creationDate LOCAL DATETIME MULTIEDGE KEY,
                           vec VECTOR<3,float>,
                           geog GEOGRAPHY default st_point(0,0)
                       }]->(Person),
                     EDGE KNOWS_EACHOTHER (Person)~[:KNOWS{id INT}]~(Person)
                     }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS sample_10897_g sample_10897_gt
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION SET GRAPH sample_10897_g
      """
    Then the execution should be successful
    When executing query:
      """
      for i in range (1,5) insert (@Person{id:i})
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {src, dst, creationDate} =
                         (1,2,"2002-01-01"),
                         (1,3,"2003-01-01"),(2,3,"2003-01-01"),
                         (3,4,"2004-01-01"),
                         (2,5,"2005-01-01"),(3,5,"2005-01-01"),(4,5,"2005-01-01")
                     FOR r IN t
                     MATCH (a@Person WHERE a.id = r.src), (b@Person WHERE b.id =
               r.dst)
                     INSERT OR REPLACE (a)-[@KNOWS{creationDate:
               date(r.creationDate)}]->(b)
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ set_var(enable_reorder=false) */
      MATCH p= (src@Person)-[e  sample right 2 where e.creationDate <> date('2003-01-01') ]->{0,6}(dst@Person where dst.id=5 )
      RETURN src.id,transform(nodes(p),x -> x.id) as nodes,dst.id
      """
    Then the result should be, in any order:
      | src.id | nodes        | dst.id |
      | 5      | LIST [5]     | 5      |
      | 3      | LIST [3,5]   | 5      |
      | 2      | LIST [2,5]   | 5      |
      | 4      | LIST [4,5]   | 5      |
      | 3      | LIST [3,4,5] | 5      |
      | 1      | LIST [1,2,5] | 5      |
    When executing query:
      """
      /*+ set_var(enable_reorder=true) */
      MATCH p= (src@Person)-[e  sample right 2 where e.creationDate <> date('2003-01-01') ]->{0,6}(dst@Person where dst.id=5 )
      RETURN src.id,transform(nodes(p),x -> x.id) as nodes,dst.id
      """
    Then the result should be, in any order:
      | src.id | nodes        | dst.id |
      | 5      | LIST [5]     | 5      |
      | 3      | LIST [3,5]   | 5      |
      | 2      | LIST [2,5]   | 5      |
      | 4      | LIST [4,5]   | 5      |
      | 3      | LIST [3,4,5] | 5      |
      | 1      | LIST [1,2,5] | 5      |
    And drop the graph "sample_10897_g"
    And drop the graph type "sample_10897_gt"
