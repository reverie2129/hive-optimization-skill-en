---
title: Optimize COUNT(DISTINCT) to avoid a single Reducer
impact: MEDIUM
tags: [query, count-distinct, skew]
---

# Optimize COUNT(DISTINCT) to avoid a single Reducer

## Overview

In Hive, `COUNT(DISTINCT)` funnels all data into a **single Reducer** for deduplication, which becomes a severe bottleneck at large data volumes. You can rewrite it with two-stage aggregation (GROUP BY to deduplicate first, then count), leveraging multiple Reducers in parallel.

## Bad Example

```sql
-- Anti-pattern: single-Reducer deduplication, extremely slow at large data volumes
SELECT count(DISTINCT user_id) FROM events WHERE dt='2026-01-01';
```

## Good Example

```sql
-- Best practice: two-stage aggregation, multiple Reducers in parallel
SELECT count(*) FROM (
    SELECT user_id FROM events WHERE dt='2026-01-01' GROUP BY user_id
) t;
```

## Notes

**Auxiliary parameters:**

These two parameters let the optimizer automatically rewrite (count) distinct into multiple stages:

```sql
SET hive.optimize.countdistinct=true;     -- Hive 3.0+, targets count distinct
SET hive.optimize.distinct.rewrite=true;  -- Hive 1.2+, targets general distinct aggregation
```

**Important:** Per the source-code logic, the two automatic rewrites above are **only triggered by the CBO under the Tez execution engine and are not enabled automatically under the MapReduce engine** (an extra MR stage on MR isn't necessarily worthwhile, so Hive doesn't enable it for MR). Therefore, in the Hive on MR scenario, **do not rely on these two parameters; stick with the manual two-stage rewrite above**. If some error is acceptable (e.g. UV estimation), you may also consider approximate deduplication for further speedup.

**Multi-column distinct:**

```sql
-- Avoid multiple count(distinct) at once; use a GROUP BY subquery instead
SELECT
    count(DISTINCT user_id),
    count(DISTINCT product_id)
FROM events;  -- anti-pattern: multiple distincts still go through a single Reducer
```

> Official docs: [LanguageManual - GroupBy](https://cwiki.apache.org/confluence/display/Hive/LanguageManual+GroupBy)
