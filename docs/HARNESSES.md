# Agent Harness Reference

This skill follows the [Agent Skills specification](https://agentskills.io/specification). Source of truth: `skill/hive-optimization-skill/`. Run `./scripts/build.sh` to generate per-provider layouts under `dist/`.

## Provider Matrix

| Provider | Project path | Global path | Invoke | Notes |
|----------|--------------|-------------|--------|-------|
| **Cursor** | `.cursor/skills/hive-optimization-skill/` | `~/.cursor/skills/hive-optimization-skill/` | `/hive-optimization-skill` | Enable Agent Skills in Settings → Rules. Marketplace: `.cursor-plugin/plugin.json` |
| **Claude Code** | `.claude/skills/hive-optimization-skill/` | `~/.claude/skills/hive-optimization-skill/` | `/hive-optimization-skill` | `user-invocable: true` in frontmatter |
| **Codex CLI** | `.agents/skills/hive-optimization-skill/` | `~/.agents/skills/hive-optimization-skill/` | `$hive-optimization-skill` or `/skills` | OpenAI Codex skill discovery |
| **Gemini CLI** | `.gemini/skills/hive-optimization-skill/` | `~/.gemini/skills/hive-optimization-skill/` | `/skills` | Requires Gemini CLI preview + Skills enabled |
| **GitHub Copilot** | `.github/skills/hive-optimization-skill/` | — | agent decides | Project-scoped only |
| **OpenCode** | `.opencode/skills/hive-optimization-skill/` | `~/.config/opencode/skills/hive-optimization-skill/` | varies | See [OpenCode skills docs](https://opencode.ai/docs/skills/) |

## Frontmatter (all providers)

```yaml
---
name: hive-optimization-skill          # required, kebab-case
description: ...                       # required, third-person, includes WHEN
license: Apache-2.0                    # optional
compatibility: Apache Hive 2.x / 3.x   # optional
user-invocable: true                   # Cursor, Claude Code, Gemini
argument-hint: "[hql|table-design|...]" # optional autocomplete hint
metadata:                              # optional arbitrary keys
  author: reverie2129
  version: "0.1.0"
---
```

## Build & Install

```bash
./scripts/build.sh                    # generate dist/{cursor,claude,codex,...}
./scripts/install.sh --global         # auto-detect harnesses, install globally
./scripts/install.sh --project cursor # project-local Cursor only
./scripts/install.sh all              # all supported providers
```

## Manual copy (no build)

After `./scripts/build.sh`:

```bash
cp -r dist/cursor/.cursor your-project/
cp -r dist/claude/.claude your-project/
cp -r dist/codex/.agents your-project/
```

## Compared to Impeccable

[Impeccable](https://github.com/pbakaus/impeccable) uses a Node/Bun factory with per-provider placeholder transforms (`{{model}}`, `{{command_prefix}}`). This Hive skill is **static Markdown only** — the same content works across agents; only install paths differ. No hooks or scripts required.

## Adding a provider

1. Add a `copy_skill` target in `scripts/build.sh`
2. Add an `install_provider` case in `scripts/install.sh`
3. Document the path in this file
