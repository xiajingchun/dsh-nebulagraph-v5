# Copyright (c) 2022 vesoft inc. All rights reserved.
Feature: Let

  Scenario: LetStatement
    When executing query:
      """
      LET a = 1
      LET b = a + 1
      RETURN a, b
      """
    Then the result should be, in any order:
      | a | b |
      | 1 | 2 |
    When executing query:
      """
      LET a = 1, b = a + 1
      RETURN a, b
      """
    Then the result should be, in any order:
      | a | b |
      | 1 | 2 |
    When executing query:
      """
      LET a = 1
      LET b = a + 1, c = VALUE { RETURN a + b LIMIT 1 }
      RETURN a, b, c
      """
    Then the result should be, in any order:
      | a | b | c |
      | 1 | 2 | 3 |
    When executing query:
      """
      LET sum_and_count = reduce([1, 2, 3, 4],
                    {sum: 0.0, count: 0},
                    (state, item) -> {sum: state.sum + item, count: state.count + 1}),
          avg = CASE WHEN sum_and_count.count = 0 THEN NULL ELSE sum_and_count.sum / sum_and_count.count END
      RETURN avg
      """
    Then the result should be, in any order:
      | avg  |
      | 2.5M |
    When executing query:
      """
      LET a = 1
      LET b = a + 1, c = VALUE { USE ldbc MATCH (v:Person WHERE v.id > a + b) RETURN v.id LIMIT 1 } + 100
      RETURN a, b, c
      """
    Then the result should be, in any order:
      | a | b | c   |
      | 1 | 2 | 104 |
    When executing query:
      """
      USE ldbc
      MATCH (v)-[e:KNOWS]->(v2:Person)
      LET id = v2.id, name = v2.firstName
      RETURN v, e, v2, id, name
      """
    Then the result should be, in any order:
      | v                                                                                                                                                                                                                | e                                                                                  | v2                                                                                                                                                                                                              | id | name   |
      | ({birthday: DATE "1990-01-01", browserUsed:"Chrome",creationDate: DATETIME "2021-01-01T10:00:40.213000",firstName:"Kyle",gender:"male",id:1,lastName:"cao",locationIP:"192.168.1", vec:VECTOR [1.0, 2.0, 3.0]})  | [{creationDate:DATETIME "2021-01-01T10:00:40.213000", vec:VECTOR [1.0, 2.0, 3.0]}] | ({birthday: DATE "1990-01-01", browserUsed:"Chrome",creationDate: DATETIME "2021-01-01T10:00:40.213000",firstName:"Kyle",gender:"male",id:1,lastName:"cao",locationIP:"192.168.1",vec:VECTOR [1.0, 2.0, 3.0]})  | 1  | "Kyle" |
      | ({birthday: DATE "2001-04-25", browserUsed:"IE",creationDate: DATETIME "2021-01-01T11:00:40.213000",firstName:"Tim",gender:"male",id:2,lastName:"Duncan",locationIP:"192.168.2", vec:VECTOR [4.0, 5.0, 6.0]})    | [{creationDate:DATETIME "2021-01-01T10:00:40.213000", vec:VECTOR [4.0, 5.0, 6.0]}] | ({birthday: DATE "2001-04-25", browserUsed:"IE",creationDate: DATETIME "2021-01-01T11:00:40.213000",firstName:"Tim",gender:"male",id:2,lastName:"Duncan",locationIP:"192.168.2",vec:VECTOR [4.0, 5.0, 6.0]})    | 2  | "Tim"  |
      | ({birthday: DATE "1995-06-12", browserUsed:"Firefox",creationDate: DATETIME "2021-01-01T12:00:40.213000",firstName:"Ming",gender:"male",id:3,lastName:"Yao",locationIP:"192.168.3", vec:VECTOR [7.0, 8.0, 9.0]}) | [{creationDate:DATETIME "2021-01-01T10:00:40.213000", vec:VECTOR [7.0, 8.0, 9.0]}] | ({birthday: DATE "1995-06-12", browserUsed:"Firefox",creationDate: DATETIME "2021-01-01T12:00:40.213000",firstName:"Ming",gender:"male",id:3,lastName:"Yao",locationIP:"192.168.3",vec:VECTOR [7.0, 8.0, 9.0]}) | 3  | "Ming" |
    When executing query:
      """
      USE ldbc
      MATCH (vv)-[e:KNOWS]->(v2:Person)
      LET id = v2.id, name = v2.firstName, v = v2.lastName
      RETURN v, e, v2, id, name
      """
    Then the result should be, in any order:
      | v        | e                                                                                  | v2                                                                                                                                                                                                              | id | name   |
      | "cao"    | [{creationDate:DATETIME "2021-01-01T10:00:40.213000", vec:VECTOR [1.0, 2.0, 3.0]}] | ({birthday: DATE "1990-01-01", browserUsed:"Chrome",creationDate: DATETIME "2021-01-01T10:00:40.213000",firstName:"Kyle",gender:"male",id:1,lastName:"cao",locationIP:"192.168.1", vec:VECTOR [1.0, 2.0, 3.0]}) | 1  | "Kyle" |
      | "Duncan" | [{creationDate:DATETIME "2021-01-01T10:00:40.213000", vec:VECTOR [4.0, 5.0, 6.0]}] | ({birthday: DATE "2001-04-25", browserUsed:"IE",creationDate: DATETIME "2021-01-01T11:00:40.213000",firstName:"Tim",gender:"male",id:2,lastName:"Duncan",locationIP:"192.168.2", vec:VECTOR [4.0, 5.0, 6.0]})   | 2  | "Tim"  |
      | "Yao"    | [{creationDate:DATETIME "2021-01-01T10:00:40.213000", vec:VECTOR [7.0, 8.0, 9.0]}] | ({birthday: DATE "1995-06-12", browserUsed:"Firefox",creationDate: DATETIME "2021-01-01T12:00:40.213000",firstName:"Ming",gender:"male",id:3,lastName:"Yao",locationIP:"192.168.3", vec:VECTOR [7.0, 8.0,9.0]}) | 3  | "Ming" |

  # Fix https://github.com/vesoft-inc/nebula-ng/issues/2499  # Fix https://github.com/vesoft-inc/nebula-ng/issues/2499
  Scenario: LetStatementWithValueQuery
    When executing query:
      """
      LET x = VALUE{USE ldbc MATCH (v:Person) RETURN v ORDER BY v.id LIMIT 1} RETURN x
      """
    Then the result should be, in any order:
      | x                                                                                                                                                                                                   |
      | ({lastName:"cao",firstName:"Kyle",browserUsed:"Chrome",gender:"male",birthday:DATE "1990-01-01",id:1,creationDate:DATETIME "2021-01-01T10:00:40.213000",locationIP:"192.168.1",vec:VECTOR [1,2,3]}) |

  # FIX: https://github.com/vesoft-inc/nebula-ng/issues/9259
  Scenario: Anon var prefix
    When executing query:
      """
      LET `@a` = 2 RETURN `@a`
      """
    Then an Error should be raised: "[42001]: identifier cannot start with: @ near ``@a``"
