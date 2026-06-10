# CLI 参考

CLI 是轻量调度器，刻意使用 shell 实现，方便查看和修改。

推荐命令顺序和恢复规则见 [最佳实践](best-practices.md)。简要原则：日常开发用普通 `run` 加显式 `review`；可信自动化闭环用 `run --yolo`；怀疑卡住前先看 `status --ai`；交付前用 `verify` 记录人工验证。

## `humanize-flow help`

显示帮助。

## `humanize-flow version`

打印 CLI 版本。

## `humanize-flow paths`

显示仓库、状态目录、文档目录和 skill 路径。

## `humanize-flow doctor`

检查本地工具和已安装 skills。

```bash
humanize-flow doctor
```

## `humanize-flow init [--with-bd]`

在当前 git 仓库初始化 Humanize Flow 目录。

```bash
humanize-flow init
humanize-flow init --with-bd
```

## `humanize-flow plan`

用非交互方式运行 Codex planner。

```bash
humanize-flow plan --slug <slug> --from <request-file>
humanize-flow plan --slug <slug> --request "<request text>"
```

选项：

- `--sandbox <mode>`：传给 `codex exec` 的 sandbox 模式，默认 `workspace-write`。
- `--no-codex`：只写 planner prompt，不实际执行。

生成的 planner prompt 会包含当前工作流语言配置。默认是英文；使用 `humanize-flow i18n zh` 可切换到简体中文。语言策略会覆盖 `request.md`、`jira-requirement.md`、`plan.md`、`acceptance.md`、`bd-plan.md`、handoff prose，以及生成的 Beads epic/task 标题、描述和验收标准。

`jira-requirement.md` 是面向内部协作系统的 Jira 风格 Markdown 需求。它应先说明 WHY/context，再说明 HOW/WHAT；主体内容使用跨职能团队能理解的语言，必要时把技术细节单独放到技术说明部分。

## `humanize-flow plan-from-bd`

从已有 Beads 任务 ID 运行 Codex planner。

```bash
humanize-flow plan-from-bd <bd-id>
humanize-flow plan-from-bd <bd-id> --slug <slug>
humanize-flow from-bd <bd-id> --slug <slug>
```

该命令会执行：

```bash
bd show <bd-id> --json
```

并保存到：

```text
docs/humanize-flow/<slug>/bd-source.json
```

然后运行 `humanize-flow-bd-planner` skill。生成的 handoff 会用 `source.type=beads`、`source.bd_id=<bd-id>`、`bd.materialized=true` 和 `execution.current_bd_id=<bd-id>` 链接原始 Beads 任务。

选项：

- `--slug <slug>`：指定产物 slug；不指定时 CLI 会根据任务标题生成。
- `--sandbox <mode>`：传给 `codex exec` 的 sandbox 模式，默认 `workspace-write`。
- `--no-codex`：只捕获任务并写 planner prompt，不实际执行 Codex。

生成的 planner prompt 会把当前工作流语言应用到生成的规划 prose、`jira-requirement.md`、`bd-plan.md` 和 handoff `bd.*` 任务 prose，同时保留来源任务 ID 和机器可读字面量的原始形式。原始任务文本会保存在 `bd-source.json`。

这条路径通常下一步是 `humanize-flow approve <slug>`，而不是 `approve --materialize-bd`，因为 Beads 任务已经存在。

## `humanize-flow approve`

批准一个 handoff。

```bash
humanize-flow approve <slug>
humanize-flow approve <slug> --materialize-bd
```

## `humanize-flow materialize-bd`

从已批准 handoff 创建 Beads epic/tasks。

```bash
humanize-flow materialize-bd <slug>
```

## `humanize-flow run`

为一个 Beads 任务运行已配置的 worker。

```bash
humanize-flow run <bd-id>
humanize-flow run <bd-id> --yolo
humanize-flow run <bd-id> --yolo --max-round 5
humanize-flow run <bd-id> --yolo --retry 5 --retry-delay 20
humanize-flow run <handoff-slug-or-epic-id> --yolo
humanize-flow run <handoff-slug-or-epic-id> --yolo --review-each-task
humanize-flow run <bd-id> --interactive
humanize-flow run <bd-id> --model claude-sonnet-4-6
humanize-flow run <bd-id> --worker-provider codex --yolo
humanize-flow run <bd-id> --humanize-mode auto
humanize-flow run <bd-id> --no-humanize
humanize-flow run <bd-id> --env-file .humanize-flow/claude-provider.env
```

默认 worker 运行使用 Claude Code print 模式，内部使用 `stream-json`、partial message chunks、hook events、`--verbose`、模型 `claude-sonnet-4-6`、权限模式 `bypassPermissions`，并设置 `claude.humanize=required`。终端会显示人类可读的进展日志。run 目录中会同时保存 `claude-final.md` 人类可读日志和 `claude-final.jsonl` 原始 Claude 事件流。需要单次降低 Claude 权限时使用 `--permission-mode auto`，需要对单条命令降低权限时使用 `HUMANIZE_FLOW_CLAUDE_PERMISSION_MODE=auto`，需要全局降低权限时使用 `humanize-flow config set claude.permission_mode auto`。

humanize 模式包括：

- `required`：默认值。CLI 会预检 humanize 是否可用，worker prompt 会要求 Claude 在改代码前从已批准 plan 启动 humanize/RLCR。如果 humanize 无法启动，Claude 必须停止并报告阻塞原因。
- `auto`：复杂任务在可用时使用 humanize/RLCR；很小或不兼容的任务可以直接实现，但仍保留 Codex review 边界。
- `off`：不启动 humanize/RLCR。

单次运行可用 `--humanize`、`--humanize-mode required|auto|off` 或 `--no-humanize` 覆盖。全局默认值可用 `humanize-flow config set claude.humanize <mode>` 设置，单条命令也可用 `HUMANIZE_FLOW_CLAUDE_HUMANIZE` 覆盖。

Claude provider 环境文件是显式启用的。默认情况下，`run` 使用 Claude Code 进程环境和 Claude Code 自己的全局 provider/auth 配置，不会自动读取仓库里的 `.env`。单次运行可用 `--env-file <file>` 加载 provider 变量；单条 shell 命令可用 `HUMANIZE_FLOW_CLAUDE_ENV_FILE=<file>`；持久默认值可用 `humanize-flow config set claude.env_file <file>`。需要忽略已配置文件时使用 `--no-env-file`。相对路径会按仓库根目录解析。包含 token 的 env 文件应保持未跟踪。

`--yolo` 会针对已批准的 Humanize Flow handoff 启动 worker+Codex 闭环。它会强制 `--humanize-mode off` 以避免嵌套 humanize/RLCR review 循环，用 yolo 模式运行 Codex review，解析 review verdict，并把最新 review 作为下一轮修正目标，直到 verdict 为 `pass` 或达到 `--max-round`。默认最多 5 轮。

默认情况下，Epic/handoff YOLO 使用最终 review 调度。CLI 会先实现所有 ready 的 handoff 子任务，并把每个子任务以“已实现，等待最终 review”的 reason 关闭，让 Beads 依赖继续解锁；全部子任务完成后，再针对 handoff slug 或 Epic ID 运行一次全局 Codex review。如果最终 review 返回 `changes_requested` 或 `blocked`，CLI 会让 worker 做全局修正，再重新全局 review，直到 `pass` 或达到 `--max-round`。`--review-at-end` 和 `--final-review-only` 仍然可用，语义等同于默认行为。需要旧的逐子任务 review 节奏时，使用 `--review-each-task`。最终 review 更快，也能让 Codex 从整个 Epic 角度验收；代价是问题会更晚暴露。

`--max-round` 只计算业务修正轮数：一轮 worker 加一轮 Codex review。默认值来自 `yolo.max_round`，未设置时是 5。临时命令失败由 `--retry` 和 `--retry-delay` 处理。YOLO 会在放弃前重试 worker provider 调用、Codex review 调用、`bd ready` 和关闭 Beads 任务等阶段；这些重试不会消耗修正轮数。如果重试耗尽，错误信息会包含一条可复制的 `humanize-flow run ... --yolo` 命令，方便网络或服务商恢复后继续。

设置 `worker.provider=codex` 可以用 Codex 替代 Claude Code 执行 YOLO 实现。Codex worker 使用 `worker.codex.model` 和 `worker.codex.reasoning_effort`，默认分别是 `gpt-5.5` 和 `medium`。Codex worker 只支持 `run --yolo`；它不会启动 humanize/RLCR，也不支持 Claude 专属的交互/session 参数。

YOLO 只自动化实现和 Codex review，不会自动完成人工验证门禁。review `pass` 后，应先按报告里的 `Human verification guide` 完成人工测试，然后运行 `humanize-flow verify <bd-id>`，再执行 `commit`、`push`、`pr` 或 release 这类交付命令。

当目标是 handoff slug 或 Beads Epic ID 时，YOLO 会把 handoff 当作 Epic 队列处理。启动时，它会先把 Beads Epic 本身标记为 `in_progress`，读取 handoff 子任务，并从已经关闭的 Beads 子任务恢复进度，所以中断后重试不会丢失已完成子任务计数。如果剩余 handoff 子任务已经是 `in_progress`，YOLO 会先继续这个子任务，再查询 ready 队列；这可以处理 Beads 已把子任务移出 `ready` 但执行过程被中断的情况。每个其他剩余子任务开始前，它都会重新查询 `bd ready --json`，把 ready 集合和 handoff 中剩余子任务求交集，并按 Beads ready 顺序选择下一个 ready 子任务。handoff 只限制允许执行的子任务集合，不施加静态执行顺序；尚未 ready 的子任务会等 Beads 依赖解锁后再执行。使用默认最终 review 调度时，每个子任务实现后会以“等待最终 review”的 reason 关闭，让下游依赖可以先解锁，再做最终全局 review。使用 `--review-each-task` 时，每个子任务都有自己的 worker 修正循环和 Codex review，review 通过后 CLI 会在 close reason 中记录通过的 review artifact 路径。

使用 `--interactive` 可以用同一个 worker prompt 打开 Claude Code 交互会话。使用 `--text` 可以使用 Claude 的纯文本输出，不保存原始事件流。

## `humanize-flow run-next`

选择一个 ready 的 Beads 任务并运行 worker。

```bash
humanize-flow run-next
```

当存在多个 ready 任务或 Epic 分组，并且 stdin 是交互式终端时，CLI 会先询问要执行哪个分组/任务，再启动 Claude Code。脚本中可设置 `HUMANIZE_FLOW_NONINTERACTIVE=1` 使用确定性的回退选择。

## `humanize-flow config`

查看或修改 Humanize Flow 全局默认值。

```bash
humanize-flow config show
humanize-flow config get language
humanize-flow config set language zh
humanize-flow config get claude.model
humanize-flow config set claude.model claude-sonnet-4-6
humanize-flow config set claude.permission_mode bypassPermissions
humanize-flow config get claude.humanize
humanize-flow config set claude.humanize required
humanize-flow config get claude.env_file
humanize-flow config set claude.env_file .humanize-flow/claude-provider.env
humanize-flow config get worker.provider
humanize-flow config set worker.provider codex
humanize-flow config get worker.codex.model
humanize-flow config set worker.codex.model gpt-5.5
humanize-flow config get worker.codex.reasoning_effort
humanize-flow config set worker.codex.reasoning_effort medium
humanize-flow config get yolo.max_round
humanize-flow config set yolo.max_round 5
humanize-flow config get yolo.review_strategy
humanize-flow config set yolo.review_strategy final
humanize-flow config get codex.model
humanize-flow config set codex.model gpt-5.5
humanize-flow config get codex.reasoning_effort
humanize-flow config set codex.reasoning_effort high
humanize-flow config get review.yolo
humanize-flow config set review.yolo false
humanize-flow config get review.sandbox
humanize-flow config set review.sandbox workspace-write
```

全局配置保存在 `${XDG_CONFIG_HOME:-$HOME/.config}/humanize-flow/config.json`。环境变量仍可对单次命令覆盖配置值。

如果没有设置 `codex.model` 或 `codex.reasoning_effort`，Humanize Flow 会使用你正常 Codex 配置中的默认值。推理强度支持 `low`、`medium`、`high` 和 `xhigh`。

## `humanize-flow i18n`

查看或设置面向人类的生成产物语言。

```bash
humanize-flow i18n
humanize-flow i18n en
humanize-flow i18n zh
```

默认是 `en`。设置为 `zh` 会把完整链路切换到简体中文，包括 `jira-requirement.md` 和 `bd-plan.md` 在内的规划文档、handoff prose、实际创建到 Beads 的 epic/task 标题、描述、验收标准、实现总结、review 报告、PR 文本和 commit message 正文。机器可读字面量保持原始形式。

## `humanize-flow review`

为一个 Beads 任务运行 Codex reviewer。

```bash
humanize-flow review <bd-id>
humanize-flow review <handoff-slug>
humanize-flow review <bd-id> --no-yolo
humanize-flow review <bd-id> --sandbox workspace-write
```

尽量使用实际 Beads 任务 ID。也可以传 handoff slug，CLI 会先解析匹配的 handoff，再选择正确的 review 目录。

`review` 默认使用 yolo 模式，会传给 Codex `--dangerously-bypass-approvals-and-sandbox`，避免权限确认提示阻塞 review 循环。可用 `humanize-flow config set review.yolo false`、`HUMANIZE_FLOW_REVIEW_YOLO=false` 或单次 `--no-yolo` 关闭默认 yolo。关闭 yolo 后，可用 `humanize-flow config set review.sandbox <mode>` 或 `HUMANIZE_FLOW_REVIEW_SANDBOX` 修改 sandbox 默认值，也可用 `--sandbox <mode>` 覆盖单次运行。传入 `--sandbox` 也会自动关闭本次 yolo。支持的模式是 `read-only`、`workspace-write` 和 `danger-full-access`。

当 verdict 是 `pass` 时，review 报告会包含人类验证指南，包括手工测试步骤和提交/推送前检查清单。当 verdict 是 `changes_requested` 或 `blocked` 时，报告会包含人类校正选项，可继续交给 `review-feedback` 合并。

Review 报告还会包含一行给程序解析的 ASCII verdict，例如 `Humanize-Flow-Verdict: pass`。这一行不会被本地化；它是 `run --yolo`、`status`、`verify` 和 PR 验证指南收集逻辑使用的稳定契约。

## `humanize-flow verify`

记录人类已经完成某个任务或 handoff 的人工验证门禁。

```bash
humanize-flow verify <bd-id>
humanize-flow verify <handoff-slug>
humanize-flow verify <bd-id> --note "已在 staging 完成手工冒烟测试。"
humanize-flow verify <bd-id> --review docs/humanize-flow/<slug>/reviews/<review>.md
humanize-flow verify <bd-id> --yes
```

如果能找到最新通过的 review，`verify` 会把确认记录关联到该 review。如果没有 review，它会记录一份独立的人工验证，不再阻塞。只有显式传入 `--review FILE` 时，被选择的 review 必须是 `pass`；这样可以避免误把失败或无法解析的 review 关联为已确认。

`verify` 会在 `.humanize-flow/verifications/` 下写入本地确认记录；如果能匹配到 handoff，也会更新 handoff 的 `latest_human_verification` artifact。这就是“人工门禁已完成，可以进入交付命令”的显式信号。

## `humanize-flow review-feedback`

把人类手工测试反馈或 review 校正意见合并成一份新的 Codex review 报告。

```bash
humanize-flow review-feedback <bd-id>
humanize-flow review-feedback <bd-id> --note "手工测试发现空状态仍然重叠。"
humanize-flow review-feedback <bd-id> --from docs/manual-test-notes.md
humanize-flow review-feedback <handoff-slug> --review docs/humanize-flow/<slug>/reviews/<file>.md --from docs/manual-test-notes.md
humanize-flow review-feedback <bd-id> --no-yolo
humanize-flow review-feedback <bd-id> --sandbox workspace-write
```

不传 `--note` 或 `--from` 时，命令会打开 `${VISUAL:-${EDITOR:-vi}}`，让人类直接填写反馈。它会把人类反馈保存到 `.humanize-flow/runs/<timestamp>-review-feedback-*/human-feedback.md`，读取前一次 review、handoff、plan、acceptance criteria、git status 和 diff，然后在 `docs/humanize-flow/<slug>/reviews/` 下写出综合后的 review。Codex 必须在考虑人类反馈后重新判断最终 verdict；反馈可能新增 finding、补充缺失验证证据、校正 review 范围，或使原 finding 失效。`review-feedback` 使用和 `review` 相同的 yolo 默认值、`--no-yolo` 和 `--sandbox` 覆盖行为。

选项：

- `--note <text>`：内联人类反馈。
- `--from <file>`：包含手工测试记录或 review 校正上下文的 Markdown 文件。
- `--review <file>`：要合并的前一次 review；不传时使用该 handoff slug 最新的 review。

## `humanize-flow commit`

使用 Codex 选择提交路径、起草 Lore commit message，并提交被选中的变更。

```bash
humanize-flow commit
humanize-flow commit --yes
humanize-flow commit --with-doc
```

通常情况下，Codex 会根据 `git status`、staged diff、unstaged diff、untracked files，以及 `AGENTS.md` / `CLAUDE.md` 等仓库约束判断哪些变更文件属于本次提交。已有 staged changes 只作为上下文参考：Codex 可以纳入相关的 unstaged 路径，也可以排除误暂存的路径。默认情况下，CLI 会从提交路径中排除 Humanize Flow 生成的计划和 review 产物，例如 `docs/humanize-flow/**`、`.humanize-flow/handoffs/**` 和 `.humanize-flow/verifications/**`，让交付提交保持代码仓库干净。确实需要提交这些产物时，传 `--with-doc`。CLI 会 stage 被选中的路径，把路径列表写到 `.humanize-flow/runs/<timestamp>-commit/commit-paths.txt`，必要时把被排除的产物路径写到 `excluded-commit-paths.txt`，把生成的 message 写到 `.humanize-flow/runs/<timestamp>-commit/commit-message.txt`，并把被选中的变更预览写到 `selected-diffstat.txt` 和 `selected-diff.patch`。在交互模式下，它会先用 pager 打开 `selected-diff.patch`；按 `q` 返回后，再确认或取消提交。命令只会提交这些被选中的路径。传 `--yes` 时跳过预览确认。

当仓库处于干净的 merge 状态时，例如 `humanize-flow pr-resolve` 已经清理完所有未合并路径后，`commit` 会跳过路径选择，为整个 merge index 创建 merge-resolution commit。它仍会让 Codex 起草 Lore commit message，并把 merge-resolution 预览写入 `selected-diffstat.txt` 和 `selected-diff.patch`。如果仍有未合并路径，命令会拒绝提交。

如果 `git commit` 因 hook、lint、format、typecheck 或测试命令失败而失败，命令会把完整输出保存到 `.humanize-flow/runs/<timestamp>-commit/git-commit.log`。在交互终端中，它会询问是否创建一个 Beads 修复任务。Codex 会根据 hook 输出和被选中的 diff 起草任务；CLI 不会静默创建这个任务。

## `humanize-flow push`

推送当前分支。

```bash
humanize-flow push
humanize-flow push --remote origin
```

如果只有一个 remote，CLI 会直接推送。如果有多个 remote，会列出来并要求输入数字或 remote 名称。非交互模式下请传 `--remote`。

## `humanize-flow pull-main`

用 merge 方式把仓库 main/base 分支拉到当前分支。

```bash
humanize-flow pull-main
humanize-flow pull-main --base main
humanize-flow pull-main --base main --no-fetch
humanize-flow pull-main --remote origin
```

命令会使用和创建 PR 相同的顺序识别 base 分支：当前分支的 `gh-merge-base`、`origin/HEAD`、`main`、`master`。如果工作区存在未提交改动，它会在 merge 前创建 autostash。Git 报告 merge 冲突时，它会把 Codex 冲突解决 prompt 写入 `.humanize-flow/runs/<timestamp>-pull-main/`，让 Codex 解决冲突，检查是否还有 conflict marker，stage 已解决冲突路径，并创建 merge commit。merge 完成后会 apply autostash；如果恢复本地改动时产生标准 Git 冲突，也会让 Codex 解决。如果恢复被未跟踪文件碰撞等情况阻塞、但没有 unmerged paths，命令会保留 stash 并报告阻塞原因，而不会猜测覆盖文件。即使 apply 成功，autostash 也会为了安全而保留。

最后，`pull-main` 会让 Codex 评估影响范围，并把报告写入本次 run 目录的 `impact-report.md`。报告会覆盖受影响文件/模块、行为风险、文档/测试影响、冲突处理选择、stash 恢复情况和建议验证。

选项：

- `--base <branch>`：base 分支。默认依次使用当前分支的 `gh-merge-base`、`origin/HEAD`、`main`、`master`。
- `--remote <name>`：fetch base 分支使用的 remote。非交互模式且存在多个 remote 时必须提供。
- `--no-fetch`：跳过 fetch，使用已有本地或 remote-tracking base ref。
- `--yolo`：用 yolo 权限运行 Codex 冲突解决 prompt。

## `humanize-flow pr`

使用 Codex 起草专业的 GitHub Pull Request，并通过 GitHub CLI 创建。

```bash
humanize-flow pr
humanize-flow pr --base main --head feature-branch
humanize-flow pr --draft --push --yes
humanize-flow pr --dry-run
```

该命令会检查当前分支提交、diff、Humanize Flow 产物、handoff、实现总结、review 报告和仓库约束。它会让 Codex 生成结构化 PR 草稿，写入 `.humanize-flow/runs/<timestamp>-pr/pr-title.txt` 和 `pr-body.md`，展示草稿后调用 `gh pr create --repo ... --title ... --body-file ...`。

PR 提示词会要求 WHY 优先于 HOW 和 WHAT：正文应先说明问题、用户或维护者影响、约束条件、决策理由，再说明实现细节。如果通过的 Codex review 报告包含 `Human verification guide`，命令会把这些片段提供给 Codex；如果草稿遗漏，也会自动追加到 PR body，方便 reviewer 在 PR 中看到人工测试清单和停止条件。

`humanize-flow pr` 依赖 GitHub CLI (`gh`)，创建前会检查 `gh auth status`。它只通过 `gh pr create` 创建 PR；如果该命令失败，会把 stdout 和 stderr 保存到本次 run 目录，方便排查。

选项：

- `--base <branch>`：PR 目标分支。默认依次使用当前分支的 `gh-merge-base`、`origin/HEAD`、`main`、`master`。
- `--head <branch>`：PR 来源分支，默认当前分支。
- `--draft`：创建 draft PR。
- `--push`：创建 PR 前先推送当前分支。
- `--remote <name>`：PR 创建使用的 GitHub remote/repository，同时也是 `--push` 使用的 remote。
- `--yes`：展示生成的 PR 草稿后跳过确认。
- `--dry-run`：只生成并展示草稿，不创建 PR。

如果只有一个 remote，CLI 会用它作为 `gh pr create --repo` 的 GitHub 仓库。如果有多个 remote，会列出 remote 名称和 URL，并要求输入数字或 remote 名称。非交互模式下请传 `--remote`。

PR 标题和正文遵循 `humanize-flow i18n` 或 `HUMANIZE_FLOW_LANGUAGE` 配置的工作流语言。文件路径、命令、label、JSON key、API、Beads ID、分支名和 commit hash 保持原始形式。

## `humanize-flow pr-resolve`

把 PR 目标分支集成到当前分支，并在 Git 遇到未合并路径时使用 Codex 解决合并冲突。

```bash
humanize-flow pr-resolve
humanize-flow pr-resolve --base main
humanize-flow pr-resolve --base main --no-fetch
humanize-flow pr-resolve --base main --rebase
humanize-flow pr-resolve --base main --no-commit --no-push
```

默认情况下，命令会 fetch 目标分支，执行 `git merge --no-edit <target>`；如果可以干净合并，会推送当前分支。如果 Git 报告冲突，它会把冲突处理 prompt 写入 `.humanize-flow/runs/<timestamp>-pr-resolve/`，让 Codex 只解决目标分支集成造成的冲突，检查冲突文件中没有 conflict marker 后，stage 已解决的冲突路径，创建 merge-resolution commit，并推送当前分支。

这条命令刻意保持保守：开始新的 merge 或 rebase 前，已跟踪文件的工作区改动必须先提交或 stash。未跟踪的本地产物可以保留，除非 Git 拒绝覆盖它们。如果你已经处在 merge 或 rebase 冲突状态，`pr-resolve` 会检测并解决当前已有冲突，而不是再启动一次新的集成。

选项：

- `--base <branch>`：目标/base 分支。默认依次使用当前分支的 `gh-merge-base`、`origin/HEAD`、`main`、`master`。
- `--remote <name>`：fetch base 分支使用的 remote。非交互模式且存在多个 remote 时必须提供；如果提供，也会用于最终 push。
- `--merge`：把目标分支 merge 到当前分支。这是默认策略，不会改写 feature 分支提交。
- `--rebase`：把当前分支 rebase 到目标分支之上。
- `--no-fetch`：跳过 fetch，使用已有本地或 remote-tracking base ref。
- `--no-commit`：解决并 stage 冲突后停止。
- `--no-push`：创建 merge-resolution commit，但不 push。
- `--yolo`：用 yolo 权限运行 Codex 冲突解决器。

对于 `--rebase`，`pr-resolve` 仍会在解决冲突后停止，因为继续 rebase 和推送通常涉及改写历史的决策。需要自动 commit 和 push 时，请使用默认 merge 策略。

## `humanize-flow status`

显示一眼可读的工作流状态。

```bash
humanize-flow status
humanize-flow status --json
humanize-flow status --ai
humanize-flow status --explain
```

默认视图会汇总仓库状态、最近的 Humanize Flow run/review 活动、最新 review verdict、Beads ready 队列、已批准 handoff、内层 humanize/RLCR 痕迹、可疑阻塞信号和建议下一步。这个视图是确定性的，不调用 AI。

`--json` 会打印同一份机器可读快照，方便自动化或其他 agent 检查。

`--ai` 会先打印确定性状态视图，再让 Codex 用当前工作流语言、以说人话的方式解释当前状态快照。`--explain` 是别名。提示词和解释会保存到 `.humanize-flow/runs/<timestamp>-status/`。

## 环境变量

| 变量 | 用途 |
| --- | --- |
| `HUMANIZE_FLOW_HOME` | 安装后的分发根目录。 |
| `HUMANIZE_FLOW_CLAUDE_ARGS` | 传给 `claude -p` 的额外参数。 |
| `HUMANIZE_FLOW_CLAUDE_MODEL` | 覆盖 Claude Code worker 模型配置。 |
| `HUMANIZE_FLOW_CLAUDE_PERMISSION_MODE` | 覆盖 Claude Code 权限模式配置。 |
| `HUMANIZE_FLOW_CLAUDE_HUMANIZE` | 覆盖 Claude Code humanize 模式（`required`、`auto` 或 `off`）。 |
| `HUMANIZE_FLOW_CLAUDE_ENV_FILE` | 显式加载到 Claude Code worker run 的 env 文件。 |
| `HUMANIZE_FLOW_WORKER_PROVIDER` | 覆盖 worker provider（`claude` 或 `codex`）。 |
| `HUMANIZE_FLOW_WORKER_CODEX_MODEL` | 覆盖 YOLO Codex worker 模型。 |
| `HUMANIZE_FLOW_WORKER_CODEX_REASONING_EFFORT` | 覆盖 YOLO Codex worker 推理强度。 |
| `HUMANIZE_FLOW_WORKER_CODEX_ARGS` | 传给 Codex worker `codex exec` 的额外参数。 |
| `HUMANIZE_FLOW_YOLO_MAX_ROUND` | 覆盖默认 YOLO 业务修正轮数。 |
| `HUMANIZE_FLOW_YOLO_REVIEW_STRATEGY` | 覆盖 YOLO review 策略（`final` 或 `each-task`）。 |
| `HUMANIZE_FLOW_CODEX_MODEL` | 覆盖 planner/review/commit/pr 使用的 Codex 模型配置。 |
| `HUMANIZE_FLOW_CODEX_REASONING_EFFORT` | 覆盖 planner/review/commit/pr 使用的 Codex 推理强度配置。 |
| `HUMANIZE_FLOW_REVIEW_YOLO` | 覆盖 review/review-feedback 是否传给 Codex `--dangerously-bypass-approvals-and-sandbox`。 |
| `HUMANIZE_FLOW_REVIEW_SANDBOX` | 覆盖 review/review-feedback 使用的 Codex sandbox。 |
| `HUMANIZE_FLOW_LANGUAGE` | 对单次命令覆盖生成产物语言。 |
| `HUMANIZE_FLOW_CODEX_ARGS` | 传给 `codex exec` 的额外参数。 |
| `HUMANIZE_FLOW_BIN_DIR` | CLI 安装位置。 |
| `CODEX_SKILLS_DIR` | 覆盖 Codex 用户级 skill 路径。 |
| `CLAUDE_CONFIG_DIR` | 覆盖 Claude Code 配置根目录。 |
