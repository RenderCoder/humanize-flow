#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
OUT="${1:-$ROOT/humanize-flow.zip}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if [ -e "$OUT" ]; then
  printf '[package] ERROR: output already exists: %s\n' "$OUT" >&2
  printf '[package] choose a different output path or remove the existing archive first.\n' >&2
  exit 1
fi

mkdir -p "$TMP/humanize-flow"
(
  cd "$ROOT"
  git ls-files -z | while IFS= read -r -d '' path; do
    case "$path" in
      humanize-flow*.zip) continue ;;
    esac
    if [ -f "$path" ]; then
      printf '%s\0' "$path"
    fi
  done | tar --null -T - -cf - --no-recursion
) | (
  cd "$TMP/humanize-flow"
  tar -xf -
)
(
  cd "$TMP"
  zip -qr "$OUT" humanize-flow
)
printf '[package] wrote %s\n' "$OUT"
