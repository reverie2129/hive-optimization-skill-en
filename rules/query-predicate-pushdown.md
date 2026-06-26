---
title: Use predicate pushdown to reduce scanning
impact: HIGH
tags: [query, predicate-pushdown, ppd]
---

# Use predicate pushdown to reduce scanning

## Overview

Predicate Push Down (PPD) pushes filter conditions as close to the data-read layer as possible, and combined with ORC/Parquet row-group indexes skips data blocks to reduce the actual read volume. Hive enables it by default, but certain query patterns block pushdown.

## Bad Example

```sql
-- Anti-pattern: filter placed in the outer layer, subquery computes everything first
SELECT * FROM (
    SELECT user_id, amount, dt FROM orders
) t
WHERE t.dt='2026-01-01';
```

## Good Example

```sql
-- Best practice: keep the filter as close to the data source as possible
SELECT user_id, amount FROM orders WHERE dt='2026-01-01';

-- Confirm PPD is enabled
SET hive.optimize.ppd=true;
SET hive.optimize.ppd.storage=true;
```

## Notes

**The outer-join predicate-pushdown trap:**

```sql
-- In a LEFT JOIN, putting a right-table filter in WHERE turns it into inner-join semantics
-- It should be placed in the ON condition
SELECT a.*, b.score
FROM orders a
LEFT JOIN dim b ON a.user_id=b.user_id AND b.valid=1;
```

**Key parameters:**

- `hive.optimize.ppd=true`: enable predicate pushdown
- `hive.optimize.ppd.storage=true`: push down to the storage layer (ORC/Parquet)

> Official docs: [LanguageManual - PredicatePushdown](https://cwiki.apache.org/confluence/display/Hive/Configuration+Properties)
