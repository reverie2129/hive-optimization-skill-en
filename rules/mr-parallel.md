---
title: Run independent MR stages in parallel
impact: MEDIUM
impactDescription: "Independent stages run concurrently, shortening total time for complex queries"
tags: [mr, parallel, stage, exec]
---

## Run independent MR stages in parallel

**Impact: MEDIUM**

Complex HQL is often split into multiple Stages (multiple MR jobs). By default Hive **serially** executes these Stages. Many Stages have no dependencies (e.g., UNION ALL branches, independent subqueries) and can run in parallel. Enabling `hive.exec.parallel` submits independent Stages concurrently, shortening total execution time. Trade-off: uses more cluster resources simultaneously — consider queue capacity.

**Bad Example (serial execution of independent branches):**

```sql
-- Two independent subqueries + UNION ALL — default serial, total time = sum of branches
SELECT 'a' AS src, count(*) c FROM table_a WHERE dt='2026-01-01'
UNION ALL
SELECT 'b' AS src, count(*) c FROM table_b WHERE dt='2026-01-01';
```

**Good Example (enable parallel execution):**

```sql
SET hive.exec.parallel=true;
SET hive.exec.parallel.thread.number=8;   -- max parallel stages

SELECT 'a' AS src, count(*) c FROM table_a WHERE dt='2026-01-01'
UNION ALL
SELECT 'b' AS src, count(*) c FROM table_b WHERE dt='2026-01-01';
-- Both branches' MR jobs submitted in parallel
```

**Notes:**

| Point | Explanation |
|-------|-------------|
| Independent stages only | Stages with dependencies still run sequentially |
| Resource usage | Parallelism requests more containers simultaneously — watch queue limits |
| Thread count | `parallel.thread.number` controls concurrency upper limit — set per cluster capacity |

Reference: [Configuration Properties - hive.exec.parallel](https://cwiki.apache.org/confluence/display/Hive/Configuration+Properties)
