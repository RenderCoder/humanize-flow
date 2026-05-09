#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$ROOT"
bash scripts/validate-project.sh

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export XDG_CONFIG_HOME="$TMP/config"
bin/humanize-flow version >/dev/null
bin/humanize-flow help >/dev/null
bin/humanize-flow paths >/dev/null
test "$(bin/humanize-flow i18n)" = "en"
test "$(HUMANIZE_FLOW_LANGUAGE=zh bin/humanize-flow i18n)" = "zh"
bin/humanize-flow config show | grep -q 'codex.model: (codex default)'
bin/humanize-flow config show | grep -q 'codex.reasoning_effort: (codex default)'
bin/humanize-flow config show | grep -q 'claude.humanize: required'
test "$(HUMANIZE_FLOW_CLAUDE_HUMANIZE=off bin/humanize-flow config get claude.humanize)" = "off"
bin/humanize-flow config show | grep -q 'review.yolo: true'
test "$(HUMANIZE_FLOW_REVIEW_YOLO=false bin/humanize-flow config get review.yolo)" = "false"
bin/humanize-flow config show | grep -q 'review.sandbox: danger-full-access'
test "$(HUMANIZE_FLOW_REVIEW_SANDBOX=workspace-write bin/humanize-flow config get review.sandbox)" = "workspace-write"
mkdir -p "$TMP/fake-bin" "$TMP/repo"
cat > "$TMP/fake-bin/bd" <<'BD'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  show)
    cat <<'JSON'
{
  "id": "bd-1234",
  "title": "Add undo redo support",
  "description": "Existing task created before Humanize Flow planning.",
  "labels": ["editor"],
  "priority": 2,
  "type": "task"
}
JSON
    ;;
  ready)
    cat <<'JSON'
[
  {
    "id": "bd-1234",
    "title": "Add undo redo support",
    "labels": ["humanize-flow"],
    "priority": 2,
    "type": "task"
  },
  {
    "id": "bd-5678",
    "title": "Another task",
    "labels": ["humanize-flow"],
    "priority": 2,
    "type": "task"
  }
]
JSON
    ;;
  create)
    printf '%s\n' "$@" > "$BD_CREATE_ARGS_CAPTURE"
    cat <<'JSON'
{"id":"bd-hook-1","title":"Fix commit hook failure"}
JSON
    ;;
  *)
    echo "fake bd only supports show, ready, and create" >&2
    exit 2
    ;;
esac
BD
chmod +x "$TMP/fake-bin/bd"
cat > "$TMP/fake-bin/claude" <<'CLAUDE'
#!/usr/bin/env bash
set -euo pipefail
if [ -n "${CLAUDE_RUN_COUNT:-}" ]; then
  count=0
  if [ -f "$CLAUDE_RUN_COUNT" ]; then count="$(cat "$CLAUDE_RUN_COUNT")"; fi
  count=$((count + 1))
  printf '%s\n' "$count" > "$CLAUDE_RUN_COUNT"
fi
printf '%s\n' "$*" > "$CLAUDE_ARGS_CAPTURE"
printf '{"type":"result","subtype":"success","result":"ok"}\n'
CLAUDE
chmod +x "$TMP/fake-bin/claude"
cat > "$TMP/fake-bin/humanize" <<'HUMANIZE'
#!/usr/bin/env bash
set -euo pipefail
printf 'fake humanize\n'
HUMANIZE
chmod +x "$TMP/fake-bin/humanize"
cat > "$TMP/fake-bin/codex" <<'CODEX'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" > "$CODEX_ARGS_CAPTURE"
case "$*" in
  *"selecting which changed files belong in one git commit"*)
    printf 'commit-test.txt\n'
    ;;
  *"drafting a Beads task for a failed git commit hook"*)
    printf '{"title":"Fix commit hook eslint failure","description":"Commit hook failed because eslint was unavailable.","priority":2,"labels":["humanize-flow","commit-hook","eslint"]}\n'
    ;;
  *"updating a Humanize Flow review with human manual-test feedback"*)
    printf '# Humanize Flow Review: bd-1234\n\n## Verdict\n\n`changes_requested`\n\n## Summary\n\nHuman feedback found a manual-test issue.\n\n## Human correction options\n\n- Suggested command: `humanize-flow run bd-1234`\n'
    ;;
  *"running the Humanize Flow reviewer for this repository"*)
    if [ -n "${CODEX_REVIEW_COUNT:-}" ]; then
      count=0
      if [ -f "$CODEX_REVIEW_COUNT" ]; then count="$(cat "$CODEX_REVIEW_COUNT")"; fi
      count=$((count + 1))
      printf '%s\n' "$count" > "$CODEX_REVIEW_COUNT"
      if [ "$count" -eq 1 ]; then
        printf '# Humanize Flow Review: bd-1234\n\n## Verdict\n\n`changes_requested`\n\n## Summary\n\nYOLO first review requested changes.\n'
      else
        printf '# Humanize Flow Review: bd-1234\n\n## Verdict\n\n`pass`\n\n## Summary\n\nYOLO second review passed.\n\n## Human verification guide\n\n- [ ] Run smoke checks.\n'
      fi
    else
      printf 'fake review\n'
    fi
    ;;
  *"drafting a professional GitHub pull request"*)
    case "$*" in
      *"language code: zh"*)
        printf '{"title":"完善 Humanize Flow 执行链路","body":"## 摘要\\n- 新增 PR 创建流程。\\n\\n## 验证\\n- make test"}\n'
        ;;
      *)
        printf '{"title":"Improve Humanize Flow delivery automation","body":"## Summary\\n- Add PR creation flow.\\n\\n## Verification\\n- make test"}\n'
        ;;
    esac
    ;;
  *)
    printf 'fake review\n'
    ;;
esac
CODEX
chmod +x "$TMP/fake-bin/codex"
cat > "$TMP/fake-bin/gh" <<'GH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" > "$GH_ARGS_CAPTURE"
case "$*" in
  *"pr create"*)
    printf 'https://github.com/example/repo/pull/1\n'
    ;;
  *)
    printf 'fake gh only supports pr create\n' >&2
    exit 2
    ;;
esac
GH
chmod +x "$TMP/fake-bin/gh"
(
  cd "$TMP/repo"
  git init -q
  git config user.email smoke@example.com
  git config user.name "Smoke Test"
  printf 'base\n' > base.txt
  git add base.txt
  git commit -qm 'Initial smoke baseline'
  git branch -M main
  PATH="$TMP/fake-bin:$PATH" "$ROOT/bin/humanize-flow" plan-from-bd bd-1234 --slug imported-task --no-codex >/dev/null
  grep -R 'language code: en' .humanize-flow/runs/*/bd-planner-prompt.md >/dev/null
  HUMANIZE_FLOW_LANGUAGE=zh PATH="$TMP/fake-bin:$PATH" "$ROOT/bin/humanize-flow" plan-from-bd bd-1234 --slug imported-task-zh --no-codex >/dev/null
  grep -R 'Simplified Chinese (language code: zh)' .humanize-flow/runs/*/bd-planner-prompt.md >/dev/null
  grep -R 'generated bd.tasks title, description, and acceptance criteria fields' .humanize-flow/runs/*/bd-planner-prompt.md >/dev/null
  HUMANIZE_FLOW_LANGUAGE=zh PATH="$TMP/fake-bin:$PATH" "$ROOT/bin/humanize-flow" plan --slug request-zh --request "Add export support" --no-codex >/dev/null
  grep -R 'bd-plan.md and Beads epic/task titles, descriptions, and acceptance criteria' .humanize-flow/runs/*/planner-prompt.md >/dev/null
  python3 - <<'PY'
import json
from pathlib import Path
path = Path('.humanize-flow/handoffs/imported-task.json')
data = {
    'schema_version': '1',
    'slug': 'imported-task',
    'state': 'approved',
    'approval': {'status': 'approved'},
    'artifacts': {
        'request': 'docs/humanize-flow/imported-task/request.md',
        'plan': 'docs/humanize-flow/imported-task/plan.md',
        'acceptance': 'docs/humanize-flow/imported-task/acceptance.md',
        'bd_plan': 'docs/humanize-flow/imported-task/bd-plan.md',
    },
    'bd': {
        'materialized': True,
        'tasks': [{'key': 'source-task', 'bd_id': 'bd-1234'}],
    },
    'execution': {'current_bd_id': 'bd-1234'},
}
path.write_text(json.dumps(data, indent=2) + '\n', encoding='utf-8')
PY
  mkdir -p docs/humanize-flow/imported-task
  printf '# Request\n\nAdd undo redo support.\n' > docs/humanize-flow/imported-task/request.md
  printf '# Plan\n\nImplement undo redo support.\n\n## Acceptance Criteria\n\n- Undo works.\n' > docs/humanize-flow/imported-task/plan.md
  printf '# Acceptance\n\n- Undo works.\n' > docs/humanize-flow/imported-task/acceptance.md
  printf '# Beads Plan\n\n- bd-1234\n' > docs/humanize-flow/imported-task/bd-plan.md
  test -f docs/humanize-flow/imported-task/bd-source.json
  grep -q 'Add undo redo support' docs/humanize-flow/imported-task/bd-source.json
  grep -R '\$humanize-flow-bd-planner' .humanize-flow/runs >/dev/null
  python3 - <<'PY'
import json
from pathlib import Path
path = Path('.humanize-flow/handoffs/zh-materialize.json')
data = {
    'schema_version': '1',
    'slug': 'zh-materialize',
    'summary': '中文摘要',
    'state': 'approved',
    'approval': {'status': 'approved'},
    'artifacts': {
        'request': 'docs/humanize-flow/zh-materialize/request.md',
        'plan': 'docs/humanize-flow/zh-materialize/plan.md',
        'acceptance': 'docs/humanize-flow/zh-materialize/acceptance.md',
        'bd_plan': 'docs/humanize-flow/zh-materialize/bd-plan.md',
    },
    'bd': {'materialized': False, 'tasks': []},
}
path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
PY
  HUMANIZE_FLOW_LANGUAGE=zh BD_CREATE_ARGS_CAPTURE="$TMP/bd-materialize-args.txt" PATH="$TMP/fake-bin:$PATH" "$ROOT/bin/humanize-flow" materialize-bd zh-materialize >/dev/null
  grep -q 'Humanize Flow 上下文' "$TMP/bd-materialize-args.txt"
  grep -q '需求' "$TMP/bd-materialize-args.txt"
  grep -q 'Beads 计划' "$TMP/bd-materialize-args.txt"
  mkdir -p docs/humanize-flow/imported-task/reviews
  printf 'old review\n' > docs/humanize-flow/imported-task/reviews/20260507-000000-bd-1234.md
  printf 'new review\n' > docs/humanize-flow/imported-task/reviews/20260508-000000-bd-1234.md
  CLAUDE_ARGS_CAPTURE="$TMP/claude-args.txt" PATH="$TMP/fake-bin:$PATH" "$ROOT/bin/humanize-flow" run bd-1234 >/dev/null
  grep -q -- '--model claude-sonnet-4-6' "$TMP/claude-args.txt"
  grep -q -- '--permission-mode auto' "$TMP/claude-args.txt"
  grep -q -- '--output-format stream-json' "$TMP/claude-args.txt"
  grep -q -- '--include-partial-messages' "$TMP/claude-args.txt"
  grep -q -- '--include-hook-events' "$TMP/claude-args.txt"
  grep -q -- '--verbose' "$TMP/claude-args.txt"
  grep -q 'Claude humanize mode: required' "$TMP/claude-args.txt"
  grep -q 'Required humanize behavior:' "$TMP/claude-args.txt"
  grep -q '/humanize:start-rlcr-loop docs/humanize-flow/imported-task/plan.md --yolo' "$TMP/claude-args.txt"
  grep -q 'Latest review path: docs/humanize-flow/imported-task/reviews/20260508-000000-bd-1234.md' "$TMP/claude-args.txt"
  grep -q 'Do not bulk-load docs/humanize-flow/imported-task/reviews/' "$TMP/claude-args.txt"
  CLAUDE_ARGS_CAPTURE="$TMP/claude-no-humanize-args.txt" PATH="$TMP/fake-bin:$PATH" "$ROOT/bin/humanize-flow" run bd-1234 --no-humanize >/dev/null
  grep -q 'Claude humanize mode: off' "$TMP/claude-no-humanize-args.txt"
  "$ROOT/bin/humanize-flow" config set claude.humanize auto >/dev/null
  test "$("$ROOT/bin/humanize-flow" config get claude.humanize)" = "auto"
  CLAUDE_ARGS_CAPTURE="$TMP/claude-auto-humanize-args.txt" PATH="$TMP/fake-bin:$PATH" "$ROOT/bin/humanize-flow" run bd-1234 >/dev/null
  grep -q 'Claude humanize mode: auto' "$TMP/claude-auto-humanize-args.txt"
  "$ROOT/bin/humanize-flow" config set claude.humanize required >/dev/null
  HUMANIZE_FLOW_NONINTERACTIVE=1 CLAUDE_ARGS_CAPTURE="$TMP/claude-run-next-args.txt" PATH="$TMP/fake-bin:$PATH" "$ROOT/bin/humanize-flow" run-next >/dev/null
  grep -q 'bd-1234' "$TMP/claude-run-next-args.txt"
  test "$(find .humanize-flow/runs -name claude-final.jsonl -print | wc -l | tr -d ' ')" -gt 0
  grep -R '\[result\] success' .humanize-flow/runs >/dev/null
  CODEX_ARGS_CAPTURE="$TMP/codex-review-args.txt" PATH="$TMP/fake-bin:$PATH" "$ROOT/bin/humanize-flow" review imported-task >/dev/null
  test -f docs/humanize-flow/imported-task/reviews/"$(ls docs/humanize-flow/imported-task/reviews | tail -n 1)"
  test ! -d docs/humanize-flow/unknown/reviews
  grep -q -- '--dangerously-bypass-approvals-and-sandbox' "$TMP/codex-review-args.txt"
  ! grep -q -- '--sandbox danger-full-access' "$TMP/codex-review-args.txt"
  grep -q 'Task id: bd-1234' "$TMP/codex-review-args.txt"
  grep -q 'Handoff slug: imported-task' "$TMP/codex-review-args.txt"
  CODEX_ARGS_CAPTURE="$TMP/codex-review-sandbox-args.txt" PATH="$TMP/fake-bin:$PATH" "$ROOT/bin/humanize-flow" review imported-task --sandbox workspace-write >/dev/null
  grep -q -- '--sandbox workspace-write' "$TMP/codex-review-sandbox-args.txt"
  ! grep -q -- '--dangerously-bypass-approvals-and-sandbox' "$TMP/codex-review-sandbox-args.txt"
  printf 'Manual test found an overlap in the empty state.\n' > manual-feedback.md
  CODEX_ARGS_CAPTURE="$TMP/codex-review-feedback-args.txt" PATH="$TMP/fake-bin:$PATH" "$ROOT/bin/humanize-flow" review-feedback imported-task --from manual-feedback.md >/dev/null
  grep -q -- '--dangerously-bypass-approvals-and-sandbox' "$TMP/codex-review-feedback-args.txt"
  grep -q 'Human feedback:' "$TMP/codex-review-feedback-args.txt"
  grep -q 'Prior review:' "$TMP/codex-review-feedback-args.txt"
  grep -R 'Manual test found an overlap' .humanize-flow/runs/*/human-feedback.md >/dev/null
  grep -R 'Human feedback found a manual-test issue' docs/humanize-flow/imported-task/reviews >/dev/null
  cat > "$TMP/fake-bin/editor" <<'EDITOR'
#!/usr/bin/env bash
set -euo pipefail
printf 'Editor feedback found a translated label issue.\n' > "$1"
EDITOR
  chmod +x "$TMP/fake-bin/editor"
  CODEX_ARGS_CAPTURE="$TMP/codex-review-feedback-editor-args.txt" EDITOR="$TMP/fake-bin/editor" PATH="$TMP/fake-bin:$PATH" "$ROOT/bin/humanize-flow" review-feedback imported-task >/dev/null
  grep -q -- '--dangerously-bypass-approvals-and-sandbox' "$TMP/codex-review-feedback-editor-args.txt"
  grep -q 'Human feedback:' "$TMP/codex-review-feedback-editor-args.txt"
  grep -R 'Editor feedback found a translated label issue' .humanize-flow/runs/*/human-feedback.md >/dev/null
  python3 - <<'PY'
import json
from pathlib import Path
data = json.loads(Path('.humanize-flow/handoffs/imported-task.json').read_text(encoding='utf-8'))
artifacts = data.get('artifacts', {})
assert artifacts.get('latest_review', '').endswith('-imported-task-human-feedback.md'), artifacts
assert artifacts.get('latest_human_feedback', '').endswith('/human-feedback.md'), artifacts
PY
  HUMANIZE_FLOW_CODEX_MODEL=gpt-5.5 HUMANIZE_FLOW_CODEX_REASONING_EFFORT=high CODEX_ARGS_CAPTURE="$TMP/codex-configured-review-args.txt" PATH="$TMP/fake-bin:$PATH" "$ROOT/bin/humanize-flow" review imported-task >/dev/null
  grep -q -- '--model gpt-5.5' "$TMP/codex-configured-review-args.txt"
  grep -q -- '-c model_reasoning_effort="high"' "$TMP/codex-configured-review-args.txt"
  HUMANIZE_FLOW_REVIEW_SANDBOX=read-only HUMANIZE_FLOW_REVIEW_YOLO=false CODEX_ARGS_CAPTURE="$TMP/codex-env-review-args.txt" PATH="$TMP/fake-bin:$PATH" "$ROOT/bin/humanize-flow" review imported-task >/dev/null
  grep -q -- '--sandbox read-only' "$TMP/codex-env-review-args.txt"
  HUMANIZE_FLOW_REVIEW_YOLO=false CODEX_ARGS_CAPTURE="$TMP/codex-env-no-yolo-review-args.txt" PATH="$TMP/fake-bin:$PATH" "$ROOT/bin/humanize-flow" review imported-task >/dev/null
  grep -q -- '--sandbox danger-full-access' "$TMP/codex-env-no-yolo-review-args.txt"
  "$ROOT/bin/humanize-flow" config set review.sandbox workspace-write >/dev/null
  "$ROOT/bin/humanize-flow" config set review.yolo false >/dev/null
  CODEX_ARGS_CAPTURE="$TMP/codex-config-sandbox-review-args.txt" PATH="$TMP/fake-bin:$PATH" "$ROOT/bin/humanize-flow" review imported-task >/dev/null
  grep -q -- '--sandbox workspace-write' "$TMP/codex-config-sandbox-review-args.txt"
  CLAUDE_RUN_COUNT="$TMP/yolo-claude-count.txt" CODEX_REVIEW_COUNT="$TMP/yolo-review-count.txt" CLAUDE_ARGS_CAPTURE="$TMP/claude-yolo-args.txt" CODEX_ARGS_CAPTURE="$TMP/codex-yolo-review-args.txt" PATH="$TMP/fake-bin:$PATH" "$ROOT/bin/humanize-flow" run imported-task --yolo --max-round 2 >/dev/null
  test "$(cat "$TMP/yolo-claude-count.txt")" = "2"
  test "$(cat "$TMP/yolo-review-count.txt")" = "2"
  grep -q -- '--permission-mode auto' "$TMP/claude-yolo-args.txt"
  grep -q -- '--dangerously-bypass-approvals-and-sandbox' "$TMP/codex-yolo-review-args.txt"
  grep -q 'Latest review path: docs/humanize-flow/imported-task/reviews/' "$TMP/claude-yolo-args.txt"
  grep -R 'YOLO second review passed' docs/humanize-flow/imported-task/reviews >/dev/null
  git checkout -qb feature/pr-smoke
  printf 'pr\n' > pr-change.txt
  git add pr-change.txt
  git commit -qm 'Add PR smoke change'
  HUMANIZE_FLOW_LANGUAGE=zh CODEX_ARGS_CAPTURE="$TMP/codex-pr-args.txt" GH_ARGS_CAPTURE="$TMP/gh-pr-args.txt" PATH="$TMP/fake-bin:$PATH" "$ROOT/bin/humanize-flow" pr --base main --yes >/dev/null
  grep -q 'language code: zh' "$TMP/codex-pr-args.txt"
  grep -q -- 'pr create --base main --head feature/pr-smoke' "$TMP/gh-pr-args.txt"
  grep -q -- '--title 完善 Humanize Flow 执行链路' "$TMP/gh-pr-args.txt"
  grep -R '## 摘要' .humanize-flow/runs/*/pr-body.md >/dev/null
  CODEX_ARGS_CAPTURE="$TMP/codex-pr-dry-run-args.txt" GH_ARGS_CAPTURE="$TMP/gh-pr-dry-run-args.txt" PATH="$TMP/fake-bin:$PATH" "$ROOT/bin/humanize-flow" pr --base main --dry-run >/dev/null
  printf 'change\n' > commit-test.txt
  CODEX_ARGS_CAPTURE="$TMP/codex-commit-args.txt" PATH="$TMP/fake-bin:$PATH" "$ROOT/bin/humanize-flow" commit --yes >/dev/null
  git log -1 --pretty=%B | grep -q 'fake review'
  git show --name-only --pretty='' HEAD | grep -q '^commit-test.txt$'
  grep -R '^commit-test.txt$' .humanize-flow/runs/*/commit-paths.txt >/dev/null
  printf '#!/usr/bin/env bash\nprintf "lefthook pre-commit failed: eslint not found\\n" >&2\nexit 1\n' > .git/hooks/pre-commit
  chmod +x .git/hooks/pre-commit
  printf 'again\n' >> commit-test.txt
  set +e
  printf 'y\n' | BD_CREATE_ARGS_CAPTURE="$TMP/bd-create-args.txt" CODEX_ARGS_CAPTURE="$TMP/codex-hook-failure-args.txt" PATH="$TMP/fake-bin:$PATH" "$ROOT/bin/humanize-flow" commit --yes >/dev/null 2>"$TMP/commit-failure.stderr"
  commit_status=$?
  set -e
  test "$commit_status" -ne 0
  grep -q 'lefthook pre-commit failed: eslint not found' "$TMP/commit-failure.stderr"
  grep -q 'Fix commit hook eslint failure' "$TMP/bd-create-args.txt"
  grep -q 'commit-hook' "$TMP/bd-create-args.txt"
  test "$(find .humanize-flow/runs -name git-commit.log -print | wc -l | tr -d ' ')" -gt 0
  git init --bare "$TMP/remote.git" >/dev/null
  git remote add origin "$TMP/remote.git"
  "$ROOT/bin/humanize-flow" push >/dev/null
)
printf '[smoke] OK\n'
