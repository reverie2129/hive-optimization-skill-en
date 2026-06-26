# Sections

This file defines all categories, ordering, impact levels, and descriptions.
The category ID in parentheses is the rule filename prefix used to group rules.

---

## 1. Storage & Table Design (storage)

**Impact:** CRITICAL

**Description:** Storage format and table structure are the foundation of Hive MapReduce performance. Columnar formats (ORC/Parquet) with compression can reduce scanned data by several times; sensible partitioning cuts irrelevant data and bucketing supports Map Join and sampling; small files cause Mapper counts to explode and overwhelm the NameNode and job startup overhead. These choices often set the performance ceiling for all subsequent queries at table-creation time.

## 2. Query Optimization (query)

**Impact:** CRITICAL

**Description:** Query writing directly determines MapReduce stage count and data volume per stage. Partition pruning, column pruning, and predicate pushdown let Mappers read only necessary data; CBO and statistics help the optimizer pick JOIN order and algorithms; vectorization processes rows in batches; poorly written count(distinct) and ORDER BY force a single Reducer — a fatal bottleneck.

## 3. JOIN Optimization (join)

**Impact:** CRITICAL

**Description:** JOIN is the most common and most expensive operation in MapReduce jobs. Common Join shuffles all data on the Reduce side; Map Join broadcasts small tables into memory to avoid Shuffle; Bucket Map Join and SMB Join on bucketed tables further eliminate Reduce stages. JOIN order and skew handling determine whether a job finishes in minutes or hours.

## 4. Data Skew (skew)

**Impact:** CRITICAL

**Description:** Data skew is the classic MapReduce "long tail": a few keys (especially NULLs and hot values) concentrate on a single Reducer, so 99% of Reducers finish early while the job stalls on the last 1%. GROUP BY skew, JOIN skew, and NULL skew each have dedicated remedies.

## 5. MapReduce Parameter Tuning (mr)

**Impact:** HIGH

**Description:** Without changing SQL, controlling Mapper/Reducer count, enabling map-side aggregation, running independent stages in parallel, managing speculative execution sensibly, and merging output small files can significantly improve MR job throughput and stability while avoiding downstream small-file problems.

## 6. Engine & Advanced Features (engine)

**Impact:** MEDIUM

**Description:** Correct configuration of dynamic partition writes, strict mode, and other advanced features avoids common full-table scans and partition explosions; when MapReduce is already tuned to its limit and the environment allows, switching to Tez/Spark can yield order-of-magnitude gains.
