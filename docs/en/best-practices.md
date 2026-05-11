# Best Practices

This guide explains the recommended day-to-day way to use Humanize Flow. The goal is to keep the automation useful without hiding the important human decisions.

## Recommended Daily Path

Use the conservative path for normal feature work:

```bash
humanize-flow init --with-bd
humanize-flow approve <slug> --materialize-bd
humanize-flow run-next
humanize-flow review <bd-id>
humanize-flow verify <bd-id>
humanize-flow commit
humanize-flow push
humanize-flow pr
```

This keeps the strongest boundaries:

- Codex creates the plan and review.
- You approve the handoff before implementation starts.
- Claude Code implements one Beads task at a time.
- Codex reviews the task against the approved artifacts.
- You complete the human verification guide before delivery.

Prefer explicit Beads task IDs when you know exactly what should run:

```bash
humanize-flow run <bd-id>
```

Use `run-next` when you want Humanize Flow to choose from the ready queue and prompt if multiple task groups are available.

## When To Use YOLO

Use YOLO for trusted worktrees where you want the CLI to keep moving through implementation and Codex review:

```bash
humanize-flow run <handoff-slug-or-epic-id> --yolo --max-round 3 --retry 5 --retry-delay 20
```

For large cohesive Epics, you can trade early per-child review for one final full-scope review:

```bash
humanize-flow run <handoff-slug-or-epic-id> --yolo --review-at-end --max-round 3
```

YOLO is best for:

- well-scoped handoffs with clear acceptance criteria,
- task queues already represented in Beads dependencies,
- trusted repositories where high automation is acceptable,
- long-running work where transient provider or network failures should retry automatically.

Prefer the default per-child review when early defect detection matters, child tasks are risky, or downstream tasks should not build on unreviewed output. Prefer `--review-at-end` when the Epic is cohesive, intermediate reviews are mostly noise, or you need Codex to judge cross-task behavior from the final integrated diff. In final-review mode, `--max-round` applies to the final full-scope review/correction loop after all child tasks are implemented.

If a YOLO Epic run is interrupted, rerun the same command. Humanize Flow restores completed-child progress from Beads closed tasks and continues handoff children already marked `in_progress` before selecting the next ready child, so a retry should continue instead of starting the Epic queue over or stalling because the active child no longer appears in `bd ready`.

YOLO is not a substitute for final human verification. After a passing review, complete the review report's `Human verification guide` and record it:

```bash
humanize-flow verify <bd-id>
```

Then run delivery commands such as `commit`, `push`, and `pr`.

## Avoid Nested Review Loops

Default non-YOLO `run` uses `claude.humanize=required`, so Claude Code is instructed to start humanize/RLCR before editing code.

YOLO intentionally forces `--humanize-mode off`. That prevents two independent review loops from competing with each other:

- Outer loop: Humanize Flow runs Claude Code, then Codex review, then another Claude correction round if needed.
- Inner loop: humanize/RLCR inside Claude Code.

For day-to-day deterministic automation, use one loop at a time:

- Use normal `run` when you want Claude Code to use humanize/RLCR during implementation.
- Use `run --yolo` when you want Humanize Flow to own the full Claude plus Codex review loop.

## Keep Reviews Machine-Readable

Review reports must begin with one stable verdict line:

```text
Humanize-Flow-Verdict: pass
```

The value must be exactly one of:

- `pass`
- `changes_requested`
- `blocked`

The rest of the report should follow your configured i18n language. Do not translate the machine-readable verdict line. Humanize Flow uses it for `run --yolo`, `status`, `verify`, and PR validation guide collection.

## Use Status Before Assuming A Run Is Stuck

When a terminal looks idle or the workflow seems to have stopped, first run:

```bash
humanize-flow status
humanize-flow status --ai
```

`status` gives the deterministic view: latest run, latest review, Beads ready queue, handoff state, warnings, and suggested next actions.

`status --ai` asks Codex to explain that snapshot in plain language. Use it when you need a quick answer to: "Is it running, blocked, done, or waiting for me?"

## Handle Human Feedback After Review

If Codex passes the task but manual testing finds a problem, do not edit the review report by hand. Merge the human feedback into a new combined review:

```bash
humanize-flow review-feedback <bd-id>
```

Without `--note` or `--from`, the command opens your editor. Write the feedback, save, and quit. Codex will re-read the prior review, the human notes, the handoff, the plan, acceptance criteria, git status, and diff, then produce a new verdict.

This is also the right path when Codex failed a review because the review scope was wrong, an unrelated file should be excluded, or missing manual evidence should change the result.

## Keep Provider Env Files Explicit

By default, Claude Code worker runs use Claude Code's normal global provider/auth configuration. Use an env file only when you intentionally want a project-specific provider:

```bash
humanize-flow run <bd-id> --env-file .humanize-flow/claude-provider.env
```

Best practices:

- Keep token-bearing env files untracked.
- Prefer one project-specific env file per provider experiment.
- Use `--no-env-file` when you want to ignore a configured default.
- Run `humanize-flow status --ai` after provider failures to see whether the workflow can be resumed.

## Commit And PR Discipline

Run delivery commands only after review and human verification:

```bash
humanize-flow review <bd-id>
humanize-flow verify <bd-id>
humanize-flow commit
humanize-flow push
humanize-flow pr
```

`commit` asks Codex to select the files that belong together, shows the selected patch in a pager, and commits only those paths. Use `--yes` only when you are comfortable skipping the preview confirmation.

`pr` uses GitHub CLI (`gh`) and prints the created PR URL. The PR body should explain WHY first: context, user or maintainer impact, constraints, decision rationale, then implementation details. Passing review reports' `Human verification guide` sections are included as reviewer-facing validation context.

## Practical Recovery Rules

- If YOLO stops after a transient provider/network problem, rerun the copyable `humanize-flow run ... --yolo` command printed in the error.
- If status says a task is ready, continue with the suggested `humanize-flow run ...` command.
- If the latest review is `changes_requested` or `blocked`, run `humanize-flow run <bd-id>` again after reading the findings.
- If the latest review is `pass`, complete manual verification and run `humanize-flow verify <bd-id>`.
- If the latest review is `unparseable`, regenerate the review or use `review-feedback`; new reports should include the `Humanize-Flow-Verdict:` line.
