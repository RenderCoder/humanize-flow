# Skill 参考

## `humanize-flow-planner`

用于**新需求规划**的 Codex skill：讨论需求、制定计划、生成 Markdown 产物、准备 Beads 任务，并创建 draft handoff。

当用户从一个还没有写入 Beads 的需求开始时，使用它。

调用方式：

```text
$humanize-flow-planner
```

核心产物：

```text
docs/humanize-flow/<slug>/request.md
docs/humanize-flow/<slug>/plan.md
docs/humanize-flow/<slug>/acceptance.md
docs/humanize-flow/<slug>/bd-plan.md
.humanize-flow/handoffs/<slug>.json
```

面向人工审核的 Markdown 产物遵循工作流语言配置，默认使用英文。JSON 字段名、枚举值、label、路径、命令、API 名称、Beads ID 和代码标识符等机器可读字面量保持原始形式。

## `humanize-flow-bd-planner`

用于**已有 Beads 任务规划**的 Codex skill。

当用户已经有 Beads 任务 ID，希望 Codex 读取该任务、确认缺失细节，并生成 Humanize Flow Markdown 和 JSON 产物，同时不重复创建任务时，使用它。

调用方式：

```text
$humanize-flow-bd-planner
```

示例 prompt：

```text
请读取 Beads 任务 bd-1234，和我确认缺失细节，然后创建 Humanize Flow Markdown 产物和 handoff JSON。不要重复创建 Beads 任务，也不要实现代码。
```

核心产物：

```text
docs/humanize-flow/<slug>/bd-source.json
docs/humanize-flow/<slug>/request.md
docs/humanize-flow/<slug>/plan.md
docs/humanize-flow/<slug>/acceptance.md
docs/humanize-flow/<slug>/bd-plan.md
.humanize-flow/handoffs/<slug>.json
```

面向人工审核的 Markdown 产物遵循工作流语言配置，默认使用英文。来源任务 ID 和机器可读字面量保持原始形式。

关键 handoff 字段：

```json
{
  "source": {
    "type": "beads",
    "bd_id": "bd-1234"
  },
  "bd": {
    "materialized": true
  },
  "execution": {
    "current_bd_id": "bd-1234"
  }
}
```

批准后的下一步命令：

```bash
humanize-flow approve <slug>
humanize-flow run bd-1234
```

## `humanize-flow-worker`

Claude Code skill，用于实现一个已批准的 Beads 任务。

交互式调用：

```text
/humanize-flow-worker
```

CLI 也会通过 `claude -p` 传入 worker skill 指令，因为并非所有 Claude Code 非交互场景都支持 slash invocation。

默认情况下，CLI worker 运行会在内部使用 Claude Code `stream-json`，包含 hook events 和 partial message chunks，然后在终端渲染为人类可读的进展日志。原始事件流仍会保存为 `claude-final.jsonl`。需要完整 Claude Code 交互会话时，使用 `humanize-flow run <bd-id> --interactive`。

## `humanize-flow-reviewer`

Codex skill，用于对一个已实现任务做最终审查。

调用方式：

```text
$humanize-flow-reviewer
```

Reviewer 会返回 Markdown 报告，verdict 为 `pass`、`changes_requested` 或 `blocked`。

## Skill 安装位置

用户级安装：

```text
~/.agents/skills/humanize-flow-planner
~/.agents/skills/humanize-flow-bd-planner
~/.agents/skills/humanize-flow-reviewer
~/.claude/skills/humanize-flow-worker
```

项目级安装：

```text
.agents/skills/humanize-flow-planner
.agents/skills/humanize-flow-bd-planner
.agents/skills/humanize-flow-reviewer
.claude/skills/humanize-flow-worker
```
