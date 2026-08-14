@yld
Feature: YieldAfterMatch

  @skip
  Scenario: Errors
    When executing query:
      """
      USE ldbc
      MATCH (v:Person WHERE v.id IN LIST[abs(2), abs(3), abs(4), -888])-[e:KNOWS]->(b)
      YIELD b
      RETURN b.id as dst, v.id as src
      """
    Then an Error should be raised: "[42N18]: Invalid syntax, variable `v` not defined"
    When executing query:
      """
      USE ldbc
      MATCH (v:Person WHERE v.id IN LIST[abs(2), abs(3), abs(4), -888])-[e:KNOWS]->(b)
      YIELD b AS v
      RETURN *
      """
    Then an Error should be raised: "[42001]: syntax error near `AS v`"
    When executing query:
      """
      USE ldbc LET val=1
      MATCH p=(v:Person)-[e1:KNOWS]->(b)-[e2]->{1,3}()
      YIELD p,v,e1,b,e2,val
      RETURN *
      """
    Then an Error should be raised: "[42N24]: Invalid syntax, yield item should be NODE, EDGE or PATH type"

  @skip
  Scenario: MatchYield
    When executing query:
      """
      USE ldbc
      MATCH (v:Person{id:1})-[e:KNOWS]->(v2:Person)
      YIELD v2, v
      RETURN v2.firstName AS name
      """
    Then the result should be, in any order:
      | name   |
      | "Kyle" |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)-[e:not_exist_label]->(v2:Person)
      YIELD v2, v
      RETURN *
      """
    Then the result should be, in any order:
      | v | v2 |
    When executing query:
      """
      USE ldbc LET val=1
      MATCH p=(v:Person)-[e1:KNOWS]->(b)-[e2]->{1,3}(n)
      YIELD v,e1,b,e2,n
      FILTER where false
      RETURN 1
      """
    Then the result should be, in any order:
      | 1 |
    # fix https://github.com/vesoft-inc/nebula-ng/issues/4206
    # fix https://github.com/vesoft-inc/nebula-ng/issues/4208
    When executing query:
      """
      USE ldbc
      MATCH (friend:Person)-(v1:Person)-[e:STUDY_AT]->(u1:University)
      YIELD friend
      MATCH p=(v2)-[study:STUDY_AT]->(u1)
      FILTER ELEMENT_ID(v2) = ELEMENT_ID(friend)
      RETURN count(friend) AS total GROUP BY ()
      """
    Then the result should be, in order:
      | total |
      | 14    |

  # yield after graph pattern return error now
  Scenario: yield after graph pattern
    When executing query:
      """
      explain format="verbose"
      USE ldbc
      MATCH (v:Person{id:1})-[e:HAS_INTEREST]->(v1)
      YIELD v
      MATCH (v)-[e:IS_LOCATED_IN]->(v1)
      RETURN *
      """
    Then an Error should be raised: "[42N45]: Invalid syntax, yield clause after graph pattern is not supported now."
