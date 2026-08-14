# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: Quantified Path Pattern

  Scenario: Quantified Path Pattern
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS quantified_path_type AS {
        NODE Person (LABEL Person {id INT PRIMARY KEY, name STRING}),
        NODE Location (LABEL Location {id INT PRIMARY KEY, name STRING}),
        EDGE KNOWS (Person)-[:KNOWS]->(Person),
        EDGE VISITED (Person)-[:VISITED]->(Location),
        EDGE LOCATED_IN (Location)-[:LOCATED_IN]->(Location)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS quantified_path TYPED quantified_path_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE quantified_path
      INSERT
        (p1@Person{id: 1, name: 'Alice'}),
        (p2@Person{id: 2, name: 'Bob'}),
        (p3@Person{id: 3, name: 'Charlie'}),
        (p4@Person{id: 4, name: 'David'}),
        (p5@Person{id: 5, name: 'Eve'}),
        (p6@Person{id: 6, name: 'Frank'}),
        (l1@Location{id: 1, name: 'Park'}),
        (l2@Location{id: 2, name: 'Museum'}),
        (l3@Location{id: 3, name: 'Library'}),
        (l4@Location{id: 4, name: 'Cafe'}),
        (p1)-[@KNOWS]->(p2),   // Alice -> Bob
        (p2)-[@KNOWS]->(p3),   // Bob -> Charlie
        (p3)-[@KNOWS]->(p4),   // Charlie -> David
        (p4)-[@KNOWS]->(p5),   // David -> Eve
        (p5)-[@KNOWS]->(p6),   // Eve -> Frank
        (p1)-[@VISITED]->(l1), // Alice -> Park
        (p2)-[@VISITED]->(l2), // Bob -> Museum
        (p3)-[@VISITED]->(l3), // Charlie -> Library
        (p4)-[@VISITED]->(l4), // David -> Cafe
        (p5)-[@VISITED]->(l2), // Eve -> Museum
        (p3)-[@VISITED]->(l2), // Charlie -> Museum
        (p6)-[@VISITED]->(l3),  // Frank -> Library
        (l1)-[@LOCATED_IN]->(l2), // Park -> Museum
        (l2)-[@LOCATED_IN]->(l3), // Museum -> Library
        (l3)-[@LOCATED_IN]->(l4) // Library -> Cafe
      """
    Then the execution should be successful
    When executing query:
      """
      USE quantified_path
      MATCH (p1:Person)-[r:KNOWS]->{1,3}(p2:Person)
      RETURN p1.name AS p1_name, p2.name AS p2_name
      ORDER BY p1_name, p2_name
      """
    Then the result should be, in order:
      | p1_name   | p2_name   |
      | "Alice"   | "Bob"     |
      | "Alice"   | "Charlie" |
      | "Alice"   | "David"   |
      | "Bob"     | "Charlie" |
      | "Bob"     | "David"   |
      | "Bob"     | "Eve"     |
      | "Charlie" | "David"   |
      | "Charlie" | "Eve"     |
      | "Charlie" | "Frank"   |
      | "David"   | "Eve"     |
      | "David"   | "Frank"   |
      | "Eve"     | "Frank"   |
    When executing query:
      """
      USE quantified_path
      MATCH (l0:Location)-[r1:LOCATED_IN]->{1,3}(l3:Location)
      RETURN l0.name, l3.name
      """
    Then the result should be, in any order:
      | l0.name   | l3.name   |
      | "Park"    | "Museum"  |
      | "Park"    | "Library" |
      | "Park"    | "Cafe"    |
      | "Museum"  | "Library" |
      | "Museum"  | "Cafe"    |
      | "Library" | "Cafe"    |
    When executing query:
      """
      USE quantified_path
      MATCH (l0:Location) ( (l1:Location)-[r1:LOCATED_IN]->(l2:Location) ){1,3} (l3:Location)
      RETURN l0.name AS l0_name, l3.name AS l3_name, transform(l1, x -> x.name) AS l1_names, transform(l2, x -> x.name) AS l2_names
      """
    Then the result should be, in any order:
      | l0_name   | l3_name   | l1_names                         | l2_names                         |
      | "Park"    | "Museum"  | LIST ["Park"]                    | LIST ["Museum"]                  |
      | "Library" | "Cafe"    | LIST ["Library"]                 | LIST ["Cafe"]                    |
      | "Museum"  | "Cafe"    | LIST ["Museum","Library"]        | LIST ["Library","Cafe"]          |
      | "Park"    | "Cafe"    | LIST ["Park","Museum","Library"] | LIST ["Museum","Library","Cafe"] |
      | "Museum"  | "Library" | LIST ["Museum"]                  | LIST ["Library"]                 |
      | "Park"    | "Library" | LIST ["Park","Museum"]           | LIST ["Museum","Library"]        |
    # The filter `WHERE l2.name <> "Museum"` inside the quantified pattern indicates that every repeat of l2 cannot be "Museum"
    # The following two cases are equivalent
    When executing query:
      """
      USE quantified_path
      MATCH (l0:Location) ( (l1:Location)-[r1:LOCATED_IN]->(l2:Location) WHERE l2.name <> "Museum" ){1,3} (l3:Location)
      RETURN l0.name AS l0_name, l3.name AS l3_name, transform(l1, x -> x.name) AS l1_names, transform(l2, x -> x.name) AS l2_names
      """
    Then the result should be, in any order:
      | l0_name   | l3_name   | l1_names                  | l2_names                |
      | "Library" | "Cafe"    | LIST ["Library"]          | LIST ["Cafe"]           |
      | "Museum"  | "Cafe"    | LIST ["Museum","Library"] | LIST ["Library","Cafe"] |
      | "Museum"  | "Library" | LIST ["Museum"]           | LIST ["Library"]        |
    When executing query:
      """
      USE quantified_path
      MATCH (l0:Location) ( (l1:Location)-[r1:LOCATED_IN]->(l2:Location) ){1,3} (l3:Location)
      LET l2_names = transform(l2, x -> x.name)
      FILTER "Museum" NOT IN l2_names
      RETURN l0.name AS l0_name, l3.name AS l3_name, transform(l1, x -> x.name) AS l1_names, l2_names
      """
    Then the result should be, in any order:
      | l0_name   | l3_name   | l1_names                  | l2_names                |
      | "Library" | "Cafe"    | LIST ["Library"]          | LIST ["Cafe"]           |
      | "Museum"  | "Cafe"    | LIST ["Museum","Library"] | LIST ["Library","Cafe"] |
      | "Museum"  | "Library" | LIST ["Museum"]           | LIST ["Library"]        |
    When executing query:
      """
      USE quantified_path
      MATCH repeatable elements (l0:Location) ( (l1:Location)-[r1:LOCATED_IN]->(l2:Location)-[r2:LOCATED_IN]->(l3:Location) ){1,2} (l0:Location) WHERE r1 = r2
      RETURN l0.name AS l0_name, transform(l1, x -> x.name) AS l1_names
      """
    Then the result should be, in any order:
      | l0_name | l1_names |
    When executing query:
      """
      USE quantified_path
      MATCH p = (p0:Person{name: "Alice"})((p1:Person)-[r1:VISITED]->(l1:Location)-[r2:LOCATED_IN]->(l2:Location)<-[r3:VISITED]-(p2:Person)){1,2}(p3:Person)
      RETURN p0.name AS p0_name, p3.name AS p3_name,
             transform(p1, x -> x.name) AS p1_names,
             transform(l1, x -> x.name) AS l1_names,
             transform(l2, x -> x.name) AS l2_names,
             transform(p2, x -> x.name) AS p2_names
      ORDER BY p0_name, p3_name
      """
    Then the result should be, in any order:
      | p0_name | p3_name   | p1_names                 | l1_names                | l2_names                  | p2_names                   |
      | "Alice" | "Bob"     | LIST ["Alice"]           | LIST ["Park"]           | LIST ["Museum"]           | LIST ["Bob"]               |
      | "Alice" | "Charlie" | LIST ["Alice"]           | LIST ["Park"]           | LIST ["Museum"]           | LIST ["Charlie"]           |
      | "Alice" | "Charlie" | LIST ["Alice","Charlie"] | LIST ["Park","Museum"]  | LIST ["Museum","Library"] | LIST ["Charlie","Charlie"] |
      | "Alice" | "Charlie" | LIST ["Alice","Bob"]     | LIST ["Park","Museum"]  | LIST ["Museum","Library"] | LIST ["Bob","Charlie"]     |
      | "Alice" | "Charlie" | LIST ["Alice","Eve"]     | LIST ["Park","Museum"]  | LIST ["Museum","Library"] | LIST ["Eve","Charlie"]     |
      | "Alice" | "David"   | LIST ["Alice","Charlie"] | LIST ["Park","Library"] | LIST ["Museum","Cafe"]    | LIST ["Charlie","David"]   |
      | "Alice" | "Eve"     | LIST ["Alice"]           | LIST ["Park"]           | LIST ["Museum"]           | LIST ["Eve"]               |
      | "Alice" | "Frank"   | LIST ["Alice","Charlie"] | LIST ["Park","Museum"]  | LIST ["Museum","Library"] | LIST ["Charlie","Frank"]   |
      | "Alice" | "Frank"   | LIST ["Alice","Bob"]     | LIST ["Park","Museum"]  | LIST ["Museum","Library"] | LIST ["Bob","Frank"]       |
      | "Alice" | "Frank"   | LIST ["Alice","Eve"]     | LIST ["Park","Museum"]  | LIST ["Museum","Library"] | LIST ["Eve","Frank"]       |
    When executing query:
      """
      USE quantified_path MATCH TRAIL (n1@Person) ( (l1@Person)-[e@VISITED]->(l2@Location) ) *(n2@Location)
      RETURN n1.name AS name
      """
    Then the result should be, in any order:
      | name      |
      | "Bob"     |
      | "Charlie" |
      | "Eve"     |
      | "Alice"   |
      | "Charlie" |
      | "Frank"   |
      | "David"   |
    When executing query:
      """
      use quantified_path match (v1) ((p1)-[]-> (p2)){0,1} (v2) return count(v1.id)
      """
    Then the result should be, in any order:
      | count(v1.id) |
      | 25           |
    When executing query:
      """
      USE quantified_path
      MATCH (l0:Location) ( (l1:Location)-[r1:LOCATED_IN]->(l2:Location)-> (l2:Location)-[r21:LOCATED_IN]->(l22:Location) ){1,3} (l3:Location)
      RETURN l0.name AS l0_name, l3.name AS l3_name, transform(l1, x -> x.name) AS l1_names, transform(l2, x -> x.name) AS l2_names
      """
    Then the result should be, in any order:
      | l0_name | l3_name | l1_names | l2_names |
    When executing query:
      """
      USE quantified_path
      MATCH (l0:Location) ( (l1:Location)-[r1:LOCATED_IN]->(l2:Location)-[r1:LOCATED_IN]->(l4:Location) ){1,3} (l3:Location)
      RETURN l0.name AS l0_name, l3.name AS l3_name, transform(l1, x -> x.name) AS l1_names, transform(l2, x -> x.name) AS l2_names, transform(l4, x -> x.name) AS l4_names
      """
    Then the result should be, in any order:
      | l0_name | l3_name | l1_names | l2_names | l4_names |
    When executing query:
      """
      USE quantified_path
      MATCH (l0:Location) ( (l1:Location)-[r1:LOCATED_IN]->(l2:Location{name:"Museum"}) ){1,3} (l3:Location)
      RETURN l0.name AS l0_name, l3.name AS l3_name, transform(l1, x -> x.name) AS l1_names, transform(l2, x -> x.name) AS l2_names
      """
    Then the result should be, in any order:
      | l0_name | l3_name  | l1_names      | l2_names        |
      | "Park"  | "Museum" | LIST ["Park"] | LIST ["Museum"] |
    When executing query:
      """
      USE quantified_path
      MATCH (l0:Location) ( (l1:Location{name:"Park"})-[r1:LOCATED_IN]->(l2:Location) ){1,3} (l3:Location)
      RETURN l0.name AS l0_name, l3.name AS l3_name, transform(l1, x -> x.name) AS l1_names, transform(l2, x -> x.name) AS l2_names
      """
    Then the result should be, in any order:
      | l0_name | l3_name  | l1_names      | l2_names        |
      | "Park"  | "Museum" | LIST ["Park"] | LIST ["Museum"] |
    When executing query:
      """
      USE quantified_path
      MATCH (l0:Location) ( (l1:Location)-[r1:LOCATED_IN]->(l2:Location) WHERE l0.name <> "Museum" ){1,3} (l3:Location)
      RETURN l0.name AS l0_name, l3.name AS l3_name, transform(l1, x -> x.name) AS l1_names, transform(l2, x -> x.name) AS l2_names
      """
    Then an Error should be raised: "[42002]: Invalid reference: The filter in the quantified path pattern currently does not support referencing variables from outside scopes"
    When executing query:
      """
      USE quantified_path
      MATCH (l0:Location) ( p0 = (l1:Location)-[r1:LOCATED_IN]->(l2:Location) ){1,3} (l3:Location)
      RETURN l0.name AS l0_name, l3.name AS l3_name, transform(l1, x -> x.name) AS l1_names, transform(l2, x -> x.name) AS l2_names
      """
    Then an Error should be raised: "[NT000]: Subpath variable declaration is not supported yet"
    When executing query:
      """
      USE quantified_path
      MATCH (l0:Location) ( (l1:Location)-[r1:LOCATED_IN]->{1,2}(l2:Location) ){1,3} (l3:Location)
      RETURN l3.name AS l3_name
      """
    Then an Error should be raised: "[NS112]: Quantified path patterns are not allowed to be nested"
    When executing query:
      """
      USE quantified_path MATCH (v2)((p1)) {1} (v3) RETURN count(v2) GROUP BY ()
      """
    Then an Error should be raised: "[NS111]: Pattern not supported: `(p1)`"
    And drop the graph "quantified_path"
    And drop the graph type "quantified_path_type"

  @sf01
  Scenario: quantified path patter with edge filter
    When executing query:
      """
      use sf01 match p=(v1{id:318})(()<-[e:KNOWS where e.creationDate is not null]-()){1}(v2{id:143}) return count(*) as cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 1   |
    When executing query:
      """
      use sf01 match p=(v1{id:318})(()<-[e:KNOWS where e.creationDate is null]-()){1}(v2{id:143}) return count(*) as cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 0   |

  Scenario: Simple Quantified Path Pattern
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS social_network_type AS {
        NODE Person (LABEL PERSON {id INT64 PRIMARY KEY}),
        EDGE FOLLOW (Person)-[:FOLLOW{sinceyear INT}]->(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS demo typed social_network_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE demo
      INSERT (a:PERSON{id:1})-[:FOLLOW{sinceyear:1999}]->(b:PERSON{id:2}),
      (b)-[:FOLLOW{sinceyear:2001}]->(c:PERSON{id:3}),
        (c)-[:FOLLOW{sinceyear:2002}]->(d:PERSON{id:4}),
        (d)-[:FOLLOW{sinceyear:2003}]->(e:PERSON{id:5}),
        (b)-[:FOLLOW{sinceyear:2004}]->(a),
        (e)-[:FOLLOW{sinceyear:2005}]->(b),
        (b)-[:FOLLOW{sinceyear:2006}]->(e)
      """
    Then the execution should be successful
    When executing query:
      """
      USE demo
      MATCH p = TRAIL (a:PERSON) ((p1:PERSON)-[f1:FOLLOW]->(p2:PERSON)<-[f2:FOLLOW]-(p3:PERSON)){2} (b:PERSON)
      RETURN a.id, b.id, length(p) AS len
      """
    Then the result should be, in any order:
      | a.id | b.id | len |
    When executing query:
      """
      USE demo
      MATCH (e:PERSON{id:5}), (d:PERSON{id:4})
      INSERT (e)-[:FOLLOW{sinceyear:1999}]->(d)
      """
    Then the execution should be successful
    When executing query:
      """
      USE demo
      MATCH p = TRAIL (a:PERSON) ((p1:PERSON)-[f1:FOLLOW]->(p2:PERSON)<-[f2:FOLLOW]-(p3:PERSON)){2} (b:PERSON)
      LET np = nodes(p)
      RETURN transform(np, x -> x.id) AS ids
      """
    Then the result should be, in any order:
      | ids                  |
      | LIST [1, 2, 5, 4, 3] |
      | LIST [3, 4, 5, 2, 1] |
    And drop the graph "demo"
    And drop the graph type "social_network_type"

  Scenario: Concat head and tail
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS quantified_path_graph_type {
          Node N1 (LABEL N1 {id INT64 PRIMARY KEY}),
          Node N2 (LABEL N2 {id INT64 PRIMARY KEY}),
          Node N3 (LABEL N1 {id INT64 PRIMARY KEY}),
          EDGE E11 (N1)-[LABEL E11 {id INT64}]->(N1),
          EDGE E12 (N1)-[LABEL E12 {id INT64}]->(N2),
          EDGE E13 (N1)-[LABEL E13 {id INT64}]->(N3),
          EDGE E21 (N2)-[LABEL E23 {id INT64}]->(N1),
          EDGE E22 (N2)-[LABEL E22 {id INT64}]->(N2),
          EDGE E23 (N2)-[LABEL E23 {id INT64}]->(N3),
          EDGE E31 (N3)-[LABEL E31 {id INT64}]->(N1),
          EDGE E32 (N3)-[LABEL E32 {id INT64}]->(N2),
          EDGE E33 (N3)-[LABEL E33 {id INT64}]->(N3)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS quantified_path_graph TYPED quantified_path_graph_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE quantified_path_graph
      INSERT (@N1{id:1}),
           (@N1{id:2}),
           (@N2{id:1}),
           (@N2{id:2}),
           (@N2{id:3}),
           (@N3{id:1})
      """
    Then the execution should be successful
    When executing query:
      """
      USE quantified_path_graph
      MATCH (n11@N1{id:1}), (n12@N1{id:2}), (n21@N2{id:1}), (n22@N2{id:2}), (n23@N2{id:3}), (n31@N3{id:1})
      INSERT (n11)-[@E12]->(n21),
           (n11)-[@E12]->(n22),
           (n11)-[@E12]->(n23),
           (n21)-[@E21]->(n12),
           (n22)-[@E23]->(n31),
           (n23)-[@E21]->(n11),
           (n11)-[@E11]->(n11)
      """
    Then the execution should be successful
    When executing query:
      """
      USE quantified_path_graph
      MATCH p = (v0) ((v1@N1{id:1})-[e]->(v2)){2} (v3)
      RETURN transform(nodes(p), x->x.id) as id
      """
    Then the result should be, in any order:
      | id          |
      | LIST[1,1,1] |
      | LIST[1,1,1] |
      | LIST[1,1,2] |
      | LIST[1,1,3] |
    # Repeated node var in inner path pattern
    When executing query:
      """
      USE quantified_path_graph
      MATCH p = (v0) ((v1@N1{id:1})-[e]->(v1)-[]->(v1)){2} (v3)
      RETURN transform(nodes(p), x->x.id) as id
      """
    Then the result should be, in any order:
      | id              |
      | LIST[1,1,1,1,1] |
    # Repeated edge var in inner path pattern
    When executing query:
      """
      USE quantified_path_graph
      MATCH p = () ((v1@N1{id:1})-[e:E11]->(v2@N1{id:1})<-[e:E11]-(v3@N1{id:1})){1} ()
      RETURN count(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 0   |
    # TRAIL must reject reusing the same physical edge twice inside a single quantified repetition.
    When executing query:
      """
      USE quantified_path_graph
      MATCH p = TRAIL () ((v1@N1{id:1})-[e1:E11]->(v2@N1{id:1})<-[e2:E11]-(v3@N1{id:1})){1} ()
      RETURN count(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 0   |
    When executing query:
      """
      USE quantified_path_graph
      MATCH p = (v0) ((v1@N1{id:1})-[e]->(v2)-[]->(v3)){2} (v4)
      RETURN transform(nodes(p), x->x.id) as id
      """
    Then the result should be, in any order:
      | id              |
      | LIST[1,3,1,1,3] |
      | LIST[1,1,1,1,3] |
      | LIST[1,3,1,3,1] |
      | LIST[1,1,1,3,1] |
      | LIST[1,3,1,1,1] |
      | LIST[1,1,1,1,1] |
      | LIST[1,3,1,1,1] |
      | LIST[1,1,1,1,1] |
      | LIST[1,3,1,2,1] |
      | LIST[1,1,1,2,1] |
      | LIST[1,3,1,1,2] |
      | LIST[1,1,1,1,2] |
      | LIST[1,3,1,1,2] |
      | LIST[1,1,1,1,2] |
    When executing query:
      """
      USE quantified_path_graph
      MATCH p = (v0@N1{id:1}) ((v1)-[e]->(v2)){2} (v3)
      RETURN transform(nodes(p), x->x.id) as id
      """
    Then the result should be, in any order:
      | id          |
      | LIST[1,1,2] |
      | LIST[1,1,2] |
      | LIST[1,1,3] |
      | LIST[1,1,1] |
      | LIST[1,3,1] |
      | LIST[1,1,1] |
      | LIST[1,2,1] |
    When executing query:
      """
      USE quantified_path_graph
      MATCH p = (v0) ((v1)-[e]->(v2)){2} (v3@N1{id:1})
      RETURN transform(nodes(p), x->x.id) as id
      """
    Then the result should be, in any order:
      | id          |
      | LIST[1,3,1] |
      | LIST[3,1,1] |
      | LIST[1,1,1] |
    And drop the graph "quantified_path_graph"
    And drop the graph type "quantified_path_graph_type"

  Scenario: Conflict quantified path var
    When executing query:
      """
      USE ldbc
      MATCH (v@Person)
      MATCH p = (v0) ((v)-[e]->(v1)){1, 2} (v)
      FINISH
      """
    Then an Error should be raised: "[NS008]: Semantic error, variable v cannot be defined as both group variable and v:NODE<(Person)>"
    When executing query:
      """
      USE ldbc
      MATCH p = (v) ((v)-[e]->(v1)){1, 2} (v)
      FINISH
      """
    Then an Error should be raised: "[NS008]: Semantic error, variable v cannot be defined as both group variable and v:NODE<(Comment), (Forum), (Organisation), (Person), (Place), (Post), (Tag), (TagClass)>"
    When executing query:
      """
      USE ldbc
      MATCH p = (v0) ((v)-[e]->(v1)){1, 2} (v1)
      FINISH
      """
    Then an Error should be raised: "[42N23]: Invalid syntax, redefined variable: `v1` with conflict type(`Node` vs `LIST<NODE<(Comment), (Organisation), (Person), (Place), (Post), (Tag), (TagClass)>>`)"
