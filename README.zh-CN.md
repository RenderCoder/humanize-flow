# humanize-flow

**humanize-flow** 是一个轻量级多 agent 编程工作流编排工具包：

```text
Codex 规划 → 人工确认 → Claude Code 执行 → Codex 审查
```

它适合这样的使用方式：让 Codex 理解需求和制定计划，让 Claude Code 具体改代码，让 Beads (`bd`) 保存任务状态和依赖，默认让 humanize/RLCR 在实现阶段提供迭代审查能力。

## 为什么需要它

复杂 AI 编程任务最容易失败的地方，是“规划、实现、审查”混在一起。humanize-flow 把边界固定下来：

- **Codex 负责规划**：必要时和你讨论需求，生成 Markdown 计划，准备 Beads 任务，写 handoff JSON。
- **人类负责确认**：没有明确批准前，不开始实现。
- **Claude Code 负责执行**：一次只执行一个已批准的任务，默认使用 humanize/RLCR，可按需关闭或改为自动模式。
- **Codex 负责审查**：对照计划、验收标准、测试和 git diff 进行 review。
- **CLI 负责编排**：安装、初始化、批准、创建 bd 任务、调用 worker、调用 reviewer、查看状态。

## 组件

| 组件 | 名称 | 作用 |
| --- | --- | --- |
| Codex skill | `humanize-flow-planner` | 从新需求开始讨论、生成 Markdown、准备 Beads 任务、写 draft handoff JSON。 |
| Codex skill | `humanize-flow-bd-planner` | 从已有 Beads 任务 ID 开始，和你确认缺失细节，生成 Markdown 和 handoff JSON，并链接原任务而不是重复创建任务。 |
| Claude Code skill | `humanize-flow-worker` | 执行一个已批准的 Beads 任务，并请求 review。 |
| Codex skill | `humanize-flow-reviewer` | 对照 handoff、计划、验收标准、测试和 git diff 进行审查。 |
| CLI | `humanize-flow` | 安装、初始化、批准、创建 Beads 任务、执行 worker、执行 review、查看状态。 |

## 安装

解压 release 后运行：

```bash
./install.sh --user
humanize-flow doctor
```

默认安装到：

```text
~/.agents/skills/humanize-flow-planner
~/.agents/skills/humanize-flow-bd-planner
~/.agents/skills/humanize-flow-reviewer
~/.claude/skills/humanize-flow-worker
~/.local/bin/humanize-flow
~/.local/share/humanize-flow
```

如果想安装为当前仓库专用 skill：

```bash
./install.sh --project
```

## 快速开始

在 git 仓库内：

```bash
humanize-flow init --with-bd
```

然后在 Codex 中交互式调用：

```text
$humanize-flow-planner

我想给编辑器增加 undo/redo 支持。请在必要时和我讨论不明确的需求，然后展示完整计划并准备 Humanize Flow 产物。不要实现代码。
```

确认计划后：

```bash
humanize-flow approve undo-redo --materialize-bd
humanize-flow run-next
humanize-flow run <bd-id> --yolo
humanize-flow review <bd-id>
humanize-flow review-feedback <bd-id>
humanize-flow commit
humanize-flow push
humanize-flow pr
```

Worker 默认使用 Claude Code print 模式，在终端显示适合人阅读的详细进展，模型为 `claude-sonnet-4-6`，权限模式为 `bypassPermissions`，并设置 `claude.humanize=required`。Codex planner/reviewer/commit/PR 默认使用你的正常 Codex 配置；如果设置了 `codex.model` 或 `codex.reasoning_effort`，则使用 Humanize Flow 配置值；review 和 review-feedback 默认使用 yolo 模式，也就是传给 Codex `--dangerously-bypass-approvals-and-sandbox`，可用 `review.yolo=false`、`HUMANIZE_FLOW_REVIEW_YOLO=false`、`--no-yolo`、`review.sandbox`、`HUMANIZE_FLOW_REVIEW_SANDBOX` 或 `--sandbox` 降低权限。需要让 Claude Code 回到 classifier gate 时，可用 `--permission-mode auto`、`HUMANIZE_FLOW_CLAUDE_PERMISSION_MODE=auto` 或 `humanize-flow config set claude.permission_mode auto` 降低权限。在 `required` 模式下，worker prompt 会要求 Claude 在改代码前基于已批准 plan 启动 humanize/RLCR；如果 humanize 不可用，可用 `--humanize-mode auto`、`--no-humanize`、`HUMANIZE_FLOW_CLAUDE_HUMANIZE` 或 `humanize-flow config set claude.humanize <mode>` 降低模式。CLI 会把原始 Claude `stream-json` 事件保存在 run 目录用于调试，但默认展示人类可读日志。如果希望在 Claude Code UI 中监督执行，可以运行：

```bash
humanize-flow run <bd-id> --interactive
```

对于已批准的 handoff，如果希望 CLI 自动闭环，可以运行 `humanize-flow run <bd-id> --yolo`。该模式会强制 Claude Code 权限模式为 `bypassPermissions`，强制 Codex review 使用 yolo 模式，并重复 Claude 修正 + Codex review，直到 review 通过或达到默认 3 轮上限。YOLO 会强制 `--humanize-mode off`，避免嵌套 review 循环。当目标是 handoff slug 或 Beads Epic ID 时，YOLO 会在每个子任务前重新查询 `bd ready --json`，选择属于该 handoff 的下一个 ready 子任务，保留 Beads 的 ready 排序，而不是使用 handoff 的静态子任务顺序。子任务 review 通过后，CLI 会关闭该 Beads 任务，让依赖关系解锁下一个 ready 任务。每次 Codex review 只审当前已完成的子任务，不能因为同一 Epic 下的兄弟任务尚未完成而判失败。可用 `--max-round N` 覆盖每个子任务的修正轮数上限。

Review 通过后，`humanize-flow commit` 每次都会让 Codex 从完整 working tree 判断哪些变更文件属于本次提交。已有 staged changes 只作为上下文参考，所以 Codex 可以纳入应该一起提交的 unstaged 路径，也可以排除误暂存的路径。CLI 会 stage 被选中的路径，起草 Lore commit message，并在确认后只提交这些被选中的路径。`humanize-flow push` 会推送当前分支；如果有多个 remote，会先让你选择。`humanize-flow pr` 会让 Codex 按当前工作流语言起草详细、专业的 GitHub PR 标题和正文，并要求 WHY/context 优先于 HOW/WHAT；它会把通过 review 中的 `Human verification guide` 纳入 PR，作为 reviewer 可参考的验证上下文，把草稿保存在 `.humanize-flow/runs/`，在多个 remote 时让你选择 GitHub 仓库，然后用 `gh pr create --repo` 创建 PR。

Codex `pass` review 会包含人类验证指南。提交/推送/创建 PR 前先完成人工检查清单。如果手工测试发现问题，或者人类校正了 review scope，运行 `humanize-flow review-feedback <bd-id>`；CLI 会打开你的编辑器填写反馈，然后生成一份 Codex + 人类反馈合并后的更新 verdict。

## 从已有 Beads 任务开始规划

如果需求已经写在 Beads 里，不需要重新输入。可以在 Codex 中调用专用 skill：

```text
$humanize-flow-bd-planner

请读取 Beads 任务 bd-1234，和我确认缺失细节，然后创建 Humanize Flow Markdown 产物和 handoff JSON。不要重复创建 Beads 任务，也不要实现代码。
```

也可以使用 CLI：

```bash
humanize-flow plan-from-bd bd-1234 --slug undo-redo
```

这个命令会把 `bd show bd-1234 --json` 保存到 `docs/humanize-flow/<slug>/bd-source.json`，在 `.humanize-flow/handoffs/<slug>.json` 中链接原始任务，通常下一步是：

```bash
humanize-flow approve <slug>
humanize-flow run bd-1234
humanize-flow review bd-1234
```

## 非交互规划

```bash
humanize-flow plan --slug undo-redo --from examples/minimal-feature-request.md
humanize-flow plan-from-bd bd-1234 --slug undo-redo
```

面向人类的生成产物默认使用英文。可以用 `humanize-flow i18n zh` 把完整链路切换到简体中文，包括 `bd-plan.md` 在内的规划文档、handoff prose、实际创建到 Beads 的 epic/task 标题、描述、验收标准、实现总结、review 报告、PR 文本和 commit message 正文。机器可读的 JSON 字段名、枚举值、label、路径、命令、API 名称、Beads ID 和代码标识符保持原始形式。

Beads 任务可以保持简洁，便于队列浏览。真正的执行契约不是简短的 Beads 文本本身：Claude Code worker prompt 要求读取已批准 handoff、`plan.md` 和 `acceptance.md`，Codex review 在这些产物缺失时会返回 blocked。

如果关键需求仍不明确，planner 应该写入 `docs/humanize-flow/<slug>/questions.md` 并停止，而不是替你做高影响决策。

## 产物模型

humanize-flow 把三类接口分开：

```text
Markdown        docs/humanize-flow/<slug>/...       给人审阅
Beads issues    bd ready / bd show / bd dep          给 agent 管任务状态
Handoff JSON    .humanize-flow/handoffs/<slug>.json  给脚本做确定性编排
```

handoff manifest 由 `schemas/handoff.schema.json` 约束。

## 依赖

CLI 本身需要：

- Bash
- Git
- Python 3
- GitHub CLI (`gh`)，用于 `humanize-flow pr`；创建 PR 前请先运行 `gh auth login -h github.com`
- 推荐安装 `jq`

推荐工作流工具：

- Codex CLI
- Claude Code CLI
- Beads (`bd`)
- humanize 插件或 skills，worker 默认要求可用

## 安全默认值

- planner 不修改业务实现代码。
- worker 拒绝执行未批准的 handoff。
- reviewer 不负责修复，只负责审查。
- Planner、commit、PR 和 worker 流程默认不会完全绕过 Codex sandbox。
- Codex review 和 review-feedback 默认使用 yolo 模式，也就是 `--dangerously-bypass-approvals-and-sandbox`，避免 review 循环被权限提示阻塞；需要更严格隔离时用 `review.yolo=false` 或 `--no-yolo` 降低权限。
- 高权限模式只应在可信、外部隔离的环境中使用。

## 文档

- 英文文档：`docs/en/`
- 简体中文文档：`docs/zh-CN/`

## 开发

```bash
make test
make package
```

生成的发布包是 `humanize-flow.zip`。

## 许可证

MIT
