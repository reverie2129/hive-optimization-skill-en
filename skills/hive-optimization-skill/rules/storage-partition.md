---
title: Partition sensibly by query filter dimensions
impact: CRITICAL
impactDescription: "Partition pruning lets Mappers read only relevant partitions, avoiding full-table scan — often 10–100× faster"
tags: [storage, partition, pruning]
---

## Partition sensibly by query filter dimensions

**Impact: CRITICAL**

Partitions split table data into separate HDFS directories by partition column values. When queries include partition filter conditions, Hive reads only relevant partition directories and skips the rest (partition pruning), directly reducing Mapper count and input volume. Most data warehouse tables should be partitioned by time (`dt`/date). Key principle: choose **low-cardinality columns that frequently appear in WHERE** as partition keys; never partition on high-cardinality columns (e.g., `user_id`) — that creates millions of small partitions and overwhelms the NameNode.

**Bad Example (no partition / high-cardinality partition):**

```sql
-- No partition: every query is a full-table scan
CREATE TABLE events (user_id BIGINT, event_type STRING, ts TIMESTAMP)
STORED AS ORC;

-- High-cardinality partition: millions of partition directories, metadata explosion
CREATE TABLE events (...)
PARTITIONED BY (user_id BIGINT)   -- wrong!
STORED AS ORC;
```

**Good Example (partition on low-cardinality dimensions like date):**

```sql
CREATE TABLE events (
    user_id BIGINT,
    event_type STRING,
    ts TIMESTAMP
)
PARTITIONED BY (dt STRING)         -- daily partition, manageable cardinality
STORED AS ORC;

-- Query with partition filter -> scans only 1 day of data
SELECT count(*) FROM events WHERE dt = '2026-01-01';
```

**Partition design guidelines:**

| Guideline | Explanation |
|-----------|-------------|
| Low cardinality | Keep total partition count in the thousands to tens of thousands |
| High-frequency filter | Choose the dimension most common in WHERE (usually `dt`) |
| Secondary partitions with care | `dt + hour` multi-level partitions multiply partition count |
| Avoid high cardinality | Never use `user_id`, order IDs, etc. as partition keys |
| Data volume | Each partition should be reasonably sized (e.g., ≥128MB); too small creates small files |

**Check partition health:**

```sql
SHOW PARTITIONS events;                 -- view partition count
SELECT dt, count(*) FROM events GROUP BY dt ORDER BY dt;  -- view partition data distribution
```

Reference: [LanguageManual DDL - Partitioned Tables](https://cwiki.apache.org/confluence/display/Hive/LanguageManual+DDL#LanguageManualDDL-PartitionedTables)
