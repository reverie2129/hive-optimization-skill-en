---
title: Handle GROUP BY data skew
impact: HIGH
impactDescription: "Skewed group keys concentrate on one Reducer; load-balanced two-stage aggregation eliminates long tail"
tags: [skew, group-by, map-aggr, two-stage]
---

## Handle GROUP BY data skew

**Impact: HIGH**

GROUP BY aggregates by group key on Reduce — identical keys go to the same Reducer. When certain group keys have far more data (e.g., GROUP BY city where one megacity dominates), the corresponding Reducer long-tails. Two approaches: (1) enable **map-side aggregation** (`hive.map.aggr`) for local pre-aggregation on Map, reducing data entering Reduce; (2) enable **skew load balancing** (`hive.groupby.skewindata`) — Hive auto-generates two MR stages: first stage randomly scatters and pre-aggregates, second stage final aggregation.

**Bad Example (skewed group keys overwhelm Reducer):**

```sql
-- If certain cities have extremely large data volume, corresponding reducer long-tails
SELECT city, count(*), sum(amount)
FROM orders WHERE dt='2026-01-01'
GROUP BY city;
```

**Good Example (map-side aggregation + skew load balancing):**

```sql
-- 1) Map-side pre-aggregation, reduce shuffle data
SET hive.map.aggr=true;
SET hive.groupby.mapaggr.checkinterval=100000;
SET hive.map.aggr.hash.min.reduction=0.5;

-- 2) Skew load balancing: auto-split into two MR stages, first stage randomly distributes to scatter hot spots
SET hive.groupby.skewindata=true;

SELECT city, count(*), sum(amount)
FROM orders WHERE dt='2026-01-01'
GROUP BY city;
```

**Two approaches compared:**

| Approach | Mechanism | Use |
|----------|-----------|-----|
| `hive.map.aggr` | Map-side hash pre-aggregation | Almost all GROUP BY — should be on by default |
| `hive.groupby.skewindata` | Two-stage MR, first stage random scatter | Only when severe skew confirmed (adds MR stage; slower without skew) |

**Note:** `hive.groupby.skewindata=true` forces an extra MR stage — enable only when skew is confirmed; keep off otherwise. Also, with this parameter enabled, **multiple distinct on different columns in the same query is unsupported** (error: "DISTINCT on different columns not supported with skew in data") — rewrite per `query-count-distinct` first.

Reference: [Configuration Properties - hive.groupby.skewindata](https://cwiki.apache.org/confluence/display/Hive/Configuration+Properties)
