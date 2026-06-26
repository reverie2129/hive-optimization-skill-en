---
title: Enable CBO and collect statistics
impact: HIGH
tags: [query, cbo, statistics]
---

# Enable CBO and collect statistics

## Overview

The CBO (Cost-Based Optimizer) relies on table and column statistics to choose the optimal execution plan (JOIN order, JOIN algorithm, etc.). Without statistics, the CBO is useless.

## Bad Example

```sql
-- Anti-pattern: no statistics, optimizer blindly picks the JOIN order
SELECT ...
FROM fact f JOIN dim1 d1 ON ... JOIN dim2 d2 ON ...;
```

## Good Example

```sql
-- Best practice: enable CBO + collect statistics
SET hive.cbo.enable=true;
SET hive.compute.query.using.stats=true;
SET hive.stats.fetch.column.stats=true;
SET hive.stats.fetch.partition.stats=true;

-- Collect table and column statistics
ANALYZE TABLE orders COMPUTE STATISTICS;
ANALYZE TABLE orders COMPUTE STATISTICS FOR COLUMNS;
```

## Notes

**Statistics levels:**

- Table level: row count, file count, total size
- Partition level: row count and size per partition
- Column level: number of distinct values, number of nulls, max/min (key for CBO cardinality estimation)

**Automatic collection:**

```sql
SET hive.stats.autogather=true;  -- automatically collect table-level statistics on INSERT
```

> Official docs: [StatsDev](https://cwiki.apache.org/confluence/display/Hive/StatsDev)
