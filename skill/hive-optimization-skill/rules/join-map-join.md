---
title: Use Map Join for small-table JOINs to eliminate Reduce Shuffle
impact: CRITICAL
impactDescription: "Broadcast small table to Map-side memory, skip Reduce stage — JOIN speedup of several×"
tags: [join, map-join, mapjoin, broadcast]
---

## Use Map Join for small-table JOINs to eliminate Reduce Shuffle

**Impact: CRITICAL**

Regular JOIN (Common Join) completes on the Reduce side, requiring both tables to be fully Shuffled by JOIN key — enormous overhead. When one table is small enough to fit in memory, Map Join loads the small table into each Mapper's in-memory hash table and completes the join on the Map side, **completely skipping the Reduce stage and Shuffle**. This is the most important JOIN optimization. Hive can auto-convert based on statistics.

**Bad Example (small table still uses Common Join):**

```sql
-- Auto Map Join disabled — large fact table and small dim table both Reduce Shuffle
SET hive.auto.convert.join=false;
SELECT f.order_id, d.name
FROM fact_orders f JOIN dim_user d ON f.user_id = d.user_id;
```

**Good Example (automatic Map Join):**

```sql
-- Enable auto-conversion: tables below threshold are broadcast as Map Join
SET hive.auto.convert.join=true;
SET hive.auto.convert.join.noconditionaltask=true;
-- Combined small-table size threshold (default ~10MB; increase per cluster memory)
SET hive.auto.convert.join.noconditionaltask.size=209715200;  -- 200MB

SELECT f.order_id, d.name
FROM fact_orders f JOIN dim_user d ON f.user_id = d.user_id;
-- Optimizer automatically broadcasts dim_user as the small table
```

**Key points:**

| Point | Explanation |
|-------|-------------|
| Auto detection | Relies on statistics — run ANALYZE to collect table sizes first |
| Threshold tuning | Set `noconditionaltask.size` per Mapper available memory; too large causes OOM |
| Large table position | Large table should be the driving table; small table is broadcast |
| Multi-table JOIN | Multiple small tables can broadcast simultaneously if combined size < threshold |
| LEFT/RIGHT | Only the non-preserved side can be broadcast (e.g., LEFT JOIN can only broadcast the right table) |

**Manual hint (older versions or when forcing):**

```sql
SELECT /*+ MAPJOIN(d) */ f.order_id, d.name
FROM fact_orders f JOIN dim_user d ON f.user_id = d.user_id;
```

Reference: [LanguageManual JoinOptimization](https://cwiki.apache.org/confluence/display/Hive/LanguageManual+JoinOptimization)
