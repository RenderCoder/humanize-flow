# Security Policy

humanize-flow orchestrates local AI coding tools. It may cause tools to read repository content, edit files, run commands, and create Beads tasks depending on how you invoke it.

## Supported versions

Security fixes target the latest released version.

## Reporting issues

If you find a security issue, report it privately to the maintainers rather than opening a public issue. If this repository is hosted on GitHub, use GitHub private vulnerability reporting when available.

## Security principles

- Planning should not modify implementation code.
- Execution requires explicit approval through a handoff manifest.
- The default CLI does not use full-access sandbox modes.
- API keys and local auth files must never be committed.
- High-permission automation should run only in trusted, isolated environments.

See `docs/en/security.md` and `docs/zh-CN/security.md` for operational guidance.
