# Contributing to humanize-flow

Thank you for helping improve humanize-flow.

## Development setup

```bash
git clone <repo-url> humanize-flow
cd humanize-flow
make test
```

The project is intentionally lightweight. It uses shell scripts, Markdown, JSON Schema, and skills. There is no package manager requirement for local development.

## Before opening a pull request

Run:

```bash
make test
```

Check that:

- English and Simplified Chinese docs are both updated.
- `AGENTS.md` guidance still matches the implementation.
- Skill names and CLI command names remain stable.
- Shell scripts pass `bash -n`.
- Handoff examples match `schemas/handoff.schema.json`.

## Documentation policy

This project is English-first, but every public documentation addition must include a Simplified Chinese counterpart.

Examples:

- Add `docs/en/foo.md` and `docs/zh-CN/foo.md` together.
- Update `README.md` and `README.zh-CN.md` together when changing quick-start behavior.
- Update skill docs in English; if the change affects user docs, update Chinese docs too.

## Design principles

- Keep humans in the loop before implementation.
- Keep planner, worker, and reviewer roles separate.
- Treat Markdown, Beads, and handoff JSON as different interfaces with different readers.
- Prefer explicit approval over silent automation.
- Prefer safe defaults over impressive demos.

## Pull request checklist

- [ ] `make test` passes.
- [ ] User-facing docs are bilingual where required.
- [ ] `CHANGELOG.md` is updated for user-visible changes.
- [ ] New CLI behavior is documented in `docs/en/cli-reference.md` and `docs/zh-CN/cli-reference.md`.
- [ ] New workflow behavior is reflected in the relevant skill reference files.
