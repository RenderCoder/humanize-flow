# 最佳实践

这份指南说明 Humanize Flow 日常应该怎么用。目标是让自动化真正帮你推进工作，同时不隐藏关键的人类决策点。

## 日常推荐路径

普通功能开发优先使用保守路径：

```bash
humanize-flow init --with-bd
humanize-flow approve <slug> --materialize-bd
humanize-flow run-next
humanize-flow review <bd-id>
humanize-flow verify <bd-id>
humanize-flow commit
humanize-flow push
humanize-flow pr
```

这条路径的边界最清楚：

- Codex 负责规划和 review。
- 你在实现开始前批准 handoff。
- Claude Code 一次只实现一个 Beads 任务。
- Codex 对照批准的产物审查当前任务。
- 你在交付前完成人工验证指南。

如果你明确知道要跑哪个任务，优先使用实际 Beads 任务 ID：

```bash
humanize-flow run <bd-id>
```

如果你希望 Humanize Flow 从 ready 队列中选择任务，并在存在多个候选分组时提示你选择，用 `run-next`。

## 什么时候使用 YOLO

在可信 worktree 中，如果希望 CLI 自动推进实现和 Codex review，可以使用 YOLO：

```bash
humanize-flow run <handoff-slug-or-epic-id> --yolo --max-round 3 --retry 5 --retry-delay 20
```

对于内聚度高的大 Epic，也可以用一次最终全局 review 换取更少的中间等待：

```bash
humanize-flow run <handoff-slug-or-epic-id> --yolo --review-at-end --max-round 3
```

YOLO 适合：

- handoff 范围明确、验收标准清楚；
- 子任务依赖已经用 Beads 表达；
- 仓库可信，可以接受高自动化权限；
- 任务运行时间较长，希望网络或服务商瞬断能自动重试。

如果更看重早发现问题、子任务风险较高，或者不希望下游任务基于未 review 的结果继续开发，保留默认 per-child review。如果 Epic 内聚度高、中间 review 大多是噪音，或者希望 Codex 从最终集成 diff 和跨任务行为角度判断，就使用 `--review-at-end`。在最终 review 模式下，`--max-round` 作用于所有子任务实现完成后的全局 review/correction 循环。

如果 YOLO Epic 运行中断，重新执行同一条命令即可。Humanize Flow 会先从 Beads 已关闭子任务恢复完成进度，再选择下一个 ready 子任务，所以重试应继续推进，而不是从 Epic 队列开头重来。

YOLO 不能替代最终人工验证。review 通过后，先完成报告里的 `Human verification guide`，再记录人工验证：

```bash
humanize-flow verify <bd-id>
```

之后再运行 `commit`、`push`、`pr` 等交付命令。

## 避免嵌套 Review 循环

默认非 YOLO 的 `run` 使用 `claude.humanize=required`，也就是要求 Claude Code 在改代码前启动 humanize/RLCR。

YOLO 会故意强制 `--humanize-mode off`。这是为了避免两个独立 review 循环互相干扰：

- 外层循环：Humanize Flow 调 Claude Code，实现后调 Codex review，需要时再让 Claude 修正。
- 内层循环：Claude Code 内部的 humanize/RLCR。

日常确定性自动化建议一次只用一个循环：

- 希望 Claude Code 在实现过程中使用 humanize/RLCR 时，用普通 `run`。
- 希望 Humanize Flow 接管完整 Claude + Codex review 闭环时，用 `run --yolo`。

## 保持 Review 可被程序解析

Review 报告必须以一行稳定 verdict 开头：

```text
Humanize-Flow-Verdict: pass
```

取值只能是：

- `pass`
- `changes_requested`
- `blocked`

报告正文继续遵循你配置的 i18n 语言，但这一行不要翻译。Humanize Flow 会用它驱动 `run --yolo`、`status`、`verify` 和 PR 验证指南收集逻辑。

## 先用 Status 判断是否卡住

当终端看起来没动，或者你怀疑流程停住时，先运行：

```bash
humanize-flow status
humanize-flow status --ai
```

`status` 给出确定性的状态视图：最近 run、最近 review、Beads ready 队列、handoff 状态、warning 和建议下一步。

`status --ai` 会让 Codex 用说人话的方式解释这份快照。你想快速判断“还在跑、卡住了、完成了，还是等我操作”时，用它最合适。

## Review 后处理人工反馈

如果 Codex 判定通过，但手工测试发现问题，不要手改 review 报告。使用下面的命令把人工反馈合并成新的综合 review：

```bash
humanize-flow review-feedback <bd-id>
```

不传 `--note` 或 `--from` 时，命令会打开编辑器。写下反馈，保存退出即可。Codex 会重新读取前一次 review、人工反馈、handoff、plan、acceptance criteria、git status 和 diff，然后给出新的 verdict。

如果 Codex 因为 review scope 错误、无关文件被误纳入、或缺少人工证据而判失败，也应该用 `review-feedback` 校正。

## Provider Env 文件保持显式

默认情况下，Claude Code worker 使用 Claude Code 自己的全局 provider/auth 配置。只有你明确想在某个项目中测试特定 provider 时，才使用 env 文件：

```bash
humanize-flow run <bd-id> --env-file .humanize-flow/claude-provider.env
```

建议：

- 包含 token 的 env 文件保持未跟踪。
- 每个 provider 实验尽量使用一个项目专用 env 文件。
- 想忽略已配置默认 env 文件时使用 `--no-env-file`。
- provider 失败后运行 `humanize-flow status --ai`，判断流程是否可以继续。

## Commit 和 PR 纪律

只有完成 review 和人工验证后再交付：

```bash
humanize-flow review <bd-id>
humanize-flow verify <bd-id>
humanize-flow commit
humanize-flow push
humanize-flow pr
```

`commit` 会让 Codex 判断哪些文件应该一起提交，用 pager 展示被选中的 patch，然后只提交这些路径。只有你确定不需要预览确认时才用 `--yes`。

`pr` 使用 GitHub CLI (`gh`)，并会打印创建后的 PR 链接。PR 正文应该先讲 WHY：背景、用户或维护者影响、约束、决策理由，然后再讲实现细节。通过 review 报告中的 `Human verification guide` 会被纳入 PR，作为 reviewer 可参考的验证上下文。

## 实用恢复规则

- 如果 YOLO 因 provider 或网络瞬断停止，复制错误里打印的 `humanize-flow run ... --yolo` 命令稍后重试。
- 如果 status 显示某个任务 ready，按建议的 `humanize-flow run ...` 命令继续。
- 如果最新 review 是 `changes_requested` 或 `blocked`，读完 findings 后再运行 `humanize-flow run <bd-id>` 修正。
- 如果最新 review 是 `pass`，完成人工验证并运行 `humanize-flow verify <bd-id>`。
- 如果最新 review 是 `unparseable`，重新生成 review 或使用 `review-feedback`；新的报告应包含 `Humanize-Flow-Verdict:` 行。
