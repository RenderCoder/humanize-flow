# Installation

humanize-flow can be installed at user level or project level.

## User-level install

Use this for your personal workstation:

```bash
./install.sh --user
humanize-flow doctor
```

This installs:

```text
~/.agents/skills/humanize-flow-planner
~/.agents/skills/humanize-flow-bd-planner
~/.agents/skills/humanize-flow-reviewer
~/.claude/skills/humanize-flow-worker
~/.local/bin/humanize-flow
~/.local/share/humanize-flow
```

If `~/.local/bin` is not on your `PATH`, add it in your shell profile:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## Project-level install

Use this when a repository should carry the workflow for every contributor:

```bash
./install.sh --project
```

This copies skills into the current git repository:

```text
.agents/skills/humanize-flow-planner
.agents/skills/humanize-flow-bd-planner
.agents/skills/humanize-flow-reviewer
.claude/skills/humanize-flow-worker
.humanize-flow/bin/humanize-flow
.humanize-flow/share/humanize-flow
```

Project-level install is useful for teams, but user-level install is simpler for a single developer.

## Dry run

```bash
./install.sh --user --dry-run
```

## Replace existing installation

```bash
./install.sh --user --force
```

## Uninstall user-level files

```bash
./uninstall.sh
```

The uninstaller removes user-level skills, CLI files, and shared files. It does not remove per-repository `.humanize-flow` state or generated docs.

## Verify installation

```bash
humanize-flow doctor
```

Warnings for Codex, Claude Code, Beads, or humanize are expected if you have not installed those optional workflow tools yet. Missing Bash, Git, Python 3, or `jq` should be fixed before serious use.
