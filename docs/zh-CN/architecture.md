# 架构

humanize-flow 将规划、执行和审查分离，让多 agent 编码工作流更容易审计和恢复。

## 角色边界

| 角色 | 工具 | 职责 | 禁止事项 |
| --- | --- | --- | --- |
| 新需求 Planner | Codex | 讨论新需求、写计划、准备 Beads 图、创建 draft handoff | 实现代码或调用 Claude Code |
| 已有任务 Planner | Codex | 读取已有 Beads 任务 ID、确认缺失细节、写计划，并把 draft handoff 链接到原任务 | 重复创建任务或实现代码 |
| Approver | Human | 判断计划是否可以执行 | 不看清楚就批准 |
| Worker | Claude Code | 实现一个已批准 Beads 任务 | 扩大范围或 review 前关闭任务 |
| Reviewer | Codex | 对照 plan 和 acceptance criteria 审查 diff | 实现修复 |
| Orchestrator | `humanize-flow` CLI | 协调文件、状态、prompt 和工具调用 | 取代人工批准 |

## 产物层

### Markdown 层

`docs/humanize-flow/<slug>/` 下的 Markdown 面向人类，用来说明需求、Jira 风格协作需求、计划、验收标准、实现总结和审查报告。

面向人类的生成产物默认使用英文，可通过 `humanize-flow i18n <lang>` 切换。这包括 `jira-requirement.md` 和 `bd-plan.md` 等 Markdown 产物、handoff prose、Beads 标题/描述/验收标准、实现总结、review、PR 文本和 commit message 正文。路径、命令、API 名称、JSON 字段名、枚举值、label、Beads ID 和代码标识符等会被工具消费的技术字面量保持原始形式。

### Beads 层

Beads 存储可执行任务图。Agent 使用 `bd ready --json`、`bd show --json` 和依赖关系来选择安全的下一步工作。已有 Beads 任务可以通过 `humanize-flow-bd-planner` 导入工作流，而不需要重复创建 issue。导入的原始文本保留为 source data，生成的规划和 handoff 任务 prose 遵循当前工作流语言。

### Handoff 层

`.humanize-flow/handoffs/<slug>.json` 是 planner、worker、reviewer 和 CLI 之间的机器可读契约，包含路径、批准状态、Beads 任务定义、来源元数据和执行元数据。

## Handoff 状态机

```text
draft
  → approved
  → in_progress
  → review_requested
  → changes_requested → in_progress
  → complete
```

无法安全推进时可使用 `blocked`。

## 为什么不让 Codex 直接调用 Claude？

嵌套 agent 会让权限、日志和失败恢复变复杂。humanize-flow 把跨 agent 调用保留在 CLI 里。Skills 定义行为，CLI 负责调度。

## 默认 required 的 humanize 集成

humanize/RLCR 是默认 worker 路径。`claude.humanize=required` 会让 `humanize-flow run` 在检测不到 humanize 集成时 fail closed，并要求 Claude 在改代码前启动 RLCR。若某个仓库或环境无法支持 humanize，团队可以把单次运行或全局默认值降为 `auto` 或 `off`。
