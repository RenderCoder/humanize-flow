#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cp "$ROOT/schemas/handoff.schema.json" "$ROOT/skills/codex/humanize-flow-planner/assets/handoff.schema.json"
cp "$ROOT/schemas/handoff.schema.json" "$ROOT/skills/codex/humanize-flow-bd-planner/assets/handoff.schema.json"
cp "$ROOT/schemas/handoff.schema.json" "$ROOT/skills/codex/humanize-flow-reviewer/assets/handoff.schema.json"
printf '[sync-schema] schema assets updated\n'
