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

Human-facing generated artifacts default to English. Use `humanize-flow i18n zh` to switch the full workflow to Simplified Chinese. This includes `bd-plan.md`, handoff prose, and generated Beads epic/task titles, descriptions, and acceptance criteria. Keep machine-readable JSON keys, enum values, labels, paths, commands, APIs, Beads IDs, and code identifiers in their canonical form.

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

This path captures `bd show <bd-id> --json` as `bd-source.json` and writes a handoff that links the existing task. Raw source task text remains in `bd-source.json`, while generated request, plan, acceptance, `bd-plan.md`, and handoff task prose follow the configured workflow language. It normally skips Beads materialization because the task already exists.

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

The worker reads the Beads task, approved handoff, plan, and acceptance criteria. Beads text may be intentionally concise; the Markdown artifacts are the detailed execution contract. If the approved handoff, `plan.md`, or `acceptance.md` is missing, the worker should stop instead of implementing from the Beads task alone.

By default, worker runs use `claude.humanize=required`. The CLI checks for a humanize command, Claude plugin, or installed Codex humanize skill script before launch, and the generated Claude prompt requires starting humanize/RLCR from the approved plan before code edits. If your environment cannot run humanize for a specific task, lower the mode explicitly:

```bash
humanize-flow run <bd-id> --humanize-mode auto
humanize-flow run <bd-id> --no-humanize
humanize-flow config set claude.humanize auto
```

For approved handoffs, YOLO mode can run the implementation and review loop automatically:

```bash
humanize-flow run <bd-id> --yolo
humanize-flow run <bd-id> --yolo --max-round 5
```

YOLO mode forces Claude Code permission mode `bypassPermissions`, forces `--humanize-mode off` to avoid nested review loops, forces Codex review yolo mode, and repeats Claude correction plus Codex review until the review verdict is `pass` or the maximum round count is reached. The default maximum is 3 rounds per target task. If you pass a handoff slug or Beads Epic ID, YOLO re-queries `bd ready --json` before each child task, chooses the next ready child that belongs to the handoff in Beads' ready order, closes each child after a passing review so dependencies can unblock, and scopes each Codex review to the completed child task, not the whole Epic. The handoff limits scope but does not impose a static child-task order.

## 5. Review with Codex

```bash
humanize-flow review <bd-id>
```

The reviewer checks the implementation against the approved artifacts and returns one of:

- `pass`
- `changes_requested`
- `blocked`

Missing handoff, plan, or acceptance evidence should produce `blocked`, not `pass`.

Codex review and review-feedback default to yolo mode with `--dangerously-bypass-approvals-and-sandbox` to avoid approval prompts blocking the loop. Use `humanize-flow config set review.yolo false`, `HUMANIZE_FLOW_REVIEW_YOLO=false`, or `--no-yolo` when you need stricter isolation; then control sandboxing with `humanize-flow config set review.sandbox <mode>`, `HUMANIZE_FLOW_REVIEW_SANDBOX`, or `--sandbox <mode>`.

When the verdict is `pass`, the report includes a human verification guide. Complete its manual test steps and checklist before final git delivery. A pass from Codex means the code satisfies the reviewed contract; it is not a command to commit immediately.

If manual testing finds a problem, or if a human decides that a Codex finding is based on the wrong scope or missing context, merge that feedback into a new review. With no `--note` or `--from`, the command opens your editor and continues after you save and quit:

```bash
humanize-flow review-feedback <bd-id>
```

The updated review combines the prior Codex review with the human feedback and re-evaluates the verdict. It can turn `pass` into `changes_requested`, or turn `changes_requested`/`blocked` into `pass` when the feedback supplies valid scope correction or missing evidence.

## 6. Iterate or close

If changes are requested, return to the worker with the review findings. If the review passes, close the Beads task according to your project policy.

For final git handoff, stage the intended files, then run:

```bash
humanize-flow commit
humanize-flow push
humanize-flow pr
```
