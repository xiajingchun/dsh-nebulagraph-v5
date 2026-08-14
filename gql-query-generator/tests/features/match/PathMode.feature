# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: path mode

  Scenario: path pattern with inner quantifier pattern
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS pm_gt AS {
        NODE EAddr (label EAddr {id int primary key, name string }),
        NODE ETrans (label ETrans{id int primary key} ),
        EDGE EthSrcFundsFlow (EAddr)-[:SrcFundsFlow]->(ETrans),
        EDGE EthDstFundsFlow (ETrans)-[:DstFundsFlow]->(EAddr)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS pm_g pm_gt
      """
    Then the execution should be successful
    When executing query:
      """
      USE pm_g INSERT
               (x:ETrans{id:100})-[:DstFundsFlow]->(a:EAddr{id:1}),
               (y:ETrans{id:200})-[:DstFundsFlow]->(b:EAddr{id:2}),
               (z:ETrans{id:300})-[:DstFundsFlow]->(c:EAddr{id:3}),
               (b)-[:SrcFundsFlow]->(z),
               (b)-[:SrcFundsFlow]->(x),
               (c)-[:SrcFundsFlow]->(y)
      """
    Then the execution should be successful
    When executing query:
      """
      USE pm_g
      MATCH p = TRAIL (src)->(hop1) ((t1@ETrans)->(temp@EAddr)->(t2@ETrans) ){1,4} (@ETrans)->(dst@EAddr)
      RETURN transform(nodes(p), x->x.id) as all_nodes
      """
    Then the result should be, in any order:
      | all_nodes                 |
      | LIST[2,300,3,200,2]       |
      | LIST[3,200,2,300,3,200,2] |
      | LIST[3,200,2,100,1]       |
      | LIST[2,300,3,200,2,100,1] |
      | LIST[3,200,2,300,3]       |
      | LIST[2,300,3,200,2,300,3] |
    When executing query:
      """
      USE pm_g
      MATCH p = ACYCLIC (src)->(hop1) ((t1@ETrans)->(temp@EAddr)->(t2@ETrans) ){1,4} (@ETrans)->(dst@EAddr)
      RETURN transform(nodes(p), x->x.id) as all_nodes
      """
    Then the result should be, in any order:
      | all_nodes           |
      | LIST[3,200,2,100,1] |
    When executing query:
      """
      USE pm_g
      MATCH p = SIMPLE (src)->(hop1) ((t1@ETrans)->(temp@EAddr)->(t2@ETrans) ){1,4} (@ETrans)->(dst@EAddr)
      RETURN transform(nodes(p), x->x.id) as all_nodes
      """
    Then the result should be, in any order:
      | all_nodes           |
      | LIST[2,300,3,200,2] |
      | LIST[3,200,2,100,1] |
      | LIST[3,200,2,300,3] |
    And drop the graph "pm_g"
