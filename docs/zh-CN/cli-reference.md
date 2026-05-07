# CLI 参考

CLI 是轻量调度器，刻意使用 shell 实现，方便查看和修改。

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

生成的 planner prompt 会包含当前工作流语言配置。默认是英文；使用 `humanize-flow i18n zh` 可切换到简体中文。

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

生成的 planner prompt 同样会应用当前工作流语言配置，同时保留来源任务 ID 和机器可读字面量的原始形式。

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

为一个 Beads 任务运行 Claude Code worker。

```bash
humanize-flow run <bd-id>
humanize-flow run <bd-id> --interactive
humanize-flow run <bd-id> --model claude-opus-4-7
```

默认 worker 运行使用 Claude Code print 模式，内部使用 `stream-json`、partial message chunks、hook events、`--verbose`、模型 `claude-opus-4-7` 和权限模式 `auto`。终端会显示人类可读的进展日志。run 目录中会同时保存 `claude-final.md` 人类可读日志和 `claude-final.jsonl` 原始 Claude 事件流。

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
humanize-flow config set claude.model claude-opus-4-7
humanize-flow config set claude.permission_mode auto
humanize-flow config get codex.model
humanize-flow config set codex.model gpt-5.5
humanize-flow config get codex.reasoning_effort
humanize-flow config set codex.reasoning_effort high
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

默认是 `en`。设置为 `zh` 会把完整链路切换到简体中文，包括规划文档、Beads 任务文本、实现总结、review 报告和 commit message 正文。机器可读字面量保持原始形式。

## `humanize-flow review`

为一个 Beads 任务运行 Codex reviewer。

```bash
humanize-flow review <bd-id>
humanize-flow review <handoff-slug>
```

尽量使用实际 Beads 任务 ID。也可以传 handoff slug，CLI 会先解析匹配的 handoff，再选择正确的 review 目录。

## `humanize-flow commit`

使用 Codex 选择提交路径、起草 Lore commit message，并提交被选中的变更。

```bash
humanize-flow commit
humanize-flow commit --yes
```

Codex 每次都会根据 `git status`、staged diff、unstaged diff、untracked files，以及 `AGENTS.md` / `CLAUDE.md` 等仓库约束判断哪些变更文件属于本次提交。已有 staged changes 只作为上下文参考：Codex 可以纳入相关的 unstaged 路径，也可以排除误暂存的路径。CLI 会 stage 被选中的路径，把路径列表写到 `.humanize-flow/runs/<timestamp>-commit/commit-paths.txt`，把生成的 message 写到 `.humanize-flow/runs/<timestamp>-commit/commit-message.txt`，展示被选中 diffstat 和 message，然后只提交这些被选中的路径。传 `--yes` 时跳过确认。

如果 `git commit` 因 hook、lint、format、typecheck 或测试命令失败而失败，命令会把完整输出保存到 `.humanize-flow/runs/<timestamp>-commit/git-commit.log`。在交互终端中，它会询问是否创建一个 Beads 修复任务。Codex 会根据 hook 输出和被选中的 diff 起草任务；CLI 不会静默创建这个任务。

## `humanize-flow push`

推送当前分支。

```bash
humanize-flow push
humanize-flow push --remote origin
```

如果只有一个 remote，CLI 会直接推送。如果有多个 remote，会列出来并要求输入数字或 remote 名称。非交互模式下请传 `--remote`。

## `humanize-flow pr`

使用 Codex 起草专业的 GitHub Pull Request，并通过 GitHub CLI 创建。

```bash
humanize-flow pr
humanize-flow pr --base main --head feature-branch
humanize-flow pr --draft --push --yes
humanize-flow pr --dry-run
```

该命令会检查当前分支提交、diff、Humanize Flow 产物、handoff、实现总结、review 报告和仓库约束。它会让 Codex 生成结构化 PR 草稿，写入 `.humanize-flow/runs/<timestamp>-pr/pr-title.txt` 和 `pr-body.md`，展示草稿后调用 `gh pr create --title ... --body-file ...`。

选项：

- `--base <branch>`：PR 目标分支。默认依次使用当前分支的 `gh-merge-base`、`origin/HEAD`、`main`、`master`。
- `--head <branch>`：PR 来源分支，默认当前分支。
- `--draft`：创建 draft PR。
- `--push`：创建 PR 前先推送当前分支。
- `--remote <name>`：`--push` 使用的 remote。
- `--yes`：展示生成的 PR 草稿后跳过确认。
- `--dry-run`：只生成并展示草稿，不创建 PR。

PR 标题和正文遵循 `humanize-flow i18n` 或 `HUMANIZE_FLOW_LANGUAGE` 配置的工作流语言。文件路径、命令、label、JSON key、API、Beads ID、分支名和 commit hash 保持原始形式。

## `humanize-flow status`

显示 handoff 状态和 Beads ready 队列。

```bash
humanize-flow status
```

## 环境变量

| 变量 | 用途 |
| --- | --- |
| `HUMANIZE_FLOW_HOME` | 安装后的分发根目录。 |
| `HUMANIZE_FLOW_CLAUDE_ARGS` | 传给 `claude -p` 的额外参数。 |
| `HUMANIZE_FLOW_CLAUDE_MODEL` | 覆盖 Claude Code worker 模型配置。 |
| `HUMANIZE_FLOW_CLAUDE_PERMISSION_MODE` | 覆盖 Claude Code 权限模式配置。 |
| `HUMANIZE_FLOW_CODEX_MODEL` | 覆盖 planner/review/commit/pr 使用的 Codex 模型配置。 |
| `HUMANIZE_FLOW_CODEX_REASONING_EFFORT` | 覆盖 planner/review/commit/pr 使用的 Codex 推理强度配置。 |
| `HUMANIZE_FLOW_LANGUAGE` | 对单次命令覆盖生成产物语言。 |
| `HUMANIZE_FLOW_CODEX_ARGS` | 传给 `codex exec` 的额外参数。 |
| `HUMANIZE_FLOW_BIN_DIR` | CLI 安装位置。 |
| `CODEX_SKILLS_DIR` | 覆盖 Codex 用户级 skill 路径。 |
| `CLAUDE_CONFIG_DIR` | 覆盖 Claude Code 配置根目录。 |
