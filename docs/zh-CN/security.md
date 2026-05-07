# 安全

humanize-flow 会协调能读取文件、写入文件和运行命令的工具。它通过明确角色边界和批准门禁来降低风险。

## 安全默认值

- Planner 不编辑实现代码。
- Worker 需要已批准 handoff。
- Reviewer 不实现修复。
- CLI 默认不使用 full-access sandbox 模式。
- Claude Code worker 默认使用权限模式 `auto`，不是完全绕过权限。
- humanize/RLCR 是可选增强，不应默认要求危险权限。

## 批准门禁

实现开始前，handoff 应包含：

```json
"approval": {
  "status": "approved"
}
```

## 权限建议

使用最小权限。规划阶段通常只需要 `codex exec --sandbox workspace-write` 来写规划产物。审查阶段优先采用只读行为。

Claude Code worker 默认权限模式是 `auto`，这样已批准任务可以顺畅执行，不需要每次文件编辑都询问。这和 `bypassPermissions` 或 `--dangerously-skip-permissions` 不同；后两者仍应只作为明确的本地选择。

可以通过 `HUMANIZE_FLOW_CLAUDE_PERMISSION_MODE` 或 `humanize-flow config set claude.permission_mode <mode>` 匹配你的本地权限策略。不要把危险的权限绕过模式作为默认值。

## Secrets

不要提交：

- API keys，
- auth files，
- `.env` files，
- 私有仓库凭据，
- 包含凭据的本地工具缓存。

## 公共项目卫生

发布前检查 zip：

```bash
unzip -l humanize-flow.zip | less
```

确认不包含本地 `.humanize-flow/runs`、认证文件或私有项目数据。
