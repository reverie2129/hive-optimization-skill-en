---
title: Use columnar storage (ORC/Parquet) instead of TextFile
impact: CRITICAL
impactDescription: "5–10× less data scanned; with predicate pushdown, skip entire stripes/row groups"
tags: [storage, file-format, ORC, Parquet]
---

## Use columnar storage (ORC/Parquet) instead of TextFile

**Impact: CRITICAL**

TextFile / SequenceFile are row-oriented — querying any column reads the entire row, and predicate pushdown is impossible. ORC and Parquet are columnar formats that read only referenced columns, with built-in lightweight indexes (min/max, bloom filter) to skip non-matching data blocks (stripes / row groups) at the Mapper stage, greatly reducing I/O and Map input. ORC is typically the Hive default choice.

**Bad Example (default TextFile):**

```sql
-- Row storage: SELECT on one column still reads all fields; cannot skip data blocks
CREATE TABLE events (
    user_id BIGINT,
    event_type STRING,
    payload STRING,
    ts TIMESTAMP
)
STORED AS TEXTFILE;
```

**Good Example (ORC + compression):**

```sql
CREATE TABLE events (
    user_id BIGINT,
    event_type STRING,
    payload STRING,
    ts TIMESTAMP
)
STORED AS ORC
TBLPROPERTIES (
    "orc.compress"="SNAPPY",
    "orc.create.index"="true",
    "orc.bloom.filter.columns"="user_id"   -- bloom filter on high-frequency equality filter columns
);
```

**Format selection:**

| Format | Use | Notes |
|--------|-----|-------|
| ORC | Hive default | High compression, built-in index/stats, best predicate pushdown and vectorization |
| Parquet | Cross-engine (Spark/Impala/Presto) | Universal columnar |
| TextFile | External import / debug only | Row-oriented, no index — never for large tables |
| SequenceFile | Legacy | Row-oriented binary |

**Migrating existing TextFile large tables:**

```sql
-- Convert to ORC via INSERT ... SELECT
INSERT OVERWRITE TABLE events_orc SELECT * FROM events_text;
```

Reference: [LanguageManual ORC](https://cwiki.apache.org/confluence/display/Hive/LanguageManual+ORC)
