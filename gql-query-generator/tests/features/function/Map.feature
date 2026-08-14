# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: Map Function

  Scenario: Length/Size
    When executing query:
      """
      RETURN length(MAP{1:"value", 2:"value", 3:"value"}) as a, size(MAP{}) as b
      """
    Then the result should be, in any order:
      | a | b |
      | 3 | 0 |
    When executing query:
      """
      RETURN size(MAP{1:"value", 2:"value", 1:"value"}) as a
      """
    Then the result should be, in any order:
      | a |
      | 2 |

  Scenario: In Map
    When executing query:
      """
      LET m = Map {1:"value", 2:"value", 3:"value"}
      RETURN 1 IN m as a, 4 IN m as b
      """
    Then the result should be, in any order:
      | a    | b     |
      | true | false |
    When executing query:
      """
      LET m = Map {1:"value", 2:"value", 3:"value"}
      RETURN 1 NOT IN m as a, 4 NOT IN m as b
      """
    Then the result should be, in any order:
      | a     | b    |
      | false | true |
    When executing query:
      """
      RETURN 1 IN Map {1:"value", 4.4:"value"} as a
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      RETURN 1 NOT IN MAP {4.4:"value", 1:"value"} as a
      """
    Then the result should be, in any order:
      | a     |
      | false |
    When executing query:
      """
      RETURN 1 NOT IN MAP {} as a
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      RETURN 1 IN MAP {} as a
      """
    Then the result should be, in any order:
      | a     |
      | false |
    When executing query:
      """
      RETURN DATE "2023-01-01" in map{DATETIME "2023-01-01T00:00:00":null} as a
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      RETURN DATE "2023-01-01" in map{DATETIME "2023-01-01T00:00:05":"value"} as a
      """
    Then the result should be, in any order:
      | a     |
      | false |
    When executing query:
      """
      RETURN zoned_datetime("2012-03-04T05:06:07.0890", "%Y-%m-%dT%H:%M:%S") in map {zoned_datetime("2012-03-04T05:06:07.0890", "%Y-%m-%dT%H:%M:%S"):"value"} AS a
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      RETURN zoned_datetime("2012-03-04T05:06:07.0890", "%Y-%m-%dT%H:%M:%S") not in map {zoned_datetime("2012-03-04T05:06:07.0890", "%Y-%m-%dT%H:%M:%S"):"value"} AS a
      """
    Then the result should be, in any order:
      | a     |
      | false |
    When executing query:
      """
      RETURN zoned_time("05:06:07.0890 -0200") in Map {zoned_time("05:06:07.0890 -0200"):1} AS a
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      RETURN zoned_time("05:06:07.0890 -0200") not in map {zoned_time("05:06:07.0890 -0200"):null} AS a
      """
    Then the result should be, in any order:
      | a     |
      | false |
    When executing query:
      """
      RETURN "str" in MAP{null:null} AS a
      """
    Then the result should be, in any order:
      | a     |
      | false |

  Scenario: Concat Map
    When executing query:
      """
      RETURN map{1:"value",2:"value",3:"value"}|| null as a, null || map{null:true} AS b
      """
    Then the result should be, in any order:
      | a    | b    |
      | null | null |
    When executing query:
      """
      RETURN map{}||map{} as a, map{}||map{1:"value",2:"value",3:"value"} as b, map{1:"value",2:"value",3:"value"}||map{} as c
      """
    Then the result should be, in any order:
      | a     | b                                  | c                                  |
      | MAP{} | MAP{1:"value",2:"value",3:"value"} | MAP{1:"value",2:"value",3:"value"} |
    When executing query:
      """
      RETURN map{1.1:map{1:"v",2:"v"}, 2:map{3:"v", null:"v"}} || map{3:map{4:"v",5:"v"}, 4:map{34:"v",45:"v"}} as a
      """
    Then the result should be, in any order:
      | a                                                                                                       |
      | MAP  {1.1M:MAP {1:"v",2:"v"},2.0M:MAP {3:"v",null:"v"},3.0M:MAP {4:"v",5:"v"},4.0M:MAP {34:"v",45:"v"}} |
    When executing query:
      """
      RETURN MAP{true:null, false:null, null:null} || map{null:null,true:null} AS a
      """
    Then the result should be, in any order:
      | a                                    |
      | map {true:null,false:null,null:null} |
    When executing query:
      """
      RETURN MAP{null:true} || map{null:false} AS a
      """
    Then the result should be, in any order:
      | a               |
      | map {null:true} |
    When executing query:
      """
      RETURN map{null:null} || map{} || map{} || map{null:null} AS a
      """
    Then the result should be, in any order:
      | a               |
      | MAP {null:null} |
    When executing query:
      """
      RETURN map{map{null:null}:"value",map{}:"value"} || Map{map{}:"value"} || Map{map{} ||map{null:null}:"value"} AS a
      """
    Then the result should be, in any order:
      | a                                             |
      | MAP  {MAP {null:null}:"value", MAP{}:"value"} |
    When executing query:
      """
      RETURN Map{"key1":true, "key2":false, "key3":null} || Map{"key":1} AS a
      """
    Then an Error should be raised: "[NR006]: Resolve function failed: `The map element valueType mismatch: BOOL vs INT32`"

  Scenario: Filter
    # Filter out null key
    When executing query:
      """
      RETURN map_filter(MAP{1:"a", 2:"b", null:null}, (k, v) -> k IS NOT NULL) AS a
      """
    Then the result should be, in any order:
      | a                |
      | MAP{1:"a",2:"b"} |
    # Filter by value: keep non-null value
    When executing query:
      """
      RETURN map_filter(MAP{1:"a", 2:null, 3:"c"}, (k, v) -> v IS NOT NULL) AS a
      """
    Then the result should be, in any order:
      | a                |
      | MAP{1:"a",3:"c"} |
    # Filter by both key and value
    When executing query:
      """
      RETURN map_filter(MAP{1:"a", 2:"b", 3:"a", 4:"x"}, (k, v) -> k >= 2 AND v <> "a") AS a
      """
    Then the result should be, in any order:
      | a                |
      | MAP{2:"b",4:"x"} |
    # Empty map: predicate not applied
    When executing query:
      """
      RETURN map_filter(MAP{}, (k, v) -> k IS NOT NULL) AS a
      """
    Then the result should be, in any order:
      | a     |
      | MAP{} |
    # All pass: predicate always true
    When executing query:
      """
      RETURN map_filter(MAP{1:"a", 2:"b"}, (k, v) -> true) AS a
      """
    Then the result should be, in any order:
      | a                |
      | MAP{1:"a",2:"b"} |
    # Filter by value string
    When executing query:
      """
      RETURN map_filter(MAP{"x":"yes", "y":"no", "z":"yes"}, (k, v) -> v = "yes") AS a
      """
    Then the result should be, in any order:
      | a                        |
      | MAP{"x":"yes","z":"yes"} |
    # Filter const map with capture
    When executing query:
      """
      FOR i IN [0, 5, 2]
      RETURN map_filter(MAP{1:"a", 2:"b", 3:"c"}, (k, v) -> k > i) AS a
      """
    Then the result should be, in any order:
      | a                      |
      | MAP{1:"a",2:"b",3:"c"} |
      | MAP{}                  |
      | MAP{3:"c"}             |
    # Filter flat map with capture
    When executing query:
      """
      LET threshold = 2
      FOR m IN [MAP{1:"a",2:"b"}, MAP{1:"x",2:"y",3:"z"}]
      RETURN map_filter(m, (k, v) -> k >= threshold) AS a
      """
    Then the result should be, in any order:
      | a                |
      | MAP{2:"b"}       |
      | MAP{2:"y",3:"z"} |
    # Filter flat map with NULL and empty map
    When executing query:
      """
      FOR m IN [MAP{1:"a"}, NULL, MAP{}, MAP{2:"b"}]
      RETURN map_filter(m, (k, v) -> k > 0) AS a
      """
    Then the result should be, in any order:
      | a          |
      | MAP{1:"a"} |
      | NULL       |
      | MAP{}      |
      | MAP{2:"b"} |
    # Direct NULL input
    When executing query:
      """
      RETURN map_filter(NULL, (k, v) -> k > 1) AS a
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    # NULL input with variable
    When executing query:
      """
      LET m = NULL
      RETURN map_filter(m, (k, v) -> v IS NOT NULL) AS a
      """
    Then the result should be, in any order:
      | a    |
      | NULL |

  Scenario: Map Remove Null
    When executing query:
      """
      RETURN remove_nulls(MAP{1:"a", 2:"b", null:null}) AS a
      """
    Then the result should be, in any order:
      | a                |
      | MAP{1:"a",2:"b"} |
    When executing query:
      """
      RETURN remove_nulls(MAP{null:1,2:null}) AS a
      """
    Then the result should be, in any order:
      | a                  |
      | MAP{null:1,2:null} |

  Scenario: Map Append
    # Basic append with non-null values
    When executing query:
      """
      RETURN map_append(MAP{1:"a", 2:"b"}, 3, "c") AS a
      """
    Then the result should be, in any order:
      | a                      |
      | MAP{1:"a",2:"b",3:"c"} |
    # Append to empty map
    When executing query:
      """
      RETURN map_append(MAP{}, 1, "value") AS a
      """
    Then the result should be, in any order:
      | a              |
      | MAP{1:"value"} |
    # Override existing key
    When executing query:
      """
      RETURN map_append(MAP{1:"old"}, 1, "new") AS a
      """
    Then the result should be, in any order:
      | a            |
      | MAP{1:"old"} |
    # Append with null key
    When executing query:
      """
      RETURN map_append(MAP{1:"a"}, null, "b") AS a
      """
    Then the result should be, in any order:
      | a                   |
      | MAP{1:"a",null:"b"} |
    # Append with null value
    When executing query:
      """
      RETURN map_append(MAP{1:"a"}, 2, null) AS a
      """
    Then the result should be, in any order:
      | a                 |
      | MAP{1:"a",2:null} |
    # Append null key and null value
    When executing query:
      """
      RETURN map_append(MAP{1:"a"}, null, null) AS a
      """
    Then the result should be, in any order:
      | a                    |
      | MAP{1:"a",null:null} |
    # INT8 type
    When executing query:
      """
      RETURN map_append(MAP{CAST(1 AS INT8):true}, CAST(2 AS INT8), false) AS a
      """
    Then the result should be, in any order:
      | a                   |
      | MAP{1:true,2:false} |
    # INT16 type
    When executing query:
      """
      RETURN map_append(MAP{CAST(1 AS INT16):1}, CAST(2 AS INT16), 2) AS a
      """
    Then the result should be, in any order:
      | a            |
      | MAP{1:1,2:2} |
    # INT32 type
    When executing query:
      """
      RETURN map_append(MAP{1:10}, 2, 20) AS a
      """
    Then the result should be, in any order:
      | a              |
      | MAP{1:10,2:20} |
    # INT64 type
    When executing query:
      """
      RETURN map_append(MAP{CAST(1 AS INT64):100}, CAST(2 AS INT64), 200) AS a
      """
    Then the result should be, in any order:
      | a                |
      | MAP{1:100,2:200} |
    # UINT8 type
    When executing query:
      """
      RETURN map_append(MAP{CAST(1 AS UINT8):"a"}, CAST(2 AS UINT8), "b") AS a
      """
    Then the result should be, in any order:
      | a                |
      | MAP{1:"a",2:"b"} |
    # UINT16 type
    When executing query:
      """
      RETURN map_append(MAP{CAST(100 AS UINT16):true}, CAST(200 AS UINT16), false) AS a
      """
    Then the result should be, in any order:
      | a                       |
      | MAP{100:true,200:false} |
    # UINT32 type
    When executing query:
      """
      RETURN map_append(MAP{CAST(1000 AS UINT32):1.1}, CAST(2000 AS UINT32), 2.2) AS a
      """
    Then the result should be, in any order:
      | a                        |
      | MAP{1000:1.1M,2000:2.2M} |
    # UINT64 type
    When executing query:
      """
      RETURN map_append(MAP{CAST(10000 AS UINT64):"x"}, CAST(20000 AS UINT64), "y") AS a
      """
    Then the result should be, in any order:
      | a                        |
      | MAP{10000:"x",20000:"y"} |
    Then the result should be, in any order:
      | a                    |
      | MAP{1.5:"a",2.5:"b"} |
    # DECIMAL type
    When executing query:
      """
      RETURN map_append(MAP{1.1M:100}, 2.2M, 200) AS a
      """
    Then the result should be, in any order:
      | a                      |
      | MAP{1.1M:100,2.2M:200} |
    # STRING type
    When executing query:
      """
      RETURN map_append(MAP{"key1":"value1"}, "key2", "value2") AS a
      """
    Then the result should be, in any order:
      | a                                    |
      | MAP{"key1":"value1","key2":"value2"} |
    # BOOL type
    When executing query:
      """
      RETURN map_append(MAP{true:1, false:2}, null, 3) AS a
      """
    Then the result should be, in any order:
      | a                          |
      | MAP{true:1,false:2,null:3} |
    # DATE type
    When executing query:
      """
      RETURN map_append(MAP{DATE "2023-01-01":"val1"}, DATE "2023-12-31", "val2") AS a
      """
    Then the result should be, in any order:
      | a                                                      |
      | MAP{DATE "2023-01-01":"val1",DATE "2023-12-31":"val2"} |
    # LOCALDATETIME type
    When executing query:
      """
      RETURN map_append(MAP{DATETIME "2023-01-01T10:00:00":1}, DATETIME "2023-12-31T23:59:59", 2) AS a
      """
    Then the result should be, in any order:
      | a                                                                      |
      | MAP{DATETIME "2023-01-01T10:00:00":1,DATETIME "2023-12-31T23:59:59":2} |
    # LOCALTIME type
    When executing query:
      """
      RETURN map_append(MAP{TIME "10:00:00":true}, TIME "23:59:59", false) AS a
      """
    Then the result should be, in any order:
      | a                                               |
      | MAP{TIME "10:00:00":true,TIME "23:59:59":false} |
    Then the result should be, in any order:
      | a                                                |
      | MAP{DURATION "P1D":"day1",DURATION "P2D":"day2"} |
    # LIST type value
    When executing query:
      """
      RETURN map_append(MAP{1:LIST[1,2]}, 2, LIST[3,4]) AS a
      """
    Then the result should be, in any order:
      | a                            |
      | MAP{1:LIST[1,2],2:LIST[3,4]} |
    # MAP type value
    When executing query:
      """
      RETURN map_append(MAP{1:MAP{10:"a"}}, 2, MAP{20:"b"}) AS a
      """
    Then the result should be, in any order:
      | a                                |
      | MAP{1:MAP{10:"a"},2:MAP{20:"b"}} |
    # SET type value
    When executing query:
      """
      RETURN map_append(MAP{"k1":SET{1,2}}, "k2", SET{3,4}) AS a
      """
    Then the result should be, in any order:
      | a                                |
      | MAP{"k1":SET{1,2},"k2":SET{3,4}} |
    # RECORD type value
    When executing query:
      """
      RETURN map_append(MAP{1:RECORD{a:1}}, 2, RECORD{a:2}) AS a
      """
    Then the result should be, in any order:
      | a                                |
      | MAP{1:RECORD{a:1},2:RECORD{a:2}} |
    # VECTOR type value
    When executing query:
      """
      RETURN map_append(MAP{1:VECTOR<2,float>([1.0,2.0])}, 2, VECTOR<2,float>([3.0,4.0])) AS a
      """
    Then the result should be, in any order:
      | a                                        |
      | MAP{1:VECTOR[1.0,2.0],2:VECTOR[3.0,4.0]} |
    # Null map should raise error
    When executing query:
      """
      RETURN map_append(null, 1, "value") AS a
      """
    Then the result should be, in any order:
      | a    |
      | null |
    # Type mismatch - key type
    When executing query:
      """
      RETURN map_append(MAP{1:"a"}, "key", "b") AS a
      """
    Then an Error should be raised: "[NR006]: Resolve function failed: `The map element key type mismatch: INT32 vs STRING`"
    # Type mismatch - value type
    When executing query:
      """
      RETURN map_append(MAP{1:"a"}, 2, 100) AS a
      """
    Then an Error should be raised: "[NR006]: Resolve function failed: `The map element value type mismatch: STRING vs INT32`"
    When executing query:
      """
      RETURN map_append(null, 2, 100) AS a
      """
    Then the result should be, in any order:
      | a    |
      | null |

  Scenario: Map Replace
    # key exists, replace value
    When executing query:
      """
      RETURN map_replace(MAP{1:"old", 2:"b"}, 1, "new") AS a
      """
    Then the result should be, in any order:
      | a                  |
      | MAP{1:"new",2:"b"} |
    When executing query:
      """
      RETURN map_replace(MAP{null:"a"}, null, "b") AS a
      """
    Then the result should be, in any order:
      | a             |
      | MAP{null:"b"} |
    # key doesn't exist, throw error
    When executing query:
      """
      RETURN map_replace(MAP{1:"a", 2:"b"}, 3, "c") AS a
      """
    Then an Error should be raised: "[NR003]: Invalid function argument: map_replace: key not found"
    # Type mismatch - key type
    When executing query:
      """
      RETURN map_replace(MAP{1:"a"}, "key", "b") AS a
      """
    Then an Error should be raised: "[NR006]: Resolve function failed: `The map element key type mismatch: INT32 vs STRING`"
    # Type mismatch - value type
    When executing query:
      """
      RETURN map_replace(MAP{1:"a"}, 1, 100) AS a
      """
    Then an Error should be raised: "[NR006]: Resolve function failed: `The map element value type mismatch: STRING vs INT32`"

  Scenario: Map Keys/Values
    When executing query:
      """
      RETURN map_keys(MAP{1:"a", 2:"b"}) AS a
      """
    Then the result should be, in any order:
      | a           |
      | LIST [1, 2] |
    When executing query:
      """
      RETURN map_values(MAP{1:"a", 2:"a"}) AS a
      """
    Then the result should be, in any order:
      | a               |
      | LIST ["a", "a"] |
    When executing query:
      """
      RETURN map_keys(MAP{null:null}) AS a
      """
    Then the result should be, in any order:
      | a           |
      | LIST [null] |
    When executing query:
      """
      RETURN map_values(MAP{}) AS a
      """
    Then the result should be, in any order:
      | a       |
      | LIST [] |

  Scenario: Map Remove
    When executing query:
      """
      RETURN map_remove(MAP{1:"a", 2:"b"}, 1) AS a
      """
    Then the result should be, in any order:
      | a          |
      | MAP{2:"b"} |
    When executing query:
      """
      RETURN map_remove(MAP{null:"a"}, 1) AS a
      """
    Then the result should be, in any order:
      | a             |
      | MAP{null:"a"} |
    When executing query:
      """
      RETURN map_remove(MAP{}, 1) AS a
      """
    Then the result should be, in any order:
      | a     |
      | MAP{} |
    When executing query:
      """
      RETURN map_remove(MAP{null:"a"}, null) AS a
      """
    Then the result should be, in any order:
      | a     |
      | MAP{} |
    When executing query:
      """
      RETURN map_remove(MAP{1:"a"}, "key") AS a
      """
    Then an Error should be raised: "[NR006]: Resolve function failed: `The map element key type mismatch: INT32 vs STRING"

  Scenario: Map Union
    When executing query:
      """
      RETURN map_union(MAP{1:"a", 2:"b"}, MAP{3:"c", 4:"d"}) AS a
      """
    Then the result should be, in any order:
      | a                            |
      | MAP{1:"a",2:"b",3:"c",4:"d"} |
    When executing query:
      """
      RETURN map_union(MAP{null:"a"}, MAP{null:"b"}) AS a
      """
    Then an Error should be raised: "[NR003]: Invalid function argument: map_union: duplicate key with different value"
    When executing query:
      """
      RETURN map_union(MAP{}, MAP{1:"a"}) AS a
      """
    Then the result should be, in any order:
      | a          |
      | MAP{1:"a"} |
    When executing query:
      """
      RETURN map_union(MAP{1:"a"}, MAP{1:"a"}) AS a
      """
    Then the result should be, in any order:
      | a          |
      | MAP{1:"a"} |

  Scenario: Map Intersect
    When executing query:
      """
      RETURN map_intersect(MAP{1:"a", 2:"b"}, MAP{1:"a", 4:"d"}) AS a
      """
    Then the result should be, in any order:
      | a          |
      | MAP{1:"a"} |
    When executing query:
      """
      RETURN map_intersect(MAP{null:"a"}, MAP{null:"b"}) AS a
      """
    Then the result should be, in any order:
      | a     |
      | MAP{} |

  Scenario: Map Except
    When executing query:
      """
      RETURN map_except(MAP{1:"a", 2:"b"}, MAP{3:"c", 4:"d"}) AS a
      """
    Then the result should be, in any order:
      | a                |
      | MAP{1:"a",2:"b"} |
    When executing query:
      """
      RETURN map_except(MAP{null:"a"}, MAP{null:"b"}) AS a
      """
    Then the result should be, in any order:
      | a             |
      | MAP{null:"a"} |
    When executing query:
      """
      RETURN map_except(MAP{}, MAP{1:"a"}) AS a
      """
    Then the result should be, in any order:
      | a     |
      | MAP{} |
    When executing query:
      """
      RETURN map_except(MAP{1:"a"}, MAP{1:"a"}) AS a
      """
    Then the result should be, in any order:
      | a     |
      | MAP{} |

  Scenario: Map ElementAt
    When executing query:
      """
      RETURN element_at(MAP{1:"a", 2:"b"}, 1) AS a
      """
    Then the result should be, in any order:
      | a   |
      | "a" |
    When executing query:
      """
      RETURN element_at(MAP{}, 1) AS a
      """
    Then the result should be, in any order:
      | a    |
      | null |
    When executing query:
      """
      RETURN element_at(MAP{null:"a"}, null) AS a
      """
    Then the result should be, in any order:
      | a   |
      | "a" |
