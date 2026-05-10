# 安全

humanize-flow 会协调能读取文件、写入文件和运行命令的工具。它通过明确角色边界和批准门禁来降低风险。

## 安全默认值

- Planner 不编辑实现代码。
- Worker 需要已批准 handoff。
- Reviewer 不实现修复。
- Planner、commit、PR 和 worker 流程默认不会完全绕过 Codex sandbox。
- Codex review 和 review-feedback 默认使用 yolo 模式，也就是 `--dangerously-bypass-approvals-and-sandbox`，避免 review 循环被权限提示阻塞。
- Claude Code worker 默认使用权限模式 `bypassPermissions`，这样已批准的自动化不会被 Claude Code 权限提示或 auto classifier 临时不可用阻塞。
- Claude Code worker 默认使用 `claude.humanize=required`；如果 humanize 不可用，应显式降低模式，而不是静默绕过循环。

## 批准门禁

实现开始前，handoff 应包含：

```json
"approval": {
  "status": "approved"
}
```

简短 Beads description 不足以授权实现。Worker 和 reviewer 流程必须读取已批准 handoff、`plan.md` 和 `acceptance.md`；缺失这些产物时应该停止实现或阻塞 review。

## 权限建议

规划阶段使用最小权限：`codex exec --sandbox workspace-write` 通常足够写规划产物。Review 和 review-feedback 默认使用 yolo 模式，因为它们需要稳定检查仓库并写入 review 产物，而且不能被权限确认提示打断。该模式会传给 Codex `--dangerously-bypass-approvals-and-sandbox`，所以只应在可信、外部隔离的仓库环境里使用。可以用 `humanize-flow config set review.yolo false` 或 `HUMANIZE_FLOW_REVIEW_YOLO=false` 降低默认权限，然后通过 `humanize-flow config set review.sandbox workspace-write`、`HUMANIZE_FLOW_REVIEW_SANDBOX=workspace-write` 或 `humanize-flow review <id> --sandbox read-only` 这类单次覆盖控制 sandbox。

Claude Code worker 默认权限模式是 `bypassPermissions`，这样 Humanize Flow handoff 被批准之后，任务可以全自动执行。这个默认值只适合你信任的仓库和 worktree。需要让 Claude Code 的 auto classifier 继续做动作门禁时，可用 `humanize-flow run <id> --permission-mode auto`、`HUMANIZE_FLOW_CLAUDE_PERMISSION_MODE=auto` 或 `humanize-flow config set claude.permission_mode auto` 降低权限。

默认 humanize 模式是 `required`。这意味着 `humanize-flow run` 会预检 humanize 命令、Claude 插件或已安装的 Codex humanize skill 脚本，worker prompt 会要求 Claude 在改代码前启动 humanize/RLCR。需要建议模式时使用 `humanize-flow config set claude.humanize auto`；只有明确希望直接实现并交给 Humanize Flow review 时才设为 `off`。

可以通过 `HUMANIZE_FLOW_CLAUDE_PERMISSION_MODE` 或 `humanize-flow config set claude.permission_mode <mode>` 匹配你的本地权限策略。

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
