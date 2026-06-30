# Release Checklist

Before publishing a release archive:

```bash
make test
make package
```

If a default `humanize-flow.zip` already exists, write a versioned archive instead:

```bash
bash scripts/package.sh humanize-flow-0.5.11.zip
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
- [ ] No `.omx/`, `.humanize-flow/runs/`, or `docs/humanize-flow/unknown/` runtime artifacts are included.
- [ ] No auth files, API keys, or local run logs are included.
- [ ] `CHANGELOG.md` has the correct version.
