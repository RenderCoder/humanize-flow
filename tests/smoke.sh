#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$ROOT"
bash scripts/validate-project.sh
bin/humanize-flow version >/dev/null
bin/humanize-flow help >/dev/null
bin/humanize-flow paths >/dev/null

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
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
  *)
    echo "fake bd only supports show" >&2
    exit 2
    ;;
esac
BD
chmod +x "$TMP/fake-bin/bd"
(
  cd "$TMP/repo"
  git init -q
  PATH="$TMP/fake-bin:$PATH" "$ROOT/bin/humanize-flow" plan-from-bd bd-1234 --slug imported-task --no-codex >/dev/null
  test -f docs/humanize-flow/imported-task/bd-source.json
  grep -q 'Add undo redo support' docs/humanize-flow/imported-task/bd-source.json
  grep -R '\$humanize-flow-bd-planner' .humanize-flow/runs >/dev/null
)
printf '[smoke] OK\n'
