---
title: Use Bucket Map Join / SMB Join for large-table JOINs
impact: HIGH
impactDescription: "Join by bucket on bucketed tables, avoid full large-table Shuffle, controlled memory"
tags: [join, bucket-map-join, SMB, sort-merge-bucket]
---

## Use Bucket Map Join / SMB Join for large-table JOINs

**Impact: HIGH**

When both tables are too large for Map Join broadcast, Common Join's full Reduce Shuffle is extremely costly. If both tables are bucketed on the same JOIN column with the same (or multiple) bucket count:

- **Bucket Map Join**: load only the corresponding bucket of the small table into memory, join bucket by bucket — memory drops from "entire table" to "single bucket".
- **SMB (Sort-Merge-Bucket) Join**: if buckets are also sorted on the JOIN column, merge-join is possible without loading any bucket entirely into memory — optimal for large JOIN large.

**Prerequisite:** see `storage-bucketing` — tables must be created with `CLUSTERED BY ... SORTED BY ... INTO N BUCKETS`.

**Bad Example (two large tables, Common Join):**

```sql
-- Two multi-billion-row tables JOIN directly — Reduce Shuffle of all data, slow and OOM-prone
SELECT a.user_id, a.amount, b.score
FROM big_orders a JOIN big_scores b ON a.user_id = b.user_id;
```

**Good Example (SMB Join):**

```sql
-- Prerequisite: both tables CLUSTERED BY(user_id) SORTED BY(user_id) INTO 256 BUCKETS

SET hive.optimize.bucketmapjoin=true;
SET hive.optimize.bucketmapjoin.sortedmerge=true;
SET hive.auto.convert.sortmerge.join=true;
SET hive.auto.convert.sortmerge.join.noconditionaltask=true;
SET hive.input.format=org.apache.hadoop.hive.ql.io.BucketizedHiveInputFormat;

SELECT a.user_id, a.amount, b.score
FROM big_orders a JOIN big_scores b ON a.user_id = b.user_id;
```

**Three JOIN types compared:**

| JOIN Type | Prerequisite | Memory | Reduce | Use |
|-----------|--------------|--------|--------|-----|
| Map Join | One table small | Full small table in memory | None | Large JOIN small |
| Bucket Map Join | Both bucketed on same column | Single bucket in memory | None | Medium-large tables, aligned buckets |
| SMB Join | Same column bucketed, sorted within bucket | Very low (merge) | None | Large JOIN large (optimal) |
| Common Join | None | High | Yes (full Shuffle) | Fallback — avoid when possible |

Reference: [LanguageManual JoinOptimization](https://cwiki.apache.org/confluence/display/Hive/LanguageManual+JoinOptimization)
