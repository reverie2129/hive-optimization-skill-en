---
title: Manage speculative execution by scenario
impact: MEDIUM
impactDescription: "Speculative execution rescues slow-node long tails but may waste resources on skew/external writes"
tags: [mr, speculative-execution, straggler]
---

## Manage speculative execution by scenario

**Impact: MEDIUM**

Speculative Execution means: when a task is significantly slower than peers in the same batch, the framework launches a duplicate on another node and uses whichever finishes first — mitigating "slow node" (straggler) drag. It helps on heterogeneous hardware clusters, but has two downsides: (1) in **data skew**, slowness is due to data volume not node speed — speculative copies are equally slow and waste resources; (2) tasks writing to external storage or with side effects may duplicate writes. Toggle per scenario.

**Default on — suitable for homogeneous clusters without skew:**

```sql
SET mapreduce.map.speculative=true;
SET mapreduce.reduce.speculative=true;
SET hive.mapred.reduce.tasks.speculative.execution=true;
```

**Disable on skew or external-table writes:**

```sql
-- Disable on data skew — avoid launching useless duplicates for "slow due to data volume"
SET mapreduce.map.speculative=false;
SET mapreduce.reduce.speculative=false;
SET hive.mapred.reduce.tasks.speculative.execution=false;
```

**Decision table:**

| Scenario | Speculative execution |
|----------|----------------------|
| Heterogeneous cluster, occasional slow nodes | Enable |
| Known data skew (long tail due to data volume) | Disable (fix skew first — see skew rules) |
| External table / HBase writes with side effects | Disable (avoid duplicate writes) |
| Resource-constrained queue | Disable (speculative copies double resource usage) |

Reference: [Configuration Properties - speculative](https://cwiki.apache.org/confluence/display/Hive/Configuration+Properties)
