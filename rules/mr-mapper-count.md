---
title: Control Mapper count via split size
impact: HIGH
impactDescription: "Too many Mappers → scheduling overhead; too few → insufficient parallelism; sensible splits improve throughput"
tags: [mr, mapper, split, CombineHiveInputFormat]
---

## Control Mapper count via split size

**Impact: HIGH**

Mapper count is determined by input split count, not direct setting. Too many Mappers (often from small files) make scheduling/startup overhead exceed compute itself; too few leave cluster resources idle with insufficient parallelism. Adjust split max/min bytes to indirectly control Mapper count, and use `CombineHiveInputFormat` to merge small files into combined splits.

**Bad Example (Mapper count unchecked):**

```sql
-- Many small files -> one Mapper per file -> tens of thousands of Mappers, huge scheduling overhead
SELECT count(*) FROM events WHERE dt='2026-01-01';
```

**Good Example (tune split size to control Mappers):**

```sql
-- Merge small-file input, slice at 256MB, reduce Mapper count
SET hive.input.format=org.apache.hadoop.hive.ql.io.CombineHiveInputFormat;
SET mapreduce.input.fileinputformat.split.maxsize=268435456;   -- 256MB, larger -> fewer Mappers
SET mapreduce.input.fileinputformat.split.minsize=134217728;   -- 128MB

-- If a single large file needs more parallelism: decrease maxsize -> more Mappers
-- SET mapreduce.input.fileinputformat.split.maxsize=67108864;  -- 64MB

SELECT count(*) FROM events WHERE dt='2026-01-01';
```

**Control logic:**

| Goal | Action |
|------|--------|
| Too many Mappers (small files) | CombineHiveInputFormat + increase split.maxsize |
| Too few Mappers (few large files) | Decrease split.maxsize for more parallelism |
| Estimate | Mapper count ≈ total input bytes / split.maxsize (affected by block size and file count) |

**Note:** Mapper count cannot be forced via `mapreduce.job.maps` (it's only a hint) — must control via split size and input format.

Reference: [Configuration Properties - InputFormat](https://cwiki.apache.org/confluence/display/Hive/Configuration+Properties)
