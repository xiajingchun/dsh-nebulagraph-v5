# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: TopN

  Scenario: TopNStatement
    When executing query:
      """
      USE ldbc match (v)
      order by v.id
      SKIP 0 LIMIT 2
      RETURN v.id
      """
    Then the result should be, in order:
      | v.id |
      | 1    |
      | 1    |
    When executing query:
      """
      USE ldbc match (v)
      order by v.id
      SKIP 0 LIMIT 0
      RETURN v.id
      """
    Then the result should be, in order:
      | v.id |
    When executing query:
      """
      ORDER BY 62 / 0 OFFSET 74 RETURN 1 AS A
      """
    Then an Error should be raised: "[22012]: Division by zero: `62 / 0`, type: `INT32`, in expression: 62 / 0"
    When executing query:
      """
      ORDER BY 62 / 1 OFFSET 74 RETURN 1 AS A
      """
    Then the result should be, in order:
      | A |
    When executing query:
      """
      ORDER BY 62 / 1 OFFSET 0 RETURN 1 AS A
      """
    Then the result should be, in order:
      | A |
      | 1 |

  @sf01
  Scenario: TopPost
    When executing query:
      """
      USE sf01 MATCH (p:Post) ORDER BY p.id LIMIT 10 RETURN p.id
      """
    Then the result should be, in order:
      | p.id  |
      | 3     |
      | 32484 |
      | 32693 |
      | 32756 |
      | 32782 |
      | 32833 |
      | 32843 |
      | 32903 |
      | 33041 |
      | 33042 |

  @sf01
  Scenario: TopWithSkip
    When executing query:
      """
      USE sf01 MATCH (p:Post) ORDER BY p.id SKIP 3 LIMIT 5 RETURN p.id
      """
    Then the result should be, in order:
      | p.id  |
      | 32756 |
      | 32782 |
      | 32833 |
      | 32843 |
      | 32903 |

  @sf01
  Scenario: TopThenSkip
    When executing query:
      """
      USE sf01 MATCH (p:Post) ORDER BY p.id LIMIT 5 SKIP 3 RETURN p.id
      """
    Then the result should be, in order:
      | p.id  |
      | 32756 |
      | 32782 |
