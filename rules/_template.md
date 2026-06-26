---
title: Rule Title
impact: CRITICAL | HIGH | MEDIUM | LOW
impactDescription: "Quantified benefit (e.g., JOIN stage drops from hours to minutes)"
tags: [tag1, tag2]
---

## Rule Title

**Impact: CRITICAL** (optional one-line summary)

Brief explanation of what this rule covers and why it matters, focusing on MapReduce job performance (Mapper/Reducer count, Shuffle data volume, extra MR stages, data skew).

**Bad Example (what goes wrong):**

```sql
-- Bad: description
SELECT * FROM huge_table;
```

**Good Example (the improvement):**

```sql
-- Good: description
SET hive.some.param = true;
SELECT col1, col2 FROM huge_table WHERE dt = '2026-01-01';
```

Reference: [Apache Hive Official Documentation](https://cwiki.apache.org/confluence/display/Hive/...)
