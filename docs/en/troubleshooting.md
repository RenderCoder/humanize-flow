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

The CLI first prefers ready tasks that appear in approved Humanize Flow handoffs, then tasks labeled `humanize-flow`. If your Beads output format differs, use an explicit task id:

```bash
humanize-flow run <bd-id>
```

## humanize is unavailable

The worker can still implement directly and request Codex review. humanize/RLCR is an enhancement, not a hard dependency.
