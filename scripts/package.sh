#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
OUT="${1:-$ROOT/humanize-flow.zip}"
case "$OUT" in
  /*) ;;
  *) OUT="$PWD/$OUT" ;;
esac
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

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
  printf '%s %s\n' "$(colorize 1 "32" "✅ [package] SUCCESS:")" "$*"
}

die() {
  printf '%s %s\n' "$(colorize 2 "31" "❌ [package] ERROR:")" "$*" >&2
  exit 1
}

if [ -e "$OUT" ]; then
  die "output already exists: $OUT. Choose a different output path or remove the existing archive first."
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
success "wrote $OUT"
