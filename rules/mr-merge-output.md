---
title: Merge job output files
impact: HIGH
impactDescription: "Auto-merge small files at job end, avoid polluting downstream and NameNode"
tags: [mr, merge, output, small-files]
---

## Merge job output files

**Impact: HIGH**

Output file count equals final-stage task count (Map-only jobs: Mapper count; Map-Reduce jobs: Reducer count). With many reducers or dynamic partition writes, many small files appear under each partition, directly polluting downstream queries (downstream Mapper explosion) and burdening NameNode. With output merge enabled, Hive appends a lightweight merge stage at job end to combine small files to target size. This is the write-side implementation of `storage-small-files`.

**Bad Example (no output merge):**

```sql
-- Dynamic partition + many reducers — several small files per partition, no merge
INSERT OVERWRITE TABLE target PARTITION(dt)
SELECT user_id, amount, dt FROM source WHERE dt >= '2026-01-01';
```

**Good Example (enable output merge):**

```sql
SET hive.merge.mapfiles=true;           -- merge map-only job output
SET hive.merge.mapredfiles=true;        -- merge map-reduce job output
SET hive.merge.size.per.task=268435456;         -- merged file target size 256MB
SET hive.merge.smallfiles.avgsize=134217728;    -- trigger when average output <128MB
SET hive.merge.orcfile.stripe.level=true;       -- ORC stripe-level fast merge

INSERT OVERWRITE TABLE target PARTITION(dt)
SELECT user_id, amount, dt FROM source WHERE dt >= '2026-01-01';
```

**Further reduce file count with DISTRIBUTE BY:**

```sql
-- Route same-partition data to same reducer — few files per partition
INSERT OVERWRITE TABLE target PARTITION(dt)
SELECT user_id, amount, dt FROM source WHERE dt >= '2026-01-01'
DISTRIBUTE BY dt;
```

**Parameter reference:**

| Parameter | Purpose |
|-----------|---------|
| `hive.merge.mapfiles` | Merge map-only job output (default true) |
| `hive.merge.mapredfiles` | Merge map-reduce job output (default false — enable manually) |
| `hive.merge.size.per.task` | Merge target size |
| `hive.merge.smallfiles.avgsize` | Average size threshold to trigger merge |

Reference: [Configuration Properties - merge](https://cwiki.apache.org/confluence/display/Hive/Configuration+Properties)
