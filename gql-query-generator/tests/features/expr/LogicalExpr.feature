# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: LogicalExpr

  Scenario: bool literal
    When executing query:
      """
      RETURN true AND false
      """
    Then the result should be, in any order:
      | true AND false |
      | false          |
    When executing query:
      """
      RETURN true AND true
      """
    Then the result should be, in any order:
      | true AND true |
      | true          |
    When executing query:
      """
      RETURN true OR false
      """
    Then the result should be, in any order:
      | true OR false |
      | true          |
    When executing query:
      """
      RETURN false OR false
      """
    Then the result should be, in any order:
      | false OR false |
      | false          |

  Scenario: IS TRUE IS NOT TRUE with Other Predicate
    When executing query:
      """
      USE ldbc MATCH(v:Person) RETURN v.gender, v.gender='male' IS TRUE as is_male
      """
    Then the result should be, in any order:
      | v.gender | is_male |
      | "female" | false   |
      | "male"   | true    |
      | "male"   | true    |
      | "male"   | true    |
    When executing query:
      """
      USE ldbc MATCH(v:Person) RETURN v.gender, v.gender='male' IS NOT TRUE as is_not_male
      """
    Then the result should be, in any order:
      | v.gender | is_not_male |
      | "female" | true        |
      | "male"   | false       |
      | "male"   | false       |
      | "male"   | false       |

  Scenario: TRUE IS
    When executing query:
      """
      RETURN TRUE IS TRUE
      """
    Then the result should be, in any order:
      | TRUE IS TRUE |
      | true         |
    When executing query:
      """
      RETURN TRUE IS FALSE
      """
    Then the result should be, in any order:
      | TRUE IS FALSE |
      | false         |
    When executing query:
      """
      RETURN TRUE IS UNKNOWN
      """
    Then the result should be, in any order:
      | TRUE IS UNKNOWN |
      | false           |
    When executing query:
      """
      RETURN TRUE IS NULL
      """
    Then the result should be, in any order:
      | TRUE IS NULL |
      | false        |

  Scenario: FALSE IS
    When executing query:
      """
      RETURN FALSE IS TRUE
      """
    Then the result should be, in any order:
      | FALSE IS TRUE |
      | false         |
    When executing query:
      """
      RETURN FALSE IS FALSE
      """
    Then the result should be, in any order:
      | FALSE IS FALSE |
      | true           |
    When executing query:
      """
      RETURN FALSE IS UNKNOWN
      """
    Then the result should be, in any order:
      | FALSE IS UNKNOWN |
      | false            |
    When executing query:
      """
      RETURN FALSE IS NULL
      """
    Then the result should be, in any order:
      | FALSE IS NULL |
      | false         |

  Scenario: UNKNOWN IS
    When executing query:
      """
      RETURN UNKNOWN IS TRUE
      """
    Then the result should be, in any order:
      | UNKNOWN IS TRUE |
      | false           |
    When executing query:
      """
      RETURN UNKNOWN IS FALSE
      """
    Then the result should be, in any order:
      | UNKNOWN IS FALSE |
      | false            |
    When executing query:
      """
      RETURN UNKNOWN IS UNKNOWN
      """
    Then the result should be, in any order:
      | UNKNOWN IS UNKNOWN |
      | true               |
    When executing query:
      """
      RETURN UNKNOWN IS NULL
      """
    Then the result should be, in any order:
      | UNKNOWN IS NULL |
      | true            |

  Scenario: NULL IS
    When executing query:
      """
      RETURN NULL IS TRUE
      """
    Then the result should be, in any order:
      | NULL IS TRUE |
      | false        |
    When executing query:
      """
      RETURN NULL IS FALSE
      """
    Then the result should be, in any order:
      | NULL IS FALSE |
      | false         |
    When executing query:
      """
      RETURN NULL IS UNKNOWN
      """
    Then the result should be, in any order:
      | NULL IS UNKNOWN |
      | true            |
    When executing query:
      """
      RETURN NULL IS NULL
      """
    Then the result should be, in any order:
      | NULL IS NULL |
      | true         |

  Scenario: NOT
    When executing query:
      """
      RETURN NOT(NULL)
      """
    Then the result should be, in any order:
      | NOT(NULL) |
      | null      |

  Scenario: bool literal with null
    When executing query:
      """
      RETURN null AND false
      """
    Then the result should be, in any order:
      | null AND false |
      | false          |
    When executing query:
      """
      RETURN null AND true
      """
    Then the result should be, in any order:
      | null AND true |
      | NULL          |
    When executing query:
      """
      RETURN null OR false
      """
    Then the result should be, in any order:
      | null OR false |
      | NULL          |
    When executing query:
      """
      RETURN null OR true
      """
    Then the result should be, in any order:
      | null OR true |
      | true         |
    When executing query:
      """
      RETURN (null OR true) AND (null OR false)
      """
    Then the result should be, in any order:
      | (null OR true) AND (null OR false) |
      | NULL                               |
    # FIX: https://github.com/vesoft-inc/nebula-ng/issues/8407
    When executing query:
      """
      FOR ua0 IN list[null, null, null]
      FILTER ua0 OR false
      RETURN ua0
      """
    Then the result should be, in any order:
      | ua0 |

  @sf01
  Scenario: complex or expr
    When executing query:
      """
      USE sf01 MATCH TRAIL (v:Person{id:318})-[e]->{2}(v2)
      RETURN v, v2, COLLECT(e) AS e_list GROUP BY v, v2
      NEXT
      USE sf01
      FILTER reduce(e_list, FALSE, (s, item) -> s OR (SIZE(item) = 1))
      RETURN COUNT(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 0   |
    When executing query:
      """
      USE sf01 MATCH (v:Person{id:318})-[e]->{1}(v2)
      RETURN v, v2, COLLECT(e) AS e_list GROUP BY v, v2
      NEXT
      USE sf01
      FILTER reduce(e_list, FALSE, (s, item) -> s OR (SIZE(item) = 1))
      RETURN COUNT(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 217 |

  # FIX: https://github.com/vesoft-inc/nebula-ng/issues/9723
  Scenario: contradictory filter condition
    When executing query:
      """
      USE ldbc
      MATCH (v:Person{id: 2})
      FILTER v.id > 2
      RETURN v.id AS vid
      """
    Then the result should be, in any order:
      | vid |
