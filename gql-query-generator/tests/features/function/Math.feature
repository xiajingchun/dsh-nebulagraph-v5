# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: Math Function

  Scenario: Math Function
    When executing query:
      """
      RETURN abs(-1.3) AS a
      """
    Then the result should be, in any order:
      | a    |
      | 1.3M |
    When executing query:
      """
      RETURN mod(7,3) AS a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      RETURN floor(1.3) AS a
      """
    Then the result should be, in any order:
      | a    |
      | 1.0M |
    When executing query:
      """
      RETURN floor(-1.3) AS a
      """
    Then the result should be, in any order:
      | a     |
      | -2.0M |
    When executing query:
      """
      RETURN ceil(1.3) AS a
      """
    Then the result should be, in any order:
      | a    |
      | 2.0M |
    When executing query:
      """
      RETURN ceiling(1.3) AS a
      """
    Then the result should be, in any order:
      | a    |
      | 2.0M |
    When executing query:
      """
      RETURN ceil(-1.3) AS a
      """
    Then the result should be, in any order:
      | a     |
      | -1.0M |
    When executing query:
      """
      RETURN log(3,3) AS a
      """
    Then the result should be, in any order:
      | a   |
      | 1.0 |
    When executing query:
      """
      RETURN log(3.3,1) AS a
      """
    Then the result should be, in any order:
      | a    |
      | 0.0M |
    When executing query:
      """
      RETURN log10(10) AS a
      """
    Then the result should be, in any order:
      | a   |
      | 1.0 |
    When executing query:
      """
      RETURN ln(-1) AS a
      """
    Then an Error should be raised: "[22020]: invalid argument for natural logarithm, in expression: ln(-1)"
    When executing query:
      """
      RETURN ln(0) AS a
      """
    Then an Error should be raised: "[22020]: invalid argument for natural logarithm, in expression: ln(0)"
    When executing query:
      """
      RETURN log10(0) AS a
      """
    Then an Error should be raised: "[22020]: invalid argument for common logarithm, in expression: log10(0)"
    When executing query:
      """
      RETURN log10(-1) AS a
      """
    Then an Error should be raised: "[22020]: invalid argument for common logarithm, in expression: log10(-1)"
    When executing query:
      """
      RETURN log(1, 2) AS a
      """
    Then an Error should be raised: "[22020]: invalid argument for general logarithm function, in expression: log(1, 2)"
    When executing query:
      """
      RETURN log(2, -1) AS a
      """
    Then an Error should be raised: "[22020]: invalid argument for general logarithm function, in expression: log(2, -1)"
    When executing query:
      """
      RETURN log(-1, 2) AS a
      """
    Then an Error should be raised: "[22020]: invalid argument for general logarithm function, in expression: log(-1, 2)"
    When executing query:
      """
      RETURN ln(exp(1)) AS a
      """
    Then the result should be, in any order:
      | a   |
      | 1.0 |
    When executing query:
      """
      RETURN power(3,4) AS a
      """
    Then the result should be, in any order:
      | a    |
      | 81.0 |
    When executing query:
      """
      RETURN sqrt(9) AS a
      """
    Then the result should be, in any order:
      | a   |
      | 3.0 |

  Scenario: Trigonometric Function
    When executing query:
      """
      RETURN sin(0) AS a
      """
    Then the result should be, in any order:
      | a   |
      | 0.0 |
    When executing query:
      """
      RETURN sin(radians(90)) AS a
      """
    Then the result should be, in any order:
      | a   |
      | 1.0 |
    When executing query:
      """
      RETURN cos(0) AS a
      """
    Then the result should be, in any order:
      | a   |
      | 1.0 |
    When executing query:
      """
      RETURN acos(1) AS a
      """
    Then the result should be, in any order:
      | a   |
      | 0.0 |
    When executing query:
      """
      RETURN cos(radians(180)) AS a
      """
    Then the result should be, in any order:
      | a    |
      | -1.0 |
    When executing query:
      """
      RETURN abs(acos(-1.0)-radians(180))<10e-8 AS a
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      RETURN abs(tan(0.25*radians(180))-1)<10e-8 AS a
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      RETURN abs(atan(1)-0.25*radians(180))<10e-8 AS a
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      RETURN abs(sinh(2)-(exp(2)-exp(-2))/2)<10e-8 AS a
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      RETURN abs(cosh(2)-(exp(2)+exp(-2))/2)<10e-7 AS a
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      RETURN abs(tanh(2)-(exp(2)-exp(-2))/(exp(2)+exp(-2)))<10e-7 AS a
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      RETURN haversin(2)*2+cos(2) AS a
      """
    Then the result should be, in any order:
      | a   |
      | 1.0 |
    When executing query:
      """
      RETURN pi() - acos(-1) AS a
      """
    Then the result should be, in any order:
      | a   |
      | 0.0 |
    When executing query:
      """
      RETURN sign(-0.0) AS a
      """
    Then the result should be, in any order:
      | a |
      | 0 |
    When executing query:
      """
      RETURN sign(-0.23) AS a
      """
    Then the result should be, in any order:
      | a  |
      | -1 |
    When executing query:
      """
      RETURN sign(23) AS a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      RETURN isnan(asin(radians(180))) AS a
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      RETURN rand()>=0 and rand()<1 AS a
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      RETURN ceil(9223372036854775807) as ret
      """
    Then the result should be, in any order:
      | ret                 |
      | 9223372036854775807 |
    When executing query:
      """
      RETURN floor(9223372036854775807) as ret
      """
    Then the result should be, in any order:
      | ret                 |
      | 9223372036854775807 |
    When executing query:
      """
      RETURN ceil(-0.0), floor(-0.0), round(-0.0)
      """
    Then the result should be, in any order:
      | ceil(-0.0) | floor(-0.0) | round(-0.0) |
      | 0.0M       | 0.0M        | 0.0M        |
    When executing query:
      """
      RETURN round(-0.0d), ceil(-0.0d), floor(-0.0d)
      """
    Then the result should be, in any order:
      | round(-0.0d) | ceil(-0.0d) | floor(-0.0d) |
      | 0.0          | 0.0         | 0.0          |
    When executing query:
      """
      RETURN round(1454.454),round(1454.454,1),round(1454.454,2),round(1454.454,-1),round(1454.454,-2)
      """
    Then the result should be, in any order:
      | round(1454.454) | round(1454.454,1) | round(1454.454,2) | round(1454.454,-1) | round(1454.454,-2) |
      | 1454.0M         | 1454.5M           | 1454.45M          | 1450.0M            | 1500.0M            |
    When executing query:
      """
      RETURN round(1454.454d),round(1454.454d,1),round(1454.454d,2),round(1454.454d,-1),round(1454.454d,-2)
      """
    Then the result should be, in any order:
      | round(1454.454d) | round(1454.454d,1) | round(1454.454d,2) | round(1454.454d,-1) | round(1454.454d,-2) |
      | 1454.0           | 1454.5             | 1454.45            | 1450.0              | 1500.0              |
    When executing query:
      """
      RETURN round(0.454),round(0.454,1),round(0.454,2),round(-0.454,-1),round(-0.454,-2)
      """
    Then the result should be, in any order:
      | round(0.454) | round(0.454,1) | round(0.454,2) | round(-0.454,-1) | round(-0.454,-2) |
      | 0.0M         | 0.5M           | 0.45M          | 0.0M             | 0.0M             |
    When executing query:
      """
      RETURN round(0.454d),round(0.454d,1),round(0.454d,2),round(-0.454d,-1),round(-0.454d,-2)
      """
    Then the result should be, in any order:
      | round(0.454d) | round(0.454d,1) | round(0.454d,2) | round(-0.454d,-1) | round(-0.454d,-2) |
      | 0.0           | 0.5             | 0.45            | 0.0               | 0.0               |
    When executing query:
      """
      RETURN round(1454),round(1454,1),round(1454,2),round(1454,-1),round(1454,-2),round(1454,-3),round(1454,-4),round(1454, 10000)
      """
    Then the result should be, in any order:
      | round(1454) | round(1454,1) | round(1454,2) | round(1454,-1) | round(1454,-2) | round(1454,-3) | round(1454,-4) | round(1454, 10000) |
      | 1454        | 1454          | 1454          | 1450           | 1500           | 1000           | 0              | 1454               |
    When executing query:
      """
      RETURN round(2147483647, -30)
      """
    Then the result should be, in any order:
      | round(2147483647, -30) |
      | 0                      |
    When executing query:
      """
      RETURN round(2147483647, -1)
      """
    Then an Error should be raised: "[22003]: Numeric value out of range: `2147483650`, type: `INT32`, in expression: round(2147483647, -1)"
    When executing query:
      """
      RETURN round(-2147483648, -1)
      """
    Then an Error should be raised: "[22003]: Numeric value out of range: `-2147483650`, type: `INT32`, in expression: round(-2147483648, -1)"
    When executing query:
      """
      RETURN round(1.0d, 400), round(1.0d,-400)
      """
    Then the result should be, in any order:
      | round(1.0d, 400) | round(1.0d,-400) |
      | 1.0              | 0.0              |
    When executing query:
      """
      FOR i IN range(1,10)
      RETURN rand()*10
      NEXT
      RETURN count(*) GROUP BY()
      """
    Then the result should be, in any order:
      | count(*) |
      | 10       |
    When executing query:
      """
      RETURN 1 > 2.3 AS comparable_numbers,
             false <> true AS comparable_booleans,
              "abc" < "abdef" AS comparable_strings,
              DATE "2023-10-01" <= DATE "2023-10-02" AS comparable_dates,
              DURATION "P1D" < DURATION "P2D" AS comparable_durations,
              TIMESTAMP "2023-10-01T00:00:00Z" >= TIMESTAMP "2023-10-02T00:00:00Z" AS comparable_timestamps,
              null < null AS comparable_nulls
      """
    Then the result should be, in any order:
      | comparable_numbers | comparable_booleans | comparable_strings | comparable_dates | comparable_durations | comparable_timestamps | comparable_nulls |
      | false              | true                | true               | true             | true                 | false                 | null             |
    When executing query:
      """
      RETURN 1>= current_timestamp
      """
    Then an Error should be raised: "[22G04]: Values not comparable: invalid operation `INT32>=ZONEDDATETIME` of `1 >= current_timestamp()`"
    When executing query:
      """
      RETURN 1= false
      """
    Then an Error should be raised: "[22G04]: Values not comparable: invalid operation `INT32=BOOL` of `1 = false`"
    When executing query:
      """
      RETURN 1<> current_date
      """
    Then an Error should be raised: "[22G04]: Values not comparable: invalid operation `INT32<>DATE` of `1 <> current_date()`"
    When executing query:
      """
      RETURN power(0,-1)
      """
    Then an Error should be raised: "[2201F]: Invalid argument for power function: zero base with a negative exponent, in expression: power(0, -1)"
    When executing query:
      """
      RETURN power(-1,0.1)
      """
    Then an Error should be raised: "[2201F]: Invalid argument for power function: -1, in expression: power(-1, 0.1)"

  Scenario: Rand geometric Function
    When executing query:
      """
      RETURN rand_geo(0) AS a
      """
    Then the result should be, in any order:
      | a          |
      | 2147483647 |
    When executing query:
      """
      VALUE a INT64 = rand_geometric(1) RETURN (a)
      """
    Then the result should be, in any order:
      | a |
      | 0 |
    When executing query:
      """
      RETURN rand_geometric(0.5) AS a
      """
    Then the execution should be successful
