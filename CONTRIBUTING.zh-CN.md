# 参与 humanize-flow 贡献

感谢你帮助改进 humanize-flow。

## 开发环境

```bash
git clone <repo-url> humanize-flow
cd humanize-flow
make test
```

项目有意保持轻量：主要使用 shell 脚本、Markdown、JSON Schema 和 skills，不需要额外的包管理器。

## 提交 PR 前

运行：

```bash
make test
```

确认：

- 英文和简体中文文档都已更新。
- `AGENTS.md` 中的维护约束仍然符合实现。
- skill 名称和 CLI 命令名称保持稳定。
- shell 脚本通过 `bash -n`。
- handoff 示例符合 `schemas/handoff.schema.json`。

## 文档策略

本项目以英文为主，但所有新增公开文档都必须包含简体中文版本。

示例：

- 新增 `docs/en/foo.md` 时，同时新增 `docs/zh-CN/foo.md`。
- 修改快速开始流程时，同时更新 `README.md` 和 `README.zh-CN.md`。
- skill 文档以英文为主；如果变更影响用户文档，也要更新中文文档。

## 设计原则

- 实现前保留人工确认。
- 保持 planner、worker、reviewer 三个角色分离。
- Markdown、Beads 和 handoff JSON 面向不同读者，不要混为一谈。
- 优先显式确认，而不是静默自动化。
- 优先安全默认值，而不是炫技式 demo。

## PR 检查清单

- [ ] `make test` 通过。
- [ ] 用户可见文档已按要求双语更新。
- [ ] 用户可见变更已更新 `CHANGELOG.md`。
- [ ] 新 CLI 行为已写入 `docs/en/cli-reference.md` 和 `docs/zh-CN/cli-reference.md`。
- [ ] 新工作流行为已反映到相关 skill reference 文件中。
