# 故障排查

## 找不到 `humanize-flow` 命令

把安装目录加入 `PATH`：

```bash
export PATH="$HOME/.local/bin:$PATH"
```

然后重启 shell 或运行：

```bash
hash -r
```

## Codex skills 没出现

检查：

```bash
ls ~/.agents/skills
```

应该看到：

```text
humanize-flow-planner
humanize-flow-bd-planner
humanize-flow-reviewer
```

安装后请重启 Codex。

## Claude Code skill 没出现

检查：

```bash
ls ~/.claude/skills
```

如果设置了 `CLAUDE_CONFIG_DIR`，检查：

```bash
ls "$CLAUDE_CONFIG_DIR/skills"
```

## Planner 停在问题列表

这是正常行为，说明仍有关键不确定点。回答问题后，重新运行 planning，或用交互方式调用 planner。

对于已有 Beads 任务，你也可以先更新任务中的缺失细节，或者调用：

```text
$humanize-flow-bd-planner
```

用交互方式讨论该任务。

## `approve --materialize-bd` 失败

检查 Beads 是否安装并初始化：

```bash
bd --version
bd init
bd ready --json
```

同时检查 handoff 是否是合法 JSON：

```bash
python3 -m json.tool .humanize-flow/handoffs/<slug>.json
```

## `run-next` 选错任务

在交互式终端中，如果存在多个候选任务，`humanize-flow run-next` 会询问要运行哪个 ready Epic/task 分组。如果你的 Beads 输出格式不同，或想完全绕过选择，可以显式指定任务：

```bash
humanize-flow run <bd-id>
```

脚本中可设置 `HUMANIZE_FLOW_NONINTERACTIVE=1` 使用确定性的回退选择。

## `commit` 在 pre-commit hook 失败

`humanize-flow commit` 会把 hook 输出保存在：

```text
.humanize-flow/runs/<timestamp>-commit/git-commit.log
```

当失败看起来来自 hook、lint、format、typecheck 或测试时，交互模式会询问是否创建 Beads 修复任务。这是刻意保留确认的：hook 失败可能是真代码问题，也可能是本地环境问题，比如缺少 `eslint` 命令。

## Review 输出到了 `unknown`

这表示 CLI 没能把传入的 review 参数映射到 Humanize Flow handoff。优先使用 handoff 中的实际 Beads 任务 ID，例如：

```bash
humanize-flow review rti-tek-miniapp-copy-63g
```

新版也支持 handoff slug，但旧版已安装 CLI 可能只能解析 Beads ID。

## humanize 不可用

Worker 默认使用 `claude.humanize=required`，所以当检测不到 humanize 命令、Claude 插件或已安装的 Codex humanize skill 脚本时，`humanize-flow run` 会停止。

请安装 humanize，或者在明确希望不使用 humanize 时显式降低模式：

```bash
humanize-flow run <bd-id> --humanize-mode auto
humanize-flow run <bd-id> --no-humanize
humanize-flow config set claude.humanize auto
```
