---
title: Enable map-side aggregation to reduce Shuffle data volume
impact: HIGH
impactDescription: "Map-side pre-aggregation can reduce data entering Reduce by an order of magnitude"
tags: [mr, map-aggr, combiner, group-by]
---

## Enable map-side aggregation to reduce Shuffle data volume

**Impact: HIGH**

For GROUP BY aggregation, by default all raw rows Shuffle to Reduce for aggregation. Enabling map-side aggregation (`hive.map.aggr=true`, similar to MapReduce Combiner) pre-aggregates locally in each Mapper's memory, sending only partial results to Reduce — Shuffle data volume drops sharply, reducing network and Reduce pressure. Enabled by default, but confirm it hasn't been disabled and tune trigger parameters.

**Bad Example (map-side aggregation disabled):**

```sql
-- All raw rows Shuffle to Reduce — high network and Reduce pressure
SET hive.map.aggr=false;
SELECT event_type, count(*) FROM events WHERE dt='2026-01-01' GROUP BY event_type;
```

**Good Example (enable and tune map-side aggregation):**

```sql
SET hive.map.aggr=true;                          -- enable map-side aggregation (default true)
SET hive.groupby.mapaggr.checkinterval=100000;   -- check aggregation effectiveness every N rows
SET hive.map.aggr.hash.min.reduction=0.5;        -- abandon if compression ratio insufficient (avoid useless hash)
SET hive.map.aggr.hash.percentmemory=0.5;        -- Map aggregation hash table memory fraction

SELECT event_type, count(*) FROM events WHERE dt='2026-01-01' GROUP BY event_type;
```

**Applicability and notes:**

| Situation | Explanation |
|-----------|-------------|
| Low group-key cardinality | Maximum benefit (e.g., event_type has only dozens of values) |
| Very high group-key cardinality | Local aggregation compression ratio low — Hive auto-abandons (controlled by min.reduction) |
| Memory | Hash table uses Map memory — on OOM, decrease `hash.percentmemory` |

Reference: [Configuration Properties - hive.map.aggr](https://cwiki.apache.org/confluence/display/Hive/Configuration+Properties)
