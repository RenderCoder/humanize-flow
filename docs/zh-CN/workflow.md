# 工作流

humanize-flow 默认保留人工确认。Codex 负责规划和讨论；Claude Code 负责实现；Codex 再负责审查。人类负责批准从规划进入实现。

## 1. 初始化仓库

```bash
humanize-flow init --with-bd
```

会创建：

```text
.humanize-flow/
docs/humanize-flow/
```

使用 `--with-bd` 且 Beads 可用时，CLI 也会在需要时初始化 Beads。

## 2. 用 Codex 规划

在 Codex 中调用 planner skill：

```text
$humanize-flow-planner
```

然后描述需求。Planner 应该查看仓库上下文，在关键需求不清楚时和你讨论，并最终展示完整计划。它只写草稿产物，不实现代码。

预期规划产物：

```text
docs/humanize-flow/<slug>/request.md
docs/humanize-flow/<slug>/plan.md
docs/humanize-flow/<slug>/acceptance.md
docs/humanize-flow/<slug>/bd-plan.md
.humanize-flow/handoffs/<slug>.json
```

面向人类的生成产物默认使用英文。使用 `humanize-flow i18n zh` 可把完整链路切换到简体中文。机器可读的 JSON 字段名、枚举值、label、路径、命令、API 名称、Beads ID 和代码标识符保持原始形式。

非交互方式：

```bash
humanize-flow plan --slug <slug> --from <request-file>
```

如果仍有高影响的不确定点，planner 应该写出 `questions.md` 并停止，而不是随意发明一个风险较高的决定。

## 2b. 从已有 Beads 任务开始规划

如果需求已经在 Beads 里，使用已有任务路径，不需要重新输入需求。

Codex 交互流程：

```text
$humanize-flow-bd-planner

请读取 Beads 任务 <bd-id>，和我确认缺失细节，并创建 Humanize Flow 产物。不要重复创建 Beads 任务，也不要实现代码。
```

CLI 流程：

```bash
humanize-flow plan-from-bd <bd-id> --slug <slug>
```

这条路径会把 `bd show <bd-id> --json` 保存为 `bd-source.json`，并写入一个链接已有任务的 handoff。通常不需要创建 Beads 任务，因为任务已经存在。

## 3. 批准并创建 Beads 任务

阅读新需求计划后执行：

```bash
humanize-flow approve <slug> --materialize-bd
```

这会把 handoff 状态改为 `approved`，并根据 handoff 创建 Beads issue。

阅读已有 Beads 任务计划后执行：

```bash
humanize-flow approve <slug>
```

这只会批准 handoff，不会重复创建 Beads 任务，因为原任务已经被链接。

## 4. 用 Claude Code 实现

执行下一个 ready 的 Humanize Flow 任务：

```bash
humanize-flow run-next
```

或者指定任务：

```bash
humanize-flow run <bd-id>
```

Worker 会读取 Beads 任务、已批准 handoff、plan 和 acceptance criteria。Beads 文本可以刻意保持简洁；详细执行契约在 Markdown 产物里。如果缺少已批准 handoff、`plan.md` 或 `acceptance.md`，worker 应该停止，而不是只根据 Beads 任务实现。

## 5. 用 Codex 审查

```bash
humanize-flow review <bd-id>
```

Reviewer 会对照批准的产物进行审查，并返回：

- `pass`
- `changes_requested`
- `blocked`

缺少 handoff、plan 或 acceptance 证据时应该返回 `blocked`，而不是 `pass`。

## 6. 迭代或关闭

如果需要修改，把 review findings 交给 worker 继续修。如果 review 通过，则按项目策略关闭 Beads 任务。

最后交付 git 变更时，先 stage 需要提交的文件，然后运行：

```bash
humanize-flow commit
humanize-flow push
humanize-flow pr
```
