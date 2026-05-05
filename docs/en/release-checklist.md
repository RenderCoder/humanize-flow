# Release Checklist

Before publishing a release archive:

```bash
make test
make package
```

Then inspect:

```bash
unzip -l humanize-flow.zip | less
```

Check:

- [ ] The zip root directory is `humanize-flow/`.
- [ ] `README.md` and `README.zh-CN.md` are present.
- [ ] `AGENTS.md` is present.
- [ ] Codex and Claude skills are present.
- [ ] CLI and install scripts are executable.
- [ ] English and Chinese docs are paired.
- [ ] No `.git/` directory is included.
- [ ] No auth files, API keys, or local run logs are included.
- [ ] `CHANGELOG.md` has the correct version.
