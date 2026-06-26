---
name: hive-optimization-skill
description: Use when reviewing or optimizing Hive on MapReduce jobs (table design, HQL queries, JOINs, data skew, parameter tuning). Contains 26 rules — always check relevant rules before giving advice and cite specific rule names in your response.
license: Apache-2.0
metadata:
  author: reverie2129
  version: "0.1.0"
---

# Hive Best Practices (MapReduce Job Optimization)

An optimization guide for Hive on MapReduce, covering storage & table design, query optimization, JOIN optimization, data skew, MapReduce parameter tuning, and engine selection. Six categories, 26 rules, ordered by impact on job performance.

> **Official docs:** [Apache Hive Wiki](https://cwiki.apache.org/confluence/display/Hive)

## Important: How to Apply This Skill

**Before answering any Hive optimization question, follow this priority:**

1. **Check whether a rule in `rules/` applies**
2. **If a rule applies:** apply it and cite it in your response as "Per `rule-name`…"
3. **If no rule applies:** use general Hive knowledge or consult official documentation
4. **If uncertain:** search for best practices for the current version
5. **Always cite the source:** rule name, "general Hive guidance", or a documentation URL

**Why rules come first:** Hive on MapReduce has a specific execution model (every MR job spills intermediate results to HDFS, shuffle cost, single-Reducer bottlenecks, data-skew long tails). General database intuition often fails. Rules encode Hive/MR-specific, validated experience.

---

## Review Workflow

### Table Design Review (CREATE TABLE)

**Read these rule files in order:**

1. `rules/storage-file-format.md` — use ORC/Parquet columnar storage
2. `rules/storage-compression.md` — enable compression
3. `rules/storage-partition.md` — partition by query filter dimensions (low cardinality)
4. `rules/storage-bucketing.md` — bucket on JOIN keys
5. `rules/storage-small-files.md` — avoid small files

**Checklist:**
- [ ] Storage format is ORC/Parquet (not TextFile)
- [ ] Compression configured (storage / intermediate / output)
- [ ] Partitioned on low-cardinality, high-frequency filter columns (usually `dt`); no high-cardinality partition keys
- [ ] Large-table JOIN scenarios bucketed and sorted on JOIN keys
- [ ] Write strategy in place to avoid small files

### Query Review (SELECT / Aggregation)

**Read these rule files:**

1. `rules/query-partition-pruning.md` — hit partition pruning
2. `rules/query-column-pruning.md` — avoid SELECT *
3. `rules/query-predicate-pushdown.md` — predicate pushdown
4. `rules/query-cbo-stats.md` — enable CBO + statistics
5. `rules/query-vectorization.md` — vectorized execution
6. `rules/query-count-distinct.md` — rewrite count(distinct)
7. `rules/query-order-by.md` — ORDER BY / SORT BY choice

**Checklist:**
- [ ] WHERE hits partition pruning (no functions on partition columns)
- [ ] Only necessary columns selected; no `SELECT *`
- [ ] Predicates pushable (PPD on; outer-join filters in ON)
- [ ] CBO enabled and tables have statistics
- [ ] Vectorization enabled for ORC tables
- [ ] No single-Reducer bottlenecks (count distinct / ORDER BY rewritten)

### JOIN Review

**Read these rule files:**

1. `rules/join-map-join.md` — Map Join for small tables
2. `rules/join-bucket-smb.md` — Bucket Map Join / SMB Join for large tables
3. `rules/join-order.md` — JOIN order and early filtering
4. `rules/join-skew.md` — JOIN data skew
5. `rules/skew-null.md` — NULL join-key skew

**Checklist:**
- [ ] Large JOIN small uses Map Join (`hive.auto.convert.join=true`)
- [ ] Large JOIN large uses bucketing + SMB Join
- [ ] Filter before join; largest table last in JOIN sequence
- [ ] Hot keys and NULL join-key skew handled

### Data Skew Review

**Read these rule files:**

1. `rules/skew-groupby.md` — GROUP BY skew
2. `rules/join-skew.md` — JOIN skew
3. `rules/skew-null.md` — NULL skew

**Checklist:**
- [ ] GROUP BY skew: map-side aggregation on; `groupby.skewindata` when needed
- [ ] JOIN hot keys handled via skew join or salting
- [ ] NULL/default join keys filtered or scattered

### Parameter Tuning Review

**Read these rule files:**

1. `rules/mr-mapper-count.md` — Mapper count (split size)
2. `rules/mr-reducer-count.md` — Reducer count
3. `rules/mr-map-aggr.md` — map-side aggregation
4. `rules/mr-parallel.md` — parallel execution
5. `rules/mr-speculative.md` — speculative execution
6. `rules/mr-merge-output.md` — output merging

**Checklist:**
- [ ] Reasonable Mapper count (CombineHiveInputFormat for small files)
- [ ] Reducers auto-estimated via `bytes.per.reducer`, not blindly hard-coded
- [ ] Map-side aggregation enabled
- [ ] Independent stages run in parallel
- [ ] Speculative execution correctly toggled for skew / external-table writes
- [ ] Output small files merged

---

## Output Format

Organize responses as follows:

```
## Rules Checked
- `rule-name-1` - compliant / violation found
- `rule-name-2` - compliant / violation found
...

## Findings

### Violations
- **`rule-name`**: problem description
  - Current: [current HQL/table design]
  - Required: [what should be done]
  - Fix: [concrete change with SQL/parameters]

### Compliant
- `rule-name`: brief explanation of why it's correct

## Recommendations
[Prioritized change list, citing rule names]
```

---

## Rule Categories and Priority

| Priority | Category | Impact | Prefix | Count |
|----------|----------|--------|--------|-------|
| 1 | Storage format | CRITICAL | `storage-file-` | 1 |
| 2 | Partition design | CRITICAL | `storage-partition` | 1 |
| 3 | Partition pruning | CRITICAL | `query-partition-` | 1 |
| 4 | Map JOIN | CRITICAL | `join-map-` | 1 |
| 5 | JOIN skew | CRITICAL | `join-skew` | 1 |
| 6 | Compression / bucketing / small files | HIGH | `storage-` | 3 |
| 7 | Column pruning / PPD / CBO / vectorization | HIGH | `query-` | 4 |
| 8 | SMB JOIN | HIGH | `join-bucket-` | 1 |
| 9 | GROUP BY skew | HIGH | `skew-groupby` | 1 |
| 10 | Mapper / Reducer / map agg / output merge | HIGH | `mr-` | 4 |
| 11 | count distinct / sorting / JOIN order | MEDIUM | various | 3 |
| 12 | NULL skew / parallel / speculative | MEDIUM | various | 3 |
| 13 | Dynamic partition / engine choice | MEDIUM | `engine-` | 2 |

---

## Quick Reference

### Storage & Table Design (storage)

- `storage-file-format` — ORC/Parquet columnar storage; no TextFile for large tables **[CRITICAL]**
- `storage-partition` — partition on low-cardinality high-frequency filter columns; no high-cardinality keys **[CRITICAL]**
- `storage-compression` — enable storage / intermediate / output compression (Snappy default)
- `storage-bucketing` — bucket on JOIN keys to support Bucket Map / SMB Join
- `storage-small-files` — write-side merge + read-side CombineHiveInputFormat

### Query Optimization (query)

- `query-partition-pruning` — WHERE hits partition pruning; no functions on partition columns **[CRITICAL]**
- `query-column-pruning` — select only necessary columns; avoid `SELECT *`
- `query-predicate-pushdown` — predicate pushdown; outer-join filters in ON
- `query-cbo-stats` — enable CBO and ANALYZE statistics
- `query-vectorization` — vectorized execution for ORC tables
- `query-count-distinct` — two-stage rewrite to avoid single Reducer
- `query-order-by` — use ORDER BY sparingly; SORT/DISTRIBUTE/CLUSTER BY as needed

### JOIN Optimization (join)

- `join-map-join` — broadcast small tables as Map Join; skip Reduce **[CRITICAL]**
- `join-skew` — handle hot-key skew (skew join / salting) **[CRITICAL]**
- `join-bucket-smb` — Bucket Map / SMB Join for large JOIN large
- `join-order` — filter first, join later; largest table last

### Data Skew (skew)

- `skew-groupby` — map-side aggregation + `groupby.skewindata` two-stage
- `skew-null` — filter or salt NULL/default join keys

### MapReduce Parameters (mr)

- `mr-mapper-count` — control Mapper count via split size and CombineHiveInputFormat
- `mr-reducer-count` — auto-estimate Reducers via `bytes.per.reducer`
- `mr-map-aggr` — enable map-side aggregation to reduce Shuffle
- `mr-merge-output` — merge output small files at job end
- `mr-parallel` — parallel execution of independent stages
- `mr-speculative` — manage speculative execution for skew / external-table scenarios

### Engine & Advanced (engine)

- `engine-dynamic-partition` — correct dynamic-partition config + DISTRIBUTE BY to control file count
- `engine-consider-tez` — evaluate Tez/Spark when MR is the bottleneck

---

## When to Trigger This Skill

Enable when you encounter:

- `CREATE TABLE` / `ALTER TABLE` statements
- Slow, long-running, or stage-stuck HQL queries
- JOIN optimization (large-table joins, broadcast, bucketing)
- "Job stuck at 99%" / Reduce long tail / data skew
- Too many small files, abnormal Mapper/Reducer counts
- GROUP BY / COUNT(DISTINCT) / ORDER BY performance issues
- Dynamic-partition writes, ETL scheduling optimization
- Considering switching away from MapReduce

---

## Rule File Structure

Each rule file in `rules/` contains:

- **YAML frontmatter**: title, impact level, tags
- **Brief explanation**: why it matters (impact on MR jobs)
- **Bad example**: anti-pattern and why it's slow
- **Good example**: best practice with parameters/SQL
- **Supplement**: comparison tables, scenarios, official doc links

---

## Full Compilation

For a one-page overview of all rules, read: `AGENTS.md` (all rules inlined — no need to open individual files).
