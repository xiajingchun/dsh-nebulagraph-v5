# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: to_literal Function

  Scenario: to_literal with basic types
    When executing query:
      """
      RETURN to_literal(null) AS result
      """
    Then the result should be, in any order:
      | result |
      | "NULL" |
    When executing query:
      """
      RETURN to_literal(true) AS result
      """
    Then the result should be, in any order:
      | result |
      | "true" |
    When executing query:
      """
      RETURN to_literal(false) AS result
      """
    Then the result should be, in any order:
      | result  |
      | "false" |

  Scenario: to_literal with integer types
    When executing query:
      """
      RETURN to_literal(123) AS result
      """
    Then the result should be, in any order:
      | result |
      | "123"  |
    When executing query:
      """
      RETURN to_literal(-456) AS result
      """
    Then the result should be, in any order:
      | result |
      | "-456" |
    When executing query:
      """
      RETURN to_literal(0) AS result
      """
    Then the result should be, in any order:
      | result |
      | "0"    |

  Scenario: to_literal with floating point types
    When executing query:
      """
      RETURN to_literal(3.14d) AS result
      """
    Then the result should be, in any order:
      | result  |
      | "3.14d" |
    When executing query:
      """
      RETURN to_literal(-2.5d) AS result
      """
    Then the result should be, in any order:
      | result  |
      | "-2.5d" |
    When executing query:
      """
      RETURN to_literal(1.01f) AS result
      """
    Then the result should be, in any order:
      | result  |
      | "1.01f" |
    When executing query:
      """
      RETURN to_literal(1.0d/0.0) AS inf_0, to_literal(-1.0d/0.0) AS inf_1
      """
    Then the result should be, in any order:
      | inf_0                         | inf_1                          |
      | "CAST('Infinity' AS FLOAT64)" | "CAST('-Infinity' AS FLOAT64)" |
    When executing query:
      """
      RETURN to_literal(1.0f/0.0) AS inf_0, to_literal(-1.0f/0.0) AS inf_1
      """
    Then the result should be, in any order:
      | inf_0                         | inf_1                          |
      | "CAST('Infinity' AS FLOAT32)" | "CAST('-Infinity' AS FLOAT32)" |
    When executing query:
      """
      RETURN to_literal(0.0d/0.0) AS nan_0, to_literal(0.0f/0.0) AS nan_1
      """
    Then the result should be, in any order:
      | nan_0                    | nan_1                    |
      | "CAST('NaN' AS FLOAT64)" | "CAST('NaN' AS FLOAT32)" |

  Scenario: to_literal with string types
    When executing query:
      """
      RETURN to_literal('hello') AS result
      """
    Then the result should be, in any order:
      | result    |
      | "'hello'" |
    When executing query:
      """
      RETURN to_literal('') AS result
      """
    Then the result should be, in any order:
      | result |
      | "''"   |
    When executing query:
      """
      RETURN to_literal('test string') AS result
      """
    Then the result should be, in any order:
      | result          |
      | "'test string'" |

  # Error: cannot format ...: INTERNAL ERROR: The new content produced is not equivalent to the source.
  # Please report a bug on https://github.com/ducminh-phan/reformat-gherkin/issues.
  # Scenario: to_literal with string escape characters
  # When executing query:
  # """
  # RETURN to_literal('hello\'world') AS result
  # """
  # Then the result should be, in any order:
  # | result           |
  # | "'hello\\'world'" |
  # When executing query:
  # """
  # RETURN to_literal('hello\nworld') AS result
  # """
  # Then the result should be, in any order:
  # | result           |
  # | "'hello\\nworld'"|
  # When executing query:
  # """
  # RETURN to_literal('hello\\world') AS result
  # """
  # Then the result should be, in any order:
  # | result             |
  # | "'hello\\\\world'" |
  # When executing query:
  # """
  # RETURN to_literal('test\n\r\t\'\\') AS result
  # """
  # Then the result should be, in any order:
  # | result                   |
  # | "'test\\n\\r\\t\\'\\\\'" |
  Scenario: to_literal with collection types
    When executing query:
      """
      RETURN to_literal([1, 2, 3]) AS result
      """
    Then the result should be, in any order:
      | result        |
      | "LIST[1,2,3]" |
    When executing query:
      """
      RETURN to_literal([]) AS result
      """
    Then the result should be, in any order:
      | result   |
      | "LIST[]" |
    When executing query:
      """
      RETURN to_literal(['a', 'b', 'c']) AS result
      """
    Then the result should be, in any order:
      | result              |
      | "LIST['a','b','c']" |
    When executing query:
      """
      RETURN to_literal(SET{1}) AS result
      """
    Then the result should be, in any order:
      | result   |
      | "SET{1}" |
    When executing query:
      """
      RETURN to_literal(MAP{1: 'a'}) AS result
      """
    Then the result should be, in any order:
      | result       |
      | "MAP{1:'a'}" |

  Scenario: to_literal with vector types
    When executing query:
      """
      RETURN to_literal(VECTOR(1f, 2f, 3f)) AS result
      """
    Then the result should be, in any order:
      | result             |
      | "VECTOR(1f,2f,3f)" |
    When executing query:
      """
      RETURN to_literal(VECTOR(1.1f, 2.2f, 3.3f, 4.4f)) AS result
      """
    Then the result should be, in any order:
      | result                        |
      | "VECTOR(1.1f,2.2f,3.3f,4.4f)" |

  Scenario: to_literal with temporal types
    When executing query:
      """
      RETURN to_literal(local_time("12:30:45", "%H:%M:%S")) AS result
      """
    Then the result should be, in any order:
      | result                                          |
      | "local_time(\"12:30:45.000000\", \"%H:%M:%S\")" |
    When executing query:
      """
      RETURN to_literal(date("2025-01-08", "%Y-%m-%d")) AS result
      """
    Then the result should be, in any order:
      | result                               |
      | "date(\"2025-01-08\", \"%Y-%m-%d\")" |
    When executing query:
      """
      RETURN to_literal(local_datetime("2025-01-08T12:30:45", "%Y-%m-%dT%H:%M:%S")) AS result
      """
    Then the result should be, in any order:
      | result                                                                  |
      | "local_datetime(\"2025-01-08T12:30:45.000000\", \"%Y-%m-%dT%H:%M:%S\")" |
    When executing query:
      """
      RETURN to_literal(zoned_time("15:45:30 +0800", "%H:%M:%S %z")) AS result
      """
    Then the result should be, in any order:
      | result                                              |
      | "zoned_time(\"07:45:30.000000Z\", \"%H:%M:%S %z\")" |
    When executing query:
      """
      RETURN to_literal(zoned_datetime("2025-01-08T15:45:30 +0800", "%Y-%m-%dT%H:%M:%S %z")) AS result
      """
    Then the result should be, in any order:
      | result                                                                      |
      | "zoned_datetime(\"2025-01-08T07:45:30.000000Z\", \"%Y-%m-%dT%H:%M:%S %z\")" |

  Scenario: to_literal with nested structures
    When executing query:
      """
      RETURN to_literal([[1, 2], [3, 4]]) AS result
      """
    Then the result should be, in any order:
      | result                      |
      | "LIST[LIST[1,2],LIST[3,4]]" |
    When executing query:
      """
      RETURN to_literal(MAP{1: [1, 2, 3]}) AS result
      """
    Then the result should be, in any order:
      | result               |
      | "MAP{1:LIST[1,2,3]}" |
    When executing query:
      """
      RETURN to_literal([RECORD{a: 1}, RECORD{a: 2}]) AS result
      """
    Then the result should be, in any order:
      | result                          |
      | "LIST[RECORD{a:1},RECORD{a:2}]" |

  Scenario: to_literal with record types
    When executing query:
      """
      RETURN to_literal(RECORD{a: 1}) AS result
      """
    Then the result should be, in any order:
      | result        |
      | "RECORD{a:1}" |

  Scenario: to_literal with decimal types
    When executing query:
      """
      RETURN to_literal(123.456M) AS result
      """
    Then the result should be, in any order:
      | result     |
      | "123.456M" |
    When executing query:
      """
      RETURN
        to_literal(CAST('INF' AS DECIMAL)) AS inf,
        to_literal(CAST('-INF' AS DECIMAL)) AS neg_inf,
        to_literal(CAST('NAN' AS DECIMAL)) AS "nan"
      """
    Then the result should be, in any order:
      | inf                           | neg_inf                        | nan                      |
      | "CAST('Infinity' AS DECIMAL)" | "CAST('-Infinity' AS DECIMAL)" | "CAST('NaN' AS DECIMAL)" |

  Scenario: to_literal with containers containing NULL values
    When executing query:
      """
      RETURN to_literal([1, NULL, 3]) AS result
      """
    Then the result should be, in any order:
      | result           |
      | "LIST[1,NULL,3]" |
    When executing query:
      """
      RETURN to_literal(MAP{1: NULL}) AS result
      """
    Then the result should be, in any order:
      | result        |
      | "MAP{1:NULL}" |
    When executing query:
      """
      RETURN to_literal(RECORD{a: NULL}) AS result
      """
    Then the result should be, in any order:
      | result           |
      | "RECORD{a:NULL}" |
    When executing query:
      """
      RETURN to_literal([[1, NULL], NULL, [NULL, 2]]) AS result
      """
    Then the result should be, in any order:
      | result                                 |
      | "LIST[LIST[1,NULL],NULL,LIST[NULL,2]]" |

  Scenario: to_literal with geography types
    When executing query:
      """
      RETURN to_literal(ST_GeogFromText('POINT(1.0 2.0)')) AS result
      """
    Then the result should be, in any order:
      | result                            |
      | "ST_GeogFromText(\"POINT(1 2)\")" |
    When executing query:
      """
      RETURN to_literal(ST_GeogFromText('LINESTRING(0.0 0.0, 1.0 1.0, 2.0 2.0)')) AS result
      """
    Then the result should be, in any order:
      | result                                           |
      | "ST_GeogFromText(\"LINESTRING(0 0, 1 1, 2 2)\")" |
    When executing query:
      """
      RETURN to_literal(ST_GeogFromText('POLYGON((0.0 0.0, 1.0 0.0, 1.0 1.0, 0.0 1.0, 0.0 0.0))')) AS result
      """
    Then the result should be, in any order:
      | result                                                    |
      | "ST_GeogFromText(\"POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))\")" |

  Scenario: to_literal with binding table types
    When executing query:
      """
      TABLE t TYPED TABLE {a INT, b STRING} = (1, 'hello'), (2, 'world')
      RETURN to_literal(t) AS result
      """
    Then the result should be, in any order:
      | result                    |
      | "(1,'hello'),(2,'world')" |
    When executing query:
      """
      TABLE empty TYPED TABLE {x INT, y INT}
      RETURN to_literal(empty) AS result
      """
    Then the result should be, in any order:
      | result |
      | "NULL" |
    When executing query:
      """
      TABLE single_col TYPED TABLE {val INT} = (10), (20), (30)
      RETURN to_literal(single_col) AS result
      """
    Then the result should be, in any order:
      | result           |
      | "(10),(20),(30)" |
    When executing query:
      """
      TABLE single_row TYPED TABLE {a INT, b STRING, c BOOL} = (1, 'test', true)
      RETURN to_literal(single_row) AS result
      """
    Then the result should be, in any order:
      | result            |
      | "(1,'test',true)" |
    When executing query:
      """
      TABLE mixed TYPED TABLE {id INT, name STRING, val FLOAT64, active BOOL} =
        (1, 'first', 1.5d, true),
        (2, 'second', 2.5d, false)
      RETURN to_literal(mixed) AS result
      """
    Then the result should be, in any order:
      | result                                          |
      | "(1,'first',1.5d,true),(2,'second',2.5d,false)" |
    When executing query:
      """
      TABLE with_nulls TYPED TABLE {a INT, b STRING} = (1, 'hello'), (NULL, 'world'), (3, NULL)
      RETURN to_literal(with_nulls) AS result
      """
    Then the result should be, in any order:
      | result                                |
      | "(1,'hello'),(NULL,'world'),(3,NULL)" |
