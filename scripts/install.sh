#!/usr/bin/env bash
# Install built skill into detected agent harness directories.
# Usage: ./scripts/install.sh [--global|--project] [provider...]
#   providers: cursor claude codex gemini copilot opencode all (default: all detected)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"
SCOPE="global"
PROVIDERS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --global) SCOPE="global"; shift ;;
    --project) SCOPE="project"; shift ;;
    --help|-h)
      sed -n '2,6p' "$0"
      exit 0
      ;;
    *)
      PROVIDERS+=("$1")
      shift
      ;;
  esac
done

if [[ ! -d "$DIST/cursor" ]]; then
  echo "dist/ not found — running build first..."
  "$ROOT/scripts/build.sh"
fi

expand_home() {
  local p="$1"
  echo "${p/#\~/$HOME}"
}

install_provider() {
  local id="$1"
  local src="" dest=""

  case "$id" in
    cursor)
      src="$DIST/cursor/.cursor/skills/hive-optimization-skill"
      if [[ "$SCOPE" == "global" ]]; then
        dest="$(expand_home ~/.cursor/skills/hive-optimization-skill)"
      else
        dest="$PWD/.cursor/skills/hive-optimization-skill"
      fi
      ;;
    claude)
      src="$DIST/claude/.claude/skills/hive-optimization-skill"
      if [[ "$SCOPE" == "global" ]]; then
        dest="$(expand_home ~/.claude/skills/hive-optimization-skill)"
      else
        dest="$PWD/.claude/skills/hive-optimization-skill"
      fi
      ;;
    codex)
      src="$DIST/codex/.agents/skills/hive-optimization-skill"
      if [[ "$SCOPE" == "global" ]]; then
        dest="$(expand_home ~/.agents/skills/hive-optimization-skill)"
      else
        dest="$PWD/.agents/skills/hive-optimization-skill"
      fi
      ;;
    gemini)
      src="$DIST/gemini/.gemini/skills/hive-optimization-skill"
      if [[ "$SCOPE" == "global" ]]; then
        dest="$(expand_home ~/.gemini/skills/hive-optimization-skill)"
      else
        dest="$PWD/.gemini/skills/hive-optimization-skill"
      fi
      ;;
    copilot)
      src="$DIST/copilot/.github/skills/hive-optimization-skill"
      dest="$PWD/.github/skills/hive-optimization-skill"
      ;;
    opencode)
      src="$DIST/opencode/.opencode/skills/hive-optimization-skill"
      if [[ "$SCOPE" == "global" ]]; then
        dest="$(expand_home ~/.config/opencode/skills/hive-optimization-skill)"
      else
        dest="$PWD/.opencode/skills/hive-optimization-skill"
      fi
      ;;
    *)
      echo "unknown provider: $id" >&2
      return 1
      ;;
  esac

  mkdir -p "$(dirname "$dest")"
  rm -rf "$dest"
  cp -R "$src" "$dest"
  echo "installed $id -> $dest"
}

detect_providers() {
  local found=()
  [[ -d "$(expand_home ~/.cursor)" || -d "$PWD/.cursor" ]] && found+=("cursor")
  [[ -d "$(expand_home ~/.claude)" || -d "$PWD/.claude" ]] && found+=("claude")
  [[ -d "$(expand_home ~/.agents)" || -d "$PWD/.agents" ]] && found+=("codex")
  [[ -d "$(expand_home ~/.gemini)" || -d "$PWD/.gemini" ]] && found+=("gemini")
  [[ -d "$PWD/.github" ]] && found+=("copilot")
  [[ -d "$(expand_home ~/.config/opencode)" || -d "$PWD/.opencode" ]] && found+=("opencode")
  if [[ ${#found[@]} -eq 0 ]]; then
    found=(cursor claude)
    echo "no harness detected; defaulting to: ${found[*]}"
  fi
  printf '%s\n' "${found[@]}"
}

if [[ ${#PROVIDERS[@]} -eq 0 ]]; then
  mapfile -t PROVIDERS < <(detect_providers)
elif [[ "${PROVIDERS[0]}" == "all" ]]; then
  PROVIDERS=(cursor claude codex gemini copilot opencode)
fi

echo "scope=$SCOPE providers=${PROVIDERS[*]}"
for p in "${PROVIDERS[@]}"; do
  install_provider "$p"
done

echo "Reload your agent (Cursor: Developer: Reload Window). Invoke with /hive-optimization-skill where supported."
