# Copyright (c) 2022 vesoft inc. All rights reserved.
Feature: Aggregate

  Scenario: explicit aggregate
    When executing query:
      """
      USE ldbc RETURN SUM(1) AS a GROUP BY ()
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      RETURN SUM(v.id) AS a GROUP BY ()
      """
    Then the result should be, in any order:
      | a  |
      | 10 |
    When executing query:
      """
      FOR i IN [1,2,3,4,5,5,5,5]
      RETURN avg(i) AS a GROUP BY ()
      """
    Then the result should be, in any order:
      | a    |
      | 3.75 |
    When executing query:
      """
      FOR i IN LIST [1,2,3,4,5,5]
      RETURN avg(distinct i) AS a GROUP BY ()
      """
    Then the result should be, in any order:
      | a   |
      | 3.0 |
    When executing query:
      """
      FOR i IN LIST [1,2,3,4,5,5]
      RETURN min(i) AS a GROUP BY ()
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      FOR i IN LIST [1,2,3,4,5,5]
      RETURN min(distinct i) AS a GROUP BY ()
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      FOR i IN LIST ["apple", "banana", "apricot"]
      RETURN max(i) AS a GROUP BY ()
      """
    Then the result should be, in any order:
      | a        |
      | "banana" |
    When executing query:
      """
      FOR i IN LIST ["apple", "banana", "apricot"]
      RETURN min(i) AS a GROUP BY ()
      """
    Then the result should be, in any order:
      | a       |
      | "apple" |
    When executing query:
      """
      FOR i IN LIST ["user", "username", "usergroup"]
      RETURN max(i) AS a GROUP BY ()
      """
    Then the result should be, in any order:
      | a          |
      | "username" |
    When executing query:
      """
      FOR i IN LIST ["user", "username", "usergroup"]
      RETURN min(i) AS a GROUP BY ()
      """
    Then the result should be, in any order:
      | a      |
      | "user" |
    When executing query:
      """
      FOR i IN LIST ["100", "20", "9"]
      RETURN max(i) AS a GROUP BY ()
      """
    Then the result should be, in any order:
      | a   |
      | "9" |
    When executing query:
      """
      FOR i IN LIST ["100", "20", "9"]
      RETURN min(i) AS a GROUP BY ()
      """
    Then the result should be, in any order:
      | a     |
      | "100" |
    When executing query:
      """
      FOR i IN LIST [duration("P1Y"), duration("P365D")]
      RETURN max(i) AS a GROUP BY ()
      """
    Then an Error should be raised: "[22G14]: Incompatible temporal duration unit groups: `DURATION \"P365DT0H0M0.000000S\"` and `DURATION \"P1Y0M\"` are not in the same duration unit group, but trying to compare with greater than, in expression: max(i)"
    When executing query:
      """
      FOR i IN LIST [duration("P1Y"), duration("P365D")]
      RETURN min(i) AS a GROUP BY ()
      """
    Then an Error should be raised: "[22G14]: Incompatible temporal duration unit groups: `DURATION \"P365DT0H0M0.000000S\"` and `DURATION \"P1Y0M\"` are not in the same duration unit group, but trying to compare with less than, in expression: min(i)"
    When executing query:
      """
      FOR i IN LIST [duration("P1M"), duration("P10D")]
      RETURN max(i) AS a GROUP BY ()
      """
    Then an Error should be raised: "[22G14]: Incompatible temporal duration unit groups: `DURATION \"P10DT0H0M0.000000S\"` and `DURATION \"P0Y1M\"` are not in the same duration unit group, but trying to compare with greater than, in expression: max(i)"
    When executing query:
      """
      FOR i IN LIST [duration("P2M"), duration("PT10H")]
      RETURN min(i) AS a GROUP BY ()
      """
    Then an Error should be raised: "[22G14]: Incompatible temporal duration unit groups: `DURATION \"P0DT10H0M0.000000S\"` and `DURATION \"P0Y2M\"` are not in the same duration unit group, but trying to compare with less than, in expression: min(i)"
    When executing query:
      """
      FOR i IN LIST [duration("P1Y2M"), duration("P1Y1M"), duration("P2Y")]
      RETURN max(i) as a GROUP BY ()
      """
    Then the result should be, in any order:
      | a                |
      | duration "P2Y0M" |
    When executing query:
      """
      FOR i IN LIST [duration("P1Y6M"), duration("P1Y9M"), duration("P1Y2M")]
      RETURN min(i) as a GROUP BY ()
      """
    Then the result should be, in any order:
      | a                |
      | duration "P1Y2M" |
    When executing query:
      """
      FOR i IN LIST [date("2024-12-31"), date("2023-01-01"), date("2025-06-15")]
      RETURN max(i) as a GROUP BY ()
      """
    Then the result should be, in any order:
      | a                 |
      | date "2025-06-15" |
    When executing query:
      """
      FOR i IN LIST [date("2024-03-15"), date("2024-01-31"), date("2024-05-01")]
      RETURN min(i) as a GROUP BY ()
      """
    Then the result should be, in any order:
      | a                 |
      | date "2024-01-31" |
    When executing query:
      """
      FOR i IN LIST [date("2024-02-10"), date("2024-02-28"), date("2024-02-01")]
      RETURN max(i) as a GROUP BY ()
      """
    Then the result should be, in any order:
      | a                 |
      | date "2024-02-28" |
    When executing query:
      """
      FOR i IN LIST [local_datetime("2024-01-01T10:00:00"), local_datetime("2023-12-31T23:59:59")]
      RETURN max(i) as a GROUP BY ()
      """
    Then the result should be, in any order:
      | a                              |
      | DATETIME "2024-01-01T10:00:00" |
    When executing query:
      """
      FOR i IN LIST [local_datetime("2024-05-15T10:00:00"), local_datetime("2024-05-15T08:00:00")]
      RETURN max(i) as a GROUP BY ()
      """
    Then the result should be, in any order:
      | a                              |
      | DATETIME "2024-05-15T10:00:00" |
    When executing query:
      """
      FOR i IN LIST [local_datetime("2024-05-15T10:30:00"), local_datetime("2024-05-15T10:15:00")]
      RETURN min(i) as a GROUP BY ()
      """
    Then the result should be, in any order:
      | a                              |
      | DATETIME "2024-05-15T10:15:00" |
    When executing query:
      """
      FOR i IN LIST [local_datetime("2024-05-15T10:30:05"), local_datetime("2024-05-15T10:30:01")]
      RETURN max(i) as a GROUP BY ()
      """
    Then the result should be, in any order:
      | a                              |
      | DATETIME "2024-05-15T10:30:05" |
    When executing query:
      """
      FOR i IN LIST [local_time("10:00:00"), local_time("12:00:00"), local_time("09:00:00")]
      RETURN max(i) as a GROUP BY ()
      """
    Then the result should be, in any order:
      | a               |
      | time "12:00:00" |
    When executing query:
      """
      FOR i IN LIST [local_time("10:30:00"), local_time("10:15:00"), local_time("10:45:00")]
      RETURN min(i) as a GROUP BY ()
      """
    Then the result should be, in any order:
      | a               |
      | time "10:15:00" |
    When executing query:
      """
      FOR i IN LIST [local_time("10:30:05"), local_time("10:30:01"), local_time("10:30:09")]
      RETURN max(i) as a GROUP BY ()
      """
    Then the result should be, in any order:
      | a               |
      | time "10:30:09" |
    When executing query:
      """
      FOR i IN LIST [zoned_datetime("2024-01-01T10:00:00 +08:00","%Y-%m-%dT%H:%M:%S %Ez"), zoned_datetime("2024-01-01T03:00:00 +01:00","%Y-%m-%dT%H:%M:%S %Ez"), zoned_datetime("2024-01-01T02:00:00 +00:00","%Y-%m-%dT%H:%M:%S %Ez")]
      RETURN min(i)=zoned_datetime("2024-01-01T02:00:00Z","%Y-%m-%dT%H:%M:%S %Ez") as a GROUP BY ()
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      FOR i IN LIST [zoned_datetime("2024-10-01T02:00:00 +05:00","%Y-%m-%dT%H:%M:%S %Ez"), zoned_datetime("2024-09-30T23:00:00 -01:00","%Y-%m-%dT%H:%M:%S %Ez")]
      RETURN max(i)=zoned_datetime("2024-09-30T23:00:00 -01:00","%Y-%m-%dT%H:%M:%S %Ez") as a GROUP BY ()
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      FOR i IN LIST [zoned_datetime("2025-01-01T00:00:00.500 +00:00","%Y-%m-%dT%H:%M:%S %Ez"), zoned_datetime("2024-12-31T16:00:00.600 -08:00","%Y-%m-%dT%H:%M:%S %Ez")]
      RETURN min(i)=zoned_datetime("2025-01-01T00:00:00.500 +00:00","%Y-%m-%dT%H:%M:%S %Ez") as a GROUP BY ()
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      FOR i IN LIST [zoned_time("10:00:00 +08:00","%H:%M:%S %Ez"), zoned_time("03:00:00 +01:00","%H:%M:%S %Ez"), zoned_time("02:00:00 +00:00","%H:%M:%S %Ez")]
      RETURN max(i)=zoned_time("10:00:00 +08:00","%H:%M:%S %Ez") as a GROUP BY ()
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      FOR i IN LIST [zoned_time("23:00:00 -02:00","%H:%M:%S %Ez"), zoned_time("00:30:00 +00:00","%H:%M:%S %Ez")]
      RETURN min(i)=zoned_time("00:30:00 +00:00","%H:%M:%S %Ez") as a GROUP BY ()
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      FOR i IN LIST [zoned_time("12:00:00.123 -01:00","%H:%M:%S %Ez"), zoned_time("14:00:00.122 +01:00","%H:%M:%S %Ez")]
      RETURN max(i)=zoned_time("12:00:00.123 -01:00","%H:%M:%S %Ez") as a GROUP BY ()
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      FOR i IN LIST [1,2,3,4,5,5]
      RETURN max(i) AS a GROUP BY ()
      """
    Then the result should be, in any order:
      | a |
      | 5 |
    When executing query:
      """
      FOR i IN LIST [1,2,3,4,5,5]
      RETURN sum(distinct i) AS a GROUP BY ()
      """
    Then the result should be, in any order:
      | a  |
      | 15 |
    When executing query:
      """
      FOR i IN LIST [1,2,3,4,5,5]
      RETURN sum(i) AS a GROUP BY ()
      """
    Then the result should be, in any order:
      | a  |
      | 20 |
    When executing query:
      """
      FOR i IN LIST [5,5,5,5,5]
      RETURN stddev_pop(i) AS a GROUP BY ()
      """
    Then the result should be, in any order:
      | a   |
      | 0.0 |
    When executing query:
      """
      FOR i IN LIST [5,5,5,5,5]
      RETURN stddev_samp(i) AS a GROUP BY ()
      """
    Then the result should be, in any order:
      | a   |
      | 0.0 |
    When executing query:
      """
      FOR i IN LIST [10,4,5,4,10]
      RETURN stddev_pop(i) AS a GROUP BY ()
      """
    Then the result should be, in any order:
      | a   |
      | 2.8 |
    When executing query:
      """
      FOR i IN LIST [1,2,3,4,5,5]
      RETURN max(distinct i) AS a GROUP BY ()
      """
    Then the result should be, in any order:
      | a |
      | 5 |
    When executing query:
      """
      FOR a IN LIST [3,3,3]
      RETURN collect(DISTINCT a) AS l GROUP BY ()
      """
    Then the result should be, in any order:
      | l        |
      | LIST [3] |
    When executing query:
      """
      FOR a IN LIST [VECTOR<3,float>([1,2,3]),VECTOR<3,float>([1,2,3]),VECTOR<3,float>([1,3.3,3]),VECTOR<3,float>([4,2,3])]
      RETURN size(collect(DISTINCT a)) AS l GROUP BY ()
      """
    Then the result should be, in any order:
      | l |
      | 3 |
    When executing query:
      """
      FOR a IN LIST [1,3,3,4,4]
      RETURN COLLECT_LIST(DISTINCT a) AS l GROUP BY ()
      NEXT RETURN size(l) as cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 3   |
    When executing query:
      """
      RETURN COLLECT(DISTINCT current_time) AS l GROUP BY ()
      NEXT RETURN size(l) as cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 1   |
    When executing query:
      """
      FOR i IN [current_timestamp, current_timestamp, current_timestamp]
      RETURN COLLECT(DISTINCT i) AS l GROUP BY ()
      NEXT RETURN size(l) as cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 1   |
    When executing query:
      """
      RETURN COUNT(DISTINCT current_time) AS l GROUP BY ()
      """
    Then the result should be, in any order:
      | l |
      | 1 |
    When executing query:
      """
      RETURN COUNT(DISTINCT current_timestamp) AS l GROUP BY ()
      """
    Then the result should be, in any order:
      | l |
      | 1 |
    When executing query:
      """
      RETURN COUNT(DISTINCT VECTOR<3,float>([1,2,3])) AS l GROUP BY ()
      """
    Then the result should be, in any order:
      | l |
      | 1 |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)-[:KNOWS]-(n)
      RETURN v.gender AS a, sum(n.id)+avg(v.id) AS b
      GROUP BY a
      """
    Then the result should be, in any order:
      | a      | b    |
      | "male" | 14.0 |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)-[:KNOWS]-(n)
      RETURN CASE WHEN v.gender="male" THEN 1 ELSE 0 END + sum(n.id)+avg(v.id)+3.3 AS b, v.gender AS x
      GROUP BY x
      """
    Then the result should be, in any order:
      | b    | x      |
      | 18.3 | "male" |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)-[:KNOWS]-(n)
      RETURN abs(v.id+v.id+abs(count(v)+avg(n.id+1)+abs(v.id))) as s ,3,count(*)+1.1 AS cnt, v.id AS vid
      GROUP BY vid
      NEXT
      USE ldbc
      RETURN s,3,cnt ORDER BY s
      """
    Then the result should be, in order:
      | s    | 3 | cnt  |
      | 7.0  | 3 | 3.1M |
      | 11.0 | 3 | 3.1M |
      | 15.0 | 3 | 3.1M |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)-[:KNOWS]-(n)
      RETURN v.gender AS a, sum(n.id)+avg(v.id) AS b GROUP BY a
      NEXT
      USE ldbc
      RETURN a
      """
    Then the result should be, in any order:
      | a      |
      | "male" |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)-[:KNOWS]-(n)
      RETURN v.gender AS a, sum(n.id)+avg(v.id+1)+v.id AS b GROUP BY v
      NEXT
      USE ldbc
      RETURN b
      """
    Then the result should be, in any order:
      | b    |
      | 9.0  |
      | 13.0 |
      | 5.0  |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)-[:KNOWS]-(n)
      RETURN v.gender AS a, sum(n.id)+avg(v.id+1)+v.id AS b, v.id+1 GROUP BY v
      NEXT
      USE ldbc
      RETURN b
      """
    Then the result should be, in any order:
      | b    |
      | 9.0  |
      | 13.0 |
      | 5.0  |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)-[:KNOWS]->(f:Person)
      RETURN v, v.id+f.id AS a, count(1)+v.id AS b GROUP BY (v), f
      """
    Then the result should be, in any order:
      | v                                                                                                                                                                                                       | a | b |
      | ({birthday:DATE '1995-06-12',browserUsed:"Firefox",creationDate:DATETIME '2021-01-01T12:00:40.213000',firstName:"Ming",gender:"male",id:3,lastName:"Yao",locationIP:"192.168.3",vec:VECTOR [7,8,9]})    | 6 | 4 |
      | ({birthday:DATE '2001-04-25',browserUsed:"IE",creationDate:DATETIME '2021-01-01T11:00:40.213000',firstName:"Tim",gender:"male",id:2,lastName:"Duncan",locationIP:"192.168.2",vec:VECTOR [4.0,5.0,6.0]}) | 4 | 3 |
      | ({birthday:DATE '1990-01-01',browserUsed:"Chrome",creationDate:DATETIME '2021-01-01T10:00:40.213000',firstName:"Kyle",gender:"male",id:1,lastName:"cao",locationIP:"192.168.1",vec:VECTOR [1,2,3]})     | 2 | 2 |
    When executing query:
      """
      USE ldbc FOR ua0 IN RANGE(0, 1) MATCH (v:Person{id:100}) RETURN count(v) as cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 0   |
    When executing query:
      """
      VALUE chongqing = VALUE {
        USE ldbc
        MATCH (s:Person)-[:KNOWS]->(t:Person)
        RETURN [sum(t.id), sum(CASE WHEN t.id > 0 THEN t.id ELSE 0 END)]
        GROUP BY ()
      }
      RETURN chongqing
      """
    Then the result should be, in any order:
      | chongqing   |
      | LIST [6, 6] |
    When executing query:
      """
      use ldbc match (n@Organisation)-[r@IS_LOCATED_IN_4]-(m) return collect(m) as mset group by ()
      next
      use ldbc for i in mset return mset,i.kind as ikind
      next
      use ldbc return length(mset) as length, any_value(ikind) as kind group by mset
      """
    Then the result should be, in any order:
      | length | kind   |
      | 3      | "city" |
    When executing query:
      """
      use ldbc match (v@Organisation) order by v.id return any_value(v) as rr group by ()
      """
    Then the result should be, in any order:
      | rr                                                 |
      | ({id:1,kind:1,name:"org1",url:"https://org1.com"}) |
    When executing query:
      """
      use ldbc match (v@Organisation) order by v.id return any_value(v.id) as rr group by ()
      """
    Then the result should be, in any order:
      | rr |
      | 1  |
    When executing query:
      """
      use ldbc match (v@Organisation) order by v.id return any_value(v.name) as rr group by ()
      """
    Then the result should be, in any order:
      | rr     |
      | "org1" |
    When executing query:
      """
      use ldbc match (v@Post) order by v.id return any_value(v.creationDate) as rr group by ()
      """
    Then the result should be, in any order:
      | rr                                    |
      | DATETIME "2021-01-01T10:00:40.213000" |
    When executing query:
      """
      use ldbc match (v@Organisation)-[e]->() order by v.id return any_value(e) as rr group by ()
      """
    Then the result should be, in any order:
      | rr   |
      | [{}] |
    When executing query:
      """
      use ldbc match p=(v@Organisation)-[e]->() order by v.id return any_value(p) as rr group by ()
      """
    Then the result should be, in any order:
      | rr                                                                                                                           |
      | PATH [({id:1,kind:1,name:"org1",url:"https://org1.com"}),[{}],({id:1,kind:"city",name:"Beijing",url:"https://beijing.com"})] |
    When executing query:
      """
      RETURN avg(value {return 2.2 limit 1}) AS a GROUP BY ()
      """
    Then the result should be, in any order:
      | a    |
      | 2.2M |
    When executing query:
      """
      USE ldbc MATCH TRAIL (v1:Person)-[e]->{1,2}(v2:Person)
      RETURN count(DISTINCT
                     VALUE {for i in e RETURN type(i) AS t ORDER BY t LIMIT 1}
      ) AS types
      GROUP BY v2
      """
    Then the result should be, in any order:
      | types |
      | 1     |
      | 4     |
      | 4     |
      | 4     |
    When executing query:
      """
      USE ldbc MATCH TRAIL (v1:Person)-[e]->{1,2}(v2:Person)
      RETURN sum(VALUE {RETURN v1.id LIMIT 1}) AS s GROUP BY v2
      """
    Then the result should be, in any order:
      | s  |
      | 8  |
      | 14 |
      | 23 |
      | 19 |
    When executing query:
      """
      USE ldbc MATCH TRAIL (v1:Person)-[e]->{1,2}(v2:Person)
      ORDER BY v1.id
      RETURN collect(
        EXISTS {MATCH (v1)-[:WORK_AT]->(v3{id:1}) RETURN v1 ORDER BY v1.id LIMIT 1})
      AS work_at_1
      GROUP BY v2
      """
    Then the result should be, in any order:
      | work_at_1                                                             |
      | LIST [true,false,false,false]                                         |
      | LIST [true,false,false,false,false,false,false,false]                 |
      | LIST [true,true,true,false,false,false,false]                         |
      | LIST [true,true,true,false,false,false,false,false,false,false,false] |
    When executing query:
      """
      FOR row IN [[1,1,1.1],[1,1,1.1],[1,2,1.2],[2,3,4],[4,4,4],[1,2,4],[3,2,5.5],[2,1,1.1],[2,2,1.2],[1,3,4],[3,4,4],[4,2,4],[2,2,5.5]]
      LET a=row[0],b=row[1],c=row[2]
      RETURN a,b,c
      NEXT RETURN a,percentile_cont(c,0) AS p GROUP BY a
      """
    Then the result should be, in any order:
      | a    | p    |
      | 1.0M | 1.1M |
      | 2.0M | 1.1M |
      | 4.0M | 4.0M |
      | 3.0M | 4.0M |
    When executing query:
      """
      FOR row IN [[1,1,1.1],[1,1,1.1],[1,2,1.2],[2,3,4],[4,4,4],[1,2,4],[3,2,5.5],[2,1,1.1],[2,2,1.2],[1,3,4],[3,4,4],[4,2,4],[2,2,5.5]]
      LET a=row[0],b=row[1],c=row[2]
      RETURN a,b,c
      NEXT RETURN a,percentile_cont(c,0.5) AS p GROUP BY a
      """
    Then the result should be, in any order:
      | a    | p     |
      | 1.0M | 1.2M  |
      | 2.0M | 2.6M  |
      | 4.0M | 4.0M  |
      | 3.0M | 4.75M |
    When executing query:
      """
      FOR row IN [[1,1,1.1],[1,1,1.1],[1,2,1.2],[2,3,4],[4,4,4],[1,2,4],[3,2,5.5],[2,1,1.1],[2,2,1.2],[1,3,4],[3,4,4],[4,2,4],[2,2,5.5]]
      LET a=row[0],b=row[1],c=row[2]
      RETURN a,b,c
      NEXT RETURN a,percentile_cont(c,0.75) AS p GROUP BY a
      """
    Then the result should be, in any order:
      | a    | p      |
      | 1.0M | 4.0M   |
      | 2.0M | 4.375M |
      | 4.0M | 4.0M   |
      | 3.0M | 5.125M |
    When executing query:
      """
      FOR row IN [[1,1,1.1],[1,1,1.1],[1,2,1.2],[2,3,4],[4,4,4],[1,2,4],[3,2,5.5],[2,1,1.1],[2,2,1.2],[1,3,4],[3,4,4],[4,2,4],[2,2,5.5]]
      LET a=row[0],b=row[1],c=row[2]
      RETURN a,b,c
      NEXT RETURN a,percentile_cont(c,1) AS p GROUP BY a
      """
    Then the result should be, in any order:
      | a    | p    |
      | 1.0M | 4.0M |
      | 2.0M | 5.5M |
      | 4.0M | 4.0M |
      | 3.0M | 5.5M |
    When executing query:
      """
      FOR row IN [[1,1,1.1],[1,1,1.1],[1,2,1.2],[2,3,4],[4,4,4],[1,2,4],[3,2,5.5],[2,1,1.1],[2,2,1.2],[1,3,4],[3,4,4],[4,2,4],[2,2,5.5]]
      LET a=row[0],b=row[1],c=row[2]
      RETURN a,b,c
      NEXT RETURN a,percentile_cont(c,a*0.01) AS p GROUP BY a
      """
    Then the result should be, in any order:
      | a    | p      |
      | 1.0M | 1.1M   |
      | 2.0M | 1.106M |
      | 4.0M | 4.0M   |
      | 3.0M | 4.045M |
    When executing query:
      """
      FOR row IN [[1,1,1.1],[1,1,1.1],[1,2,1.2],[2,3,4],[4,4,4],[1,2,4],[3,2,5.5],[2,1,1.1],[2,2,1.2],[1,3,4],[3,4,4],[4,2,4],[2,2,5.5]]
      LET a=row[0],b=row[1],c=row[2]
      RETURN a,b,c
      NEXT RETURN a,percentile_cont(distinct c,a*0.01) AS p GROUP BY a
      """
    Then the result should be, in any order:
      | a    | p      |
      | 1.0M | 1.102M |
      | 2.0M | 1.106M |
      | 4.0M | 4.0M   |
      | 3.0M | 4.045M |
    When executing query:
      """
      FOR row IN [[1,1,1.1],[1,1,1.1],[1,2,1.2],[2,3,4],[4,4,4],[1,2,4],[3,2,5.5],[2,1,1.1],[2,2,1.2],[1,3,4],[3,4,4],[4,2,4],[2,2,5.5]]
      LET a=row[0],b=row[1],c=row[2]
      RETURN a,b,c
      NEXT RETURN a,percentile_disc(c,a*0.01) AS p GROUP BY a
      """
    Then the result should be, in any order:
      | a    | p    |
      | 1.0M | 1.1M |
      | 2.0M | 1.1M |
      | 4.0M | 4.0M |
      | 3.0M | 4.0M |
    When executing query:
      """
      FOR row IN [[1,1,1.1],[1,1,1.1],[1,2,1.2],[2,3,4],[4,4,4],[1,2,4],[3,2,5.5],[2,1,1.1],[2,2,1.2],[1,3,4],[3,4,4],[4,2,4],[2,2,5.5]]
      LET a=row[0],b=row[1],c=row[2]
      RETURN a,b,c
      NEXT RETURN a,percentile_disc(c,0.0) AS p GROUP BY a
      """
    Then the result should be, in any order:
      | a    | p    |
      | 1.0M | 1.1M |
      | 2.0M | 1.1M |
      | 4.0M | 4.0M |
      | 3.0M | 4.0M |
    When executing query:
      """
      FOR row IN [[1,1,1.1],[1,1,1.1],[1,2,1.2],[2,3,4],[4,4,4],[1,2,4],[3,2,5.5],[2,1,1.1],[2,2,1.2],[1,3,4],[3,4,4],[4,2,4],[2,2,5.5]]
      LET a=row[0],b=row[1],c=row[2]
      RETURN a,b,c
      NEXT RETURN a,percentile_disc(c,0.5) AS p GROUP BY a
      """
    Then the result should be, in any order:
      | a    | p    |
      | 1.0M | 1.2M |
      | 2.0M | 1.2M |
      | 4.0M | 4.0M |
      | 3.0M | 4.0M |
    When executing query:
      """
      FOR row IN [[1,1,1.1],[1,1,1.1],[1,2,1.2],[2,3,4],[4,4,4],[1,2,4],[3,2,5.5],[2,1,1.1],[2,2,1.2],[1,3,4],[3,4,4],[4,2,4],[2,2,5.5]]
      LET a=row[0],b=row[1],c=row[2]
      RETURN a,b,c
      NEXT RETURN a,percentile_disc(c,0.75) AS p GROUP BY a
      """
    Then the result should be, in any order:
      | a    | p    |
      | 1.0M | 4.0M |
      | 2.0M | 4.0M |
      | 4.0M | 4.0M |
      | 3.0M | 4.0M |
    When executing query:
      """
      FOR row IN [[1,1,1.1],[1,1,1.1],[1,2,1.2],[2,3,4],[4,4,4],[1,2,4],[3,2,5.5],[2,1,1.1],[2,2,1.2],[1,3,4],[3,4,4],[4,2,4],[2,2,5.5]]
      LET a=row[0],b=row[1],c=row[2]
      RETURN a,b,c
      NEXT RETURN a,percentile_disc(c,1) AS p GROUP BY a
      """
    Then the result should be, in any order:
      | a    | p    |
      | 1.0M | 4.0M |
      | 2.0M | 5.5M |
      | 4.0M | 4.0M |
      | 3.0M | 5.5M |
    When executing query:
      """
      FOR row IN [[1,1,1.1],[1,1,1.1],[1,2,1.2],[2,3,4],[4,4,4],[1,2,4],[3,2,5.5],[2,1,1.1],[2,2,1.2],[1,3,4],[3,4,4],[4,2,4],[2,2,5.5]]
      LET a=row[0],b=row[1],c=row[2]
      RETURN a,b,c
      NEXT RETURN a,percentile_disc(distinct c,a*0.25) AS p GROUP BY a
      """
    Then the result should be, in any order:
      | a    | p    |
      | 1.0M | 1.1M |
      | 2.0M | 1.2M |
      | 4.0M | 4.0M |
      | 3.0M | 4.0M |

  Scenario: implicit aggregate
    When executing query:
      """
      USE ldbc MATCH (v:City)
      RETURN avg(v.id)
      """
    Then the result should be, in any order:
      | avg(v.id) |
      | 3.5M      |
    When executing query:
      """
      RETURN SUM(1)
      """
    Then the result should be, in any order:
      | SUM(1) |
      | 1M     |
    When executing query:
      """
      VALUE chongqing = VALUE {
        USE ldbc
        MATCH (s:Person)-[:KNOWS]->(t:Person)
        RETURN [sum(t.id), sum(CASE WHEN t.id > 0 THEN t.id ELSE 0 END)]
      }
      RETURN chongqing
      """
    Then the result should be, in any order:
      | chongqing   |
      | LIST [6, 6] |
    When executing query:
      """
      FOR row IN [[1,1,1.1],[1,1,1.1],[1,2,1.2],[2,3,4],[4,4,4],[1,2,4],[3,2,5.5],[2,1,1.1],[2,2,1.2],[1,3,4],[3,4,4],[4,2,4],[2,2,5.5]]
      LET a=row[0],b=row[1],c=row[2]
      RETURN a,b,c
      NEXT RETURN a,percentile_disc(c,0.75) AS p
      """
    Then the result should be, in any order:
      | a    | p    |
      | 1.0M | 4.0M |
      | 2.0M | 4.0M |
      | 4.0M | 4.0M |
      | 3.0M | 4.0M |

  Scenario: errors
    When executing query:
      """
      USE ldbc RETURN SUM(distinct count(1)) AS a
      """
    Then an Error should be raised: "[NT202]: Unsupported, aggregate expressions cannot be nested: `sum(DISTINCT count(1))`"
    When executing query:
      """
      USE ldbc MATCH (v:City)
      FOR i IN collect(distinct v.id)
      RETURN i
      """
    Then an Error should be raised: "[NT203]: Aggregate function `collect(DISTINCT v.id)` is not allowed in this context"
    When executing query:
      """
      USE ldbc MATCH (v:City where count(v.id)>1)
      where size(collect(distinct(v)))>3
      RETURN v
      """
    Then an Error should be raised: "[NT203]: Aggregate function `count(v.id)` is not allowed in this context"
    When executing query:
      """
      USE ldbc MATCH (v:City where v.id>1)
      where size(collect(distinct(v)))>3
      RETURN v
      """
    Then an Error should be raised: "[NT203]: Aggregate function `collect(DISTINCT v)` is not allowed in this context"
    When executing query:
      """
      USE ldbc MATCH (v:City where v.id>1)
      FILTER where size(collect(distinct(v)))>3
      RETURN v
      """
    Then an Error should be raised: "[NT203]: Aggregate function `collect(DISTINCT v)` is not allowed in this context"
    When executing query:
      """
      USE ldbc MATCH (v:City where v.id>1)
      LET x=size(collect(distinct(v)))>3
      RETURN x
      """
    Then an Error should be raised: "[NT203]: Aggregate function `collect(DISTINCT v)` is not allowed in this context"
    When executing query:
      """
      USE ldbc MATCH (v:City)
      ORDER BY abs(count(v.id))
      RETURN v
      """
    Then an Error should be raised: "[NT203]: Aggregate function `count(v.id)` is not allowed in this context"
    When executing query:
      """
      USE ldbc MATCH (v:City)
      RETURN * GROUP BY ()
      """
    Then an Error should be raised: "[NS106]: Semantic error, return all can't be used with user specified group bys"
    When executing query:
      """
      USE ldbc MATCH (v:City)
      RETURN * GROUP BY v
      """
    Then an Error should be raised: "[NS106]: Semantic error, return all can't be used with user specified group bys"
    When executing query:
      """
      USE ldbc MATCH (v:City)
      RETURN count(*) GROUP BY v.id
      """
    Then an Error should be raised: "[NS203]: Semantic error, user specified group bys must be binding variable: `v.id`"
    When executing query:
      """
      USE ldbc MATCH (v:City)
      RETURN count(*) AS cnt, avg(v.id) AS cnt GROUP BY v.id
      """
    Then an Error should be raised: "[NS109]: Semantic error, duplicate column name in return statement: `cnt`"
    When executing query:
      """
      USE ldbc MATCH (v:City)
      RETURN v.id, count(*) GROUP BY ()
      """
    Then an Error should be raised: "[NS205]: Semantic error, group bys mismatched"
    When executing query:
      """
      USE ldbc MATCH (v:City)
      RETURN v.id, v.name GROUP BY v
      """
    Then an Error should be raised: "[NS202]: Semantic error, no aggregates found but specified group bys"
    When executing query:
      """
      USE ldbc MATCH (v:City)
      RETURN v.id AS vid, avg(v.id) AS a GROUP BY vid, a
      """
    Then an Error should be raised: "[NS204]: Semantic error, group by item `a` can't contain aggregate expressions: `avg(v.id)`"
    When executing query:
      """
      USE ldbc MATCH (v:City)
      RETURN v.id AS vid, v.name, avg(v.id) AS a GROUP BY vid,v
      """
    Then an Error should be raised: "[NS205]: Semantic error, group bys mismatched"
    When executing query:
      """
      USE ldbc MATCH (v:City)
      RETURN v.id AS vid, v.name, avg(v.id) AS a GROUP BY vid,n
      """
    Then an Error should be raised: "[42N18]: Invalid syntax, variable `n` not defined"
    When executing query:
      """
      USE ldbc MATCH (v:City)
      RETURN v.id AS vid, v.name, avg(v.id) AS a GROUP BY vid,(),n
      """
    Then an Error should be raised: "[42001]: syntax error near `)`"
    When executing query:
      """
      USE ldbc MATCH (v:City)
      RETURN v.id AS vid, v.name, avg(v.id) AS a GROUP BY (),n
      """
    Then an Error should be raised: "[42001]: syntax error near `,`"
    When executing query:
      """
      FOR row IN [[1,1,1.1],[1,1,1.1],[1,2,1.2],[2,3,4],[4,4,4],[1,2,4],[3,2,5.5],[2,1,1.1],[2,2,1.2],[1,3,4],[3,4,4],[4,2,4],[2,2,5.5]]
      LET a=row[0],b=row[1],c=row[2]
      RETURN a,b,c
      NEXT RETURN a,percentile_disc(distinct c,1.01) AS p GROUP BY a
      """
    Then an Error should be raised: "[NR003]: Invalid function argument: the second argument for PERCENTILE_DISC which should be between 0 and 1, in expression: percentile_disc_distinct(c,1.01)"
    When executing query:
      """
      FOR row IN [[1,1,1.1],[1,1,1.1],[1,2,1.2],[2,3,4],[4,4,4],[1,2,4],[3,2,5.5],[2,1,1.1],[2,2,1.2],[1,3,4],[3,4,4],[4,2,4],[2,2,5.5]]
      LET a=row[0],b=row[1],c=row[2]
      RETURN a,b,c
      NEXT RETURN a,percentile_cont(distinct c,-.01) AS p GROUP BY a
      """
    Then an Error should be raised: "[NR003]: Invalid function argument: the second argument for PERCENTILE_CONT which should be between 0 and 1, in expression: percentile_cont_distinct(c,-0.01)"
    When executing query:
      """
      FOR row IN [[1,1,1.1],[1,1,1.1],[1,2,1.2],[2,3,4],[4,4,4],[1,2,4],[3,2,5.5],[2,1,1.1],[2,2,1.2],[1,3,4],[3,4,4],[4,2,4],[2,2,5.5]]
      LET a=row[0],b=row[1],c=row[2]
      RETURN a,b,c
      NEXT RETURN a,percentile_cont(distinct c,b) AS p GROUP BY a
      """
    Then an Error should be raised: "[NR003]: Invalid function argument: the second argument for PERCENTILE_CONT can use only grouping columns, in expression: percentile_cont_distinct(c,CAST(b AS DOUBLE))"
    When executing query:
      """
      FOR row IN [[1,1,1.1],[1,1,1.1],[1,2,1.2],[2,3,4],[4,4,4],[1,2,4],[3,2,5.5],[2,1,1.1],[2,2,1.2],[1,3,4],[3,4,4],[4,2,4],[2,2,5.5]]
      LET a=row[0],b=row[1],c=row[2]
      RETURN a,b,c
      NEXT RETURN a,percentile_disc(c,b) AS p GROUP BY a
      """
    Then an Error should be raised: "[NR003]: Invalid function argument: the second argument for PERCENTILE_DISC can use only grouping columns, in expression: percentile_disc(c,CAST(b AS DOUBLE))"
    When executing query:
      """
      FOR i IN [9223372036854775807,10]
      RETURN SUM(i) AS a GROUP BY ()
      """
    Then an Error should be raised: "[22003]: Numeric value out of range: `10 + 9223372036854775807`, type: `INT64`, in expression: sum(i)"

  Scenario: empty aggregate with empty groupbys
    When executing query:
      """
      USE ldbc
      MATCH (v)
      WHERE false
      RETURN count(v.id) AS a
      GROUP BY ()
      """
    Then the result should be, in any order:
      | a |
      | 0 |
    When executing query:
      """
      USE ldbc
      MATCH (v)
      WHERE false
      RETURN count(DISTINCT v) AS a
      GROUP BY ()
      """
    Then the result should be, in any order:
      | a |
      | 0 |
    When executing query:
      """
      USE ldbc
      MATCH (v)
      WHERE false
      RETURN count(*) AS a
      GROUP BY ()
      """
    Then the result should be, in any order:
      | a |
      | 0 |
    When executing query:
      """
      USE ldbc
      MATCH (v)
      WHERE false
      RETURN MAX(v.id) AS a
      GROUP BY ()
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    When executing query:
      """
      USE ldbc
      MATCH (v)
      WHERE false
      RETURN MIN(v.id) AS a
      GROUP BY ()
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    When executing query:
      """
      USE ldbc
      MATCH (v)
      WHERE false
      RETURN SUM(v.id) AS a
      GROUP BY ()
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    When executing query:
      """
      USE ldbc
      MATCH (v)
      WHERE false
      RETURN avg(v.id) AS a
      GROUP BY ()
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    When executing query:
      """
      USE ldbc
      MATCH (v)
      WHERE false
      RETURN collect(v.id) AS a
      GROUP BY ()
      """
    Then the result should be, in any order:
      | a       |
      | LIST [] |
    When executing query:
      """
      USE ldbc
      MATCH (v)
      WHERE false
      RETURN STDDEV_POP(v.id) AS a
      GROUP BY ()
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    When executing query:
      """
      USE ldbc
      MATCH (v)
      LIMIT 1
      ORDER BY v.id
      RETURN STDDEV_POP(v.id) AS a
      GROUP BY ()
      """
    Then the result should be, in any order:
      | a   |
      | 0.0 |
    When executing query:
      """
      USE ldbc
      MATCH (v)
      LIMIT 1
      ORDER BY v.id
      RETURN STDDEV_POP(distinct v.id) AS a
      GROUP BY ()
      """
    Then the result should be, in any order:
      | a   |
      | 0.0 |
    When executing query:
      """
      USE ldbc
      MATCH (v)
      LIMIT 0
      ORDER BY v.id
      RETURN STDDEV_SAMP(v.id) AS a
      GROUP BY ()
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    When executing query:
      """
      USE ldbc
      MATCH (v)
      LIMIT 1
      ORDER BY v.id
      RETURN STDDEV_SAMP(v.id) AS a
      GROUP BY ()
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    When executing query:
      """
      USE ldbc
      MATCH (v)
      LIMIT 1
      ORDER BY v.id
      RETURN STDDEV_SAMP(distinct v.id) AS a
      GROUP BY ()
      """
    Then the result should be, in any order:
      | a    |
      | NULL |

  Scenario: empty aggregate with groupbys
    When executing query:
      """
      USE ldbc
      MATCH (v)
      WHERE false
      LET vid = v.id
      RETURN count(v) AS a
      GROUP BY vid
      """
    Then the result should be, in any order:
      | a |
    When executing query:
      """
      USE ldbc
      MATCH (v)
      WHERE false
      RETURN count(DISTINCT v) AS a
      GROUP BY v
      """
    Then the result should be, in any order:
      | a |
    When executing query:
      """
      USE ldbc
      MATCH (v)
      WHERE false
      RETURN MAX(v.id) AS a
      GROUP BY v
      """
    Then the result should be, in any order:
      | a |
    When executing query:
      """
      USE ldbc
      MATCH (v)
      WHERE false
      RETURN MIN(v.id) AS a
      GROUP BY v
      """
    Then the result should be, in any order:
      | a |
    When executing query:
      """
      USE ldbc
      MATCH (v)
      WHERE false
      RETURN SUM(v.id) AS a
      GROUP BY v
      """
    Then the result should be, in any order:
      | a |
    When executing query:
      """
      USE ldbc
      MATCH (v)
      WHERE false
      RETURN collect(v.id) AS a
      GROUP BY v
      """
    Then the result should be, in any order:
      | a |
    When executing query:
      """
      USE ldbc
      MATCH (v)
      WHERE false
      RETURN STDDEV_POP(v.id) AS a
      GROUP BY v
      """
    Then the result should be, in any order:
      | a |
    When executing query:
      """
      USE ldbc
      MATCH (v)
      LIMIT 1
      ORDER BY v.id
      RETURN STDDEV_POP(v.id) AS a
      GROUP BY v
      """
    Then the result should be, in any order:
      | a   |
      | 0.0 |
    When executing query:
      """
      USE ldbc
      MATCH (v)
      LIMIT 0
      ORDER BY v.id
      RETURN STDDEV_SAMP(v.id) AS a
      GROUP BY v
      """
    Then the result should be, in any order:
      | a |
    When executing query:
      """
      USE ldbc
      MATCH (v)
      LIMIT 1
      ORDER BY v.id
      RETURN STDDEV_SAMP(v.id) AS a
      GROUP BY v
      """
    Then the result should be, in any order:
      | a    |
      | NULL |

  Scenario: aggregate with empty groupbys
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      RETURN count(v.id) AS a
      GROUP BY ()
      """
    Then the result should be, in any order:
      | a |
      | 4 |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      RETURN count(DISTINCT v.gender) AS a
      GROUP BY ()
      """
    Then the result should be, in any order:
      | a |
      | 2 |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      RETURN count(*) AS a
      GROUP BY ()
      """
    Then the result should be, in any order:
      | a |
      | 4 |
    # https://github.com/vesoft-inc/nebula-ng/issues/5328
    # When executing query:
    # """
    # USE ldbc
    # MATCH (v) WHERE false
    # RETURN count(*), collect(v), SUM(v.id), avg(distinct v.id), MIN(v.id), MAX(v.id), STDDEV_POP(v.id), STDDEV_SAMP(v.nonexist) AS x
    # GROUP BY ()
    # """
    # Then the result should be, in any order:
    # | count(*) | collect(v) | SUM(v.id) | avg(distinct v.id) | MIN(v.id) | MAX(v.id) | STDDEV_POP(v.id) | x    |
    # | 0        | LIST[]     | NULL      | NULL               | NULL      | NULL      | NULL             | NULL |
    When executing query:
      """
      USE ldbc
      MATCH (v)->(n) WHERE false
      RETURN n.id AS nid, count(*), collect(v), SUM(v.id), avg(distinct v.id), MIN(v.id), MAX(v.id), STDDEV_POP(v.id), STDDEV_SAMP(v.id)
      GROUP BY nid
      """
    Then the result should be, in any order:
      | nid | count(*) | collect(v) | SUM(v.id) | avg(distinct v.id) | MIN(v.id) | MAX(v.id) | STDDEV_POP(v.id) | STDDEV_SAMP(v.id) |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      RETURN MAX(v.id) AS a
      GROUP BY ()
      """
    Then the result should be, in any order:
      | a |
      | 4 |
    When executing query:
      """
      USE ldbc
      MATCH (v:Comment)
      RETURN avg(v.extent/10) AS a, sum(v.extent/10.0)/4 AS s
      GROUP BY ()
      """
    Then the result should be, in any order:
      | a   | s    |
      | 0.0 | 0.8M |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      RETURN MIN(v.id) AS a
      GROUP BY ()
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      RETURN SUM(v.id) AS a
      GROUP BY ()
      """
    Then the result should be, in any order:
      | a  |
      | 10 |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      RETURN avg(v.id) AS a
      GROUP BY ()
      """
    Then the result should be, in any order:
      | a   |
      | 2.5 |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      ORDER BY v.id
      RETURN collect(v.id) AS a
      GROUP BY ()
      """
    Then the result should be, in any order:
      | a              |
      | LIST [1,2,3,4] |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      RETURN STDDEV_POP(v.id) >= 1.1180339887498900 AND STDDEV_POP(v.id) <= 1.1180339887498999 AS a
      GROUP BY ()
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      RETURN STDDEV_SAMP(v.id) >= 1.2909944487358000 AND STDDEV_SAMP(v.id) <= 1.2909944487358099 AS a
      GROUP BY ()
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      USE ldbc
      MATCH (v{id:3})
      RETURN count(v.id) AS a
      GROUP BY ()
      """
    Then the result should be, in any order:
      | a |
      | 8 |
    When executing query:
      """
      USE ldbc
      MATCH (v{id:3})
      RETURN count(distinct v.id) AS a
      GROUP BY ()
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person{id:3})
      RETURN count(distinct v.id)+1 AS a
      GROUP BY ()
      """
    Then the result should be, in any order:
      | a |
      | 2 |
    When executing query:
      """
      USE ldbc
      MATCH (v{id:3})
      RETURN count(v.id) AS a, count(distinct v.id) AS b
      GROUP BY ()
      """
    Then the result should be, in any order:
      | a | b |
      | 8 | 1 |
    When executing query:
      """
      USE ldbc
      MATCH (v{id:3})
      RETURN count(distinct v.id) AS a, count(v.id) AS b
      GROUP BY ()
      """
    Then the result should be, in any order:
      | a | b |
      | 1 | 8 |

  Scenario: CountConstant
    When executing query:
      """
      RETURN count(1) GROUP BY ()
      """
    Then the result should be, in any order:
      | count(1) |
      | 1        |
    When executing query:
      """
      RETURN count("1") GROUP BY ()
      """
    Then the result should be, in any order:
      | count("1") |
      | 1          |
    When executing query:
      """
      RETURN count(*) GROUP BY ()
      """
    Then the result should be, in any order:
      | count(*) |
      | 1        |
    When executing query:
      """
      RETURN cOuNt("*") GROUP BY ()
      """
    Then the result should be, in any order:
      | cOuNt("*") |
      | 1          |
    When executing query:
      """
      RETURN count(1+2) GROUP BY ()
      """
    Then the result should be, in any order:
      | count(1+2) |
      | 1          |
    When executing query:
      """
      RETURN count("1+2") GROUP BY ()
      """
    Then the result should be, in any order:
      | count("1+2") |
      | 1            |

  Scenario: Null
    When executing query:
      """
      use ldbc let rec = RECORD{name:null} return rec.name as name, count(*) group by name
      """
    Then the result should be, in any order:
      | name | count(*) |
      | NULL | 1        |

  Scenario: Optimize COUNT path for specified pattern
    # optimized plan: Project -> Aggregate(p=>element_id(v)) -> NodesScan(v)
    When executing query:
      """
      USE ldbc
      MATCH p=(v)
      RETURN count(p) AS res1, count(distinct p)+1 AS res2, count(distinct v)+count(p) AS res3
      """
    Then the result should be, in any order:
      | res1 | res2 | res3 |
      | 34   | 35   | 68   |
    # optimized plan: Project -> Aggregate(p=>element_id(v)) -> NodesScan(v)
    When executing query:
      """
      USE ldbc
      MATCH p=(v)
      RETURN count(p) + count(distinct p)+1 +count(distinct v)+count(p) AS res
      """
    Then the result should be, in any order:
      | res |
      | 137 |
    # optimized plan: Project -> Aggregate(p=>e) -> EdgesScan(e)
    When executing query:
      """
      USE ldbc
      MATCH p=(v)-[e]->()
      RETURN count(p) AS res1, count(distinct p)+1 AS res2, count(distinct p)+count(p) AS res3
      """
    Then the result should be, in any order:
      | res1 | res2 | res3 |
      | 74   | 75   | 148  |
    When executing query:
      """
      USE ldbc
      MATCH p=(v)-[e]->{1}()
      RETURN count(p) AS res1, count(distinct p)+1 AS res2, count(distinct p)+count(p) AS res3
      """
    Then the result should be, in any order:
      | res1 | res2 | res3 |
      | 74   | 75   | 148  |
    # optimized plan: Project -> Aggregate(p=>e) -> EdgesScan(e)
    When executing query:
      """
      USE ldbc
      MATCH p=(v)-[e]->()
      RETURN count(p) + count(distinct p)+1 + count(distinct p)+count(p) AS res
      """
    Then the result should be, in any order:
      | res |
      | 297 |
    When executing query:
      """
      USE ldbc
      MATCH p=(v)-[e]->{1}()
      RETURN count(p) + count(distinct p)+1 + count(distinct p)+count(p) AS res
      """
    Then the result should be, in any order:
      | res |
      | 297 |
    When executing query:
      """
      USE ldbc
      MATCH p=(v)-[e]-()
      RETURN count(p) + 1 AS res
      """
    Then the result should be, in any order:
      | res |
      | 149 |
    When executing query:
      """
      USE ldbc
      MATCH p=(v)-[e]-{1}()
      RETURN count(p) + 1 AS res
      """
    Then the result should be, in any order:
      | res |
      | 149 |
    When executing query:
      """
      USE ldbc
      MATCH p=(v)-[e]-()
      RETURN count(distinct p) + 1 AS res
      """
    Then the result should be, in any order:
      | res |
      | 140 |
    When executing query:
      """
      USE ldbc
      MATCH p=(v)-[e]-{1}()
      RETURN count(distinct p) + 1 AS res
      """
    Then the result should be, in any order:
      | res |
      | 140 |
    When executing query:
      """
      USE ldbc
      MATCH p=(v)-[e]->{1,3}()
      RETURN count( p) + 1 AS res
      """
    Then the result should be, in any order:
      | res  |
      | 1177 |
    When executing query:
      """
      USE ldbc
      MATCH p=(v)-[e]-{1,3}()
      RETURN count( p) + 1 AS res
      """
    Then the result should be, in any order:
      | res   |
      | 10905 |
    When executing query:
      """
      USE ldbc
      MATCH p=(v)-[e]-{1,3}()->(:Person)
      RETURN count( p) + 1 AS res
      """
    Then the result should be, in any order:
      | res   |
      | 14597 |
    When executing query:
      """
      USE ldbc
      MATCH p=(v)-[e]-()->(:Person)
      RETURN count( p) + 1 AS res
      """
    Then the result should be, in any order:
      | res |
      | 185 |
    When executing query:
      """
      USE ldbc
      MATCH p=(v)-[e]-()->(:Person)
      RETURN count(distinct p) + 1 AS res
      """
    Then the result should be, in any order:
      | res |
      | 174 |
    When executing query:
      """
      USE ldbc
      MATCH p=(v)-[e]->()->(:Person)
      RETURN count( p) + 1 AS res
      """
    Then the result should be, in any order:
      | res |
      | 67  |
    When executing query:
      """
      USE ldbc
      MATCH p=(v)-[e]-()-(:Person)
      RETURN count( p) + 1 AS res
      """
    Then the result should be, in any order:
      | res |
      | 379 |
    When executing query:
      """
      USE ldbc
      MATCH p=(v)-[e]-()-(:Person)
      RETURN count(distinct p) + 1 AS res
      """
    Then the result should be, in any order:
      | res |
      | 316 |
    When executing query:
      """
      USE ldbc
      MATCH p=(v)-[e]-{1}()-(:Person)
      RETURN count( p) + 1 AS res
      """
    Then the result should be, in any order:
      | res |
      | 379 |
    When executing query:
      """
      USE ldbc
      MATCH p=(v)-[e]-()-{1}(:Person)
      RETURN count(distinct p) + 1 AS res
      """
    Then the result should be, in any order:
      | res |
      | 316 |
    When executing query:
      """
      USE ldbc
      MATCH p=(v)-[e]-{1}()-{1}(:Person)
      RETURN count(distinct p) + 1 AS res
      """
    Then the result should be, in any order:
      | res |
      | 316 |
    When executing query:
      """
      USE ldbc
      MATCH p=(v)-[e]-{1}()-{1}(:Person)
      RETURN count(distinct p) + 1 AS res
      """
    Then the result should be, in any order:
      | res |
      | 316 |
    # bidirectional pattern cases cannot be optimized
    When executing query:
      """
      USE ldbc
      MATCH p=(v)-[e]-()
      RETURN count(p) + count(distinct p)+1 + count(distinct p)+count(p) AS res
      """
    Then the result should be, in any order:
      | res |
      | 575 |
    # single-node & single-edge paths
    When executing query:
      """
      USE ldbc
      MATCH p1=(v) OPTIONAL MATCH p2=(v)-[e]->()
      RETURN count(p1) AS res1, count(distinct p1)+1 AS res2, count(distinct e) AS res3, count(p2) AS res4
      """
    Then the result should be, in any order:
      | res1 | res2 | res3 | res4 |
      | 84   | 35   | 74   | 74   |
    # single-node & single-edge paths
    When executing query:
      """
      USE ldbc
      MATCH p1=(v) OPTIONAL MATCH p2=(v)-[e]->()
      RETURN count(p1) + count(distinct p1)+1 + count(distinct e)+count(p2) AS res
      """
    Then the result should be, in any order:
      | res |
      | 267 |
    # more complex cases: multiple return statements with variable renaming and path variables with same name
    When executing query:
      """
      USE ldbc MATCH p1=(v) OPTIONAL MATCH p2=(v)-[e]->() OPTIONAL MATCH p3=(v:Person)<-[e2]-()
      RETURN count(p1)+1 AS res1,                -- equal to count(v)+1, since p1 is a single-node path
             abs(count(distinct p2)+2) AS res2,  -- equal to abs(count(distinct e)+2), since p2 is a single-edge path
             count(p3) +3 AS res3,               -- equal to count(e2) +3, since p3 is a single-edge path
             v AS v1,v, p1 AS p3                 -- alias some groupby variables for next query to check the edge cases
      NEXT USE ldbc MATCH pp2=(v1) OPTIONAL MATCH pp1=(v2)<-[e]-() MATCH pp4=(v1)-[e2]->(:Person)
      RETURN res1, abs(res2+res3) AS res2,       -- check the pass-through results
             count(distinct pp1)+3 AS res3,      -- equal to count(distinct e)+3, since pp1 is a single-edge path
             abs(count(distinct pp2))+4 AS res4, -- equal to abs(count(distinct v1))+4, since pp2 is a single-node path
             count(p3)+5 AS res5,                -- p3 is from previous return statement
             count(distinct pp4)+6 AS res6       -- equal to count(distinct e2)+6, since pp4 is a single-edge path
      """
    Then the result should be, in any order:
      | res1 | res2 | res3 | res4 | res5 | res6 |
      | 55   | 68   | 77   | 5    | 227  | 9    |
      | 6    | 10   | 77   | 7    | 227  | 9    |
      | 5    | 9    | 77   | 7    | 449  | 12   |
      | 4    | 8    | 77   | 7    | 227  | 9    |
      | 49   | 61   | 77   | 5    | 153  | 8    |
      | 64   | 77   | 77   | 5    | 227  | 9    |
    When executing query:
      """
      USE ldbc MATCH p1=(v) OPTIONAL MATCH p2=(v)-[e]->() OPTIONAL MATCH p3=(v:Person)<-[e2]-()
      RETURN count(p1)+1 AS res1,                -- equal to count(v)+1, since p1 is a single-node path
             abs(count(distinct p2)+2) AS res2,  -- equal to abs(count(distinct e)+2), since p2 is a single-edge path
             count(p3) +3 AS res3,               -- equal to count(e2) +3, since p3 is a single-edge path
             v AS v1,v, p1 AS p3                 -- alias some groupby variables for next query to check the edge cases
      NEXT USE ldbc MATCH p2=(v1) OPTIONAL MATCH p1=(v2)<-[e]-() MATCH p4=(v1)-[e2]->(:Person)
      RETURN res1, abs(res2+res3) AS res2,       -- check the pass-through results
             count(distinct p1)+3 AS res3,       -- redeclared p1
             abs(count(distinct p2))+4 AS res4,  -- redeclared p2
             count(p3)+5 AS res5,                -- p3 is from previous return statement
             count(distinct p4)+6 AS res6        -- equal to count(distinct e2)+6, since p4 is a new declared single-edge path variable
      """
    Then the result should be, in any order:
      | res1 | res2 | res3 | res4 | res5 | res6 |
      | 55   | 68   | 77   | 5    | 227  | 9    |
      | 6    | 10   | 77   | 7    | 227  | 9    |
      | 5    | 9    | 77   | 7    | 449  | 12   |
      | 4    | 8    | 77   | 7    | 227  | 9    |
      | 49   | 61   | 77   | 5    | 153  | 8    |
      | 64   | 77   | 77   | 5    | 227  | 9    |
    When executing query:
      """
      USE ldbc MATCH p1=(v) OPTIONAL MATCH p2=(v)-[e]->() OPTIONAL MATCH p3=(v:Person)<-[e2]->()
      RETURN count(p1)+1 AS res1,                -- equal to count(v)+1, since p1 is a single-node path
             abs(count(distinct p2)+2) AS res2,  -- equal to abs(count(distinct e)+2), since p2 is a single-edge path
             count(p3) +3 AS res3,               -- not equal to count(e2), since p3 is bidirectional path
             v AS v1,v, p1 AS p3                 -- alias some groupby variables for next query to check the edge cases
      NEXT USE ldbc MATCH pp2=(v1) OPTIONAL MATCH pp1=(v2)<-[e]-() MATCH pp4=(v1)-[e2]-(:Person)
      RETURN res1, abs(res2+res3) AS res2,       -- check the pass-through results
             count(distinct pp1)+3 AS res3,      -- equal to count(distinct e)+3, since pp1 is a single-edge path
             abs(count(distinct pp2))+4 AS res4, -- equal to abs(count(distinct v1))+4, since pp2 is a single-node path
             count(p3)+5 AS res5,                -- p3 is from previous return statement
             count(distinct pp4)+6 AS res6       -- not equal to count(distinct e2)+6, since pp4 is a bidirectional path
      """
    Then the result should be, in any order:
      | res1 | res2 | res3 | res4 | res5 | res6 |
      | 145  | 158  | 77   | 5    | 449  | 11   |
      | 2    | 6    | 77   | 14   | 967  | 19   |
      | 136  | 149  | 77   | 5    | 375  | 10   |
      | 113  | 125  | 77   | 5    | 301  | 9    |
      | 4    | 8    | 77   | 7    | 449  | 12   |
      | 6    | 10   | 77   | 7    | 449  | 12   |
      | 5    | 9    | 77   | 7    | 449  | 12   |
    When executing query:
      """
      USE ldbc MATCH p1=(v) OPTIONAL MATCH p2=(v)-[e]->() OPTIONAL MATCH p3=(v:Person)<-[e2]->()
      RETURN count(p1)+1 AS res1,                -- equal to count(v)+1, since p1 is a single-node path
             abs(count(distinct p2)+2) AS res2,  -- equal to abs(count(distinct e)+2), since p2 is a single-edge path
             count(p3) +3 AS res3,               -- not equal to count(e2), since p3 is bidirectional path
             v AS v1,v, p1 AS p3                 -- alias some groupby variables for next query to check the edge cases
      NEXT USE ldbc MATCH p2=(v1) OPTIONAL MATCH p1=(v2)<-[e]-() MATCH p4=(v1)-[e2]-(:Person)
      RETURN res1, abs(res2+res3) AS res2,       -- check the pass-through results
             count(distinct p1)+3 AS res3,       -- redeclared p1
             abs(count(distinct p2))+4 AS res4,  -- redeclared p2
             count(p3)+5 AS res5,                -- p3 is from previous return statement
             count(distinct p4)+6 AS res6        -- not equal to count(distinct e2)+6, since p4 is a bidirectional path
      """
    Then the result should be, in any order:
      | res1 | res2 | res3 | res4 | res5 | res6 |
      | 145  | 158  | 77   | 5    | 449  | 11   |
      | 2    | 6    | 77   | 14   | 967  | 19   |
      | 136  | 149  | 77   | 5    | 375  | 10   |
      | 113  | 125  | 77   | 5    | 301  | 9    |
      | 4    | 8    | 77   | 7    | 449  | 12   |
      | 6    | 10   | 77   | 7    | 449  | 12   |
      | 5    | 9    | 77   | 7    | 449  | 12   |
    When executing query:
      """
      USE ldbc MATCH p1=(v) OPTIONAL MATCH p2=(v)-[e]->() OPTIONAL MATCH p3=(v:Person)-[e2]->{1,2}()
      RETURN count(p1)+1 AS res1,                -- equal to count(v)+1, since p1 is a single-node path
             abs(count(distinct p2)+2) AS res2,  -- equal to abs(count(distinct e)+2), since p2 is a single-edge path
             count(p3) +3 AS res3,               -- not equal to count(e2), since p3 is quantified path
             v AS v1,v, p1 AS p3                 -- alias some groupby variables for next query to check the edge cases
      NEXT USE ldbc MATCH pp2=(v1) OPTIONAL MATCH pp1=(v2)<-[e]-() MATCH pp4=(v1)~[e2]~>(:Person)
      RETURN res1, abs(res2+res3) AS res2,       -- check the pass-through results
             count(distinct pp1)+3 AS res3,      -- equal to count(distinct e)+3, since pp1 is a single-edge path
             abs(count(distinct pp2))+4 AS res4, -- equal to abs(count(distinct v1))+4, since pp2 is a single-node path
             count(p3)+5 AS res5,                -- p3 is from previous return statement
             count(distinct pp4)+6 AS res6       -- not equal to count(distinct e2)+6, since pp4 is a hybrid path
      """
    Then the result should be, in any order:
      | res1 | res2 | res3 | res4 | res5 | res6 |
      | 424  | 437  | 77   | 5    | 227  | 9    |
      | 297  | 309  | 77   | 5    | 153  | 8    |
      | 6    | 10   | 77   | 7    | 227  | 9    |
      | 5    | 9    | 77   | 7    | 449  | 12   |
      | 4    | 8    | 77   | 7    | 227  | 9    |
      | 352  | 365  | 77   | 5    | 227  | 9    |
    When executing query:
      """
      USE ldbc MATCH p1=(v) OPTIONAL MATCH p2=(v)-[e]->() OPTIONAL MATCH p3=(v:Person)-[e2]->{1,2}()
      RETURN count(p1)+1 AS res1,                -- equal to count(v)+1, since p1 is a single-node path
             abs(count(distinct p2)+2) AS res2,  -- equal to abs(count(distinct e)+2), since p2 is a single-edge path
             count(p3) +3 AS res3,               -- not equal to count(e2), since p3 is quantified path
             v AS v1,v, p1 AS p3                 -- alias some groupby variables for next query to check the edge cases
      NEXT USE ldbc MATCH pp2=(v1) OPTIONAL MATCH pp1=(v2)<-[e]-() MATCH pp4=(v1)~[e2]~>(:Person)
      RETURN res1, abs(res2+res3) AS res2,       -- check the pass-through results
             count(distinct pp1)+3 AS res3,      -- equal to count(distinct e)+3, since pp1 is a single-edge path
             abs(count(distinct pp2))+4 AS res4, -- equal to abs(count(distinct v1))+4, since pp2 is a single-node path
             count(distinct pp4)+6 AS res6       -- not equal to count(distinct e2)+6, since pp4 is a hybrid path
      """
    Then the result should be, in any order:
      | res1 | res2 | res3 | res4 | res6 |
      | 352  | 365  | 77   | 5    | 9    |
      | 424  | 437  | 77   | 5    | 9    |
      | 6    | 10   | 77   | 7    | 9    |
      | 5    | 9    | 77   | 7    | 12   |
      | 4    | 8    | 77   | 7    | 9    |
      | 297  | 309  | 77   | 5    | 8    |
    When executing query:
      """
      USE ldbc MATCH p1=(v) OPTIONAL MATCH p2=(v)-[e]-() OPTIONAL MATCH p3=(v:Person)-[e2]->{1,3}()
      RETURN count(p1)+1 AS res1,                -- equal to count(v)+1, since p1 is a single-node path
             abs(count(p2)+2) AS res2,           -- equal to abs(count(distinct e)+2), since p2 is a single-edge path
             count(p3) +3 AS res3,               -- not equal to count(e2), since p3 is quantified path
             v AS v1,v, p1 AS p3                 -- alias some groupby variables for next query to check the edge cases
      NEXT USE ldbc MATCH pp2=(v1) OPTIONAL MATCH pp1=(v2)-[e]-() MATCH pp4=(v1)~[e2]~>(:Person)
      RETURN res1, abs(res2+res3) AS res2,       -- check the pass-through results
             count(distinct pp1)+3 AS res3,      -- equal to count(distinct e)+3, since pp1 is a single-edge path
             abs(count(distinct pp2))+4 AS res4, -- equal to abs(count(distinct v1))+4, since pp2 is a single-node path
             count(distinct pp4)+6 AS res6       -- not equal to count(distinct e2)+6, since pp4 is a hybrid path
      """
    Then the result should be, in any order:
      | res1 | res2 | res3 | res4 | res6 |
      | 2241 | 4485 | 142  | 5    | 9    |
      | 2656 | 5315 | 142  | 5    | 9    |
      | 1779 | 3561 | 142  | 5    | 8    |
      | 8    | 12   | 142  | 7    | 9    |
      | 7    | 11   | 142  | 7    | 9    |
      | 5    | 9    | 142  | 7    | 12   |
