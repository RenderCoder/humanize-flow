# Changelog

All notable changes to humanize-flow will be documented in this file.

## Unreleased

### Changed

- Make CLI, installer, validation, packaging, and status output use clearer emoji state markers and terminal colors for success, warning, and error messages.
- Make `humanize-flow commit` exclude generated Humanize Flow planning/review artifacts by default, with `--with-doc` to include them intentionally.

### Fixed

- Mark the Beads Epic itself `in_progress` when an Epic-scoped `humanize-flow run ... --yolo` starts, so dashboards show active Epic work while child tasks run.

## [0.5.9] - 2026-05-16

### Added

- Add `humanize-flow pull-main` to detect the repository base branch, autostash uncommitted work, merge the base branch into the current branch, ask Codex to resolve merge or stash-restore conflicts, and write an impact report.

### Fixed

- Make `humanize-flow commit` complete a merge-resolution commit after `pr-resolve` clears conflicts, instead of asking Codex to select partial paths and failing when it returns `NONE`.
- Make default merge-mode `humanize-flow pr-resolve` stage resolved conflicts, create the merge-resolution commit, and push the PR branch automatically, with `--no-commit` and `--no-push` escape hatches.

## [0.5.8] - 2026-05-16

### Added

- Add opt-in Codex worker execution for `run --yolo` via `worker.provider=codex`, with persistent `worker.codex.model` and `worker.codex.reasoning_effort` defaults (`gpt-5.5` / `medium`).
- Add persistent YOLO defaults with `yolo.max_round` and `yolo.review_strategy`, including environment overrides.
- Add `humanize-flow pr-resolve` to integrate a PR target branch and use Codex to resolve merge or rebase conflicts without committing or pushing.

### Changed

- Default `run --yolo` to final full-scope review scheduling and default `--max-round` to 5; use `--review-each-task` to restore per-child review cadence.

### Fixed

- Make `scripts/package.sh <relative-output.zip>` write the archive relative to the caller's working directory instead of the script's temporary package directory.
- Ignore root-level generated zip archives and remove tracked release archives from source control.

## [0.5.7] - 2026-05-11

### Fixed

- Continue Epic YOLO handoff children already marked `in_progress` before falling back to `bd ready`, so resumed runs do not stall when Beads hides active child tasks from the ready queue.

## [0.5.6] - 2026-05-11

### Added

- Add `humanize-flow run --yolo --review-at-end` / `--final-review-only` so Epic YOLO can skip per-child Codex reviews, implement all ready handoff children first, then run one final full-scope review/correction loop.

### Fixed

- Restore Epic YOLO progress from already closed Beads child tasks before selecting the next ready child, so interrupted or resumed runs do not stop with a misleading "no ready remaining child tasks" error.

## [0.5.5] - 2026-05-11

### Fixed

- Require and parse a stable `Humanize-Flow-Verdict: ...` line in Codex review and review-feedback reports so localized review prose does not break `run --yolo`, `status`, `verify`, or PR guide collection.

### Documentation

- Add paired English and Simplified Chinese best-practice guides covering daily workflow, YOLO usage, status diagnosis, review feedback, provider env files, and delivery discipline.

## [0.5.4] - 2026-05-11

### Added

- Add a richer `humanize-flow status` view with latest run/review activity, Beads ready queue, handoff state, inner humanize/RLCR traces, blocker signals, suggested next actions, `--json`, and Codex-powered `--ai` / `--explain`.
- Add opt-in Claude Code provider env-file support for worker runs via `run --env-file`, `run --no-env-file`, `HUMANIZE_FLOW_CLAUDE_ENV_FILE`, and `claude.env_file`.
- Add `humanize-flow verify` to explicitly record that a human completed the Human verification guide after a passing review, allow standalone manual verification when no review artifact exists, and make YOLO startup messaging disclose that this gate is not automated.
- Add planner output for `jira-requirement.md`, a Jira-style Markdown requirement document for internal collaboration systems that follows the configured workflow language.
- Add YOLO phase retries with `run --yolo --retry N --retry-delay SECONDS` so transient Claude, Codex, or Beads command failures do not consume business correction rounds and print a copyable continuation command when retries are exhausted.

## [0.5.3] - 2026-05-10

### Changed

- Make `humanize-flow run --yolo` treat handoff slug and Beads Epic targets as dynamic Beads queues: each child run re-queries `bd ready --json`, selects the next ready handoff child in Beads ready order, closes passing child tasks to unblock dependencies, and scopes Codex review to the completed child task instead of the full Epic.

### Fixed

- Preserve explicit child Beads IDs when resolving handoff-backed `run`, `review`, and `review-feedback` targets so child reviews do not fall back to the Epic/default task.
- Ignore empty or verdict-less review artifacts when selecting the latest review, and fail review commands that produce no parseable verdict.
- Remove an invalid YOLO-only guard from single-task `run` execution.

## [0.5.2] - 2026-05-10

### Changed

- Default Claude Code worker and `run --yolo` permission mode to `bypassPermissions` for fully automatic execution after handoff approval, while keeping `--permission-mode`, `HUMANIZE_FLOW_CLAUDE_PERMISSION_MODE`, and `claude.permission_mode` overrides for stricter local policies.

## [0.5.1] - 2026-05-09

### Changed

- Strengthen `humanize-flow pr` so PR drafts prioritize WHY/context over HOW/WHAT, include passing review `Human verification guide` content for reviewer reference, and pass an explicit `gh pr create --repo` target selected from Git remotes.
- Make `humanize-flow pr` preflight `gh auth status`, save `gh pr create` stdout/stderr, and print/save the resulting pull request URL.
- Make `humanize-flow commit` write `selected-diff.patch` and `selected-diffstat.txt`, then open the selected diff preview before interactive commit confirmation so users can inspect file-level changes before pressing `q` and approving.

## [0.5.0] - 2026-05-09

### Added

- Add `humanize-flow run --yolo` with a Claude Code auto-permission plus Codex yolo review loop, configurable with `--max-round`.
- Add `claude.humanize` worker mode with default `required`, plus `HUMANIZE_FLOW_CLAUDE_HUMANIZE`, `--humanize`, `--humanize-mode`, and `--no-humanize` overrides.

### Changed

- Default Claude Code worker model to `claude-sonnet-4-6` for new installs or unset `claude.model` configuration.
- Default Codex review and review-feedback runs to yolo mode with `--dangerously-bypass-approvals-and-sandbox`, with `review.yolo`, `HUMANIZE_FLOW_REVIEW_YOLO`, `--no-yolo`, `review.sandbox`, `HUMANIZE_FLOW_REVIEW_SANDBOX`, and `--sandbox` overrides.

### Fixed

- Use Python 3-compatible UTC timestamp generation instead of requiring `datetime.UTC`.

## [0.4.0] - 2026-05-08

### Changed

- Codex reviewer reports now require a human verification guide for `pass` verdicts and human correction options for `changes_requested` or `blocked` verdicts.
- Strengthen i18n enforcement so `bd-plan.md`, handoff Beads prose, materialized Beads titles/descriptions/acceptance criteria, and existing-task planning output follow the configured workflow language.

### Added

- Add `humanize-flow review-feedback` for merging human manual-test feedback or review corrections into an updated Codex review verdict.

## [0.3.0] - 2026-05-07

### Changed

- Default Humanize Flow planning Markdown artifacts to Simplified Chinese for faster human review while preserving canonical machine-readable literals.
- Default Claude Code worker runs to human-readable detailed progress output backed by raw `stream-json` capture, permission mode `auto`, and model `claude-opus-4-7`.
- `humanize-flow run-next` now prompts for ready Epic/task selection in interactive terminals instead of immediately running the first ready task.

### Added

- Add `humanize-flow config` for global Claude worker defaults.
- Add `humanize-flow i18n` and `language` config for workflow artifact language.
- Add `codex.model` and `codex.reasoning_effort` config for planner, reviewer, and commit Codex runs.
- Add `humanize-flow run --interactive` for Claude Code interactive worker sessions.
- Add `humanize-flow commit` for Codex-assisted change selection and Lore commit messages.
- Let `humanize-flow commit` ask Codex which changed files belong in the commit every time, treating existing staged changes as advisory context instead of the final commit boundary.
- Capture commit hook failures and optionally create a Beads task for fixing them.
- Add `humanize-flow push` for current-branch push with remote selection.
- Add `humanize-flow pr` for Codex-drafted professional GitHub pull requests that follow the configured workflow language.

### Fixed

- Resolve Humanize Flow handoff slugs in `run` and `review` so review files do not fall back to `docs/humanize-flow/unknown`.
- Add Humanize Flow artifact links to materialized Beads descriptions and require worker/reviewer flows to use approved Markdown artifacts rather than brief Beads text alone.
- Remove a local fallback review artifact from tracked release files and make release packaging use only git-tracked files.
- Make English the default generated artifact language while allowing `zh` for Simplified Chinese workflows.
- Quote skill `description` frontmatter values so Codex can parse installed `SKILL.md` files.
- Validate skill frontmatter during project checks to catch invalid installed skill metadata before release.

## [0.2.0] - 2026-05-05

### Added

- New Codex skill: `humanize-flow-bd-planner` for planning from an existing Beads task ID.
- New CLI command: `humanize-flow plan-from-bd <bd-id>` with alias `humanize-flow from-bd <bd-id>`.
- Existing-task handoff support through optional `source` metadata in `schemas/handoff.schema.json`.
- `bd-source.json` capture flow for `bd show <bd-id> --json`.
- Existing-task handoff template and example.
- `run-next` now prefers ready tasks that appear in approved handoffs, even if the Beads task was imported and does not have a `humanize-flow` label.

### Changed

- Installation, uninstallation, doctor checks, validation, schema sync, and documentation now include `humanize-flow-bd-planner`.
- Documentation now distinguishes new-request planning from existing-Beads-task planning.

## [0.1.0] - 2026-05-04

### Added

- Initial public project structure.
- Codex planner skill: `humanize-flow-planner`.
- Claude Code worker skill: `humanize-flow-worker`.
- Codex reviewer skill: `humanize-flow-reviewer`.
- `humanize-flow` CLI with `doctor`, `init`, `plan`, `approve`, `materialize-bd`, `run`, `run-next`, `review`, `status`, and `paths` commands.
- User-level and project-level installer.
- Simplified Chinese documentation by default.
- AI maintenance instructions in `AGENTS.md`.
- Handoff JSON schema, templates, and examples.
