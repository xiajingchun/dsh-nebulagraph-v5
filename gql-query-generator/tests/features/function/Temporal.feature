# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: Temporal Function

  Scenario: Datetime Literal
    When executing query:
      """
      SESSION SET timezone = "UTC"
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN DATETIME "2012-03-04T05:06:07.0890" as a
      """
    Then the result should be, in any order:
      | a                                     |
      | DATETIME "2012-03-04T05:06:07.089000" |
    When executing query:
      """
      RETURN TIMESTAMP "2012-03-04T05:06:07 -0200" as a
      """
    Then the result should be, in any order:
      | a                                           |
      | ZONED DATETIME "2012-03-04T07:06:07.000000" |
    When executing query:
      """
      SESSION SET zoned_datetime_format = "%m-%d-%YT%H:%M:%S%z"
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN DATETIME "03-04-2012T05:06:07.0890+0800" as a
      """
    Then the result should be, in any order:
      | a                                           |
      | ZONED DATETIME "2012-03-03T21:06:07.089000" |
    When executing query:
      """
      SESSION SET zoned_datetime_format = "%m-%d-%YT%H:%M%z"
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN DATETIME "03-04-2012T05:06+0800" as a
      """
    Then the result should be, in any order:
      | a                                           |
      | ZONED DATETIME "2012-03-03T21:06:00.000000" |
    When executing query:
      """
      RETURN DATETIME "03-04-2012T05:06:07+0800" as a
      """
    Then an Error should be raised: "[22009]: Parse DATETIME (either local or zoned): `03-04-2012T05:06:07+0800` fail"
    When executing query:
      """
      SESSION SET zoned_datetime_format = "%m-%d-%YT%H%z"
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN DATETIME "03-04-2012T05+0800" as a
      """
    Then the result should be, in any order:
      | a                                           |
      | ZONED DATETIME "2012-03-03T21:00:00.000000" |
    When executing query:
      """
      SESSION SET zoned_datetime_format = "%m-%d-%Y"
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN DATETIME "03-04-2012" as a
      """
    Then the result should be, in any order:
      | a                                           |
      | ZONED DATETIME "2012-03-04T00:00:00.000000" |
    When executing query:
      """
      SESSION SET local_time_format = "%H"
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN TIME "47" as a
      """
    Then the result should be, in any order:
      | a               |
      | TIME "23:00:00" |
    When executing query:
      """
      SESSION SET local_time_format = "%H:%M"
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN TIME "10:25" as a
      """
    Then the result should be, in any order:
      | a               |
      | TIME "10:25:00" |
    When executing query:
      """
      SESSION SET local_time_format = "%H:%S"
      """
    Then an Error should be raised: "[NV003]: Config data error: local_time_format missing the required: %M for minutes."
    When executing query:
      """
      SESSION SET local_time_format = "%M:%S"
      """
    Then an Error should be raised: "[NV003]: Config data error: local_time_format missing the required: %H or %I for hours."
    When executing query:
      """
      SESSION SET local_datetime_format = "%Y-%m-%dT%H:%S"
      """
    Then an Error should be raised: "[NV003]: Config data error: local_datetime_format missing the required: %M for minutes."
    When executing query:
      """
      SESSION SET local_datetime_format = "%Y-%m-%dT%M:%S"
      """
    Then an Error should be raised: "[NV003]: Config data error: local_datetime_format missing the required: %H or %I for hours."

  Scenario: LocalDatetime Function
    When executing query:
      """
      RETURN local_datetime("2012-03-04T05:06:07.0890") as a
      """
    Then the result should be, in any order:
      | a                                     |
      | DATETIME "2012-03-04T05:06:07.089000" |
    When executing query:
      """
      RETURN local_datetime("2012-03-04T05:06:07.0890", "%Y-%m-%dT%H:%M:%S") as a
      """
    Then the result should be, in any order:
      | a                                     |
      | DATETIME "2012-03-04T05:06:07.089000" |
    When executing query:
      """
      RETURN local_datetime("2012-03-04T05:06:07", "%Y-%m-%dT%H:%M:%S") as a
      """
    Then the result should be, in any order:
      | a                                     |
      | DATETIME "2012-03-04T05:06:07.000000" |
    When executing query:
      """
      RETURN local_datetime() as a,local_datetime() as b,local_datetime() as c,local_datetime() as d
      NEXT
      RETURN a = b and b = c and c = d as res
      """
    Then the result should be, in any order:
      | res  |
      | true |
    # https://github.com/vesoft-inc/nebula-ng/issues/10818
    # 1970-01-02T00:00:00 has epoch microseconds == exactly 24 hours,
    # triggering a bug in TimeUtils::toLocalTime() that sets hour=24.
    When executing query:
      """
      RETURN CAST(local_datetime("1970-01-02T00:00:00") AS STRING) AS a
      """
    Then the result should be, in any order:
      | a                            |
      | "1970-01-02T00:00:00.000000" |

  Scenario: ZonedDatetime Function
    When executing query:
      """
      SESSION SET timezone = "UTC"
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN zoned_datetime("2012-03-04T05:06:07.0890", "%Y-%m-%dT%H:%M:%S") as a
      """
    Then the result should be, in any order:
      | a                                           |
      | ZONED DATETIME "2012-03-04T05:06:07.089000" |
    When executing query:
      """
      RETURN zoned_datetime("2012-03-04T05:06:07Z", "%Y-%m-%dT%H:%M:%S%z") as a
      """
    Then the result should be, in any order:
      | a                                           |
      | ZONED DATETIME "2012-03-04T05:06:07.000000" |
    When executing query:
      """
      RETURN zoned_datetime("2012-03-04T05:06:07 -0200") as a
      """
    Then the result should be, in any order:
      | a                                           |
      | ZONED DATETIME "2012-03-04T07:06:07.000000" |
    When executing query:
      """
      RETURN zoned_datetime("2012-03-04T05:06:07 -02:00", "%Y-%m-%dT%H:%M:%S %Ez") as a
      """
    Then the result should be, in any order:
      | a                                           |
      | ZONED DATETIME "2012-03-04T07:06:07.000000" |
    When executing query:
      """
      RETURN zoned_datetime("2012-03-04T05:06:07 AT -0200", "%Y-%m-%dT%H:%M:%S AT %z") as a
      """
    Then the result should be, in any order:
      | a                                           |
      | ZONED DATETIME "2012-03-04T07:06:07.000000" |
    When executing query:
      """
      SESSION SET timezone = "Asia/Shanghai"
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN zoned_datetime("2012-03-04T05:06:07.0890", "%Y-%m-%dT%H:%M:%S") as a
      """
    Then the result should be, in any order:
      | a                                           |
      | ZONED DATETIME "2012-03-04T05:06:07.089000" |
    When executing query:
      """
      RETURN zoned_datetime("2012-03-04T05:06:07 -0200") as a
      """
    Then the result should be, in any order:
      | a                                           |
      | ZONED DATETIME "2012-03-04T15:06:07.000000" |
    When executing query:
      """
      RETURN zoned_datetime("2012-03-04T05:06:07 AT -02:00", "%Y-%m-%dT%H:%M:%S AT %Ez") as a
      """
    Then the result should be, in any order:
      | a                                           |
      | ZONED DATETIME "2012-03-04T15:06:07.000000" |
    When executing query:
      """
      RETURN zoned_datetime() as a,zoned_datetime() as b,zoned_datetime() as c,zoned_datetime() as d
      NEXT
      RETURN a = b and b = c and c = d as res
      """
    Then the result should be, in any order:
      | res  |
      | true |

  Scenario: LocalTime Function
    When executing query:
      """
      RETURN TIME "05:06:07.0890" as a
      """
    Then the result should be, in any order:
      | a                      |
      | TIME "05:06:07.089000" |
    When executing query:
      """
      RETURN local_time("05:06:07.0890") as a
      """
    Then the result should be, in any order:
      | a                      |
      | TIME "05:06:07.089000" |
    When executing query:
      """
      RETURN local_time("05:06:07.0890", "%H:%M:%S") as a
      """
    Then the result should be, in any order:
      | a                      |
      | TIME "05:06:07.089000" |
    When executing query:
      """
      RETURN local_time("2012-03-04T05:06:07 AT -0200", "%Y-%m-%dT%H:%M:%S AT %z") as a
      """
    Then the result should be, in any order:
      | a                      |
      | TIME "05:06:07.000000" |
    When executing query:
      """
      RETURN local_time() as a,local_time() as b,local_time() as c,local_time() as d
      NEXT
      RETURN a = b and b = c and c = d as res
      """
    Then the result should be, in any order:
      | res  |
      | true |

  Scenario: ZonedTime Function
    When executing query:
      """
      SESSION SET timezone = "UTC"
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN zoned_time("05:06:07.0890Z", "%H:%M:%S%z") as a
      """
    Then the result should be, in any order:
      | a                            |
      | ZONED TIME "05:06:07.089000" |
    When executing query:
      """
      RETURN zoned_time("05:06:07.0890 -0200") as a
      """
    Then the result should be, in any order:
      | a                            |
      | ZONED TIME "07:06:07.089000" |
    When executing query:
      """
      RETURN zoned_time("01:02:03.0400 +1000") as a
      """
    Then the result should be, in any order:
      | a                          |
      | ZONED TIME "15:02:03.0400" |
    When executing query:
      """
      RETURN zoned_time("20:02:03.0400 -1000") as a
      """
    Then the result should be, in any order:
      | a                          |
      | ZONED TIME "06:02:03.0400" |
    When executing query:
      """
      RETURN zoned_time("05:06:07.0890", "%H:%M:%S") as a
      """
    Then the result should be, in any order:
      | a                            |
      | ZONED TIME "05:06:07.089000" |
    When executing query:
      """
      RETURN ZONED_time("2012-03-04T05:06:07 AT -0200", "%Y-%m-%dT%H:%M:%S AT %z") as a
      """
    Then the result should be, in any order:
      | a                            |
      | ZONED TIME "07:06:07.000000" |
    When executing query:
      """
      RETURN ZONED_time("05:06:07 AT -1000", "%H:%M:%S AT %z") as a
      """
    Then the result should be, in any order:
      | a                            |
      | ZONED TIME "15:06:07.000000" |
    When executing query:
      """
      SESSION SET timezone = "Asia/Shanghai"
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN zoned_time("05:06:07.0890", "%H:%M:%S") as a
      """
    Then the result should be, in any order:
      | a                            |
      | ZONED TIME "05:06:07.089000" |
    When executing query:
      """
      RETURN zoned_time("01:02:03.0400 +1000") as a
      """
    Then the result should be, in any order:
      | a                          |
      | ZONED TIME "23:02:03.0400" |
    When executing query:
      """
      RETURN zoned_time("20:02:03.0400 -1000") as a
      """
    Then the result should be, in any order:
      | a                          |
      | ZONED TIME "14:02:03.0400" |
    When executing query:
      """
      RETURN ZONED_time("05:06:07 AT -1000", "%H:%M:%S AT %z") as a
      """
    Then the result should be, in any order:
      | a                            |
      | ZONED TIME "23:06:07.000000" |
    When executing query:
      """
      LET a="05:06:07 AT -1000", b={x:"05:06:07 AT -1000"}
      RETURN ZONED_time(a, "%H:%M:%S AT %z") as zt1, ZONED_time(b.x, "%H:%M:%S AT %z") as zt2
      """
    Then the result should be, in any order:
      | zt1                          | zt2                          |
      | ZONED TIME "23:06:07.000000" | ZONED TIME "23:06:07.000000" |
    When executing query:
      """
      RETURN zoned_time() as a,zoned_time() as b,zoned_time() as c,zoned_time() as d
      NEXT
      RETURN a = b and b = c and c = d as res
      """
    Then the result should be, in any order:
      | res  |
      | true |

  Scenario: Date Function
    When executing query:
      """
      RETURN Date "9999-2-28" as a
      """
    Then the result should be, in any order:
      | a                 |
      | DATE "9999-02-28" |
    When executing query:
      """
      RETURN date("9999-2-28") as a
      """
    Then the result should be, in any order:
      | a                 |
      | DATE "9999-02-28" |
    When executing query:
      """
      RETURN date("9999-2-28", "%Y-%m-%d") as a
      """
    Then the result should be, in any order:
      | a                 |
      | DATE "9999-02-28" |
    When executing query:
      """
      LET a="9999-2-28", b={x:"9999-2-28"}
      RETURN date(a, "%Y-%m-%d") as d1, date(b.x, "%Y-%m-%d") as d2, date(a) AS d3
      """
    Then the result should be, in any order:
      | d1                | d2                | d3                |
      | DATE "9999-02-28" | DATE "9999-02-28" | DATE "9999-02-28" |
    When executing query:
      """
      RETURN date("28 2 -9999", "%d %m %Y") as a
      """
    Then the result should be, in any order:
      | a                  |
      | DATE "-9999-02-28" |
    When executing query:
      """
      RETURN date("1-1-1", "%Y-%m-%d") as a
      """
    Then the result should be, in any order:
      | a                 |
      | DATE "0001-01-01" |
    When executing query:
      """
      RETURN date() as a,date() as b,date() as c,date() as d
      NEXT
      RETURN a = b and b = c and c = d as res
      """
    Then the result should be, in any order:
      | res  |
      | true |
    When executing query:
      """
      SESSION SET TIME ZONE "America/Denver"
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN current_timestamp.day = date().day AS a
      """
    Then the result should be, in any order:
      | a    |
      | true |

  Scenario: Duration literal
    When executing query:
      """
      RETURN duration "P-19999Y" as a
      """
    Then an Error should be raised: "[22009]: `years for duration` value -19999 out of limits: [`-19998`, `19998`]"
    When executing query:
      """
      RETURN duration "P19999Y" as a
      """
    Then an Error should be raised: "[22009]: `years for duration` value 19999 out of limits: [`-19998`, `19998`]"
    When executing query:
      """
      RETURN duration "P1Y3M" as a
      """
    Then the result should be, in any order:
      | a                |
      | DURATION "P1Y3M" |
    When executing query:
      """
      RETURN duration "P10Y-20M" as a
      """
    Then the result should be, in any order:
      | a                   |
      | DURATION "P10Y-20M" |
    When executing query:
      """
      RETURN duration "P10Y-20M" as a
      """
    Then the result should be, in any order:
      | a                               |
      | DURATION {years:10, months:-20} |
    When executing query:
      """
      RETURN duration({years:10, months:-20}) as a
      """
    Then the result should be, in any order:
      | a                   |
      | DURATION "P10Y-20M" |
    When executing query:
      """
      RETURN duration("P10Y-20M") as a
      """
    Then the result should be, in any order:
      | a                   |
      | DURATION "P10Y-20M" |
    When executing query:
      """
      RETURN duration "P-30DT40H50M-60.7080S" as a
      """
    Then the result should be, in any order:
      | a                                |
      | DURATION "P-30DT40H50M-60.7080S" |
    When executing query:
      """
      RETURN duration "P-30DT40H50M-60.7080S" as a
      """
    Then the result should be, in any order:
      | a                                                                            |
      | DURATION {days:-30, hours:40, minutes:50, seconds:-60, microseconds:-708000} |
    When executing query:
      """
      RETURN duration({days:-30, hours:40, minutes:50, seconds:-60, microseconds:-708000}) as a
      """
    Then the result should be, in any order:
      | a                                |
      | DURATION "P-30DT40H50M-60.7080S" |
    When executing query:
      """
      RETURN duration("P-30DT40H50M-60.7080S") as a
      """
    Then the result should be, in any order:
      | a                                |
      | DURATION "P-30DT40H50M-60.7080S" |
    When executing query:
      """
      RETURN duration "P0Y0M" as a
      """
    Then the result should be, in any order:
      | a                |
      | DURATION "P0Y0M" |
    When executing query:
      """
      RETURN duration "P0DT0H00M0.000000000S" as a
      """
    Then the result should be, in any order:
      | a                     |
      | DURATION "P0DT0H0M0S" |
    When executing query:
      """
      RETURN duration("P0Y0M") as a
      """
    Then the result should be, in any order:
      | a                |
      | DURATION "P0Y0M" |
    When executing query:
      """
      RETURN duration("P0DT0H00M0.000000000S") as a
      """
    Then the result should be, in any order:
      | a                     |
      | DURATION "P0DT0H0M0S" |
    When executing query:
      """
      RETURN duration "PT10.1S" as a
      """
    Then the result should be, in any order:
      | a                             |
      | DURATION "P0DT0H0M10.100000S" |
    When executing query:
      """
      RETURN duration "P1Y2M2D" as a
      """
    Then an Error should be raised: "[22009]: Duration must be either year-month based or day-time based"
    When executing query:
      """
      RETURN duration "P1YT2M" as a
      """
    Then an Error should be raised: "[22009]: Duration must be either year-month based or day-time based"
    When executing query:
      """
      RETURN duration "P" as a
      """
    Then an Error should be raised: "[22009]: Duration must be either year-month based or day-time based"
    When executing query:
      """
      RETURN duration "PT" as a
      """
    Then an Error should be raised: "[22009]: Duration must be either year-month based or day-time based"
    When executing query:
      """
      RETURN duration "P0Y0MT0S" as a
      """
    Then an Error should be raised: "[22009]: Duration must be either year-month based or day-time based"
    When executing query:
      """
      RETURN duration "" as a
      """
    Then an Error should be raised: "[22009]: Parse Duration `` fail, missing `P` at beginning"
    When executing query:
      """
      RETURN duration "Pabaaba" as a
      """
    Then an Error should be raised: "[22009]: Parse Duration `Pabaaba` fail, near `abaaba`"
    When executing query:
      """
      RETURN duration "P100D0T" as a
      """
    Then an Error should be raised: "[22009]: Parse Duration `P100D0T` fail, near `0T`"
    When executing query:
      """
      RETURN duration "PaabbD" as a
      """
    Then an Error should be raised: "[22009]: Parse Duration `PaabbD` fail, near `aabbD`"
    When executing query:
      """
      RETURN duration "P01010..1D" as a
      """
    Then an Error should be raised: "[22009]: Parse Duration `P01010..1D` fail, near `01010..1D`"
    When executing query:
      """
      RETURN duration "P1D2D" as a
      """
    Then an Error should be raised: "[22009]: Parse Duration `P1D2D` fail, near `2D`"
    When executing query:
      """
      RETURN duration "P1D2DT" as a
      """
    Then an Error should be raised: "[22009]: Parse Duration `P1D2DT` fail, near `2DT`"
    When executing query:
      """
      RETURN duration "PT1H2M2M3S" as a
      """
    Then an Error should be raised: "[22009]: Parse Duration `PT1H2M2M3S` fail, near `M3S`"
    When executing query:
      """
      RETURN duration "PT1.12300000Saabb" as a
      """
    Then an Error should be raised: "[22009]: Parse Duration `PT1.12300000Saabb` fail, near `aabb`"
    When executing query:
      """
      RETURN duration "P-30.10DT40H-50M-60.7080S" as a
      """
    Then an Error should be raised: "[22009]: Parse Duration `P-30.10DT40H-50M-60.7080S` fail, near `-30.10D`"
    When executing query:
      """
      RETURN duration("P1YT2M") as a
      """
    Then an Error should be raised: "[22G0H]: Invalid duration format: Duration must be either year-month based or day-time based, in expression: duration(\"P1YT2M\")"
    When executing query:
      """
      RETURN duration("") as a
      """
    Then an Error should be raised: "[22G0H]: Invalid duration format: Parse Duration `` fail, missing `P` at beginning, in expression: duration(\"\")"
    When executing query:
      """
      RETURN duration("PaabbD") as a
      """
    Then an Error should be raised: "[22G0H]: Invalid duration format: Parse Duration `PaabbD` fail, near `aabbD`, in expression: duration(\"PaabbD\")"
    When executing query:
      """
      RETURN duration("P1D2D") as a
      """
    Then an Error should be raised: "[22G0H]: Invalid duration format: Parse Duration `P1D2D` fail, near `2D`, in expression: duration(\"P1D2D\")"
    When executing query:
      """
      RETURN duration ("P-30.10DT40H-50M-60.7080S") as a
      """
    Then an Error should be raised: "[22G0H]: Invalid duration format: Parse Duration `P-30.10DT40H-50M-60.7080S` fail, near `-30.10D`, in expression: duration(\"P-30.10DT40H-50M-60.7080S\")"

  Scenario: Duration Record Constructor
    When executing query:
      """
      RETURN duration({years:1, months:2}) as a
      """
    Then the result should be, in any order:
      | a                            |
      | DURATION {years:1, months:2} |
    When executing query:
      """
      RETURN duration({days:1, hours:2, minutes:3, seconds:4, microseconds:5}) as a
      """
    Then the result should be, in any order:
      | a                                                                |
      | duration {days:1, hours:2, minutes:3, seconds:4, microseconds:5} |
    When executing query:
      """
      RETURN duration({years:1, months:2, days:1, hours:2, minutes:3, seconds:4, microseconds:5}) as a
      """
    Then an Error should be raised: "[22G0H]: Invalid duration format: Duration must be either year-month based or day-time based"
    When executing query:
      """
      RETURN duration(record {}) as a
      """
    Then an Error should be raised: "[22G0H]: Invalid duration format: Duration must be either year-month based or day-time based"
    When executing query:
      """
      RETURN duration({years:1.5, months:2.1})
      """
    Then an Error should be raised: "[22G0H]: Invalid duration format: Values in the input Record should be Integers"
    When executing query:
      """
      RETURN duration({years:"3b3b3", months:"7a7a7"})
      """
    Then an Error should be raised: "[22G0H]: Invalid duration format: Values in the input Record should be Integers"
    When executing query:
      """
      RETURN duration({years: {tmp: 1}, months: {tmp: 2}})
      """
    Then an Error should be raised: "[22G0H]: Invalid duration format: Values in the input Record should be Integers"
    When executing query:
      """
      RETURN duration({years:1, month:2}) as a
      """
    Then an Error should be raised: "[22G07]: Invalid duration field name: `month` is not a valid `time unit`, you must input plural time unit when using Record to construct duration"
    When executing query:
      """
      RETURN duration({abaaba:1, months:2}) as a
      """
    Then an Error should be raised: "[22G07]: Invalid duration field name: `abaaba` is not a valid `time unit`, you should use years, months, or days, etc. to construct duration"
    When executing query:
      """
      RETURN duration({years:1234567890})
      """
    Then an Error should be raised: "[22G15]: `years for duration` value 1234567890 out of limits: [`-19998`, `19998`], in expression: duration({years:1234567890})"
    When executing query:
      """
      RETURN duration({years:-19998}), duration({years:19998})
      """
    Then the result should be, in any order:
      | duration({years:-19998}) | duration({years:19998}) |
      | DURATION {years:-19998}  | DURATION {years:19998}  |
    When executing query:
      """
      RETURN duration({years:-19999})
      """
    Then an Error should be raised: "[22G15]: `years for duration` value -19999 out of limits: [`-19998`, `19998`], in expression: duration({years:-19999})"
    When executing query:
      """
      RETURN duration({years:19999})
      """
    Then an Error should be raised: "[22G15]: `years for duration` value 19999 out of limits: [`-19998`, `19998`], in expression: duration({years:19999})"

  Scenario: Duration Operator
    When executing query:
      """
      return duration({hours:2, days:1}) as a, duration({years:1, months:2}) as b
      """
    Then the result should be, in any order:
      | a                            | b                              |
      | DURATION {hours: 2, days: 1} | DURATION {years: 1, months: 2} |
    When executing query:
      """
      RETURN duration({years:1, months:2}) + duration({years:2, months:3}) as a
      """
    Then the result should be, in any order:
      | a                            |
      | DURATION {years:3, months:5} |
    When executing query:
      """
      RETURN duration("P1DT2H") + duration({hours:3, seconds:4}) as a
      """
    Then the result should be, in any order:
      | a                                     |
      | DURATION {days:1, hours:5, seconds:4} |
    When executing query:
      """
      RETURN duration({days:1, hours:2}) + duration("PT3H4S") as a
      """
    Then the result should be, in any order:
      | a                   |
      | DURATION "P1DT5H4S" |
    When executing query:
      """
      RETURN duration({years:1, months:2}) - duration({years:2, months:3}) as a
      """
    Then the result should be, in any order:
      | a                     |
      | DURATION {months:-13} |
    When executing query:
      """
      RETURN duration "P1DT2H" - duration({hours:3, seconds:4}) as a
      """
    Then the result should be, in any order:
      | a                                       |
      | DURATION {days:1, hours:-1, seconds:-4} |
    When executing query:
      """
      RETURN duration({days:1, hours:2}) - duration"P1DT2H" as a
      """
    Then the result should be, in any order:
      | a               |
      | DURATION "PT0S" |
    When executing query:
      """
      RETURN duration({days:1, hours:2}) - duration({days:1, hours:2}) as a
      """
    Then the result should be, in any order:
      | a               |
      | DURATION "PT0S" |
    When executing query:
      """
      RETURN duration("P1Y1M") - duration"P1Y1M" as a
      """
    Then the result should be, in any order:
      | a              |
      | DURATION "P0M" |
    When executing query:
      """
      RETURN duration({years:1, months:2}) + duration({hours:3, seconds:4}) as a
      """
    Then an Error should be raised: "[22G14]: Incompatible temporal duration unit groups: `DURATION \"P1Y2M\"` and `DURATION \"P0DT3H0M4.000000S\"` are not in the same duration unit group, but trying to do addition, in expression: DURATION \"P1Y2M\" + DURATION \"P0DT3H0M4.000000S\""
    When executing query:
      """
      RETURN duration({years:1, months:2}) + duration({years:1, months:2}) + duration({hours:3, seconds:4}) as a
      """
    Then an Error should be raised: "[22G14]: Incompatible temporal duration unit groups: `DURATION \"P2Y4M\"` and `DURATION \"P0DT3H0M4.000000S\"` are not in the same duration unit group, but trying to do addition, in expression: DURATION \"P2Y4M\" + DURATION \"P0DT3H0M4.000000S\""
    When executing query:
      """
      RETURN duration({years:1, months:2}) - duration({hours:3, seconds:4}) as a
      """
    Then an Error should be raised: "[22G14]: Incompatible temporal duration unit groups: `DURATION \"P1Y2M\"` and `DURATION \"P0DT3H0M4.000000S\"` are not in the same duration unit group, but trying to do subtraction, in expression: DURATION \"P1Y2M\" - DURATION \"P0DT3H0M4.000000S\""
    When executing query:
      """
      RETURN duration({years:1, months:2}) * 2 as a
      """
    Then the result should be, in any order:
      | a                            |
      | DURATION {years:2, months:4} |
    When executing query:
      """
      RETURN duration({days:1, hours:2}) * 2 as a
      """
    Then the result should be, in any order:
      | a                          |
      | DURATION {days:2, hours:4} |
    When executing query:
      """
      RETURN 2 * duration({years:1, months:2}) as a
      """
    Then the result should be, in any order:
      | a                            |
      | DURATION {years:2, months:4} |
    When executing query:
      """
      RETURN 2 * duration({years:1, months:2}) as a
      """
    Then the result should be, in any order:
      | a                |
      | DURATION "P2Y4M" |
    When executing query:
      """
      RETURN 2 * duration({days:1, hours:2}) as a
      """
    Then the result should be, in any order:
      | a                          |
      | DURATION {days:2, hours:4} |
    When executing query:
      """
      RETURN duration({years:1, months:2}) / 2 as a
      """
    Then the result should be, in any order:
      | a                   |
      | DURATION {months:7} |
    When executing query:
      """
      RETURN duration({days:1, hours:2}) / 2 as a
      """
    Then the result should be, in any order:
      | a                           |
      | DURATION {days:0, hours:13} |

  Scenario: Duration Between day-time based
    When executing query:
      """
      SESSION SET timezone = "UTC"
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN DURATION_BETWEEN(date("2024-5-30"), date("2024-4-30")) as a
      """
    Then the result should be, in any order:
      | a                   |
      | DURATION {days: 30} |
    When executing query:
      """
      RETURN DURATION_BETWEEN(date("2024-5-30"), date("2024-4-30")) DAY TO SECOND as a
      """
    Then the result should be, in any order:
      | a                  |
      | DURATION {days:30} |
    When executing query:
      """
      RETURN DURATION_BETWEEN(local_time("01:02:03.0400"), local_time("06:07:08.0900")) as a
      """
    Then the result should be, in any order:
      | a                                                                |
      | DURATION {hours:-5, minutes:-5, seconds:-5, microseconds:-50000} |
    When executing query:
      """
      RETURN DURATION_BETWEEN(zoned_time("22:03:03.0000 -1000"), zoned_time("08:03:03.0000 Z")) as a
      """
    Then the result should be, in any order:
      | a               |
      | DURATION "PT0S" |
    When executing query:
      """
      RETURN DURATION_BETWEEN(zoned_time("23:04:05.0000 +1000"), zoned_time("02:01:02.0000 -1000")) as a
      """
    Then the result should be, in any order:
      | a                   |
      | DURATION "PT1H3M3S" |
    When executing query:
      """
      RETURN DURATION_BETWEEN(zoned_time("08:04:05.0000 +1000"), zoned_time("22:01:02.0000 -1000")) as a
      """
    Then the result should be, in any order:
      | a                    |
      | DURATION "PT14H3M3S" |
    When executing query:
      """
      RETURN DURATION_BETWEEN(local_datetime("2024-05-31T06:07:08.0900"), local_datetime("2024-5-1T01:02:03.0400")) as a
      """
    Then the result should be, in any order:
      | a                                                                      |
      | DURATION {days: 30, hours:5, minutes:5, seconds:5, microseconds:50000} |
    When executing query:
      """
      RETURN DURATION_BETWEEN(local_datetime("2024-05-31T06:07:08.0900"), local_datetime("2024-5-1T01:02:03.0400")) as a
      """
    Then the result should be, in any order:
      | a                         |
      | DURATION "P30DT5H5M5.05S" |
    When executing query:
      """
      RETURN DURATION_BETWEEN(zoned_datetime("2024-05-31T06:07:08.0900 +1000"), zoned_datetime("2024-05-01T01:02:03.0400Z")) as a
      """
    Then the result should be, in any order:
      | a                          |
      | DURATION "P29DT19H5M5.05S" |
    When executing query:
      """
      RETURN DURATION_BETWEEN(zoned_datetime("2024-03-31T06:07:08.0900 -1000"), zoned_datetime("2024-02-29T01:02:03.0400Z")) as a
      """
    Then the result should be, in any order:
      | a                          |
      | DURATION "P31DT15H5M5.05S" |
    When executing query:
      """
      SESSION SET timezone = "Asia/Shanghai"
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN DURATION_BETWEEN(zoned_time("22:03:03.0000 -1000"), zoned_time("08:03:03.0000", "%H:%M:%S")) as a
      """
    Then the result should be, in any order:
      | a               |
      | DURATION "PT8H" |
    When executing query:
      """
      RETURN DURATION_BETWEEN(zoned_time("22:03:03.0000 -0100"), zoned_time("07:03:03.0000", "%H:%M:%S")) as a
      """
    Then the result should be, in any order:
      | a               |
      | DURATION "PT0S" |
    When executing query:
      """
      RETURN DURATION_BETWEEN(zoned_time("23:04:05.0000 +1000"), zoned_time("20:01:02.0000", "%H:%M:%S")) as a
      """
    Then the result should be, in any order:
      | a                   |
      | DURATION "PT1H3M3S" |
    When executing query:
      """
      RETURN DURATION_BETWEEN(zoned_time("08:01:01.0000", "%H:%M:%S"), zoned_time("22:01:01.0000 -1000")) as a
      """
    Then the result should be, in any order:
      | a                |
      | DURATION "PT-8H" |
    When executing query:
      """
      RETURN DURATION_BETWEEN(zoned_datetime("2024-05-31T06:07:08.0900 +1000"), zoned_datetime("2024-05-01T01:02:03.0400", "%Y-%m-%dT%H:%M:%S")) as a
      """
    Then the result should be, in any order:
      | a                         |
      | DURATION "P30DT3H5M5.05S" |

  Scenario: Duration Between year-month based
    When executing query:
      """
      SESSION SET timezone = "UTC"
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN DURATION_BETWEEN(date("2024-5-30"), date("2024-4-30")) YEAR TO MONTH as a
      """
    Then the result should be, in any order:
      | a                   |
      | DURATION {months:1} |
    When executing query:
      """
      LET date1 = date("2024-5-30")
      LET date2 = date("2024-4-30")
      RETURN DURATION_BETWEEN(date1, date2) YEAR TO MONTH as a
      """
    Then the result should be, in any order:
      | a                   |
      | DURATION {months:1} |
    When executing query:
      """
      RETURN DURATION_BETWEEN(local_time("01:02:03.0400"), local_time("06:07:08.0900")) YEAR TO MONTH as a
      """
    Then an Error should be raised: "[NQ002]: Invalid temporal instant subtraction: `TIME \"01:02:03.040000\"` and `TIME \"06:07:08.090000\"` are Time type. But the duration between Time can only be day-time based, in expression: duration_between(TIME \"01:02:03.040000\", TIME \"06:07:08.090000\", true)"
    When executing query:
      """
      RETURN DURATION_BETWEEN(zoned_time("01:02:03.0400 +0000"), zoned_time("06:07:08.0900Z")) YEAR TO MONTH as a
      """
    Then an Error should be raised: "[NQ002]: Invalid temporal instant subtraction: `TIME \"01:02:03.040000Z\"` and `TIME \"06:07:08.090000Z\"` are ZonedTime type. But the duration between ZonedTime can only be day-time based, in expression: duration_between(TIME \"01:02:03.040000Z\", TIME \"06:07:08.090000Z\", true)"
    When executing query:
      """
      RETURN DURATION_BETWEEN(local_datetime("2024-05-31T06:07:08.0900"), local_datetime("2023-03-01T01:02:03.0400")) YEAR TO MONTH as a
      """
    Then the result should be, in any order:
      | a                            |
      | DURATION {years:1, months:2} |
    When executing query:
      """
      RETURN DURATION_BETWEEN(local_datetime("2024-05-31T06:07:08.0900"), local_datetime("2023-03-01T01:02:03.0400")) YEAR TO MONTH as a
      """
    Then the result should be, in any order:
      | a                |
      | DURATION "P1Y2M" |
    When executing query:
      """
      RETURN DURATION_BETWEEN(zoned_datetime("2024-03-01T10:00:00 +1200"), zoned_datetime("2023-01-01T12:00:00 Z")) YEAR TO MONTH as a
      """
    Then the result should be, in any order:
      | a                |
      | DURATION "P1Y1M" |

  Scenario: Add Sub Duration
    When executing query:
      """
      SESSION SET timezone = "UTC"
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN date("2024-5-30") + duration({years:1000, months:10}) as a
      """
    Then the result should be, in any order:
      | a                |
      | date "3025-3-30" |
    When executing query:
      """
      RETURN date("2024-5-30") + duration({days:32}) as a
      """
    Then the result should be, in any order:
      | a               |
      | date "2024-7-1" |
    When executing query:
      """
      RETURN + duration("P1000Y10M") + date("2024-5-30")  as a
      """
    Then the result should be, in any order:
      | a                |
      | date "3025-3-30" |
    When executing query:
      """
      RETURN + duration "P1000Y10M" + date("2024-5-30")  as a
      """
    Then the result should be, in any order:
      | a                |
      | date "3025-3-30" |
    When executing query:
      """
      RETURN duration({days:32}) + date("2024-5-30")  as a
      """
    Then the result should be, in any order:
      | a               |
      | date "2024-7-1" |
    When executing query:
      """
      RETURN date("2022-4-30") - duration({years:2, months:2}) as a
      """
    Then the result should be, in any order:
      | a                |
      | date "2020-2-29" |
    When executing query:
      """
      RETURN date("2021-2-28") - duration("P365D") as a
      """
    Then the result should be, in any order:
      | a                |
      | date "2020-2-29" |
    When executing query:
      """
      RETURN local_time("01:02:03.0400") + duration({hours:3, minutes:3, seconds:3, microseconds:30000}) as a
      """
    Then the result should be, in any order:
      | a                    |
      | time "04:05:06.0700" |
    When executing query:
      """
      RETURN local_time("01:02:03.0400") + duration"PT3H3M3.03S" as a
      """
    Then the result should be, in any order:
      | a                    |
      | time "04:05:06.0700" |
    When executing query:
      """
      RETURN local_time("01:05:05.0500") - duration({hours:3, minutes:3, seconds:3, microseconds:30000}) as a
      """
    Then the result should be, in any order:
      | a                    |
      | time "22:02:02.0200" |
    When executing query:
      """
      RETURN zoned_time("01:02:03.0400 +1000") + duration({hours:3, minutes:3, seconds:3, microseconds:30000}) as a
      """
    Then the result should be, in any order:
      | a                          |
      | zoned time "18:05:06.0700" |
    When executing query:
      """
      RETURN zoned_time("01:02:03.0400 -1000") + duration"PT3H3M3.03S" as a
      """
    Then the result should be, in any order:
      | a                          |
      | zoned time "14:05:06.0700" |
    When executing query:
      """
      RETURN zoned_time("01:05:05.0500 +0400") - duration({hours:3, minutes:3, seconds:3, microseconds:30000}) as a
      """
    Then the result should be, in any order:
      | a                          |
      | zoned time "18:02:02.0200" |
    When executing query:
      """
      RETURN zoned_time("01:05:05.0500 -0100") - duration("PT3H3M3.03S") as a
      """
    Then the result should be, in any order:
      | a                          |
      | zoned time "23:02:02.0200" |
    When executing query:
      """
      RETURN local_datetime("2024-5-31T01:02:03.0400") + duration({hours:3, minutes:3, seconds:3, microseconds:30000}) as a
      """
    Then the result should be, in any order:
      | a                                  |
      | datetime "2024-5-31T04:05:06.0700" |
    When executing query:
      """
      RETURN local_datetime("2024-5-31T01:05:05.0500") - duration({hours:3, minutes:3, seconds:3, microseconds:30000}) as a
      """
    Then the result should be, in any order:
      | a                                  |
      | datetime "2024-5-30T22:02:02.0200" |
    When executing query:
      """
      RETURN local_datetime("2022-4-30T01:02:03.0400") - duration({years:2, months:2}) as a
      """
    Then the result should be, in any order:
      | a                                  |
      | datetime "2020-2-29T01:02:03.0400" |
    When executing query:
      """
      RETURN local_datetime("2021-2-28T03:03:03.0000") - duration({days:365}) as a
      """
    Then the result should be, in any order:
      | a                                  |
      | datetime "2020-2-29T03:03:03.0000" |
    When executing query:
      """
      RETURN zoned_datetime("2024-5-31T01:02:03.0400 +1200") + duration("PT3H3M3.03S") as a
      """
    Then the result should be, in any order:
      | a                                        |
      | ZONED datetime "2024-5-30T16:05:06.0700" |
    When executing query:
      """
      RETURN zoned_datetime("2024-5-31T01:05:05.0500 -1000") - duration({hours:3, minutes:3, seconds:3, microseconds:30000}) as a
      """
    Then the result should be, in any order:
      | a                                        |
      | zoned datetime "2024-5-31T08:02:02.0200" |
    When executing query:
      """
      RETURN zoned_datetime("2022-4-30T22:01:01.0100 -0200") - duration({years:2, months:2}) as a
      """
    Then the result should be, in any order:
      | a                                       |
      | zoned datetime "2020-3-1T00:01:01.0100" |
    When executing query:
      """
      RETURN zoned_datetime("2022-5-1T01:01:01.0100 +0200") - duration "P2Y2M" as a
      """
    Then the result should be, in any order:
      | a                                        |
      | zoned datetime "2020-2-29T23:01:01.0100" |
    When executing query:
      """
      RETURN zoned_datetime("2021-2-28T03:03:03.0000 +1000") - duration "P365D" as a
      """
    Then the result should be, in any order:
      | a                                        |
      | zoned datetime "2020-2-28T17:03:03.0000" |
    When executing query:
      """
      SESSION SET timezone = "Asia/Shanghai"
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN zoned_time("01:02:03.0400 +1000") + duration({hours:3, minutes:3, seconds:3, microseconds:30000}) as a
      """
    Then the result should be, in any order:
      | a                          |
      | zoned time "02:05:06.0700" |
    When executing query:
      """
      RETURN zoned_time("01:02:03.0400", "%H:%M:%S") + duration({hours:3, minutes:3, seconds:3, microseconds:30000}) as a
      """
    Then the result should be, in any order:
      | a                          |
      | zoned time "04:05:06.0700" |
    When executing query:
      """
      RETURN zoned_time("01:02:03.0400 -1000") + duration"PT3H3M3.03S" as a
      """
    Then the result should be, in any order:
      | a                          |
      | zoned time "22:05:06.0700" |
    When executing query:
      """
      RETURN zoned_time("01:05:05.0500", "%H:%M:%S") - duration("PT3H3M3.03S") as a
      """
    Then the result should be, in any order:
      | a                          |
      | zoned time "22:02:02.0200" |

  Scenario: date property
    When executing query:
      """
      USE ldbc
      MATCH (v:Person WHERE v.id = 1)-[e:KNOWS]->(b)
      RETURN b.birthday as birthday, b.birthday as day
      """
    Then the result should be, in any order:
      | birthday          | day               |
      | DATE '1990-01-01' | DATE '1990-01-01' |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person WHERE v.id = 1)-[e:KNOWS]->(b)
      LET birthday = b.birthday
      // The DOT operator of DATE type not supported yet
      RETURN birthday, birthday as day
      """
    Then the result should be, in any order:
      | birthday          | day               |
      | DATE '1990-01-01' | DATE '1990-01-01' |

  Scenario: Get Datetime Field
    When executing query:
      """
      RETURN LOCAL_DATETIME('2022-10-01T10:30:14.000213', "%Y-%m-%dT%H:%M:%S").Year AS year
      """
    Then the result should be, in any order:
      | year |
      | 2022 |
    When executing query:
      """
      RETURN LOCAL_DATETIME('2022-10-01T10:30:14.000213', "%Y-%m-%dT%H:%M:%S").month AS month
      """
    Then the result should be, in any order:
      | month |
      | 10    |
    When executing query:
      """
      RETURN LOCAL_DATETIME('2022-10-01T10:30:14.000213', "%Y-%m-%dT%H:%M:%S").DAY AS day
      """
    Then the result should be, in any order:
      | day |
      | 1   |
    When executing query:
      """
      RETURN YEAR(LOCAL_DATETIME('2022-10-01T10:30:14.000213', "%Y-%m-%dT%H:%M:%S")) AS year
      """
    Then the result should be, in any order:
      | year |
      | 2022 |
    When executing query:
      """
      RETURN MONTH(LOCAL_DATETIME('2022-10-01T10:30:14.000213', "%Y-%m-%dT%H:%M:%S")) AS m
      """
    Then the result should be, in any order:
      | m  |
      | 10 |
    When executing query:
      """
      RETURN DAY(LOCAL_DATETIME('2022-10-01T10:30:14.000213', "%Y-%m-%dT%H:%M:%S")) AS day
      """
    Then the result should be, in any order:
      | day |
      | 1   |
    When executing query:
      """
      RETURN HOUR(LOCAL_DATETIME('2022-10-01T10:30:14.000213', "%Y-%m-%dT%H:%M:%S")) AS HOUR
      """
    Then the result should be, in any order:
      | HOUR |
      | 10   |
    When executing query:
      """
      RETURN MINUTE(LOCAL_DATETIME('2022-10-01T10:30:14.000213', "%Y-%m-%dT%H:%M:%S")) AS Minute
      """
    Then the result should be, in any order:
      | Minute |
      | 30     |
    When executing query:
      """
      RETURN SECOND(LOCAL_DATETIME('2022-10-01T10:30:14.000213', "%Y-%m-%dT%H:%M:%S")) AS second
      """
    Then the result should be, in any order:
      | second |
      | 14     |

  Scenario: Get Date Field
    When executing query:
      """
      RETURN date('2022-10-01').year AS year
      """
    Then the result should be, in any order:
      | year |
      | 2022 |
    When executing query:
      """
      RETURN (DATE '2022-10-01').Month AS month
      """
    Then the result should be, in any order:
      | month |
      | 10    |
    When executing query:
      """
      RETURN (DATE '2022-10-01').day AS day
      """
    Then the result should be, in any order:
      | day |
      | 1   |
    When executing query:
      """
      RETURN YEAR(DATE('2022-10-01', "%Y-%m-%d")) AS year
      """
    Then the result should be, in any order:
      | year |
      | 2022 |
    When executing query:
      """
      RETURN MONTH(DATE('2022-10-01', "%Y-%m-%d")) AS m
      """
    Then the result should be, in any order:
      | m  |
      | 10 |
    When executing query:
      """
      RETURN DAY(DATE('2022-10-01', "%Y-%m-%d")) AS day
      """
    Then the result should be, in any order:
      | day |
      | 1   |
    When executing query:
      """
      RETURN HOUR(DATE('2022-10-01', "%Y-%m-%d")) AS HOUR
      """
    # date will be casted to local datetime implicitly
    Then the result should be, in any order:
      | HOUR |
      | 0    |
    When executing query:
      """
      RETURN MINUTE(DATE('2022-10-01', "%Y-%m-%d")) AS Minute
      """
    Then the result should be, in any order:
      | Minute |
      | 0      |
    When executing query:
      """
      RETURN SECOND(DATE('2022-10-01', "%Y-%m-%d")) AS second
      """
    Then the result should be, in any order:
      | second |
      | 0      |
    When executing query:
      """
      LET lhs = YEAR(DATE()),
      rhs = YEAR(TIME "05:06:07.0890")
      RETURN lhs = rhs as a
      """
    Then the result should be, in any order:
      | a    |
      | true |

  Scenario: Get Time Field
    When executing query:
      """
      SESSION SET timezone = "Asia/Shanghai"
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN ZONED_time("05:06:07 AT -1000", "%H:%M:%S AT %z").hour AS hour, hour(ZONED_time("05:06:07 AT -1000", "%H:%M:%S AT %z")) AS h
      """
    Then the result should be, in any order:
      | hour | h  |
      | 23   | 23 |
    When executing query:
      """
      RETURN ZONED_time("05:06:07 AT -1000", "%H:%M:%S AT %z").minute AS minute, minute(ZONED_time("05:06:07 AT -1000", "%H:%M:%S AT %z")) AS m
      """
    Then the result should be, in any order:
      | minute | m |
      | 6      | 6 |
    When executing query:
      """
      RETURN ZONED_time("05:06:07 AT -1000", "%H:%M:%S AT %z").second AS second, second(ZONED_time("05:06:07 AT -1000", "%H:%M:%S AT %z")) AS s
      """
    Then the result should be, in any order:
      | second | s |
      | 7      | 7 |
    When executing query:
      """
      RETURN TIME "05:06:07.0890".hour AS hour, hour(TIME "05:06:07.0890") AS h
      """
    Then the result should be, in any order:
      | hour | h |
      | 5    | 5 |
    When executing query:
      """
      RETURN TIME "05:06:07.0890".minute AS minute, minute(TIME "05:06:07.0890") AS m
      """
    Then the result should be, in any order:
      | minute | m |
      | 6      | 6 |
    When executing query:
      """
      RETURN TIME "05:06:07.0890".second AS second, second(TIME "05:06:07.0890") AS s
      """
    Then the result should be, in any order:
      | second | s |
      | 7      | 7 |
    When executing query:
      """
      RETURN local_time("05:06:07.0890").hour AS hour, hour(local_time("05:06:07.0890")) AS h
      """
    Then the result should be, in any order:
      | hour | h |
      | 5    | 5 |
    When executing query:
      """
      RETURN local_time("05:06:07.0890").minute AS minute, minute(local_time("05:06:07.0890")) AS m
      """
    Then the result should be, in any order:
      | minute | m |
      | 6      | 6 |
    When executing query:
      """
      RETURN local_time("05:06:07.0890").second AS second, second(local_time("05:06:07.0890")) AS s
      """
    Then the result should be, in any order:
      | second | s |
      | 7      | 7 |
    When executing query:
      """
      LET current_year = year(date()), y = year(local_time("05:06:07.0890"))
      RETURN current_year = y AS a
      """
    # local time will be casted to local datetime implicitly
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      LET current_month = month(date()), m = month(local_time("05:06:07.0890"))
      RETURN current_month = m AS a
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      LET current_day = day(date()), d = day(ZONED_time("05:06:07 AT -1000", "%H:%M:%S AT %z"))
      RETURN current_day = d AS a
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      LET t=local_time("05:06:07 AT -0200", "%H:%M:%S AT %z")
      RETURN t.hour AS d, t.minute AS e, t.second AS f
      """
    Then the result should be, in any order:
      | d | e | f |
      | 5 | 6 | 7 |
    When executing query:
      """
      LET t=date()
      RETURN t.hour AS d, t.minute AS e, t.second AS f
      """
    Then the result should be, in any order:
      | d | e | f |
      | 0 | 0 | 0 |
    When executing query:
      """
      LET t=zoned_time("23:23:23 +0300", "%H:%M:%S %z")
      RETURN t.minute AS e, t.second AS f
      """
    Then the result should be, in any order:
      | e  | f  |
      | 23 | 23 |

  Scenario: errors
    When executing query:
      """
      RETURN LOCAL_DATETIME('20230112', "%Y-%m-%d")
      """
    Then an Error should be raised: "[22009]: Parse LocalDatetime: `20230112` fail, in expression: local_datetime(\"20230112\", \"%Y-%m-%d\")"
    When executing query:
      """
      RETURN LOCAL_DATETIME('2023-01-53', "%Y-%m-%d")
      """
    Then an Error should be raised: "[22009]: Parse LocalDatetime: `2023-01-53` fail, in expression: local_datetime(\"2023-01-53\", \"%Y-%m-%d\")"
    When executing query:
      """
      RETURN LOCAL_DATETIME('2023-99-13', "%Y-%m-%d")
      """
    Then an Error should be raised: "[22009]: Parse LocalDatetime: `2023-99-13` fail, in expression: local_datetime(\"2023-99-13\", \"%Y-%m-%d\")"
    When executing query:
      """
      RETURN LOCAL_DATETIME('2022-11', "%Y-%m")
      """
    Then an Error should be raised: "[22009]: Parse LocalDatetime: `2022-11` fail, in expression: local_datetime(\"2022-11\", \"%Y-%m\")"
    When executing query:
      """
      RETURN LOCAL_DATETIME("hello", "%Y-%m-%d")
      """
    Then an Error should be raised: "[22009]: Parse LocalDatetime: `hello` fail, in expression: local_datetime(\"hello\", \"%Y-%m-%d\")"
    When executing query:
      """
      RETURN LOCAL_DATETIME('', "%Y-%m-%d %H:%M:%S")
      """
    Then an Error should be raised: "[22009]: Parse LocalDatetime: `` fail, in expression: local_datetime(\"\", \"%Y-%m-%d %H:%M:%S\")"
    When executing query:
      """
      RETURN ZONED_DATETIME('你好', "%Y-%m-%d")
      """
    Then an Error should be raised: "[22009]: Parse ZonedDatetime: `你好` fail, in expression: zoned_datetime(\"你好\", \"%Y-%m-%d\")"
    When executing query:
      """
      RETURN ZONED_DATETIME('', "%Y")
      """
    Then an Error should be raised: "[22009]: Parse ZonedDatetime: `` fail, in expression: zoned_datetime(\"\", \"%Y\")"

  Scenario: 21.2 65 type of time and datetime literal
    When executing query:
      """
      SESSION SET timezone = "UTC"
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN DATETIME "2021-05-11T10:25:00+0800"
      """
    Then the result should be, in any order:
      | DATETIME "2021-05-11T10:25:00+0800"         |
      | ZONED DATETIME "2021-05-11T02:25:00.000000" |
    When executing query:
      """
      RETURN DATETIME "2021-05-11T10:25:00"
      """
    Then the result should be, in any order:
      | DATETIME "2021-05-11T10:25:00"        |
      | DATETIME "2021-05-11T10:25:00.000000" |
    When executing query:
      """
      RETURN TIME "10:25:00"
      """
    Then the result should be, in any order:
      | TIME "10:25:00"        |
      | TIME "10:25:00.000000" |
    When executing query:
      """
      RETURN TIME "10:25:00+0800"
      """
    Then the result should be, in any order:
      | TIME "10:25:00+0800"         |
      | ZONED TIME "02:25:00.000000" |
    When executing query:
      """
      RETURN TIME "10:25:00-0800"
      """
    Then the result should be, in any order:
      | TIME "10:25:00-0800"         |
      | ZONED TIME "18:25:00.000000" |
    When executing query:
      """
      RETURN TIME "10:25:00Z"
      """
    Then the result should be, in any order:
      | TIME "10:25:00Z"             |
      | ZONED TIME "10:25:00.000000" |
    When executing query:
      """
      RETURN TIME "10:25:00Zxxx"
      """
    Then an Error should be raised: "[22009]: Parse TIME: `10:25:00Zxxx` fail"
    When executing query:
      """
      RETURN DATETIME "2024-12-01T10:25:00z"
      """
    Then an Error should be raised: "[22009]: Parse DATETIME (either local or zoned): `2024-12-01T10:25:00z` fail"
    When executing query:
      """
      RETURN TIME "xxx"
      """
    Then an Error should be raised: "[22009]: Parse TIME: `xxx` fail"
    When executing query:
      """
      RETURN DATETIME "xxx"
      """
    Then an Error should be raised: "[22009]: Parse DATETIME (either local or zoned): `xxx` fail"
    When executing query:
      """
      RETURN TIME "10:25:00xxx"
      """
    Then an Error should be raised: "[22009]: Parse TIME: `10:25:00xxx` fail"
    When executing query:
      """
      RETURN DATETIME "10:25:00xxx"
      """
    Then an Error should be raised: "[22009]: Parse DATETIME (either local or zoned): `10:25:00xxx` fail"
    When executing query:
      """
      RETURN DATETIME "2024-05-13T10:25:00xxx"
      """
    Then an Error should be raised: "[22009]: Parse DATETIME (either local or zoned): `2024-05-13T10:25:00xxx` fail"
    When executing query:
      """
      RETURN DATETIME "xxx2024-05-13T10:25:00"
      """
    Then an Error should be raised: "[22009]: Parse DATETIME (either local or zoned): `xxx2024-05-13T10:25:00` fail"
    When executing query:
      """
      RETURN DATETIME "2024-xxx05-13T10:25:00"
      """
    Then an Error should be raised: "[22009]: Parse DATETIME (either local or zoned): `2024-xxx05-13T10:25:00` fail"
    When executing query:
      """
      RETURN TIME "2024-xxx05-13T10:25:00"
      """
    Then an Error should be raised: "[22009]: Parse TIME: `2024-xxx05-13T10:25:00` fail"
    When executing query:
      """
      RETURN TIME "2024-05-13T10:25:00"
      """
    Then an Error should be raised: "[22009]: Parse TIME: `2024-05-13T10:25:00` fail"
    When executing query:
      """
      RETURN DATETIME "10:25:00"
      """
    Then an Error should be raised: "[22009]: Parse DATETIME (either local or zoned): `10:25:00` fail"

  Scenario: casting
    When executing query:
      """
      SESSION SET timezone = "Pacific/Fiji"
      """
    # Fiji's timezone is UTC+12
    Then the execution should be successful
    When executing query:
      """
      $a=DATETIME "2022-10-01T10:30:14.000213", $b=DATETIME "2022-10-01T10:30:14.000213+0800"
      RETURN CAST($a as ZONED DATETIME) AS localToZone, CAST($b as LOCAL DATETIME) as zoneToLocal
      """
    Then the result should be, in any order:
      | localToZone                                 | zoneToLocal                           |
      | ZONED DATETIME "2022-10-01T10:30:14.000213" | DATETIME "2022-10-01T14:30:14.000213" |
    When executing query:
      """
      $a=DATETIME "2022-10-01T10:30:14.000213", $b=DATETIME "2022-10-01T10:30:14.000213+0800"
      RETURN LIST [$a, $b] as l
      """
    Then the result should be, in any order:
      | l                                                                                              |
      | LIST[ZONED DATETIME "2022-10-01T10:30:14.000213", ZONED DATETIME "2022-10-01T14:30:14.000213"] |
    When executing query:
      """
      $a=DATETIME "2022-10-01T10:30:14.000213", $b=DATETIME "2022-10-01T10:30:14.000213+0800"
      RETURN $a = $b as equal, $a < $b as less
      """
    Then the result should be, in any order:
      | equal | less |
      | false | true |
    When executing query:
      """
      RETURN DATE() > DATETIME "2022-10-01T10:30:14.000213" as a
      """
    Then the result should be, in any order:
      | a    |
      | true |
    When executing query:
      """
      $a=TIME "10:30:14.000213", $b=TIME "10:30:14.000213+0800"
      RETURN CAST($a as ZONED TIME) as localToZone, CAST($b as LOCAL TIME) as zoneToLocal
      """
    Then the result should be, in any order:
      | localToZone                  | zoneToLocal            |
      | ZONED TIME "10:30:14.000213" | TIME "14:30:14.000213" |
    When executing query:
      """
      $varString="14:45:00.00",
      $varZonedTime=TIME "23:45:00.00-0300",
      $varLocalDatetime=DATETIME "2024-05-24T14:45:00.00",
      $varZonedDatetime=DATETIME "2024-05-23T23:45:00.00-0300"
      RETURN CAST($varString as LOCAL TIME) as fromString,
      CAST($varZonedTime as LOCAL TIME) as fromZonedTime,
      CAST($varLocalDatetime as LOCAL TIME) as fromLocalDatetime,
      CAST($varZonedDatetime as LOCAL TIME) as fromZonedDatetime
      """
    Then the result should be, in any order:
      | fromString             | fromZonedTime          | fromLocalDatetime      | fromZonedDatetime      |
      | TIME "14:45:00.000000" | TIME "14:45:00.000000" | TIME "14:45:00.000000" | TIME "14:45:00.000000" |
    When executing query:
      """
      $varString="14:45:00.00+1200",
      $varLocalTime=TIME "14:45:00.00",
      $varLocalDatetime=DATETIME "2024-05-24T14:45:00.00",
      $varZonedDatetime=DATETIME "2024-05-23T23:45:00.00-0300"
      RETURN CAST($varString as ZONED TIME) as fromString,
      CAST($varLocalTime as ZONED TIME) as fromLocalTime,
      CAST($varLocalDatetime as ZONED TIME) as fromLocalDatetime,
      CAST($varZonedDatetime as ZONED TIME) as fromZonedDatetime
      """
    Then the result should be, in any order:
      | fromString                   | fromLocalTime                | fromLocalDatetime            | fromZonedDatetime            |
      | ZONED TIME "14:45:00.000000" | ZONED TIME "14:45:00.000000" | ZONED TIME "14:45:00.000000" | ZONED TIME "14:45:00.000000" |
    When executing query:
      """
      $varString="2024-05-24T00:00:00.00",
      $varDate=DATE "2024-05-24",
      $varLocalTime=TIME "00:00:00.00",
      $varZonedTime=TIME "00:00:00.00+1200",
      $varZonedDatetime=DATETIME "2024-05-24T00:00:00.00+1200"
      RETURN CAST($varString as LOCAL DATETIME) as fromString,
      CAST($varDate as LOCAL DATETIME) as fromDate,
      CAST($varLocalTime as LOCAL DATETIME).hour as fromLocalTime,
      CAST($varZonedTime as LOCAL DATETIME).hour as fromZonedTime,
      CAST($varZonedDatetime as LOCAL DATETIME) as fromZonedDatetime
      """
    Then the result should be, in any order:
      | fromString                            | fromDate                              | fromLocalTime | fromZonedTime | fromZonedDatetime                     |
      | DATETIME "2024-05-24T00:00:00.000000" | DATETIME "2024-05-24T00:00:00.000000" | 0             | 0             | DATETIME "2024-05-24T00:00:00.000000" |
    When executing query:
      """
      $varString="2024-05-24T00:00:00.00+1200",
      $varDate=DATE "2024-05-24",
      $varLocalTime=TIME "00:00:00.00",
      $varZonedTime=TIME "00:00:00.00+1200",
      $varLocalDatetime=DATETIME "2024-05-24T00:00:00.00"
      RETURN CAST($varString as ZONED DATETIME) as fromString,
      CAST($varDate as ZONED DATETIME) as fromDate,
      CAST($varLocalTime as ZONED DATETIME).hour as fromLocalTime,
      CAST($varZonedTime as ZONED DATETIME).hour as fromZonedTime,
      CAST($varLocalDatetime as ZONED DATETIME) as fromLocalDatetime
      """
    Then the result should be, in any order:
      | fromString                                  | fromDate                                    | fromLocalTime | fromZonedTime | fromLocalDatetime                           |
      | ZONED DATETIME "2024-05-24T00:00:00.000000" | ZONED DATETIME "2024-05-24T00:00:00.000000" | 0             | 0             | ZONED DATETIME "2024-05-24T00:00:00.000000" |
    When executing query:
      """
      $varString="2024-05-24",
      $varLocalDatetime=DATETIME "2024-05-24T00:00:00.00",
      $varZonedDatetime=DATETIME "2024-05-24T00:00:00.00+1200"
      RETURN CAST($varString as DATE) as fromString,
      CAST($varLocalDatetime as DATE) as fromLocalDatetime,
      CAST($varZonedDatetime as DATE) as fromZonedDatetime
      """
    Then the result should be, in any order:
      | fromString        | fromLocalDatetime | fromZonedDatetime |
      | DATE "2024-05-24" | DATE "2024-05-24" | DATE "2024-05-23" |
    When executing query:
      """
      $varTime=TIME "10:00:40.213000",
      $varZonedTime=TIME "10:00:40.213000+1200",
      $varDatetime=DATETIME "2021-01-13T10:00:40.213000",
      $varZonedDatetime=DATETIME "2021-01-13T10:00:40.213000+1200"
      RETURN CAST($varTime as STRING) as fromTime,
      CAST($varZonedTime as STRING) as fromZonedTime,
      CAST($varDatetime as String) as fromDatetime,
      CAST($varZonedDatetime as STRING) as fromZonedDatetime
      """
    Then the result should be, in any order:
      | fromTime          | fromZonedTime           | fromDatetime                 | fromZonedDatetime                  |
      | "10:00:40.213000" | "10:00:40.213000 +1200" | "2021-01-13T10:00:40.213000" | "2021-01-13T10:00:40.213000 +1200" |
    When executing query:
      """
      $varZonedTime="xx:00:00.00+1200"
      RETURN CAST($varZonedTime as ZONED DATETIME) as a
      """
    Then an Error should be raised: "[22009]: Parse ZonedDatetime: `xx:00:00.00+1200` fail, in expression: CAST(\"xx:00:00.00+1200\" AS ZONEDDATETIME)"
    When executing query:
      """
      $varZonedTime="xx:00:00.00+1200"
      RETURN CAST($varZonedTime as DATE) as a
      """
    Then an Error should be raised: "[22009]: Parse Date: `xx:00:00.00+1200` fail, in expression: CAST(\"xx:00:00.00+1200\" AS DATE)"
    When executing query:
      """
      $varZonedTime="xx:00:00.00+1200"
      RETURN CAST($varZonedTime as LOCAL TIME) as a
      """
    Then an Error should be raised: "[22009]: Parse LocalTime: `xx:00:00.00+1200` fail, in expression: CAST(\"xx:00:00.00+1200\" AS LOCALTIME)"
    When executing query:
      """
      $varZonedTime="xx:00:00.00+1200"
      RETURN CAST($varZonedTime as LOCAL DATETIME) as a
      """
    Then an Error should be raised: "[22009]: Parse LocalDatetime: `xx:00:00.00+1200` fail, in expression: CAST(\"xx:00:00.00+1200\" AS LOCALDATETIME)"
    When executing query:
      """
      $varZonedTime="xx:00:00.00+1200"
      RETURN CAST($varZonedTime as ZONED TIME) as a
      """
    Then an Error should be raised: "[22009]: Parse ZonedTime: `xx:00:00.00+1200` fail, in expression: CAST(\"xx:00:00.00+1200\" AS ZONEDTIME)"
    When executing query:
      """
      RETURN CAST (["10:00:00.00+0800", "12:00:00.00+0800"] as LIST<ZONED TIME>) as TIME_IN_LIST,
      CAST (["2024-05-03T10:00:00.00+0800", "2024-05-03T12:00:00.00+0800"] as LIST<ZONED DATETIME>) as DATETIME_IN_LIST,
      CAST (["10:00:00.00", "12:00:00.00"] as LIST<LOCAL TIME>) as LOCAL_TIME_IN_LIST,
      CAST (["2024-05-03T10:00:00.00", "2024-05-03T12:00:00.00"] as LIST<LOCAL DATETIME>) as LOCAL_DATETIME_IN_LIST
      """
    Then the result should be, in any order:
      | TIME_IN_LIST                                                      | DATETIME_IN_LIST                                                                                | LOCAL_TIME_IN_LIST                                    | LOCAL_DATETIME_IN_LIST                                                              |
      | LIST [ZONED TIME "14:00:00.000000", ZONED TIME "16:00:00.000000"] | LIST [ZONED DATETIME "2024-05-03T14:00:00.000000", ZONED DATETIME "2024-05-03T16:00:00.000000"] | LIST [TIME "10:00:00.000000", TIME "12:00:00.000000"] | LIST [DATETIME "2024-05-03T10:00:00.000000", DATETIME "2024-05-03T12:00:00.000000"] |
    When executing query:
      """
      $varTime=TIME "10:00:40.213000",
      $varZonedTime=TIME "10:00:40.213000+1200",
      $varDatetime=DATETIME "2021-01-13T10:00:40.213000",
      $varZonedDatetime=DATETIME "2021-01-13T10:00:40.213000+1200",
      $varDate=DATE "2024-05-03"
      RETURN CAST({t0: $varTime, t1: $varZonedTime, t2: $varDatetime, t3: $varZonedDatetime, t4: $varDate}
      as RECORD {t0 ZONED TIME, t1 LOCAL TIME, t2 ZONED DATETIME, t3 LOCAL DATETIME, t4 LOCAL DATETIME}) as CASTING_IN_RECORD
      """
    Then the result should be, in any order:
      | CASTING_IN_RECORD                                                                                                                                                                                   |
      | RECORD {t2:ZONED DATETIME "2021-01-13T10:00:40.213000",t3:DATETIME "2021-01-13T10:00:40.213000",t4:DATETIME "2024-05-03T00:00:00.000000",t1:TIME "10:00:40.213000",t0:ZONED TIME "10:00:40.213000"} |

  Scenario: temporal function push down storage
    When executing query:
      """
      SESSION SET timezone = "UTC"
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS test_temporal_func_type AS {
      node test_date (labels test_datetime&test_date {id int primary key, _date date}),
      node test_zoned_time (labels test_datetime&test_zoned_time {id int primary key, _zoned_time zoned time})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS test_temporal_func TYPED test_temporal_func_type
      """
    Then the execution should be successful
    And graph "test_temporal_func" should be ready to use
    When executing query:
      """
      USE test_temporal_func
      INSERT OR REPLACE
      (@test_date{id:1, _date: null}),
      (@test_zoned_time{id:1, _zoned_time:local_time("11:22:33")}),
      (@test_zoned_time{id:2, _zoned_time: null})
      """
    Then the execution should be successful
    When executing query:
      """
      USE test_temporal_func
      MATCH (v:test_datetime)
      RETURN coalesce(v._date,v._zoned_time) AS coal
      NEXT
      USE test_temporal_func
      FILTER coal IS NOT NULL
      RETURN regexp_like(cast(coal as string), ".*T11:22:33.000000.*") as v
      """
    Then the result should be, in any order:
      | v    |
      | true |
    When executing query:
      """
      USE test_temporal_func
      MATCH (v:test_datetime)
      WHERE v._zoned_time <> current_time
      RETURN v.id
      """
    Then the result should be, in any order:
      | v.id |
      | 1    |
    And drop the graph "test_temporal_func"
    And drop the graph type "test_temporal_func_type"

  Scenario: default session time zone
    When executing query:
      """
      return cast(DATETIME "2024-06-12T11:50:00" as zoned datetime) as a
      """
    Then the result should be, in any order:
      | a                                           |
      | ZONED DATETIME "2024-06-12T11:50:00.000000" |
    When executing query:
      """
      session reset timezone
      """
    Then the execution should be successful
    When executing query:
      """
      return cast(DATETIME "2024-06-12T11:50:00" as zoned datetime) as a
      """
    Then the result should be, in any order:
      | a                                           |
      | ZONED DATETIME "2024-06-12T11:50:00.000000" |

  Scenario: compare
    When executing query:
      """
      return zoned_time("01:00:00+0800") > zoned_time("12:00:00+0700") as a,
        zoned_time("01:00:00+0800") = zoned_time("00:00:00+0700") as b,
        zoned_time("01:00:00+0800") = zoned_time("17:00:00+0000") as c,
        zoned_time("15:00:00-0200") = zoned_time("17:00:00+0000") as d,
        zoned_time("01:00:00+0800") = zoned_time("15:00:00-0200") as e,
        zoned_time("16:39:00+0800") > zoned_time("16:39:00+0000") as f,
        zoned_time("16:39:00+0800") < zoned_time("18:39:00+0700") as g,
        zoned_time("01:00:00+0800") < zoned_time("15:00:00-0200") as h,
        zoned_time("01:00:00+0800") > zoned_time("15:00:00-0200") as i
      """
    Then the result should be, in any order:
      | a    | b    | c    | d    | e    | f     | g    | h     | i     |
      | true | true | true | true | true | false | true | false | false |

  Scenario: convertion functions between epoch and datetime
    And create a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      SESSION SET timezone = "UTC"
      """
    Then the execution should be successful
    When executing query:
      """
      return from_epoch(1333670400000*1000) as dt
      """
    Then the result should be, in any order:
      | dt                                       |
      | ZONED DATETIME "2012-04-06T00:00:00.000" |
    When executing query:
      """
      return to_epoch(zoned_datetime("2012-04-06T08:00:00.000+08")) as epoch
      """
    Then the result should be, in any order:
      | epoch            |
      | 1333670400000000 |
    When executing query:
      """
      SESSION SET timezone = "Asia/Shanghai"
      """
    Then the execution should be successful
    When executing query:
      """
      LET zd = from_epoch(1333670400000*1000)
      return CAST(zd AS LOCAL DATETIME) as ld
      """
    Then the result should be, in any order:
      | ld                                 |
      | DATETIME "2012-04-06T08:00:00.000" |
    And close the current session
