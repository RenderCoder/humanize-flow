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

它不应该静默扩大范围。发现的新工作应按项目策略创建新的 Beads issue 或作为 reviewer finding 记录。

## `run-next` 行为

`humanize-flow run-next` 会优先选择已批准 handoff 中出现的 ready Beads 任务。这样即使导入任务没有 `humanize-flow` 标签，也可以被选中。如果没有这类任务，它会回退到带 `humanize-flow` 标签的任务，再回退到第一个 ready 任务。

## Review 使用

Reviewer 应把 Beads 数据作为事实来源之一，但也必须检查已批准 handoff 和 git diff。
