# Security

humanize-flow coordinates tools that can read files, write files, and run commands. The workflow uses explicit role boundaries and approval gates to reduce risk.

## Safe defaults

- Planner does not edit implementation code.
- Worker requires an approved handoff.
- Reviewer does not implement fixes.
- CLI does not default to full-access sandbox modes.
- Claude Code worker runs default to permission mode `auto`, not full permission bypass.
- humanize/RLCR is optional and should not require unsafe permissions by default.

## Approval gate

Implementation should not begin until the handoff contains:

```json
"approval": {
  "status": "approved"
}
```

## Permission guidance

Use least privilege. For planning, `codex exec --sandbox workspace-write` is enough to write planning artifacts. For review, read-only behavior is preferred when practical.

For Claude Code, the default worker permission mode is `auto` so approved tasks can proceed without prompting for every file edit. This is intentionally different from `bypassPermissions` or `--dangerously-skip-permissions`, which should remain an explicit local choice only.

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
