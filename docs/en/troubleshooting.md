# Troubleshooting

## `humanize-flow` command not found

Add the install bin directory to your `PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then restart your shell or run:

```bash
hash -r
```

## Codex skills do not appear

Check:

```bash
ls ~/.agents/skills
```

You should see:

```text
humanize-flow-planner
humanize-flow-bd-planner
humanize-flow-reviewer
```

Restart Codex after installing skills.

## Claude Code skill does not appear

Check:

```bash
ls ~/.claude/skills
```

If `CLAUDE_CONFIG_DIR` is set, check:

```bash
ls "$CLAUDE_CONFIG_DIR/skills"
```

## Planner stops with questions

This is expected when key ambiguity remains. Answer the questions, then rerun planning or invoke the planner interactively.

For an existing Beads task, you can either update the task with the missing details or invoke:

```text
$humanize-flow-bd-planner
```

and discuss the task interactively.

## `approve --materialize-bd` fails

Check that Beads is installed and initialized:

```bash
bd --version
bd init
bd ready --json
```

Also check that the handoff is valid JSON:

```bash
python3 -m json.tool .humanize-flow/handoffs/<slug>.json
```

## `run-next` selects the wrong task

In an interactive terminal, `humanize-flow run-next` asks which ready Epic/task group to run when there are multiple candidates. If your Beads output format differs, or if you want to bypass selection entirely, use an explicit task id:

```bash
humanize-flow run <bd-id>
```

For scripts, set `HUMANIZE_FLOW_NONINTERACTIVE=1` to use deterministic fallback selection.

## `commit` fails in pre-commit hooks

`humanize-flow commit` preserves the hook output under:

```text
.humanize-flow/runs/<timestamp>-commit/git-commit.log
```

When the failure looks like a hook, linter, formatter, typecheck, or test failure, interactive runs ask whether to create a Beads task to fix it. This is intentional: hook failures can mean a real code issue, but they can also mean a local environment problem such as a missing `eslint` binary.

## Review output goes under `unknown`

This means the CLI could not map the provided review argument to a Humanize Flow handoff. Prefer the actual Beads task id from the handoff, for example:

```bash
humanize-flow review rti-tek-miniapp-copy-63g
```

Newer versions also accept the handoff slug, but older installed CLIs may only resolve Beads ids.

## humanize is unavailable

The worker can still implement directly and request Codex review. humanize/RLCR is an enhancement, not a hard dependency.
