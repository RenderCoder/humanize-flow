#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$ROOT"

fail() { printf '[validate] FAIL: %s\n' "$*" >&2; exit 1; }
pass() { printf '[validate] OK: %s\n' "$*"; }

required_files="
README.md
README.zh-CN.md
AGENTS.md
LICENSE
bin/humanize-flow
install.sh
uninstall.sh
schemas/handoff.schema.json
skills/codex/humanize-flow-planner/SKILL.md
skills/codex/humanize-flow-bd-planner/SKILL.md
skills/codex/humanize-flow-reviewer/SKILL.md
skills/claude/humanize-flow-worker/SKILL.md
"

for f in $required_files; do
  [ -f "$f" ] || fail "missing required file: $f"
done
pass "required files exist"

bash -n bin/humanize-flow install.sh uninstall.sh scripts/package.sh scripts/validate-project.sh scripts/sync-schema-assets.sh
pass "shell syntax"

python3 - <<'PY'
import json
from pathlib import Path
for pattern in ['schemas/*.json', 'templates/*.json', 'examples/*.json']:
    for path in Path('.').glob(pattern):
        json.loads(path.read_text(encoding='utf-8'))
print('[validate] OK: JSON files parse')
PY

for f in docs/en/*.md; do
  base="$(basename "$f")"
  [ -f "docs/zh-CN/$base" ] || fail "missing Chinese doc for docs/en/$base"
done
for f in docs/zh-CN/*.md; do
  base="$(basename "$f")"
  [ -f "docs/en/$base" ] || fail "missing English doc for docs/zh-CN/$base"
done
pass "docs/en and docs/zh-CN are paired"

grep -q 'humanize-flow-planner' skills/codex/humanize-flow-planner/SKILL.md || fail "planner skill missing public name"
grep -q 'humanize-flow-bd-planner' skills/codex/humanize-flow-bd-planner/SKILL.md || fail "bd planner skill missing public name"
grep -q 'humanize-flow-worker' skills/claude/humanize-flow-worker/SKILL.md || fail "worker skill missing public name"
grep -q 'humanize-flow-reviewer' skills/codex/humanize-flow-reviewer/SKILL.md || fail "reviewer skill missing public name"
pass "skill names present"

python3 - <<'PY'
from pathlib import Path
schema = Path('schemas/handoff.schema.json').read_text(encoding='utf-8')
for p in [Path('skills/codex/humanize-flow-planner/assets/handoff.schema.json'), Path('skills/codex/humanize-flow-bd-planner/assets/handoff.schema.json'), Path('skills/codex/humanize-flow-reviewer/assets/handoff.schema.json')]:
    if p.read_text(encoding='utf-8') != schema:
        raise SystemExit(f'[validate] FAIL: {p} is not in sync with schemas/handoff.schema.json')
print('[validate] OK: copied schemas are in sync')
PY

pass "all checks passed"
