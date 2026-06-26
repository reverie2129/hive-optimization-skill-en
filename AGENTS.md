# Hive Best Practices (MapReduce Job Optimization)

**Version 0.1.0**
hive-optimization-skill-en
June 2026
For Apache Hive 2.x / 3.x on MapReduce

> **Note:**
> This document is primarily for Agents and LLMs when designing, optimizing, and maintaining Hive on MapReduce jobs.
> Humans may also reference it, but content is optimized for AI-assisted workflow automation and consistency.

---

## Summary

Complete optimization best practices for Hive on MapReduce. Covers storage & table design, query optimization, JOIN optimization, data skew remediation, MapReduce parameter tuning, and execution engine selection. Each rule includes explanation, good/bad SQL/parameter examples, and concrete impact on job performance. The core tension always revolves around MapReduce mechanics: reduce scanned data, reduce Shuffle, avoid single-Reducer bottlenecks, eliminate data-skew long tails, control small files.

---

## Table of Contents

1. [Storage & Table Design](#1-storage--table-design) — **CRITICAL**
2. [Query Optimization](#2-query-optimization) — **CRITICAL**
3. [JOIN Optimization](#3-join-optimization) — **CRITICAL**
4. [Data Skew](#4-data-skew) — **CRITICAL**
5. [MapReduce Parameter Tuning](#5-mapreduce-parameter-tuning) — **HIGH**
6. [Engine & Advanced Features](#6-engine--advanced-features) — **MEDIUM**

---

## 1. Storage & Table Design

**Impact: CRITICAL**

Storage format and table structure are the foundation of Hive MapReduce performance — choices at CREATE TABLE time set the performance ceiling for all subsequent queries.

### 1.1 Use Columnar Storage (ORC/Parquet)

**Impact: CRITICAL (5–10× less data scanned)**

TextFile row storage reads entire rows for any column and cannot push predicates down. ORC/Parquet columnar storage reads only referenced columns, with built-in min/max and bloom filter indexes to skip entire stripes/row groups. ORC is the Hive default choice.

```sql
-- Bad: row-oriented TextFile
CREATE TABLE events (user_id BIGINT, payload STRING) STORED AS TEXTFILE;

-- Good: ORC + Snappy + bloom filter
CREATE TABLE events (user_id BIGINT, payload STRING)
STORED AS ORC
TBLPROPERTIES ("orc.compress"="SNAPPY","orc.bloom.filter.columns"="user_id");
```

| Format | Use |
|--------|-----|
| ORC | Hive default — best compression, indexing, vectorization |
| Parquet | Cross-engine interoperability |
| TextFile | Import/debug only — never for large tables |

Reference: [LanguageManual ORC](https://cwiki.apache.org/confluence/display/Hive/LanguageManual+ORC)

### 1.2 Enable Compression

**Impact: HIGH (50–70% less I/O on intermediate results and output)**

Three compression points in MR jobs: final output, Map→Reduce intermediate (Shuffle), and table storage. Shuffle goes over the network — compressing intermediate results yields the most benefit. Snappy is fast with moderate ratio (recommended default); Gzip has high ratio but is slow (cold data).

```sql
SET hive.exec.compress.intermediate=true;
SET mapreduce.map.output.compress=true;
SET mapreduce.map.output.compress.codec=org.apache.hadoop.io.compress.SnappyCodec;
SET hive.exec.compress.output=true;
SET mapreduce.output.fileoutputformat.compress.codec=org.apache.hadoop.io.compress.SnappyCodec;
```

Reference: [CompressedStorage](https://cwiki.apache.org/confluence/display/Hive/CompressedStorage)

### 1.3 Partition by Query Filter Dimensions

**Impact: CRITICAL (partition pruning often yields 10–100× speedup)**

Partitions split data into HDFS directories by column value; queries with partition filters read only relevant directories. Choose **low-cardinality columns that frequently appear in WHERE** (usually `dt`). Never partition on high-cardinality columns (`user_id`) — that creates millions of small partitions and overwhelms the NameNode.

```sql
-- Bad: high-cardinality partition
PARTITIONED BY (user_id BIGINT)
-- Good: daily partition
CREATE TABLE events (user_id BIGINT, ts TIMESTAMP)
PARTITIONED BY (dt STRING) STORED AS ORC;
SELECT count(*) FROM events WHERE dt='2026-01-01';
```

Reference: [Partitioned Tables](https://cwiki.apache.org/confluence/display/Hive/LanguageManual+DDL)

### 1.4 Bucket on JOIN Keys

**Impact: HIGH (enables Bucket Map / SMB Join, eliminates Reduce Shuffle)**

CLUSTERED BY hashes data within partitions into a fixed number of buckets; identical keys land in the same bucket. Two tables bucketed on the same column with the same bucket count (and SORTED BY) can do SMB Join without full Reduce Shuffle.

```sql
CREATE TABLE orders (order_id BIGINT, user_id BIGINT)
CLUSTERED BY (user_id) SORTED BY (user_id) INTO 256 BUCKETS STORED AS ORC;
SET hive.optimize.bucketmapjoin=true;
SET hive.auto.convert.sortmerge.join=true;
```

Reference: [Bucketed Tables](https://cwiki.apache.org/confluence/display/Hive/LanguageManual+DDL+BucketedTables)

### 1.5 Avoid Small Files

**Impact: HIGH (small files explode Mapper count and overwhelm NameNode)**

Small files cause Mapper counts to spike (one per file), NameNode memory pressure, and slow downstream reads. Enable `hive.merge.*` on the write side and CombineHiveInputFormat on the read side.

```sql
SET hive.merge.mapfiles=true;
SET hive.merge.mapredfiles=true;
SET hive.merge.size.per.task=268435456;
SET hive.input.format=org.apache.hadoop.hive.ql.io.CombineHiveInputFormat;
ALTER TABLE events PARTITION (dt='2026-01-01') CONCATENATE;
```

Reference: [Configuration Properties](https://cwiki.apache.org/confluence/display/Hive/Configuration+Properties)

---

## 2. Query Optimization

**Impact: CRITICAL**

Query writing determines MR stage count and data volume per stage.

### 2.1 Queries Must Hit Partition Pruning

**Impact: CRITICAL (otherwise degrades to full-table scan)**

Even with correct partition design, queries must filter on partition columns in WHERE to prune. Anti-patterns: wrapping functions around partition columns, implicit type conversion, no filter at all.

```sql
-- Bad: function on partition column disables pruning
SELECT * FROM events WHERE substr(dt,1,7)='2026-01';
-- Good: direct range filter
SELECT * FROM events WHERE dt>='2026-01-01' AND dt<'2026-02-01';
SET hive.mapred.mode=strict;
```

Reference: [Configuration Properties](https://cwiki.apache.org/confluence/display/Hive/Configuration+Properties)

### 2.2 Select Only Needed Columns

**Impact: HIGH (several times less I/O with columnar storage)**

`SELECT *` forfeits columnar advantages. Column pruning is automatic via ColumnPruner (legacy `hive.optimize.cp` removed in Hive 0.13.0), but SQL must reference only necessary columns.

```sql
-- Bad: SELECT * FROM events WHERE dt='2026-01-01';
-- Good:
SELECT user_id, ts FROM events WHERE dt='2026-01-01';
```

Reference: [Configuration Properties](https://cwiki.apache.org/confluence/display/Hive/Configuration+Properties)

### 2.3 Use Predicate Pushdown

**Impact: HIGH (skip entire stripes/row groups)**

PPD pushes WHERE to the read layer; with ORC indexes, skip data blocks. Functions on columns and outer-join filters in WHERE break pushdown.

```sql
SET hive.optimize.ppd=true;
SET hive.optimize.index.filter=true;
SELECT o.order_id, u.name FROM orders o
LEFT JOIN users u ON o.user_id=u.user_id AND u.country='CN';
```

Reference: [Configuration Properties](https://cwiki.apache.org/confluence/display/Hive/Configuration+Properties)

### 2.4 Enable CBO and Collect Statistics

**Impact: HIGH (pick correct JOIN order and algorithm)**

CBO relies on statistics for JOIN order/algorithm/Map Join conversion. Without stats, the optimizer guesses.

```sql
SET hive.cbo.enable=true;
SET hive.stats.fetch.column.stats=true;
ANALYZE TABLE orders PARTITION(dt) COMPUTE STATISTICS;
ANALYZE TABLE orders PARTITION(dt='2026-01-01') COMPUTE STATISTICS FOR COLUMNS user_id, amount;
```

Reference: [StatsDev](https://cwiki.apache.org/confluence/display/Hive/StatsDev)

### 2.5 Enable Vectorized Execution

**Impact: HIGH (batch 1024 rows, 3–5× CPU improvement)**

Vectorization processes 1024-row column vectors at a time, reducing virtual function calls. Requires ORC format.

```sql
SET hive.vectorized.execution.enabled=true;
SET hive.vectorized.execution.reduce.enabled=true;
-- Coverage check: EXPLAIN VECTORIZATION ...
```

Reference: [Vectorized Query Execution](https://cwiki.apache.org/confluence/display/Hive/Vectorized+Query+Execution)

### 2.6 Optimize COUNT(DISTINCT)

**Impact: MEDIUM (avoid single-Reducer global dedup)**

`COUNT(DISTINCT)` funnels all data to one Reducer. Rewrite with two stages.

```sql
-- Bad: SELECT count(DISTINCT user_id) FROM events WHERE dt='2026-01-01';
-- Good:
SELECT count(1) FROM (SELECT user_id FROM events WHERE dt='2026-01-01' GROUP BY user_id) t;
```

Reference: [LanguageManual GroupBy](https://cwiki.apache.org/confluence/display/Hive/LanguageManual+GroupBy)

### 2.7 Use ORDER BY Sparingly

**Impact: MEDIUM (ORDER BY forces single-Reducer global sort)**

ORDER BY uses one Reducer for global sort. Most scenarios use SORT BY (local order, multiple Reducers) / DISTRIBUTE BY / CLUSTER BY. When global sort is truly needed, always include LIMIT.

```sql
-- Bad: SELECT ... ORDER BY amount DESC; -- single reducer
-- Good: local order
SELECT ... SORT BY amount DESC;
-- Top N: local trim then global
SELECT * FROM (SELECT ... SORT BY amount DESC LIMIT 100) t ORDER BY amount DESC LIMIT 100;
```

| Syntax | Sort scope | Reducers |
|--------|------------|----------|
| ORDER BY | Global | 1 (bottleneck) |
| SORT BY | Per Reducer | Multiple |
| CLUSTER BY | Distribute + local sort | Multiple |

Reference: [LanguageManual SortBy](https://cwiki.apache.org/confluence/display/Hive/LanguageManual+SortBy)

---

## 3. JOIN Optimization

**Impact: CRITICAL**

JOIN is the most expensive operation in MR jobs.

### 3.1 Map Join for Small Tables

**Impact: CRITICAL (broadcast small table to Map side, skip Reduce)**

Common Join shuffles all data on Reduce. Map Join broadcasts the small table to each Mapper's hash table, completing the join on Map side with no Reduce.

```sql
SET hive.auto.convert.join=true;
SET hive.auto.convert.join.noconditionaltask.size=209715200; -- 200MB
SELECT f.order_id, d.name FROM fact_orders f JOIN dim_user d ON f.user_id=d.user_id;
-- Manual: SELECT /*+ MAPJOIN(d) */ ...
```

Reference: [JoinOptimization](https://cwiki.apache.org/confluence/display/Hive/LanguageManual+JoinOptimization)

### 3.2 Bucket Map / SMB Join for Large Tables

**Impact: HIGH (join by bucket, avoid full Shuffle)**

When both tables are too large to broadcast, bucket on the same JOIN column + bucket count: Bucket Map Join loads one bucket into memory; SMB Join merges sorted buckets with minimal memory — optimal for large JOIN large.

```sql
SET hive.optimize.bucketmapjoin=true;
SET hive.optimize.bucketmapjoin.sortedmerge=true;
SET hive.auto.convert.sortmerge.join=true;
SET hive.input.format=org.apache.hadoop.hive.ql.io.BucketizedHiveInputFormat;
```

| JOIN | Prerequisite | Reduce |
|------|--------------|--------|
| Map Join | One table small | None |
| SMB Join | Same bucket column, sorted | None (optimal) |
| Common Join | None | Yes (avoid) |

Reference: [JoinOptimization](https://cwiki.apache.org/confluence/display/Hive/LanguageManual+JoinOptimization)

### 3.3 Arrange JOIN Order Sensibly

**Impact: MEDIUM (reduce intermediate results and Shuffle)**

Filter early (shrink before JOIN); put the largest table last (Common Join caches earlier tables, streams the last). Enable CBO for automatic reorder.

```sql
SELECT f.order_id, u.name FROM
(SELECT user_id, name FROM dim_user WHERE country='CN') u
JOIN (SELECT order_id, user_id FROM fact_orders WHERE dt='2026-01-01') f
ON f.user_id=u.user_id;
-- Hint: /*+ STREAMTABLE(f) */
```

Reference: [LanguageManual Joins](https://cwiki.apache.org/confluence/display/Hive/LanguageManual+Joins)

### 3.4 Handle JOIN Data Skew

**Impact: CRITICAL (hot keys cause single-Reducer long tail)**

Hot keys land on one Reducer. Enable automatic skew join or manually salt known hot keys.

```sql
SET hive.optimize.skewjoin=true;
SET hive.skewjoin.key=100000;
-- Manual salting: add random suffix (0~9) to large-table join key, expand small table 10× to match
SELECT a.user_id, a.amount, b.score
FROM (
 SELECT user_id, amount, concat(cast(user_id AS STRING),'_',cast(floor(rand()*10) AS INT)) AS join_key
 FROM big_orders
) a
JOIN (
 SELECT user_id, score, concat(cast(user_id AS STRING),'_',salt) AS join_key
 FROM big_user LATERAL VIEW explode(array(0,1,2,3,4,5,6,7,8,9)) tmp AS salt
) b ON a.join_key = b.join_key;
```

Reference: [Skewed Join Optimization](https://cwiki.apache.org/confluence/display/Hive/Skewed+Join+Optimization)

---

## 4. Data Skew

**Impact: CRITICAL**

Skew is the classic MR long tail: a few keys concentrate on one Reducer while the job stalls on the last 1%.

### 4.1 Handle GROUP BY Skew

**Impact: HIGH (skewed group keys concentrate on one Reducer)**

Enable map-side aggregation; when skew is confirmed, enable `groupby.skewindata` two-stage scatter. Do not enable skewindata without skew — an extra MR stage slows things down.

```sql
SET hive.map.aggr=true;
SET hive.groupby.skewindata=true; -- only when skew is confirmed
SELECT city, count(*) FROM orders WHERE dt='2026-01-01' GROUP BY city;
```

Reference: [Configuration Properties](https://cwiki.apache.org/confluence/display/Hive/Configuration+Properties)

### 4.2 Handle NULL Join-Key Skew

**Impact: MEDIUM (massive NULLs hash to one Reducer)**

All NULL JOIN keys hash to the same Reducer. For INNER JOIN, filter NULLs early; for LEFT JOIN when NULLs must be kept, salt NULLs with random values.

```sql
-- INNER: filter early
SELECT a.*, b.name FROM (SELECT * FROM logs WHERE user_id IS NOT NULL) a JOIN users b ON a.user_id=b.user_id;
-- LEFT: salt NULLs
... ON CASE WHEN a.user_id IS NULL THEN concat('null_',cast(rand()*1000 AS INT)) ELSE cast(a.user_id AS STRING) END = cast(b.user_id AS STRING);
```

Reference: [Skewed Join Optimization](https://cwiki.apache.org/confluence/display/Hive/Skewed+Join+Optimization)

---

## 5. MapReduce Parameter Tuning

**Impact: HIGH**

Tune throughput and stability via parameters without changing SQL.

### 5.1 Control Mapper Count

**Impact: HIGH (too many → scheduling overhead; too few → insufficient parallelism)**

Mapper count is determined by split count, not direct setting. Control via split size + CombineHiveInputFormat.

```sql
SET hive.input.format=org.apache.hadoop.hive.ql.io.CombineHiveInputFormat;
SET mapreduce.input.fileinputformat.split.maxsize=268435456; -- larger → fewer Mappers
```

Reference: [Configuration Properties](https://cwiki.apache.org/confluence/display/Hive/Configuration+Properties)

### 5.2 Set Reducer Count Sensibly

**Impact: HIGH (too few → bottleneck; too many → small files)**

Prefer auto-estimation by bytes per Reducer; don't blindly hard-code.

```sql
SET hive.exec.reducers.bytes.per.reducer=268435456; -- 256MB per reducer
SET hive.exec.reducers.max=1009;
```

Note: ORDER BY / global aggregation / COUNT(DISTINCT) force a single Reducer — tuning is ineffective; rewrite SQL.

Reference: [Configuration Properties](https://cwiki.apache.org/confluence/display/Hive/Configuration+Properties)

### 5.3 Enable Map-Side Aggregation

**Impact: HIGH (reduce data entering Reduce by an order of magnitude)**

`hive.map.aggr=true` (Combiner-like) pre-aggregates locally on Map, reducing Shuffle. Maximum benefit when group-key cardinality is low.

```sql
SET hive.map.aggr=true;
SET hive.map.aggr.hash.min.reduction=0.5;
```

Reference: [Configuration Properties](https://cwiki.apache.org/confluence/display/Hive/Configuration+Properties)

### 5.4 Run Independent Stages in Parallel

**Impact: MEDIUM (parallel independent stages shorten total time)**

By default stages run serially. Enable parallel execution for independent stages (e.g., UNION ALL branches). Watch resource usage.

```sql
SET hive.exec.parallel=true;
SET hive.exec.parallel.thread.number=8;
```

Reference: [Configuration Properties](https://cwiki.apache.org/confluence/display/Hive/Configuration+Properties)

### 5.5 Manage Speculative Execution by Scenario

**Impact: MEDIUM (rescues slow nodes; wastes resources on skew/external writes)**

Enable on homogeneous clusters without skew; disable on data skew or external-table writes (speculative copies are equally slow / duplicate writes).

```sql
SET mapreduce.map.speculative=false;
SET mapreduce.reduce.speculative=false;
```

Reference: [Configuration Properties](https://cwiki.apache.org/confluence/display/Hive/Configuration+Properties)

### 5.6 Merge Job Output Files

**Impact: HIGH (merge small files at job end, avoid polluting downstream)**

Output file count equals final-stage task count. Enable output merge + DISTRIBUTE BY partition column to control file count.

```sql
SET hive.merge.mapredfiles=true;
SET hive.merge.size.per.task=268435456;
INSERT OVERWRITE TABLE target PARTITION(dt) SELECT ... DISTRIBUTE BY dt;
```

Reference: [Configuration Properties](https://cwiki.apache.org/confluence/display/Hive/Configuration+Properties)

---

## 6. Engine & Advanced Features

**Impact: MEDIUM**

### 6.1 Configure Dynamic Partitions Correctly

**Impact: MEDIUM (misconfiguration creates massive small files or failures)**

Pure dynamic partitions need `nonstrict`; use DISTRIBUTE BY partition column and output merge to control file count; set partition limits to prevent accidental writes.

```sql
SET hive.exec.dynamic.partition=true;
SET hive.exec.dynamic.partition.mode=nonstrict;
SET hive.exec.max.dynamic.partitions.pernode=500;
INSERT OVERWRITE TABLE target PARTITION(dt) SELECT user_id, amount, dt FROM source DISTRIBUTE BY dt;
```

Reference: [Dynamic Partitions](https://cwiki.apache.org/confluence/display/Hive/DynamicPartitions)

### 6.2 Evaluate Tez/Spark When MR Is the Bottleneck

**Impact: MEDIUM (DAG and container reuse avoid repeated disk spills, often several× faster)**

MR spills every job's intermediate results to HDFS and restarts JVMs. Tez/Spark chain stages into one DAG, keeping intermediates in memory/local and reusing containers. Evaluate switching when MR tuning hits its limit.

```sql
SET hive.execution.engine=tez;
SET hive.tez.auto.reducer.parallelism=true;
```

Note: The rest of this document (storage, partitioning, JOIN, skew) applies equally to all three engines — do those first before switching engines.

Reference: [Hive on Tez](https://cwiki.apache.org/confluence/display/Hive/Hive+on+Tez)

---

## References

1. [Apache Hive Wiki](https://cwiki.apache.org/confluence/display/Hive)
2. [Configuration Properties](https://cwiki.apache.org/confluence/display/Hive/Configuration+Properties)
3. [LanguageManual](https://cwiki.apache.org/confluence/display/Hive/LanguageManual)
