# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: TypeOf

  Scenario: basic
    When executing query:
      """
      RETURN typeof(1) as t
      """
    Then the result should be, in any order:
      | t       |
      | "INT32" |
    When executing query:
      """
      RETURN typeof(1.0) as t
      """
    Then the result should be, in any order:
      | t         |
      | "DECIMAL" |
    When executing query:
      """
      RETURN typeof(true) as t
      """
    Then the result should be, in any order:
      | t      |
      | "BOOL" |
    When executing query:
      """
      RETURN typeof(CAST(1 AS INT8)) as t
      """
    Then the result should be, in any order:
      | t      |
      | "INT8" |
    When executing query:
      """
      RETURN typeof(CAST(1 AS INT16)) as t
      """
    Then the result should be, in any order:
      | t       |
      | "INT16" |
    When executing query:
      """
      RETURN typeof(CAST(1 AS INT32)) as t
      """
    Then the result should be, in any order:
      | t       |
      | "INT32" |
    When executing query:
      """
      RETURN typeof(CAST(1 AS INT64)) as t
      """
    Then the result should be, in any order:
      | t       |
      | "INT64" |
    When executing query:
      """
      RETURN typeof(CAST(1 AS UINT8)) as t
      """
    Then the result should be, in any order:
      | t       |
      | "UINT8" |
    When executing query:
      """
      RETURN typeof(CAST(1 AS UINT16)) as t
      """
    Then the result should be, in any order:
      | t        |
      | "UINT16" |
    When executing query:
      """
      RETURN typeof(CAST(1 AS UINT32)) as t
      """
    Then the result should be, in any order:
      | t        |
      | "UINT32" |
    When executing query:
      """
      RETURN typeof(CAST(1 AS UINT64)) as t
      """
    Then the result should be, in any order:
      | t        |
      | "UINT64" |
    When executing query:
      """
      RETURN typeof(CAST(1.0 AS FLOAT)) as t
      """
    Then the result should be, in any order:
      | t       |
      | "FLOAT" |
    When executing query:
      """
      RETURN typeof(CAST(1.0 AS DOUBLE)) as t
      """
    Then the result should be, in any order:
      | t        |
      | "DOUBLE" |
    When executing query:
      """
      RETURN typeof('abc') as t
      """
    Then the result should be, in any order:
      | t        |
      | "STRING" |
    When executing query:
      """
      RETURN typeof(NULL) as t
      """
    Then the result should be, in any order:
      | t      |
      | "NULL" |
    When executing query:
      """
      USE ldbc
      MATCH (v)
      RETURN typeof(v) as t limit 3
      """
    Then the result should be, in any order:
      | t                                                                                        |
      | "NODE<(Comment), (Forum), (Organisation), (Person), (Place), (Post), (Tag), (TagClass)>" |
      | "NODE<(Comment), (Forum), (Organisation), (Person), (Place), (Post), (Tag), (TagClass)>" |
      | "NODE<(Comment), (Forum), (Organisation), (Person), (Place), (Post), (Tag), (TagClass)>" |
    When executing query:
      """
      USE ldbc
      RETURN typeof(LIST[1]) as t limit 3
      """
    Then the result should be, in any order:
      | t             |
      | "LIST<INT32>" |
    When executing query:
      """
      USE ldbc
      MATCH (v@Person)-[e]->(@Person)
      RETURN typeof(e) as t limit 3
      """
    Then the result should be, in any order:
      | t                                                                |
      | "EDGE<(Person)-[FOLLOWS]->(Person), (Person)-[KNOWS]->(Person)>" |
      | "EDGE<(Person)-[FOLLOWS]->(Person), (Person)-[KNOWS]->(Person)>" |
      | "EDGE<(Person)-[FOLLOWS]->(Person), (Person)-[KNOWS]->(Person)>" |
    When executing query:
      """
      USE ldbc
      MATCH p = (v@Person)-[e]->(@Person)
      RETURN typeof(p) as t limit 3
      """
    Then the result should be, in any order:
      | t      |
      | "PATH" |
      | "PATH" |
      | "PATH" |
    When executing query:
      """
      LET a = RECORD{a:1, b:"1"}
      RETURN typeof(a) AS t
      """
    Then the result should be, in any order:
      | t                           |
      | "RECORD{a INT32, b STRING}" |
    When executing query:
      """
      LET a = local_datetime('2025-07-26T01:00:00.000')
      RETURN typeof(a) AS t
      """
    Then the result should be, in any order:
      | t               |
      | "LOCALDATETIME" |
    When executing query:
      """
      LET a = zoned_datetime("2011-03-04T11:06:08Z", "%Y-%m-%dT%H:%M:%S%z")
      RETURN typeof(a) AS t
      """
    Then the result should be, in any order:
      | t               |
      | "ZONEDDATETIME" |
    When executing query:
      """
      let a = VECTOR<3,float>([1.1,2.1,3.1])
      RETURN typeof(a) AS t
      """
    Then the result should be, in any order:
      | t                  |
      | "VECTOR<3, FLOAT>" |
    When executing query:
      """
      let a = MAP{1.1:"1.1", 2.6:"2.2"}
      RETURN typeof(a) AS t
      """
    Then the result should be, in any order:
      | t                      |
      | "MAP<DECIMAL, STRING>" |
    When executing query:
      """
      let a = SET{"1.1"}
      RETURN typeof(a) AS t
      """
    Then the result should be, in any order:
      | t             |
      | "SET<STRING>" |
    When executing query:
      """
      let a = CAST('POINT(0 1)' as GEOGRAPHY)
      RETURN typeof(a) AS t
      """
    Then the result should be, in any order:
      | t                |
      | "GEOGRAPHY(Any)" |
    When executing query:
      """
      USE ldbc
      OPTIONAL MATCH (v)
      WHERE FALSE
      RETURN typeof(v) AS t
      """
    Then the result should be, in any order:
      | t                                                                                        |
      | "NODE<(Comment), (Forum), (Organisation), (Person), (Place), (Post), (Tag), (TagClass)>" |
