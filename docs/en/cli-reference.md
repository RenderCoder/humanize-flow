# CLI Reference

The CLI is a lightweight orchestrator. It is intentionally shell-based so the workflow is easy to inspect and modify.

## `humanize-flow help`

Show command help.

## `humanize-flow version`

Print the CLI version.

## `humanize-flow paths`

Show resolved repository, state, docs, and skill paths.

## `humanize-flow doctor`

Check local tools and installed skills.

```bash
humanize-flow doctor
```

## `humanize-flow init [--with-bd]`

Initialize Humanize Flow directories in the current git repository.

```bash
humanize-flow init
humanize-flow init --with-bd
```

## `humanize-flow plan`

Run the Codex planner in non-interactive mode.

```bash
humanize-flow plan --slug <slug> --from <request-file>
humanize-flow plan --slug <slug> --request "<request text>"
```

Options:

- `--sandbox <mode>`: pass sandbox mode to `codex exec`; default is `workspace-write`.
- `--no-codex`: write the planner prompt but do not execute it.

## `humanize-flow plan-from-bd`

Run the Codex planner from an existing Beads task ID.

```bash
humanize-flow plan-from-bd <bd-id>
humanize-flow plan-from-bd <bd-id> --slug <slug>
humanize-flow from-bd <bd-id> --slug <slug>
```

The command captures:

```bash
bd show <bd-id> --json
```

into:

```text
docs/humanize-flow/<slug>/bd-source.json
```

Then it runs the `humanize-flow-bd-planner` skill. The generated handoff links the original Beads task with `source.type=beads`, `source.bd_id=<bd-id>`, `bd.materialized=true`, and `execution.current_bd_id=<bd-id>`.

Options:

- `--slug <slug>`: choose the artifact slug; otherwise the CLI derives one from the task title.
- `--sandbox <mode>`: pass sandbox mode to `codex exec`; default is `workspace-write`.
- `--no-codex`: capture the task and write the planner prompt but do not execute it.

For this path, the next command is usually `humanize-flow approve <slug>` rather than `approve --materialize-bd`, because the Beads task already exists.

## `humanize-flow approve`

Mark a handoff as approved.

```bash
humanize-flow approve <slug>
humanize-flow approve <slug> --materialize-bd
```

## `humanize-flow materialize-bd`

Create Beads epic/tasks from an approved handoff.

```bash
humanize-flow materialize-bd <slug>
```

## `humanize-flow run`

Run Claude Code worker for one Beads task.

```bash
humanize-flow run <bd-id>
```

## `humanize-flow run-next`

Pick a ready Beads task and run the worker.

```bash
humanize-flow run-next
```

## `humanize-flow review`

Run Codex reviewer for one Beads task.

```bash
humanize-flow review <bd-id>
```

## `humanize-flow status`

Show handoff states and Beads ready queue.

```bash
humanize-flow status
```

## Environment variables

| Variable | Purpose |
| --- | --- |
| `HUMANIZE_FLOW_HOME` | Distribution root when installed. |
| `HUMANIZE_FLOW_CLAUDE_ARGS` | Extra arguments for `claude -p`. |
| `HUMANIZE_FLOW_CODEX_ARGS` | Extra arguments for `codex exec`. |
| `HUMANIZE_FLOW_BIN_DIR` | Install location for the CLI. |
| `CODEX_SKILLS_DIR` | Override Codex user skill path. |
| `CLAUDE_CONFIG_DIR` | Override Claude Code config root. |
