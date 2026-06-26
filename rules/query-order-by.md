---
title: Use ORDER BY with caution; use SORT/DISTRIBUTE BY as needed
impact: MEDIUM
tags: [query, order-by, sort-by]
---

# Use ORDER BY with caution; use SORT/DISTRIBUTE BY as needed

## Overview

In Hive, `ORDER BY` requires **global ordering** and funnels all data into a **single Reducer**, which is a fatal bottleneck at large data volumes. Most scenarios can use `SORT BY` (ordered within a partition) or `DISTRIBUTE BY + SORT BY` instead.

## Bad Example

```sql
-- Anti-pattern: global sort, single Reducer processes all data
SELECT * FROM orders ORDER BY amount DESC;
```

## Good Example

```sql
-- Best practice 1: use SORT BY when only intra-partition ordering is needed
SELECT * FROM orders SORT BY amount DESC;

-- Best practice 2: distribute by key, then sort
SELECT * FROM orders DISTRIBUTE BY user_id SORT BY user_id, amount DESC;

-- Best practice 3: when a global TopN is truly needed, do local then global
SELECT * FROM (
    SELECT * FROM orders SORT BY amount DESC LIMIT 100
) t ORDER BY amount DESC LIMIT 100;
```

## Notes

**Difference between the three:**

| Clause | Effect | Reducer |
|------|------|---------|
| ORDER BY | Global ordering | Single |
| SORT BY | Ordered within each Reducer | Multiple |
| DISTRIBUTE BY | Distribute to Reducers by column | Multiple |
| CLUSTER BY | =DISTRIBUTE BY+SORT BY (same column) | Multiple |

**Global TopN optimization:** do a local TopN in each Reducer first, then aggregate into a global TopN, avoiding a full single-Reducer sort.

> Official docs: [LanguageManual SortBy](https://cwiki.apache.org/confluence/display/Hive/LanguageManual+SortBy)
