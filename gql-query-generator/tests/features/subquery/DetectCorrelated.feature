# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: DetectCorrelated

  Scenario: Detect correlated in aggregate function
    When executing query:
      """
      RETURN
      62 AS ri1
      NEXT
      RETURN EXISTS {
      RETURN (count(EXISTS {
      RETURN ri1
      }
      )) AS c
      } AS d
      """
    Then the result should be, in any order:
      | d    |
      | true |
    When executing query:
      """
      RETURN
      62 AS ri1
      NEXT
      RETURN VALUE {
      RETURN (count(VALUE {
         RETURN ri1 LIMIT 1
         }
      )) AS c LIMIT 1
      } AS d
      """
    Then the result should be, in any order:
      | d |
      | 1 |
