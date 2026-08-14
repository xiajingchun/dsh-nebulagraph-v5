# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: GetProp Function

  Scenario: Record
    When executing query:
      """
      RETURN RECORD {id: 1}.id
      """
    Then the result should be, in any order:
      | RECORD {id: 1}.id |
      | 1                 |
    When executing query:
      """
      LET r = RECORD {a: RECORD {b: 3}}
      RETURN r.a
      """
    Then the result should be, in any order:
      | r.a    |
      | {b: 3} |
    When executing query:
      """
      LET r = RECORD {a: RECORD {b: 3}}
      RETURN r.a.b
      """
    Then the result should be, in any order:
      | r.a.b |
      | 3     |
    When executing query:
      """
      RETURN RECORD {a: RECORD {b: 3}}.a.b
      """
    Then the result should be, in any order:
      | RECORD {a: RECORD {b: 3}}.a.b |
      | 3                             |
    When executing query:
      """
      USE ldbc
      MATCH TRAIL (v0:Person{id:1})-[e:FOLLOWS]->{1,10}(v1:Person{id:4})
      RETURN {k1:v0, k2:e, k3:v1} AS r
      NEXT USE ldbc
      RETURN r.k1.id AS id1, size(r.k2) AS steps, r.k3.id AS id2
      """
    Then the result should be, in any order:
      | id1 | steps | id2 |
      | 1   | 2     | 4   |
      | 1   | 4     | 4   |
    When executing query:
      """
      RETURN RECORD {year: RECORD {month: 3}}.year.month AS a
      """
    Then the result should be, in any order:
      | a |
      | 3 |
    When executing query:
      """
      RETURN DATETIME "2012-03-04T05:06:07.0890" as a next return a.year AS a,a.month AS b,a.day AS c,a.hour AS d,a.minute AS e,a.second AS f
      """
    Then the result should be, in any order:
      | a    | b | c | d | e | f |
      | 2012 | 3 | 4 | 5 | 6 | 7 |
