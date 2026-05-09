# humanize 集成

humanize/RLCR 在 humanize-flow worker 运行中默认是 required。它用于实现阶段，而不是规划阶段。

## 模式

- `required`：默认值。`humanize-flow run` 会检查 humanize 是否已安装，Claude prompt 会要求在改代码前从已批准 plan 启动 RLCR。
- `auto`：复杂任务在可用时使用 humanize；不可用或不适合时允许直接实现。
- `off`：本次运行禁用 humanize。

配置默认值：

```bash
humanize-flow config set claude.humanize required
humanize-flow config set claude.humanize auto
humanize-flow config set claude.humanize off
```

覆盖单次运行：

```bash
humanize-flow run <bd-id> --humanize
humanize-flow run <bd-id> --humanize-mode auto
humanize-flow run <bd-id> --no-humanize
```

## `auto` 何时使用 humanize

当 worker 任务比较复杂时使用：

- 涉及多个文件，
- 验收标准不简单，
- 重构风险中等或较高，
- 可能需要多轮 review，
- 涉及架构敏感点。

## `auto` 何时可以跳过 humanize

以下情况跳过：

- 只是很小的编辑，
- 未安装 humanize，
- 调用它需要不安全权限，
- 当前非交互模式无法安全调用 slash commands。

## 降级行为

在 `required` 中没有静默降级：应停止并报告阻塞原因。在 `auto` 中，如果 humanize 不可用，worker 应模拟同样纪律：

1. 从已批准 plan 实现，
2. 运行针对性测试，
3. 写实现总结，
4. 请求 Codex review，
5. 只修 review blockers。

## 重要边界

humanize 应在 Claude worker 阶段使用。Codex planner 不应调用 humanize，Codex reviewer 不应实现修复。
