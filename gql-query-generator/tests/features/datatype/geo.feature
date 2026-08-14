# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: geography

  Scenario: geo basics
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS geot AS {
          NODE TYPE Geog(labels Geog {id int, g Geography, primary key(id)}),
          NODE TYPE GPoint(labels GPoint {id int, g Geography(Point), primary key(id)}),
          NODE TYPE GLine(labels GLine {id int, g Geography(LineString), primary key(id)}),
          NODE TYPE GPolygon(labels GPolygon {id int, g Geography(Polygon), primary key(id)})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH geo TYPED geot
      """
    Then the execution should be successful
    When executing query:
      """
      USE geo INSERT (@Geog{id: 101, g: ST_GeogFromWkt("POINT(3 8)")}),
        (@Geog{id: 102, g: ST_GeogFromText("LINESTRING(3 8, 4.7 73.23)")}),
        (@Geog{id: 103, g: ST_GeogFromText("POLYGON((0 1, 1 2, 2 3, 0 1))")})
      """
    Then the execution should be successful
    When executing query:
      """
      USE geo INSERT (@GPoint{id: 201, g: ST_GeogFromWkt("LINESTRING(3 8, 4.7 73.23)")})
      """
    Then an Error should be raised: "[NR029]: Invalid spatial cast: can not cast from `GEOGRAPHY(LineString)` to `GEOGRAPHY(Point)`, in expression: CAST(LINESTRING(3 8, 4.7 73.23) AS GEOGRAPHY(Point))"
    When executing query:
      """
      USE geo INSERT (@GPoint{id: 201, g: ST_GeogFromWkt("POINT(3 8)")})
      """
    Then the execution should be successful
    When executing query:
      """
      USE geo INSERT (@GLine{id: 302, g: ST_GeogFromWkt("LINESTRING(3 8, 4.7 73.23)")})
      """
    Then the execution should be successful
    When executing query:
      """
      USE geo INSERT (@GPolygon{id: 302, g: ST_GeogFromWkt("POLYGON((0 1, 1 2, 2 3, 0 1))")})
      """
    Then the execution should be successful
    When executing query:
      """
      USE geo MATCH (v:Geog) RETURN ST_AsText(v.g) AS g
      """
    Then the result should be, in any order:
      | g                               |
      | "POINT(3 8)"                    |
      | "POLYGON((0 1, 1 2, 2 3, 0 1))" |
      | "LINESTRING(3 8, 4.7 73.23)"    |
    When executing query:
      """
      USE geo MATCH (v:GPoint) RETURN ST_AsText(v.g) AS g
      """
    Then the result should be, in any order:
      | g            |
      | "POINT(3 8)" |
    When executing query:
      """
      USE geo MATCH (v:GLine) RETURN ST_AsText(v.g) AS g
      """
    Then the result should be, in any order:
      | g                            |
      | "LINESTRING(3 8, 4.7 73.23)" |
    When executing query:
      """
      USE geo MATCH (v:GPolygon) RETURN ST_AsText(v.g) AS g
      """
    Then the result should be, in any order:
      | g                               |
      | "POLYGON((0 1, 1 2, 2 3, 0 1))" |
    When executing query:
      """
      RETURN ST_ASTEXT(ST_GeogFromText("POINT(24.7 36.842)")) AS p
      """
    Then the result should be, in any order:
      | p                    |
      | "POINT(24.7 36.842)" |
    When executing query:
      """
      RETURN ST_ASTEXT(ST_GeogFromText("LINESTRING(-122.416667 37.783333, -122.383333 37.766667)")) AS p
      """
    Then the result should be, in any order:
      | p                                                          |
      | "LINESTRING(-122.416667 37.783333, -122.383333 37.766667)" |
    When executing query:
      """
      RETURN ST_ASTEXT(ST_GeogFromText("POLYGON((0 0, 0 10, 10 10, 10 0, 0 0), (2 2, 2 4, 4 4, 4 2, 2 2))")) AS p
      """
    Then the result should be, in any order:
      | p                                                                   |
      | "POLYGON((0 0, 0 10, 10 10, 10 0, 0 0), (2 2, 2 4, 4 4, 4 2, 2 2))" |
    When executing query:
      """
      RETURN ST_ASTEXT(ST_GeogFromText("POLYGON((0 0, 0 10, 10 10, 10 0, 0 0), (2 2, 2 4, 4 4, 4 2,)")) AS p
      """
    Then an Error should be raised: "[22G20]: Invalid WKT data: syntax error near `)', in expression: st_astext(st_geogfromtext(\"POLYGON((0 0, 0 10, 10 10, 10 0, 0 0), (2 2, 2 4, 4 4, 4 2,)\"))"
    # st_isvalid
    When executing query:
      """
      RETURN ST_ISValid(ST_GeogFromText("POINT(24.7 36.842)")) AS p
      """
    Then the result should be, in any order:
      | p    |
      | true |
    When executing query:
      """
      RETURN ST_ISValid(ST_GeogFromText("POINT(224.7 36.842)")) AS p
      """
    Then the result should be, in any order:
      | p    |
      | true |
    When executing query:
      """
      RETURN ST_ISValid(ST_GeogFromText("LINESTRING(-122.416667 37.783333, -122.383333 37.766667)")) AS p
      """
    Then the result should be, in any order:
      | p    |
      | true |
    When executing query:
      """
      RETURN ST_ASTEXT(ST_GeogFromText("LINESTRING(-122.416667 37.783333)")) AS p
      """
    Then an Error should be raised: "[22G18]: Invalid linestring line string requires at least 2 coordinates but got 1, in expression: st_astext(st_geogfromtext(\"LINESTRING(-122.416667 37.783333)\"))"
    When executing query:
      """
      RETURN ST_ISValid(ST_GeogFromText("POLYGON((0 1, 1 2, 0 1))")) AS p
      """
    Then an Error should be raised: "[22G19]: Invalid polygon Polygon's 0-th loop contains 3 coordinates, requires at least 4 , in expression: st_isvalid(st_geogfromtext(\"POLYGON((0 1, 1 2, 0 1))\"))"
    When executing query:
      """
      RETURN ST_ISValid(ST_GeogFromText("POLYGON((0 1, 1 2, 2 3, 3 4))")) AS p
      """
    Then an Error should be raised: "[22G19]: Invalid polygon Polygon's 0-th LinearRing is not closed, in expression: st_isvalid(st_geogfromtext(\"POLYGON((0 1, 1 2, 2 3, 3 4))\"))"
    # ST_GeogFromText
    When executing query:
      """
      RETURN ST_AsText(ST_GeogFromText("LINESTRING(1.0 2.1)")) AS p
      """
    Then an Error should be raised: "[22G18]: Invalid linestring line string requires at least 2 coordinates but got 1, in expression: st_astext(st_geogfromtext(\"LINESTRING(1.0 2.1)\"))"
    When executing query:
      """
      RETURN ST_AsText(ST_GeogFromText("POLYGON((1.0 2.1, 2 4))")) AS p
      """
    Then an Error should be raised: "[22G19]: Invalid polygon Polygon's 0-th loop contains 2 coordinates, requires at least 4 , in expression: st_astext(st_geogfromtext(\"POLYGON((1.0 2.1, 2 4))\"))"
    # st_centroid
    When executing query:
      """
      RETURN ST_AsText(ST_Centroid(ST_GeogFromText('POINT(1 2)'))) AS p
      """
    Then the result should be, in any order:
      | p            |
      | "POINT(1 2)" |
    When executing query:
      """
      RETURN ST_AsText(ST_Centroid(ST_GeogFromText('LINESTRING(1 1, 2 2, 3 3)'))) AS p
      """
    Then the result should be, in any order:
      | p                                            |
      | "POINT(1.999619094813822 2.000076020985223)" |
    # FIXME: incorrect result
    When executing query:
      """
      RETURN ST_AsText(ST_Centroid(ST_GeogFromText('POLYGON((0 1, 1 2, 2 3, 3 4, 0 1))'))) AS p
      """
    Then the result should be, in any order:
      | p                                              |
      | "POINT(1.5321755010792664 2.5338019175825375)" |
    When executing query:
      """
      RETURN ST_Intersects(ST_GeogFromText('POINT(0 1)'), ST_GeogFromText('POLYGON((0 1, 1 2, 2 3, 0 1))')) AS v
      """
    Then the result should be, in any order:
      | v    |
      | true |
    When executing query:
      """
      RETURN ST_Intersects(ST_GeogFromText('POINT(3 8)'), ST_GeogFromText('POINT(3 8)')) AS v
      """
    Then the result should be, in any order:
      | v    |
      | true |
    When executing query:
      """
      RETURN ST_Intersects(ST_GeogFromText('POINT(3 8)'), ST_GeogFromText('LINESTRING(3 8, 4.7 73.23)')) AS v
      """
    Then the result should be, in any order:
      | v    |
      | true |
    When executing query:
      """
      USE geo INSERT (@Geog{id: 108, g: ST_GeogFromWkt("POINT(72.3 84.6)")})
      """
    Then the execution should be successful
    When executing query:
      """
      USE geo INSERT (@GPoint{id: 208, g: ST_GeogFromWkt("POINT(0.01 0.01)")})
      """
    Then the execution should be successful
    When executing query:
      """
      USE geo INSERT (@GLine{id: 308, g: ST_GeogFromWkt("LINESTRING(9 9, 8 8, 7 7, 9 9)")})
      """
    Then the execution should be successful
    When executing query:
      """
      USE geo INSERT (@GPolygon{id: 408, g: ST_GeogFromWkt("POLYGON((0 1, 1 2, 2 3, 0 1))")})
      """
    Then the execution should be successful
    # cell id
    When executing query:
      """
      USE geo MATCH (v:Geog) RETURN v.id AS vid, S2_CellIdFromPoint(v.g) AS cid
      """
    Then the result should be, in any order:
      | vid | cid                 |
      | 108 | 4987215245349669805 |
      | 101 | 1166542697063163289 |
      | 102 | 0                   |
      | 103 | 0                   |
    When executing query:
      """
      USE geo MATCH (v:Geog) RETURN v.id AS vid, S2_CoveringCellIds(v.g) AS cids
      """
    Then the result should be, in any order:
      | vid | cids                                                                                                                                                                  |
      | 108 | LIST[4987215245349669805]                                                                                                                                             |
      | 101 | LIST[1166542697063163289]                                                                                                                                             |
      | 102 | LIST[1167558203395801088,1279022294173220864,1315051091192184832,1351079888211148800,5039527983027585024,5062045981164437504,5174635971848699904,5183643171103440896] |
      | 103 | LISt[1152391494368201343,1153466862374223872,1153554823304445952,1153836298281156608,1153959443583467520,1154240918560178176,1160503736791990272,1160591697722212352] |
    # ST_Intersects
    When executing query:
      """
      USE geo MATCH (v:Geog) WHERE ST_Intersects(v.g, ST_GeogFromText('POINT(3 8)')) RETURN v.id AS vid, ST_AsText(v.g) AS g
      """
    Then the result should be, in any order:
      | vid | g                            |
      | 101 | "POINT(3 8)"                 |
      | 102 | "LINESTRING(3 8, 4.7 73.23)" |
    When executing query:
      """
      USE geo MATCH (v:Geog) WHERE ST_Intersects(v.g, ST_GeogFromText('POINT(0 1)')) RETURN v.id AS vid, ST_AsText(v.g) AS g
      """
    Then the result should be, in any order:
      | vid | g                               |
      | 103 | "POLYGON((0 1, 1 2, 2 3, 0 1))" |
    When executing query:
      """
      USE geo MATCH (v:Geog) WHERE ST_Intersects(v.g, ST_GeogFromText('POINT(4.7 73.23)')) RETURN v.id AS vid, ST_AsText(v.g) AS g
      """
    Then the result should be, in any order:
      | vid | g                            |
      | 102 | "LINESTRING(3 8, 4.7 73.23)" |
    When executing query:
      """
      USE geo MATCH (v:Geog) WHERE ST_Intersects(v.g, ST_Point(72.3, 84.6)) RETURN v.id AS vid, ST_AsText(v.g) AS g
      """
    Then the result should be, in any order:
      | vid | g                  |
      | 108 | "POINT(72.3 84.6)" |
    # ST_Distance
    When executing query:
      """
      USE geo MATCH (v:Geog) WHERE ST_Distance(v.g, ST_Point(3, 8)) < 1.0 RETURN v.id AS vid, ST_AsText(v.g) AS g
      """
    Then the result should be, in any order:
      | vid | g                            |
      | 101 | "POINT(3 8)"                 |
      | 102 | "LINESTRING(3 8, 4.7 73.23)" |
    When executing query:
      """
      USE geo MATCH (v:Geog) WHERE ST_Distance(v.g, ST_Point(3, 8)) <= 1.0 RETURN v.id AS vid, ST_AsText(v.g) AS g
      """
    Then the result should be, in any order:
      | vid | g                            |
      | 101 | "POINT(3 8)"                 |
      | 102 | "LINESTRING(3 8, 4.7 73.23)" |
    When executing query:
      """
      USE geo MATCH (v:Geog) WHERE ST_Distance(v.g, ST_Point(3, 8)) <= 8909524.383934561 RETURN v.id AS vid, ST_AsText(v.g) AS g
      """
    Then the result should be, in any order:
      | vid | g                               |
      | 101 | "POINT(3 8)"                    |
      | 102 | "LINESTRING(3 8, 4.7 73.23)"    |
      | 103 | "POLYGON((0 1, 1 2, 2 3, 0 1))" |
      | 108 | "POINT(72.3 84.6)"              |
    When executing query:
      """
      USE geo MATCH (v:Geog) WHERE ST_Distance(v.g, ST_Point(3, 8)) < 8909524.383934561 RETURN v.id AS vid, ST_AsText(v.g) AS g
      """
    Then the result should be, in any order:
      | vid | g                               |
      | 101 | "POINT(3 8)"                    |
      | 102 | "LINESTRING(3 8, 4.7 73.23)"    |
      | 103 | "POLYGON((0 1, 1 2, 2 3, 0 1))" |
    When executing query:
      """
      USE geo MATCH (v:Geog) WHERE ST_Distance(v.g, ST_Point(3, 8)) < 8909524.383934563 RETURN v.id AS vid, ST_AsText(v.g) AS g
      """
    Then the result should be, in any order:
      | vid | g                               |
      | 101 | "POINT(3 8)"                    |
      | 102 | "LINESTRING(3 8, 4.7 73.23)"    |
      | 103 | "POLYGON((0 1, 1 2, 2 3, 0 1))" |
      | 108 | "POINT(72.3 84.6)"              |
    # ST_DWithin
    When executing query:
      """
      USE geo MATCH (v:Geog) WHERE ST_DWithin(v.g, ST_Point(3, 8), 8909524.383934561) RETURN v.id AS vid, ST_AsText(v.g) AS g
      """
    Then the result should be, in any order:
      | vid | g                               |
      | 101 | "POINT(3 8)"                    |
      | 102 | "LINESTRING(3 8, 4.7 73.23)"    |
      | 103 | "POLYGON((0 1, 1 2, 2 3, 0 1))" |
      | 108 | "POINT(72.3 84.6)"              |
    When executing query:
      """
      USE geo MATCH (v:Geog) WHERE ST_DWithin(v.g, ST_Point(3, 8), 100) RETURN v.id AS vid, ST_AsText(v.g) AS g
      """
    Then the result should be, in any order:
      | vid | g                            |
      | 101 | "POINT(3 8)"                 |
      | 102 | "LINESTRING(3 8, 4.7 73.23)" |
    # ST_Covers
    When executing query:
      """
      USE geo MATCH (v:Geog) WHERE ST_Covers(v.g, ST_Point(3, 8)) RETURN v.id AS vid, ST_AsText(v.g) AS g
      """
    Then the result should be, in any order:
      | vid | g                            |
      | 101 | "POINT(3 8)"                 |
      | 102 | "LINESTRING(3 8, 4.7 73.23)" |
    When executing query:
      """
      USE geo MATCH (v:Geog) WHERE ST_Covers(ST_GeogFromText('POLYGON((-0.7 3.8,3.6 3.2,1.8 -0.8,-3.4 2.4,-0.7 3.8))'), v.g) RETURN v.id AS vid, ST_AsText(v.g) AS g
      """
    Then the result should be, in any order:
      | vid | g                               |
      | 103 | "POLYGON((0 1, 1 2, 2 3, 0 1))" |
    When executing query:
      """
      USE geo MATCH (v:Geog) WHERE ST_CoveredBy(v.g, ST_GeogFromText('POLYGON((-0.7 3.8,3.6 3.2,1.8 -0.8,-3.4 2.4,-0.7 3.8))')) RETURN v.id AS vid, ST_AsText(v.g) AS g
      """
    Then the result should be, in any order:
      | vid | g                               |
      | 103 | "POLYGON((0 1, 1 2, 2 3, 0 1))" |
    # insert null test
    When executing query:
      """
      USE geo INSERT (@GPoint{id: 8899, g: null})
      """
    Then the execution should be successful
    When executing query:
      """
      USE geo MATCH (v{id: 8899}) RETURN v.g AS g
      """
    Then the result should be, in any order:
      | g    |
      | null |
    When executing query:
      """
      DROP GRAPH geo
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE geot
      """
    Then the execution should be successful

  Scenario: geo index
    # geo type cannot be primary key
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS illegal_geot AS {
          NODE TYPE Geog(labels Geog {g Geography, primary key(g)})
      }
      """
    Then an Error should be raised: "[NT005]: Unsupported primary key type of `g` in node type `Geog`"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS index_geot AS {
          NODE TYPE GNode(labels Geog {id int, g Geography NOT NULL, ng Geography, primary key(id)}),
          EDGE TYPE GEdge (GNode)-[LABEL GEdge {g Geography NOT NULL, ng Geography }]->(GNode)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH index_geo TYPED index_geot
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_geo INSERT (@GNode{id: 101, g: ST_GeogFromWkt("POINT(3 8)")}),
        (@GNode{id: 102, g: ST_GeogFromText("LINESTRING(3 8, 4.7 73.23)")}),
        (@GNode{id: 103, g: ST_GeogFromText("POLYGON((0 1, 1 2, 2 3, 0 1))")})
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_geo CREATE INDEX IF NOT EXISTS g1 ON NODE GNode(id, g)
      """
    Then an Error should be raised: "[NC304]: Illegal DDL: Unsupport indexed property type of g"
    When executing query:
      """
      USE index_geo CREATE SPATIAL INDEX IF NOT EXISTS ng1 ON NODE GNode(id, s2_max_level = 30, s2_max_cells = 8)
      """
    Then an Error should be raised: "[NC206]: Invalid spatial index: expect spatial type but got id(INT64)"
    When executing query:
      """
      USE index_geo MATCH (f{id: 101}), (t)
      INSERT (f)-[@GEdge{g: f.g}]->(t)
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_geo MATCH (v{id: 101}) RETURN ST_AsText(v.ng) AS g
      """
    Then the result should be, in any order:
      | g    |
      | null |
    When executing query:
      """
      USE index_geo MATCH (v{id: 101})-[e:GEdge]->() RETURN ST_AsText(e.ng) AS g
      """
    Then the result should be, in any order:
      | g    |
      | null |
      | null |
      | null |
    When executing query:
      """
      USE index_geo CREATE SPATIAL INDEX IF NOT EXISTS ng1 ON NODE GNode(g, s2_max_level = 30, s2_max_cells = 8)
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_geo CREATE SPATIAL INDEX IF NOT EXISTS eg1 ON Edge GEdge(g, s2_max_level = 30, s2_max_cells = 8)
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_geo SHOW INDEXES
      """
    Then the result should contain:
      | name  | state   | index_type                           | schema            | graph_name  | entity_type | element_type | properties |
      | "ng1" | "Valid" | "Spatial(max_level=30, max_cells=8)" | "/default_schema" | "index_geo" | "Node"      | "GNode"      | LIST["g"]  |
      | "eg1" | "Valid" | "Spatial(max_level=30, max_cells=8)" | "/default_schema" | "index_geo" | "Edge"      | "GEdge"      | LIST["g"]  |
    # index on nullable spatial field
    When executing query:
      """
      USE index_geo CREATE SPATIAL INDEX IF NOT EXISTS null_ng1 ON NODE GNode(ng, s2_max_level = 30, s2_max_cells = 8)
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_geo CREATE SPATIAL INDEX IF NOT EXISTS null_eg1 ON Edge GEdge(ng, s2_max_level = 30, s2_max_cells = 8)
      """
    Then the execution should be successful
    # insert after indexes was created
    When executing query:
      """
      USE index_geo INSERT (@GNode{id: 201, g: ST_GeogFromWkt("POINT(8 8)")}),
        (@GNode{id: 202, g: ST_GeogFromText("LINESTRING(8 8, 4.7 73.23)")}),
        (@GNode{id: 203, g: ST_GeogFromText("POLYGON((0 1, 8 2, 2 3, 0 1))")})
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_geo MATCH (f{id: 201}), (t WHERE t.id > 200)
      INSERT (f)-[@GEdge{g: f.g}]->(t)
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_geo CREATE SPATIAL INDEX ng1 ON NODE GNode(g, s2_max_level = 30, s2_max_cells = 8)
      """
    Then an Error should be raised: "[NC115]: Node spatial index already exists: ng1"
    When executing query:
      """
      USE index_geo CREATE SPATIAL INDEX eg1 ON Edge GEdge(g, s2_max_level = 30, s2_max_cells = 8)
      """
    Then an Error should be raised: "[NC116]: Edge spatial index already exists: eg1"
    When executing query:
      """
      USE index_geo CREATE SPATIAL INDEX ng1 ON NODE GNode(g, s2_max_level = 0, s2_max_cells = 8)
      """
    Then an Error should be raised: "[NC206]: Invalid spatial index: expect max level in range (0, 30] but got 0"
    When executing query:
      """
      USE index_geo CREATE SPATIAL INDEX ng1 ON NODE GNode(g, s2_max_level = 30, s2_max_cells = 0)
      """
    Then an Error should be raised: "[NC206]: Invalid spatial index: expect max cell in range (0, 256] but got 0"
    When executing query:
      """
      USE index_geo CREATE SPATIAL INDEX eg1 ON Edge GEdge(g, s2_max_level = 0, s2_max_cells = 8)
      """
    Then an Error should be raised: "[NC206]: Invalid spatial index: expect max level in range (0, 30] but got 0"
    When executing query:
      """
      USE index_geo CREATE SPATIAL INDEX eg1 ON Edge GEdge(g, s2_max_level = 30, s2_max_cells = 0)
      """
    Then an Error should be raised: "[NC206]: Invalid spatial index: expect max cell in range (0, 256] but got 0"
    # test update
    When executing query:
      """
      USE index_geo INSERT (@GNode{id: 301, g: ST_GeogFromWkt("POINT(8 8)")}),
        (@GNode{id: 302, g: ST_GeogFromText("LINESTRING(8 8, 4.7 73.23)")}),
        (@GNode{id: 303, g: ST_GeogFromText("POLYGON((0 1, 8 2, 2 3, 0 1))")})
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_geo MATCH (f{id: 301}), (t WHERE t.id > 300)
      INSERT (f)-[@GEdge{g: f.g}]->(t)
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_geo MATCH (f{id: 301})-[e@GEdge]->() RETURN ST_ASTEXT(e.g) AS g
      """
    Then the result should be, in any order:
      | g            |
      | "POINT(8 8)" |
      | "POINT(8 8)" |
      | "POINT(8 8)" |
    When executing query:
      """
      USE index_geo MATCH (f{id: 301})-[e@GEdge]->() SET e.g = ST_GeogFromText("POINT(9 9)")
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_geo MATCH (f{id: 301})-[e@GEdge]->() RETURN ST_ASTEXT(e.g) AS g
      """
    Then the result should be, in any order:
      | g            |
      | "POINT(9 9)" |
      | "POINT(9 9)" |
      | "POINT(9 9)" |
    When executing query:
      """
      USE index_geo MATCH (f{id: 301}) RETURN ST_ASTEXT(f.g) AS g
      """
    Then the result should be, in any order:
      | g            |
      | "POINT(8 8)" |
    When executing query:
      """
      USE index_geo MATCH (f{id: 301}) SET f.g = ST_GeogFromText("POINT(10 10)")
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_geo match (f{id: 301}) RETURN ST_ASTEXT(f.g) AS g
      """
    Then the result should be, in any order:
      | g              |
      | "POINT(10 10)" |
    When executing query:
      """
      USE index_geo match (f{id: 301})-[e@GEdge]->() DELETE e
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_geo match (f{id: 301})-[e@GEdge]->() RETURN ST_ASTEXT(e.g) AS g
      """
    Then the result should be, in any order:
      | g |
    # delete test
    When executing query:
      """
      USE index_geo match (f{id: 301}) DELETE f
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_geo match (f{id: 301}) RETURN ST_ASTEXT(f.g) AS g
      """
    Then the result should be, in any order:
      | g |
    When executing query:
      """
      USE index_geo DROP INDEX ng1
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_geo DROP INDEX null_ng1
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_geo DROP INDEX eg1
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_geo DROP INDEX null_eg1
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH index_geo
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE index_geot
      """
    Then the execution should be successful

  Scenario: geo index query
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS index_query_geot AS {
          NODE TYPE GNode(labels GNode {id int, g Geography NOT NULL, primary key(id)}),
          EDGE TYPE GEdge (GNode)-[LABEL GEdge {g Geography NOT NULL}]->(GNode)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH index_query_geo TYPED index_query_geot
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_query_geo CREATE SPATIAL INDEX IF NOT EXISTS index_query_geo_ng1 ON NODE GNode(g, s2_max_level = 30, s2_max_cells = 8)
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_query_geo CREATE SPATIAL INDEX IF NOT EXISTS index_query_geo_eg1 ON Edge GEdge(g, s2_max_level = 30, s2_max_cells = 8)
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_query_geo INSERT (@GNode{id: 201, g: ST_GeogFromWkt("POINT(8 8)")}),
        (@GNode{id: 202, g: ST_GeogFromText("LINESTRING(8 8, 4.7 73.23)")}),
        (@GNode{id: 203, g: ST_GeogFromText("POLYGON((0 1, 8 2, 2 3, 0 1))")}),
        (@GNode{id: 204, g: ST_GeogFromWkt("POINT(10 10)")}),
        (@GNode{id: 205, g: ST_GeogFromText("LINESTRING(10 10, 15 15)")}),
        (@GNode{id: 206, g: ST_GeogFromText("POLYGON((5 5, 15 5, 15 15, 5 15, 5 5))")}),
        (@GNode{id: 207, g: ST_GeogFromWkt("POINT(20 20)")}),
        (@GNode{id: 208, g: ST_GeogFromText("LINESTRING(20 20, 25 25)")}),
        (@GNode{id: 209, g: ST_GeogFromText("POLYGON((18 18, 22 18, 22 22, 18 22, 18 18))")})
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_query_geo MATCH (f{id: 201}), (t)
      INSERT (f)-[@GEdge{g: t.g}]->(t)
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_query_geo MATCH (f{id: 204}), (t)
      INSERT (f)-[@GEdge{g: t.g}]->(t)
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_query_geo MATCH (f{id: 207}), (t)
      INSERT (f)-[@GEdge{g: t.g}]->(t)
      """
    Then the execution should be successful
    # 1. test ST_Intersects
    When executing query:
      """
      USE index_query_geo
      MATCH (v:GNode /*+ ignore_index(index_query_geo_ng1) */)
      WHERE ST_Intersects(v.g, ST_GeogFromText('POINT(8 8)'))
      RETURN v.id as vid, ST_AsText(v.g) as g
      """
    Then the result should be, in any order:
      | vid | g                                        |
      | 201 | "POINT(8 8)"                             |
      | 202 | "LINESTRING(8 8, 4.7 73.23)"             |
      | 206 | "POLYGON((5 5, 15 5, 15 15, 5 15, 5 5))" |
    When executing query:
      """
      USE index_query_geo
      MATCH (v:GNode)
      WHERE ST_Intersects(v.g, ST_GeogFromText('POINT(8 8)'))
      RETURN v.id as vid, ST_AsText(v.g) as g
      """
    Then the result should be, in any order:
      | vid | g                                        |
      | 201 | "POINT(8 8)"                             |
      | 202 | "LINESTRING(8 8, 4.7 73.23)"             |
      | 206 | "POLYGON((5 5, 15 5, 15 15, 5 15, 5 5))" |
    # IndexSelector should still choose geo index for the following query
    When executing query:
      """
      USE index_query_geo
      MATCH (v:GNode)
      WHERE ST_Intersects(v.g, ST_GeogFromText('POINT(8 8)')) AND v.id <> 202
      RETURN v.id as vid, ST_AsText(v.g) as g
      """
    Then the result should be, in any order:
      | vid | g                                        |
      | 201 | "POINT(8 8)"                             |
      | 206 | "POLYGON((5 5, 15 5, 15 15, 5 15, 5 5))" |
    # IndexSelector should choose id index(primary key index) instead of geo index for the following query
    When executing query:
      """
      USE index_query_geo
      MATCH (v:GNode)
      WHERE ST_Intersects(v.g, ST_GeogFromText('POINT(8 8)')) AND v.id = 202
      RETURN v.id as vid, ST_AsText(v.g) as g
      """
    Then the result should be, in any order:
      | vid | g                            |
      | 202 | "LINESTRING(8 8, 4.7 73.23)" |
    # 2. test ST_DWithin
    When executing query:
      """
      USE index_query_geo
      MATCH (v:GNode)
      WHERE ST_DWithin(v.g, ST_GeogFromText('POINT(8 8)'), 5.0)
      RETURN v.id as vid, ST_AsText(v.g) as g
      """
    Then the result should be, in any order:
      | vid | g                                        |
      | 201 | "POINT(8 8)"                             |
      | 202 | "LINESTRING(8 8, 4.7 73.23)"             |
      | 206 | "POLYGON((5 5, 15 5, 15 15, 5 15, 5 5))" |
    # 3. test ST_Distance
    When executing query:
      """
      USE index_query_geo
      MATCH (v:GNode)
      WHERE ST_Distance(v.g, ST_GeogFromText('POINT(10 10)')) < 3.0
      RETURN v.id as vid, ST_AsText(v.g) as g
      """
    Then the result should be, in any order:
      | vid | g                                        |
      | 204 | "POINT(10 10)"                           |
      | 206 | "POLYGON((5 5, 15 5, 15 15, 5 15, 5 5))" |
      | 205 | "LINESTRING(10 10, 15 15)"               |
    # 4. test ST_Covers
    When executing query:
      """
      USE index_query_geo
      MATCH (v:GNode)
      WHERE ST_Covers(v.g, ST_GeogFromText('POINT(10 10)'))
      RETURN v.id as vid, ST_AsText(v.g) as g
      """
    Then the result should be, in any order:
      | vid | g                                        |
      | 204 | "POINT(10 10)"                           |
      | 205 | "LINESTRING(10 10, 15 15)"               |
      | 206 | "POLYGON((5 5, 15 5, 15 15, 5 15, 5 5))" |
    # 5. test ST_CoveredBy
    When executing query:
      """
      USE index_query_geo
      MATCH (v:GNode)
      WHERE ST_CoveredBy(v.g, ST_GeogFromText('POLYGON((0 0, 30 0, 30 30, 0 30, 0 0))'))
      RETURN v.id as vid, ST_AsText(v.g) as g
      """
    Then the result should be, in any order:
      | vid | g                                              |
      | 201 | "POINT(8 8)"                                   |
      | 204 | "POINT(10 10)"                                 |
      | 205 | "LINESTRING(10 10, 15 15)"                     |
      | 206 | "POLYGON((5 5, 15 5, 15 15, 5 15, 5 5))"       |
      | 207 | "POINT(20 20)"                                 |
      | 208 | "LINESTRING(20 20, 25 25)"                     |
      | 209 | "POLYGON((18 18, 22 18, 22 22, 18 22, 18 18))" |
    # test edge
    # 6. test edge ST_Intersects
    When executing query:
      """
      USE index_query_geo
      MATCH (f{id: 201})-[e:GEdge]->()
      WHERE ST_Intersects(e.g, ST_GeogFromText('POINT(8 8)'))
      RETURN ST_ASTEXT(e.g) as g ORDER BY g
      """
    Then the result should be, in any order:
      | g                                        |
      | "LINESTRING(8 8, 4.7 73.23)"             |
      | "POINT(8 8)"                             |
      | "POLYGON((5 5, 15 5, 15 15, 5 15, 5 5))" |
    # 7. test edge ST_DWithin
    When executing query:
      """
      USE index_query_geo
      MATCH (f{id: 204})-[e:GEdge]->()
      WHERE ST_DWithin(e.g, ST_GeogFromText('POINT(10 10)'), 2)
      RETURN ST_AsText(e.g) as g ORDER BY g
      """
    Then the result should be, in any order:
      | g                                        |
      | "LINESTRING(10 10, 15 15)"               |
      | "POINT(10 10)"                           |
      | "POLYGON((5 5, 15 5, 15 15, 5 15, 5 5))" |
    # 8. test edge ST_Covers
    When executing query:
      """
      USE index_query_geo
      MATCH (f{id: 207})-[e:GEdge]->()
      WHERE ST_CoveredBy(e.g, ST_GeogFromText('POLYGON((0 0, 30 0, 30 30, 0 30, 0 0))'))
      RETURN ST_AsText(e.g) as g ORDER BY g
      """
    Then the result should be, in any order:
      | g                                              |
      | "LINESTRING(10 10, 15 15)"                     |
      | "LINESTRING(20 20, 25 25)"                     |
      | "POINT(10 10)"                                 |
      | "POINT(20 20)"                                 |
      | "POINT(8 8)"                                   |
      | "POLYGON((18 18, 22 18, 22 22, 18 22, 18 18))" |
      | "POLYGON((5 5, 15 5, 15 15, 5 15, 5 5))"       |
    # 9. test empty result
    When executing query:
      """
      USE index_query_geo
      MATCH (v:GNode)
      WHERE ST_Intersects(v.g, ST_GeogFromText('POINT(100 100)'))
      RETURN v.id as vid, ST_AsText(v.g) as g
      """
    Then the result should be, in any order:
      | vid | g |
    # 10. now clean up
    When executing query:
      """
      USE index_query_geo DROP INDEX index_query_geo_ng1
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_query_geo DROP INDEX index_query_geo_eg1
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH index_query_geo
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE index_query_geot
      """
    Then the execution should be successful

  # This scenario is used to test the spatial index query with multiple node/edge types
  # which might or might not have index.
  Scenario: complex geo index query
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS complex_geo_geot AS {
          NODE TYPE IndexedNode1(labels IndexedNode1 {id int, g Geography NOT NULL, primary key(id)}),
          NODE TYPE IndexedNode2(labels IndexedNode2 {id int, g Geography NOT NULL, primary key(id)}),
          NODE TYPE IndexedNode3(labels IndexedNode3 {id int, ng Geography NOT NULL, primary key(id)}),
          NODE TYPE NoIndexNode(labels NoIndexNode {id int, g Geography NOT NULL, primary key(id)}),
          EDGE TYPE IndexedEdge1 (IndexedNode1)-[LABEL IndexedEdge1 {g Geography NOT NULL}]->(IndexedNode2),
          EDGE TYPE IndexedEdge2 (IndexedNode2)-[LABEL IndexedEdge2 {g Geography NOT NULL}]->(IndexedNode1),
          EDGE TYPE IndexedEdge3 (IndexedNode3)-[LABEL IndexedEdge3 {ng Geography NOT NULL}]->(IndexedNode1),
          EDGE TYPE NoIndexEdge (IndexedNode1)-[LABEL NoIndexEdge {g Geography NOT NULL}]->(NoIndexNode)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH complex_geo TYPED complex_geo_geot
      """
    Then the execution should be successful
    When executing query:
      """
      USE complex_geo CREATE SPATIAL INDEX IF NOT EXISTS complex_geo_n1 ON NODE IndexedNode1(g, s2_max_level = 30, s2_max_cells = 8)
      """
    Then the execution should be successful
    When executing query:
      """
      USE complex_geo CREATE SPATIAL INDEX IF NOT EXISTS complex_geo_n2 ON NODE IndexedNode2(g, s2_max_level = 30, s2_max_cells = 8)
      """
    Then the execution should be successful
    When executing query:
      """
      USE complex_geo CREATE SPATIAL INDEX IF NOT EXISTS complex_geo_n3 ON NODE IndexedNode3(ng, s2_max_level = 30, s2_max_cells = 8)
      """
    Then the execution should be successful
    When executing query:
      """
      USE complex_geo CREATE SPATIAL INDEX IF NOT EXISTS complex_geo_e1 ON Edge IndexedEdge1(g, s2_max_level = 30, s2_max_cells = 8)
      """
    Then the execution should be successful
    When executing query:
      """
      USE complex_geo CREATE SPATIAL INDEX IF NOT EXISTS complex_geo_e2 ON Edge IndexedEdge2(g, s2_max_level = 30, s2_max_cells = 8)
      """
    Then the execution should be successful
    When executing query:
      """
      USE complex_geo CREATE SPATIAL INDEX IF NOT EXISTS complex_geo_e3 ON Edge IndexedEdge3(ng, s2_max_level = 30, s2_max_cells = 8)
      """
    Then the execution should be successful
    When executing query:
      """
      USE complex_geo INSERT (@IndexedNode1{id: 101, g: ST_GeogFromWkt("POINT(5 5)")}),
        (@IndexedNode1{id: 102, g: ST_GeogFromText("LINESTRING(5 5, 10 10)")}),
        (@IndexedNode1{id: 103, g: ST_GeogFromText("POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))")}),
        (@IndexedNode2{id: 201, g: ST_GeogFromWkt("POINT(8 8)")}),
        (@IndexedNode2{id: 202, g: ST_GeogFromText("LINESTRING(8 8, 15 15, 5 5)")}),
        (@IndexedNode2{id: 203, g: ST_GeogFromText("POLYGON((5 5, 15 5, 15 15, 5 15, 5 5))")}),
        (@NoIndexNode{id: 301, g: ST_GeogFromWkt("POINT(6 6)")}),
        (@NoIndexNode{id: 302, g: ST_GeogFromText("LINESTRING(6 6, 12 12)")}),
        (@NoIndexNode{id: 303, g: ST_GeogFromText("POLYGON((3 3, 12 3, 12 12, 3 12, 3 3))")})
      """
    Then the execution should be successful
    When executing query:
      """
      USE complex_geo MATCH (f:IndexedNode1), (t:IndexedNode2)
      INSERT (f)-[@IndexedEdge1{g: f.g}]->(t)
      """
    Then the execution should be successful
    When executing query:
      """
      USE complex_geo MATCH (f:IndexedNode2), (t:IndexedNode1)
      INSERT (f)-[@IndexedEdge2{g: f.g}]->(t)
      """
    Then the execution should be successful
    When executing query:
      """
      USE complex_geo MATCH (f:IndexedNode1), (t:NoIndexNode)
      INSERT (f)-[@NoIndexEdge{g: f.g}]->(t)
      """
    Then the execution should be successful
    # Test 1: Both nodes and edges have indexes
    # 1.0. test extract spatial predicate, geo index scan should be triggered
    When executing query:
      """
      USE complex_geo
      MATCH (v:IndexedNode1|IndexedNode2)
      WHERE ST_Covers(v.g, ST_GeogFromText('POINT(5 5)')) AND v.id * 2 > 0
      RETURN v.id as vid, ST_AsText(v.g) as g ORDER BY vid
      """
    Then the result should be, in any order:
      | vid | g                                        |
      | 101 | "POINT(5 5)"                             |
      | 102 | "LINESTRING(5 5, 10 10)"                 |
      | 103 | "POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))" |
      | 202 | "LINESTRING(8 8, 15 15, 5 5)"            |
    # 1.1. test ST_Covers on indexed nodes only
    When executing query:
      """
      USE complex_geo
      MATCH (v:IndexedNode1|IndexedNode2)
      WHERE ST_Covers(v.g, ST_GeogFromText('POINT(5 5)'))
      RETURN v.id as vid, ST_AsText(v.g) as g ORDER BY vid
      """
    Then the result should be, in any order:
      | vid | g                                        |
      | 101 | "POINT(5 5)"                             |
      | 102 | "LINESTRING(5 5, 10 10)"                 |
      | 103 | "POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))" |
      | 202 | "LINESTRING(8 8, 15 15, 5 5)"            |
    # 1.2. test ST_Covers on indexed edges only
    When executing query:
      """
      USE complex_geo
      MATCH (s)-[e:IndexedEdge1|IndexedEdge2]->(t)
      WHERE ST_Covers(e.g, ST_GeogFromText('POINT(5 5)'))
      RETURN ST_AsText(e.g) as g, s.id as sid, t.id as tid ORDER BY g
      """
    Then the result should be, in any order:
      | g                                        | sid | tid |
      | "LINESTRING(5 5, 10 10)"                 | 102 | 202 |
      | "LINESTRING(5 5, 10 10)"                 | 102 | 203 |
      | "LINESTRING(5 5, 10 10)"                 | 102 | 201 |
      | "LINESTRING(8 8, 15 15, 5 5)"            | 202 | 101 |
      | "LINESTRING(8 8, 15 15, 5 5)"            | 202 | 102 |
      | "LINESTRING(8 8, 15 15, 5 5)"            | 202 | 103 |
      | "POINT(5 5)"                             | 101 | 202 |
      | "POINT(5 5)"                             | 101 | 203 |
      | "POINT(5 5)"                             | 101 | 201 |
      | "POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))" | 103 | 202 |
      | "POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))" | 103 | 203 |
      | "POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))" | 103 | 201 |
    # 1.3. test ST_Covers on single indexed edge
    When executing query:
      """
      USE complex_geo
      MATCH (s)-[e:IndexedEdge1]->(t)
      WHERE ST_Covers(e.g, ST_GeogFromText('POINT(5 5)'))
      RETURN ST_AsText(e.g) as g, s.id as sid, t.id as tid ORDER BY g
      """
    Then the result should be, in any order:
      | g                                        | sid | tid |
      | "LINESTRING(5 5, 10 10)"                 | 102 | 202 |
      | "LINESTRING(5 5, 10 10)"                 | 102 | 203 |
      | "LINESTRING(5 5, 10 10)"                 | 102 | 201 |
      | "POINT(5 5)"                             | 101 | 202 |
      | "POINT(5 5)"                             | 101 | 203 |
      | "POINT(5 5)"                             | 101 | 201 |
      | "POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))" | 103 | 202 |
      | "POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))" | 103 | 203 |
      | "POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))" | 103 | 201 |
    # Test 2: Mixed scenario - one has index, one doesn't
    # 2.1. test ST_Covers on mixed nodes (indexed + no index)
    When executing query:
      """
      USE complex_geo
      MATCH (v:IndexedNode1|NoIndexNode|IndexedNode3)
      WHERE ST_Covers(v.g, ST_GeogFromText('POINT(5 5)'))
      RETURN v.id as vid, ST_AsText(v.g) as g ORDER BY vid
      """
    Then the result should be, in any order:
      | vid | g                                        |
      | 101 | "POINT(5 5)"                             |
      | 102 | "LINESTRING(5 5, 10 10)"                 |
      | 103 | "POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))" |
      | 303 | "POLYGON((3 3, 12 3, 12 12, 3 12, 3 3))" |
    # 2.2. test ST_Covers on mixed edges (indexed + no index)
    When executing query:
      """
      USE complex_geo
      MATCH (s)-[e:IndexedEdge1|NoIndexEdge|IndexedEdge3]->(t)
      WHERE ST_Covers(e.g, ST_GeogFromText('POINT(5 5)'))
      RETURN ST_AsText(e.g) as g, s.id as sid, t.id as tid ORDER BY g
      """
    Then the result should be, in any order:
      | g                                        | sid | tid |
      | "LINESTRING(5 5, 10 10)"                 | 102 | 301 |
      | "LINESTRING(5 5, 10 10)"                 | 102 | 201 |
      | "LINESTRING(5 5, 10 10)"                 | 102 | 302 |
      | "LINESTRING(5 5, 10 10)"                 | 102 | 202 |
      | "LINESTRING(5 5, 10 10)"                 | 102 | 203 |
      | "LINESTRING(5 5, 10 10)"                 | 102 | 303 |
      | "POINT(5 5)"                             | 101 | 201 |
      | "POINT(5 5)"                             | 101 | 301 |
      | "POINT(5 5)"                             | 101 | 302 |
      | "POINT(5 5)"                             | 101 | 203 |
      | "POINT(5 5)"                             | 101 | 303 |
      | "POINT(5 5)"                             | 101 | 202 |
      | "POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))" | 103 | 203 |
      | "POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))" | 103 | 302 |
      | "POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))" | 103 | 303 |
      | "POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))" | 103 | 301 |
      | "POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))" | 103 | 202 |
      | "POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))" | 103 | 201 |
    # We cannot swap liter for ST_CoveredBy/ST_Covers, fall back to ndoe scan
    When executing query:
      """
      USE complex_geo
      MATCH (v:IndexedNode1|NoIndexNode|IndexedNode3)
      WHERE ST_Covers(ST_GeogFromText('POINT(5 5)'), v.g)
      RETURN v.id as vid, ST_AsText(v.g) as g ORDER BY vid
      """
    Then the result should be, in any order:
      | vid | g            |
      | 101 | "POINT(5 5)" |
    When executing query:
      """
      USE complex_geo
      MATCH (v:IndexedNode1)
      WHERE ST_DWithin(ST_GeogFromText('POINT(5 5)'), v.g, 100)
      RETURN v.id as vid, ST_AsText(v.g) as g ORDER BY vid
      """
    Then the result should be, in any order:
      | vid | g                                        |
      | 101 | "POINT(5 5)"                             |
      | 102 | "LINESTRING(5 5, 10 10)"                 |
      | 103 | "POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))" |
    # test push predicate down through intermediate operators
    When executing query:
      """
      USE complex_geo
      MATCH (v:IndexedNode1)
      LIMIT 1000
      FILTER ST_DWithin(ST_GeogFromText('POINT(5 5)'), v.g, 100)
      RETURN v.id as vid, ST_AsText(v.g) as g ORDER BY vid
      """
    Then the result should be, in any order:
      | vid | g                                        |
      | 101 | "POINT(5 5)"                             |
      | 102 | "LINESTRING(5 5, 10 10)"                 |
      | 103 | "POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))" |
    # test spatial with non-const inputs
    When executing query:
      """
      USE complex_geo
      MATCH (v:IndexedNode1), (t:IndexedNode1)
      WHERE ST_DWithin(v.g, v.g, 100) AND v.g <> t.g
      RETURN v.id as vid, ST_AsText(v.g) as g ORDER BY vid
      """
    Then the result should be, in any order:
      | vid | g                                        |
      | 101 | "POINT(5 5)"                             |
      | 101 | "POINT(5 5)"                             |
      | 102 | "LINESTRING(5 5, 10 10)"                 |
      | 102 | "LINESTRING(5 5, 10 10)"                 |
      | 103 | "POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))" |
      | 103 | "POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))" |
    # Test non-const distance param for ST_DWITHIN
    When executing query:
      """
      USE complex_geo
      MATCH (v:IndexedNode1)
      WHERE ST_DWITHIN(v.g, ST_GEOGFROMTEXT("POINT(100 100)"), v.id)
      RETURN v.g AS g, v.id  AS vid
      """
    Then the result should be, in any order:
      | g | vid |
    # clean up
    When executing query:
      """
      DROP GRAPH complex_geo
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE complex_geo_geot
      """
    Then the execution should be successful

  # Scenario: point only spatial index optimization
  # This scenario tests the optimization for Geography(Point) spatial index.
  Scenario: point only spatial index optimization
    # Create a node type with Geography(Point) only
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS point_only_geot AS {
          NODE TYPE P(labels P {id int, g Geography(Point), primary key(id)})
      }
      """
    Then the execution should be successful
    # Create graph and spatial index
    When executing query:
      """
      CREATE GRAPH point_only_geo TYPED point_only_geot
      """
    Then the execution should be successful
    # Insert multiple points before creating index
    When executing query:
      """
      USE point_only_geo INSERT
        (@P{id: 1, g: ST_GeogFromWkt("POINT(1 1)")}),
        (@P{id: 2, g: ST_GeogFromWkt("POINT(2 2)")}),
        (@P{id: 3, g: ST_GeogFromWkt("POINT(3 3)")})
      """
    Then the execution should be successful
    When executing query:
      """
      USE point_only_geo CREATE SPATIAL INDEX IF NOT EXISTS p_g_idx ON NODE P(g, s2_max_level = 30, s2_max_cells = 8)
      """
    Then the execution should be successful
    # Insert multiple points
    When executing query:
      """
      USE point_only_geo INSERT
        (@P{id: 4, g: ST_GeogFromWkt("POINT(4 4)")}),
        (@P{id: 5, g: ST_GeogFromWkt("POINT(5 5)")}),
        (@P{id: 6, g: ST_GeogFromWkt("POINT(6 6)")})
      """
    Then the execution should be successful
    # Query: ST_Intersects should match a single point
    When executing query:
      """
      USE point_only_geo
      MATCH (v:P)
      WHERE ST_Intersects(v.g, ST_GeogFromText('POINT(2 2)'))
      RETURN v.id as vid, ST_AsText(v.g) as g
      """
    Then the result should be, in any order:
      | vid | g            |
      | 2   | "POINT(2 2)" |
    # Query: ST_DWithin should match all points within a large distance
    When executing query:
      """
      USE point_only_geo
      MATCH (v:P)
      WHERE ST_DWithin(v.g, ST_GeogFromText('POINT(2 2)'), 200000)
      RETURN v.id as vid, ST_AsText(v.g) as g ORDER BY vid
      """
    Then the result should be, in any order:
      | vid | g            |
      | 1   | "POINT(1 1)" |
      | 2   | "POINT(2 2)" |
      | 3   | "POINT(3 3)" |
    # Insert a non-Point geometry, should fail
    When executing query:
      """
      USE point_only_geo INSERT (@P{id: 10, g: ST_GeogFromWkt("LINESTRING(0 0, 1 1)")})
      """
    Then an Error should be raised: "[NR029]: Invalid spatial cast: can not cast from `GEOGRAPHY(LineString)` to `GEOGRAPHY(Point)`, in expression: CAST(LINESTRING(0 0, 1 1) AS GEOGRAPHY(Point))"
    # Cleanup
    When executing query:
      """
      DROP GRAPH point_only_geo
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE point_only_geot
      """
    Then the execution should be successful

  Scenario: geography type functions
    # Create graph type with Geography fields
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS geo_func_geot AS {
          NODE TYPE GeoFuncNode(labels GeoFuncNode {id int, g Geography, ng Geography, primary key(id)})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH geo_func TYPED geo_func_geot
      """
    Then the execution should be successful
    # Insert test data with null and non-null Geography values
    When executing query:
      """
      USE geo_func INSERT
        (@GeoFuncNode{id: 1, g: ST_GeogFromWkt("POINT(1 1)"), ng: null}),
        (@GeoFuncNode{id: 2, g: ST_GeogFromWkt("LINESTRING(1 1, 2 2)"), ng: ST_GeogFromWkt("POINT(2 2)")}),
        (@GeoFuncNode{id: 3, g: null, ng: ST_GeogFromWkt("POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))")}),
        (@GeoFuncNode{id: 4, g: ST_GeogFromWkt("POINT(3 3)"), ng: null}),
        (@GeoFuncNode{id: 5, g: ST_GeogFromWkt("LINESTRING(3 3, 4 4)"), ng: ST_GeogFromWkt("POINT(4 4)")})
      """
    Then the execution should be successful
    # Test is_null function
    When executing query:
      """
      USE geo_func MATCH (v:GeoFuncNode)
      WHERE v.g IS NULL
      RETURN v.id AS id, v.g IS NULL AS g_is_null, v.ng is null AS ng_is_null
      """
    Then the result should be, in any order:
      | id | g_is_null | ng_is_null |
      | 3  | true      | false      |
    # Test is_not_null function
    When executing query:
      """
      USE geo_func MATCH (v:GeoFuncNode)
      WHERE v.g IS NOT NULL
      RETURN v.id AS id, v.g IS NOT NULL AS g_is_not_null, v.ng IS NOT NULL AS ng_is_not_null
      """
    Then the result should be, in any order:
      | id | g_is_not_null | ng_is_not_null |
      | 1  | true          | false          |
      | 2  | true          | true           |
      | 4  | true          | false          |
      | 5  | true          | true           |
    # Test in operator with Geography values
    When executing query:
      """
      USE geo_func MATCH (v:GeoFuncNode)
      WHERE v.g IN [ST_GeogFromWkt("POINT(1 1)"), ST_GeogFromWkt("POINT(3 3)")]
      RETURN v.id AS id, ST_AsText(v.g) AS g
      """
    Then the result should be, in any order:
      | id | g            |
      | 1  | "POINT(1 1)" |
      | 4  | "POINT(3 3)" |
    # Test in operator with null values
    When executing query:
      """
      USE geo_func MATCH (v:GeoFuncNode)
      WHERE v.ng IN [null, ST_GeogFromWkt("POINT(2 2)")]
      RETURN v.id AS id, ST_AsText(v.ng) AS ng
      """
    Then the result should be, in any order:
      | id | ng           |
      | 2  | "POINT(2 2)" |
    When executing query:
      """
      USE geo_func MATCH (v:GeoFuncNode)
      WHERE v.ng NOT IN [null, ST_GeogFromWkt("POINT(2 2)")]
      RETURN v.id AS id, ST_AsText(v.ng) AS ng
      """
    Then the result should be, in any order:
      | id | ng                                   |
      | 5  | "POINT(4 4)"                         |
      | 3  | "POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))" |
    # Test collect function with Geography values, null should be ignored
    When executing query:
      """
      USE geo_func MATCH (v:GeoFuncNode)
      ORDER BY v.id
      RETURN collect(ST_ASTEXT(v.g)) AS collected_g
      """
    Then the result should be, in any order:
      | collected_g                                                                      |
      | LIST["POINT(1 1)", "LINESTRING(1 1, 2 2)", "POINT(3 3)", "LINESTRING(3 3, 4 4)"] |
    # Test collect function with non-null Geography values only
    When executing query:
      """
      USE geo_func MATCH (v:GeoFuncNode)
      WHERE v.g IS NOT NULL
      ORDER BY v.id
      RETURN collect(ST_ASTEXT(v.g)) AS collected_non_null_g
      """
    Then the result should be, in any order:
      | collected_non_null_g                                                             |
      | LIST["POINT(1 1)", "LINESTRING(1 1, 2 2)", "POINT(3 3)", "LINESTRING(3 3, 4 4)"] |
    # Test subscript operator on Geography
    When executing query:
      """
      USE geo_func MATCH (v:GeoFuncNode)
      ORDER BY v.id
      RETURN collect(v.ng) AS collected_g
      NEXT
      USE geo_func
      RETURN ST_ASTEXT(collected_g[0]) AS g_first
      """
    Then the result should be, in any order:
      | g_first      |
      | "POINT(2 2)" |
    When executing query:
      """
      USE geo_func MATCH (v:GeoFuncNode)
      ORDER BY v.id
      RETURN collect(distinct v.ng) AS collected_g
      NEXT
      USE geo_func
      FOR g IN collected_g
      RETURN ST_ASTEXT(g) AS g
      """
    Then the result should be, in any order:
      | g                                    |
      | "POINT(2 2)"                         |
      | "POINT(4 4)"                         |
      | "POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))" |
    When executing query:
      """
      USE geo_func MATCH (v) ORDER BY v.g RETURN v.id
      """
    Then an Error should be raised: "[22G04]: Values not comparable: invalid operation `ORDER BY GEOGRAPHY` of `v.g`"
    # Clean up
    When executing query:
      """
      DROP GRAPH geo_func
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE geo_func_geot
      """
    Then the execution should be successful

  Scenario: geography type cannot be multiedge key
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS geography_multiedge_test1 AS {
        NODE person (LABEL person {id INT PRIMARY KEY}),
        EDGE location (person)-[LABEL location {geo Geography MULTIEDGE KEY}]->(person)
      }
      """
    Then an Error should be raised: "[NT014]: Unsupported multiple edge key of `geo` in edge type `location`"
    When executing query:
      """
      DROP GRAPH TYPE IF EXISTS geography_multiedge_test1
      """
    Then the execution should be successful

  Scenario: geography type alter restrictions
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS geography_alter_test AS {
        NODE TestNode (LABEL TestNode {
          id INT PRIMARY KEY,
          g_any Geography,
          g_point Geography(Point)
        })
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH geography_alter_graph TYPED geography_alter_test
      """
    Then the execution should be successful
    # Test 1: Alter Geography(Any) to Geography(Point) - should fail
    When executing query:
      """
      ALTER GRAPH TYPE geography_alter_test {
        ALTER NODE TYPE TestNode MODIFY PROPERTIES {g_any Geography(Point)}
      }
      """
    Then an Error should be raised: "[NR113]: Property `g_any` of element type `TestNode` cannot be modified from `GEOGRAPHY(Any)` to `GEOGRAPHY(Point)`"
    # Test 2: Alter Geography(Point) to Geography(Any) - should succeed
    When executing query:
      """
      ALTER GRAPH TYPE geography_alter_test {
        ALTER NODE TYPE TestNode MODIFY PROPERTIES {g_point Geography}
      }
      """
    Then the execution should be successful
    # Test 3: Alter Geography(Point) to Geography(LineString) - should fail
    When executing query:
      """
      ALTER GRAPH TYPE geography_alter_test {
        ALTER NODE TYPE TestNode MODIFY PROPERTIES {g_point Geography(LineString)}
      }
      """
    Then an Error should be raised: "[NR113]: Property `g_point` of element type `TestNode` cannot be modified from `GEOGRAPHY(Any)` to `GEOGRAPHY(LineString)"
    # Clean up
    When executing query:
      """
      DROP GRAPH geography_alter_graph
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE geography_alter_test
      """
    Then the execution should be successful

  Scenario: geography type alter with data operations
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS geography_alter_data_test AS {
        NODE TestNode (LABEL TestNode {
          id INT PRIMARY KEY,
          g_any Geography,
          g_point Geography(Point)
        })
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH geography_alter_data_graph TYPED geography_alter_data_test
      """
    Then the execution should be successful
    # Insert data before alter
    When executing query:
      """
      USE geography_alter_data_graph INSERT
        (@TestNode{id: 1, g_any: ST_GeogFromWkt("POINT(1 1)")}),
        (@TestNode{id: 2, g_point: ST_GeogFromWkt("POINT(2 2)")})
      """
    Then the execution should be successful
    # Read data before alter
    When executing query:
      """
      USE geography_alter_data_graph
      MATCH (n:TestNode)
      RETURN n.id AS id, ST_AsText(n.g_any) AS g_any, ST_AsText(n.g_point) AS g_point
      ORDER BY id
      """
    Then the result should be, in any order:
      | id | g_any        | g_point      |
      | 1  | "POINT(1 1)" | null         |
      | 2  | null         | "POINT(2 2)" |
    # Alter g_point to Geography(Any)
    When executing query:
      """
      ALTER GRAPH TYPE geography_alter_data_test {
        ALTER NODE TYPE TestNode MODIFY PROPERTIES {g_point Geography}
      }
      """
    Then the execution should be successful
    # Read data after alter
    When executing query:
      """
      USE geography_alter_data_graph MATCH (n:TestNode)
      RETURN n.id AS id, ST_AsText(n.g_any) AS g_any, ST_AsText(n.g_point) AS g_point
      ORDER BY id
      """
    Then the result should be, in any order:
      | id | g_any        | g_point      |
      | 1  | "POINT(1 1)" | null         |
      | 2  | null         | "POINT(2 2)" |
    # Insert data after alter
    When executing query:
      """
      USE geography_alter_data_graph INSERT
        (@TestNode{id: 3, g_any: ST_GeogFromWkt("LINESTRING(3 3, 4 4)")}),
        (@TestNode{id: 4, g_point: ST_GeogFromWkt("LINESTRING(5 5, 6 6)")})
      """
    Then the execution should be successful
    # Read data after alter and insert
    When executing query:
      """
      USE geography_alter_data_graph MATCH (n:TestNode)
      RETURN n.id AS id, ST_AsText(n.g_any) AS g_any, ST_AsText(n.g_point) AS g_point
      ORDER BY id
      """
    Then the result should be, in any order:
      | id | g_any                  | g_point                |
      | 1  | "POINT(1 1)"           | null                   |
      | 2  | null                   | "POINT(2 2)"           |
      | 3  | "LINESTRING(3 3, 4 4)" | null                   |
      | 4  | null                   | "LINESTRING(5 5, 6 6)" |
    # Clean up
    When executing query:
      """
      DROP GRAPH geography_alter_data_graph
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE geography_alter_data_test
      """
    Then the execution should be successful

  # FIX: https://github.com/vesoft-inc/nebula-ng/issues/8483
  Scenario: spatial index crash prevention test
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS crash_prevention_test AS {
          NODE TYPE CrashTestNode(labels CrashTestNode {id string, name string, g geography, primary key(id)}),
          EDGE TYPE CrashTestEdge (CrashTestNode)-[LABEL CrashTestEdge {g geography}]->(CrashTestNode)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH crash_prevention_graph TYPED crash_prevention_test
      """
    Then the execution should be successful
    When executing query:
      """
      USE crash_prevention_graph INSERT (@CrashTestNode{id: "point_1", name: "p1", g: ST_GeogFromWkt("POINT(121.5 31.2)")})
      """
    Then the execution should be successful
    # Create spatial index on node
    When executing query:
      """
      USE crash_prevention_graph CREATE SPATIAL INDEX IF NOT EXISTS crash_prevention_node_idx ON NODE CrashTestNode(g, s2_max_level = 30, s2_max_cells = 8)
      """
    Then the execution should be successful
    # Test INSERT OR UPDATE on node with existing spatial index - should not crash
    When executing query:
      """
      USE crash_prevention_graph INSERT OR UPDATE(@CrashTestNode{id: "point_1", name: "p1_updated"})
      """
    Then the execution should be successful
    # Test INSERT OR UPDATE with new node - should not crash
    When executing query:
      """
      USE crash_prevention_graph INSERT OR UPDATE(@CrashTestNode{id: "point_2", name: "p2", g: ST_GeogFromWkt("POINT(121.7 31.4)")})
      """
    Then the execution should be successful
    # Create edge with geography property
    When executing query:
      """
      USE crash_prevention_graph MATCH (f{id: "point_1"}), (t{id: "point_2"})
      INSERT (f)-[@CrashTestEdge{g: f.g}]->(t)
      """
    Then the execution should be successful
    # Create spatial index on edge
    When executing query:
      """
      USE crash_prevention_graph CREATE SPATIAL INDEX IF NOT EXISTS crash_prevention_edge_idx ON Edge CrashTestEdge(g, s2_max_level = 30, s2_max_cells = 8)
      """
    Then the execution should be successful
    # Test INSERT OR UPDATE on edge with existing spatial index - should not crash
    When executing query:
      """
      USE crash_prevention_graph MATCH (f{id: "point_1"})-[e@CrashTestEdge]->(t{id: "point_2"})
      SET e.g = ST_GeogFromWkt("POINT(121.6 31.3)")
      """
    Then the execution should be successful
    # Verify data integrity after operations
    When executing query:
      """
      USE crash_prevention_graph MATCH (v:CrashTestNode)
      RETURN v.id AS id, v.name AS name, ST_AsText(v.g) AS g
      ORDER BY id
      """
    Then the result should be, in any order:
      | id        | name         | g                   |
      | "point_1" | "p1_updated" | "POINT(121.5 31.2)" |
      | "point_2" | "p2"         | "POINT(121.7 31.4)" |
    When executing query:
      """
      USE crash_prevention_graph
      MATCH (f{id: "point_1"})-[e@CrashTestEdge]->(t{id: "point_2"})
      RETURN ST_AsText(e.g) AS edge_g
      """
    Then the result should be, in any order:
      | edge_g              |
      | "POINT(121.6 31.3)" |
    # Clean up
    When executing query:
      """
      DROP GRAPH crash_prevention_graph
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE crash_prevention_test
      """
    Then the execution should be successful

  # Test geo index data integrity after compaction
  Scenario: geo index data integrity after compaction
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS index_compact_test AS {
          NODE TYPE a(labels a {id int primary key, name string default "我爱北京天安门", geog geography default ST_GeogFromText("LINESTRING(106.5879 29.5665, 114.3055 30.5497, 118.7386 32.1155, 121.4905 31.2419)")})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH index_compact_test TYPED index_compact_test
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_compact_test CREATE SPATIAL INDEX IF NOT EXISTS geo_idx_compact ON NODE a(geog, s2_max_level = 30, s2_max_cells = 8)
      """
    Then the execution should be successful
    When executing query:
      """
      USE index_compact_test FOR i IN range(1, 100) INSERT OR REPLACE (@a{id: i})
      """
    Then the execution should be successful
    # Test geo index query before compaction
    When executing query:
      """
      USE index_compact_test MATCH (v) WHERE ST_Intersects(v.geog, ST_Point(114.3055, 30.5497)) RETURN count(*) AS count
      """
    Then the result should be, in any order:
      | count |
      | 100   |
    # Execute compaction job
    When executing query:
      """
      SUBMIT JOB COMPACT
      """
    Then the execution should be successful
    # Wait for compaction to complete and verify data integrity
    When executing query:
      """
      SHOW JOBS
      """
    Then the execution should be successful
    And wait "1" seconds
    # Test geo index query after compaction - should return same results
    When executing query:
      """
      USE index_compact_test MATCH (v) WHERE ST_Intersects(v.geog, ST_Point(114.3055, 30.5497)) RETURN count(*) AS count
      """
    Then the result should be, in any order:
      | count |
      | 100   |
    # Test all data is still accessible after compaction
    When executing query:
      """
      USE index_compact_test MATCH (v) RETURN count(*) AS total_count
      """
    Then the result should be, in any order:
      | total_count |
      | 100         |
    # Clean up
    When executing query:
      """
      DROP GRAPH index_compact_test
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE index_compact_test
      """
    Then the execution should be successful

  # Test Geography(Any) -> Geography(Any) modification
  Scenario: geography any to any modification
    # Create graph type with Geography(Any) field
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS geography_any_modify_test AS {
        NODE TestNode (LABEL TestNode {
          id INT PRIMARY KEY,
          g_any Geography
        })
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH geography_any_modify_graph TYPED geography_any_modify_test
      """
    Then the execution should be successful
    # Test: Modify Geography(Any) to Geography(Any) - should succeed
    When executing query:
      """
      ALTER GRAPH TYPE geography_any_modify_test {
        ALTER NODE TYPE TestNode MODIFY PROPERTIES {g_any Geography}
      }
      """
    Then the execution should be successful
    # Clean up
    When executing query:
      """
      DROP GRAPH geography_any_modify_graph
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE geography_any_modify_test
      """
    Then the execution should be successful

  # cast test
  Scenario: geo cast test
    When executing query:
      """
      RETURN CAST(ST_GEOGFROMTEXT('POINT(1 1)') AS GEOGRAPHY(LINESTRING))
      """
    Then an Error should be raised: "[NR029]: Invalid spatial cast: can not cast from `GEOGRAPHY(Point)` to `GEOGRAPHY(LineString)`, in expression: CAST(POINT(1 1) AS GEOGRAPHY(LineString))"
    When executing query:
      """
      RETURN ST_ASTEXT(CAST(ST_GEOGFROMTEXT('POINT(1 1)') AS GEOGRAPHY(ANY))) AS g
      """
    Then the result should be, in any order:
      | g            |
      | "POINT(1 1)" |
    # Test geography list type functionality
    When executing query:
      """
      CREATE GRAPH TYPE test_geo_list_gt AS {
          NODE TYPE Person ({ id int PRIMARY KEY, g_list_point list<geography(point)> })
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH test_geo_list_g test_geo_list_gt
      """
    Then the execution should be successful
    When executing query:
      """
      USE test_geo_list_g INSERT(@Person{id:11,g_list_point:[ST_GeogFromText('Polygon((1 2,3 4,5 6,17 8,1 2))')]})
      """
    Then an Error should be raised: "[NR029]: Invalid spatial cast: can not cast from `GEOGRAPHY(Polygon)` to `GEOGRAPHY(Point)`, in expression: CAST([POLYGON((1 2, 3 4, 5 6, 17 8, 1 2))] AS LIST<GEOGRAPHY(Point)>)"
    When executing query:
      """
      USE test_geo_list_g INSERT(@Person{id:11,g_list_point:[ST_GeogFromText('POINT(1 1)')]})
      """
    Then the execution should be successful
    # Clean up resources
    When executing query:
      """
      DROP GRAPH test_geo_list_g
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE test_geo_list_gt
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN CAST(ST_GeogFromText('POINT(0 0)') AS STRING) AS g
      """
    Then the result should be, in any order:
      | g            |
      | "POINT(0 0)" |
    When executing query:
      """
      RETURN ST_ASTEXT(CAST('POINT(0 1)' as GEOGRAPHY)) AS g
      """
    Then the result should be, in any order:
      | g            |
      | "POINT(0 1)" |
    When executing query:
      """
      RETURN ST_ASTEXT(CAST('POINT(0 1)' as GEOGRAPHY(POINT))) AS g
      """
    Then the result should be, in any order:
      | g            |
      | "POINT(0 1)" |

  Scenario: geography default value modification test
    # Create graph type with Geography(Point) type
    When executing query:
      """
      CREATE GRAPH TYPE test_geo_alter01 AS {
        NODE person ({
          id int primary key,
          geog_point Geography(Point)
        })
      }
      """
    Then the execution should be successful
    # Test: Modify Geography(Point) type with default value - should succeed
    When executing query:
      """
      ALTER GRAPH TYPE test_geo_alter01 {
        ALTER NODE TYPE person MODIFY PROPERTIES {
          geog_point Geography(Point) default st_point(1,1)
        }
      }
      """
    Then the execution should be successful
    # Create graph to test default values
    When executing query:
      """
      CREATE GRAPH test_geo_alter01_graph TYPED test_geo_alter01
      """
    Then the execution should be successful
    # Insert data without specifying geog_point to test default value
    When executing query:
      """
      USE test_geo_alter01_graph INSERT (@person{id: 1})
      """
    Then the execution should be successful
    # Verify that default value is correctly applied
    When executing query:
      """
      USE test_geo_alter01_graph MATCH (p) RETURN p.id AS id, ST_AsText(p.geog_point) AS geog_point
      """
    Then the result should be, in any order:
      | id | geog_point   |
      | 1  | "POINT(1 1)" |
    # Insert data with explicit value to ensure it works
    When executing query:
      """
      USE test_geo_alter01_graph INSERT (@person{id: 2, geog_point: ST_Point(5, 5)})
      """
    Then the execution should be successful
    # Verify both default and explicit values
    When executing query:
      """
      USE test_geo_alter01_graph MATCH (p) RETURN p.id AS id, ST_AsText(p.geog_point) AS geog_point ORDER BY id
      """
    Then the result should be, in any order:
      | id | geog_point   |
      | 1  | "POINT(1 1)" |
      | 2  | "POINT(5 5)" |
    # Clean up
    When executing query:
      """
      DROP GRAPH test_geo_alter01_graph
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE test_geo_alter01
      """
    Then the execution should be successful
