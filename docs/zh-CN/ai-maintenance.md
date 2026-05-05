# AI 维护指南

本项目设计为可以由 Codex 或其他编码 agent 维护。请先阅读 `AGENTS.md`。

## 必须遵守的维护行为

新增或修改公开文档时，必须同时更新两种语言：

```text
docs/en/<topic>.md
docs/zh-CN/<topic>.md
```

修改快速开始行为时，必须同时更新：

```text
README.md
README.zh-CN.md
```

## 新增 CLI 命令

1. 更新 `bin/humanize-flow`。
2. 更新 `docs/en/cli-reference.md`。
3. 更新 `docs/zh-CN/cli-reference.md`。
4. 更新测试或校验。
5. 更新 `CHANGELOG.md`。
6. 运行 `make test`。

## 修改 skill

1. 更新相关 `SKILL.md`。
2. 如果流程变化，更新 references 或 assets。
3. 如果用户行为变化，更新文档。
4. 运行 `make test`。

## 修改 handoff schema

1. 更新 `schemas/handoff.schema.json`。
2. 运行 `scripts/sync-schema-assets.sh`。
3. 更新 `templates/handoff.json`；如果影响导入已有任务的路径，也要更新 `templates/handoff-from-bd.json`。
4. 更新 `examples/handoff.example.json`；如有需要，也要更新 `examples/handoff-from-bd.example.json`。
5. 如行为有变化，更新双语文档。
6. 运行 `make test`。

## 打包发布

```bash
make test
make package
```

发布 zip 的根目录应该是 `humanize-flow/`。
