# Hive Optimization Skill · Hive on MapReduce Best Practices (English)

> An Agent Skill for optimizing **Hive on MapReduce** jobs: covering storage & table design, query optimization, JOIN optimization, data skew remediation, and MapReduce parameter tuning — **26 citable rules across 6 categories**. AI coding assistants (Cursor / Claude Code, etc.) follow it automatically when reviewing or optimizing Hive jobs; human engineers can use it as a direct reference.

![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)
![Hive](https://img.shields.io/badge/Hive-2.x%20%7C%203.x-yellow.svg)
![Engine](https://img.shields.io/badge/engine-MapReduce-orange.svg)

**Chinese version:** [hive-optimization-skill](https://github.com/reverie2129/hive-optimization-skill)

## What is this

Hive on MapReduce has a specific execution model (every MR job spills intermediate results to HDFS, shuffle cost, single-Reducer bottlenecks, long-tail data skew, small files), where general database intuition often fails. This project encodes hard-won optimization experience into a set of **atomic, citable rules with good/bad examples**, so AI assistants have a solid basis for optimizing HQL or designing tables, and give consistent, verifiable advice.

Each rule contains:

- **Impact level** (CRITICAL / HIGH / MEDIUM) and quantified benefit
- **Bad Example** (anti-pattern + why it's slow)
- **Good Example** (best practice + specific `SET` parameters / SQL)
- **Comparison tables + official documentation links**

## Rules Overview

| Prefix | Count | Coverage |
|------|------|----------|
| `storage-*` | 5 | Columnar storage (ORC/Parquet), compression, partitioning, bucketing, small-files remediation |
| `query-*` | 7 | Partition pruning, column pruning, predicate pushdown, CBO, vectorization, count distinct, sorting |
| `join-*` | 4 | Map Join, Bucket Map / SMB Join, JOIN order, JOIN skew |
| `skew-*` | 2 | GROUP BY skew, NULL JOIN-key skew |
| `mr-*` | 6 | Mapper/Reducer count, map-side aggregation, parallelism, speculative execution, output merging |
| `engine-*` | 2 | Dynamic partitioning, execution engine choice (Tez/Spark) |

## Installation & Usage

### As a Cursor / Claude Code Skill

Clone this repo into the corresponding skills directory and it will be auto-discovered (the entry `SKILL.md` is at the repo root):

```bash
# Cursor (project level)
git clone https://github.com/reverie2129/hive-optimization-skill-en.git \
  your-project/.cursor/skills/hive-optimization-skill

# Cursor (user level, globally available)
git clone https://github.com/reverie2129/hive-optimization-skill-en.git \
  ~/.cursor/skills/hive-optimization-skill

# Claude Code (user level)
git clone https://github.com/reverie2129/hive-optimization-skill-en.git \
  ~/.claude/skills/hive-optimization-skill
```

Afterwards, when you ask the AI assistant things like "optimize this HQL", "why is this Hive job slow", or "how do I handle data skew", the skill activates automatically and cites rules under `rules/`.

### As Direct Documentation

- For a quick scan: open [`AGENTS.md`](./AGENTS.md) — all rules inlined on one page.
- To understand the review workflow: open [`SKILL.md`](./SKILL.md).
- For individual rule details: go to the [`rules/`](./rules) directory.

## Trigger Scenarios

- `CREATE TABLE` / `ALTER TABLE` design
- HQL queries that are slow, long-running, or stuck at a stage
- "Job stuck at 99%" / Reduce long tail / data skew
- Large-table JOINs, too many small files, abnormal Mapper/Reducer counts
- `GROUP BY` / `COUNT(DISTINCT)` / `ORDER BY` performance issues
- Dynamic partition writes, ETL scheduling job optimization
- Evaluating switching execution engine away from MapReduce

## Directory Structure

```
hive-optimization-skill-en/
├── SKILL.md            # Skill entry (read by skill system)
├── README.md           # Project description (this file)
├── AGENTS.md           # Full rule compilation
├── LICENSE             # Apache-2.0
└── rules/              # 26 rules + meta files
    ├── _template.md
    ├── _sections.md
    └── *.md            # Individual rules
```

## Scope

- **Engine:** primarily Hive on MapReduce; the general parts also apply to Tez/Spark
- **Version:** Apache Hive 2.x / 3.x
- **Data scale:** medium-to-large offline data warehouses (GB ~ TB tables)

## Contributing

Contributions of rules or cases are welcome. New rules should follow the structure in `rules/_template.md` and be registered in the `SKILL.md` quick reference. Keep the Chinese version in [hive-optimization-skill](https://github.com/reverie2129/hive-optimization-skill) in sync when possible.

## License

[Apache-2.0](./LICENSE). Free for personal and commercial use; retain the copyright and license notice.

---

**Entry points for different readers:**

- **AI / Agent:** read `SKILL.md` and `AGENTS.md`
- **Data engineers:** go straight to categorized rules under `rules/`, or `AGENTS.md` for a one-page overview
- **Maintainers:** extend the rule set per `rules/_template.md`
