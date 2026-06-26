---
title: Handle NULL/default-value JOIN skew
impact: MEDIUM
impactDescription: "Massive NULL join keys all hash to one Reducer; filter or scatter to eliminate long tail"
tags: [skew, null, join, salting]
---

## Handle NULL/default-value JOIN skew

**Impact: MEDIUM**

Large volumes of NULL join keys (or 0, -1, '' placeholder defaults) during JOIN are the most hidden skew source: all NULLs hash to the same Reducer. Even when every real key is evenly distributed, NULLs alone can overwhelm a single Reducer. Since NULLs cannot match in JOIN anyway, filter them early, or replace NULLs with random values to scatter.

**Bad Example (massive NULL join keys flood one Reducer):**

```sql
-- log table has many NULL user_ids (not logged in) — all go to same reducer
SELECT a.*, b.name
FROM logs a LEFT JOIN users b ON a.user_id = b.user_id;
```

**Good Example 1 (INNER JOIN: filter NULLs early):**

```sql
-- NULLs cannot match anyway — filter before JOIN
SELECT a.*, b.name
FROM (SELECT * FROM logs WHERE user_id IS NOT NULL) a
JOIN users b ON a.user_id = b.user_id;
```

**Good Example 2 (LEFT JOIN must preserve NULL rows: salt NULLs with random values):**

```sql
-- Replace NULL with random non-matching negative values, scatter across reducers
SELECT a.col1, a.col2, b.name
FROM logs a
LEFT JOIN users b
  ON CASE WHEN a.user_id IS NULL
          THEN concat('null_', cast(rand()*1000 AS INT))
          ELSE cast(a.user_id AS STRING)
     END = cast(b.user_id AS STRING);
-- NULL rows randomly hashed, won't match users but still returned (LEFT semantics), no longer concentrated
```

**Detect NULL skew:**

```sql
SELECT
    sum(if(user_id IS NULL,1,0)) AS null_cnt,
    count(*) AS total
FROM logs WHERE dt='2026-01-01';
-- high null_cnt ratio = potential skew source
```

Reference: [Skewed Join Optimization](https://cwiki.apache.org/confluence/display/Hive/Skewed+Join+Optimization)
