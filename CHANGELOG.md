# Changelog

All notable changes to humanize-flow will be documented in this file.

## Unreleased

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
