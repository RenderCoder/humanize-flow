# Example: Plan from an existing Beads task

Assume your repository already has a Beads task:

```text
bd-1234  Add undo/redo support to the editor
```

Use the dedicated existing-task path:

```bash
humanize-flow plan-from-bd bd-1234
```

Or invoke the skill interactively in Codex:

```text
$humanize-flow-bd-planner

Please read Beads task bd-1234, discuss any missing details with me, and create the Humanize Flow Markdown artifacts and handoff JSON. Do not create duplicate Beads tasks and do not implement code.
```

Expected artifacts:

```text
docs/humanize-flow/<slug>/bd-source.json
docs/humanize-flow/<slug>/request.md
docs/humanize-flow/<slug>/plan.md
docs/humanize-flow/<slug>/acceptance.md
docs/humanize-flow/<slug>/bd-plan.md
.humanize-flow/handoffs/<slug>.json
```

After approval, run the original task directly:

```bash
humanize-flow approve <slug>
humanize-flow run bd-1234
humanize-flow review bd-1234
```
