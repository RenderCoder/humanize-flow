# Beads 集成

humanize-flow 使用 Beads 作为任务记忆和依赖层。

## 为什么使用 Beads

Markdown 计划适合人类阅读，但 agent 需要队列和依赖图。Beads 提供 ready task 选择、任务详情、依赖关系和 JSON 输出。

## 标签

由新需求 planner 创建的 Humanize Flow 任务建议包含：

- `humanize-flow`
- slug，例如 `undo-redo`

可选标签：

- `planner-created`
- `imported-bd-task`
- `humanize-preferred`
- 区域标签，例如 `frontend`、`backend`、`tests` 或 `docs`

通过 `humanize-flow-bd-planner` 导入的已有任务在执行前不一定需要重新打标签，因为 handoff 会记录它的 `bd_id`。如果你的项目策略允许，补充 `humanize-flow` 和 slug 标签仍然有助于队列可见性。

生成的 Beads prose 遵循 `humanize-flow i18n`：新需求 epic/task 标题、描述和验收标准会使用当前工作流语言。导入的 Beads 原始文本保留在 `bd-source.json`，但生成的规划和 handoff 任务 prose 仍应使用当前配置语言。

## 新需求任务创建

标准 planner 会在 handoff manifest 中准备 Beads 任务。批准后执行：

```bash
humanize-flow approve <slug> --materialize-bd
```

或者：

```bash
humanize-flow materialize-bd <slug>
```

## 已有任务规划

当需求已经存储在 Beads 中时，使用：

```bash
humanize-flow plan-from-bd <bd-id> --slug <slug>
```

或者调用：

```text
$humanize-flow-bd-planner
```

这条路径会执行：

```bash
bd show <bd-id> --json
```

并保存为：

```text
docs/humanize-flow/<slug>/bd-source.json
```

handoff 应包含：

```json
{
  "source": {
    "type": "beads",
    "bd_id": "<bd-id>"
  },
  "bd": {
    "materialized": true
  },
  "execution": {
    "current_bd_id": "<bd-id>"
  }
}
```

这表示 Beads 任务已经存在，不应该再次创建。批准命令是：

```bash
humanize-flow approve <slug>
```

然后执行：

```bash
humanize-flow run <bd-id>
```

## Worker 使用

Worker 应读取任务：

```bash
bd show <bd-id> --json
```

Beads 任务是队列记忆，不是完整实现契约。由 Humanize Flow 创建的 Beads description 会在路径已知时链接回 handoff、request、plan、acceptance criteria 和 Beads plan。Worker 必须读取已批准 handoff、`plan.md` 和 `acceptance.md`；如果这些产物缺失，应该停止，而不是只根据简短 Beads 文本实现。

它不应该静默扩大范围。发现的新工作应按项目策略创建新的 Beads issue 或作为 reviewer finding 记录。

## `run-next` 行为

`humanize-flow run-next` 仍会按优先级排列 ready Beads 任务：先选择已批准 handoff 中出现的任务，再选择带 `humanize-flow` 标签的任务，最后才是其他 ready 任务。当 stdin 是交互式终端且存在多个 ready 任务或 Epic 分组时，它会先询问要运行哪个分组/任务，再启动 Claude Code。

在非交互脚本中，可设置 `HUMANIZE_FLOW_NONINTERACTIVE=1` 使用确定性的回退选择。

## Review 使用

Reviewer 应把 Beads 数据作为事实来源之一，但也必须检查已批准 handoff、`plan.md`、`acceptance.md` 和 git diff。如果已批准 Markdown 产物缺失，正确结论是 `blocked`。
