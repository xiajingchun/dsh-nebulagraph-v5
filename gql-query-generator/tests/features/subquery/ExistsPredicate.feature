# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: ExistsPredicate

  Scenario: FilterExistsPredicate
    When executing query:
      """
      USE ldbc
      LET a = 1
      FILTER EXISTS { LET a = 2 RETURN 3 }
      RETURN a
      """
    Then an Error should be raised: "[NS002]: Semantic error, duplicate defined variable: `a`"
    When executing query:
      """
      USE ldbc
      LET a = 1
      FILTER EXISTS { RETURN 2 AS a }
      RETURN a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      USE ldbc
      LET a = 1
      FILTER EXISTS { RETURN a }
      RETURN a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      USE ldbc
      LET a = 1
      RETURN EXISTS { LET a = 2 RETURN 3 } AS b
      """
    Then an Error should be raised: "[NS002]: Semantic error, duplicate defined variable: `a`"
    When executing query:
      """
      USE ldbc
      LET a = 1
      RETURN EXISTS { RETURN 2 AS a } AS b
      """
    Then the result should be, in any order:
      | b    |
      | true |
    When executing query:
      """
      USE ldbc
      LET a = 1
      RETURN EXISTS { RETURN a } AS b
      """
    Then the result should be, in any order:
      | b    |
      | true |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      WHERE EXISTS
      ((v)-[:KNOWS]->())
      RETURN v.id as vid
      """
    Then the result should be, in any order:
      | vid |
      | 3   |
      | 2   |
      | 1   |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      WHERE EXISTS
      ((v)-[:KNOWS]->())
      AND v.id <> 1
      RETURN v.id as vid
      """
    Then the result should be, in any order:
      | vid |
      | 3   |
      | 2   |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      WHERE EXISTS
      ((v)-[:KNOWS]->())
      OR v.id = 4
      RETURN v.id as vid
      """
    Then the result should be, in any order:
      | vid |
      | 2   |
      | 4   |
      | 1   |
      | 3   |
    When executing query:
      """
      RETURN EXISTS {
        VALUE a = false
        SET a = true
        RETURN a
      } AS b
      """
    Then the result should be, in any order:
      | b    |
      | true |

  Scenario: FilterNotExistsPredicate
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      WHERE NOT EXISTS
      ((v)-[:KNOWS]->())
      RETURN v.id as vid
      """
    Then the result should be, in any order:
      | vid |
      | 4   |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      WHERE NOT EXISTS
      ((v)-[:KNOWS]->())
      OR v.id = 1
      RETURN v.id as vid
      """
    Then the result should be, in any order:
      | vid |
      | 1   |
      | 4   |
    When executing query:
      """
      USE ldbc
      MATCH (friend:Person where friend.id=1)
      WHERE NOT EXISTS((friend:Person)<-[:KNOWS]->(person:Person{id : 30786325579101}))
      RETURN DISTINCT friend.id AS fid
      """
    Then the result should be, in any order:
      | fid |
      | 1   |

  Scenario: InlineWhereNotExistsPredicate
    When executing query:
      """
      USE ldbc
      MATCH (v:Person WHERE NOT EXISTS((v)-[:KNOWS]->()))
      RETURN v.id as vid
      """
    Then the result should be, in any order:
      | vid |
      | 4   |
    When executing query:
      """
      USE ldbc
      MATCH p = (v@Person)-[e:FOLLOWS]->{1,2}(n@Person WHERE NOT EXISTS((n)-[:KNOWS]->()))
      RETURN n.id
      """
    Then the result should be, in any order:
      | n.id |
      | 4    |
      | 4    |
      | 4    |

  Scenario: SubqueryInVarLenEdgePredicateNotSupported
    When executing query:
      """
      USE ldbc
      MATCH (v@Person{id:1})-[e:KNOWS WHERE EXISTS { RETURN e }]->{1,3}(n@Person)
      RETURN n.id
      LIMIT 1
      """
    Then an Error should be raised: "[NT000]: Using subquery in predicates of quantified edge/path patterns is not supported yet"
    When executing query:
      """
      USE ldbc
      MATCH (v@Person{id:1}) ( (a@Person)-[e:KNOWS]->(b@Person) WHERE NOT EXISTS((b)-[:KNOWS]->()) ){1,2} (c@Person)
      RETURN c.id
      LIMIT 1
      """
    Then an Error should be raised: "[NT000]: Using subquery in predicates of quantified edge/path patterns is not supported yet"

  Scenario: ReturnExistsPredicate
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      RETURN v.id AS vid,
      EXISTS  ((v)-[:KNOWS]->()) AS knows
      """
    Then the result should be, in any order:
      | vid | knows |
      | 3   | true  |
      | 4   | false |
      | 1   | true  |
      | 2   | true  |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      RETURN v.lastName as vname,
      EXISTS  ((v)-[:KNOWS]->(p:Person{lastName:"cao"})) AS knows
      """
    Then the result should be, in any order:
      | vname     | knows |
      | "Duncan"  | false |
      | "Marceau" | false |
      | "Yao"     | false |
      | "cao"     | true  |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      RETURN v.lastName as vname,
      EXISTS  { MATCH (v)-[:KNOWS]->(p:Person{lastName:"cao"}) } AS knows
      """
    Then the result should be, in any order:
      | vname     | knows |
      | "Duncan"  | false |
      | "Marceau" | false |
      | "Yao"     | false |
      | "cao"     | true  |

  Scenario: ControlFlowWithinExistsPredicate
    When executing query:
      """
      VALUE v1 = 5
      VALUE v2 = EXISTS {
        IF v1 > 0 THEN {
          RETURN 1 AS val
        } ELSE {
          FILTER false RETURN 0 AS val
        }
      }
      RETURN v2
      """
    Then the result should be, in any order:
      | v2   |
      | true |
    When executing query:
      """
      VALUE v1 = 5
      VALUE v2 = EXISTS {
        IF v1 <= 0 THEN {
          RETURN 1 AS val
        } ELSE {
          FILTER false RETURN 0 AS val
        }
      }
      RETURN v2
      """
    Then the result should be, in any order:
      | v2    |
      | false |
    When executing query:
      """
      VALUE v1 = 5
      VALUE v2 = EXISTS {
        WHILE v1 > 3 THEN {
          SET v1 = v1 - 1
        }
        RETURN v1 AS v2
      }
      RETURN v2
      """
    Then the result should be, in any order:
      | v2   |
      | true |
    When executing query:
      """
      VALUE v1 = 5
      VALUE v2 = EXISTS {
        WHILE v1 > 0 THEN {
          SET v1 = v1 - 1
          IF v1 = 3 THEN {
            BREAK
          }
        }
        RETURN v1 AS v2
      }
      RETURN v2
      """
    Then the result should be, in any order:
      | v2   |
      | true |
    When executing query:
      """
      VALUE v1 = 5
      VALUE v2 = EXISTS {
        VALUE v3 = 0
        WHILE v1 > 0 THEN {
          SET v1 = v1 - 1
          IF v1 > 3 THEN {
            CONTINUE
          }
          LOG_INFO(v1)
          SET v3 = v3 + 1
        }
        RETURN v3
      }
      RETURN v2
      """
    Then the result should be, in any order:
      | v2   |
      | true |

  Scenario: ExistsPredicateWithControlFlowInvalidColumnCount
    When executing query:
      """
      VALUE v1 = 5
      RETURN EXISTS {
        IF v1 > 0 THEN {
          SET v1 = v1 - 1
        } ELSE {
          SET v1 = v1 + 1
        }
      } AS val
      """
    Then the result should be, in any order:
      | val   |
      | false |
    When executing query:
      """
      VALUE v1 = 5
      RETURN EXISTS {
        IF v1 > 0 THEN {
          SET v1 = v1 - 1
        } ELSE {
          SET v1 = v1 + 1
        }
        FINISH
      } AS val
      """
    Then the result should be, in any order:
      | val   |
      | false |
    # return multiple columns
    When executing query:
      """
      VALUE v1 = 5
      RETURN EXISTS {
        WHILE v1 > 0 THEN {
          SET v1 = v1 - 1
        }
        RETURN v1 AS val, v1 + 1 AS val2
      } AS val
      """
    Then the result should be, in any order:
      | val  |
      | true |
