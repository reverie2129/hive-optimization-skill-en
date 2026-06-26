---
title: Ensure queries hit partition pruning
impact: CRITICAL
tags: [query, partition-pruning, predicate]
---

# Ensure queries hit partition pruning

## Overview

Partition pruning is the lifeline of query performance. Whether the WHERE condition can hit the partition column determines whether you scan 1 partition or the whole table. Wrapping functions around partition columns or implicit type conversion both **disable pruning**, triggering a full-table scan.

## Bad Example

```sql
-- Anti-pattern 1: function on partition column, pruning disabled
SELECT * FROM orders WHERE substr(dt,1,7)='2026-01';

-- Anti-pattern 2: implicit type conversion (dt is string, an int is passed)
SELECT * FROM orders WHERE dt=20260101;
```

## Good Example

```sql
-- Best practice: direct equality/range comparison on the partition column
SELECT * FROM orders WHERE dt='2026-01-01';

-- Range query
SELECT * FROM orders WHERE dt >= '2026-01-01' AND dt <= '2026-01-31';

-- Month filter: use a range instead of a function
SELECT * FROM orders WHERE dt >= '2026-01-01' AND dt < '2026-02-01';
```

## Notes

**Common causes of pruning failure:**

- Using a function on the partition column: `substr(dt,...)`, `date_format(dt,...)`
- Implicit type conversion: partition column type doesn't match the literal
- Mixing partition and non-partition columns in an OR condition

**Verify that pruning takes effect:**

```sql
EXPLAIN DEPENDENCY
SELECT * FROM orders WHERE dt='2026-01-01';
-- Check input partitions to confirm only the target partition is scanned
```

> Official docs: [LanguageManual DDL - PartitionPruning](https://cwiki.apache.org/confluence/display/Hive/LanguageManual+DDL)
