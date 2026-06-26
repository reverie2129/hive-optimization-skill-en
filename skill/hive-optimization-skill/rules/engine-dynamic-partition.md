---
title: Configure dynamic partition writes correctly
impact: MEDIUM
impactDescription: "Misconfigured dynamic partitions create massive small files or write failures"
tags: [engine, dynamic-partition, insert]
---

## Configure dynamic partition writes correctly

**Impact: MEDIUM**

Dynamic partitions let `INSERT` auto-create partitions from partition column values in data, without writing partition by partition. Misconfiguration causes two typical problems: (1) default `strict` mode requires at least one static partition — pure dynamic fails; (2) each Reducer produces one file per partition, so partition count × Reducer count explodes into massive small files. Correctly relax limits and use `DISTRIBUTE BY` with output merge to control file count.

**Bad Example (dynamic partition used naively):**

```sql
-- Dynamic partition not configured, or file count uncontrolled — errors / massive small files
INSERT OVERWRITE TABLE target PARTITION(dt)
SELECT user_id, amount, dt FROM source;
```

**Good Example (complete dynamic partition configuration):**

```sql
-- Enable dynamic partitions and allow fully dynamic
SET hive.exec.dynamic.partition=true;
SET hive.exec.dynamic.partition.mode=nonstrict;
-- Partition count upper-limit protection
SET hive.exec.max.dynamic.partitions=2000;
SET hive.exec.max.dynamic.partitions.pernode=500;
-- Control small files: same partition to same reducer + output merge
SET hive.merge.mapredfiles=true;
SET hive.merge.size.per.task=268435456;

INSERT OVERWRITE TABLE target PARTITION(dt)
SELECT user_id, amount, dt
FROM source
DISTRIBUTE BY dt;     -- key: route same dt to same reducer, fewer files
```

**Key points:**

| Point | Explanation |
|-------|-------------|
| `dynamic.partition.mode` | Pure dynamic partitions need `nonstrict` |
| Partition limits | `max.dynamic.partitions(.pernode)` prevent accidental massive partition writes |
| `DISTRIBUTE BY partition column` | Key technique to control files per partition |
| Partition column position | Partition columns in SELECT must be last, matching PARTITION clause order |

Reference: [Dynamic Partitions](https://cwiki.apache.org/confluence/display/Hive/DynamicPartitions)
