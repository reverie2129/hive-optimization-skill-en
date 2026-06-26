---
title: Arrange JOIN order sensibly — filter first, largest table last
impact: MEDIUM
impactDescription: "Correct JOIN order and early filtering reduce intermediate results and Shuffle volume"
tags: [join, join-order, filter, intermediate]
---

## Arrange JOIN order sensibly — filter first, largest table last

**Impact: MEDIUM**

In multi-table JOINs, intermediate result size depends on JOIN order. Two rules of thumb: (1) **filter early** — use WHERE/subqueries to shrink each table before JOIN; (2) **largest table last** — Hive's Common Join caches tables on the left and streams the last table, so putting the largest table last in the JOIN sequence reduces cached data in memory. With CBO enabled, the optimizer auto-selects JOIN order (see `query-cbo-stats`), but explicit filtering is still necessary.

**Bad Example (join first, filter later; large table first):**

```sql
-- JOIN full tables then filter — huge intermediate result
SELECT f.order_id, u.name, p.title
FROM fact_orders f                 -- largest table first
JOIN dim_user u ON f.user_id = u.user_id
JOIN dim_product p ON f.product_id = p.product_id
WHERE f.dt = '2026-01-01' AND u.country = 'CN';
```

**Good Example (filter first, largest table last):**

```sql
-- Shrink each table first, then join; fact table last for streaming
SELECT f.order_id, u.name, p.title
FROM (SELECT user_id, name FROM dim_user WHERE country='CN') u
JOIN (SELECT product_id, title FROM dim_product) p
JOIN (SELECT order_id, user_id, product_id FROM fact_orders WHERE dt='2026-01-01') f
  ON f.user_id = u.user_id AND f.product_id = p.product_id;
```

**Key points:**

| Point | Explanation |
|-------|-------------|
| Early filtering | Partition filters and column pruning in subqueries first |
| Largest table last | Common Join caches earlier tables, streams the last |
| Enable CBO | Let optimizer reorder JOINs based on stats (`hive.cbo.enable=true`) |
| STREAMTABLE hint | `/*+ STREAMTABLE(f) */` explicitly designates the streaming table |
| Same-key consecutive JOINs | Multi-table JOINs on the same key merge into one MR job |

Reference: [LanguageManual Joins](https://cwiki.apache.org/confluence/display/Hive/LanguageManual+Joins)
