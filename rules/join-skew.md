---
title: Handle JOIN data skew
impact: CRITICAL
impactDescription: "Hot-key single-Reducer long tail can stall jobs at the last 1%; skew join can speed up several×"
tags: [join, skew, hot-key, reducer]
---

## Handle JOIN data skew

**Impact: CRITICAL**

JOIN skew means certain keys have far more data than others (e.g., one large customer's orders are 30% of the table). In Common Join, identical keys go to the same Reducer — hot keys make one Reducer process far above average, creating a long tail while all other Reducers finish early. Remedies: enable Hive automatic skew join, or manually salt known hot keys.

**Bad Example (skewed keys overwhelm a single Reducer):**

```sql
-- If big_orders has a few hot user_ids (e.g., large customers) with most orders,
-- those keys all go to one reducer, causing severe long tail
SELECT a.user_id, a.amount, b.score
FROM big_orders a JOIN big_user b ON a.user_id = b.user_id;
```

**Good Example 1 (enable automatic skew join):**

```sql
-- Hive auto-detects hot keys exceeding threshold, handles them separately via Map Join
SET hive.optimize.skewjoin=true;
SET hive.skewjoin.key=100000;                  -- keys with more rows than this are considered skewed
SET hive.skewjoin.mapjoin.map.tasks=10000;
SET hive.skewjoin.mapjoin.min.split=33554432;

SELECT a.user_id, a.amount, b.score
FROM big_orders a JOIN big_user b ON a.user_id = b.user_id;
```

**Good Example 2 (declare skew at table creation):**

```sql
-- When hot keys are known, declare skew at CREATE TABLE for storage-layer optimization
CREATE TABLE big_orders (...)
SKEWED BY (user_id) ON (10001, 10002) STORED AS DIRECTORIES;
```

**Good Example 3 (manual salting: add random suffix to large table, expand small table to match):**

```sql
-- Core idea: add random suffix (0~N-1) to skewed table's JOIN key to scatter hot keys across N reducers;
-- expand the other table N-fold (each with suffix 0~N-1) to ensure matches still work.
SELECT a.user_id, a.amount, b.score
FROM (
    -- Large table (skewed side): hot keys scattered across 0~9 (10 copies)
    SELECT user_id, amount,
           concat(cast(user_id AS STRING), '_', cast(floor(rand()*10) AS INT)) AS join_key
    FROM big_orders
) a
JOIN (
    -- Small table: each row expanded 10× with suffixes 0~9
    SELECT user_id, score,
           concat(cast(user_id AS STRING), '_', salt) AS join_key
    FROM big_user
    LATERAL VIEW explode(array(0,1,2,3,4,5,6,7,8,9)) tmp AS salt
) b
ON a.join_key = b.join_key;
-- Hot key data spread across 10 reducers, eliminating single-point long tail
-- Note: to reduce expansion, salt only known hot keys and UNION ALL with normal JOIN for non-hot keys
```

**Detect skew:**

```sql
-- Check key distribution for outliers
SELECT user_id, count(*) c FROM big_orders
GROUP BY user_id ORDER BY c DESC LIMIT 20;
```

Reference: [Skewed Join Optimization](https://cwiki.apache.org/confluence/display/Hive/Skewed+Join+Optimization)
