#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$ROOT"

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

fail() {
  printf '%s %s\n' "$(colorize 2 "31" "❌ [validate] FAIL:")" "$*" >&2
  exit 1
}

pass() {
  printf '%s %s\n' "$(colorize 1 "32" "✅ [validate] OK:")" "$*"
}

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
PY
pass "JSON files parse"

python3 - <<'PY'
from pathlib import Path

try:
    import yaml
except ImportError:
    yaml = None

required_keys = {'name', 'description'}
for path in sorted(Path('skills').glob('**/SKILL.md')):
    text = path.read_text(encoding='utf-8')
    if not text.startswith('---\n'):
        raise SystemExit(f'❌ [validate] FAIL: {path} missing YAML frontmatter')
    try:
        _, frontmatter, _ = text.split('---\n', 2)
    except ValueError:
        raise SystemExit(f'❌ [validate] FAIL: {path} has unterminated YAML frontmatter')
    if yaml is not None:
        try:
            data = yaml.safe_load(frontmatter)
        except Exception as exc:
            raise SystemExit(f'❌ [validate] FAIL: {path} invalid YAML frontmatter: {exc}')
        if not isinstance(data, dict) or not required_keys.issubset(data):
            raise SystemExit(f'❌ [validate] FAIL: {path} frontmatter must include name and description')
    else:
        data = {}
        for line in frontmatter.splitlines():
            if not line.strip():
                continue
            if ':' not in line:
                raise SystemExit(f'❌ [validate] FAIL: {path} frontmatter line is not key/value YAML: {line}')
            key, value = line.split(':', 1)
            key = key.strip()
            value = value.strip()
            if not key or not value:
                raise SystemExit(f'❌ [validate] FAIL: {path} frontmatter has empty key or value: {line}')
            if value[0] in {'"', "'"}:
                if len(value) < 2 or value[-1] != value[0]:
                    raise SystemExit(f'❌ [validate] FAIL: {path} frontmatter has unterminated quoted value: {line}')
            elif ': ' in value:
                raise SystemExit(f'❌ [validate] FAIL: {path} frontmatter plain scalar must quote colon-space values: {line}')
            data[key] = value
        if not required_keys.issubset(data):
            raise SystemExit(f'❌ [validate] FAIL: {path} frontmatter must include name and description')
PY
pass "skill frontmatter parses"

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
        raise SystemExit(f'❌ [validate] FAIL: {p} is not in sync with schemas/handoff.schema.json')
PY
pass "copied schemas are in sync"

pass "all checks passed"
