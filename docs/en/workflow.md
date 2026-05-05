# Workflow

humanize-flow is intentionally human-gated. Codex can plan and discuss; Claude Code can implement; Codex can review. The human approves the transition from planning to implementation.

## 1. Initialize a repository

```bash
humanize-flow init --with-bd
```

This creates:

```text
.humanize-flow/
docs/humanize-flow/
```

When `--with-bd` is used and Beads is available, the CLI also initializes Beads if needed.

## 2. Plan with Codex

In Codex, invoke the planner skill:

```text
$humanize-flow-planner
```

Then describe the request. The planner should inspect repository context, discuss unclear requirements when important, and eventually present the complete plan. It writes draft artifacts only; it does not implement code.

Expected planning artifacts:

```text
docs/humanize-flow/<slug>/request.md
docs/humanize-flow/<slug>/plan.md
docs/humanize-flow/<slug>/acceptance.md
docs/humanize-flow/<slug>/bd-plan.md
.humanize-flow/handoffs/<slug>.json
```

For non-interactive use:

```bash
humanize-flow plan --slug <slug> --from <request-file>
```

If high-impact ambiguity remains, the planner should write `questions.md` and stop rather than inventing a risky decision.

## 2b. Plan from an existing Beads task

If the requirement is already in Beads, use the existing-task path instead of retyping the request.

Interactive Codex flow:

```text
$humanize-flow-bd-planner

Please read Beads task <bd-id>, discuss any missing details with me, and create the Humanize Flow artifacts. Do not duplicate the Beads task and do not implement code.
```

CLI flow:

```bash
humanize-flow plan-from-bd <bd-id> --slug <slug>
```

This path captures `bd show <bd-id> --json` as `bd-source.json` and writes a handoff that links the existing task. It normally skips Beads materialization because the task already exists.

## 3. Approve and materialize Beads tasks

After reading a new-request plan:

```bash
humanize-flow approve <slug> --materialize-bd
```

This changes the handoff state to `approved` and creates Beads issues from the handoff manifest.

After reading an existing-Beads-task plan:

```bash
humanize-flow approve <slug>
```

This only marks the handoff approved. It should not create duplicate Beads tasks because the original task is already linked.

## 4. Execute with Claude Code

Run the next ready Humanize Flow task:

```bash
humanize-flow run-next
```

Or run a specific task:

```bash
humanize-flow run <bd-id>
```

The worker reads the Beads task, handoff, plan, and acceptance criteria. It implements exactly one approved task, optionally uses humanize/RLCR for complex work, records test evidence, and asks for review.

## 5. Review with Codex

```bash
humanize-flow review <bd-id>
```

The reviewer checks the implementation against the approved artifacts and returns one of:

- `pass`
- `changes_requested`
- `blocked`

## 6. Iterate or close

If changes are requested, return to the worker with the review findings. If the review passes, close the Beads task according to your project policy.
