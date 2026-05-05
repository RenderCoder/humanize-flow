#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

PROJECT_NAME="humanize-flow"
dry_run=0
scope="user"
force=0
install_codex=1
install_claude=1
install_bin=1

info() { printf '[install] %s\n' "$*"; }
die() { printf '[install] ERROR: %s\n' "$*" >&2; exit 1; }
warn() { printf '[install] WARN: %s\n' "$*" >&2; }

usage() {
  cat <<'EOF'
Install humanize-flow skills and CLI.

Usage:
  ./install.sh [--user|--project] [--dry-run] [--force] [--no-codex] [--no-claude] [--no-bin]

Options:
  --user       Install to user-level locations. Default.
  --project    Install skills into the current repository's .agents/.claude folders.
  --dry-run    Print actions without writing files.
  --force      Replace existing installed skill directories.
  --no-codex   Skip Codex skills.
  --no-claude  Skip Claude Code skill.
  --no-bin     Skip CLI installation.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --user) scope="user" ;;
    --project) scope="project" ;;
    --dry-run) dry_run=1 ;;
    --force) force=1 ;;
    --no-codex) install_codex=0 ;;
    --no-claude) install_claude=0 ;;
    --no-bin) install_bin=0 ;;
    --help|-h) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
  shift
done

script_dir() { CDPATH= cd -- "$(dirname -- "$0")" && pwd; }
SRC_ROOT="$(script_dir)"

copy_dir() {
  local src dest
  src="$1"; dest="$2"
  [ -d "$src" ] || die "missing directory: $src"
  if [ -e "$dest" ] && [ "$force" -ne 1 ]; then
    die "destination exists: $dest (use --force to replace)"
  fi
  if [ "$dry_run" -eq 1 ]; then info "would copy directory $src -> $dest"; return 0; fi
  rm -rf "$dest"
  mkdir -p "$(dirname "$dest")"
  cp -R "$src" "$dest"
}

copy_file() {
  local src dest
  src="$1"; dest="$2"
  [ -f "$src" ] || die "missing file: $src"
  if [ "$dry_run" -eq 1 ]; then info "would copy file $src -> $dest"; return 0; fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
}

if [ "$scope" = "user" ]; then
  CODEX_SKILLS_DIR="${CODEX_SKILLS_DIR:-$HOME/.agents/skills}"
  CLAUDE_BASE="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
  CLAUDE_SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$CLAUDE_BASE/skills}"
  BIN_DIR="${HUMANIZE_FLOW_BIN_DIR:-$HOME/.local/bin}"
  SHARE_DIR="${HUMANIZE_FLOW_HOME:-$HOME/.local/share/humanize-flow}"
else
  if ! git rev-parse --show-toplevel >/dev/null 2>&1; then die "--project install must be run inside a git repository"; fi
  REPO_ROOT="$(git rev-parse --show-toplevel)"
  CODEX_SKILLS_DIR="$REPO_ROOT/.agents/skills"
  CLAUDE_SKILLS_DIR="$REPO_ROOT/.claude/skills"
  BIN_DIR="$REPO_ROOT/.humanize-flow/bin"
  SHARE_DIR="$REPO_ROOT/.humanize-flow/share/humanize-flow"
fi

info "scope: $scope"
info "source: $SRC_ROOT"
info "codex skills: $CODEX_SKILLS_DIR"
info "claude skills: $CLAUDE_SKILLS_DIR"
info "bin dir: $BIN_DIR"
info "share dir: $SHARE_DIR"

if [ "$dry_run" -eq 0 ]; then mkdir -p "$CODEX_SKILLS_DIR" "$CLAUDE_SKILLS_DIR" "$BIN_DIR" "$(dirname "$SHARE_DIR")"; fi

if [ "$install_codex" -eq 1 ]; then
  copy_dir "$SRC_ROOT/skills/codex/humanize-flow-planner" "$CODEX_SKILLS_DIR/humanize-flow-planner"
  copy_dir "$SRC_ROOT/skills/codex/humanize-flow-bd-planner" "$CODEX_SKILLS_DIR/humanize-flow-bd-planner"
  copy_dir "$SRC_ROOT/skills/codex/humanize-flow-reviewer" "$CODEX_SKILLS_DIR/humanize-flow-reviewer"
fi

if [ "$install_claude" -eq 1 ]; then
  copy_dir "$SRC_ROOT/skills/claude/humanize-flow-worker" "$CLAUDE_SKILLS_DIR/humanize-flow-worker"
fi

if [ "$install_bin" -eq 1 ]; then
  copy_dir "$SRC_ROOT" "$SHARE_DIR"
  copy_file "$SRC_ROOT/bin/humanize-flow" "$BIN_DIR/humanize-flow"
  if [ "$dry_run" -eq 0 ]; then chmod +x "$BIN_DIR/humanize-flow" "$SHARE_DIR/bin/humanize-flow"; fi
fi

if [ "$dry_run" -eq 0 ]; then
  info "installed $PROJECT_NAME"
  case ":$PATH:" in *":$BIN_DIR:"*) ;; *) warn "Add $BIN_DIR to PATH to run humanize-flow directly." ;; esac
  if command -v humanize-flow >/dev/null 2>&1; then humanize-flow doctor || true; else "$BIN_DIR/humanize-flow" doctor || true; fi
else
  info "dry run complete"
fi
