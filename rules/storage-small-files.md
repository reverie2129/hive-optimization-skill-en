---
title: Avoid small file problems
impact: HIGH
impactDescription: "Small files explode Mapper count and job startup overhead, overwhelming NameNode"
tags: [storage, small-files, merge, mapper]
---

## Avoid small file problems

**Impact: HIGH**

On HDFS, each file consumes at least one Map split. Too many small files cause: Mapper count explosion (one Mapper per file — startup/scheduling overhead exceeds actual compute), NameNode memory pressure (~150 bytes metadata per file), and slow downstream reads. Small files commonly arise from dynamic partition writes, too many reducers, and frequent append INSERTs. Control on the write side and merge on the read side.

**Bad Example (produces many small files):**

```sql
-- Dynamic partition + many reducers — each partition × each reducer = one small file
SET mapreduce.job.reduces=500;
INSERT OVERWRITE TABLE target PARTITION(dt)
SELECT user_id, event_type, dt FROM source;   -- may produce partitions × 500 small files
```

**Good Example (output merge + combined input):**

```sql
-- 1) Auto-merge output small files after job completion
SET hive.merge.mapfiles=true;          -- merge map-only job output
SET hive.merge.mapredfiles=true;       -- merge map-reduce job output
SET hive.merge.size.per.task=268435456;        -- merge target 256MB
SET hive.merge.smallfiles.avgsize=134217728;    -- trigger when average <128MB

-- 2) Read side: CombineHiveInputFormat merges multiple small files per Mapper
SET hive.input.format=org.apache.hadoop.hive.ql.io.CombineHiveInputFormat;
SET mapreduce.input.fileinputformat.split.maxsize=268435456;

INSERT OVERWRITE TABLE target PARTITION(dt)
SELECT user_id, event_type, dt FROM source;
```

**Remediation approaches:**

| Scenario | Approach |
|----------|----------|
| Merge on write | `hive.merge.*` parameter family |
| Merge on read | `CombineHiveInputFormat` |
| Existing small-file tables | `INSERT OVERWRITE ... SELECT` rewrite (with controlled reducer count) |
| Dynamic partitions | `DISTRIBUTE BY dt` so same-partition data goes to same reducer, fewer files |
| Concurrent INSERT | Periodic `ALTER TABLE ... CONCATENATE` (ORC) to merge |

```sql
-- Merge ORC table files by partition
ALTER TABLE events PARTITION (dt='2026-01-01') CONCATENATE;
```

Reference: [Hive Configuration - merge](https://cwiki.apache.org/confluence/display/Hive/Configuration+Properties)
