# AGENTS.md

This file is the authoritative maintenance guide for AI agents working on `humanize-flow`.

humanize-flow is intended to be maintained with Codex. Keep this file short enough to fit into the default AGENTS.md budget while still preserving the critical contracts.

## Project intent

humanize-flow coordinates three roles:

1. **Codex new-request planner** (`humanize-flow-planner`): discuss new requirements when needed, create Markdown plans, prepare Beads tasks, and write a draft handoff.
2. **Codex existing-task planner** (`humanize-flow-bd-planner`): read an existing Beads task ID, clarify missing details, and write a draft handoff that links the original task without duplicating it.
3. **Claude Code worker** (`humanize-flow-worker`): implement exactly one approved Beads task, optionally using humanize/RLCR.
4. **Codex reviewer** (`humanize-flow-reviewer`): review the implementation against the approved plan and acceptance criteria.

The CLI `bin/humanize-flow` is the deterministic orchestrator. Skills define role behavior; the CLI coordinates cross-agent execution.

## Language and documentation policy

- English is the primary language for implementation, public README content, skills, schemas, scripts, and issue templates.
- Simplified Chinese documentation is included by default for the project owner and Chinese-speaking users.
- Human-facing generated artifacts default to English unless the user or Humanize Flow `language`/`i18n` config requests another language. This includes planning docs, Beads task text, implementation summaries, review reports, and commit message prose. Keep machine-readable JSON field names, enum values, labels, paths, commands, API names, code identifiers, and Beads IDs in their canonical form.
- When adding or changing any user-facing documentation, update both versions in the same change:
  - `README.md` and `README.zh-CN.md`
  - `docs/en/<topic>.md` and `docs/zh-CN/<topic>.md`
  - `CONTRIBUTING.md` and `CONTRIBUTING.zh-CN.md`
- If you add a new English doc, add the matching Simplified Chinese doc before finishing.
- If you add a new CLI command, update both `docs/en/cli-reference.md` and `docs/zh-CN/cli-reference.md`.

## Skill naming policy

All public skill names must start with `humanize-flow-`.

Current skills:

- `humanize-flow-planner`
- `humanize-flow-bd-planner`
- `humanize-flow-worker`
- `humanize-flow-reviewer`

Do not introduce short aliases unless the maintainer explicitly asks for them.

## Handoff contract

The handoff JSON is the machine-readable contract between planner, worker, reviewer, and CLI.

Canonical schema:

```text
schemas/handoff.schema.json
```

Canonical handoff path in target repositories:

```text
.humanize-flow/handoffs/<slug>.json
```

Rules:

- Keep `schemas/handoff.schema.json`, `skills/codex/humanize-flow-planner/assets/handoff.schema.json`, `skills/codex/humanize-flow-bd-planner/assets/handoff.schema.json`, and `skills/codex/humanize-flow-reviewer/assets/handoff.schema.json` in sync.
- Keep `templates/handoff.json` and `examples/handoff.example.json` consistent with the schema.
- Handoff states are: `draft`, `approved`, `in_progress`, `review_requested`, `changes_requested`, `complete`, `blocked`.
- Never let the worker execute a handoff whose `approval.status` is not `approved`.

## Role boundaries

- New-request planner may write planning artifacts and draft handoffs. It must not implement product code or invoke Claude.
- Existing-task planner may read existing Beads tasks and write planning artifacts. It must not duplicate Beads tasks unless the human explicitly approves a split.
- Worker may implement exactly one approved task. It must not silently expand scope or rewrite the approved plan.
- Reviewer may inspect and report. It must not implement fixes unless the user explicitly changes its role.
- CLI may orchestrate tools, but should preserve explicit human approval before implementation.

## External integration facts

When updating facts about Codex, Claude Code, Beads, or humanize:

- Check current upstream documentation before editing docs or scripts.
- Prefer official docs and upstream repositories.
- Update troubleshooting notes if upstream CLI flags or skill locations change.

## Tests and validation

Before finalizing changes, run:

```bash
make test
```

At minimum, this should run:

```bash
bash scripts/validate-project.sh
bash -n bin/humanize-flow install.sh uninstall.sh scripts/package.sh scripts/validate-project.sh scripts/sync-schema-assets.sh
```

If you change the CLI, test at least:

```bash
bin/humanize-flow help
bin/humanize-flow doctor
bin/humanize-flow init --help
```

## Changelog

For user-visible changes, update `CHANGELOG.md` under `Unreleased` or create a new version section.

## Security and permissions

- Never store API keys, auth tokens, or local Claude/Codex auth files in this repository.
- Do not write docs that encourage blanket `danger-full-access`, `bypassPermissions`, or equivalent permission bypass as the default.
- If a workflow needs high permissions, document why, where it is safe, and what the safer default is.

## Packaging

The release zip should contain the repository root directory named `humanize-flow/`. Use:

```bash
make package
```

The generated archive is intended to be installable after extraction with:

```bash
./install.sh --user
```

<!-- BEGIN BEADS INTEGRATION -->
## Issue Tracking with bd (beads)

**IMPORTANT**: This project uses **bd (beads)** for ALL issue tracking. Do NOT use markdown TODOs, task lists, or other tracking methods.

### Why bd?

- Dependency-aware: Track blockers and relationships between issues
- Git-friendly: Auto-syncs to JSONL for version control
- Agent-optimized: JSON output, ready work detection, discovered-from links
- Prevents duplicate tracking systems and confusion

### Quick Start

**Check for ready work:**

```bash
bd ready --json
```

**Create new issues:**

```bash
bd create "Issue title" --description="Detailed context" -t bug|feature|task -p 0-4 --json
bd create "Issue title" --description="What this issue is about" -p 1 --deps discovered-from:bd-123 --json
```

**Claim and update:**

```bash
bd update bd-42 --status in_progress --json
bd update bd-42 --priority 1 --json
```

**Complete work:**

```bash
bd close bd-42 --reason "Completed" --json
```

### Issue Types

- `bug` - Something broken
- `feature` - New functionality
- `task` - Work item (tests, docs, refactoring)
- `epic` - Large feature with subtasks
- `chore` - Maintenance (dependencies, tooling)

### Priorities

- `0` - Critical (security, data loss, broken builds)
- `1` - High (major features, important bugs)
- `2` - Medium (default, nice-to-have)
- `3` - Low (polish, optimization)
- `4` - Backlog (future ideas)

### Workflow for AI Agents

1. **Check ready work**: `bd ready` shows unblocked issues
2. **Claim your task**: `bd update <id> --status in_progress`
3. **Work on it**: Implement, test, document
4. **Discover new work?** Create linked issue:
   - `bd create "Found bug" --description="Details about what was found" -p 1 --deps discovered-from:<parent-id>`
5. **Complete**: `bd close <id> --reason "Done"`

### Auto-Sync

bd automatically syncs with git:

- Exports to `.beads/issues.jsonl` after changes (5s debounce)
- Imports from JSONL when newer (e.g., after `git pull`)
- No manual export/import needed!

### Important Rules

- ✅ Use bd for ALL task tracking
- ✅ Always use `--json` flag for programmatic use
- ✅ Link discovered work with `discovered-from` dependencies
- ✅ Check `bd ready` before asking "what should I work on?"
- ❌ Do NOT create markdown TODO lists
- ❌ Do NOT use external issue trackers
- ❌ Do NOT duplicate tracking systems

For more details, see README.md and docs/QUICKSTART.md.

<!-- END BEADS INTEGRATION -->

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
