# humanize 集成

humanize/RLCR 在 humanize-flow 中是可选项。它最适合实现阶段，而不是规划阶段。

## 何时使用 humanize

当 worker 任务比较复杂时使用：

- 涉及多个文件，
- 验收标准不简单，
- 重构风险中等或较高，
- 可能需要多轮 review，
- 涉及架构敏感点。

## 何时不使用 humanize

以下情况跳过：

- 只是很小的编辑，
- 未安装 humanize，
- 调用它需要不安全权限，
- 当前非交互模式无法安全调用 slash commands。

## 降级行为

如果 humanize 不可用，worker 应模拟同样纪律：

1. 从已批准 plan 实现，
2. 运行针对性测试，
3. 写实现总结，
4. 请求 Codex review，
5. 只修 review blockers。

## 重要边界

humanize 应在 Claude worker 阶段使用。Codex planner 不应调用 humanize，Codex reviewer 不应实现修复。
