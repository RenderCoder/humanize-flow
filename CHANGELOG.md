# Changelog

All notable changes to humanize-flow will be documented in this file.

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
