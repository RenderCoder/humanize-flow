# 发布检查清单

发布归档前运行：

```bash
make test
make package
```

如果默认的 `humanize-flow.zip` 已存在，改用带版本号的归档路径：

```bash
bash scripts/package.sh humanize-flow-0.5.9.zip
```

然后检查：

```bash
unzip -l humanize-flow.zip | less
```

确认：

- [ ] zip 根目录是 `humanize-flow/`。
- [ ] 存在 `README.md` 和 `README.zh-CN.md`。
- [ ] 存在 `AGENTS.md`。
- [ ] Codex 和 Claude skills 都存在。
- [ ] CLI 和安装脚本可执行。
- [ ] 英文和中文文档一一对应。
- [ ] 不包含 `.git/` 目录。
- [ ] 不包含 `.omx/`、`.humanize-flow/runs/` 或 `docs/humanize-flow/unknown/` 运行时产物。
- [ ] 不包含认证文件、API keys 或本地运行日志。
- [ ] `CHANGELOG.md` 版本正确。
