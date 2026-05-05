# AI Maintenance Guide

This project is designed to be maintained by Codex or another coding agent. Read `AGENTS.md` first.

## Required maintenance behavior

When adding or changing public documentation, update both languages:

```text
docs/en/<topic>.md
docs/zh-CN/<topic>.md
```

When changing quick-start behavior, update both:

```text
README.md
README.zh-CN.md
```

## Add a CLI command

1. Update `bin/humanize-flow`.
2. Update `docs/en/cli-reference.md`.
3. Update `docs/zh-CN/cli-reference.md`.
4. Update tests or validation.
5. Update `CHANGELOG.md`.
6. Run `make test`.

## Change a skill

1. Update the relevant `SKILL.md`.
2. Update references or assets if the procedure changes.
3. Update docs if user behavior changes.
4. Run `make test`.

## Change the handoff schema

1. Update `schemas/handoff.schema.json`.
2. Run `scripts/sync-schema-assets.sh`.
3. Update `templates/handoff.json` and, if the change affects imported tasks, `templates/handoff-from-bd.json`.
4. Update `examples/handoff.example.json` and, if relevant, `examples/handoff-from-bd.example.json`.
5. Update bilingual docs if behavior changes.
6. Run `make test`.

## Package a release

```bash
make test
make package
```

The release zip should contain a root directory named `humanize-flow/`.
