---
title: Evaluate Tez/Spark when MapReduce is the bottleneck
impact: MEDIUM
impactDescription: "Tez/Spark use DAG and container reuse to avoid repeated disk spills — often several× faster"
tags: [engine, tez, spark, execution-engine]
---

## Evaluate Tez/Spark when MapReduce is the bottleneck

**Impact: MEDIUM**

Hive on MapReduce's fundamental overhead: complex HQL splits into multiple MR jobs, **each job's intermediate results spill to HDFS**, repeatedly reading/writing disk and restarting JVMs. Tez and Spark chain multiple stages into one application via DAG (directed acyclic graph), keeping intermediates in memory/local with container reuse, eliminating much disk spill and startup overhead. When MR tuning hits its limit and queries are still slow, evaluate switching engines — often the highest-impact single step.

**MapReduce (multiple jobs, repeated disk spills):**

```sql
SET hive.execution.engine=mr;
-- Complex multi-JOIN/multi-GROUP BY queries split into multiple MR jobs, intermediates repeatedly spill to HDFS
```

**Switch to Tez (DAG, intermediates don't spill to disk):**

```sql
SET hive.execution.engine=tez;
SET hive.tez.container.size=4096;
SET hive.tez.auto.reducer.parallelism=true;   -- dynamically adjust reducer parallelism at runtime
-- Same query completes in one DAG, eliminating inter-job spills and JVM startup
```

**Switch to Spark:**

```sql
SET hive.execution.engine=spark;
-- Requires Hive on Spark deployment; leverages in-memory compute and RDD caching
```

**Engine comparison:**

| Engine | Intermediate results | Startup overhead | Use |
|--------|---------------------|------------------|-----|
| MapReduce | Spills to HDFS per job | High (JVM per job) | Ultra-large batch, stability priority, legacy environments |
| Tez | DAG, mostly memory/local | Low (container reuse) | Interactive and complex ETL — Hive's preferred upgrade path |
| Spark | Memory + RDD | Low | Existing Spark ecosystem, iterative compute |

**Note:** Switching engines requires the corresponding runtime deployed on the cluster, and memory/parallelism parameters must be re-evaluated. The rest of this skill (storage format, partitioning, JOIN, skew handling) **applies equally to all three engines** — do those first before considering an engine switch.

Reference: [Hive on Tez](https://cwiki.apache.org/confluence/display/Hive/Hive+on+Tez)
