---
title: Bucket on JOIN/aggregation keys to support map-side JOIN and sampling
impact: HIGH
impactDescription: "Bucketed tables enable Bucket Map Join / SMB Join, eliminating Reduce-side Shuffle"
tags: [storage, bucketing, CLUSTERED BY, SMB]
---

## Bucket on JOIN/aggregation keys to support map-side JOIN and sampling

**Impact: HIGH**

Bucketing (CLUSTERED BY) further splits data within a partition into a fixed number of files (buckets) by column hash. Identical keys land in the same bucket number. Three benefits: (1) two tables bucketed on the same column with the same bucket count can do **Bucket Map Join / SMB (Sort-Merge-Bucket) Join** without full Reduce Shuffle; (2) efficient TABLESAMPLE sampling; (3) bucketing + sorting makes aggregation more efficient. Complements partitioning: partitions for pruning, buckets for even distribution and JOIN key alignment.

**Bad Example (large-table JOIN without bucketing):**

```sql
-- Two large tables JOIN — only Common Join possible, full Reduce Shuffle
CREATE TABLE orders (order_id BIGINT, user_id BIGINT, amount DECIMAL(10,2))
STORED AS ORC;

CREATE TABLE users (user_id BIGINT, name STRING)
STORED AS ORC;
```

**Good Example (bucket and sort on JOIN key):**

```sql
-- Both tables bucketed on same column, same bucket count, sorted on JOIN key
CREATE TABLE orders (order_id BIGINT, user_id BIGINT, amount DECIMAL(10,2))
CLUSTERED BY (user_id) SORTED BY (user_id) INTO 256 BUCKETS
STORED AS ORC;

CREATE TABLE users (user_id BIGINT, name STRING)
CLUSTERED BY (user_id) SORTED BY (user_id) INTO 256 BUCKETS
STORED AS ORC;

-- Enable SMB Join — merge by bucket on Map side, no Reduce Shuffle
SET hive.optimize.bucketmapjoin=true;
SET hive.optimize.bucketmapjoin.sortedmerge=true;
SET hive.auto.convert.sortmerge.join=true;

SELECT o.order_id, u.name
FROM orders o JOIN users u ON o.user_id = u.user_id;
```

**Bucketing essentials:**

| Point | Explanation |
|-------|-------------|
| Bucket count alignment | Bucket Map Join requires equal bucket counts or integer multiples |
| Write switch | Older versions need `SET hive.enforce.bucketing=true` (default in 2.x+) |
| Bucket count choice | Target moderate data per bucket (e.g., hundreds of MB); usually powers of 2 |
| SORTED BY | SMB Join additionally requires sorting on JOIN key |

Reference: [LanguageManual DDL - Bucketed Tables](https://cwiki.apache.org/confluence/display/Hive/LanguageManual+DDL+BucketedTables)
