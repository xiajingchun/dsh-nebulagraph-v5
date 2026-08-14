# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: Construct Function

  Scenario: Construct List
    When executing query:
      """
      RETURN list[] as a
      """
    Then the result should be, in any order:
      | a       |
      | LIST [] |
    When executing query:
      """
      RETURN list[1] as a
      """
    Then the result should be, in any order:
      | a        |
      | LIST [1] |
    When executing query:
      """
      RETURN list["a","b"] as a
      """
    Then the result should be, in any order:
      | a               |
      | LIST ["a", "b"] |
    When executing query:
      """
      FOR i IN LIST[1, 2, 3]
      RETURN size(collect(i)) as sz GROUP BY ()
      """
    Then the result should be, in any order:
      | sz |
      | 3  |
    # TODO(Xuntao): Fix null-related issues while parsing tck.
    # https://github.com/vesoft-inc/nebula-ng/issues/5331
    # When executing query:
    # """
    # RETURN LIST [3.33, 4, null] AS a
    # """
    # Then the result should be, in any order:
    # | a                      |
    # | LIST [3.33, 4.0, null] |
    When executing query:
      """
      RETURN LIST [null] AS a
      """
    Then the result should be, in any order:
      | a           |
      | LIST [null] |
    When executing query:
      """
      RETURN length(LIST [null]) AS a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    # TODO(Xuntao): Fix null-related issues while parsing tck.
    # https://github.com/vesoft-inc/nebula-ng/issues/5331
    # When executing query:
    # """
    # RETURN LIST [null, LIST [1, 2.5]] AS a
    # """
    # Then the result should be, in any order:
    # | a                            |
    # | LIST [null, LIST [1.0, 2.5]] |
    When executing query:
      """
      RETURN LIST [1, LIST [2, 3]] AS a
      """
    Then an Error should be raised: "[NR013]: All elements of list constructor must have compatible types"
    When executing query:
      """
      RETURN LIST ["你好", 3.33, 3, date("2023-11-30", "%Y-%m-%d")] AS a
      """
    Then an Error should be raised: "[NR013]: All elements of list constructor must have compatible types"
    When executing query:
      """
      RETURN [[NULL], [1]] as a
      """
    Then the result should be, in any order:
      | a                             |
      | LIST [ LIST [null], LIST [1]] |
    When executing query:
      """
      RETURN [[1], [1.5]] as a
      """
    Then the result should be, in any order:
      | a                                |
      | LIST [ LIST [1.0M], LIST [1.5M]] |
    When executing query:
      """
      RETURN [{p: 1}, {p: 1.5}] as a
      """
    Then the result should be, in any order:
      | a                                         |
      | LIST [ RECORD {p: 1.0}, RECORD {p: 1.5} ] |
    When executing query:
      """
      RETURN LIST[RECORD{a:1},RECORD{a:"x"}]
      """
    Then an Error should be raised: "[NR013]: All elements of list constructor must have compatible types"
    When executing query:
      """
      RETURN LIST[RECORD{a:1,b:"y"},RECORD{a:1}]
      """
    Then an Error should be raised: "[NR013]: All elements of list constructor must have compatible types"
    When executing query:
      """
      RETURN LIST[RECORD{a:1},RECORD{a:1,b:"y"}]
      """
    Then an Error should be raised: "[NR013]: All elements of list constructor must have compatible types"
    When executing query:
      """
      RETURN LIST[RECORD{a:1},RECORD{b:1}]
      """
    Then an Error should be raised: "[NR013]: All elements of list constructor must have compatible types"
    When executing query:
      """
      RETURN LIST[LIST[1,2],LIST["x","y"]]
      """
    Then an Error should be raised: "[NR013]: All elements of list constructor must have compatible types"
    When executing query:
      """
      USE ldbc MATCH (v1:Comment), (v2:Post)
      RETURN LIST [v1, v2]
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc MATCH ()-[e1:KNOWS]-(), ()-[e2:LIKES]-()
      RETURN LIST [e1, e2]
      """
    Then the execution should be successful
    When executing query:
      """
      LET ldt = DATETIME "2024-05-31T15:38:14.000213",
          d   = DATE "2024-05-31"
      RETURN [ldt, d] as a
      """
    Then the result should be, in any order:
      | a                                                                                    |
      | LIST [ DATETIME "2024-05-31T15:38:14.000213", DATETIME "2024-05-31T00:00:00.000000"] |

  Scenario: Construct Record
    When executing query:
      """
      RETURN Record {} as a
      """
    Then the result should be, in any order:
      | a         |
      | Record {} |
    When executing query:
      """
      RETURN RECORD {a: 1, b: 2, c: 3} as a
      """
    Then the result should be, in any order:
      | a                         |
      | Record {a: 1, b: 2, c: 3} |
    When executing query:
      """
      RETURN RECORD {a: RECORD {b: 1}} as r
      """
    Then the result should be, in any order:
      | r           |
      | {a: {b: 1}} |
    When executing query:
      """
      RETURN RECORD {a: 1, a: 2} as r
      """
    Then an Error should be raised: "[NR015]: Record could only contain unique field names"
    When executing query:
      """
      RETURN RECORD {p1: 1, p2: 1.5} as a
      """
    Then the result should be, in any order:
      | a                          |
      | Record {p1: 1.0,  p2: 1.5} |

  Scenario: Construct Set
    When executing query:
      """
      RETURN set {} as a
      """
    Then the result should be, in any order:
      | a     |
      | SET{} |
    When executing query:
      """
      RETURN set{1} as a
      """
    Then the result should be, in any order:
      | a       |
      | SET {1} |
    When executing query:
      """
      RETURN set {"a","b"} as a
      """
    Then the result should be, in any order:
      | a              |
      | SET {"a", "b"} |
    When executing query:
      """
      RETURN SET {null} AS a
      """
    Then the result should be, in any order:
      | a          |
      | SET {null} |
    When executing query:
      """
      RETURN length(SET {null}) AS a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      RETURN SET {1, SET {2, 3}} AS a
      """
    Then an Error should be raised: "[NR030]: All elements of set constructor must have compatible types"
    When executing query:
      """
      RETURN SET {"你好", 3.33, 3, date("2023-11-30", "%Y-%m-%d")} AS a
      """
    Then an Error should be raised: "[NR030]: All elements of set constructor must have compatible types"
    When executing query:
      """
      RETURN SET{SET{1.5}, SET{1}} as a
      """
    Then the result should be, in any order:
      | a                            |
      | SET {SET {1.5M}, SET {1.0M}} |
    When executing query:
      """
      RETURN SET{RECORD{a:1},RECORD{a:"x"}}
      """
    Then an Error should be raised: "[NR030]: All elements of set constructor must have compatible types"
    When executing query:
      """
      RETURN SET{RECORD{a:1,b:"y"},RECORD{a:1}}
      """
    Then an Error should be raised: "[NR030]: All elements of set constructor must have compatible types"
    When executing query:
      """
      RETURN SET{RECORD{a:1},RECORD{a:1,b:"y"}}
      """
    Then an Error should be raised: "[NR030]: All elements of set constructor must have compatible types"
    When executing query:
      """
      RETURN SET{RECORD{a:1},RECORD{b:1}}
      """
    Then an Error should be raised: "[NR030]: All elements of set constructor must have compatible types"
    When executing query:
      """
      RETURN SET{SET{1,2},SET{"x","y"}}
      """
    Then an Error should be raised: "[NR030]: All elements of set constructor must have compatible types"
    When executing query:
      """
      USE ldbc MATCH (v1:Comment), (v2:Post)
      RETURN SET {v1, v2}
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc MATCH ()-[e1:KNOWS]-(), ()-[e2:LIKES]-()
      RETURN SET {e1, e2}
      """
    Then the execution should be successful
    When executing query:
      """
      LET ldt = DATETIME "2024-05-31T15:38:14.000213",
          d   = DATE "2024-05-31"
      RETURN SET {ldt, d} as a
      """
    Then the result should be, in any order:
      | a                                                                                   |
      | SET { DATETIME "2024-05-31T15:38:14.000213", DATETIME "2024-05-31T00:00:00.000000"} |

  Scenario: Construct Map
    When executing query:
      """
      RETURN map {} as a
      """
    Then the result should be, in any order:
      | a     |
      | MAP{} |
    When executing query:
      """
      RETURN map{1:"value"} as a
      """
    Then the result should be, in any order:
      | a               |
      | MAP {1:"value"} |
    When executing query:
      """
      RETURN map {"a":"b"} as a
      """
    Then the result should be, in any order:
      | a             |
      | MAP {"a":"b"} |
    When executing query:
      """
      RETURN MAP {null:null} AS a
      """
    Then the result should be, in any order:
      | a               |
      | MAP {null:null} |
    When executing query:
      """
      RETURN MAP {null:1} AS a
      """
    Then the result should be, in any order:
      | a            |
      | MAP {null:1} |
    When executing query:
      """
      RETURN length(MAP {null:null, null:1}) AS a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      RETURN MAP {1: MAP {2:3}, "test" : MAP {2:3}} AS a
      """
    Then an Error should be raised: "[NR031]: All keys or values of map constructor must have compatible types"
    When executing query:
      """
      RETURN MAP {1.0:3.33, 3 : date("2023-11-30", "%Y-%m-%d")} AS a
      """
    Then an Error should be raised: "[NR031]: All keys or values of map constructor must have compatible types"
    When executing query:
      """
      RETURN MAP{MAP{"key1":1.5}: MAP{"key2":1}} as a
      """
    Then the result should be, in any order:
      | a                                          |
      | MAP { MAP {"key1":1.5M}:MAP {"key2":1.0M}} |
    When executing query:
      """
      RETURN MAP{1:RECORD{a:1},2:RECORD{a:"x"}}
      """
    Then an Error should be raised: "[NR031]: All keys or values of map constructor must have compatible types"
    When executing query:
      """
      RETURN MAP{RECORD{a:1,b:"y"}:1,RECORD{a:1}:1}
      """
    Then an Error should be raised: "[NR031]: All keys or values of map constructor must have compatible types"
    When executing query:
      """
      RETURN MAP{1:RECORD{a:1,b:"y"},2:RECORD{a:1}}
      """
    Then an Error should be raised: "[NR031]: All keys or values of map constructor must have compatible types"
    When executing query:
      """
      RETURN MAP{MAP{1:1}:MAP{1:2},MAP{2:3}:MAP{"x":"y"}}
      """
    Then an Error should be raised: "[NR031]: All keys or values of map constructor must have compatible types"
    When executing query:
      """
      LET ldt = DATETIME "2024-05-31T15:38:14.000213",
          d   = DATE "2024-05-31"
      RETURN MAP {1:ldt, 2:d} as a
      """
    Then the result should be, in any order:
      | a                                                                                       |
      | MAP { 1:DATETIME "2024-05-31T15:38:14.000213", 2:DATETIME "2024-05-31T00:00:00.000000"} |
