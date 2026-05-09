# 安装

humanize-flow 支持用户级安装和项目级安装。

## 用户级安装

适合你的个人开发机器：

```bash
./install.sh --user
humanize-flow doctor
```

会安装到：

```text
~/.agents/skills/humanize-flow-planner
~/.agents/skills/humanize-flow-bd-planner
~/.agents/skills/humanize-flow-reviewer
~/.claude/skills/humanize-flow-worker
~/.local/bin/humanize-flow
~/.local/share/humanize-flow
```

如果 `~/.local/bin` 不在 `PATH` 中，请加入 shell 配置：

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## 项目级安装

如果你希望某个仓库自带这套流程，可以使用：

```bash
./install.sh --project
```

会复制到当前 git 仓库：

```text
.agents/skills/humanize-flow-planner
.agents/skills/humanize-flow-bd-planner
.agents/skills/humanize-flow-reviewer
.claude/skills/humanize-flow-worker
.humanize-flow/bin/humanize-flow
.humanize-flow/share/humanize-flow
```

团队协作时项目级安装更合适；个人使用时用户级安装更简单。

## 预演安装

```bash
./install.sh --user --dry-run
```

## 覆盖已有安装

```bash
./install.sh --user --force
```

## 卸载用户级文件

```bash
./uninstall.sh
```

卸载脚本会删除用户级 skills、CLI 和共享文件，但不会删除各个仓库里的 `.humanize-flow` 状态或生成的文档。

## 验证安装

```bash
humanize-flow doctor
```

如果你还没安装 Codex、Claude Code 或 Beads，看到相关 warning 是正常的。由于 worker 默认使用 `claude.humanize=required`，缺少 humanize 会被视为 failure，除非你把模式降为 `auto` 或 `off`。Bash、Git、Python 3、`jq` 这类基础工具缺失时，应先修复。
