# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: List Function

  Scenario: Subscript
    When executing query:
      """
      LET l = LIST [1, 2, 3]
      RETURN l[0] as a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      value a int8 = 34
      value i int32 = 1
      value j int64 = 2
      LET l = LIST [floor(a-3), a, a+1]
      RETURN l[i] AS a, l[j] AS b, l[::] AS c, abs(a+i-l[j-2]) AS d, l[l[j]] AS e, l[::-2] AS f
      """
    Then the result should be, in any order:
      | a  | b  | c               | d | e    | f            |
      | 34 | 35 | LIST [31,34,35] | 4 | NULL | LIST [35,31] |
    When executing query:
      """
      LET l = LIST [ LIST [1, 2], LIST [3] ]
      RETURN l[1] as a
      """
    Then the result should be, in any order:
      | a        |
      | LIST [3] |
    When executing query:
      """
      LET l = LIST [ RECORD {id: 1, prop: "s1"}, RECORD {id: 5, prop: "s5"} ]
      RETURN l[1] as a
      """
    Then the result should be, in any order:
      | a                          |
      | RECORD {id: 5, prop: "s5"} |
    When executing query:
      """
      LET l = LIST [ RECORD {id: 1, prop: "s1"}, RECORD {id: 5, prop: "s5"} ]
      RETURN (l[1]).prop as a
      """
    Then the result should be, in any order:
      | a    |
      | "s5" |
    When executing query:
      """
      LET l = LIST [1, NULL]
      RETURN l[1] as a
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    When executing query:
      """
      RETURN back(null) as a
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    When executing query:
      """
      RETURN back([1,2.3,null]) as a
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    When executing query:
      """
      RETURN back([null]) as a
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    When executing query:
      """
      RETURN tail(null) as a
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    When executing query:
      """
      RETURN tail([1,2]) as a
      """
    Then the result should be, in any order:
      | a        |
      | LIST [2] |
    When executing query:
      """
      RETURN tail([null]) as a
      """
    Then the result should be, in any order:
      | a       |
      | LIST [] |
    When executing query:
      """
      RETURN tail([null,null,1,2]) as a
      """
    Then the result should be, in any order:
      | a                 |
      | LIST [NULL, 1, 2] |
    When executing query:
      """
      RETURN back([]) as a
      """
    Then an Error should be raised: "[22G0C]: List element error: back() on empty list, in expression: back([])"
    When executing query:
      """
      RETURN tail([]) as a
      """
    Then an Error should be raised: "[22G0C]: List element error: tail() on empty list, in expression: tail([])"

  Scenario: head
    When executing query:
      """
      RETURN head([]) as a
      """
    Then an Error should be raised: "[22G0C]: List element error: head() on empty list, in expression: head([])"
    When executing query:
      """
      RETURN head([1, null, 3]) as a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      RETURN head([null, 2, 3]) as a
      """
    Then the result should be, in any order:
      | a    |
      | NULL |

  Scenario: In List
    When executing query:
      """
      LET l = LIST [1, 2, 3]
      RETURN 1 IN l as a, 4 IN l as b
      """
    Then the result should be, in any order:
      | a    | b     |
      | true | false |
    When executing query:
      """
      LET l = LIST [1, 2, 3]
      RETURN 1 NOT IN l as a, 4 NOT IN l as b
      """
    Then the result should be, in any order:
      | a     | b    |
      | false | true |
    When executing query:
      """
      RETURN 1 IN LIST [1, 4.4] as a
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      RETURN 1 NOT IN LIST [4.4, 1] as a
      """
    Then the result should be, in any order:
      | a     |
      | false |
    When executing query:
      """
      RETURN 1 NOT IN LIST [] as a
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      RETURN 1 IN LIST [] as a
      """
    Then the result should be, in any order:
      | a     |
      | false |
    When executing query:
      """
      RETURN DATE "2023-01-01" in [DATETIME "2023-01-01T00:00:00"] as a
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      RETURN DATE "2023-01-01" in [DATETIME "2023-01-01T00:00:05"] as a
      """
    Then the result should be, in any order:
      | a     |
      | false |
    When executing query:
      """
      RETURN zoned_datetime("2012-03-04T05:06:07.0890", "%Y-%m-%dT%H:%M:%S") in List [zoned_datetime("2012-03-04T05:06:07.0890", "%Y-%m-%dT%H:%M:%S")] AS a
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      RETURN zoned_datetime("2012-03-04T05:06:07.0890", "%Y-%m-%dT%H:%M:%S") not in List [zoned_datetime("2012-03-04T05:06:07.0890", "%Y-%m-%dT%H:%M:%S")] AS a
      """
    Then the result should be, in any order:
      | a     |
      | false |
    When executing query:
      """
      RETURN zoned_time("05:06:07.0890 -0200") in List [zoned_time("05:06:07.0890 -0200")] AS a
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      RETURN zoned_time("05:06:07.0890 -0200") not in List [zoned_time("05:06:07.0890 -0200")] AS a
      """
    Then the result should be, in any order:
      | a     |
      | false |
    When executing query:
      """
      USE ldbc
      MATCH p= TRAIL (v:Person)-[]->{1,2}(:Person) where v.id>2
      RETURN COLLECT(distinct p) AS path_list group by ()
      NEXT
      USE ldbc
      MATCH p = TRAIL (v:Person)-[]->{1,2}(:Person)
      RETURN p not in path_list AS a
      """
    Then the result should be, in any order:
      | a     |
      | true  |
      | true  |
      | false |
      | true  |
      | true  |
      | false |
      | true  |
      | true  |
      | false |
      | true  |
      | false |
      | false |
      | true  |
      | true  |
      | false |
      | true  |
      | false |
      | true  |
      | false |
      | true  |
      | true  |
      | false |
      | true  |
      | false |
      | true  |
      | true  |
      | true  |
      | false |
      | true  |
      | false |
    When executing query:
      """
      USE ldbc
      MATCH p=TRAIL(v:Person)-[]->{1,2}(:Person) where v.id>2
      RETURN COLLECT(distinct p) AS path_list group by ()
      NEXT
      USE ldbc
      MATCH p = TRAIL (v:Person)-[]->{1,2}(:Person)
      RETURN p in path_list AS a
      """
    Then the result should be, in any order:
      | a     |
      | true  |
      | false |
      | true  |
      | false |
      | false |
      | true  |
      | false |
      | true  |
      | false |
      | true  |
      | true  |
      | false |
      | false |
      | false |
      | true  |
      | false |
      | false |
      | true  |
      | false |
      | false |
      | false |
      | true  |
      | false |
      | true  |
      | false |
      | true  |
      | false |
      | false |
      | false |
      | true  |
    When executing query:
      """
      RETURN "str" in [null] AS a
      """
    Then the result should be, in any order:
      | a     |
      | false |

  # FIXME: issue #4903
  # When executing query:
  # """
  # USE ldbc
  # MATCH p= TRAIL (v:Person)-[]->{1,4}() where v.id>2
  # RETURN COLLECT(distinct p) AS path_list group by ()
  # NEXT
  # MATCH p = TRAIL (v:Person)-[:KNOWS]->{1,2}(:Person)
  # RETURN p in path_list AS a
  # """
  # Then the result should be, in any order:
  # | a     |
  Scenario: Concat list
    When executing query:
      """
      RETURN list[1,2,3] || null as a, null || [true] AS b
      """
    Then the result should be, in any order:
      | a    | b    |
      | null | null |
    When executing query:
      """
      RETURN []||[] as a, []||[1,2,3] as b, [1,2,3]||[] as c
      """
    Then the result should be, in any order:
      | a      | b           | c           |
      | LIST[] | LIST[1,2,3] | LIST[1,2,3] |
    When executing query:
      """
      RETURN [list[1,2,3], [3, null]] || [list[4,5,6], [34,45]] as a
      """
    Then the result should be, in any order:
      | a                                                            |
      | LIST  [LIST [1,2,3],LIST [3,null],LIST [4,5,6],LIST [34,45]] |
    When executing query:
      """
      RETURN [true, false, null] || [null,true] AS a
      """
    Then the result should be, in any order:
      | a                                |
      | LIST [true,false,null,null,true] |
    When executing query:
      """
      RETURN [null,null] || [null] || [] ||[null] AS a
      """
    Then the result should be, in any order:
      | a                          |
      | LIST [null,null,null,null] |
    When executing query:
      """
      RETURN [[null,null],[]] || [[]] || [[] ||[null]] AS a
      """
    Then the result should be, in any order:
      | a                                                   |
      | LIST  [LIST [null,null],LIST [],LIST [],LIST[null]] |
    When executing query:
      """
      RETURN [true, false, null] || [null,1] AS a
      """
    Then an Error should be raised: "[NR006]: Resolve function failed: `The list element type mismatch: BOOL vs INT32`"
    When executing query:
      """
      RETURN [1,2,3] || [3.3, 4.4] AS a
      """
    Then the result should be, in any order:
      | a                                   |
      | LIST [1.0M, 2.0M, 3.0M, 3.3M, 4.4M] |
    When executing query:
      """
      RETURN [list[1,2,3.3, null]] || [list[4,5,6], [34,45]] as a
      """
    Then the result should be, in any order:
      | a                                                                                   |
      | LIST [ LIST [1.0M, 2.0M, 3.3M, null], LIST [4.0M, 5.0M, 6.0M], LIST [34.0M, 45.0M]] |

  Scenario: Trim list
    When executing query:
      """
      RETURN trim([1,2,null,3], 0) as a
      """
    Then the result should be, in any order:
      | a                 |
      | LIST [1,2,null,3] |
    When executing query:
      """
      RETURN trim([1,2,null,3], 1) as a
      """
    Then the result should be, in any order:
      | a               |
      | LIST [1,2,null] |
    When executing query:
      """
      RETURN trim([1,2,null,3], 2) as a
      """
    Then the result should be, in any order:
      | a          |
      | LIST [1,2] |
    When executing query:
      """
      RETURN trim([1,2,null,3], 3) as a
      """
    Then the result should be, in any order:
      | a        |
      | LIST [1] |
    When executing query:
      """
      RETURN trim([1,2,null,3], 4) as a
      """
    Then the result should be, in any order:
      | a       |
      | LIST [] |
    When executing query:
      """
      RETURN trim([1,2,null,3], -1) as a
      """
    Then an Error should be raised: "[NQ001]: Trim list out of range, list size: `4`, trim number: `-1`, in expression: trim([1,2,NULL,3], -1)"
    When executing query:
      """
      RETURN trim([1,2,null,3], 5) as a
      """
    Then an Error should be raised: "[NQ001]: Trim list out of range, list size: `4`, trim number: `5`, in expression: trim([1,2,NULL,3], 5)"
    When executing query:
      """
      RETURN trim([list[1.1,2,3], [3.0, null],[4.4,5,6]],2) as a
      """
    Then the result should be, in any order:
      | a                             |
      | LIST   [LIST[1.1M,2.0M,3.0M]] |
    When executing query:
      """
      RETURN trim([true, false, null],null) AS a
      """
    Then the result should be, in any order:
      | a    |
      | null |
    When executing query:
      """
      RETURN trim([null,null] || [null] || [] ||[null],2) AS a
      """
    Then the result should be, in any order:
      | a                |
      | LIST [null,null] |
    When executing query:
      """
      RETURN trim(LIST  [LIST [null,null],LIST [],LIST [],LIST[null]], 1) AS a
      """
    Then the result should be, in any order:
      | a                                        |
      | LIST  [LIST [null,null],LIST [], LIST[]] |
    When executing query:
      """
      RETURN trim(LIST[],0) AS a
      """
    Then the result should be, in any order:
      | a        |
      | LIST  [] |
    When executing query:
      """
      RETURN trim([],[]) AS a
      """
    Then an Error should be raised: "[NR002]: Undefined function: `trim(LIST, LIST)`"
    When executing query:
      """
      RETURN trim([],3.3)
      """
    Then an Error should be raised: "[NR002]: Undefined function: `trim(LIST, DECIMAL)`"

  Scenario: Slice list
    When executing query:
      """
      LET input = range(1,6)
      RETURN list_slice(input, 0, 3) as a, input[0:3] as b, input[:3] AS c
      """
    Then the result should be, in any order:
      | a              | b              | c              |
      | LIST [1,2,3,4] | LIST [1,2,3,4] | LIST [1,2,3,4] |
    When executing query:
      """
      LET input = range(1,6)
      RETURN list_slice(input, 1, 1) as a, input[1:1] as b, input[1:1:1] as c
      """
    Then the result should be, in any order:
      | a        | b        | c        |
      | LIST [2] | LIST [2] | LIST [2] |
    When executing query:
      """
      LET input = range(1,6)
      RETURN list_slice(input, 0, -1) as a, input[0:-1] as b, input[:-1] as c
      """
    Then the result should be, in any order:
      | a                  | b                  | c                  |
      | LIST [1,2,3,4,5,6] | LIST [1,2,3,4,5,6] | LIST [1,2,3,4,5,6] |
    When executing query:
      """
      LET input = range(1,6)
      RETURN list_slice(input, 1, -2) as a, input[1:-2] as b, input[1:-2:1] as c
      """
    Then the result should be, in any order:
      | a              | b              | c              |
      | LIST [2,3,4,5] | LIST [2,3,4,5] | LIST [2,3,4,5] |
    When executing query:
      """
      LET input = range(1,6)
      RETURN list_slice(input, 1, 10) as a, input[1:10] as b, input[1:10:1] as c
      """
    Then the result should be, in any order:
      | a                | b                | c                |
      | LIST [2,3,4,5,6] | LIST [2,3,4,5,6] | LIST [2,3,4,5,6] |
    When executing query:
      """
      LET input = range(1,6)
      RETURN list_slice(input, -3, -1) as a, input[-3:-1] as b, input[-3:-1:1] as c
      """
    Then the result should be, in any order:
      | a            | b            | c            |
      | LIST [4,5,6] | LIST [4,5,6] | LIST [4,5,6] |
    When executing query:
      """
      LET input = range(1,6)
      RETURN list_slice(input, -3, 6) as a, input[-3:6] as b, input[-3:6:1] as c
      """
    Then the result should be, in any order:
      | a            | b            | c            |
      | LIST [4,5,6] | LIST [4,5,6] | LIST [4,5,6] |
    When executing query:
      """
      LET input = range(1,6)
      RETURN list_slice(input, -6, -3) as a, input[-6:-3] as b, input[-6:-3:1] as c
      """
    Then the result should be, in any order:
      | a              | b              | c              |
      | LIST [1,2,3,4] | LIST [1,2,3,4] | LIST [1,2,3,4] |
    When executing query:
      """
      LET input = range(1,6)
      RETURN list_slice(input, -6, 4, 2) as a, input[-6:4:2] as b
      """
    Then the result should be, in any order:
      | a            | b            |
      | LIST [1,3,5] | LIST [1,3,5] |
    When executing query:
      """
      LET input = range(1,6)
      RETURN list_slice(input, -6, -2, 2) as a, input[-6:-2:2] as b
      """
    Then the result should be, in any order:
      | a            | b            |
      | LIST [1,3,5] | LIST [1,3,5] |
    When executing query:
      """
      LET input = range(1,6)
      RETURN list_slice(input, -6, -1, 2) as a, input[-6:-1:2] as b
      """
    Then the result should be, in any order:
      | a            | b            |
      | LIST [1,3,5] | LIST [1,3,5] |
    When executing query:
      """
      LET input = range(1,6)
      RETURN list_slice(input, 5, 1, 2) as a, input[5:1:2] as b
      """
    Then the result should be, in any order:
      | a       | b       |
      | LIST [] | LIST [] |
    When executing query:
      """
      LET input = range(1,6)
      RETURN list_slice(input, 5, 1, -2) as a, input[5:1:-2] as b
      """
    Then the result should be, in any order:
      | a            | b            |
      | LIST [6,4,2] | LIST [6,4,2] |
    When executing query:
      """
      LET input = range(1,6)
      RETURN list_slice(input, 5, 0, -2) as a, input[5:0:-2] as b
      """
    Then the result should be, in any order:
      | a            | b            |
      | LIST [6,4,2] | LIST [6,4,2] |
    When executing query:
      """
      LET input = range(1,6)
      RETURN list_slice(input, 5, -6, -2) as a, input[5:-6:-2] as b
      """
    Then the result should be, in any order:
      | a            | b            |
      | LIST [6,4,2] | LIST [6,4,2] |
    When executing query:
      """
      LET input = range(1,6)
      RETURN input[::] as a, input[::1] as b, input[0::] AS c, input[:7:] AS d, input[::-1] as e
      """
    Then the result should be, in any order:
      | a                  | b                  | c                 | d                 | e                  |
      | LIST [1,2,3,4,5,6] | LIST [1,2,3,4,5,6] | LIST[1,2,3,4,5,6] | LIST[1,2,3,4,5,6] | LIST [6,5,4,3,2,1] |
    When executing query:
      """
      LET input = range(1,6)
      RETURN input[: :] as a, input[: :1] as b, input[0: :] AS c, input[: 7:] AS d, input[: :-1] as e
      """
    Then the result should be, in any order:
      | a                  | b                  | c                 | d                 | e                  |
      | LIST [1,2,3,4,5,6] | LIST [1,2,3,4,5,6] | LIST[1,2,3,4,5,6] | LIST[1,2,3,4,5,6] | LIST [6,5,4,3,2,1] |
    When executing query:
      """
      LET input = range(1,6)
      RETURN list_slice(input, 1, 4, 0) as a
      """
    Then an Error should be raised: "[NR003]: Invalid function argument: Slice step cannot be zero, in expression: list_slice([1,2,3,4,5,6], 1, 4, 0)"
    When executing query:
      """
      LET input = range(1,6)
      RETURN input[1:4:0] as a
      """
    Then an Error should be raised: "[NR003]: Invalid function argument: Slice step cannot be zero, in expression: list_slice([1,2,3,4,5,6], 1, 4, 0, true, true)"
    When executing query:
      """
      RETURN list_slice([], 1, 3) as a, [][1:1] as b
      """
    Then the result should be, in any order:
      | a       | b       |
      | LIST [] | LIST [] |
    When executing query:
      """
      LET input = range(1,3)
      RETURN list_slice(input, 4, 6) as a, input[4:6] as b
      """
    Then the result should be, in any order:
      | a       | b       |
      | LIST [] | LIST [] |
    When executing query:
      """
      LET input = range(1,3)
      RETURN list_slice(input, 4, -6, -1) as a, input[4:-6:-1] as b
      """
    Then the result should be, in any order:
      | a              | b              |
      | LIST [3, 2, 1] | LIST [3, 2, 1] |
    When executing query:
      """
      LET input = range(1,3)
      RETURN list_slice(input, 6, 4, -1) as a, input[6:4:-1] as b
      """
    Then the result should be, in any order:
      | a       | b       |
      | LIST [] | LIST [] |
    When executing query:
      """
      LET input = range(1,3)
      RETURN input[4:] as a, input[-4::-1] as b
      """
    Then the result should be, in any order:
      | a       | b       |
      | LIST [] | LIST [] |

  Scenario: Cardinality
    When executing query:
      """
      RETURN cardinality([2,2,3]) AS a
      """
    Then the result should be, in any order:
      | a |
      | 3 |
    When executing query:
      """
      RETURN cardinality(["1","1"]) AS a
      """
    Then the result should be, in any order:
      | a |
      | 2 |
    When executing query:
      """
      RETURN cardinality({a:1, b:true, c:null, d:null, e: 1}) AS a
      """
    Then the result should be, in any order:
      | a |
      | 5 |
    When executing query:
      """
      RETURN cardinality(null) AS a
      """
    Then the result should be, in any order:
      | a    |
      | null |

  @sf01
  Scenario: Complex
    When executing query:
      """
      USE sf01
      MATCH (v1:TagClass{id:318}),(v2:Tag{id:318})
      RETURN all_different(v1,v2) AS a
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      USE sf01
      MATCH TRAIL (v{id:318})-[e]->{1,2}(v)
      RETURN collect(distinct e) AS edge_list GROUP BY ()
      NEXT
      USE sf01
      MATCH TRAIL (person1:Person{id:318})-[e1]->{1,2}(person1),
            TRAIL (person2:Person{id:687})-[e2]->{1,2}(person2)
      RETURN e1 not in edge_list AS a, e2 not in edge_list AS b
      """
    Then the result should be, in any order:
      | a     | b    |
      | false | true |
      | false | true |
      | false | true |
      | false | true |

  Scenario: Max length
    When executing query:
      """
      RETURN range(0,9223372036854775807)
      """
    Then an Error should be raised: "[NR017]: List should be no longer than 67108863, in expression: range(0, 9223372036854775807)"
    When executing query:
      """
      RETURN range(1,67108864)
      """
    Then an Error should be raised: "[NR017]: List should be no longer than 67108863, in expression: range(1, 67108864)"
    When executing query:
      """
      RETURN range(-2147483648,2147483647,2147483647) as a
      """
    Then the result should be, in any order:
      | a                                |
      | LIST [-2147483648,-1,2147483646] |
    When executing query:
      """
      RETURN range(-9223372036854775807, 9223372036854775807, 9223372036854775807) as a
      """
    Then the result should be, in any order:
      | a                                                 |
      | LIST [-9223372036854775807,0,9223372036854775807] |

  Scenario: Unwind large list
    When executing query:
      """
      LET a = range(1, 12000)
      FOR i IN a
      RETURN count(*) AS c GROUP BY ()
      """
    Then the result should be, in any order:
      | c     |
      | 12000 |

  Scenario: neo4j apoc functions
    # number
    When executing query:
      """
      RETURN zip([1,2,3],[4,5,6]) AS res
      """
    Then the result should be, in any order:
      | res                                 |
      | LIST[LIST[1,4],LIST[2,5],LIST[3,6]] |
    When executing query:
      """
      RETURN zip([1,2,3],[4,NULL,6]) AS res
      """
    Then the result should be, in any order:
      | res                                    |
      | LIST[LIST[1,4],LIST[2,NULL],LIST[3,6]] |
    When executing query:
      """
      RETURN zip([NULL,2,3],[NULL,4,5,6,NULL,7]) AS res
      """
    Then the result should be, in any order:
      | res                                       |
      | LIST[LIST[NULL,NULL],LIST[2,4],LIST[3,5]] |
    When executing query:
      """
      RETURN zip([NULL,1.4e5,5,6,NULL,7e7],[2,3.3]) AS res
      """
    Then the result should be, in any order:
      | res                                     |
      | LIST[LIST[NULL,2.0],LIST[140000.0,3.3]] |
    When executing query:
      """
      RETURN zip([NULL,1.4e5,5,6m,NULL,7e7],[2,3.3m]) AS res
      """
    Then the result should be, in any order:
      | res                                     |
      | LIST[LIST[NULL,2.0],LIST[140000.0,3.3]] |
    When executing query:
      """
      RETURN zip([NULL,-1.4e5,5,6m,NULL,7e7],[2,-3.3m]) AS res
      """
    Then the result should be, in any order:
      | res                                       |
      | LIST[LIST[NULL,2.0],LIST[-140000.0,-3.3]] |
    # boolean
    When executing query:
      """
      RETURN zip([NULL,true,NULL,false],[false,NULL,NULL]) AS res
      """
    Then the result should be, in any order:
      | res                                                     |
      | LIST[LIST[NULL,false],LIST[true,NULL], LIST[NULL,NULL]] |
    # record
    When executing query:
      """
      RETURN zip([{a:false,b:NULL,c:1e3},NULL],[{a:false,b:{b1:5,b2:4},c:NULL},{a:NULL,b:NULL,c:NULL},NULL,NULL,NULL]) AS res
      """
    Then the result should be, in any order:
      | res                                                                                                                      |
      | LIST[LIST[RECORD{a:false,b:NULL,c:1000.0},RECORD{a:false,b:{b1:5,b2:4},c:NULL}],LIST[NULL,RECORD{a:NULL,b:NULL,c:NULL}]] |
    # string
    When executing query:
      """
      RETURN zip(["a","b","c"],["d","e","f"]) AS res
      """
    Then the result should be, in any order:
      | res                                             |
      | LIST[LIST["a","d"],LIST["b","e"],LIST["c","f"]] |
    When executing query:
      """
      RETURN zip(["a","b","c"],["d","e",NULL]) AS res
      """
    Then the result should be, in any order:
      | res                                              |
      | LIST[LIST["a","d"],LIST["b","e"],LIST["c",NULL]] |
    When executing query:
      """
      RETURN zip(["a","b",NULL],["d","e","f","g"]) AS res
      """
    Then the result should be, in any order:
      | res                                              |
      | LIST[LIST["a","d"],LIST["b","e"],LIST[NULL,"f"]] |
    When executing query:
      """
      RETURN zip(["a","b",NULL],["d","e",NULL,"g"]) AS res
      """
    Then the result should be, in any order:
      | res                                               |
      | LIST[LIST["a","d"],LIST["b","e"],LIST[NULL,NULL]] |
    # temporal
    When executing query:
      """
      RETURN zip([DATE "2023-01-02", DATE "2023-01-03"], [DATETIME "2023-01-01T00:00:00", DATETIME "2023-01-02T00:00:00",null,null]) AS res
      """
    Then the result should be, in any order:
      | res                                                                                                                                                                       |
      | LIST[LIST[DATETIME "2023-01-02T00:00:00.000000",DATETIME "2023-01-01T00:00:00.000000"],LIST[DATETIME "2023-01-03T00:00:00.000000",DATETIME "2023-01-02T00:00:00.000000"]] |
    When executing query:
      """
      RETURN zip([DATE "2023-01-01", DATETIME "2023-01-01T00:00:00", DATE "2023-01-02", NULL], [DATETIME "2023-01-02T00:00:00", NULL, NULL]) AS res
      """
    Then the result should be, in any order:
      | res                                                                                                                                                                                       |
      | LIST[LIST[DATETIME "2023-01-01T00:00:00.000000",DATETIME "2023-01-02T00:00:00.000000"],LIST[DATETIME "2023-01-01T00:00:00.000000",NULL],LIST[DATETIME "2023-01-02T00:00:00.000000",NULL]] |
    # duration
    When executing query:
      """
      RETURN zip([DURATION "P1Y", DURATION "P2Y"], [DURATION "P3M", DURATION "P4M"]) AS res
      """
    Then the result should be, in any order:
      | res                                                                              |
      | LIST[LIST[DURATION "P1Y", DURATION "P3M"], LIST[DURATION "P2Y", DURATION "P4M"]] |
    # nested lists
    When executing query:
      """
      RETURN zip([[1,2],[3,4,5]],[[5,6],[7,8]]) AS res
      """
    Then the result should be, in any order:
      | res                                                         |
      | LIST[LIST[LIST[1,2],LIST[5,6]],LIST[LIST[3,4,5],LIST[7,8]]] |
    When executing query:
      """
      RETURN zip([null,[1,2.4],[3,4.]],[]) AS res
      """
    Then the result should be, in any order:
      | res    |
      | LIST[] |

  # FIXME(czp): maybe tck parsing bug: https://github.com/vesoft-inc/nebula-ng/issues/8102
  # When executing query:
  # """
  # RETURN zip([null,[1,2],[3]],[[5,6],[],[9,10],[null,11.3]]) AS res
  # """
  # Then the result should be, in any order:
  # | res                                                                           |
  # | LIST[LIST[NULL, LIST[5,6]], LIST[LIST[1,2],LIST[]], LIST[LIST[3],LIST[9,10]]] |
  # When executing query:
  # """
  # RETURN zip([NULL,2,3],[NULL,1.4,5,6,NULL,7.7]) AS res
  # """
  # Then the result should be, in any order:
  # | res                                         |
  # | LIST[LIST[NULL,NULL],LIST[2,1.4],LIST[3,5]] |
  # When executing query:
  # """
  # RETURN zip([NULL,1,5,6,NULL,7.7],[NULL,2,3.3]) AS res
  # """
  # Then the result should be, in any order:
  # | res                                       |
  # | LIST[LIST[NULL,NULL],LIST[1,2],LIST[5,3.3]] |
  Scenario: neo4j apoc function errors
    When executing query:
      """
      RETURN zip([1,2,3],[4,5,6], [7,8,9])
      """
    Then an Error should be raised: "[NR002]: Undefined function: `zip(LIST, LIST, LIST)`"
    When executing query:
      """
      RETURN zip([1,2,3])
      """
    Then an Error should be raised: "[NR002]: Undefined function: `zip(LIST)`"
    When executing query:
      """
      RETURN zip([1,2,3], ["1","2","3"])
      """
    Then an Error should be raised: "[NR006]: Resolve function failed: `The list element type mismatch: INT32 vs STRING`"
    When executing query:
      """
      RETURN zip([1,2,3], [null,false])
      """
    Then an Error should be raised: "[NR006]: Resolve function failed: `The list element type mismatch: INT32 vs BOOL`"
    When executing query:
      """
      RETURN zip([null,{a:3},null], [{a:4,b:null},{a:3}])
      """
    Then an Error should be raised: "[NR013]: All elements of list constructor must have compatible types"

  Scenario: array_distinct
    When executing query:
      """
      RETURN array_distinct([]) AS res
      """
    Then the result should be, in any order:
      | res    |
      | LIST[] |
    When executing query:
      """
      RETURN array_distinct([1,1,1,1,1]) AS res
      """
    Then the result should be, in any order:
      | res     |
      | LIST[1] |
    When executing query:
      """
      RETURN array_distinct([1,2,3,2,1,3,1,2,3]) AS res
      """
    Then the result should be, in any order:
      | res         |
      | LIST[1,2,3] |
    When executing query:
      """
      RETURN array_distinct(["a","b","a","c","b"]) AS res
      """
    Then the result should be, in any order:
      | res               |
      | LIST["a","c","b"] |
    When executing query:
      """
      RETURN array_distinct([true,false,true,false,true,null,null]) AS res
      """
    Then the result should be, in any order:
      | res                     |
      | LIST[false, true, NULL] |
    When executing query:
      """
      RETURN array_distinct([1.1,2.2,1.1,null,3.3,2.2]) AS res
      """
    Then the result should be, in any order:
      | res                       |
      | LIST[1.1M,NULL,3.3M,2.2M] |
    When executing query:
      """
      RETURN array_distinct([DATE "2023-01-01", DATE "2023-01-02",null, DATE "2023-01-01",null,null]) AS res
      """
    Then the result should be, in any order:
      | res                                             |
      | LIST[ DATE "2023-01-02",DATE "2023-01-01",NULL] |
    When executing query:
      """
      RETURN array_distinct([DURATION "P1Y", DURATION "P2Y", null,DURATION "P1Y",null]) AS res
      """
    Then the result should be, in any order:
      | res                                        |
      | LIST[DURATION "P2Y", DURATION "P1Y", NULL] |
    When executing query:
      """
      RETURN array_distinct([[1,2],[],[3,4],[],null,[null],[],[1,2],[5,6]]) AS res
      """
    Then the result should be, in any order:
      | res                                                         |
      | LIST[LIST[3,4],NULL,LIST[NULL],LIST [],LIST[1,2],LIST[5,6]] |
    When executing query:
      """
      RETURN array_distinct([[],[],[],[]]) AS res
      """
    Then the result should be, in any order:
      | res          |
      | LIST[LIST[]] |
    When executing query:
      """
      RETURN array_distinct([null,null,null]) AS res
      """
    Then the result should be, in any order:
      | res        |
      | LIST[NULL] |
    When executing query:
      """
      RETURN array_distinct([1,null,2,null,3,null]) AS res
      """
    Then the result should be, in any order:
      | res              |
      | LIST[1,2,3,NULL] |
    When executing query:
      """
      RETURN array_distinct([[1],[1,2],[1],[1,2,3]]) AS res
      """
    Then the result should be, in any order:
      | res                                 |
      | LIST[LIST[1,2],LIST[1],LIST[1,2,3]] |
    When executing query:
      """
      RETURN array_distinct([[null],[null,1],[null]]) AS res
      """
    Then the result should be, in any order:
      | res                           |
      | LIST[LIST[NULL,1],LIST[NULL]] |
    When executing query:
      """
      RETURN array_distinct([{a:1,b:2},{a:1,b:2},{a:null,b:1}, NULL,null]) AS res
      """
    Then the result should be, in any order:
      | res                                             |
      | LIST[RECORD{a:1,b:2}, RECORD{a:NULL,b:1}, NULL] |
    When executing query:
      """
      RETURN array_distinct([{a:null},{a:null},{a:1}]) AS res
      """
    Then the result should be, in any order:
      | res                               |
      | LIST[RECORD{a:NULL}, RECORD{a:1}] |
    When executing query:
      """
      RETURN array_distinct([1.0,1,1.00,1.000]) AS res
      """
    Then the result should be, in any order:
      | res        |
      | LIST[1.0M] |
    When executing query:
      """
      RETURN array_distinct([1e0,1,1.0]) AS res
      """
    Then the result should be, in any order:
      | res        |
      | LIST[1.0M] |
    When executing query:
      """
      RETURN array_distinct([1,2,3.3,null,2,3.3,null,null,1]) AS res
      """
    Then the result should be, in any order:
      | res                   |
      | LIST[2M,3.3M,NULL,1M] |
    When executing query:
      """
      RETURN array_distinct(zip([3.3,null,2,3.3,null,null],[5,null,1,5,6,null,7.7])) AS res
      """
    Then the result should be, in any order:
      | res                                                           |
      | LIST[LIST[2M,1M],LIST[3.3M,5M],LIST[NULL,6M],LIST[NULL,NULL]] |
    When executing query:
      """
      RETURN array_distinct([null,{a:3,b:true},null,{a:3,b:true},null,{a:34.4,b:true}]) AS res
      """
    Then the result should be, in any order:
      | res                                                   |
      | LIST[RECORD{a:3,b:true}, NULL, RECORD{a:34.4,b:true}] |
    When executing query:
      """
      RETURN array_distinct([null,[[]],[[null]],[[]]]) AS res
      """
    Then the result should be, in any order:
      | res                                        |
      | LIST[NULL, LIST[LIST[NULL]], LIST[LIST[]]] |
    When executing query:
      """
      RETURN array_distinct(null) AS res
      """
    Then the result should be, in any order:
      | res  |
      | NULL |
    When executing query:
      """
      RETURN array_distinct(zip([null,[1,2],[3]],[[],[], [5,6],[],[9,10],[null,11.3]])) AS res
      """
    Then the result should be, in any order:
      | res                                                                            |
      | LIST[LIST[NULL, LIST[]], LIST[LIST[1M,2M],LIST[]], LIST[LIST[3M],LIST[5M,6M]]] |

  Scenario: array_except
    When executing query:
      """
      RETURN array_except([],null) AS res
      """
    Then the result should be, in any order:
      | res  |
      | NULL |
    When executing query:
      """
      RETURN array_except([],[1]) AS res
      """
    Then the result should be, in any order:
      | res    |
      | LIST[] |
    When executing query:
      """
      RETURN array_except(null,[null,3,4,5]) AS res
      """
    Then the result should be, in any order:
      | res  |
      | NULL |
    When executing query:
      """
      RETURN array_except([null],[null,3,4,5]) AS res
      """
    Then the result should be, in any order:
      | res    |
      | LIST[] |
    When executing query:
      """
      RETURN array_except([null,3,null,4,3,4,5],[null]) AS res
      """
    Then the result should be, in any order:
      | res         |
      | LIST[3,4,5] |
    When executing query:
      """
      RETURN array_except([1,2,3,4,5],[3,4,4,4,4,4,null]) AS res
      """
    Then the result should be, in any order:
      | res         |
      | LIST[1,2,5] |
    When executing query:
      """
      RETURN array_except([1,2,3,null,null,null],[1,2,3]) AS res
      """
    Then the result should be, in any order:
      | res        |
      | LIST[NULL] |
    When executing query:
      """
      RETURN array_except(["a","b","c"],["b","d", null]) AS res
      """
    Then the result should be, in any order:
      | res           |
      | LIST["a","c"] |
    When executing query:
      """
      RETURN array_except([true,false,true,true,null,null],[false]) AS res
      """
    Then the result should be, in any order:
      | res              |
      | LIST[true, NULL] |
    When executing query:
      """
      RETURN array_except([1.1,2.2,3.3],[2.2,4.4,1.1,1.1,1.1,null,null]) AS res
      """
    Then the result should be, in any order:
      | res        |
      | LIST[3.3M] |
    When executing query:
      """
      RETURN array_except([DATE "2023-01-01", DATE "2023-01-02"],[DATE "2023-01-01"]) AS res
      """
    Then the result should be, in any order:
      | res                     |
      | LIST[DATE "2023-01-02"] |
    When executing query:
      """
      RETURN array_except([[1,2],null,null,[3,4]],[[3,4]]) AS res
      """
    Then the result should be, in any order:
      | res                   |
      | LIST[LIST[1,2], NULL] |
    When executing query:
      """
      RETURN array_except([{a:1},{a:2},{a:2},{a:1}],[{a:1},{a:3}, null]) AS res
      """
    Then the result should be, in any order:
      | res               |
      | LIST[RECORD{a:2}] |

  Scenario: array_intersect
    When executing query:
      """
      RETURN array_intersect([],[]) AS res
      """
    Then the result should be, in any order:
      | res    |
      | LIST[] |
    When executing query:
      """
      RETURN array_intersect([1,2,3],[2,3,null,4]) AS res
      """
    Then the result should be, in any order:
      | res       |
      | LIST[2,3] |
    When executing query:
      """
      RETURN array_intersect([1,2,null,null,3],[4,5,6,null]) AS res
      """
    Then the result should be, in any order:
      | res        |
      | LIST[NULL] |
    When executing query:
      """
      RETURN array_intersect([1,2,2,3],[1,2,3,2]) AS res
      """
    Then the result should be, in any order:
      | res         |
      | LIST[1,2,3] |
    When executing query:
      """
      RETURN array_intersect(["a","b","c","b","a"],["b","c","d"]) AS res
      """
    Then the result should be, in any order:
      | res           |
      | LIST["c","b"] |
    When executing query:
      """
      RETURN array_intersect([true,false],[false,null,true]) AS res
      """
    Then the result should be, in any order:
      | res              |
      | LIST[true,false] |
    When executing query:
      """
      RETURN array_intersect([1.1,2.2,3.3],[2.2,3.3,4.4]) AS res
      """
    Then the result should be, in any order:
      | res             |
      | LIST[2.2M,3.3M] |
    When executing query:
      """
      RETURN array_intersect([null,1,2,3],[2,3,null,4]) AS res
      """
    Then the result should be, in any order:
      | res            |
      | LIST[NULL,2,3] |
    When executing query:
      """
      RETURN array_intersect([null],[null]) AS res
      """
    Then the result should be, in any order:
      | res        |
      | LIST[NULL] |
    When executing query:
      """
      RETURN array_intersect([null],null) AS res
      """
    Then the result should be, in any order:
      | res  |
      | NULL |
    When executing query:
      """
      RETURN array_intersect([[1,2],[3,4],null],[[3,4],[5,6],[],[null]]) AS res
      """
    Then the result should be, in any order:
      | res             |
      | LIST[LIST[3,4]] |
    When executing query:
      """
      RETURN array_intersect([{a:1},{a:2}],[{a:2},{a:null},null]) AS res
      """
    Then the result should be, in any order:
      | res               |
      | LIST[RECORD{a:2}] |
    When executing query:
      """
      RETURN array_intersect([DATE "2023-01-01", DATE "2023-01-02"],[DATE "2023-01-02", DATE "2023-01-03"]) AS res
      """
    Then the result should be, in any order:
      | res                     |
      | LIST[DATE "2023-01-02"] |
    When executing query:
      """
      RETURN array_intersect([DURATION "P1Y", DURATION "P2Y"],[DURATION "P2Y", null,DURATION "P3Y"]) AS res
      """
    Then the result should be, in any order:
      | res                  |
      | LIST[DURATION "P2Y"] |
    When executing query:
      """
      RETURN array_intersect([1,1,2,2,3],[2,2,3,3,4]) AS res
      """
    Then the result should be, in any order:
      | res       |
      | LIST[2,3] |
    When executing query:
      """
      RETURN array_intersect(null,[1,2,3]) AS res
      """
    Then the result should be, in any order:
      | res  |
      | NULL |
    When executing query:
      """
      RETURN array_intersect([1,2,3],null) AS res
      """
    Then the result should be, in any order:
      | res  |
      | NULL |
    When executing query:
      """
      RETURN array_intersect([],[]) AS res
      """
    Then the result should be, in any order:
      | res    |
      | LIST[] |
    When executing query:
      """
      RETURN array_intersect([1,2,3],[]) AS res
      """
    Then the result should be, in any order:
      | res    |
      | LIST[] |
    When executing query:
      """
      RETURN array_intersect([[null],[1]],[[null],[2]]) AS res
      """
    Then the result should be, in any order:
      | res              |
      | LIST[LIST[NULL]] |
    When executing query:
      """
      RETURN array_intersect([1,2,3],["1","2","3"]) AS res
      """
    Then an Error should be raised: "[NR006]: Resolve function failed: `The list element type mismatch: INT32 vs STRING`"
    When executing query:
      """
      RETURN array_intersect([1,2,3],[true,false]) AS res
      """
    Then an Error should be raised: "[NR006]: Resolve function failed: `The list element type mismatch: INT32 vs BOOL`"

  Scenario: array_min and array_max
    When executing query:
      """
      RETURN array_min([1,2,3,0/0d,4,5]) AS res
      """
    Then the result should be, in any order:
      | res |
      | 1.0 |
    When executing query:
      """
      RETURN array_max([1,2,3,4,5]) AS res
      """
    Then the result should be, in any order:
      | res |
      | 5   |
    When executing query:
      """
      RETURN array_min([5,4,3,5,2,1]) AS res
      """
    Then the result should be, in any order:
      | res |
      | 1   |
    When executing query:
      """
      RETURN array_max([5,4,3,5,2,1]) AS res
      """
    Then the result should be, in any order:
      | res |
      | 5   |
    When executing query:
      """
      RETURN array_min([1.1,2.2,3.3]) AS res
      """
    Then the result should be, in any order:
      | res  |
      | 1.1M |
    When executing query:
      """
      RETURN array_max([1.1,2.2,3.3]) AS res
      """
    Then the result should be, in any order:
      | res  |
      | 3.3M |
    When executing query:
      """
      RETURN array_min(["a","b","c"]) AS res
      """
    Then the result should be, in any order:
      | res |
      | "a" |
    When executing query:
      """
      RETURN array_max(["a","b","c"]) AS res
      """
    Then the result should be, in any order:
      | res |
      | "c" |
    When executing query:
      """
      RETURN array_min([DATE "2023-01-01", DATE "2023-01-02", DATE "2023-01-03"]) AS res
      """
    Then the result should be, in any order:
      | res               |
      | DATE "2023-01-01" |
    When executing query:
      """
      RETURN array_max([DATE "2023-01-01", DATE "2023-01-02", DATE "2023-01-03"]) AS res
      """
    Then the result should be, in any order:
      | res               |
      | DATE "2023-01-03" |
    When executing query:
      """
      RETURN array_max([DATETIME "2023-01-01T00:00:00", DATETIME "2023-01-02T00:00:00", DATETIME "2023-01-03T00:00:00"]) AS res
      """
    Then the result should be, in any order:
      | res                                   |
      | DATETIME "2023-01-03T00:00:00.000000" |
    When executing query:
      """
      RETURN array_min([DURATION "P1Y", DURATION "P2Y", DURATION "P3Y"]) AS res
      """
    Then the result should be, in any order:
      | res            |
      | DURATION "P1Y" |
    When executing query:
      """
      RETURN array_max([DURATION "P1Y", DURATION "P2Y", DURATION "P3Y"]) AS res
      """
    Then the result should be, in any order:
      | res            |
      | DURATION "P3Y" |
    When executing query:
      """
      RETURN array_min([1,null,3]) AS res
      """
    Then the result should be, in any order:
      | res  |
      | NULL |
    When executing query:
      """
      RETURN array_max([1,null,3]) AS res
      """
    Then the result should be, in any order:
      | res  |
      | NULL |
    When executing query:
      """
      RETURN array_min([null,null,null]) AS res
      """
    Then the result should be, in any order:
      | res  |
      | NULL |
    When executing query:
      """
      RETURN array_max([null,null,null]) AS res
      """
    Then the result should be, in any order:
      | res  |
      | NULL |
    When executing query:
      """
      RETURN array_min([]) AS res
      """
    Then the result should be, in any order:
      | res  |
      | NULL |
    When executing query:
      """
      RETURN array_max([]) AS res
      """
    Then the result should be, in any order:
      | res  |
      | NULL |
    When executing query:
      """
      RETURN array_min(null) AS res
      """
    Then the result should be, in any order:
      | res  |
      | NULL |
    When executing query:
      """
      RETURN array_max(null) AS res
      """
    Then the result should be, in any order:
      | res  |
      | NULL |
    When executing query:
      """
      RETURN array_min([1]) AS res
      """
    Then the result should be, in any order:
      | res |
      | 1   |
    When executing query:
      """
      RETURN array_max([1]) AS res
      """
    Then the result should be, in any order:
      | res |
      | 1   |
    When executing query:
      """
      RETURN array_min([-5,-3,-1,0,1,3,5]) AS res
      """
    Then the result should be, in any order:
      | res |
      | -5  |
    When executing query:
      """
      RETURN array_max([-5,-3,-1,0,1,3,5]) AS res
      """
    Then the result should be, in any order:
      | res |
      | 5   |
    When executing query:
      """
      RETURN array_min([1.5,0/0d,1.6,1.0d/0,1.4]) AS res
      """
    Then the result should be, in any order:
      | res |
      | 1.4 |
    When executing query:
      """
      RETURN CAST(array_min([1,-1.0,1d/0,-2.2d/0]) AS STRING) AS res
      """
    Then the result should be, in any order:
      | res         |
      | "-Infinity" |
    When executing query:
      """
      RETURN CAST(array_max([1,-1.0,0d/0,1d/0,-2.2d/0]) AS STRING) AS res
      """
    Then the result should be, in any order:
      | res   |
      | "NaN" |
    When executing query:
      """
      RETURN array_max([1.5,1.6,1.4]) AS res
      """
    Then the result should be, in any order:
      | res  |
      | 1.6M |
    When executing query:
      """
      RETURN array_min([true,false]) AS res
      """
    Then the result should be, in any order:
      | res   |
      | false |
    When executing query:
      """
      RETURN array_max([true,false]) AS res
      """
    Then the result should be, in any order:
      | res  |
      | true |
    When executing query:
      """
      RETURN CAST (array_max([32,-1,5.5,0.1d/0,-3d/0]) AS STRING) AS res
      """
    Then the result should be, in any order:
      | res        |
      | "Infinity" |
    When executing query:
      """
      RETURN CAST (array_min([32,-1,5.5,0.1d/0,-3d/0]) AS STRING) AS res
      """
    Then the result should be, in any order:
      | res         |
      | "-Infinity" |
    When executing query:
      """
      RETURN CAST (array_min([32,0d/0,-1,5.5,0.1d/0,-3d/0]) AS STRING) AS res
      """
    Then the result should be, in any order:
      | res         |
      | "-Infinity" |
    When executing query:
      """
      RETURN CAST (array_max([32,0d/0,-1,5.5,0.1d/0,-3d/0]) AS STRING) AS res
      """
    Then the result should be, in any order:
      | res   |
      | "NaN" |
    When executing query:
      """
      RETURN array_min([32,0d/0,-1,5.5,0.1d/0,-3d/0,null,null])  AS res
      """
    Then the result should be, in any order:
      | res  |
      | NULL |
    When executing query:
      """
      RETURN array_max([32,0d/0,-1,5.5,0.1d/0,-3d/0,null,null])  AS res
      """
    Then the result should be, in any order:
      | res  |
      | NULL |

  Scenario: array_sum
    When executing query:
      """
      RETURN array_sum([1,2,3,4,5]) AS res
      """
    Then the result should be, in any order:
      | res |
      | 15  |
    When executing query:
      """
      RETURN array_sum([]) AS res
      """
    Then the result should be, in any order:
      | res |
      | 0.0 |
    When executing query:
      """
      RETURN array_sum([1]) AS res
      """
    Then the result should be, in any order:
      | res |
      | 1   |
    When executing query:
      """
      RETURN array_sum([-5,-3,-1,null,null,0,1,3,5]) AS res
      """
    Then the result should be, in any order:
      | res |
      | 0   |
    When executing query:
      """
      RETURN CAST (array_sum([-5,-3,-1,null,null,0,1,3,5,0d/0]) AS STRING) AS res
      """
    Then the result should be, in any order:
      | res   |
      | "NaN" |
    When executing query:
      """
      RETURN CAST (array_sum([-5,-3,-1,null,null,0,1,3,5,1d/0]) AS STRING) AS res
      """
    Then the result should be, in any order:
      | res        |
      | "Infinity" |
    When executing query:
      """
      RETURN CAST (array_sum([-5,-3,-1,null,null,0,1,3,5,-21d/0]) AS STRING) AS res
      """
    Then the result should be, in any order:
      | res         |
      | "-Infinity" |
    When executing query:
      """
      RETURN CAST (array_sum([-5,-3,-1,null,null,0,1,3,5,-21d/0,1d/0]) AS STRING) AS res
      """
    Then the result should be, in any order:
      | res   |
      | "NaN" |
    When executing query:
      """
      RETURN CAST (array_sum([-5,-3,-1,null,null,0d/0,3,5,-21d/0,1d/0]) AS STRING) AS res
      """
    Then the result should be, in any order:
      | res   |
      | "NaN" |
    When executing query:
      """
      RETURN array_sum([1.1,2.2,3.3]) AS res
      """
    Then the result should be, in any order:
      | res  |
      | 6.6M |
    When executing query:
      """
      RETURN array_sum([1.5,1.6,1.4]) AS res
      """
    Then the result should be, in any order:
      | res  |
      | 4.5M |
    When executing query:
      """
      RETURN array_sum([1,2,3,null,5]) AS res
      """
    Then the result should be, in any order:
      | res |
      | 11  |
    When executing query:
      """
      RETURN array_sum([null,null,null]) AS res
      """
    Then the result should be, in any order:
      | res |
      | 0.0 |
    When executing query:
      """
      RETURN CAST(array_sum([null,null,0d/0,null]) AS STRING) AS res
      """
    Then the result should be, in any order:
      | res   |
      | "NaN" |
    When executing query:
      """
      RETURN array_sum(null) AS res
      """
    Then the result should be, in any order:
      | res  |
      | NULL |
    When executing query:
      """
      RETURN array_sum([1,2.5,3]) AS res
      """
    Then the result should be, in any order:
      | res  |
      | 6.5M |
    When executing query:
      """
      RETURN array_sum([-1,-2,-3]) AS res
      """
    Then the result should be, in any order:
      | res |
      | -6  |
    When executing query:
      """
      RETURN array_sum([0,0,null,0]) AS res
      """
    Then the result should be, in any order:
      | res |
      | 0   |
    When executing query:
      """
      RETURN array_sum([1e10,2e10,3e10]) AS res
      """
    Then the result should be, in any order:
      | res           |
      | 60000000000.0 |
    When executing query:
      """
      RETURN array_sum([["a","b"]]) AS res
      """
    Then an Error should be raised: "[NR006]: Resolve function failed: `The list element type is not numeric: LIST<STRING>`"
    When executing query:
      """
      RETURN array_sum([true,false]) AS res
      """
    Then an Error should be raised: "[NR006]: Resolve function failed: `The list element type is not numeric: BOOL`"
    When executing query:
      """
      RETURN array_sum([[1e10,2e10,3e10]]) AS res
      """
    Then an Error should be raised: "[NR006]: Resolve function failed: `The list element type is not numeric: LIST<DOUBLE>`"

  Scenario: array_sort
    When executing query:
      """
      RETURN array_sort([3,1,4,1,5,9,2,6]) AS res
      """
    Then the result should be, in any order:
      | res                   |
      | LIST[1,1,2,3,4,5,6,9] |
    When executing query:
      """
      RETURN array_sort([]) AS res
      """
    Then the result should be, in any order:
      | res    |
      | LIST[] |
    When executing query:
      """
      RETURN array_sort([5]) AS res
      """
    Then the result should be, in any order:
      | res     |
      | LIST[5] |
    When executing query:
      """
      RETURN array_sort([3,1,null,2,null]) AS res
      """
    Then the result should be, in any order:
      | res                   |
      | LIST[1,2,3,NULL,NULL] |
    When executing query:
      """
      RETURN array_sort([3.3,1.1,2.2]) AS res
      """
    Then the result should be, in any order:
      | res                  |
      | LIST[1.1M,2.2M,3.3M] |
    When executing query:
      """
      RETURN array_sort(["c","a","a","ab",null,"ac","abcd","b"]) AS res
      """
    Then the result should be, in any order:
      | res                                         |
      | LIST["a","a","ab","abcd","ac","b","c",NULL] |
    When executing query:
      """
      RETURN array_sort([true,false,true,null,null]) AS res
      """
    Then the result should be, in any order:
      | res                             |
      | LIST[false,true,true,NULL,NULL] |
    When executing query:
      """
      RETURN array_sort([3,1,null,2]) AS res
      """
    Then the result should be, in any order:
      | res              |
      | LIST[1,2,3,NULL] |
    When executing query:
      """
      RETURN transform(array_sort([-333,4,3.3d/0,1,NULL,-1d/0,null,0d/0,1d/0,-1.3d/0,null,0.0d/0.0]),x -> CAST(x AS STRING)) AS res
      """
    Then the result should be, in any order:
      | res                                                                                           |
      | LIST["-Infinity","-Infinity","-333","1","4","Infinity","Infinity","NaN","NaN",NULL,NULL,NULL] |
    When executing query:
      """
      RETURN array_sort(null) AS res
      """
    Then the result should be, in any order:
      | res  |
      | NULL |
    When executing query:
      """
      RETURN array_sort([-5,-1,-3,0,2]) AS res
      """
    Then the result should be, in any order:
      | res                |
      | LIST[-5,-3,-1,0,2] |
    When executing query:
      """
      RETURN array_sort([1,2.5,3,1.5]) AS res
      """
    Then the result should be, in any order:
      | res                   |
      | LIST[1M,1.5M,2.5M,3M] |
    When executing query:
      """
      RETURN array_sort([DATE "2023-01-03", null,DATE "2023-01-01", DATE "2023-01-02",null]) AS res
      """
    Then the result should be, in any order:
      | res                                                                   |
      | LIST[DATE "2023-01-01",DATE "2023-01-02",DATE "2023-01-03",NULL,NULL] |
    When executing query:
      """
      RETURN array_sort([DURATION "P3Y", NULL,DURATION "P1Y", DURATION "P2Y"]) AS res
      """
    Then the result should be, in any order:
      | res                                                     |
      | LIST[DURATION "P1Y",DURATION "P2Y",DURATION "P3Y",NULL] |
    When executing query:
      """
      RETURN array_sort([5,5,5,5]) AS res
      """
    Then the result should be, in any order:
      | res           |
      | LIST[5,5,5,5] |
    When executing query:
      """
      LET ll =array_sort([[3,2],[3,2,-3.3d/0,3.3d/0],[3,2,3.3d/0,-3.3d/0],[3,0d/0.0],[3],[],[null,3,2],[3,null,2],[3,2,null,-3.3d/0,null],[],[3,2,0d/0],[3,2,1d],[2,3]])
      RETURN transform(ll, l->transform(l, x->cast(x as string))) AS res
      """
    Then the result should be, in any order:
      | res                                                                                                                                                                                                                                                                 |
      | LIST[LIST[],LIST[],LIST["2","3"],LIST["3"],LIST["3","2"],LIST["3","2","-Infinity","Infinity"],LIST["3","2","1"],LIST["3","2","Infinity","-Infinity"],LIST["3","2","NaN"],LIST["3","2",NULL,"-Infinity",NULL],LIST["3","NaN"],LIST["3",NULL,"2"],LIST[NULL,"3","2"]] |
    When executing query:
      """
      RETURN array_sort([{a:1},{a:3},{a:2}]) AS res
      """
    Then the result should be, in any order:
      | res                                       |
      | LIST[RECORD{a:1},RECORD{a:2},RECORD{a:3}] |
    When executing query:
      """
      RETURN array_sort([DATETIME "2023-01-03T00:00:00", null,DATETIME "2023-01-01T00:00:00", DATETIME "2023-01-02T00:00:00"]) AS res
      """
    Then the result should be, in any order:
      | res                                                                                                                           |
      | LIST[DATETIME "2023-01-01T00:00:00.000000",DATETIME "2023-01-02T00:00:00.000000",DATETIME "2023-01-03T00:00:00.000000", NULL] |

  Scenario: array_union
    When executing query:
      """
      RETURN array_union([],[]) AS res
      """
    Then the result should be, in any order:
      | res    |
      | LIST[] |
    When executing query:
      """
      RETURN array_union([1,2,2,3,2,2],[2,3,4,null,null]) AS res
      """
    Then the result should be, in any order:
      | res                |
      | LIST[1,2,3,4,NULL] |
    When executing query:
      """
      RETURN array_union([1,2,3],[4,5,6]) AS res
      """
    Then the result should be, in any order:
      | res               |
      | LIST[1,2,3,4,5,6] |
    When executing query:
      """
      RETURN array_union([1,2,2,3],[1,2,3,2]) AS res
      """
    Then the result should be, in any order:
      | res         |
      | LIST[1,2,3] |
    When executing query:
      """
      RETURN array_union(["a","b","c"],["b","c","d"]) AS res
      """
    Then the result should be, in any order:
      | res                   |
      | LIST["a","b","c","d"] |
    When executing query:
      """
      RETURN array_union([true,false],[false,null,true]) AS res
      """
    Then the result should be, in any order:
      | res                   |
      | LIST[true,false,NULL] |
    When executing query:
      """
      RETURN array_union([1.1,2.2,3.3],[2.2,3.3,4.4]) AS res
      """
    Then the result should be, in any order:
      | res                       |
      | LIST[1.1M,2.2M,3.3M,4.4M] |
    When executing query:
      """
      RETURN array_union([null,1,2,3,null,null],[2,3,null,4]) AS res
      """
    Then the result should be, in any order:
      | res                |
      | LIST[NULL,1,2,3,4] |
    When executing query:
      """
      RETURN array_union([null],[null]) AS res
      """
    Then the result should be, in any order:
      | res        |
      | LIST[NULL] |
    When executing query:
      """
      RETURN array_union([[1,2],[3,4]],[[3,4],[5,6],[],[],null,[null]]) AS res
      """
    Then the result should be, in any order:
      | res                                                        |
      | LIST[LIST[1,2],LIST[3,4],LIST[5,6],LIST[],NULL,LIST[NULL]] |
    When executing query:
      """
      RETURN array_union([{a:1},{a:2}],[{a:2},{a:3}]) AS res
      """
    Then the result should be, in any order:
      | res                                       |
      | LIST[RECORD{a:1},RECORD{a:2},RECORD{a:3}] |
    When executing query:
      """
      RETURN array_union([DATE "2023-01-01", DATE "2023-01-02"],[DATE "2023-01-02", DATE "2023-01-03"]) AS res
      """
    Then the result should be, in any order:
      | res                                                         |
      | LIST[DATE "2023-01-01",DATE "2023-01-02",DATE "2023-01-03"] |
    When executing query:
      """
      RETURN array_union([DURATION "P1Y", DURATION "P2Y", DURATION "P2Y", DURATION "P2Y", DURATION "P2Y"],[DURATION "P2Y", DURATION "P3Y", DURATION "P3Y"]) AS res
      """
    Then the result should be, in any order:
      | res                                                |
      | LIST[DURATION "P1Y",DURATION "P2Y",DURATION "P3Y"] |
    When executing query:
      """
      RETURN array_union([1,1,2,2,3],[2,2,3,3,4]) AS res
      """
    Then the result should be, in any order:
      | res           |
      | LIST[1,2,3,4] |
    When executing query:
      """
      RETURN array_union(null,[1,2,3]) AS res
      """
    Then the result should be, in any order:
      | res  |
      | NULL |
    When executing query:
      """
      RETURN array_union([1,2,3],null) AS res
      """
    Then the result should be, in any order:
      | res  |
      | NULL |
    When executing query:
      """
      RETURN array_union([],[1,2,3]) AS res
      """
    Then the result should be, in any order:
      | res         |
      | LIST[1,2,3] |
    When executing query:
      """
      RETURN array_union([1,2,3],[]) AS res
      """
    Then the result should be, in any order:
      | res         |
      | LIST[1,2,3] |
    When executing query:
      """
      RETURN array_union([[null],[1]],[[null],[2],null,null]) AS res
      """
    Then the result should be, in any order:
      | res                                   |
      | LIST[LIST[NULL],LIST[1],LIST[2],NULL] |
    When executing query:
      """
      RETURN array_union([1,2,3],["1","2","3"]) AS res
      """
    Then an Error should be raised: "[NR006]: Resolve function failed: `The list element type mismatch: INT32 vs STRING`"
    When executing query:
      """
      RETURN array_union([1,2,3],[true,false]) AS res
      """
    Then an Error should be raised: "[NR006]: Resolve function failed: `The list element type mismatch: INT32 vs BOOL`"

  Scenario: remove_nulls
    When executing query:
      """
      RETURN remove_nulls([1,2,null,3,null,4]) AS res
      """
    Then the result should be, in any order:
      | res           |
      | LIST[1,2,3,4] |
    When executing query:
      """
      RETURN remove_nulls([]) AS res
      """
    Then the result should be, in any order:
      | res    |
      | LIST[] |
    When executing query:
      """
      RETURN remove_nulls([null,null,null]) AS res
      """
    Then the result should be, in any order:
      | res    |
      | LIST[] |
    When executing query:
      """
      RETURN remove_nulls([1,2,3]) AS res
      """
    Then the result should be, in any order:
      | res         |
      | LIST[1,2,3] |
    When executing query:
      """
      RETURN remove_nulls(["a",null,"b","c",null]) AS res
      """
    Then the result should be, in any order:
      | res               |
      | LIST["a","b","c"] |
    When executing query:
      """
      RETURN remove_nulls([true,null,false,null]) AS res
      """
    Then the result should be, in any order:
      | res              |
      | LIST[true,false] |
    When executing query:
      """
      RETURN remove_nulls([1.1,null,2.2,3.3,null]) AS res
      """
    Then the result should be, in any order:
      | res                  |
      | LIST[1.1M,2.2M,3.3M] |
    When executing query:
      """
      RETURN remove_nulls([DATE "2023-01-01",null,DATE "2023-01-02"]) AS res
      """
    Then the result should be, in any order:
      | res                                       |
      | LIST[DATE "2023-01-01",DATE "2023-01-02"] |
    When executing query:
      """
      RETURN remove_nulls([DURATION "P1Y",null,DURATION "P2Y"]) AS res
      """
    Then the result should be, in any order:
      | res                                 |
      | LIST[DURATION "P1Y",DURATION "P2Y"] |
    When executing query:
      """
      RETURN remove_nulls([[1,2],null,[3,4]]) AS res
      """
    Then the result should be, in any order:
      | res                       |
      | LIST[LIST[1,2],LIST[3,4]] |
    When executing query:
      """
      RETURN remove_nulls([[null],null,[1,2]]) AS res
      """
    Then the result should be, in any order:
      | res                        |
      | LIST[LIST[NULL],LIST[1,2]] |
    When executing query:
      """
      RETURN remove_nulls([{a:1},null,{a:2}]) AS res
      """
    Then the result should be, in any order:
      | res                           |
      | LIST[RECORD{a:1},RECORD{a:2}] |
    When executing query:
      """
      RETURN remove_nulls([{a:null},null,{a:1}]) AS res
      """
    Then the result should be, in any order:
      | res                              |
      | LIST[RECORD{a:NULL},RECORD{a:1}] |
    When executing query:
      """
      RETURN remove_nulls(null) AS res
      """
    Then the result should be, in any order:
      | res  |
      | NULL |
    When executing query:
      """
      RETURN remove_nulls([null]) AS res
      """
    Then the result should be, in any order:
      | res    |
      | LIST[] |
    When executing query:
      """
      RETURN remove_nulls([1,2,3,4,5]) AS res
      """
    Then the result should be, in any order:
      | res             |
      | LIST[1,2,3,4,5] |
    When executing query:
      """
      RETURN remove_nulls([DATETIME "2023-01-01T00:00:00",null,DATETIME "2023-01-02T00:00:00"]) AS res
      """
    Then the result should be, in any order:
      | res                                                                               |
      | LIST[DATETIME "2023-01-01T00:00:00.000000",DATETIME "2023-01-02T00:00:00.000000"] |

  Scenario: array_join
    When executing query:
      """
      RETURN array_join([1,2,3], ",") AS res
      """
    Then the result should be, in any order:
      | res     |
      | "1,2,3" |
    When executing query:
      """
      RETURN array_join(["a","b","c"], "-") AS res
      """
    Then the result should be, in any order:
      | res     |
      | "a-b-c" |
    When executing query:
      """
      RETURN array_join([1,2,3], "") AS res
      """
    Then the result should be, in any order:
      | res   |
      | "123" |
    When executing query:
      """
      RETURN array_join([], ",") AS res
      """
    Then the result should be, in any order:
      | res |
      | ""  |
    When executing query:
      """
      RETURN array_join([1], ",") AS res
      """
    Then the result should be, in any order:
      | res |
      | "1" |
    When executing query:
      """
      RETURN array_join([1,null,3], ",") AS res
      """
    Then the result should be, in any order:
      | res    |
      | "1,,3" |
    When executing query:
      """
      RETURN array_join([null,null,null], ",") AS res
      """
    Then the result should be, in any order:
      | res  |
      | ",," |
    When executing query:
      """
      RETURN array_join([true,false,true], "->") AS res
      """
    Then the result should be, in any order:
      | res                 |
      | "true->false->true" |
    When executing query:
      """
      RETURN array_join([1.1,2.2,3.3], ";") AS res
      """
    Then the result should be, in any order:
      | res           |
      | "1.1;2.2;3.3" |
    When executing query:
      """
      RETURN array_join([DATE "2023-01-01", DATE "2023-01-02"], " ") AS res
      """
    Then the result should be, in any order:
      | res                                       |
      | "DATE \"2023-01-01\" DATE \"2023-01-02\"" |
    When executing query:
      """
      RETURN array_join([DURATION "P1Y", DURATION "P2Y"], " and ") AS res
      """
    Then the result should be, in any order:
      | res                                         |
      | "DURATION \"P1Y0M\" and DURATION \"P2Y0M\"" |
    When executing query:
      """
      RETURN array_join(null, ",") AS res
      """
    Then the result should be, in any order:
      | res  |
      | NULL |
    When executing query:
      """
      RETURN array_join([1,2,null,3], null) AS res
      """
    Then the result should be, in any order:
      | res  |
      | NULL |
    When executing query:
      """
      RETURN array_join(["hello",null,"world"], " ") AS res
      """
    Then the result should be, in any order:
      | res            |
      | "hello  world" |
    When executing query:
      """
      RETURN array_join([1,2,null,3,4,5], "::") AS res
      """
    Then the result should be, in any order:
      | res               |
      | "1::2::::3::4::5" |
    When executing query:
      """
      RETURN array_join([[1,2],null,null,[3,4]], ",") AS res
      """
    Then the result should be, in any order:
      | res             |
      | "[1,2],,,[3,4]" |
    When executing query:
      """
      RETURN array_join([{a:1},null,null,{a:2}], ",") AS res
      """
    Then the result should be, in any order:
      | res             |
      | "{a:1},,,{a:2}" |
    When executing query:
      """
      RETURN array_join([1,2,3])
      """
    Then an Error should be raised: "[NR002]: Undefined function: `array_join(LIST)`"
    When executing query:
      """
      RETURN array_join([1,null,3], ",", "NULL") AS res
      """
    Then the result should be, in any order:
      | res        |
      | "1,NULL,3" |
    When executing query:
      """
      RETURN array_join([null,null,null], ",", "N/A") AS res
      """
    Then the result should be, in any order:
      | res           |
      | "N/A,N/A,N/A" |
    When executing query:
      """
      RETURN array_join([1,2,null,4], "-", "?") AS res
      """
    Then the result should be, in any order:
      | res       |
      | "1-2-?-4" |
    When executing query:
      """
      RETURN array_join(["a",null,"c"], "->", "") AS res
      """
    Then the result should be, in any order:
      | res      |
      | "a->->c" |
    When executing query:
      """
      RETURN array_join([null], ",", "empty📈") AS res
      """
    Then the result should be, in any order:
      | res       |
      | "empty📈" |
    When executing query:
      """
      RETURN array_join([true,null,false], " ", "unknown") AS res
      """
    Then the result should be, in any order:
      | res                  |
      | "true unknown false" |
    When executing query:
      """
      RETURN array_join([1,null,2,null,3], "数据库", "📈✅图") AS res
      """
    Then the result should be, in any order:
      | res                                       |
      | "1数据库📈✅图数据库2数据库📈✅图数据库3" |
    When executing query:
      """
      RETURN array_join(null, ",", "default") AS res
      """
    Then the result should be, in any order:
      | res  |
      | NULL |
