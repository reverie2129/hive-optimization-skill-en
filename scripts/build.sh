#!/usr/bin/env bash
# Build provider-specific skill layouts from skills/hive-optimization-skill/
# Pattern inspired by https://github.com/pbakaus/impeccable (source -> dist per harness)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$ROOT/skills/hive-optimization-skill"
DIST="$ROOT/dist"

if [[ ! -f "$SOURCE/SKILL.md" ]]; then
  echo "error: missing $SOURCE/SKILL.md" >&2
  exit 1
fi

echo "Building hive-optimization-skill for all providers..."
rm -rf "$DIST"
mkdir -p "$DIST"

copy_skill() {
  local dest="$1"
  mkdir -p "$dest"
  cp "$SOURCE/SKILL.md" "$dest/"
  cp -R "$SOURCE/rules" "$dest/"
}

# Cursor
copy_skill "$DIST/cursor/.cursor/skills/hive-optimization-skill"

# Claude Code
copy_skill "$DIST/claude/.claude/skills/hive-optimization-skill"

# Codex CLI (.agents/skills)
copy_skill "$DIST/codex/.agents/skills/hive-optimization-skill"

# Gemini CLI
copy_skill "$DIST/gemini/.gemini/skills/hive-optimization-skill"

# GitHub Copilot
copy_skill "$DIST/copilot/.github/skills/hive-optimization-skill"

# OpenCode
copy_skill "$DIST/opencode/.opencode/skills/hive-optimization-skill"

# Universal flat copy (for manual symlink / custom harnesses)
copy_skill "$DIST/universal/hive-optimization-skill"

# Plugin bundle (Cursor + Claude marketplace / local plugin test)
# Note: the repo root itself is also a valid Cursor + Claude plugin
# (skills/ + .cursor-plugin/ + .claude-plugin/), so this bundle is a convenience copy.
PLUGIN_ROOT="$DIST/plugin"
mkdir -p "$PLUGIN_ROOT/.cursor-plugin" "$PLUGIN_ROOT/.claude-plugin" "$PLUGIN_ROOT/skills/hive-optimization-skill"
cp "$ROOT/.cursor-plugin/plugin.json" "$PLUGIN_ROOT/.cursor-plugin/"
cp "$ROOT/.claude-plugin/plugin.json" "$PLUGIN_ROOT/.claude-plugin/"
cp "$SOURCE/SKILL.md" "$PLUGIN_ROOT/skills/hive-optimization-skill/"
cp -R "$SOURCE/rules" "$PLUGIN_ROOT/skills/hive-optimization-skill/"

echo "Done. Output:"
find "$DIST" -name 'SKILL.md' | sort | sed "s|$ROOT/||"
