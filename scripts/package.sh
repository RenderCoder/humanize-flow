#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
OUT="${1:-$ROOT/humanize-flow.zip}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/humanize-flow"
(
  cd "$ROOT"
  tar --exclude='./humanize-flow.zip' --exclude='./.git' --exclude='./.humanize-flow/runs' -cf - .
) | (
  cd "$TMP/humanize-flow"
  tar -xf -
)
(
  cd "$TMP"
  rm -f "$OUT"
  zip -qr "$OUT" humanize-flow
)
printf '[package] wrote %s\n' "$OUT"
