# Security

humanize-flow coordinates tools that can read files, write files, and run commands. The workflow uses explicit role boundaries and approval gates to reduce risk.

## Safe defaults

- Planner does not edit implementation code.
- Worker requires an approved handoff.
- Reviewer does not implement fixes.
- Planner, commit, PR, and worker flows do not default to full Codex sandbox bypass.
- Codex worker runs are opt-in with `worker.provider=codex`, only support `run --yolo`, and run with Codex yolo permissions because implementation must be unattended.
- Codex review and review-feedback default to yolo mode with `--dangerously-bypass-approvals-and-sandbox` to avoid approval prompts blocking the review loop.
- Claude Code worker runs default to permission mode `bypassPermissions` so approved automation is not blocked by Claude Code permission prompts or auto-classifier outages.
- Claude Code worker runs default to `claude.humanize=required`; if humanize is unavailable, lower the mode explicitly instead of silently bypassing the loop.

## Approval gate

Implementation should not begin until the handoff contains:

```json
"approval": {
  "status": "approved"
}
```

Brief Beads descriptions are not enough authority for implementation. Worker and reviewer flows must read the approved handoff plus `plan.md` and `acceptance.md`; missing artifacts should stop implementation or block review.

## Permission guidance

Use least privilege for planning: `codex exec --sandbox workspace-write` is enough to write planning artifacts. Review and review-feedback default to yolo mode because they need reliable repository inspection and may write review artifacts without stopping for approval prompts. This passes Codex `--dangerously-bypass-approvals-and-sandbox`, so use it only in trusted, externally isolated repositories. You can reduce that default with `humanize-flow config set review.yolo false` or `HUMANIZE_FLOW_REVIEW_YOLO=false`, and then control the sandbox with `humanize-flow config set review.sandbox workspace-write`, `HUMANIZE_FLOW_REVIEW_SANDBOX=workspace-write`, or a one-run override such as `humanize-flow review <id> --sandbox read-only`.

For Claude Code, the default worker permission mode is `bypassPermissions` so approved tasks can proceed fully automatically after the Humanize Flow handoff is approved. Use this default only in repositories and worktrees you trust. Lower it with `humanize-flow run <id> --permission-mode auto`, `HUMANIZE_FLOW_CLAUDE_PERMISSION_MODE=auto`, or `humanize-flow config set claude.permission_mode auto` when you want Claude Code's auto classifier to gate actions.

The default humanize mode is `required`. This means `humanize-flow run` preflights for a humanize command, Claude plugin, or installed Codex humanize skill script, and the worker prompt requires Claude to start humanize/RLCR before editing code. Use `humanize-flow config set claude.humanize auto` for an advisory mode, or `off` only when you intentionally want direct implementation plus Humanize Flow review.

Codex worker mode does not run humanize/RLCR. Use it only when you intentionally want `run --yolo` to spend Codex quota instead of Claude Code quota: `humanize-flow config set worker.provider codex`. It keeps the final Codex review and human verification gates, but implementation and review are both Codex-family calls, so treat the human verification guide as mandatory.

Set `HUMANIZE_FLOW_CLAUDE_PERMISSION_MODE` or `humanize-flow config set claude.permission_mode <mode>` to match your local policy.

## Secrets

Never commit:

- API keys,
- auth files,
- `.env` files,
- private repository credentials,
- local tool caches containing credentials.

## Public project hygiene

Before publishing a package, inspect the zip:

```bash
unzip -l humanize-flow.zip | less
```

Ensure it does not include local `.humanize-flow/runs`, auth files, or private project data.
