---
title: Enable vectorized execution
impact: HIGH
tags: [query, vectorization, orc]
---

# Enable vectorized execution

## Overview

Vectorized execution changes processing from one row at a time to **batches of 1024 rows at a time**, greatly reducing function-call and CPU overhead. For scan, filter, and aggregation queries it can speed things up **2~10x**. It requires the table to be in ORC/Parquet format.

## Bad Example

```sql
-- Anti-pattern: vectorization off, row-by-row processing with high CPU overhead
SELECT dt, count(*), sum(amount) FROM orders GROUP BY dt;
```

## Good Example

```sql
-- Best practice: enable vectorized execution
SET hive.vectorized.execution.enabled=true;
SET hive.vectorized.execution.reduce.enabled=true;

SELECT dt, count(*), sum(amount) FROM orders GROUP BY dt;
```

## Notes

**Vectorization requirements and limitations:**

- The table must be in ORC/Parquet columnar format
- Some complex UDFs don't support vectorization and fall back to row-by-row
- Data types must be supported (all mainstream types are)

**Verify it takes effect:**

```sql
EXPLAIN VECTORIZATION
SELECT dt, count(*) FROM orders GROUP BY dt;
-- Check Execution mode: vectorized
```

> Official docs: [Vectorized Query Execution](https://cwiki.apache.org/confluence/display/Hive/Vectorized+Query+Execution)
