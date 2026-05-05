#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

dry_run=0

usage() {
  cat <<'EOF'
Uninstall user-level humanize-flow files.

Usage:
  ./uninstall.sh [--dry-run]

Removes:
  ~/.agents/skills/humanize-flow-planner
  ~/.agents/skills/humanize-flow-bd-planner
  ~/.agents/skills/humanize-flow-reviewer
  ~/.claude/skills/humanize-flow-worker or $CLAUDE_CONFIG_DIR/skills/humanize-flow-worker
  ~/.local/bin/humanize-flow
  ~/.local/share/humanize-flow
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) dry_run=1 ;;
    --help|-h) usage; exit 0 ;;
    *) printf '[uninstall] ERROR: unknown option: %s\n' "$1" >&2; exit 1 ;;
  esac
  shift
done

remove_path() {
  local p
  p="$1"
  if [ "$dry_run" -eq 1 ]; then
    printf '[uninstall] would remove %s\n' "$p"
  else
    rm -rf "$p"
    printf '[uninstall] removed %s\n' "$p"
  fi
}

remove_path "${CODEX_SKILLS_DIR:-$HOME/.agents/skills}/humanize-flow-planner"
remove_path "${CODEX_SKILLS_DIR:-$HOME/.agents/skills}/humanize-flow-bd-planner"
remove_path "${CODEX_SKILLS_DIR:-$HOME/.agents/skills}/humanize-flow-reviewer"
remove_path "${CLAUDE_SKILLS_DIR:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills}/humanize-flow-worker"
remove_path "${HUMANIZE_FLOW_BIN_DIR:-$HOME/.local/bin}/humanize-flow"
remove_path "${HUMANIZE_FLOW_HOME:-$HOME/.local/share/humanize-flow}"
