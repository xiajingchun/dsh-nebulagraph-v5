# Copyright (c) 2025 vesoft inc. All rights reserved.
# NOTE: This feature is a copy of the feature `MatchStatement` in the `MatchStatement.feature` file, but for the memory graph #analytic_ldbc
Feature: MatchStatement On MemGraph

  # FIXME: VariadicView does not support VectorReader<T, Const>
  Scenario: Match zero step
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Person WHERE v.id IN LIST[2, 3, 4, 888])-[e:KNOWS]->{0}(b)
      RETURN v.id as src, b.id as dst
      """
    Then an Error should be raised: "[NS103]: Semantic error, the value of upper bound of graph pattern quantifier shall be greater than 0"
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v IS Person WHERE v.id IN LIST[2, 3, 4, 888])-[e:KNOWS]->{0,1}(b)
      RETURN v.id as src, b.id as dst, v.vec as vvec, (e[0]).vec as evec, (e[0]) IS NULL AS isNull
      """
    Then the result should be, in any order:
      | src | dst | vvec                      | evec                   | isNull |
      | 3   | 3   | VECTOR [7.0, 8.0, 9.0]    | VECTOR [7.0, 8.0, 9.0] | false  |
      | 3   | 3   | VECTOR [7.0, 8.0, 9.0]    | null                   | true   |
      | 4   | 4   | VECTOR [10.0, 11.0, 12.0] | null                   | true   |
      | 2   | 2   | VECTOR [4.0, 5.0, 6.0]    | null                   | true   |
      | 2   | 2   | VECTOR [4.0, 5.0, 6.0]    | VECTOR [4.0, 5.0, 6.0] | false  |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH TRAIL (v:Person WHERE v.id IN LIST[2, 3, 4, 888])-[e:KNOWS]->{0,1}(b)-[e2:KNOWS]->{0,2}(c)
      RETURN v.id as src, b.id as mid, c.id as dst
      """
    Then the result should be, in any order:
      | src | mid | dst |
      | 4   | 4   | 4   |
      | 3   | 3   | 3   |
      | 3   | 3   | 3   |
      | 2   | 2   | 2   |
      | 2   | 2   | 2   |
      | 3   | 3   | 3   |
      | 2   | 2   | 2   |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Person WHERE v.id = 1)-[e:KNOWS]->{0,1}(b:Person {id:3})
      RETURN v.id as src, b.id as dst
      """
    Then the result should be, in any order:
      | src | dst |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH TRAIL (v:Person{id:1})-[e:KNOWS]->{0, 2}(v2)
      RETURN v2.id as dst
      """
    Then the result should be, in any order:
      | dst |
      | 1   |
      | 1   |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Person WHERE v.id IN LIST[abs(2), abs(3), abs(4), -888])-[e:KNOWS]->{0}(b)
      RETURN v.id as src, b.id as dst
      """
    Then an Error should be raised: "[NS103]: Semantic error, the value of upper bound of graph pattern quantifier shall be greater than 0"
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Person WHERE v.id IN LIST[abs(2), abs(3), abs(4), -888])-[e:KNOWS]->{0,1}(b)
      RETURN v.id as src, b.id as dst
      """
    Then the result should be, in any order:
      | src | dst |
      | 2   | 2   |
      | 3   | 3   |
      | 4   | 4   |
      | 2   | 2   |
      | 3   | 3   |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH TRAIL (v:Person WHERE v.id IN LIST[abs(2), abs(3), abs(4), -888])-[e:KNOWS]->{0,1}(b)-[e2:KNOWS]->{0,2}(c)
      RETURN v.id as src, b.id as mid, c.id as dst
      """
    Then the result should be, in any order:
      | src | mid | dst |
      | 4   | 4   | 4   |
      | 3   | 3   | 3   |
      | 3   | 3   | 3   |
      | 2   | 2   | 2   |
      | 2   | 2   | 2   |
      | 3   | 3   | 3   |
      | 2   | 2   | 2   |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Person WHERE v.id = 1)-[e:KNOWS]->{0,1}(b:Person {id:3})
      RETURN v.id as src, b.id as dst
      """
    Then the result should be, in any order:
      | src | dst |

  Scenario: Match
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Person WHERE v.id = 1)
      RETURN v.firstName as name
      """
    Then the result should be, in any order:
      | name   |
      | "Kyle" |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Person{id:1})-[e:KNOWS]->(v2:Person)
      RETURN v2.firstName AS name
      """
    Then the result should be, in any order:
      | name   |
      | "Kyle" |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Person) WHERE v.firstName <> "Tom"
      RETURN v.id AS vid
      """
    Then the result should be, in any order:
      | vid |
      | 1   |
      | 3   |
      | 2   |
      | 4   |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Person)
      RETURN v.id < 3 AS pred
      NEXT USE #analytic_ldbc
      OPTIONAL MATCH (v:Person{firstName:"Tim"})
      FILTER pred
      RETURN v.id AS vid
      """
    Then the result should be, in any order:
      | vid |
      | 2   |
      | 2   |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Person) WHERE v.firstName <> "Tom"
      LIMIT 4
      RETURN v.id AS vid
      """
    Then the result should be, in any order:
      | vid |
      | 1   |
      | 3   |
      | 2   |
      | 4   |
    # The label doesn't exist
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Not_Exist_Label)
      RETURN v.id AS vid
      """
    Then an Error should be raised: "[NS228]: node label `Not_Exist_Label` not found in graph type `ldbc_type`"
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v1:Person), (v2:Person), (v1:Person)
      RETURN count(v2) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 16  |
    # 888 is not existed
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Person WHERE v.id IN LIST[abs(2), abs(3), abs(4), -888])
      RETURN v.firstName as name, v.id as id
      """
    Then the result should be, in any order:
      | name     | id |
      | "Sophie" | 4  |
      | "Ming"   | 3  |
      | "Tim"    | 2  |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:not_exist_label)
      RETURN v
      """
    Then an Error should be raised: "[NS228]: node label `not_exist_label` not found in graph type `ldbc_type`"
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:not_exist_label)-[e:KNOWS]->(v2:Person)
      RETURN v2
      """
    Then an Error should be raised: "[NS228]: node label `not_exist_label` not found in graph type `ldbc_type`"
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Person)-[e:not_exist_label]->(v2:Person)
      RETURN v2
      """
    Then an Error should be raised: "[NS228]: edge label `not_exist_label` not found in graph type `ldbc_type`"
    When executing query:
      """
      VALUE test_vector=VECTOR<3,float>([1.1,2.1,3.1])
      USE #analytic_ldbc
      MATCH (v:Person)
      ORDER BY vector_distance(test_vector,v.vec) APPROX LIMIT 10 OPTIONS {type:IVF}
      RETURN v.vec AS vec, round(euclidean(test_vector,v.vec)) AS dist, test_vector
      """
    Then the result should be, in any order:
      | vec                     | dist | test_vector          |
      | VECTOR [1.0,2.0,3.0]    | 0.0  | VECTOR [1.1,2.1,3.1] |
      | VECTOR [4.0,5.0,6.0]    | 5.0  | VECTOR [1.1,2.1,3.1] |
      | VECTOR [7.0,8.0,9.0]    | 10.0 | VECTOR [1.1,2.1,3.1] |
      | VECTOR [10.0,11.0,12.0] | 15.0 | VECTOR [1.1,2.1,3.1] |

  Scenario: Variables declared by a path pattern are visible to any element pattern within it
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v1:Person)-[e:KNOWS]->(v2:Person{firstName: v1.firstName})
      RETURN v1.firstName AS name1, v2.firstName AS name2
      """
    Then the result should be, in any order:
      | name1  | name2  |
      | "Ming" | "Ming" |
      | "Tim"  | "Tim"  |
      | "Kyle" | "Kyle" |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v1:Person{firstName: v2.firstName})-[e:KNOWS]->(v2:Person)
      RETURN v1.firstName AS name1, v2.firstName AS name2
      """
    Then the result should be, in any order:
      | name1  | name2  |
      | "Ming" | "Ming" |
      | "Tim"  | "Tim"  |
      | "Kyle" | "Kyle" |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v1:Person)-[e:KNOWS WHERE e.creationDate > v1.birthday AND e.creationDate > v2.birthday]->(v2:Person)
      RETURN v1.firstName AS name1, v2.firstName AS name2
      """
    Then the result should be, in any order:
      | name1  | name2  |
      | "Ming" | "Ming" |
      | "Tim"  | "Tim"  |
      | "Kyle" | "Kyle" |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v1:Person{firstName:v2.firstName})-[e:KNOWS]->(v2:Person{gender:v1.gender})
      RETURN v1.firstName AS name1, v1.gender AS gender1, v2.firstName AS name2, v2.gender AS gender2
      """
    Then the result should be, in any order:
      | name1  | gender1 | name2  | gender2 |
      | "Kyle" | "male"  | "Kyle" | "male"  |
      | "Ming" | "male"  | "Ming" | "male"  |
      | "Tim"  | "male"  | "Tim"  | "male"  |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v1:Person)-[e:KNOWS]->(v2:Person)
        WHERE v1.firstName = v2.firstName
      RETURN v1.firstName AS name1, v2.firstName AS name2
      """
    Then the result should be, in any order:
      | name1  | name2  |
      | "Ming" | "Ming" |
      | "Tim"  | "Tim"  |
      | "Kyle" | "Kyle" |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v1:Person)-[e:KNOWS]->(v2:Person)
      FILTER  WHERE v1.firstName = v2.firstName
      RETURN v1.firstName AS name1, v2.firstName AS name2
      """
    Then the result should be, in any order:
      | name1  | name2  |
      | "Ming" | "Ming" |
      | "Tim"  | "Tim"  |
      | "Kyle" | "Kyle" |
    When executing query:
      """
      USE #analytic_ldbc MATCH (v:Person{id:1})
      LET _list = VALUE { MATCH p = (v)-[e]->{1}() RETURN p LIMIT 1}
      RETURN length(_list) AS len LIMIT 1
      """
    Then the result should be, in any order:
      | len |
      | 1   |

  Scenario: Variables declared by a graph pattern are visible to any element pattern within it
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v1:Person), (v2:Person{firstName:v1.firstName})
      RETURN v1.firstName AS name1, v2.firstName AS name2
      """
    Then the result should be, in any order:
      | name1    | name2    |
      | "Ming"   | "Ming"   |
      | "Tim"    | "Tim"    |
      | "Kyle"   | "Kyle"   |
      | "Sophie" | "Sophie" |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v1:Person{firstName:v2.firstName}), (v2:Person)
      RETURN v1.firstName AS name1, v2.firstName AS name2
      """
    Then the result should be, in any order:
      | name1    | name2    |
      | "Ming"   | "Ming"   |
      | "Tim"    | "Tim"    |
      | "Kyle"   | "Kyle"   |
      | "Sophie" | "Sophie" |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v1:Person{firstName:v2.firstName}), (v2:Person{gender:v1.gender})
      RETURN v1.firstName AS name1, v1.gender AS gender1, v2.firstName AS name2, v2.gender AS gender2
      """
    Then the result should be, in any order:
      | name1    | gender1  | name2    | gender2  |
      | "Kyle"   | "male"   | "Kyle"   | "male"   |
      | "Sophie" | "female" | "Sophie" | "female" |
      | "Ming"   | "male"   | "Ming"   | "male"   |
      | "Tim"    | "male"   | "Tim"    | "male"   |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v1:Person{firstName:v2.firstName}), (v2:Person{gender:v1.gender})-[e:KNOWS]->(v3:Person WHERE v3.firstName = v1.firstName OR v3.firstName = v2.firstName)
      RETURN v1.firstName AS name1, v1.gender AS gender1, v2.firstName AS name2, v2.gender AS gender2, v3.firstName AS name3, v3.gender AS gender3
      """
    Then the result should be, in any order:
      | name1  | gender1 | name2  | gender2 | name3  | gender3 |
      | "Kyle" | "male"  | "Kyle" | "male"  | "Kyle" | "male"  |
      | "Ming" | "male"  | "Ming" | "male"  | "Ming" | "male"  |
      | "Tim"  | "male"  | "Tim"  | "male"  | "Tim"  | "male"  |

  Scenario: Previous variables are visible to the match statement followed
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v1:Person)
      MATCH (v2:Person{firstName:v1.firstName})
      RETURN v1.firstName AS name1, v2.firstName AS name2
      """
    Then the result should be, in any order:
      | name1    | name2    |
      | "Ming"   | "Ming"   |
      | "Tim"    | "Tim"    |
      | "Kyle"   | "Kyle"   |
      | "Sophie" | "Sophie" |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v1:Person)
      OPTIONAL MATCH (v2:Person{firstName:v1.firstName})
      RETURN v1.firstName AS name1, v2.firstName AS name2
      """
    Then the result should be, in any order:
      | name1    | name2    |
      | "Ming"   | "Ming"   |
      | "Tim"    | "Tim"    |
      | "Kyle"   | "Kyle"   |
      | "Sophie" | "Sophie" |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v1:Person)
      OPTIONAL MATCH (v2:Person) WHERE v2.firstName = v1.firstName
      RETURN v1.firstName AS name1, v2.firstName AS name2
      """
    Then the result should be, in any order:
      | name1    | name2    |
      | "Ming"   | "Ming"   |
      | "Tim"    | "Tim"    |
      | "Kyle"   | "Kyle"   |
      | "Sophie" | "Sophie" |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v1:Person)
      OPTIONAL MATCH (v1)-[e:KNOWS]->(v2:Person)
      RETURN v1.firstName AS name1, v2.firstName AS name2
      """
    Then the result should be, in any order:
      | name1    | name2  |
      | "Ming"   | "Ming" |
      | "Tim"    | "Tim"  |
      | "Kyle"   | "Kyle" |
      | "Sophie" | NULL   |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v1:Person{firstName:v2.firstName})
      MATCH (v2:Person)
      RETURN v1.firstName AS name1, v2.firstName AS name2
      """
    Then an Error should be raised:  "[42N18]: Invalid syntax, variable `v2` not defined"
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v1:Person{firstName:v2.firstName})
      MATCH (v2:Person{gender:v1.gender})
      RETURN v1.firstName AS name1, v1.gender AS gender1, v2.firstName AS name2, v2.gender AS gender2
      """
    Then an Error should be raised:  "[42N18]: Invalid syntax, variable `v2` not defined"

  Scenario: same node or edge var
    When executing query:
      """
      USE #analytic_ldbc
      MATCH p = TRAIL (v1:Person{id:1})-[e:KNOWS]->(v2:Person{id:1})-[e:KNOWS]->(v1)
      RETURN COUNT(*) AS cnt GROUP BY ()
      """
    Then an Error should be raised: "[NS221]: Repeated edge variable in a path pattern restricted by TRAIL mode will lead to no results"
    When executing query:
      """
      USE #analytic_ldbc
      MATCH p = WALK (v1:Person{id:1})-[e:KNOWS]->(v2:Person{id:1})-[e:KNOWS]->(v1)
      RETURN length(p) AS len
      """
    Then the result should be, in any order:
      | len |
      | 2   |

  Scenario: Match Path
    When executing query:
      """
      USE #analytic_ldbc
      MATCH p = (v:Person{id:2})
      RETURN p
      """
    Then the result should be, in any order:
      | p                                                                                                                                                                                                                |
      | PATH [({lastName:"Duncan",birthday:DATE '2001-04-25',browserUsed:"IE",gender:"male",locationIP:"192.168.2",firstName:"Tim",creationDate:DATETIME '2021-01-01T11:00:40.213000',id:2,vec:VECTOR [4.0, 5.0, 6.0]})] |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH p = (v:Person{firstName:"Tim"})-[e1:KNOWS]-()
      RETURN p
      """
    Then the result should be, in any order:
      | p                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
      | PATH [({lastName:"Duncan",birthday:DATE '2001-04-25',browserUsed:"IE",gender:"male",locationIP:"192.168.2",firstName:"Tim",creationDate:DATETIME '2021-01-01T11:00:40.213000',id:2,vec:VECTOR [4.0, 5.0, 6.0]}), [{creationDate:DATETIME '2021-01-01T10:00:40.213000',vec: VECTOR [4.0,5.0,6.0]}], ({creationDate:DATETIME '2021-01-01T11:00:40.213000',id:2,locationIP:"192.168.2",gender:"male",browserUsed:"IE",firstName:"Tim",birthday:DATE' 2001-04-25',lastName:"Duncan",vec:VECTOR [4.0, 5.0, 6.0]})] |
      | PATH [({locationIP:"192.168.2",gender:"male",browserUsed:"IE",birthday:DATE '2001-04-25',lastName:"Duncan",firstName:"Tim",creationDate:DATETIME '2021-01-01T11:00:40.213000',id:2,vec:VECTOR [4.0, 5.0, 6.0]}), [{creationDate:DATETIME '2021-01-01T10:00:40.213000',vec: VECTOR [4.0,5.0,6.0]}], ({gender:"male",browserUsed:"IE",locationIP:"192.168.2",creationDate:DATETIME '2021-01-01T11:00:40.213000',id:2,firstName:"Tim",birthday:DATE '2001-04-25',lastName:"Duncan",vec:VECTOR [4.0, 5.0, 6.0]})] |

  Scenario: Path search prefix
    When executing query:
      """
      USE #analytic_ldbc
      MATCH ANY 1 (v:Person{id:2})-[e:KNOWS]->(v1)
      RETURN v1.id AS id
      """
    Then the result should be, in any order:
      | id |
      | 2  |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH ANY 0 (v:Person{id:2})-[e:KNOWS]->(v1)
      RETURN v1.id AS id
      """
    Then the result should be, in any order:
      | id |

  Scenario: Match Path with mutiple node types
    When executing query:
      """
      USE #analytic_ldbc
      MATCH p = (v)-[e]->()
      RETURN length(p) limit 2
      """
    Then the execution should be successful
    When executing query:
      """
      USE #analytic_ldbc
      MATCH p = (v)-[e]->()
      RETURN length(p) limit 2
      """
    Then the execution should be successful
    # FIXME(Xuntao): the internals depended by the following function 'same' have been removed. Need to reimplement the same function. Comment out this case for now.
    When executing query:
      """
      USE #analytic_ldbc
      MATCH p= TRAIL (m:Person{id:3})-[r]->(n)->(v:Person)
      RETURN same(m,n) AS a1, same(m,v,n) AS a2, same(m,n,m) AS a3, same(r,r,r,r) AS a4
      """
    Then the result should be, in any order:
      | a1    | a2    | a3    | a4   |
      | false | false | false | true |
      | true  | false | true  | true |
      | false | false | false | true |
      | false | false | false | true |
      | true  | false | true  | true |
      | false | false | false | true |
      | false | false | false | true |
      | false | false | false | true |
      | false | false | false | true |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH p=(m:Person{id:3})
      LET n = null
      RETURN same(m, n) AS a1
      """
    Then an Error should be raised: "[NR002]: Undefined function: `same(NODE, NULL)`"
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Person WHERE v.id IN LIST[2, 3, 4, 888])-[e:KNOWS]->{0}(b)
      KEEP TRAIL
      RETURN v.id as src, b.id as dst
      """
    Then an Error should be raised: "[NT000]: The `keep clause` is not supported yet"

  # Fix https://github.com/vesoft-inc/nebula-ng/issues/2489
  Scenario: Match Path contains variable length pattern
    When executing query:
      """
      USE #analytic_ldbc
      MATCH p=(v{id:2})-[e:KNOWS]->{1}(v1) RETURN p
      """
    Then the result should be, in any order:
      | p                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
      | PATH [({lastName:"Duncan",birthday:DATE '2001-04-25',browserUsed:"IE",gender:"male",locationIP:"192.168.2",firstName:"Tim",creationDate:DATETIME '2021-01-01T11:00:40.213000',id:2,vec:VECTOR [4.0, 5.0, 6.0]}), [{creationDate:DATETIME '2021-01-01T10:00:40.213000',vec: VECTOR [4.0,5.0,6.0]}], ({creationDate:DATETIME '2021-01-01T11:00:40.213000',id:2,locationIP:"192.168.2",gender:"male",browserUsed:"IE",firstName:"Tim",birthday:DATE' 2001-04-25',lastName:"Duncan",vec:VECTOR [4.0, 5.0, 6.0]})] |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH p= TRAIL (v{id:2})-[e:KNOWS]->{1,3}(v1) RETURN p
      """
    Then the result should be, in any order:
      | p                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
      | PATH [({lastName:"Duncan",birthday:DATE '2001-04-25',browserUsed:"IE",gender:"male",locationIP:"192.168.2",firstName:"Tim",creationDate:DATETIME '2021-01-01T11:00:40.213000',id:2,vec:VECTOR [4.0, 5.0, 6.0]}), [{creationDate:DATETIME '2021-01-01T10:00:40.213000',vec:VECTOR [4.0,5.0,6.0]}], ({creationDate:DATETIME '2021-01-01T11:00:40.213000',id:2,locationIP:"192.168.2",gender:"male",browserUsed:"IE",firstName:"Tim",birthday:DATE' 2001-04-25',lastName:"Duncan",vec:VECTOR [4.0, 5.0, 6.0]})] |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH p= WALK (v{id:2})-[e:KNOWS]->{1,3}(v1) RETURN nodes(p) AS nodes
      NEXT
      USE #analytic_ldbc
      RETURN transform(nodes, n -> n.id) AS node_ids_of_path
      """
    Then the result should be, in any order:
      | node_ids_of_path |
      | LIST[2, 2]       |
      | LIST[2, 2, 2]    |
      | LIST[2, 2, 2, 2] |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH p= TRAIL (v{id:2})-[e:KNOWS]->{1,3}(v1) RETURN cardinality(p) AS c
      """
    Then the result should be, in any order:
      | c |
      | 3 |
    When executing query:
      """
      EXPLAIN raw format="verbose"
      USE #analytic_ldbc MATCH (v0:Person)<-[e1:KNOWS]->(v2:Person)<-[e3:KNOWS]->(v4:Person)-[e5:KNOWS]->(v6:Person) RETURN v6.id AS vid
      """
    Then the execution should be successful

  Scenario: Test path restrictors
    # Use Edge type FOLLOWS to test path restrictors
    # The topology of FOLLOWS is: 1->2->3->2->4, 3->1
    When executing query:
      """
      USE #analytic_ldbc
      MATCH TRAIL (v0:Person{id:1})-[e:FOLLOWS]->{1,10}(v1:Person{id:4})
      RETURN e
      """
    # 1->2->4, 1->2->3->2->4
    Then the result should be, in any order:
      | e                                                                         |
      | LIST [[{dst:2,src:1}], [{dst:4,src:2}]]                                   |
      | LIST [[{dst:2,src:1}], [{dst:3,src:2}], [{dst:2,src:3}], [{dst:4,src:2}]] |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH SIMPLE (v0:Person{id:1})-[e:FOLLOWS]->{1,10}(v1:Person{id:4})
      RETURN e
      """
    # 1->2->4
    Then the result should be, in any order:
      | e                                       |
      | LIST [[{dst:2,src:1}], [{dst:4,src:2}]] |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH ACYCLIC (v0:Person{id:1})-[e:FOLLOWS]->{1,10}(v1:Person{id:4})
      RETURN e
      """
    # 1->2->4
    Then the result should be, in any order:
      | e                                       |
      | LIST [[{dst:2,src:1}], [{dst:4,src:2}]] |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH ACYCLIC (v0:Person{id:1})-[e:FOLLOWS]->{1,10}(v1:Person{id:2})
      RETURN e
      """
    # 1->2
    Then the result should be, in any order:
      | e                      |
      | LIST [[{dst:2,src:1}]] |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH TRAIL (v0:Person)-[e:FOLLOWS]->{1,10}(v1:Person)
      FILTER where v1.id = v0.id
      RETURN e
      """
    # 1->2->3->1, 2->3->2, 2->3->1->2, 3->1->2->3, 3->2->3
    Then the result should be, in any order:
      | e                                                       |
      | LIST[[{dst:2,src:3}], [{dst:3,src:2}]]                  |
      | LIST[[{dst:1,src:3}], [{dst:2,src:1}], [{dst:3,src:2}]] |
      | LIST[[{dst:2,src:1}], [{dst:3,src:2}], [{dst:1,src:3}]] |
      | LIST[[{dst:3,src:2}], [{dst:1,src:3}], [{dst:2,src:1}]] |
      | LIST[[{dst:3,src:2}], [{dst:2,src:3}]]                  |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH SIMPLE (v0:Person)-[e:FOLLOWS]->{1,10}(v1:Person)
      FILTER where v1.id = v0.id
      RETURN e
      """
    # 1->2->3->1, 2->3->2, 2->3->1->2, 3->1->2->3, 3->2->3
    Then the result should be, in any order:
      | e                                                       |
      | LIST[[{dst:2,src:3}], [{dst:3,src:2}]]                  |
      | LIST[[{dst:1,src:3}], [{dst:2,src:1}], [{dst:3,src:2}]] |
      | LIST[[{dst:2,src:1}], [{dst:3,src:2}], [{dst:1,src:3}]] |
      | LIST[[{dst:3,src:2}], [{dst:1,src:3}], [{dst:2,src:1}]] |
      | LIST[[{dst:3,src:2}], [{dst:2,src:3}]]                  |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH ACYCLIC (v0:Person)-[:FOLLOWS]->{1,10}(v1:Person)
      FILTER where v1.id = v0.id
      RETURN count(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 0   |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v0:Person{id:1})-[e:FOLLOWS]->{1,6}(v1:Person{id:4})
      RETURN e
      """
    # 1->2->4, 1->2->3->2->4, 1->2->3->1->2->4, 1->2->3->2->3->2->4,
    Then the result should be, in any order:
      | e                                                                                                          |
      | LIST[[{dst:2,src:1}], [{dst:3,src:2}], [{dst:2,src:3}], [{dst:4,src:2}]]                                   |
      | LIST[[{dst:2,src:1}], [{dst:4,src:2}]]                                                                     |
      | LIST[[{dst:2,src:1}], [{dst:3,src:2}], [{dst:1,src:3}], [{dst:2,src:1}], [{dst:4,src:2}]]                  |
      | LIST[[{dst:2,src:1}], [{dst:3,src:2}], [{dst:2,src:3}], [{dst:3,src:2}], [{dst:2,src:3}], [{dst:4,src:2}]] |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH WALK (v0:Person{id:1})-[e:FOLLOWS]->{1,6}(v1:Person{id:4})
      RETURN e
      """
    Then the result should be, in any order:
      | e                                                                                                          |
      | LIST[[{dst:2,src:1}], [{dst:3,src:2}], [{dst:2,src:3}], [{dst:4,src:2}]]                                   |
      | LIST[[{dst:2,src:1}], [{dst:4,src:2}]]                                                                     |
      | LIST[[{dst:2,src:1}], [{dst:3,src:2}], [{dst:1,src:3}], [{dst:2,src:1}], [{dst:4,src:2}]]                  |
      | LIST[[{dst:2,src:1}], [{dst:3,src:2}], [{dst:2,src:3}], [{dst:3,src:2}], [{dst:2,src:3}], [{dst:4,src:2}]] |

  Scenario: Scan Edge
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v1)-[e:KNOWS]->(v2:Person)
      RETURN e.creationDate AS knowsDate
      """
    Then the result should be, in any order:
      | knowsDate                             |
      | DATETIME '2021-01-01T10:00:40.213000' |
      | DATETIME '2021-01-01T10:00:40.213000' |
      | DATETIME '2021-01-01T10:00:40.213000' |

  Scenario: Optional Match
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v1)-[e:KNOWS]->(v2:Person)
      OPTIONAL MATCH (v2)-[e2:IS_LOCATED_IN]->(v3:City)
      RETURN v2.id, v3.name
      """
    Then the result should be, in any order:
      | v2.id | v3.name    |
      | 1     | "Beijing"  |
      | 2     | "Shanghai" |
      | 3     | "Hangzhou" |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v1)-[e:KNOWS]->(v2:Person)
      OPTIONAL MATCH (v3 WHERE v3.id = 1)-[e2:IS_LOCATED_IN]->(v4:City)
      RETURN DISTINCT v2.id, v4.name
      """
    Then the result should be, in any order:
      | v2.id | v4.name   |
      | 1     | "Beijing" |
      | 2     | "Beijing" |
      | 3     | "Beijing" |
    When executing query:
      """
      USE #analytic_ldbc
      OPTIONAL MATCH (v:Person{firstName:"not exist"})
      RETURN v.id AS b
      """
    Then the result should be, in any order:
      | b    |
      | NULL |
    # edge with non-exist prop value
    When executing query:
      """
      USE #analytic_ldbc
      OPTIONAL MATCH ()-[e:STUDY_AT{classYear:-1}]-()
      RETURN e.classYear AS b
      """
    Then the result should be, in any order:
      | b    |
      | NULL |
    When executing query:
      """
      USE #analytic_ldbc
      OPTIONAL MATCH p = (v:Person{firstName:"not exist"})-[e:KNOWS]->(v2:Person)
      RETURN length(p) as len
      """
    Then the result should be, in any order:
      | len  |
      | NULL |
    When executing query:
      """
      USE #analytic_ldbc
      LET a = 1
      OPTIONAL MATCH (v:Person{firstName:"not exist"})
      RETURN a, v.id AS b
      """
    Then the result should be, in any order:
      | a | b    |
      | 1 | NULL |
    When executing query:
      """
      USE #analytic_ldbc
      LET a = 1
      OPTIONAL MATCH (v:Not_Exist_Label)
      RETURN a, v.id AS b
      """
    Then an Error should be raised: "[NS228]: node label `Not_Exist_Label` not found in graph type `ldbc_type`"
    # GetDay function will be pushed down to storage side
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Person{id:2})
      RETURN v.birthday.day AS day
      """
    Then the result should be, in any order:
      | day |
      | 25  |
    When executing query:
      """
      USE #analytic_ldbc
      FOR i IN LIST[abs(1), abs(2), abs(3)]
      OPTIONAL MATCH (v:Person{firstName:"not exist"})
      RETURN i, v.id AS b
      """
    Then the result should be, in any order:
      | i | b    |
      | 1 | NULL |
      | 2 | NULL |
      | 3 | NULL |
    When executing query:
      """
      USE #analytic_ldbc
      OPTIONAL MATCH (v:Person{id:3})
      OPTIONAL MATCH (v:Person{firstName:"not exist"})
      RETURN v.lastName AS name
      """
    Then the result should be, in any order:
      | name  |
      | "Yao" |
    When executing query:
      """
      USE #analytic_ldbc
      OPTIONAL MATCH (v:Person{id:3})
      MATCH (v:Person{firstName:"not exist"})
      RETURN v.lastName AS name
      """
    Then the result should be, in any order:
      | name |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v1:City{id:1})
      OPTIONAL MATCH (v2:City{id:10000})
      RETURN v1, v2
      """
    Then the result should be, in any order:
      | v1                                                            | v2   |
      | ({id:1,kind:"city",name:"Beijing",url:"https://beijing.com"}) | null |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v1:City{id:1})
      OPTIONAL MATCH (v2:Person{id:10000})
      RETURN SAME(v1, v2)
      """
    Then an Error should be raised: "[22004]: Null value not allowed in `same predicate`, in expression: same(v1, v2)"

  Scenario: Use Group Variable
    When executing query:
      """
      USE #analytic_ldbc MATCH TRAIL (v0:Person)<-[e1:KNOWS]->{1, 2}(v2:Person) return e1
      """
    Then the result should be, in any order:
      | e1                                                                                          |
      | LIST [ [{creationDate: DATETIME "2021-01-01T10:00:40.213000", vec: VECTOR [4.0,5.0,6.0]}] ] |
      | LIST [ [{creationDate: DATETIME "2021-01-01T10:00:40.213000", vec: VECTOR [4.0,5.0,6.0]}] ] |
      | LIST [ [{creationDate: DATETIME "2021-01-01T10:00:40.213000", vec: VECTOR [7,8,9]}] ]       |
      | LIST [ [{creationDate: DATETIME "2021-01-01T10:00:40.213000", vec: VECTOR [7,8,9]}] ]       |
      | LIST [ [{creationDate: DATETIME "2021-01-01T10:00:40.213000", vec: VECTOR [1,2,3]}] ]       |
      | LIST [ [{creationDate: DATETIME "2021-01-01T10:00:40.213000", vec: VECTOR [1,2,3]}] ]       |

  Scenario: Node Join
    When executing query:
      """
      USE #analytic_ldbc MATCH (v1)-[e1]-(v1)-[e2]->(v3) where v1.id =1 limit 1 return v1.id
      """
    Then the result should be, in any order:
      | v1.id |
      | 1     |

  Scenario: Edge Join
    When executing query:
      """
      USE #analytic_ldbc
      MATCH REPEATABLE ELEMENTS (v1)-[e:KNOWS]->(v2:Person)
      OPTIONAL MATCH (v2)-[e:KNOWS]->(v3)
      RETURN v2.id, v3.name
      """
    Then an Error should be raised: "[NS230]: property `name` not found in NODE<(Person)>"

  Scenario: shortest path
    When executing query:
      """
      USE #analytic_ldbc
      MATCH p = ALL SHORTEST (v:Person{id:2})-[e:KNOWS]->{0,1}(v2:Person{id:2})
      RETURN length(p) AS len
      """
    Then the result should be, in any order:
      | len |
      | 0   |

  Scenario: variable length pattern
    When executing query:
      """
      USE #analytic_ldbc
      MATCH TRAIL (v:Person)-[e:!FOLLOWS]->{2,5}(v2)
      RETURN count(v2) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 711 |
    # {,5} means {0,5}
    When executing query:
      """
      USE #analytic_ldbc
      MATCH DIFFERENT EDGES (v:Person)-[e:!FOLLOWS]->{,5}(v2)
      RETURN count(v2) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 736 |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH TRAIL (v:Person)-[e:!FOLLOWS]->{3,3}(v2)
      RETURN count(v2) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 114 |
    # {3} means {3,3}
    When executing query:
      """
      USE #analytic_ldbc
      MATCH TRAIL (v:Person)-[e:!FOLLOWS]->{3}(v2)
      RETURN count(v2) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 114 |
    # {1,} means {1,+∞}
    When executing query:
      """
      USE #analytic_ldbc
      MATCH TRAIL (v:Person)-[e:KNOWS]->{1,}(v2:Person)
      RETURN count(v2) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 3   |
    # {,} means {0,+∞}
    When executing query:
      """
      USE #analytic_ldbc
      MATCH TRAIL (v:Person)-[e:!FOLLOWS]->{,}(v2)
      RETURN count(v2) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt  |
      | 1801 |
    # * means {0,+∞}
    When executing query:
      """
      USE #analytic_ldbc
      MATCH TRAIL (v:Person)-[e:!FOLLOWS]->*(v2)
      RETURN count(v2) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt  |
      | 1801 |
    # + means {1,+∞}
    When executing query:
      """
      USE #analytic_ldbc
      MATCH TRAIL (v:Person)-[e:!FOLLOWS]->+(v2)
      RETURN count(v2) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt  |
      | 1797 |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:City|Message&!Post|Person)
      RETURN case when v.kind="city" then "city" else v.content end AS kind
      """
    Then the result should be, in any order:
      | kind       |
      | "city"     |
      | "comment4" |
      | NULL       |
      | "city"     |
      | NULL       |
      | "city"     |
      | "comment2" |
      | "city"     |
      | "city"     |
      | "comment1" |
      | NULL       |
      | NULL       |
      | "city"     |
      | "comment3" |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:%)
      RETURN count(v) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 34  |

  Scenario: group variable without labels
    When executing query:
      """
      USE #analytic_ldbc
      MATCH TRAIL (v:Person)-[e:!FOLLOWS]->{1,2}(v2)
      RETURN count(v2) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 75  |

  Scenario: dedup pk scan
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Person)
      WHERE v.id in list[2, 2, 2]
      RETURN v.id as vid
      """
    Then the result should be, in any order:
      | vid |
      | 2   |

  Scenario: empty node filter
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Person{id: 1})-[:KNOWS]->({})
      LIMIT 1
      RETURN count(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 1   |

  Scenario: empty edge filter
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Person{id: 1})-[:KNOWS{}]->()
      LIMIT 1
      RETURN count(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 1   |

  Scenario: join on empty node set
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Person{id:100})
      MATCH TRAIL (t:Person{id: 2})-[]->{1, 2}(v)-[]->(t)
      LIMIT 1
      RETURN v
      """
    Then the result should be, in any order:
      | v |

  # Fix https://github.com/vesoft-inc/nebula-ng/issues/2383
  Scenario: Match node and edge without label
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v)-[e:!FOLLOWS]-() ORDER BY v.kind,v.id LIMIT 20 return DISTINCT v
      """
    Then the result should be, in order:
      | v                                                               |
      | ({id:1,kind:"1",name:"org1",url:"https://org1.com"})            |
      | ({id:2,kind:"2",name:"org2",url:"https://org2.com"})            |
      | ({id:3,kind:"3",name:"org3",url:"https://org3.com"})            |
      | ({id:1,kind:"city",name:"Beijing",url:"https://beijing.com"})   |
      | ({id:2,kind:"city",name:"Shanghai",url:"https://shanghai.com"}) |
      | ({id:3,kind:"city",name:"Hangzhou",url:"https://hangzhou.com"}) |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Person)-[e:!FOLLOWS]->()
      RETURN e.vec AS vec
      """
    Then the result should be, in any order:
      | vec                    |
      | VECTOR [1.0, 2.0, 3.0] |
      | VECTOR [4.0, 5.0, 6.0] |
      | VECTOR [7.0, 8.0, 9.0] |
      | null                   |
      | null                   |
      | null                   |
      | null                   |
      | null                   |
      | null                   |
      | null                   |
      | null                   |
      | null                   |
      | null                   |
      | null                   |
      | null                   |
      | null                   |
      | null                   |
      | null                   |
      | null                   |
      | null                   |
      | null                   |

  Scenario: Pattern contains non-exisistent schema
    # Node with non-exisistent label
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:not_exists_label) WHERE v.id = 1 RETURN v.id AS vid
      """
    Then an Error should be raised: "[NS228]: node label `not_exists_label` not found in graph type `ldbc_type`"
    # Edge with non-exisistent type
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Person)-[e:not_exists_type]->(v2:Person) RETURN v.id AS vid
      """
    Then an Error should be raised: "[NS228]: edge label `not_exists_type` not found in graph type `ldbc_type`"
    # Node with non-exisistent property
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Person) WHERE v.not_exists_property = 1 RETURN v.id AS vid
      """
    Then an Error should be raised: "[NS230]: property `not_exists_property` not found in NODE<(Person)>"
    # Edge with non-exisistent property
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Person)-[e:KNOWS]-(v2:Person) WHERE e.not_exists_property = 1 RETURN v.id AS vid
      """
    Then an Error should be raised: "[NS230]: property `not_exists_property` not found in EDGE<(Person)-[KNOWS]->(Person)>"
    # Return non-exisistent property
    # Fix https://github.com/vesoft-inc/nebula-ng/issues/2642
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Person) RETURN v.not_exists_property AS vid
      """
    Then an Error should be raised: "[NS230]: property `not_exists_property` not found in NODE<(Person)>"
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Person)-[e]-(v2:Person) RETURN e.not_exists_property AS vid
      """
    Then an Error should be raised: "[NS230]: property `not_exists_property` not found in EDGE<(Person)-[FOLLOWS]->(Person), (Person)-[KNOWS]->(Person)>"

  Scenario: ElementPatternPredicate
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v1:Person WHERE v0.age > 0)
      RETURN v1
      """
    Then an Error should be raised: "[42N18]: Invalid syntax, variable `v0` not defined"
    When executing query:
      """
      USE #analytic_ldbc
      MATCH DIFFERENT RELATIONSHIP BINDINGS (v0:Person)-[e0:KNOWS]->(v1:Person WHERE v0.id > 2)
      RETURN v1.id
      """
    Then the result should be, in any order:
      | v1.id |
      | 3     |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH REPEATABLE ELEMENT BINDINGS (v0:Person WHERE v0.id > 2)-[e0:KNOWS]->(v1:Person)
      RETURN v1.id
      """
    Then the result should be, in any order:
      | v1.id |
      | 3     |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH DIFFERENT EDGE BINDINGS (v0:Person)-[e0:KNOWS]->(v1:Person) WHERE v0.id > 2
      RETURN v1.id
      """
    Then the result should be, in any order:
      | v1.id |
      | 3     |
    When executing query:
      """
      USE #analytic_ldbc
      LET id=3
      MATCH (v1:Person WHERE v1.id = id)
      RETURN v1.id, v1.firstName
      """
    Then the result should be, in any order:
      | v1.id | v1.firstName |
      | 3     | "Ming"       |
    When executing query:
      """
      USE #analytic_ldbc
      LET id=3
      MATCH (v1:Person{id: id})
      RETURN v1.id, v1.firstName
      """
    Then the result should be, in any order:
      | v1.id | v1.firstName |
      | 3     | "Ming"       |

  Scenario: var ref from previous statement
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Person{id: 2})
      MATCH (t:Person)
      WHERE v.id = t.id
      RETURN v.id as vid, t.id as tid
      """
    Then the result should be, in any order:
      | vid | tid |
      | 2   | 2   |
    # pruner should not prune v.id
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Person{id: 2})
      MATCH (t:Person)
      WHERE v.id = t.id
      RETURN t.id as tid
      """
    Then the result should be, in any order:
      | tid |
      | 2   |
    # `Filter c.extent = 8` will generate a filter as parent of DelimProduce
    # We should gurantee that DelimScan is pruned before DelimProduce in
    # this case
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (c:Comment{id: 1})
      OPTIONAL MATCH (t:Comment{id: 1})
      WHERE c.content = "comment1"
      FILTER  c.extent = 8
      RETURN t.id as tid
      """
    Then the result should be, in any order:
      | tid |
      | 1   |
    # see https://github.com/vesoft-inc/nebula-ng/issues/3473 for details
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (p:Person)-[:FOLLOWS]->(f:Person{id: 4})
      RETURN f.id as fid
      """
    Then the result should be, in any order:
      | fid |
      | 4   |

  Scenario: labeled predicate
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v)
      WHERE v IS LABELED Comment|Tag
      RETURN labels(v)
      """
    Then the result should be, in any order:
      | labels(v)                   |
      | LIST ["Tag"]                |
      | LIST ["Comment", "Message"] |
      | LIST ["Tag"]                |
      | LIST ["Comment", "Message"] |
      | LIST ["Comment", "Message"] |
      | LIST ["Tag"]                |
      | LIST ["Tag"]                |
      | LIST ["Comment", "Message"] |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v)
      WHERE v IS LABELED Comment|Tag&!Message
      RETURN labels(v)
      """
    Then the result should be, in any order:
      | labels(v)                   |
      | LIST ["Tag"]                |
      | LIST ["Comment", "Message"] |
      | LIST ["Tag"]                |
      | LIST ["Comment", "Message"] |
      | LIST ["Comment", "Message"] |
      | LIST ["Tag"]                |
      | LIST ["Tag"]                |
      | LIST ["Comment", "Message"] |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v)
      WHERE v IS LABELED (Comment|Tag)&!Message
      RETURN labels(v)
      """
    Then the result should be, in any order:
      | labels(v)    |
      | LIST ["Tag"] |
      | LIST ["Tag"] |
      | LIST ["Tag"] |
      | LIST ["Tag"] |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v)
      FILTER WHERE v IS LABELED (Comment|Tag)&!Message
      RETURN v IS LABELED (Comment|Tag)&!Message AS isLabel
      """
    Then the result should be, in any order:
      | isLabel |
      | true    |
      | true    |
      | true    |
      | true    |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v)
      FILTER WHERE v IS LABELED (Comment|Tag)&!Message
      RETURN v IS LABELED !Comment&!Tag | Message AS isNotLabel
      """
    Then the result should be, in any order:
      | isNotLabel |
      | false      |
      | false      |
      | false      |
      | false      |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Person | Comment)
      FOR i IN [Record{a:v IS LABELED Person, b:labels(v)}]
      LET isMessage = v IS LABELED Message
      RETURN i.a AS isPerson, i.b AS labels, isMessage, [v:Person, v is labeled Comment] AS l
      """
    Then the result should be, in any order:
      | isPerson | labels                       | isMessage | l                  |
      | true     | LIST  ["Person"]             | false     | LIST [true, false] |
      | false    | LIST  ["Comment", "Message"] | true      | LIST [false, true] |
      | false    | LIST  ["Comment", "Message"] | true      | LIST [false, true] |
      | false    | LIST  ["Comment", "Message"] | true      | LIST [false, true] |
      | true     | LIST ["Person"]              | false     | LIST [true, false] |
      | true     | LIST  ["Person"]             | false     | LIST [true, false] |
      | false    | LIST  ["Comment", "Message"] | true      | LIST [false, true] |
      | true     | LIST  ["Person"]             | false     | LIST [true, false] |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v WHERE v IS LABELED (Comment|Tag)&!Message)
      RETURN v IS LABELED !Comment&!Tag | Message AS isNotLabel
      """
    Then the result should be, in any order:
      | isNotLabel |
      | false      |
      | false      |
      | false      |
      | false      |
    When executing query:
      """
      USE #analytic_ldbc
      LET v = 1
      FILTER WHERE v IS LABELED (Comment|Tag)&!Message
      RETURN v IS LABELED !Comment&!Tag | Message AS isNotLabel
      """
    Then an Error should be raised: "[NS210]: Invalid label expression input: `v`, expect NODE or EDGE type but got `INT32`"

  Scenario: Unsupported patterns
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v)(v1)(v2)
      RETURN v
      """
    Then an Error should be raised: "[NS111]: Pattern not supported: `(v1)`"
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v)?-[e]->(v2)
      RETURN v
      """
    Then an Error should be raised: "[NT000]: Questioned path pattern is not supported yet"
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v)-[e]->?(v2) RETURN v
      """
    Then an Error should be raised: "[NT000]: Questioned path pattern is not supported yet"
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v)->((v))
      RETURN v
      """
    Then an Error should be raised: "[NT000]: Parenthesized path pattern is not supported yet"
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v)->((a)->(b))
      RETURN v
      """
    Then an Error should be raised: "[NT000]: Parenthesized path pattern is not supported yet"
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v)->(){3}
      RETURN v
      """
    Then an Error should be raised: "[NS111]: Pattern not supported: `(){3}`"
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v){1,3}
      RETURN v
      """
    Then an Error should be raised: "[NS111]: Pattern not supported: `(v){1,3}`"
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v)->(v1)(v2)~[]~
      RETURN v
      """
    Then an Error should be raised: "[NS111]: Pattern not supported: `(v2)`"
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v)~(v1)(v2)~[]~
      RETURN v
      """
    Then an Error should be raised: "[NS111]: Pattern not supported: `(v2)`"
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v)->~[]~(v1)->~[]~(v2)
      RETURN v
      """
    Then an Error should be raised: "[NS111]: Pattern not supported: `~[]~`"
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v)->{1,3}~[]~
      RETURN v
      """
    Then an Error should be raised: "[NS111]: Pattern not supported: `~[]~`"
    When executing query:
      """
      USE #analytic_ldbc
      MATCH p=(v{id:2})-[e:KNOWS]->{1}(v1) RETURN p.prop
      """
    Then an Error should be raised: "[NT206]: ValueType PATH can't get property"
    When executing query:
      """
      USE #analytic_ldbc
      MATCH ()-[e:KNOWS]->()
      MATCH ()-[e:KNOWS]->{1}(t)
      return t
      """
    Then an Error should be raised: "[NS008]: Semantic error, variable e cannot be defined as both group variable and EDGE<(Person)-[KNOWS]->(Person)>"
    When executing query:
      """
      USE #analytic_ldbc
      MATCH ()-[e]->{1}()
      MATCH ()-[e]->{1}(t)
      return t
      """
    Then an Error should be raised: "[NS009]: Semantic error, group variable redefinition e"
    When executing query:
      """
      USE #analytic_ldbc
      LET e = 1
      MATCH ()-[e]->{1}(t)
      return t
      """
    Then an Error should be raised: "[NS008]: Semantic error, variable e cannot be defined as both group variable and INT32"
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Person) WHERE v RETURN v LIMIT 1
      """
    Then an Error should be raised: "[NS005]: Semantic error, filter clause must be type of bool"
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Person where v) RETURN v LIMIT 1
      """
    Then an Error should be raised: "[NS005]: Semantic error, filter clause must be type of bool"
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Person where v)(n) RETURN v LIMIT 1
      """
    Then an Error should be raised: "[NS111]: Pattern not supported: `(v:Person WHERE v)(n)`"
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Person)() RETURN v LIMIT 1
      """
    Then an Error should be raised: "[NS111]: Pattern not supported: `(v:Person)()`"
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Person where v)-> RETURN v LIMIT 1
      """
    Then an Error should be raised: "[NS111]: Pattern not supported: `(v:Person WHERE v)-[]->`"
    When executing query:
      """
      USE #analytic_ldbc
      MATCH -[e:KNOWS]- RETURN v LIMIT 1
      """
    Then an Error should be raised: "[NS111]: Pattern not supported: `-[e:KNOWS]-`"
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v)~[]~ RETURN v LIMIT 1
      """
    Then an Error should be raised: "[NS111]: Pattern not supported: `(v)~[]~`"
    When executing query:
      """
      USE #analytic_ldbc
      MATCH (v:Person where v),->(n) RETURN v LIMIT 1
      """
    Then an Error should be raised: "[NS111]: Pattern not supported: `-[]->(n)`"
    When executing query:
      """
      USE #analytic_ldbc
      MATCH -* RETURN v LIMIT 1
      """
    Then an Error should be raised: "[NS111]: Pattern not supported: `-[]-{0,}`"
    When executing query:
      """
      USE #analytic_ldbc
      MATCH p=(v{id:318})-[:WORK_AT]- RETURN v LIMIT 1
      """
    Then an Error should be raised: "[NS111]: Pattern not supported: `(v WHERE v.id = 318)-[:WORK_AT]-`"
    # issue: https://github.com/vesoft-inc/nebula-ng/issues/4113
    When executing query:
      """
      USE #analytic_ldbc
      MATCH pth = (p1:Person)-[e1:KNOWS]->{1, 1}(p2:Person)-[e2:STUDY_AT]->{1, 1}()
      RETURN COUNT(pth) AS total GROUP BY ()
      """
    Then the result should be, in any order:
      | total |
      | 3     |
    When executing query:
      """
      USE #analytic_ldbc
      MATCH pth = (p1:Person{id: 1})-[:KNOWS{creationDate:date('2022-01-02')}]->{0, 1}(p2:Person)
      RETURN COUNT(distinct pth) as total GROUP BY()
      """
    Then the result should be, in any order:
      | total |
      | 1     |
    When executing query:
      """
      EXPLAIN
      USE #analytic_ldbc
      MATCH ()-[e]->*()
      RETURN e
      """
    Then an Error should be raised: "[NS219]: Unbounded quantifiers in non-restrictive and non-selective path patterns may lead to infinite result sets. Consider using restrictive path modes (e.g., 'trail'), selective path search prefixes (e.g., 'any shortest'), 'different edges' match mode, or setting an upper bound"
    When executing query:
      """
      EXPLAIN
      USE #analytic_ldbc
      MATCH TRAIL (a)-[e]->(b)-[e]->()
      RETURN a, b
      """
    Then an Error should be raised: "[NS221]: Repeated edge variable in a path pattern restricted by TRAIL mode will lead to no results"
    When executing query:
      """
      EXPLAIN
      USE #analytic_ldbc
      MATCH ACYCLIC (a)-[]->(b)-[]->(a)-[]->(c)
      RETURN a, b, c
      """
    Then an Error should be raised: "[NS222]: Repeated node variable in a path pattern restricted by ACYCLIC mode will lead to no results"
    When executing query:
      """
      EXPLAIN
      USE #analytic_ldbc
      MATCH ACYCLIC (a)-[]->(b)-[]->(a)
      RETURN a, b
      """
    Then an Error should be raised: "[NS222]: Repeated node variable in a path pattern restricted by ACYCLIC mode will lead to no results"
    When executing query:
      """
      EXPLAIN
      USE #analytic_ldbc
      MATCH SIMPLE (a)-[]->(b)-[]->(a)
      RETURN a, b
      """
    Then the execution should be successful
    When executing query:
      """
      EXPLAIN
      USE #analytic_ldbc
      MATCH SIMPLE (a)-[]->(b)-[]->(a)-[]->(c)
      RETURN a, b, c
      """
    Then an Error should be raised: "[NS223]: Repeated node variable in a path pattern restricted by SIMPLE mode will lead to no results unless the repeated node variables are the first and last in the path pattern"
    When executing query:
      """
      EXPLAIN
      USE #analytic_ldbc
      MATCH DIFFERENT EDGES (a)-[e]->(b)-[e]->()
      RETURN a, b
      """
    Then an Error should be raised: "[NS224]: Repeated edge variable in a graph pattern restricted by 'different edges' match mode will lead to no results"
    When executing query:
      """
      EXPLAIN
      USE #analytic_ldbc
      MATCH DIFFERENT EDGES (a)-[e]->(b), (c)-[e]->(d)
      RETURN a, b, c, d
      """
    Then an Error should be raised: "[NS224]: Repeated edge variable in a graph pattern restricted by 'different edges' match mode will lead to no results"
    When executing query:
      """
      EXPLAIN
      USE #analytic_ldbc
      MATCH DIFFERENT EDGES ANY SHORTEST (a)-[e]->*(b), ANY SHORTEST (c)-[f]->+(d)
      RETURN a, b, c, d
      """
    Then an Error should be raised: "[NS225]: In 'different edges' match mode, if the graph pattern contains a selective path pattern, it must not contain any other patterns"
    When executing query:
      """
      EXPLAIN
      USE #analytic_ldbc
      MATCH DIFFERENT EDGES ANY SHORTEST (a)-[e]->*(b), (c)-[f]->(d)
      RETURN a, b, c, d
      """
    Then an Error should be raised: "[NS225]: In 'different edges' match mode, if the graph pattern contains a selective path pattern, it must not contain any other patterns"

  # fix https://github.com/vesoft-inc/nebula-ng/issues/5759
  Scenario: path variable should be count as local def
    When executing query:
      """
      EXPLAIN
      USE #analytic_ldbc
      FOR
          ua0 IN RANGE(0, 1)
      RETURN
          ua0
      NEXT
      USE #analytic_ldbc
      MATCH
          p0 = (v1)
      WHERE
          v1.id > 0 and LENGTH(p0) > 0
      return v1
      """
    Then the execution should be successful

  Scenario: match label filter
    # no is_labeled filter should exist in the query below:
    When executing query:
      """
      EXPLAIN
      USE #analytic_ldbc
      MATCH (m), (m)<-[:LIKES]-(p@Person) RETURN p.id
      """
    Then the execution should be successful
    # all property of m should be pruned
    When executing query:
      """
      EXPLAIN
      USE #analytic_ldbc
      MATCH (m:Message)
      MATCH (m:Comment)<-[:LIKES]-(p@Person) RETURN p.id
      """
    Then the execution should be successful

  Scenario: variable conflict error
    # node/edge conflict
    When executing query:
      """
      USE #analytic_ldbc MATCH (x)-[x]-() RETURN x
      """
    Then an Error should be raised: "[42N23]: Invalid syntax, redefined variable: `x` with conflict type"
    # node/path conflict
    When executing query:
      """
      USE #analytic_ldbc MATCH x=(x)-[]-() RETURN x
      """
    Then an Error should be raised: "[42N22]: Invalid syntax, redefined variable: `x`"
    When executing query:
      """
      USE #analytic_ldbc MATCH x=(x)-[]->{1,3}()-[]-() RETURN x
      """
    Then an Error should be raised: "[42N22]: Invalid syntax, redefined variable: `x`"
    When executing query:
      """
      USE #analytic_ldbc MATCH x=(x)|()-[]-() RETURN x
      """
    Then an Error should be raised: "[NT104]: Not supported path pattern with more than one path term"
    When executing query:
      """
      USE #analytic_ldbc MATCH (x),x=()-[]-() RETURN x
      """
    Then an Error should be raised: "[42N22]: Invalid syntax, redefined variable: `x`"
    When executing query:
      """
      USE #analytic_ldbc MATCH (x=(x)|()-[]-()) RETURN x
      """
    Then an Error should be raised: "[NT104]: Not supported path pattern with more than one path term"
    When executing query:
      """
      USE #analytic_ldbc MATCH (x),(x=()-[]-()) RETURN x
      """
    Then an Error should be raised: "[NT000]: Parenthesized path pattern is not supported yet"
    # edge/path conflict
    When executing query:
      """
      USE #analytic_ldbc MATCH x=()-[x]-() RETURN x
      """
    Then an Error should be raised: "[42N22]: Invalid syntax, redefined variable: `x`"
    When executing query:
      """
      USE #analytic_ldbc MATCH x=()|()-[x]-() RETURN x
      """
    Then an Error should be raised: "[NT104]: Not supported path pattern with more than one path term"
    When executing query:
      """
      USE #analytic_ldbc MATCH (),x=()-[x]-() RETURN x
      """
    Then an Error should be raised: "[42N22]: Invalid syntax, redefined variable: `x`"

  Scenario: implicit join error
    # Conditional/Uncondition join
    When executing query:
      """
      USE #analytic_ldbc MATCH (x)?->(x) RETURN x
      """
    Then an Error should be raised: "[NT000]: Questioned path pattern is not supported yet"
    When executing query:
      """
      USE #analytic_ldbc MATCH (x)?->()|(x) RETURN x
      """
    Then an Error should be raised: "[NT000]: Questioned path pattern is not supported yet"
    When executing query:
      """
      USE #analytic_ldbc MATCH (x)?->(),(x) RETURN x
      """
    Then an Error should be raised: "[NT000]: Questioned path pattern is not supported yet"
    When executing query:
      """
      USE #analytic_ldbc MATCH (x)->(y)|(x)->(z)|(y) RETURN x
      """
    Then an Error should be raised: "[NT104]: Not supported path pattern with more than one path term"
    When executing query:
      """
      USE #analytic_ldbc MATCH (x)->(y)|(x)->(z),(y) RETURN x
      """
    Then an Error should be raised: "[NT104]: Not supported path pattern with more than one path term"
    When executing query:
      """
      USE #analytic_ldbc MATCH (x)?->(p=(x)) RETURN x
      """
    Then an Error should be raised: "[NT000]: Questioned path pattern is not supported yet"
    When executing query:
      """
      USE #analytic_ldbc MATCH (p=(x)?->())|(x) RETURN x
      """
    Then an Error should be raised: "[NT000]: Questioned path pattern is not supported yet"
    When executing query:
      """
      USE #analytic_ldbc MATCH (x)?->(),((x)) RETURN x
      """
    Then an Error should be raised: "[NT000]: Questioned path pattern is not supported yet"
    When executing query:
      """
      USE #analytic_ldbc MATCH (x)->(y)|(x)->(z)|(p=(y)) RETURN x
      """
    Then an Error should be raised: "[NT000]: Parenthesized path pattern is not supported yet"
    When executing query:
      """
      USE #analytic_ldbc MATCH (x)->(y)|(p=(x)->(z)),(y) RETURN x
      """
    Then an Error should be raised: "[NT000]: Parenthesized path pattern is not supported yet"
    # Conditional/Group join
    When executing query:
      """
      USE #analytic_ldbc MATCH (x)?->(x){1,3} RETURN x
      """
    Then an Error should be raised: "[NT000]: Questioned path pattern is not supported yet"
    When executing query:
      """
      USE #analytic_ldbc MATCH (x)?->()|(x){1} RETURN x
      """
    Then an Error should be raised: "[NT000]: Questioned path pattern is not supported yet"
    When executing query:
      """
      USE #analytic_ldbc MATCH (x)?->(),(x){,} RETURN x
      """
    Then an Error should be raised: "[NT000]: Questioned path pattern is not supported yet"
    When executing query:
      """
      USE #analytic_ldbc MATCH (x)?->()|(x){1} RETURN x
      """
    Then an Error should be raised: "[NT000]: Questioned path pattern is not supported yet"
    When executing query:
      """
      USE #analytic_ldbc MATCH (x)?->(),(x){,} RETURN x
      """
    Then an Error should be raised: "[NT000]: Questioned path pattern is not supported yet"
    When executing query:
      """
      USE #analytic_ldbc MATCH (x)->(y)|(x)->(z)|(y){1} RETURN x
      """
    Then an Error should be raised: "[NT104]: Not supported path pattern with more than one path term"
    When executing query:
      """
      USE #analytic_ldbc MATCH (x)->(y)|(x)->(z),(y){,} RETURN x
      """
    Then an Error should be raised: "[NT104]: Not supported path pattern with more than one path term"
    When executing query:
      """
      USE #analytic_ldbc MATCH ((x)?)->(x){1,3} RETURN x
      """
    Then an Error should be raised: "[NT000]: Questioned path pattern is not supported yet"
    When executing query:
      """
      USE #analytic_ldbc MATCH (x)?->()|(p=(x){1}) RETURN x
      """
    Then an Error should be raised: "[NT000]: Questioned path pattern is not supported yet"
    When executing query:
      """
      USE #analytic_ldbc MATCH (p1=(x)?->()),p2=(x){,} RETURN x
      """
    Then an Error should be raised: "[NT000]: Questioned path pattern is not supported yet"
    When executing query:
      """
      USE #analytic_ldbc MATCH (p=(x)->(y))|(x)->(z)|(y){1} RETURN x
      """
    Then an Error should be raised: "[NT000]: Parenthesized path pattern is not supported yet"
    When executing query:
      """
      USE #analytic_ldbc MATCH (x)->(y)|(p=(x)->(z)),(y){,} RETURN x
      """
    Then an Error should be raised: "[NT000]: Parenthesized path pattern is not supported yet"
    # Group/Uncondition join
    When executing query:
      """
      USE #analytic_ldbc MATCH (x)->(x){1,3} RETURN x
      """
    Then an Error should be raised: "[NS111]: Pattern not supported: `(x){1,3}`"
    When executing query:
      """
      USE #analytic_ldbc MATCH (x)->()|(x){1} RETURN x
      """
    Then an Error should be raised: "[NT104]: Not supported path pattern with more than one path term"
    When executing query:
      """
      USE #analytic_ldbc MATCH (x)->(),(x){,} RETURN x
      """
    Then an Error should be raised: "[NS111]: Pattern not supported: `(x){0,}`"
    When executing query:
      """
      USE #analytic_ldbc MATCH ((x))->(x){1,3} RETURN x
      """
    Then an Error should be raised: "[NT000]: Parenthesized path pattern is not supported yet"
    When executing query:
      """
      USE #analytic_ldbc MATCH (p=(x)->())|(x){1} RETURN x
      """
    Then an Error should be raised: "[NT000]: Parenthesized path pattern is not supported yet"
    When executing query:
      """
      USE #analytic_ldbc MATCH p1=(x)->(),(p2=(x){,}) RETURN x
      """
    Then an Error should be raised: "[NT000]: Parenthesized path pattern is not supported yet"
