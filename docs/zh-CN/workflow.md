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
docs/humanize-flow/<slug>/jira-requirement.md
docs/humanize-flow/<slug>/plan.md
docs/humanize-flow/<slug>/acceptance.md
docs/humanize-flow/<slug>/bd-plan.md
.humanize-flow/handoffs/<slug>.json
```

面向人类的生成产物默认使用英文。使用 `humanize-flow i18n zh` 可把完整链路切换到简体中文，包括 `jira-requirement.md`、`bd-plan.md`、handoff prose，以及生成的 Beads epic/task 标题、描述和验收标准。机器可读的 JSON 字段名、枚举值、label、路径、命令、API 名称、Beads ID 和代码标识符保持原始形式。

`jira-requirement.md` 是面向协作的需求文档，适合贴到 Jira 类内部系统中。它会先解释 WHY/context，用非工程同事也能理解的语言说明需求，并在需要时把技术细节单独拆到技术说明部分。

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

这条路径会把 `bd show <bd-id> --json` 保存为 `bd-source.json`，并写入一个链接已有任务的 handoff。原始任务文本保留在 `bd-source.json`，生成的 request、Jira 风格需求、plan、acceptance、`bd-plan.md` 和 handoff 任务 prose 遵循当前工作流语言。通常不需要创建 Beads 任务，因为任务已经存在。

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

批准后的日常推荐顺序：

```bash
humanize-flow run-next
humanize-flow review <bd-id>
humanize-flow verify <bd-id>
```

希望 Claude Code 使用默认 humanize/RLCR 实现路径时，用普通 `run`。只有在 handoff 范围清楚、worktree 可信，并且希望 Humanize Flow 接管完整 Claude + Codex review 闭环时，才使用 `run --yolo`。选择建议见 [最佳实践](best-practices.md)。

执行下一个 ready 的 Humanize Flow 任务：

```bash
humanize-flow run-next
```

或者指定任务：

```bash
humanize-flow run <bd-id>
```

Worker 会读取 Beads 任务、已批准 handoff、plan 和 acceptance criteria。Beads 文本可以刻意保持简洁；详细执行契约在 Markdown 产物里。如果缺少已批准 handoff、`plan.md` 或 `acceptance.md`，worker 应该停止，而不是只根据 Beads 任务实现。

默认 worker 使用 `claude.humanize=required`。CLI 会在启动前检查 humanize 命令、Claude 插件或已安装的 Codex humanize skill 脚本，生成的 Claude prompt 会要求在改代码前从已批准 plan 启动 humanize/RLCR。如果某个任务所在环境无法运行 humanize，需要显式降低模式：

```bash
humanize-flow run <bd-id> --humanize-mode auto
humanize-flow run <bd-id> --no-humanize
humanize-flow config set claude.humanize auto
```

对于已批准的 handoff，也可以用 YOLO 模式自动运行实现和 review 闭环：

```bash
humanize-flow run <bd-id> --yolo
humanize-flow run <bd-id> --yolo --max-round 5
humanize-flow run <handoff-slug-or-epic-id> --yolo --review-at-end
```

YOLO 模式会强制 Claude Code 权限模式为 `bypassPermissions`，强制 `--humanize-mode off` 以避免嵌套 review 循环，强制 Codex review 使用 yolo 模式，并重复 Claude 修正 + Codex review，直到 review verdict 为 `pass` 或达到最大轮数。默认每个目标任务最多 3 轮。如果传入 handoff slug 或 Beads Epic ID，YOLO 会在每个子任务前重新查询 `bd ready --json`，按 Beads ready 顺序选择属于该 handoff 的下一个 ready 子任务；子任务 review 通过后会关闭该 Beads 任务，让依赖关系解锁；默认每次 Codex review 只审刚完成的子任务，而不是审整个 Epic。handoff 只限制范围，不施加静态子任务顺序。

当 per-child review 成本太高，或者你希望 Codex 在所有子任务实现后从完整 Epic 角度验收时，可以加 `--review-at-end`。该模式会把子任务以“已实现，等待最终 review”的 reason 关闭，然后针对 handoff slug 或 Epic ID 运行一次全局 final review/correction 循环。重试时，YOLO 会先从已经关闭的 Beads 子任务恢复进度，并继续已标记为 `in_progress` 的 handoff 子任务，再查询下一个 ready 子任务。它更快、视角更整体，但问题会延迟到最后才暴露。

## 5. 用 Codex 审查

```bash
humanize-flow review <bd-id>
```

Reviewer 会对照批准的产物进行审查，并返回：

- `pass`
- `changes_requested`
- `blocked`

每份 review 报告还必须包含一行给程序解析的 ASCII verdict，例如：

```text
Humanize-Flow-Verdict: pass
```

这一行只能使用 `pass`、`changes_requested` 或 `blocked` 三个值之一。报告正文继续遵循用户配置的 i18n 语言，但这一行故意不翻译，保证 `run --yolo`、`status`、`verify` 和 PR 验证指南收集逻辑都能稳定解析结果。

缺少 handoff、plan 或 acceptance 证据时应该返回 `blocked`，而不是 `pass`。

Codex review 和 review-feedback 默认使用 yolo 模式，也就是传给 Codex `--dangerously-bypass-approvals-and-sandbox`，避免权限确认提示阻塞循环。需要更严格隔离时，可用 `humanize-flow config set review.yolo false`、`HUMANIZE_FLOW_REVIEW_YOLO=false` 或 `--no-yolo`；然后再用 `humanize-flow config set review.sandbox <mode>`、`HUMANIZE_FLOW_REVIEW_SANDBOX` 或 `--sandbox <mode>` 控制 sandbox。

当 verdict 是 `pass` 时，报告会包含人类验证指南。最终 git 交付前，先完成人工测试步骤和检查清单。Codex pass 表示代码满足被审查的契约；它不是立即提交的命令。

如果手工测试发现问题，或者人类判断某个 Codex finding 是因为 scope 或上下文缺失导致的，可以把反馈合并成新的 review。不传 `--note` 或 `--from` 时，命令会打开你的编辑器，保存退出后继续执行：

```bash
humanize-flow review-feedback <bd-id>
```

更新后的 review 会综合前一次 Codex review 和人类反馈，并重新判断 verdict。它可以把 `pass` 改成 `changes_requested`，也可以在人类反馈提供有效 scope 校正或缺失证据时，把 `changes_requested` / `blocked` 改成 `pass`。

## 6. 迭代或关闭

如果需要修改，把 review findings 交给 worker 继续修。如果 review 通过，则按项目策略关闭 Beads 任务。

最后交付 git 变更时，先 stage 需要提交的文件，然后运行：

```bash
humanize-flow commit
humanize-flow push
humanize-flow pr
```
