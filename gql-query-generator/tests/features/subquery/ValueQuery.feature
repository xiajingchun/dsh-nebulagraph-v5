# Copyright (c) 2022 vesoft inc. All rights reserved.
Feature: ValueQueryExprTest

  Scenario: basic
    When executing query:
      """
      USE ldbc
      MATCH (m)-[:IS_PART_OF]->(p)
      RETURN VALUE { USE ldbc MATCH (m)-[:IS_PART_OF]->(p)
      RETURN count(*) AS cnt GROUP BY () } AS cnt, m.id AS mid,p.id AS pid
      """
    Then the result should be, in any order:
      | cnt | mid | pid |
      | 1   | 1   | 4   |
      | 1   | 2   | 5   |
      | 1   | 3   | 6   |
    When executing query:
      """
      RETURN VALUE { RETURN 1 AS a NEXT RETURN a as va LIMIT 1} AS a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      PARAMETERS $l=2 RETURN VALUE { RETURN 1 AS a NEXT RETURN a LIMIT $l} AS a
      """
    Then an Error should be raised: "[42N09]: Invalid syntax, the last statement in value query must be RETURN, with either a single item and LIMIT 1, or a single aggregate expression without GROUP BY"
    When executing query:
      """
      PARAMETERS $l=1 RETURN VALUE { RETURN 1 AS a NEXT RETURN a as va LIMIT $l} AS a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      RETURN VALUE { MATCH (v) RETURN * LIMIT 1 } AS val
      NEXT
      USE ldbc
      RETURN val.id AS vid
      """
    Then the result should be, in any order:
      | vid |
      | 1   |
      | 3   |
      | 2   |
      | 4   |
    When executing query:
      """
      USE ldbc
      RETURN VALUE { MATCH (v:Person{id:1})->(n) RETURN count(distinct n) group by v limit 1} AS val
      """
    Then the result should be, in any order:
      | val |
      | 7   |
    When executing query:
      """
      VALUE cnt = VALUE { RETURN 1 AS cnt LIMIT 1 }
      VALUE cnt2 = VALUE { RETURN 2 AS cnt LIMIT 1 }
      RETURN cnt, cnt2
      """
    Then the result should be, in any order:
      | cnt | cnt2 |
      | 1   | 2    |

  Scenario: PropertyCorrelated
    When executing query:
      """
      USE ldbc
      MATCH (m)-[:IS_PART_OF]->(p)
      RETURN m.id, p.id,
      VALUE {
      USE ldbc
      MATCH (q)
      WHERE q.id=m.id
      RETURN count(*) AS cnt GROUP BY ()} AS cnt
      """
    Then the result should be, in any order:
      | m.id | p.id | cnt |
      | 1    | 4    | 8   |
      | 2    | 5    | 8   |
      | 3    | 6    | 8   |

  Scenario: Nested value query expression
    When executing query:
      """
      USE ldbc
      LET a = 1
      RETURN VALUE { LET a = 2 RETURN 3 LIMIT 1 } AS b
      """
    Then an Error should be raised: "[NS002]: Semantic error, duplicate defined variable: `a`"
    When executing query:
      """
      USE ldbc
      LET a = 1
      RETURN VALUE { LET b = a RETURN b LIMIT 1 } AS b
      """
    Then the result should be, in any order:
      | b |
      | 1 |
    When executing query:
      """
      USE ldbc
      LET a = 1
      RETURN VALUE { RETURN 3 AS a LIMIT 1 } AS b
      """
    Then the result should be, in any order:
      | b |
      | 3 |
    When executing query:
      """
      USE ldbc
      LET a = 1
      RETURN VALUE { RETURN 3 AS a NEXT RETURN a LIMIT 1 } AS b
      """
    Then an Error should be raised: "[NS216]: The returned column `a` conflicts with parent scope variables. Please use a unique alias to distinguish them"
    When executing query:
      """
      USE ldbc
      LET a = 1
      RETURN VALUE { RETURN a NEXT RETURN a LIMIT 1 } AS b
      """
    Then an Error should be raised: "[NS216]: The returned column `a` conflicts with parent scope variables. Please use a unique alias to distinguish them"
    When executing query:
      """
      USE ldbc
      LET a = 1
      RETURN a, VALUE { RETURN a LIMIT 1 } AS b, a AS c
      """
    Then the result should be, in any order:
      | a | b | c |
      | 1 | 1 | 1 |
    When executing query:
      """
      USE ldbc
      LET a = 1
      RETURN a, VALUE { LET b = a + 1 RETURN 3 AS a LIMIT 1 } AS b
      """
    Then the result should be, in any order:
      | a | b |
      | 1 | 3 |
    When executing query:
      """
      USE ldbc
      LET a = 1
      RETURN a, VALUE { LET b = a + 1 RETURN 3 AS a NEXT RETURN a LIMIT 1 } AS b
      """
    Then an Error should be raised: "[NS216]: The returned column `a` conflicts with parent scope variables. Please use a unique alias to distinguish them"
    When executing query:
      """
      USE ldbc
      LET a = 1
      RETURN a, VALUE { LET b = a + 1 RETURN 3 AS a NEXT RETURN a AS c LIMIT 1 } AS b
      """
    Then an Error should be raised: "[NS216]: The returned column `a` conflicts with parent scope variables. Please use a unique alias to distinguish them"
    When executing query:
      """
      RETURN VALUE { for i in [1,2,3,4] return i order by i } AS b
      """
    Then an Error should be raised: "[42N09]: Invalid syntax, the last statement in value query must be RETURN, with either a single item and LIMIT 1, or a single aggregate expression without GROUP BY"
    When executing query:
      """
      USE ldbc
      LET a = 1
      RETURN VALUE { LET b = 2 RETURN VALUE { RETURN a + 1 as c LIMIT 1 } AS d LIMIT 1 } AS e
      """
    Then the result should be, in any order:
      | e |
      | 2 |
    When executing query:
      """
      USE ldbc
      LET a = 1
      RETURN VALUE { LET b = 2 RETURN VALUE { RETURN a + b as c LIMIT 1 } AS d LIMIT 1 } AS e
      """
    Then the result should be, in any order:
      | e |
      | 3 |
    When executing query:
      """
      USE ldbc
      LET a = 1
      RETURN VALUE { LET b = a RETURN VALUE { RETURN a + b as c LIMIT 1 } AS d LIMIT 1 } AS e
      """
    Then the result should be, in any order:
      | e |
      | 2 |
    When executing query:
      """
      USE ldbc
      LET a = 1
      RETURN VALUE { RETURN VALUE { RETURN a +1 as c LIMIT 1 } AS d LIMIT 1 } AS e
      """
    Then the result should be, in any order:
      | e |
      | 2 |
    When executing query:
      """
      USE ldbc
      LET a = 1
      RETURN VALUE { LET b = 2
                     RETURN VALUE { LET c = 3
                                    RETURN VALUE {
                                                    RETURN a + b + c LIMIT 1
                                                 }  LIMIT 1
                                  } LIMIT 1
                   } AS val
      """
    Then the result should be, in any order:
      | val |
      | 6   |
    When executing query:
      """
      USE ldbc
      LET a = 1
      RETURN VALUE { RETURN VALUE { RETURN VALUE {
                                                    RETURN a LIMIT 1
                                                 }  LIMIT 1
                                  } LIMIT 1
                   } AS val
      """
    Then the result should be, in any order:
      | val |
      | 1   |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      RETURN VALUE { RETURN CASE WHEN true THEN 1 ELSE v.id END AS a LIMIT 1 } +
             VALUE { RETURN CASE WHEN true THEN 2 else v.id END AS a LIMIT 1}
             AS val
      """
    Then the result should be, in any order:
      | val |
      | 3   |
      | 3   |
      | 3   |
      | 3   |
    When executing query:
      """
      USE ldbc
      LET a = 1
      RETURN VALUE { RETURN a + VALUE { RETURN a LIMIT 1 }  LIMIT 1} AS val
      """
    Then the result should be, in any order:
      | val |
      | 2   |
    When executing query:
      """
      USE ldbc
      LET a = 1
      RETURN VALUE { LET b = 2 RETURN VALUE { RETURN b LIMIT 1 } LIMIT 1 } AS val
      """
    Then the result should be, in any order:
      | val |
      | 2   |
    When executing query:
      """
      USE ldbc
      LET a = 1
      RETURN VALUE { LET b = a RETURN VALUE { RETURN b LIMIT 1 } LIMIT 1 } AS val
      """
    Then the result should be, in any order:
      | val |
      | 1   |
    When executing query:
      """
      USE ldbc
      LET a = 1
      RETURN VALUE { LET b = 2 RETURN VALUE { RETURN a LIMIT 1 } LIMIT 1 } AS val
      """
    Then the result should be, in any order:
      | val |
      | 1   |
    When executing query:
      """
      LET a = 1
      RETURN VALUE { RETURN VALUE { RETURN a AS c LIMIT 1 } LIMIT 1 } AS val
      """
    Then the result should be, in any order:
      | val |
      | 1   |
    When executing query:
      """
      LET a = 1
      RETURN EXISTS { RETURN a } AND ( VALUE { RETURN a LIMIT 1 } > 3 ) AS val
      """
    Then the result should be, in any order:
      | val   |
      | false |
    When executing query:
      """
      LET a = 1
      RETURN EXISTS { RETURN a + ( VALUE { RETURN a LIMIT 1 } ) } AS val
      """
    Then the result should be, in any order:
      | val  |
      | true |

  Scenario: ConflictType
    When executing query:
      """
      USE ldbc
      MATCH (m)-[e:IS_PART_OF]->(p)
      WHERE VALUE { USE ldbc MATCH pa = (e)-[:IS_PART_OF]->(p) RETURN count(*) AS cnt GROUP BY ()}<> 0
      RETURN m.id, p.id
      """
    Then an Error should be raised: "[42N23]: Invalid syntax, redefined variable: `e` with conflict type(`Node` vs `EDGE<(Place)-[IS_PART_OF]->(Place)>`)"
    When executing query:
      """
      USE ldbc
      MATCH (m)-[:IS_PART_OF]->(p)
      RETURN VALUE {
      USE ldbc MATCH (m)-[:IS_PART_OF]->(p)
      RETURN count(*) AS cnt GROUP BY ()
      } AS cnt, m.id AS cnt, p.id
      """
    Then an Error should be raised: "[NS109]: Semantic error, duplicate column name in return statement: `cnt`"
    When executing query:
      """
      USE ldbc
      MATCH (m)-[:IS_PART_OF]->(p)
      RETURN VALUE {
      USE ldbc MATCH (m)-[:IS_PART_OF]->(p)
      RETURN count(*) AS cnt GROUP BY ()
      } AS a, m.id AS cnt, p.id
      """
    Then the result should be, in any order:
      | a | cnt | p.id |
      | 1 | 1   | 4    |
      | 1 | 2   | 5    |
      | 1 | 3   | 6    |
    When executing query:
      """
      USE ldbc
      MATCH (m)-[:IS_PART_OF]->(p)
      RETURN count(*) AS cnt, m, p
      GROUP BY m,p
      NEXT
      USE ldbc
      RETURN VALUE {
        MATCH (m)-[:IS_PART_OF]->(p)
        RETURN count(*) AS cnt GROUP BY ()
      } AS a, m.id AS cnt, p.id
      """
    Then the result should be, in any order:
      | a | cnt | p.id |
      | 1 | 1   | 4    |
      | 1 | 2   | 5    |
      | 1 | 3   | 6    |

  Scenario: Conflict return column name
    When executing query:
      """
      USE ldbc
      MATCH (v2{id:1})
      RETURN VALUE {USE ldbc MATCH (v2:`Tag`) RETURN v2 limit 1} as v3
      """
    Then the result should be, in any order:
      | v3                                          |
      | null                                        |
      | null                                        |
      | null                                        |
      | ({name:"tag1",id:1,url:"https://tag1.com"}) |
      | null                                        |
      | null                                        |
      | null                                        |
      | null                                        |
    When executing query:
      """
      USE ldbc
      MATCH (v2{id:1})
      RETURN VALUE {USE ldbc MATCH (v2:`Tag`) RETURN v2 as vx limit 1} as v3
      """
    Then the result should be, in any order:
      | v3                                          |
      | null                                        |
      | null                                        |
      | null                                        |
      | ({name:"tag1",id:1,url:"https://tag1.com"}) |
      | null                                        |
      | null                                        |
      | null                                        |
      | null                                        |
    When executing query:
      """
      use ldbc
      match (v1:Person{id:1})-[e]->(v2) order by type(v2), v2.id
      return type(v2), v2.id,
        value {use ldbc match (v2:`Tag`) return v2 as vx limit 1} as v2
      """
    Then the result should be, in order:
      | type(v2)       | v2.id | v2                                          |
      | "Tag"          | 1     | ({name:"tag1",id:1,url:"https://tag1.com"}) |
      | "Comment"      | 1     | null                                        |
      | "Organisation" | 1     | null                                        |
      | "Organisation" | 1     | null                                        |
      | "Person"       | 1     | null                                        |
      | "Person"       | 2     | null                                        |
      | "Place"        | 1     | null                                        |
      | "Post"         | 1     | null                                        |
    When executing query:
      """
      use ldbc
      match (v1:Person{id:1})-[e]->(v2) order by type(v2), v2.id
      return type(v2), v2.id,
        value {use ldbc match (v2:`Tag`) return v2.id limit 1} as v2
      """
    Then the result should be, in order:
      | type(v2)       | v2.id | v2   |
      | "Tag"          | 1     | 1    |
      | "Comment"      | 1     | null |
      | "Organisation" | 1     | null |
      | "Organisation" | 1     | null |
      | "Person"       | 1     | null |
      | "Person"       | 2     | null |
      | "Place"        | 1     | null |
      | "Post"         | 1     | null |

  Scenario: WrongValueQuerySyntax
    When executing query:
      """
      USE ldbc
      MATCH (m)
      RETURN VALUE {
      USE ldbc MATCH (m)-[:IS_PART_OF]->(p)
      RETURN p
      } as vp
      """
    Then an Error should be raised: "[42N09]: Invalid syntax, the last statement in value query must be RETURN, with either a single item and LIMIT 1, or a single aggregate expression without GROUP BY"
    When executing query:
      """
      return value {let a = 1 finish}
      """
    Then an Error should be raised: "[42N09]: Invalid syntax, the last statement in value query must be RETURN, with either a single item and LIMIT 1, or a single aggregate expression without GROUP BY"
    When executing query:
      """
      RETURN VALUE {
        RETURN 1 AS id LIMIT 1
        UNION
        RETURN 2 AS id LIMIT 1
      } AS id
      """
    Then an Error should be raised: "[NS218]: Invalid value query expression"
    When executing query:
      """
      RETURN VALUE {
        IF (true) THEN {
            RETURN 1 AS id LIMIT 1
        } ELSE {
            RETURN 2 AS id LIMIT 1
        }
      } AS id
      """
    Then the result should be, in order:
      | id |
      | 1  |

  Scenario: LimitValueQueryExpression
    When executing query:
      """
      USE ldbc
      MATCH (m:Person)
      RETURN VALUE {
      USE ldbc MATCH (m)-[:IS_PART_OF]->(p)
      RETURN p
      ORDER BY p.id
      LIMIT 1
      } as vp, m.id as mid
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `(m)-[:IS_PART_OF]->(p)` was found"
    When executing query:
      """
      USE ldbc
      MATCH (m:City)
      LET maxCity = VALUE {
      USE ldbc MATCH (m)-[:IS_PART_OF]->(p)
      RETURN p
      ORDER BY p.name
      LIMIT 1
      }
      RETURN m.name, maxCity.name
      """
    Then the result should be, in any order:
      | m.name      | maxCity.name |
      | "Shenzhen"  | NULL         |
      | "Beijing"   | "Chongqing"  |
      | "Hangzhou"  | "Shenzhen"   |
      | "Chengdu"   | NULL         |
      | "Shanghai"  | "Chengdu"    |
      | "Chongqing" | NULL         |

  Scenario: value query with aggregate functions
    When executing query:
      """
      USE ldbc
      RETURN VALUE {
          USE ldbc
          MATCH (n:Person WHERE n.id > 0)-[:IS_LOCATED_IN]->(p:City)
          RETURN max(n.birthday.year)
          GROUP BY ()} as myValue
      """
    Then the result should be, in any order:
      | myValue |
      | 2001    |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person where v.id > 0)
      RETURN v.firstName,
        VALUE {
          USE ldbc
          MATCH (n:Person WHERE n.id > 0)-[:IS_LOCATED_IN]->(p:City)
          RETURN max(n.birthday.year)
          GROUP BY ()}
        AS myValue
      """
    Then the result should be, in any order:
      | v.firstName | myValue |
      | "Ming"      | 2001    |
      | "Sophie"    | 2001    |
      | "Kyle"      | 2001    |
      | "Tim"       | 2001    |

  Scenario: complex variable reference
    When executing query:
      """
      USE ldbc
      MATCH (v), (m)
      RETURN m, collect(v) AS x GROUP BY m
      NEXT
      USE ldbc
      RETURN VALUE { FOR i IN x
                        OPTIONAL MATCH (m)-[r]-(i)
                        FILTER r IS NOT NULL
                        RETURN count(r) GROUP BY () } AS val
      """
    Then the execution should be successful

  Scenario: GraphPattern correlated var
    When executing query:
      """
      USE ldbc {
      MATCH
      (v0)-[e1]->(v1)
      LET
      var4 = VALUE {
      MATCH
          p3 = (v2)-[e1]->(v3)
      RETURN v3.id
      LIMIT 1
      }
      RETURN count(var4) AS c
      }
      """
    Then the result should be, in any order:
      | c  |
      | 74 |
    When executing query:
      """
      USE ldbc {
      MATCH
          (v0)
      LET
          var4 = VALUE {
          MATCH
              p3 = (v0)
          RETURN 1
          LIMIT 1
      }
      RETURN count(var4) AS c
      }
      """
    Then the result should be, in any order:
      | c  |
      | 34 |
    When executing query:
      """
      USE ldbc {
      MATCH
          (v1)-[e1]->{1, 3}()
      LET
          var4 = VALUE {
          MATCH
              p3 = (v1)-[e2]->{1, 3}(v3)
          RETURN v3
          LIMIT 1
      }
      RETURN count(var4) AS c
      }
      """
    Then the result should be, in any order:
      | c    |
      | 1176 |

  Scenario: where subquery
    When executing query:
      """
      USE ldbc {
      MATCH
          (v0)
      MATCH
          (v)
      WHERE EXISTS {
      RETURN v0
      }
      FINISH
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc {
      LET x = 1
      RETURN x
      NEXT
      MATCH (v)
      WHERE VALUE { return x limit 1 } = 1
      RETURN COUNT(1) as c
      }
      """
    Then the result should be, in any order:
      | c  |
      | 34 |
    When executing query:
      """
      LET v1 = 1
      RETURN VALUE {
        IF v1 = 1 THEN {
          RETURN v1 * 2 AS c LIMIT 1
        } ELSE {
          RETURN 0 AS c LIMIT 1
        }
      } AS val
      """
    Then the result should be, in any order:
      | val |
      | 2   |

  Scenario: ControlFlowWithinValueQuery
    When executing query:
      """
      VALUE v1 = 5
      VALUE v2 = VALUE {
        IF v1 > 0 THEN {
          RETURN 1 AS val LIMIT 1
        } ELSE {
          RETURN 0 AS val LIMIT 1
        }
      }
      RETURN v2
      """
    Then the result should be, in any order:
      | v2 |
      | 1  |
    When executing query:
      """
      VALUE v1 = 5
      VALUE v2 = VALUE {
        WHILE v1 > 3 THEN {
          SET v1 = v1 - 1
        }
        RETURN v1 AS v2 LIMIT 1
      }
      RETURN v2
      """
    Then the result should be, in any order:
      | v2 |
      | 3  |
    When executing query:
      """
      VALUE v1 = 5
      VALUE v2 = VALUE {
        WHILE v1 > 0 THEN {
          SET v1 = v1 - 1
          IF v1 = 3 THEN {
            BREAK
          }
        }
        RETURN v1 AS v2 LIMIT 1
      }
      RETURN v2
      """
    Then the result should be, in any order:
      | v2 |
      | 3  |
    When executing query:
      """
      VALUE v1 = 5
      VALUE v2 = VALUE {
        VALUE v3 = 0
        WHILE v1 > 0 THEN {
          SET v1 = v1 - 1
          IF v1 > 3 THEN {
            CONTINUE
          }
          LOG_INFO(v1)
          SET v3 = v3 + 1
        }
        RETURN v3 LIMIT 1
      }
      RETURN v2
      """
    Then the result should be, in any order:
      | v2 |
      | 4  |

  Scenario: ValueQueryWithControlFlowInvalidColumnCount
    When executing query:
      """
      VALUE v1 = 5
      RETURN VALUE {
        IF v1 > 0 THEN {
          RETURN 1 AS a, 2 AS b LIMIT 1
        } ELSE {
          RETURN 0 AS a, 1 AS b LIMIT 1
        }
      } AS val
      """
    Then an Error should be raised: "[NS218]: Invalid value query expression: VALUE subquery must return exactly 1 column, got 2"
    When executing query:
      """
      VALUE v1 = 5
      RETURN VALUE {
        WHILE v1 > 0 THEN {
          SET v1 = v1 - 1
        }
      } AS val
      """
    Then an Error should be raised: "[NS218]: Invalid value query expression: VALUE subquery must return exactly 1 column, got 0"
