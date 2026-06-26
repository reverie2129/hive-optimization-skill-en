---
title: Set Reducer count sensibly
impact: HIGH
impactDescription: "Too few Reducers → bottleneck; too many → small files; set by data volume"
tags: [mr, reducer, bytes-per-reducer]
---

## Set Reducer count sensibly

**Impact: HIGH**

Reducer count directly affects post-Shuffle parallelism and output file count. Too few: a single Reducer becomes a bottleneck processing too much data; too many: each Reducer outputs one file, creating many small files and adding scheduling overhead. Hive defaults to auto-estimation by "bytes per Reducer" — prefer tuning this parameter over hard-coding reducer count.

**Bad Example (hard-coded reducer count or unchecked default):**

```sql
-- Hard-coded too high: massive small files
SET mapreduce.job.reduces=2000;
INSERT OVERWRITE TABLE result SELECT user_id, sum(amount) FROM orders GROUP BY user_id;

-- Hard-coded too low: single reducer processing TB-scale data, long tail
SET mapreduce.job.reduces=1;
```

**Good Example (auto-estimate by bytes per Reducer):**

```sql
-- Let Hive dynamically decide reducer count by data volume (recommended)
SET hive.exec.reducers.bytes.per.reducer=268435456;   -- 256MB per reducer
SET hive.exec.reducers.max=1009;                       -- reducer count upper limit

INSERT OVERWRITE TABLE result
SELECT user_id, sum(amount) FROM orders GROUP BY user_id;
-- reducer count ≈ input data / bytes.per.reducer, auto-adapts to data scale
```

**Tuning guidelines:**

| Symptom | Adjustment |
|---------|------------|
| Reduce stage long tail / slow | Decrease `bytes.per.reducer` (more reducers) |
| Too many output small files | Increase `bytes.per.reducer` (fewer reducers) or enable output merge |
| Force fixed count | `SET mapreduce.job.reduces=N` (only when you know exactly) |

**Note:** `ORDER BY`, global aggregation without GROUP BY, and `COUNT(DISTINCT)` force a single Reducer — tuning is ineffective; rewrite SQL (see `query-order-by`, `query-count-distinct`).

Reference: [Configuration Properties - reducers](https://cwiki.apache.org/confluence/display/Hive/Configuration+Properties)
