---
title: Avoid SELECT *, select only necessary columns
impact: HIGH
tags: [query, column-pruning, projection]
---

# Avoid SELECT *, select only necessary columns

## Overview

With columnar storage, reading only the columns referenced by the query greatly reduces I/O. `SELECT *` reads all columns, wasting I/O and memory — the impact is especially significant for wide tables (dozens to hundreds of columns). Column pruning is an automatic Hive optimization, but the way you write queries still matters.

## Bad Example

```sql
-- Anti-pattern: read all columns, wide table wastes a lot of I/O
SELECT * FROM events WHERE dt='2026-01-01';
```

## Good Example

```sql
-- Best practice: select only the needed columns
SELECT user_id, ts FROM events WHERE dt='2026-01-01';
```

## Notes

**About column pruning:**

- Hive enables column pruning by default (the `ColumnPruner` optimizer), automatically reading only referenced columns
- But `SELECT *` explicitly requests all columns, so the optimizer cannot prune
- Works best combined with columnar storage (ORC/Parquet)

**Verify column pruning:**

```sql
-- EXPLAIN to inspect the TableScan's Output (should contain only referenced columns, not all columns)
EXPLAIN
SELECT user_id, ts FROM events WHERE dt = '2026-01-01';
```

> Official docs: [Configuration Properties - hive.optimize](https://cwiki.apache.org/confluence/display/Hive/Configuration+Properties)
