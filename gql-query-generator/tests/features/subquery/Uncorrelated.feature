# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: UncorrelatedSubquery

  Scenario: ExistsPredicate
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      FILTER EXISTS
      (MATCH (v1))
      RETURN v.id AS vid
      """
    Then the result should be, in any order:
      | vid |
      | 3   |
      | 2   |
      | 1   |
      | 4   |

  Scenario: ExistsPredicateInWhere
    When executing query:
      """
      USE ldbc
      MATCH (v: Person{id: 1})
      WHERE EXISTS((t))
      RETURN v.id as vid
      """
    Then the result should be, in any order:
      | vid |
      | 1   |
    When executing query:
      """
      USE ldbc
      MATCH (v: Person{id: 1})
      WHERE NOT EXISTS((t))
      RETURN v.id as vid
      """
    Then the result should be, in any order:
      | vid |
    When executing query:
      """
      USE ldbc
      MATCH (v: Person{id: 1})
      WHERE NOT EXISTS{
      MATCH (t) WHERE t.id < 0
      RETURN t}
      RETURN v.id as vid
      """
    Then the result should be, in any order:
      | vid |
      | 1   |
    When executing query:
      """
      USE ldbc
      MATCH (v: Person{id: 1})
      WHERE EXISTS{
      MATCH (t) WHERE t.id < 0
      RETURN t}
      RETURN v.id as vid
      """
    Then the result should be, in any order:
      | vid |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      WHERE EXISTS
      ((v1))
      RETURN v.id AS vid
      """
    Then the result should be, in any order:
      | vid |
      | 3   |
      | 2   |
      | 1   |
      | 4   |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      WHERE NOT EXISTS
      ((v1))
      RETURN v.id AS vid
      """
    Then the result should be, in any order:
      | vid |

  Scenario: ReturnExistsPredicate
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      RETURN v.id as vid,
      NOT EXISTS((v1)) as ne
      """
    Then the result should be, in any order:
      | vid | ne    |
      | 3   | false |
      | 2   | false |
      | 1   | false |
      | 4   | false |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      RETURN v.id as vid,
      EXISTS((v1)) as e
      """
    Then the result should be, in any order:
      | vid | e    |
      | 3   | true |
      | 2   | true |
      | 1   | true |
      | 4   | true |

  Scenario: ValueQuery
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      WHERE value {
      USE ldbc MATCH (v1:Person)
      RETURN MAX(v1.id) AS maxId GROUP BY ()} >v.id
      RETURN v.id as vid
      """
    Then the result should be, in any order:
      | vid |
      | 3   |
      | 2   |
      | 1   |

  Scenario: ValueQuery
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      RETURN v.id, value {
      USE ldbc MATCH (v1:Person)
      WHERE v1.id < 0
      RETURN MAX(v1.id) AS maxId
      GROUP BY ()
      } as m
      """
    Then the result should be, in any order:
      | v.id | m    |
      | 3    | NULL |
      | 1    | NULL |
      | 4    | NULL |
      | 2    | NULL |
    When executing query:
      """
      USE ldbc
      MATCH (p:Person{id:2}), (friend:Person{id:2})
      RETURN VALUE {
        MATCH (p)-[:KNOWS]-{1,3}(friend)-[]-(ff:Person)
        RETURN ff ORDER BY ff.id LIMIT 1
      } AS f
      NEXT USE ldbc RETURN f.id AS fid
      """
    Then the result should be, in any order:
      | fid |
      | 1   |
