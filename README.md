# Hive Optimization Skill · Hive on MapReduce Best Practices (English)

> An Agent Skill for optimizing **Hive on MapReduce** jobs: **26 citable rules across 6 categories**. Follows the [Agent Skills spec](https://agentskills.io/specification) and ships builds for **Cursor, Claude Code, Codex, Gemini CLI, GitHub Copilot, and OpenCode** — same pattern as [Impeccable](https://github.com/pbakaus/impeccable).

![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)
![Hive](https://img.shields.io/badge/Hive-2.x%20%7C%203.x-yellow.svg)
![Engine](https://img.shields.io/badge/engine-MapReduce-orange.svg)

**Chinese version:** [hive-optimization-skill](https://github.com/reverie2129/hive-optimization-skill)

## Quick Start

```bash
git clone https://github.com/reverie2129/hive-optimization-skill-en.git
cd hive-optimization-skill-en
./scripts/build.sh
./scripts/install.sh --global          # auto-detect Cursor / Claude / etc.
```

Reload your agent, then ask: *"Why is this Hive job stuck at 99%?"* or invoke `/hive-optimization-skill` where supported.

## Architecture

```
skill/hive-optimization-skill/     # Source of truth (edit here)
  SKILL.md
  rules/                           # 26 atomic rules
scripts/build.sh                   # -> dist/{cursor,claude,codex,...}
scripts/install.sh                 # copy dist into harness folders
AGENTS.md                          # One-page rule compilation (humans + agents)
```

Provider paths and frontmatter details: [docs/HARNESSES.md](./docs/HARNESSES.md).

## Installation by Agent

### Option 1: Install script (recommended)

```bash
./scripts/build.sh
./scripts/install.sh --global cursor claude    # pick providers
./scripts/install.sh --project all             # current repo, all providers
```

### Option 2: Copy from `dist/` (after build)

**Cursor**

```bash
cp -r dist/cursor/.cursor ~/.cursor/           # global (merge skills/)
# or
cp -r dist/cursor/.cursor your-project/        # project-local
```

Enable Agent Skills in Cursor Settings → Rules. Marketplace: submit repo at [cursor.com/marketplace/publish](https://cursor.com/marketplace/publish) (includes `.cursor-plugin/plugin.json`).

**Claude Code**

```bash
cp -r dist/claude/.claude/skills/hive-optimization-skill ~/.claude/skills/
```

**Codex CLI**

```bash
cp -r dist/codex/.agents/skills/hive-optimization-skill ~/.agents/skills/
```

**Gemini CLI**

```bash
cp -r dist/gemini/.gemini/skills/hive-optimization-skill ~/.gemini/skills/
```

Requires preview Gemini CLI with Skills enabled (`/settings`).

**GitHub Copilot**

```bash
cp -r dist/copilot/.github your-project/
```

**OpenCode**

```bash
cp -r dist/opencode/.opencode/skills/hive-optimization-skill ~/.config/opencode/skills/
```

### Option 3: Git submodule (teams)

```bash
git submodule add https://github.com/reverie2129/hive-optimization-skill-en.git .hive-optimization-skill
cd .hive-optimization-skill && ./scripts/build.sh && ./scripts/install.sh --project cursor
```

## Rules Overview

| Prefix | Count | Coverage |
|------|------|----------|
| `storage-*` | 5 | ORC/Parquet, compression, partitioning, bucketing, small files |
| `query-*` | 7 | Partition pruning, column pruning, PPD, CBO, vectorization, count distinct, sorting |
| `join-*` | 4 | Map Join, Bucket/SMB Join, JOIN order, JOIN skew |
| `skew-*` | 2 | GROUP BY skew, NULL join-key skew |
| `mr-*` | 6 | Mapper/Reducer, map agg, parallel, speculative, output merge |
| `engine-*` | 2 | Dynamic partitions, Tez/Spark evaluation |

## Trigger Scenarios

- `CREATE TABLE` / `ALTER TABLE` design
- Slow or stage-stuck HQL; job at 99% / Reduce long tail
- JOIN optimization, data skew, small files
- `GROUP BY` / `COUNT(DISTINCT)` / `ORDER BY` issues
- Dynamic partition writes; switching execution engine

## Scope

- **Engine:** Hive on MapReduce (rules largely apply to Tez/Spark)
- **Version:** Apache Hive 2.x / 3.x

## Contributing

Edit files under `skill/hive-optimization-skill/`, run `./scripts/build.sh`, verify install. New rules: follow `skill/hive-optimization-skill/rules/_template.md`. Keep [hive-optimization-skill](https://github.com/reverie2129/hive-optimization-skill) (Chinese) in sync when possible.

## License

[Apache-2.0](./LICENSE)
