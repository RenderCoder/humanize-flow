#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

dry_run=0

color_enabled() {
  local fd
  fd="$1"
  [ -z "${NO_COLOR:-}" ] || return 1
  [ -t "$fd" ]
}

colorize() {
  local fd code text
  fd="$1"; code="$2"; text="$3"
  if color_enabled "$fd"; then
    printf '\033[%sm%s\033[0m' "$code" "$text"
  else
    printf '%s' "$text"
  fi
}

emit() {
  local fd icon color label prefix
  fd="$1"; icon="$2"; color="$3"; label="$4"
  shift 4
  prefix="$(colorize "$fd" "$color" "$icon [uninstall] $label")"
  if [ "$fd" = "2" ]; then
    printf '%s %s\n' "$prefix" "$*" >&2
  else
    printf '%s %s\n' "$prefix" "$*"
  fi
}

info() { emit 1 "ℹ️" "34" "INFO:" "$*"; }
success() { emit 1 "✅" "32" "SUCCESS:" "$*"; }
die() { emit 2 "❌" "31" "ERROR:" "$*"; exit 1; }

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
    *) die "unknown option: $1" ;;
  esac
  shift
done

remove_path() {
  local p
  p="$1"
  if [ "$dry_run" -eq 1 ]; then
    info "would remove $p"
  else
    rm -rf "$p"
    success "removed $p"
  fi
}

remove_path "${CODEX_SKILLS_DIR:-$HOME/.agents/skills}/humanize-flow-planner"
remove_path "${CODEX_SKILLS_DIR:-$HOME/.agents/skills}/humanize-flow-bd-planner"
remove_path "${CODEX_SKILLS_DIR:-$HOME/.agents/skills}/humanize-flow-reviewer"
remove_path "${CLAUDE_SKILLS_DIR:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills}/humanize-flow-worker"
remove_path "${HUMANIZE_FLOW_BIN_DIR:-$HOME/.local/bin}/humanize-flow"
remove_path "${HUMANIZE_FLOW_HOME:-$HOME/.local/share/humanize-flow}"
