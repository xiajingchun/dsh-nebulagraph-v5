# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: Set Function

  Scenario: Length/Size
    When executing query:
      """
      RETURN length(SET{1, 2, 3}) as a, size(SET{}) as b
      """
    Then the result should be, in any order:
      | a | b |
      | 3 | 0 |
    When executing query:
      """
      RETURN size(SET{1, 2, 1}) as a
      """
    Then the result should be, in any order:
      | a |
      | 2 |

  Scenario: In Set
    When executing query:
      """
      LET s = SET {1, 2, 3}
      RETURN 1 IN s as a, 4 IN s as b
      """
    Then the result should be, in any order:
      | a    | b     |
      | true | false |
    When executing query:
      """
      LET s = SET {1, 2, 3}
      RETURN 1 NOT IN s as a, 4 NOT IN s as b
      """
    Then the result should be, in any order:
      | a     | b    |
      | false | true |
    When executing query:
      """
      RETURN 1 IN SET {1, 4.4} as a
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      RETURN 1 NOT IN SET {4.4, 1} as a
      """
    Then the result should be, in any order:
      | a     |
      | false |
    When executing query:
      """
      RETURN 1 NOT IN SET {} as a
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      RETURN 1 IN SET {} as a
      """
    Then the result should be, in any order:
      | a     |
      | false |
    When executing query:
      """
      RETURN DATE "2023-01-01" in SET{DATETIME "2023-01-01T00:00:00"} as a
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      RETURN DATE "2023-01-01" in SET{DATETIME "2023-01-01T00:00:05"} as a
      """
    Then the result should be, in any order:
      | a     |
      | false |
    When executing query:
      """
      RETURN zoned_datetime("2012-03-04T05:06:07.0890", "%Y-%m-%dT%H:%M:%S") in SET {zoned_datetime("2012-03-04T05:06:07.0890", "%Y-%m-%dT%H:%M:%S")} AS a
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      RETURN zoned_datetime("2012-03-04T05:06:07.0890", "%Y-%m-%dT%H:%M:%S") not in set {zoned_datetime("2012-03-04T05:06:07.0890", "%Y-%m-%dT%H:%M:%S")} AS a
      """
    Then the result should be, in any order:
      | a     |
      | false |
    When executing query:
      """
      RETURN zoned_time("05:06:07.0890 -0200") in Set {zoned_time("05:06:07.0890 -0200")} AS a
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      RETURN zoned_time("05:06:07.0890 -0200") not in set {zoned_time("05:06:07.0890 -0200")} AS a
      """
    Then the result should be, in any order:
      | a     |
      | false |
    When executing query:
      """
      RETURN "str" in SET{null} AS a
      """
    Then the result should be, in any order:
      | a     |
      | false |

  Scenario: Set Concat/Union
    When executing query:
      """
      RETURN set{1,2,3}|| null as a, null || set{true} AS b
      """
    Then the result should be, in any order:
      | a    | b    |
      | null | null |
    When executing query:
      """
      RETURN set{}||set{} as a, set{}||set{1,2,3} as b, set{1,2,3}||set{} as c
      """
    Then the result should be, in any order:
      | a     | b          | c          |
      | SET{} | SET{1,2,3} | SET{1,2,3} |
    When executing query:
      """
      RETURN set{set{1,2,3}, set{3, null}} || set{set{4,5,6}, set{34,45}} as a
      """
    Then the result should be, in any order:
      | a                                                       |
      | SET  {SET {1,2,3},SET {3,null},SET {4,5,6},SET {34,45}} |
    When executing query:
      """
      RETURN Set{true, false, null} || set{null,true} AS a
      """
    Then the result should be, in any order:
      | a                     |
      | SET {true,false,null} |
    When executing query:
      """
      RETURN set{null,null} || set{null} || set_union(set{}, set{null}) AS a
      """
    Then the result should be, in any order:
      | a          |
      | SET {null} |
    When executing query:
      """
      RETURN set{set{null,null},set{}} || SET{SET{}} || SET{set{} ||set{null}} AS a
      """
    Then the result should be, in any order:
      | a                        |
      | SET  {SET {null},SET {}} |
    When executing query:
      """
      RETURN SET{true, false, null} || SET{null,1} AS a
      """
    Then an Error should be raised: "[NR006]: Resolve function failed: `The set element type mismatch: BOOL vs INT32`"
    When executing query:
      """
      RETURN SET{1,2,3} || SET{3.3, 4.4} AS a
      """
    Then the result should be, in any order:
      | a                                  |
      | SET {1.0M, 2.0M, 3.0M, 3.3M, 4.4M} |
    When executing query:
      """
      RETURN set{set{1,2,3.3, null}} || set{set{4,5,6}, set{34,45}} as a
      """
    Then the result should be, in any order:
      | a                                                                               |
      | SET { SET {1.0M, 2.0M, 3.3M, null}, SET {4.0M, 5.0M, 6.0M}, SET {34.0M, 45.0M}} |

  Scenario: Set Append
    When executing query:
      """
      RETURN set_append(SET{1, 2, 3}, 4) AS a
      """
    Then the result should be, in any order:
      | a            |
      | SET{1,2,3,4} |
    When executing query:
      """
      RETURN set_append(SET{null}, null) AS a
      """
    Then the result should be, in any order:
      | a         |
      | SET{null} |
    When executing query:
      """
      RETURN set_append(SET{1}, null) AS a
      """
    Then the result should be, in any order:
      | a           |
      | SET{1,null} |
    When executing query:
      """
      RETURN set_append(SET{}, null) AS a
      """
    Then the result should be, in any order:
      | a         |
      | SET{null} |

  Scenario: Set Remove Null
    When executing query:
      """
      RETURN remove_nulls(SET{1, 2, null}) AS a
      """
    Then the result should be, in any order:
      | a        |
      | SET{1,2} |
    When executing query:
      """
      RETURN remove_nulls(SET{null}) AS a
      """
    Then the result should be, in any order:
      | a     |
      | SET{} |

  Scenario: Set Remove
    When executing query:
      """
      RETURN set_remove(SET{1, 2, 3}, 1) AS a
      """
    Then the result should be, in any order:
      | a        |
      | SET{2,3} |
    When executing query:
      """
      RETURN set_remove(SET{null}, 1) AS a
      """
    Then the result should be, in any order:
      | a         |
      | SET{null} |
    When executing query:
      """
      RETURN set_remove(SET{}, 1) AS a
      """
    Then the result should be, in any order:
      | a     |
      | SET{} |
    When executing query:
      """
      RETURN set_remove(SET{null}, null) AS a
      """
    Then the result should be, in any order:
      | a     |
      | SET{} |
    When executing query:
      """
      RETURN set_remove(SET{1, 2, 3}, "key") AS a
      """
    Then an Error should be raised: "[NR006]: Resolve function failed: `The set element type mismatch: INT32 vs STRING"

  Scenario: Set Sum
    When executing query:
      """
      RETURN set_sum(SET{null}) AS a
      """
    Then the result should be, in any order:
      | a |
      | 0 |
    When executing query:
      """
      RETURN set_sum(SET{1, null}) AS a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      RETURN set_sum(SET{1.0M, 2M}) AS a
      """
    Then the result should be, in any order:
      | a    |
      | 3.0M |
    When executing query:
      """
      RETURN set_sum(SET{1.0M, 2M, NAN}) AS a
      """
    Then the result should be, in any order:
      | a   |
      | NaN |
    When executing query:
      """
      RETURN set_sum(SET{1.0M, 2M, NAN, NULL}) AS a
      """
    Then the result should be, in any order:
      | a   |
      | NaN |

  Scenario: Set Max
    When executing query:
      """
      RETURN set_max(SET{null}) AS a
      """
    Then the result should be, in any order:
      | a    |
      | null |
    When executing query:
      """
      RETURN set_max(SET{1, 2, 3.0M}) AS a
      """
    Then the result should be, in any order:
      | a    |
      | 3.0M |
    When executing query:
      """
      RETURN set_max(SET{1.0M, 2M, NAN}) AS a
      """
    Then the result should be, in any order:
      | a   |
      | NaN |
    When executing query:
      """
      RETURN set_max(SET{20, 30, NAN}) AS a
      """
    Then the result should be, in any order:
      | a   |
      | NaN |
    When executing query:
      """
      RETURN set_max(SET{1.0M, NULL, 2M, NAN}) AS a
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    When executing query:
      """
      RETURN set_max(SET{-10.8, -10.7, -10.6}) AS a
      """
    Then the result should be, in any order:
      | a      |
      | -10.6M |

  Scenario: Set Min
    When executing query:
      """
      RETURN set_min(SET{1.0M, NULL, 2M, NAN}) AS a
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    When executing query:
      """
      RETURN set_min(SET{1.0M, 2M, NAN}) AS a
      """
    Then the result should be, in any order:
      | a    |
      | 1.0M |
    When executing query:
      """
      RETURN set_min(SET{null}) AS a
      """
    Then the result should be, in any order:
      | a    |
      | null |
    When executing query:
      """
      RETURN set_min(SET{-10.8, -10.7, -10.6}) AS a
      """
    Then the result should be, in any order:
      | a      |
      | -10.8M |

  Scenario: Set Intersection
    When executing query:
      """
      RETURN set_intersect(SET{1, 2, 3}, SET{4, 5, 6}) AS a
      """
    Then the result should be, in any order:
      | a     |
      | SET{} |
    When executing query:
      """
      RETURN set_intersect(SET{1, 2, 3}, null) AS a
      """
    Then the result should be, in any order:
      | a    |
      | null |
    When executing query:
      """
      let a = set_intersect(SET{1, 2, 3, null}, SET{1, 2, 3, 4})
      return size(a)
      """
    Then the result should be, in any order:
      | size(a) |
      | 3       |

  Scenario: Set Except
    When executing query:
      """
      RETURN set_except(SET{1, 2, 3}, SET{1, 2, 3, 4}) AS a
      """
    Then the result should be, in any order:
      | a     |
      | SET{} |
    When executing query:
      """
      return set_except(SET{1, 2, 3, null}, SET{4}) AS a
      """
    Then the result should be, in any order:
      | a               |
      | SET{null,3,2,1} |
    When executing query:
      """
      return set_except(SET{4}, SET{1, 2, 3, null}) AS a
      """
    Then the result should be, in any order:
      | a      |
      | SET{4} |

  Scenario: Set Filter
    # Filter out null element
    When executing query:
      """
      RETURN set_filter(SET{1, 2, 3, null}, x -> x IS NOT NULL) AS a
      """
    Then the result should be, in any order:
      | a          |
      | SET{1,2,3} |
    # Filter by numeric condition
    When executing query:
      """
      RETURN set_filter(SET{1, 2, 3, 4}, x -> x >= 2 AND x <> 3) AS a
      """
    Then the result should be, in any order:
      | a        |
      | SET{2,4} |
    # Empty set: predicate not applied
    When executing query:
      """
      RETURN set_filter(SET{}, x -> x IS NOT NULL) AS a
      """
    Then the result should be, in any order:
      | a     |
      | SET{} |
    # All pass: predicate always true
    When executing query:
      """
      RETURN set_filter(SET{1, 2}, x -> true) AS a
      """
    Then the result should be, in any order:
      | a        |
      | SET{1,2} |
    # Filter by string
    When executing query:
      """
      RETURN set_filter(SET{"yes", "no", "yes"}, x -> x = "yes") AS a
      """
    Then the result should be, in any order:
      | a          |
      | SET{"yes"} |
    # Filter const set with capture
    When executing query:
      """
      FOR i IN [0, 5, 2]
      RETURN set_filter(SET{1, 2, 3}, x -> x > i) AS a
      """
    Then the result should be, in any order:
      | a          |
      | SET{1,2,3} |
      | SET{}      |
      | SET{3}     |
    # Filter flat set with capture
    When executing query:
      """
      LET threshold = 2
      FOR s IN [SET{1, 2}, SET{1, 2, 3}]
      RETURN set_filter(s, x -> x >= threshold) AS a
      """
    Then the result should be, in any order:
      | a        |
      | SET{2}   |
      | SET{2,3} |
    # Filter flat set with NULL and empty set
    When executing query:
      """
      FOR s IN [SET{-1}, NULL, SET{}, SET{2}]
      RETURN set_filter(s, x -> x > 0) AS a
      """
    Then the result should be, in any order:
      | a      |
      | SET{}  |
      | NULL   |
      | SET{}  |
      | SET{2} |
    # Direct NULL input
    When executing query:
      """
      RETURN set_filter(NULL, x -> x > 1) AS a
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
    # NULL input with variable
    When executing query:
      """
      LET s = NULL
      RETURN set_filter(s, x -> x IS NOT NULL) AS a
      """
    Then the result should be, in any order:
      | a    |
      | NULL |
