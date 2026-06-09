#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

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

success() {
  printf '%s %s\n' "$(colorize 1 "32" "✅ [sync-schema] SUCCESS:")" "$*"
}

cp "$ROOT/schemas/handoff.schema.json" "$ROOT/skills/codex/humanize-flow-planner/assets/handoff.schema.json"
cp "$ROOT/schemas/handoff.schema.json" "$ROOT/skills/codex/humanize-flow-bd-planner/assets/handoff.schema.json"
cp "$ROOT/schemas/handoff.schema.json" "$ROOT/skills/codex/humanize-flow-reviewer/assets/handoff.schema.json"
success "schema assets updated"
