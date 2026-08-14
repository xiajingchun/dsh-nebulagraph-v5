# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: String Function

  Scenario: SUBSTRING
    When executing query:
      """
      RETURN SUBSTRING("nebula graph", 8 , 5) AS a
      """
    Then the result should be, in any order:
      | a       |
      | "graph" |
    When executing query:
      """
      RETURN SUBSTRING("nebula graph", 8 , -1) AS a
      """
    Then an Error should be raised: "[22011]: Substring error, invalid length `-1`, must greater than or equal to 0, in expression: substring(\"nebula graph\", 8, -1)"
    When executing query:
      """
      RETURN SUBSTRING("nebula graph", 0, 100) AS a
      """
    Then the result should be, in any order:
      | a  |
      | "" |
    When executing query:
      """
      RETURN SUBSTRING("图📈数据库✅", 1, 2) AS a
      """
    Then the result should be, in any order:
      | a      |
      | "图📈" |

  Scenario: LEFT
    When executing query:
      """
      RETURN LEFT("nebula graph", 6) AS a
      """
    Then the result should be, in any order:
      | a        |
      | "nebula" |
    When executing query:
      """
      RETURN LEFT("nebula graph", -6) AS a
      """
    Then an Error should be raised: "[22011]: Substring error, invalid length `-6`, must greater than or equal to 0, in expression: left(\"nebula graph\", -6)"
    When executing query:
      """
      RETURN LEFT("nebula graph", 0) AS a
      """
    Then the result should be, in any order:
      | a  |
      | "" |
    When executing query:
      """
      RETURN LEFT("图📈数据库✅", 2) AS a
      """
    Then the result should be, in any order:
      | a      |
      | "图📈" |

  Scenario: RIGHT
    When executing query:
      """
      RETURN RIGHT("nebula graph", 5) AS a
      """
    Then the result should be, in any order:
      | a       |
      | "graph" |
    When executing query:
      """
      RETURN RIGHT("nebula graph", -100) AS a
      """
    Then an Error should be raised: "[22011]: Substring error, invalid length `-100`, must greater than or equal to 0, in expression: right(\"nebula graph\", -100)"
    When executing query:
      """
      RETURN RIGHT("nebula graph", 0) AS a
      """
    Then the result should be, in any order:
      | a  |
      | "" |
    When executing query:
      """
      RETURN RIGHT("图📈数据库✅", 4) AS a
      """
    Then the result should be, in any order:
      | a          |
      | "数据库✅" |

  Scenario: Concat
    When executing query:
      """
      RETURN "aaa" || "bbb" AS c
      """
    Then the result should be, in any order:
      | c        |
      | "aaabbb" |
    When executing query:
      """
      RETURN "图" || "数据库" AS c
      """
    Then the result should be, in any order:
      | c          |
      | "图数据库" |
    When executing query:
      """
      RETURN "📈图" || "数据库✅" AS c
      """
    Then the result should be, in any order:
      | c              |
      | "📈图数据库✅" |
    When executing query:
      """
      USE ldbc MATCH (n:Person WHERE n.id = 2) RETURN n.firstName || " " || n.lastName  AS fullName
      """
    Then the result should be, in any order:
      | fullName     |
      | "Tim Duncan" |

  Scenario: UPPER
    When executing query:
      """
      RETURN UPPER("nebula graph") AS a
      """
    Then the result should be, in any order:
      | a              |
      | "NEBULA GRAPH" |
    When executing query:
      """
      RETURN upper("nebula graph") AS a
      """
    Then the result should be, in any order:
      | a              |
      | "NEBULA GRAPH" |
    When executing query:
      """
      RETURN UPPER("nebula 图📈数据库✅ graph") AS a
      """
    Then the result should be, in any order:
      | a                           |
      | "NEBULA 图📈数据库✅ GRAPH" |

  Scenario: LOWER
    When executing query:
      """
      RETURN LOWER("Nebula Graph") AS a
      """
    Then the result should be, in any order:
      | a              |
      | "nebula graph" |
    When executing query:
      """
      RETURN LOWER("Nebula 图📈数据库✅ Graph") AS a
      """
    Then the result should be, in any order:
      | a                           |
      | "nebula 图📈数据库✅ graph" |

  Scenario: TRIM
    When executing query:
      """
      RETURN TRIM("   Nebula Graph   ") AS a
      """
    Then the result should be, in any order:
      | a              |
      | "Nebula Graph" |
    When executing query:
      """
      RETURN TRIM("  图 📈数据库✅    ") AS a
      """
    Then the result should be, in any order:
      | a               |
      | "图 📈数据库✅" |
    When executing query:
      """
      RETURN TRIM( '_' FROM "__图 📈数据库✅  __") AS a
      """
    Then the result should be, in any order:
      | a                 |
      | "图 📈数据库✅  " |
    When executing query:
      """
      RETURN TRIM( LEADING '_' FROM "__图 📈数据库✅  __") AS a
      """
    Then the result should be, in any order:
      | a                   |
      | "图 📈数据库✅  __" |
    When executing query:
      """
      RETURN TRIM( TRAILING '_' FROM "__图 📈数据库✅  __") AS a
      """
    Then the result should be, in any order:
      | a                   |
      | "__图 📈数据库✅  " |
    When executing query:
      """
      RETURN TRIM( BOTH '_' FROM "__图 📈数据库✅  __") AS a
      """
    Then the result should be, in any order:
      | a                 |
      | "图 📈数据库✅  " |

  Scenario: LTRIM
    When executing query:
      """
      RETURN LTRIM("   Nebula Graph   ") AS a
      """
    Then the result should be, in any order:
      | a                 |
      | "Nebula Graph   " |
    When executing query:
      """
      RETURN LTRIM("ABC Nebula Graph   ", "ABC") AS a
      """
    Then the result should be, in any order:
      | a                  |
      | " Nebula Graph   " |

  Scenario: RTRIM
    When executing query:
      """
      RETURN RTRIM("   Nebula Graph   ") AS a
      """
    Then the result should be, in any order:
      | a                 |
      | "   Nebula Graph" |
    When executing query:
      """
      RETURN RTRIM("ABC Nebula Graph  BCA", "AB") AS a
      """
    Then the result should be, in any order:
      | a                      |
      | "ABC Nebula Graph  BC" |

  Scenario: BTRIM
    When executing query:
      """
      RETURN BTRIM("   Nebula Graph   ") AS a
      """
    Then the result should be, in any order:
      | a              |
      | "Nebula Graph" |
    When executing query:
      """
      RETURN BTRIM("ABC Nebula Graph  BCA", "AB") AS a
      """
    Then the result should be, in any order:
      | a                    |
      | "C Nebula Graph  BC" |

  Scenario: LENGTH
    When executing query:
      """
      RETURN LENGTH("Nebula Graph") AS a
      """
    Then the result should be, in any order:
      | a  |
      | 12 |
    When executing query:
      """
      RETURN LENGTH("Nebula 图📈数据库✅ Graph") AS a
      """
    Then the result should be, in any order:
      | a  |
      | 19 |
    When executing query:
      """
      RETURN CHARACTER_LENGTH("Nebula Graph") AS a
      """
    Then the result should be, in any order:
      | a  |
      | 12 |
    When executing query:
      """
      RETURN CHARACTER_LENGTH("Nebula 图📈数据库✅ Graph") AS a
      """
    Then the result should be, in any order:
      | a  |
      | 19 |
    When executing query:
      """
      RETURN CHAR_LENGTH("Nebula Graph") AS a
      """
    Then the result should be, in any order:
      | a  |
      | 12 |
    When executing query:
      """
      RETURN CHAR_LENGTH("Nebula 图📈数据库✅ Graph") AS a
      """
    Then the result should be, in any order:
      | a  |
      | 19 |

  Scenario: CONTAINS
    When executing query:
      """
      RETURN CONTAINS("Nebula 图📈数据库✅ Graph", "📈数据库✅ G") AS v
      """
    Then the result should be, in any order:
      | v    |
      | true |

  Scenario: LIKE
    When executing query:
      """
      return LIKE("a", "a%%") as v
      """
    Then the result should be, in any order:
      | v    |
      | true |
    When executing query:
      """
      return "a" like "a%%" as v
      """
    Then the result should be, in any order:
      | v    |
      | true |
    When executing query:
      """
      return "a" like "%a%" as v
      """
    Then the result should be, in any order:
      | v    |
      | true |
    When executing query:
      """
      return "b" like "%a%" as v
      """
    Then the result should be, in any order:
      | v     |
      | false |
    When executing query:
      """
      return "b" like "%_%" as v
      """
    Then the result should be, in any order:
      | v    |
      | true |
    When executing query:
      """
      LET input = "hello, world", patterns = LIST[
        "%ello, _orl%",
        "hello, _orld%",
        "%hello, world%%"]
      FOR i in RANGE(1, LENGTH(patterns))
      RETURN input LIKE  patterns[i-1] AS v
      """
    Then the result should be, in any order:
      | v    |
      | true |
      | true |
      | true |
    When executing query:
      """
      LET input = "你好，世界", patterns = LIST[
        "%好，_界%",
        "你好，_界%",
        "%你好，世界%%"]
      FOR i in RANGE(1, LENGTH(patterns))
      RETURN input LIKE patterns[i-1] AS v
      """
    Then the result should be, in any order:
      | v    |
      | true |
      | true |
      | true |
    # test escape
    When executing query:
      """
      RETURN "\\" like "\\\\" as v
      """
    Then the result should be, in any order:
      | v    |
      | true |
    When executing query:
      """
      RETURN "%" like "\\%" as v
      """
    Then the result should be, in any order:
      | v    |
      | true |
    When executing query:
      """
      RETURN "_" like "\\_" as v
      """
    Then the result should be, in any order:
      | v    |
      | true |
    When executing query:
      """
      RETURN "_" like "\\a" as v
      """
    Then an Error should be raised: "[NR003]: Invalid function argument: \\a of `like`"
    When executing query:
      """
      LET input = 'hello, world', ids = RANGE(1, 2)
      FOR i in ids
      RETURN input LIKE "hello, _orl%" as v
      """
    Then the result should be, in any order:
      | v    |
      | true |
      | true |

  Scenario: REGEXP_LIKE
    When executing query:
      """
      return REGEXP_LIKE("hello", "he..o") as v
      """
    Then the result should be, in any order:
      | v    |
      | true |
    When executing query:
      """
      LET words = LIST["hello, world"]
      LET patterns = LIST["hel{2}o, .(or).*", ".*", "^hello.*", "hello"]
      FOR w IN words
      FOR p IN patterns
      RETURN REGEXP_LIKE(w, p) as v
      """
    Then the result should be, in any order:
      | v     |
      | true  |
      | true  |
      | true  |
      | false |
    When executing query:
      """
      LET words = LIST["hello, world", "hello, ", ", world"]
      FOR w IN words
      RETURN REGEXP_LIKE(w, ".*world") as v
      """
    Then the result should be, in any order:
      | v     |
      | true  |
      | false |
      | true  |
    # test regexp_like params
    When executing query:
      """
      LET words = LIST["hello, world", "hello, ", ", world"]
      FOR w IN words
      RETURN REGEXP_LIKE(w, ".*WORLD", "i") as v
      """
    Then the result should be, in any order:
      | v     |
      | true  |
      | false |
      | true  |
    When executing query:
      """
      RETURN REGEXP_LIKE("hello, world", "(abc") as v
      """
    Then an Error should be raised: "[NR003]: Invalid function argument: (abc of `regexp_like`"
    # test operator 'like' precedence
    When executing query:
      """
      RETURN true and "hello" like "hell%" as v
      """
    Then the result should be, in any order:
      | v    |
      | true |
    # FIX: https://github.com/vesoft-inc/nebula-ng/issues/6515
    When executing query:
      """
      return REGEXP_LIKE("hello nebula", "HE..*", "") as ret
      """
    Then the result should be, in any order:
      | ret   |
      | false |
    # FIX: https://github.com/vesoft-inc/nebula-ng/issues/8879
    When executing query:
      """
      RETURN REGEXP_LIKE("HEllo nebula", "he..*", "im") AS ret
      """
    Then the result should be, in any order:
      | ret  |
      | true |
    When executing query:
      """
      RETURN REGEXP_LIKE("你好，nebula","*") AS res
      """
    Then an Error should be raised: "[NR003]: Invalid function argument: * of `regexp_like`, in expression: regexp_like(\"你好，nebula\", \"*\")"

  Scenario: Binary str
    # byte str
    When executing query:
      """
      RETURN X' x' AS bs
      """
    Then an Error should be raised: "[42N33]: Invalid syntax, illegal byte string: x"

  Scenario: neo4j apoc.util.md5
    When executing query:
      """
      RETURN md5(["1","2","3"]) AS res
      """
    Then the result should be, in any order:
      | res                                |
      | "202cb962ac59075b964b07152d234b70" |
    When executing query:
      """
      RETURN md5(["12","3"]) AS res
      """
    Then the result should be, in any order:
      | res                                |
      | "202cb962ac59075b964b07152d234b70" |
    When executing query:
      """
      RETURN md5(["12","3"])=md5("123") AS res
      """
    Then the result should be, in any order:
      | res  |
      | true |
    When executing query:
      """
      RETURN md5(["1","Nebula 图📈数据库✅ Graph", "📈数据库✅ G","3"]) AS res
      """
    Then the result should be, in any order:
      | res                                |
      | "3718c9070faa89afcc1a74f538e050bc" |
    When executing query:
      """
      RETURN md5(["1","Nebula 图📈数据库✅ Graph", "📈数据库✅ G","3"])=md5("1Nebula 图📈数据库✅ Graph📈数据库✅ G3") AS res
      """
    Then the result should be, in any order:
      | res  |
      | true |
    When executing query:
      """
      RETURN md5()
      """
    Then an Error should be raised: "[NR002]: Undefined function: `md5()`"
    When executing query:
      """
      RETURN md5(true)
      """
    Then an Error should be raised: "[NR002]: Undefined function: `md5(BOOL)`"
    When executing query:
      """
      RETURN md5(vector(1,2,3,4.5))
      """
    Then an Error should be raised: "[NR002]: Undefined function: `md5(VECTOR)`"
    When executing query:
      """
      RETURN md5([null,8])
      """
    Then an Error should be raised: "[NI000]: Invalid parameter: MD5 function requires an argument of type string or list of strings"
    When executing query:
      """
      RETURN md5([true])
      """
    Then an Error should be raised: "[NI000]: Invalid parameter: MD5 function requires an argument of type string or list of strings"
    When executing query:
      """
      RETURN md5([null])
      """
    Then an Error should be raised: "[NI000]: Invalid parameter: MD5 function requires an argument of type string or list of strings"
    When executing query:
      """
      RETURN md5([[],null,[null]])
      """
    Then an Error should be raised: "[NI000]: Invalid parameter: MD5 function requires an argument of type string or list of strings"
    When executing query:
      """
      RETURN md5([[],null,[vector(1)]])
      """
    Then an Error should be raised: "[NI000]: Invalid parameter: MD5 function requires an argument of type string or list of strings"

  Scenario: string regex split
    When executing query:
      """
      RETURN split("a,b,c", ",") AS result
      """
    Then the result should be, in any order:
      | result              |
      | LIST["a", "b", "c"] |
    When executing query:
      """
      RETURN split("a,b,c,", ",") AS result
      """
    Then the result should be, in any order:
      | result                  |
      | LIST["a", "b", "c", ""] |
    When executing query:
      """
      RETURN split("a,b,c,,,", ",") AS result
      """
    Then the result should be, in any order:
      | result                          |
      | LIST["a", "b", "c", "", "", ""] |
    When executing query:
      """
      RETURN split("a,, ,,b,c,,", ",") AS result
      """
    Then the result should be, in any order:
      | result                                   |
      | LIST["a", "", " ", "", "b", "c", "", ""] |
    When executing query:
      """
      RETURN split("a,, ,,b,c,,", ",+") AS result
      """
    Then the result should be, in any order:
      | result                       |
      | LIST["a", " ", "b", "c", ""] |
    When executing query:
      """
      RETURN split("a,, ,,b,c,,", "") AS result
      """
    Then the result should be, in any order:
      | result                                                        |
      | LIST["","a", ",", ",", " ",",",",", "b", ",","c", ",",",",""] |
    When executing query:
      """
      RETURN split("a.txt,.txtb .txt,dfdc.txt, .txt ","[a-z]+\\.txt") AS result
      """
    Then the result should be, in any order:
      | result                            |
      | LIST["",",.txtb .txt,",", .txt "] |
    When executing query:
      """
      RETURN split("a.txt,.txtb .txt,dfdc.txt, .txt abc.txt","[a-z]+\\.txt") AS result
      """
    Then the result should be, in any order:
      | result                               |
      | LIST["",",.txtb .txt,",", .txt ",""] |
    When executing query:
      """
      RETURN split("","[a-z]+\\.txt") AS result
      """
    Then the result should be, in any order:
      | result   |
      | LIST[""] |
    # limit 0
    When executing query:
      """
      RETURN split("a,b,c", ",",0) AS result
      """
    Then the result should be, in any order:
      | result              |
      | LIST["a", "b", "c"] |
    When executing query:
      """
      RETURN split("a,b,c,", ",",-90) AS result
      """
    Then the result should be, in any order:
      | result                  |
      | LIST["a", "b", "c", ""] |
    When executing query:
      """
      RETURN split("a,b,c,,,", ",",0) AS result
      """
    Then the result should be, in any order:
      | result                          |
      | LIST["a", "b", "c", "", "", ""] |
    When executing query:
      """
      RETURN split("a,, ,,b,c,,", ",",0) AS result
      """
    Then the result should be, in any order:
      | result                                   |
      | LIST["a", "", " ", "", "b", "c", "", ""] |
    When executing query:
      """
      RETURN split("a,, ,,b,c,,", ",+",0) AS result
      """
    Then the result should be, in any order:
      | result                       |
      | LIST["a", " ", "b", "c", ""] |
    # limit 1
    When executing query:
      """
      RETURN split("a,b,c", ",",1) AS result
      """
    Then the result should be, in any order:
      | result        |
      | LIST["a,b,c"] |
    When executing query:
      """
      RETURN split("a,b,c,", ",",1) AS result
      """
    Then the result should be, in any order:
      | result         |
      | LIST["a,b,c,"] |
    When executing query:
      """
      RETURN split("a,b,c,,,", ",",1) AS result
      """
    Then the result should be, in any order:
      | result           |
      | LIST["a,b,c,,,"] |
    When executing query:
      """
      RETURN split("a,, ,,b,c,,", ",",1) AS result
      """
    Then the result should be, in any order:
      | result              |
      | LIST["a,, ,,b,c,,"] |
    When executing query:
      """
      RETURN split("a,, ,,b,c,,", ",+",1) AS result
      """
    Then the result should be, in any order:
      | result              |
      | LIST["a,, ,,b,c,,"] |
    # limit 2
    When executing query:
      """
      RETURN split("a,b,c", ",",2) AS result
      """
    Then the result should be, in any order:
      | result           |
      | LIST["a", "b,c"] |
    When executing query:
      """
      RETURN split("a,b,c,", ",",2) AS result
      """
    Then the result should be, in any order:
      | result            |
      | LIST["a", "b,c,"] |
    When executing query:
      """
      RETURN split("a,b,c,,,", ",",2) AS result
      """
    Then the result should be, in any order:
      | result              |
      | LIST["a", "b,c,,,"] |
    When executing query:
      """
      RETURN split("a,, ,,b,c,,", ",",2) AS result
      """
    Then the result should be, in any order:
      | result                 |
      | LIST["a", ", ,,b,c,,"] |
    When executing query:
      """
      RETURN split("a,, ,,b,c,,", ",+",2) AS result
      """
    Then the result should be, in any order:
      | result                |
      | LIST["a", " ,,b,c,,"] |
    # limit 3
    When executing query:
      """
      RETURN split("a,b,c", ",",3) AS result
      """
    Then the result should be, in any order:
      | result              |
      | LIST["a", "b", "c"] |
    When executing query:
      """
      RETURN split("a,b,c,", ",",3) AS result
      """
    Then the result should be, in any order:
      | result               |
      | LIST["a", "b", "c,"] |
    When executing query:
      """
      RETURN split("a,b,c,,,", ",",3) AS result
      """
    Then the result should be, in any order:
      | result                 |
      | LIST["a", "b", "c,,,"] |
    When executing query:
      """
      RETURN split("a,, ,,b,c,,", ",",3) AS result
      """
    Then the result should be, in any order:
      | result                    |
      | LIST["a", "", " ,,b,c,,"] |
    When executing query:
      """
      RETURN split("a,, ,,b,c,,", ",+",3) AS result
      """
    Then the result should be, in any order:
      | result                  |
      | LIST["a", " ", "b,c,,"] |
    When executing query:
      """
      RETURN split("1Nebula 图📈数据库✅ Graph📈数据a库✅ G3", "a库✅ ") AS result
      """
    Then the result should be, in any order:
      | result                                        |
      | LIST["1Nebula 图📈数据库✅ Graph📈数据","G3"] |
    When executing query:
      """
      RETURN split("1Nebula 图📈数据库✅ Graph📈数据a库✅ G3", "✅") AS result
      """
    Then the result should be, in any order:
      | result                                             |
      | LIST["1Nebula 图📈数据库"," Graph📈数据a库"," G3"] |
    When executing query:
      """
      RETURN split("1N图📈数据库✅", "") AS result
      """
    Then the result should be, in any order:
      | result                                            |
      | LIST["","1","N","图","📈","数","据","库","✅",""] |
    When executing query:
      """
      TABLE t {str, regex, lm} =
      {str: "a,b,c", regex: ",", lm: 0},
      {str: "a,b,c,", regex: ",", lm: 2},
      {str: "abc图📈数据库✅def", regex: "[ab,]", lm: 3},
      {str: "1N图📈数据库✅", regex: "", lm: 2},
      {str: "1Nebula 图📈数据库✅ Graph📈数据a库✅ G3", regex: "a库✅ ", lm: 2},
      {str: "1Nebula 图📈📈数据库✅ Graph📈数据a库 ", regex: "📈+", lm: 0},
      {str: "1Nebula 图📈数据库✅ Graph📈数据a库✅ G3", regex: "[a-z]+", lm: 0}
      FOR row in t
      RETURN split(row.str, row.regex, row.lm) AS result
      """
    Then the result should be, in any order:
      | result                                          |
      | LIST["a","b","c"]                               |
      | LIST["a","b,c,"]                                |
      | LIST["","","c图📈数据库✅def"]                  |
      | LIST["","1N图📈数据库✅"]                       |
      | LIST["1Nebula 图📈数据库✅ Graph📈数据","G3"]   |
      | LIST["1Nebula 图","数据库✅ Graph","数据a库 "]  |
      | LIST["1N"," 图📈数据库✅ G","📈数据","库✅ G3"] |

  Scenario: indexof substring
    When executing query:
      """
      RETURN index_of("a数据库✅bcadabad书ad", "ad") AS res
      """
    Then the result should be, in any order:
      | res |
      | 7   |
    When executing query:
      """
      RETURN index_of("a数据库✅bcadabad书ad", "ad", -1, 9) AS res
      """
    Then the result should be, in any order:
      | res |
      | 7   |
    When executing query:
      """
      RETURN index_of("a数据库✅bcadabad书ad", "ad", -1, 8) AS res
      """
    # -1 means not found
    Then the result should be, in any order:
      | res |
      | -1  |
    When executing query:
      """
      RETURN indexes_of("a数据库✅bcadabad书ad", "ad", -1, 8) AS res
      """
    Then the result should be, in any order:
      | res    |
      | LIST[] |
    When executing query:
      """
      RETURN index_of("a数据库✅bcadabad书ad", "ad", 7, 888) AS res
      """
    Then the result should be, in any order:
      | res |
      | 7   |
    When executing query:
      """
      RETURN index_of("a数据库✅bcadabad书ad", "ad", 8, -888) AS res
      """
    Then the result should be, in any order:
      | res |
      | 11  |
    When executing query:
      """
      RETURN index_of("a数据库✅bcadabad书ad", "ad", 12) AS res
      """
    Then the result should be, in any order:
      | res |
      | 14  |
    When executing query:
      """
      RETURN index_of("a数据库✅bcadabad书ad", "ad", 12,13) AS res
      """
    Then the result should be, in any order:
      | res |
      | -1  |
    When executing query:
      """
      RETURN index_of("a数据库✅bcadabad书ad", "ad", 14,14) AS res
      """
    Then the result should be, in any order:
      | res |
      | -1  |
    When executing query:
      """
      RETURN index_of("a数据库✅bcadabad书ad", "ad", 14,-1) AS res
      """
    Then the result should be, in any order:
      | res |
      | 14  |
    When executing query:
      """
      RETURN index_of("a数据库✅bcadabad书a📈", "a📈", 1,15) AS res
      """
    Then the result should be, in any order:
      | res |
      | -1  |
    When executing query:
      """
      RETURN index_of("a数据库✅bcadabad书a📈", "a📈", 1,16) AS res
      """
    Then the result should be, in any order:
      | res |
      | 14  |
    When executing query:
      """
      RETURN index_of("a数据库✅bcadabad书a📈b", "a📈b", 14,15) AS res
      """
    Then the result should be, in any order:
      | res |
      | -1  |
    When executing query:
      """
      RETURN index_of("1Nebula 图📈数据库✅ Graph📈数据库✅ G3", "数据库") AS res
      """
    Then the result should be, in any order:
      | res |
      | 10  |
    When executing query:
      """
      RETURN index_of("1Nebula 图📈数据库✅ Graph📈数据库✅ G3", "数据库",null) AS res
      """
    Then the result should be, in any order:
      | res  |
      | null |
    When executing query:
      """
      RETURN index_of("1Nebula 图📈数据库✅ Graph📈数据库✅ G3", null) AS res
      """
    Then the result should be, in any order:
      | res  |
      | null |
    When executing query:
      """
      RETURN index_of("1Nebula 图📈数据库✅ Graph📈数据库✅ G3", "数据库",3,null) AS res
      """
    Then the result should be, in any order:
      | res  |
      | null |
    When executing query:
      """
      RETURN index_of(null, "数据库",3,4) AS res
      """
    Then the result should be, in any order:
      | res  |
      | null |
    When executing query:
      """
      RETURN index_of("", "ad") AS res
      """
    Then the result should be, in any order:
      | res |
      | -1  |
    When executing query:
      """
      RETURN index_of("sfdsfaf", "af", 7,3) AS res
      """
    Then the result should be, in any order:
      | res |
      | -1  |
    When executing query:
      """
      RETURN index_of("sfdsfaf", "f", 7,-1) AS res
      """
    Then the result should be, in any order:
      | res |
      | -1  |
    When executing query:
      """
      RETURN index_of("sfdsfaf", "af", 6,-1) AS res
      """
    Then the result should be, in any order:
      | res |
      | -1  |
    When executing query:
      """
      RETURN index_of("sfdsfaf", "af", 5) AS res
      """
    Then the result should be, in any order:
      | res |
      | 5   |
    When executing query:
      """
      TABLE t {haystack, needle, pos1, pos2} =
      {haystack:"a数据库✅bcadabad书ad", needle:"ad", pos1:0, pos2:100},
      {haystack:"a数据库✅bcadabad书ad", needle:"ad", pos1:-1, pos2:100},
      {haystack:"a数据库✅bcadabad书ad", needle:"ad", pos1:7, pos2:888},
      {haystack:"a数据库✅bcadabad书ad", needle:"ad", pos1:8, pos2:-888},
      {haystack:"a数据库✅bcadabad书ad", needle:"ad", pos1:12, pos2:100},
      {haystack:"a数据库✅bcadabad书ad", needle:"ad", pos1:12, pos2:13},
      {haystack:"a数据库✅bcadabad书ad", needle:"ad", pos1:14, pos2:14},
      {haystack:"a数据库✅bcadabad书a📈b", needle:"a📈b", pos1:14, pos2:15},
      {haystack:"1Nebula 图📈数据库✅ Graph📈数据库✅ G3", needle:"数据库", pos1:0, pos2:100},
      {haystack:"1Nebula 图📈数据库✅ Graph📈数据库✅ G3", needle:"数据库", pos1:null, pos2:null},
      {haystack:"1Nebula 图📈数据库✅ Graph📈数据库✅ G3", needle:null, pos1:0, pos2:100},
      {haystack:"1Nebula 图📈数据库✅ Graph📈数据库✅ G3", needle:"数据库", pos1:3, pos2:null},
      {haystack:null, needle:"数据库", pos1:3, pos2:4},
      {haystack:"", needle:"ad", pos1:0, pos2:100},
      {haystack:"sfdsfaf", needle:"af", pos1:7, pos2:3},
      {haystack:"sfdsfaf", needle:"f", pos1:7, pos2:-1},
      {haystack:"sfdsfaf", needle:"af", pos1:6, pos2:-1},
      {haystack:"sfdsfaf", needle:"af", pos1:5, pos2:100}
      FOR row in t
      RETURN index_of(row.haystack, row.needle, row.pos1, row.pos2) AS res
      """
    Then the result should be, in any order:
      | res  |
      | 7    |
      | 7    |
      | 7    |
      | 11   |
      | 14   |
      | -1   |
      | -1   |
      | -1   |
      | 10   |
      | null |
      | null |
      | null |
      | null |
      | -1   |
      | -1   |
      | -1   |
      | -1   |
      | 5    |
    # indexes_of
    When executing query:
      """
      TABLE t {haystack, needle, pos1, pos2} =
      {haystack:"a数据库✅bcadabad书ad", needle:"ad", pos1:0, pos2:100},
      {haystack:"a数据库✅bcadabad书ad", needle:"ad", pos1:-1, pos2:100},
      {haystack:"a数据库✅bcadabad书ad", needle:"ad", pos1:7, pos2:888},
      {haystack:"a数据库✅bcadabad书ad", needle:"ad", pos1:8, pos2:-888},
      {haystack:"a数据库✅bcadabad书ad", needle:"ad", pos1:12, pos2:100},
      {haystack:"a数据库✅bcadabad书ad", needle:"ad", pos1:12, pos2:13},
      {haystack:"a数据库✅bcadabad书ad", needle:"ad", pos1:14, pos2:14},
      {haystack:"a数据库✅bcadabad书a📈b", needle:"a📈b", pos1:14, pos2:15},
      {haystack:"1Nebula 图📈数据库✅ Graph📈数据库✅ G3", needle:"数据库", pos1:0, pos2:100},
      {haystack:"1Nebula 图📈数据库✅ Graph📈数据库✅ G3", needle:"数据库", pos1:null, pos2:null},
      {haystack:"1Nebula 图📈数据库✅ Graph📈数据库✅ G3", needle:null, pos1:0, pos2:100},
      {haystack:"1Nebula 图📈数据库✅ Graph📈数据库✅ G3", needle:"数据库", pos1:3, pos2:null},
      {haystack:null, needle:"数据库", pos1:3, pos2:4},
      {haystack:"", needle:"ad", pos1:0, pos2:100},
      {haystack:"sfdsfaf", needle:"af", pos1:7, pos2:3},
      {haystack:"sfdsfaf", needle:"f", pos1:7, pos2:-1},
      {haystack:"sfdsfaf", needle:"af", pos1:6, pos2:-1},
      {haystack:"sfdsfaf", needle:"af", pos1:5, pos2:100}
      FOR row in t
      RETURN indexes_of(row.haystack, row.needle, row.pos1, row.pos2) AS res
      """
    Then the result should be, in any order:
      | res            |
      | LIST [7,11,14] |
      | LIST [7,11,14] |
      | LIST [7,11,14] |
      | LIST [11,14]   |
      | LIST [14]      |
      | LIST []        |
      | LIST []        |
      | LIST []        |
      | LIST [10,21]   |
      | null           |
      | null           |
      | null           |
      | null           |
      | LIST []        |
      | LIST []        |
      | LIST []        |
      | LIST []        |
      | LIST [5]       |

  Scenario: REPEAT
    When executing query:
      """
      RETURN repeat("图📈数据库✅", 4) AS a, repeat("nebula-graph ", 2) as b , repeat("nebula", -1) as c
      """
    Then the result should be, in any order:
      | a                                                  | b                            | c  |
      | "图📈数据库✅图📈数据库✅图📈数据库✅图📈数据库✅" | "nebula-graph nebula-graph " | "" |
    When executing query:
      """
      RETURN length(repeat("x",70000))
      """
    Then the result should be, in any order:
      | length(repeat("x",70000)) |
      | 70000                     |
    When executing query:
      """
      RETURN length(repeat("xxxxxxxxx",1000000000))
      """
    Then an Error should be raised: "[NR016]: String should be no more than 4294967295 bytes, but got 4294967296 bytes"
