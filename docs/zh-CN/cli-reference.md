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
```

## `humanize-flow run-next`

选择一个 ready 的 Beads 任务并运行 worker。

```bash
humanize-flow run-next
```

## `humanize-flow review`

为一个 Beads 任务运行 Codex reviewer。

```bash
humanize-flow review <bd-id>
```

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
| `HUMANIZE_FLOW_CODEX_ARGS` | 传给 `codex exec` 的额外参数。 |
| `HUMANIZE_FLOW_BIN_DIR` | CLI 安装位置。 |
| `CODEX_SKILLS_DIR` | 覆盖 Codex 用户级 skill 路径。 |
| `CLAUDE_CONFIG_DIR` | 覆盖 Claude Code 配置根目录。 |
