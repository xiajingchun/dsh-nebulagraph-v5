# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: Type and Labels Function

  Scenario: Type
    When executing query:
      """
      USE ldbc MATCH (v:Comment) where v.id=1 RETURN TYPE(v)
      """
    Then the result should be, in any order:
      | TYPE(v)   |
      | "Comment" |
    When executing query:
      """
      USE ldbc MATCH (v:Person WHERE v.id=1)-[e:KNOWS]->(b) RETURN TYPE(e)
      """
    Then the result should be, in any order:
      | TYPE(e) |
      | "KNOWS" |
    When executing query:
      """
      RETURN TYPE(null)
      """
    Then the result should be, in any order:
      | TYPE(null) |
      | NULL       |
    When executing query:
      """
      USE ldbc RETURN TYPE(null)
      """
    Then the result should be, in any order:
      | TYPE(null) |
      | NULL       |

  Scenario: Labels
    When executing query:
      """
      USE ldbc match (v:Comment) WHERE v.id=1 RETURN labels(v)
      """
    Then the result should be, in any order:
      | labels(v)                   |
      | LIST ["Comment", "Message"] |
    When executing query:
      """
      USE ldbc MATCH (v:Person WHERE v.id=1)-[e:KNOWS]->(b) RETURN LABELS(e)
      """
    Then the result should be, in any order:
      | LABELS(e)      |
      | LIST ["KNOWS"] |
    When executing query:
      """
      RETURN LABELS(null)
      """
    Then the result should be, in any order:
      | LABELS(null) |
      | NULL         |
    When executing query:
      """
      USE ldbc RETURN LABELS(null)
      """
    Then the result should be, in any order:
      | LABELS(null) |
      | NULL         |

  @sf01
  Scenario: Label intersections
    When executing query:
      """
      USE sf01 MATCH (v:Place) RETURN DISTINCT type(v) AS types
      """
    Then the result should be, in any order:
      | types       |
      | "City"      |
      | "Country"   |
      | "Continent" |
    When executing query:
      """
      USE sf01 MATCH (v:Place) MATCH (v:City) RETURN DISTINCT type(v) AS types
      """
    Then the result should be, in any order:
      | types  |
      | "City" |
    # FIX: https://github.com/vesoft-inc/nebula-ng/issues/8953
    When executing query:
      """
      USE ldbc MATCH (v) WHERE TYPE(v) = "hello" RETURN * LIMIT 1
      """
    Then the execution should be successful
