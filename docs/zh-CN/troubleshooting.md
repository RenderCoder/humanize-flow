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

CLI 会先选择已批准 Humanize Flow handoff 中出现的 ready 任务，然后再选择带 `humanize-flow` label 的任务。如果你的 Beads 输出格式不同，可以显式指定任务：

```bash
humanize-flow run <bd-id>
```

## humanize 不可用

Worker 仍可直接实现并请求 Codex review。humanize/RLCR 是增强能力，不是硬依赖。
