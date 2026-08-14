# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: Vector Function

  Scenario: ctor
    When executing query:
      """
      RETURN VECTOR<3,float>([1, 2, 3]) AS vec
      """
    Then the result should be, in any order:
      | vec            |
      | VECTOR [1,2,3] |
    When executing query:
      """
      RETURN VECTOR<4, float>([1.1f, 2, 3, 4.4f]) AS vec
      """
    Then the result should be, in any order:
      | vec                     |
      | VECTOR [1.1, 2, 3, 4.4] |
    When executing query:
      """
      FOR i IN [VECTOR<3,float>([1,2,3.3]), VECTOR<3,float>([2,3,33.3]), null, VECTOR<3,float>([3,3,4.3])]
      RETURN i IS NULL AS isNull, i IS NOT NULL AS isNotNull
      """
    Then the result should be, in any order:
      | isNull | isNotNull |
      | false  | true      |
      | false  | true      |
      | true   | false     |
      | false  | true      |
    When executing query:
      """
      LET vl=[VECTOR<3,float>([1,2,3.3]), VECTOR<3,float>([2,3,33.3]), null, VECTOR<3,float>([3,3,4.3])]
      RETURN head(vl) AS v0, vl[1] AS v1, vl[2] IS NULL AS v2, back(vl) AS v3
      """
    Then the result should be, in any order:
      | v0               | v1                | v2   | v3               |
      | VECTOR [1,2,3.3] | VECTOR [2,3,33.3] | true | VECTOR [3,3,4.3] |

  Scenario: distance functions
    When executing query:
      """
      RETURN inner_product(VECTOR<3,float>([1,2,3]), VECTOR<3,float>([4,5,6])) AS distance
      """
    Then the result should be, in any order:
      | distance |
      | 32.0     |
    When executing query:
      """
      RETURN euclidean(VECTOR<2,float>([1,2]), VECTOR<2,float>([4,6])) AS distance
      """
    Then the result should be, in any order:
      | distance |
      | 5.0      |
    When executing query:
      """
      RETURN cosine(VECTOR<3,float>([1,2,3]), VECTOR<3,float>([4,5,6])) * (sqrt(1+4+9)*sqrt(16+25+36)) AS distance
      """
    Then the result should be, in any order:
      | distance           |
      | 31.999998034929281 |
    When executing query:
      """
      RETURN vector_distance(VECTOR<3,float>([1,2,3]), VECTOR<3,float>([4,5,6]) cosine) * (sqrt(1+4+9)*sqrt(16+25+36)) AS distance
      """
    Then the result should be, in any order:
      | distance           |
      | 31.999998034929281 |
    When executing query:
      """
      RETURN inner_product(VECTOR<2,float>([1,2]), null) AS distance
      """
    Then the result should be, in any order:
      | distance |
      | NULL     |
    When executing query:
      """
      RETURN euclidean(VECTOR<2,float>([1,2]), null) AS distance
      """
    Then the result should be, in any order:
      | distance |
      | NULL     |
    When executing query:
      """
      RETURN cosine(VECTOR<2,float>([1,2]), null) AS distance
      """
    Then the result should be, in any order:
      | distance |
      | NULL     |

  Scenario: knn search
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      RETURN v.vec AS vec
      """
    Then the result should be, in any order:
      | vec                       |
      | VECTOR [1.0, 2.0, 3.0]    |
      | VECTOR [4.0, 5.0, 6.0]    |
      | VECTOR [7.0, 8.0, 9.0]    |
      | VECTOR [10.0, 11.0, 12.0] |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      ORDER BY inner_product(v.vec, VECTOR<3,float>([1,2,3])) LIMIT 3
      RETURN v.id AS id, inner_product(v.vec, VECTOR<3,float>([1,2,3])) AS distance_IP
      """
    Then the result should be, in any order:
      | id | distance_IP |
      | 1  | 14.0        |
      | 2  | 32.0        |
      | 3  | 50.0        |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      ORDER BY cosine(v.vec, VECTOR<3,float>([1,2,3])) LIMIT 3
      RETURN v.id AS id, cosine(v.vec, VECTOR<3,float>([1,2,3])) AS distance_cosine
      """
    Then the result should be, in order:
      | id | distance_cosine |
      | 4  | 0.95125824f     |
      | 3  | 0.95941186f     |
      | 2  | 0.9746318f      |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      ORDER BY euclidean(v.vec, VECTOR<3,float>([1,2,3])) LIMIT 3
      RETURN v.id AS id, euclidean(v.vec, VECTOR<3,float>([1,2,3])) AS distance_euclidean
      """
    Then the result should be, in any order:
      | id | distance_euclidean |
      | 1  | 0.0f               |
      | 2  | 5.196152f          |
      | 3  | 10.392304f         |

  Scenario: errors
    When executing query:
      """
      RETURN VECTOR<3,float>([true, false, true]) AS vec
      """
    Then an Error should be raised: "[NR022]: Invalid data type input: true"
    When executing query:
      """
      RETURN VECTOR<3,float>([1, 2, 3, 4]) AS vec
      """
    Then an Error should be raised: "[42001]: The dimension of vector do not match near `[1, 2, 3, 4]`"
    When executing query:
      """
      RETURN VECTOR<3,bool>([true,false,true]) AS vec
      """
    Then an Error should be raised: "[42001]: The coordinate type of vector must be float32 near `bool`"
    When executing query:
      """
      RETURN VECTOR<1,float>([3.50282e+38]) AS vec
      """
    Then an Error should be raised: "[NR021]: Float out of range: 3.50282E38"

  Scenario: Vector Arithmetic With Vector
    When executing query:
      """
      LET x = VECTOR<3, FLOAT>([10.1, 20.2, 30.3]), y = VECTOR<3, FLOAT>([2.2, 3.3, 4.4]) RETURN x + y AS z
      """
    Then the result should be, in any order:
      | z                       |
      | VECTOR [12.3,23.5,34.7] |
    When executing query:
      """
      LET x = VECTOR<3, FLOAT>([10.1, 20.2, 30.3]), y = VECTOR<3, FLOAT>([2.0, 3.0, 4.0]) RETURN x - y AS z
      """
    Then the result should be, in any order:
      | z                      |
      | VECTOR [8.1,17.2,26.3] |

  Scenario: Vector Arithmetic With Scalar
    When executing query:
      """
      LET x = VECTOR<3, FLOAT>([1.1, 2.2, 3.3]) RETURN x + 1 AS x
      """
    Then the result should be, in any order:
      | x                    |
      | VECTOR [2.1,3.2,4.3] |
    When executing query:
      """
      LET x = VECTOR<3, FLOAT>([10.1, 2.2, 3.3]) RETURN x - 1 AS x
      """
    Then the result should be, in any order:
      | x                    |
      | VECTOR [9.1,1.2,2.3] |
    When executing query:
      """
      LET x = VECTOR<3, FLOAT>([1.1, 2.2, 3.3]) RETURN x * 2 AS x
      """
    Then the result should be, in any order:
      | x                    |
      | VECTOR [2.2,4.4,6.6] |
    When executing query:
      """
      LET x = VECTOR<3, FLOAT>([1.1, 2.2, 3.3]) RETURN x / 2 AS x
      """
    Then the result should be, in any order:
      | x                      |
      | VECTOR [0.55,1.1,1.65] |
    When executing query:
      """
      LET x = VECTOR<3, FLOAT>([1.1, 2.2, 3.3]) RETURN x + 1.1 AS x
      """
    Then the result should be, in any order:
      | x                    |
      | VECTOR [2.2,3.3,4.4] |
    When executing query:
      """
      LET x = VECTOR<3, FLOAT>([10.1, 20.2, 30.3]) RETURN x - 0.1 AS x
      """
    Then the result should be, in any order:
      | x                       |
      | VECTOR [10.0,20.1,30.2] |
    When executing query:
      """
      LET x = VECTOR<3, FLOAT>([1.1, 2.2, 3.3]) RETURN x * 2.2 AS x
      """
    Then the result should be, in any order:
      | x                       |
      | VECTOR [2.42,4.84,7.26] |
    When executing query:
      """
      LET x = VECTOR<3, FLOAT>([1.1, 2.2, 3.3]) RETURN x / 2.2 AS x
      """
    Then the result should be, in any order:
      | x                    |
      | VECTOR [0.5,1.0,1.5] |

  Scenario: Vector Arithmetic Unary
    When executing query:
      """
      LET x = VECTOR<3, FLOAT>([1.1, -2.2, 3.3]) RETURN abs(x) AS x
      """
    Then the result should be, in any order:
      | x                    |
      | VECTOR [1.1,2.2,3.3] |
    When executing query:
      """
      LET x = VECTOR<3, FLOAT>([1.1, -2.2, 3.3]) RETURN abs2(x) AS x
      """
    Then the result should be, in any order:
      | x                        |
      | VECTOR [1.21,4.84,10.89] |
    When executing query:
      """
      LET x = VECTOR<3, FLOAT>([1.21,4.84,10.89]) RETURN sqrt(x) AS x
      """
    Then the result should be, in any order:
      | x                    |
      | VECTOR [1.1,2.2,3.3] |
    When executing query:
      """
      LET x = VECTOR<3, FLOAT>([64.0, 256.0, 16.0]) RETURN ln(x) AS x
      """
    Then the result should be, in any order:
      | x                                           |
      | VECTOR [4.15888308, 5.54517744, 2.77258872] |
    When executing query:
      """
      LET x = VECTOR<3, FLOAT>([64.0, 256.0, 16.0]) RETURN log(10, x) AS x
      """
    Then the result should be, in any order:
      | x                                           |
      | VECTOR [1.80617997, 2.40823996, 1.20411982] |
    When executing query:
      """
      LET x = VECTOR<3, FLOAT>([64.0, 256.0, 16.0]) RETURN log10(x) AS x
      """
    Then the result should be, in any order:
      | x                                           |
      | VECTOR [1.80617997, 2.40823996, 1.20411982] |
    When executing query:
      """
      LET x = VECTOR<3, FLOAT>([1, 2, 3]) RETURN exp(x) AS x
      """
    Then the result should be, in any order:
      | x                                     |
      | VECTOR [2.7182817,7.389056,20.085537] |
    When executing query:
      """
      LET x = VECTOR<3, FLOAT>([1, 2, 3]) RETURN normalize(x) AS x
      """
    Then the result should be, in any order:
      | x                                       |
      | VECTOR [0.26726124,0.5345225,0.8017837] |

  Scenario: Vector Reduction Function
    When executing query:
      """
      LET x = VECTOR<3, FLOAT>([10.1, 20.2, 30.3]) RETURN accum(x) AS z
      """
    Then the result should be, in any order:
      | z     |
      | 60.6f |
    When executing query:
      """
      LET x = VECTOR<3, FLOAT>([1.1, 2.2, 3.3]) RETURN mean(x) AS z
      """
    Then the result should be, in any order:
      | z    |
      | 2.2f |
    When executing query:
      """
      LET x = VECTOR<3, FLOAT>([1.1, 2.2, 3.3]) RETURN prod(x) AS z
      """
    Then the result should be, in any order:
      | z      |
      | 7.986f |
    When executing query:
      """
      LET x = VECTOR<3, FLOAT>([1.1, 2.2, 3.3]) RETURN abs(norm(x) - 4.115823) < 0.0001 AS z
      """
    Then the result should be, in any order:
      | z    |
      | TRUE |
    When executing query:
      """
      LET x = VECTOR<3, FLOAT>([1.1, 2.2, 3.3]) RETURN abs(squared_norm(x) - 16.94) < 0.001 AS z
      """
    Then the result should be, in any order:
      | z    |
      | TRUE |
