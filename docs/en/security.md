# Security

humanize-flow coordinates tools that can read files, write files, and run commands. The workflow uses explicit role boundaries and approval gates to reduce risk.

## Safe defaults

- Planner does not edit implementation code.
- Worker requires an approved handoff.
- Reviewer does not implement fixes.
- Planner, commit, PR, and worker flows do not default to full Codex sandbox bypass.
- Codex review and review-feedback default to yolo mode with `--dangerously-bypass-approvals-and-sandbox` to avoid approval prompts blocking the review loop.
- Claude Code worker runs default to permission mode `auto`, not full permission bypass.
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

For Claude Code, the default worker permission mode is `auto` so approved tasks can proceed without prompting for every file edit. This is intentionally different from `bypassPermissions` or `--dangerously-skip-permissions`, which should remain an explicit local choice only.

The default humanize mode is `required`. This means `humanize-flow run` preflights for a humanize command, Claude plugin, or installed Codex humanize skill script, and the worker prompt requires Claude to start humanize/RLCR before editing code. Use `humanize-flow config set claude.humanize auto` for an advisory mode, or `off` only when you intentionally want direct implementation plus Humanize Flow review.

Set `HUMANIZE_FLOW_CLAUDE_PERMISSION_MODE` or `humanize-flow config set claude.permission_mode <mode>` to match your local policy. Avoid dangerous permission bypass modes as defaults.

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
