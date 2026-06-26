---
title: Enable compression to reduce I/O and Shuffle overhead
impact: HIGH
impactDescription: "Intermediate and output compression can reduce disk and network I/O by 50–70%"
tags: [storage, compression, snappy, shuffle]
---

## Enable compression to reduce I/O and Shuffle overhead

**Impact: HIGH**

MapReduce jobs have three compression points: final output, Map-to-Reduce intermediate results (Shuffle), and table storage itself. The Shuffle stage transfers large volumes over the network — compressing intermediate results significantly reduces network and disk I/O and shortens job time. Choose compression algorithms balancing ratio vs CPU: Snappy/LZO are fast with moderate ratio (intermediate results and hot data); Gzip/Zlib have high ratio but are slow (cold archive data).

**Bad Example (no compression):**

```sql
-- Neither intermediate nor output compressed — Shuffle transfers raw data at full size
INSERT OVERWRITE TABLE result
SELECT user_id, count(*) FROM events GROUP BY user_id;
```

**Good Example (intermediate and output compression):**

```sql
-- Map output (Shuffle intermediate) compression: use a fast codec
SET hive.exec.compress.intermediate=true;
SET mapreduce.map.output.compress=true;
SET mapreduce.map.output.compress.codec=org.apache.hadoop.io.compress.SnappyCodec;

-- Final output compression
SET hive.exec.compress.output=true;
SET mapreduce.output.fileoutputformat.compress=true;
SET mapreduce.output.fileoutputformat.compress.codec=org.apache.hadoop.io.compress.SnappyCodec;

INSERT OVERWRITE TABLE result
SELECT user_id, count(*) FROM events GROUP BY user_id;
```

**Compression algorithm selection:**

| Algorithm | Speed | Ratio | Splittable | Use |
|-----------|-------|-------|------------|-----|
| Snappy | Fast | Medium | No* | Intermediate, hot data (recommended default) |
| LZO | Fast | Medium | Yes (needs index) | Large text files needing splits |
| Gzip/Zlib | Slow | High | No | Cold data, archive |
| Bzip2 | Very slow | Very high | Yes | Rarely used |

*Note: ORC/Parquet compress internally by block; the file as a whole can still be split for parallel processing, so columnar format + Snappy is the most common combination.

Reference: [CompressedStorage](https://cwiki.apache.org/confluence/display/Hive/CompressedStorage)
