# Nearest-Neighbor Query Reference

## KNN（精确最近邻）
依赖 `ORDER BY` + 相似度函数 + `LIMIT`。

### Node Vector KNN Template
```gql
USE <graph_name>
MATCH (v:<Tag>)
ORDER BY <vector_function>(v.<vector_prop>, VECTOR<d,float>([...])) <ASC|DESC>
LIMIT <k>
RETURN v, <vector_function>(v.<vector_prop>, VECTOR<d,float>([...])) AS <score>
```

### Edge Vector KNN Template
```gql
USE <graph_name>
MATCH (s)-[e:<EDGE_TYPE>]->(d)
ORDER BY <vector_function>(e.<vector_prop>, VECTOR<d,float>([...])) <ASC|DESC>
LIMIT <k>
RETURN s, e, d, <vector_function>(e.<vector_prop>, VECTOR<d,float>([...])) AS <score>
```

## ANN（近似最近邻）
在 KNN 基础上增加 `APPROX | APPROXIMATE` 与 `OPTIONS`。

```gql
ORDER BY <vector_function>(...) ASC|DESC
APPROX | APPROXIMATE
LIMIT <k>
OPTIONS { METRIC: <L2|IP>, TYPE: <IVF|HNSW>, NPROBE: <n>, EFSEARCH: <n> }
```

## Function-Direction Constraints
| 函数 | ANN 排序方向 | METRIC |
|------|-------------|--------|
| `euclidean()` | ASC | L2 |
| `inner_product()` | DESC | IP |
| `cosine()` | 仅 KNN | — |

## ANN Defaults
- 未指定 TYPE → 默认 `IVF`
- `TYPE: IVF` 未写 NPROBE → 默认 `8`
- `TYPE: HNSW` 未写 EFSEARCH → 默认 `16`

## Rules
- `NPROBE` 只在 IVF 下有效；`EFSEARCH` 只在 HNSW 下有效。
- 向量维度必须匹配。
- 用户没有明确 ANN 索引前提时默认生成 KNN。
- 不与 `SAMPLE` 混用。
- 不负责生成 `CREATE VECTOR INDEX` DDL。
- 不混写节点向量和边向量。
