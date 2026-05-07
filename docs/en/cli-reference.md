# CLI Reference

The CLI is a lightweight orchestrator. It is intentionally shell-based so the workflow is easy to inspect and modify.

## `humanize-flow help`

Show command help.

## `humanize-flow version`

Print the CLI version.

## `humanize-flow paths`

Show resolved repository, state, docs, and skill paths.

## `humanize-flow doctor`

Check local tools and installed skills.

```bash
humanize-flow doctor
```

## `humanize-flow init [--with-bd]`

Initialize Humanize Flow directories in the current git repository.

```bash
humanize-flow init
humanize-flow init --with-bd
```

## `humanize-flow plan`

Run the Codex planner in non-interactive mode.

```bash
humanize-flow plan --slug <slug> --from <request-file>
humanize-flow plan --slug <slug> --request "<request text>"
```

Options:

- `--sandbox <mode>`: pass sandbox mode to `codex exec`; default is `workspace-write`.
- `--no-codex`: write the planner prompt but do not execute it.

The generated planner prompt includes the configured workflow language. The default is English; use `humanize-flow i18n zh` to switch to Simplified Chinese.

## `humanize-flow plan-from-bd`

Run the Codex planner from an existing Beads task ID.

```bash
humanize-flow plan-from-bd <bd-id>
humanize-flow plan-from-bd <bd-id> --slug <slug>
humanize-flow from-bd <bd-id> --slug <slug>
```

The command captures:

```bash
bd show <bd-id> --json
```

into:

```text
docs/humanize-flow/<slug>/bd-source.json
```

Then it runs the `humanize-flow-bd-planner` skill. The generated handoff links the original Beads task with `source.type=beads`, `source.bd_id=<bd-id>`, `bd.materialized=true`, and `execution.current_bd_id=<bd-id>`.

Options:

- `--slug <slug>`: choose the artifact slug; otherwise the CLI derives one from the task title.
- `--sandbox <mode>`: pass sandbox mode to `codex exec`; default is `workspace-write`.
- `--no-codex`: capture the task and write the planner prompt but do not execute it.

The generated planner prompt applies the configured workflow language while preserving source IDs and machine-readable literals.

For this path, the next command is usually `humanize-flow approve <slug>` rather than `approve --materialize-bd`, because the Beads task already exists.

## `humanize-flow approve`

Mark a handoff as approved.

```bash
humanize-flow approve <slug>
humanize-flow approve <slug> --materialize-bd
```

## `humanize-flow materialize-bd`

Create Beads epic/tasks from an approved handoff.

```bash
humanize-flow materialize-bd <slug>
```

## `humanize-flow run`

Run Claude Code worker for one Beads task.

```bash
humanize-flow run <bd-id>
humanize-flow run <bd-id> --interactive
humanize-flow run <bd-id> --model claude-opus-4-7
```

Default worker runs use Claude Code print mode with `stream-json` internally, partial message chunks, hook events, `--verbose`, model `claude-opus-4-7`, and permission mode `auto`. The terminal shows a human-readable progress log. The run directory contains both `claude-final.md` for the readable log and `claude-final.jsonl` for the raw Claude event stream.

Use `--interactive` to open a Claude Code interactive session with the same generated worker prompt. Use `--text` when you want Claude's text-only output without raw event capture.

## `humanize-flow run-next`

Pick a ready Beads task and run the worker.

```bash
humanize-flow run-next
```

When multiple ready tasks or Epic groups exist and stdin is interactive, the CLI asks which group/task to run before starting Claude Code. In non-interactive scripts, set `HUMANIZE_FLOW_NONINTERACTIVE=1` to use the deterministic fallback selection.

## `humanize-flow config`

Show or change global Humanize Flow defaults.

```bash
humanize-flow config show
humanize-flow config get language
humanize-flow config set language zh
humanize-flow config get claude.model
humanize-flow config set claude.model claude-opus-4-7
humanize-flow config set claude.permission_mode auto
humanize-flow config get codex.model
humanize-flow config set codex.model gpt-5.5
humanize-flow config get codex.reasoning_effort
humanize-flow config set codex.reasoning_effort high
```

Global config is stored in `${XDG_CONFIG_HOME:-$HOME/.config}/humanize-flow/config.json`. Environment variables still override config values for a single command.

If `codex.model` or `codex.reasoning_effort` is unset, Humanize Flow uses the Codex CLI defaults from your normal Codex configuration. Supported reasoning effort values are `low`, `medium`, `high`, and `xhigh`.

## `humanize-flow i18n`

Show or set the language for human-facing generated artifacts.

```bash
humanize-flow i18n
humanize-flow i18n en
humanize-flow i18n zh
```

The default is `en`. Setting `zh` switches the full workflow to Simplified Chinese for planning docs, Beads task text, implementation summaries, review reports, and commit message prose. Machine-readable literals remain canonical.

## `humanize-flow review`

Run Codex reviewer for one Beads task.

```bash
humanize-flow review <bd-id>
humanize-flow review <handoff-slug>
```

Use the actual Beads task id when possible. Handoff slugs are also accepted and resolved to the matching handoff before the review path is chosen.

## `humanize-flow commit`

Use Codex to select commit paths, draft a Lore commit message, and commit the selected changes.

```bash
humanize-flow commit
humanize-flow commit --yes
```

Codex always selects which changed file paths belong in the commit based on `git status`, staged diff, unstaged diff, untracked files, and repository guidance such as `AGENTS.md` or `CLAUDE.md`. Existing staged changes are advisory context only: Codex may include related unstaged paths and exclude accidentally staged paths. The CLI stages the selected paths, writes them to `.humanize-flow/runs/<timestamp>-commit/commit-paths.txt`, writes the generated message under `.humanize-flow/runs/<timestamp>-commit/commit-message.txt`, shows the selected diffstat and message, and commits only those selected paths unless the confirmation is rejected. Pass `--yes` to skip the confirmation prompt.

If `git commit` fails because a hook, linter, formatter, typecheck, or test command fails, the command saves the full output to `.humanize-flow/runs/<timestamp>-commit/git-commit.log`. In an interactive terminal, it then asks whether to create a Beads task for fixing the hook failure. Codex drafts the task from the hook output and selected diff; the CLI does not create this task silently.

## `humanize-flow push`

Push the current branch.

```bash
humanize-flow push
humanize-flow push --remote origin
```

If exactly one remote exists, the CLI pushes to it. If multiple remotes exist, it lists them and asks for a number or remote name. In non-interactive mode, pass `--remote`.

## `humanize-flow pr`

Use Codex to draft a professional GitHub pull request and create it with GitHub CLI.

```bash
humanize-flow pr
humanize-flow pr --base main --head feature-branch
humanize-flow pr --draft --push --yes
humanize-flow pr --dry-run
```

The command inspects the branch commits, diff, Humanize Flow artifacts, handoffs, implementation summaries, review reports, and repository guidance. It asks Codex for a structured PR draft, writes `.humanize-flow/runs/<timestamp>-pr/pr-title.txt` and `pr-body.md`, shows the draft, then calls `gh pr create --title ... --body-file ...`.

Options:

- `--base <branch>`: base branch. Defaults to branch `gh-merge-base`, `origin/HEAD`, `main`, then `master`.
- `--head <branch>`: PR head branch. Defaults to the current branch.
- `--draft`: create a draft PR.
- `--push`: push the current branch before creating the PR.
- `--remote <name>`: remote used by `--push`.
- `--yes`: skip confirmation after showing the generated PR draft.
- `--dry-run`: generate and show the draft without creating the PR.

The PR title and body follow the configured workflow language from `humanize-flow i18n` or `HUMANIZE_FLOW_LANGUAGE`. File paths, commands, labels, JSON keys, APIs, Beads IDs, branch names, and commit hashes stay canonical.

## `humanize-flow status`

Show handoff states and Beads ready queue.

```bash
humanize-flow status
```

## Environment variables

| Variable | Purpose |
| --- | --- |
| `HUMANIZE_FLOW_HOME` | Distribution root when installed. |
| `HUMANIZE_FLOW_CLAUDE_ARGS` | Extra arguments for `claude -p`. |
| `HUMANIZE_FLOW_CLAUDE_MODEL` | Override the configured Claude Code worker model. |
| `HUMANIZE_FLOW_CLAUDE_PERMISSION_MODE` | Override the configured Claude Code permission mode. |
| `HUMANIZE_FLOW_CODEX_MODEL` | Override the configured Codex model for planner/review/commit/pr runs. |
| `HUMANIZE_FLOW_CODEX_REASONING_EFFORT` | Override the configured Codex reasoning effort for planner/review/commit/pr runs. |
| `HUMANIZE_FLOW_LANGUAGE` | Override generated artifact language for one command. |
| `HUMANIZE_FLOW_CODEX_ARGS` | Extra arguments for `codex exec`. |
| `HUMANIZE_FLOW_BIN_DIR` | Install location for the CLI. |
| `CODEX_SKILLS_DIR` | Override Codex user skill path. |
| `CLAUDE_CONFIG_DIR` | Override Claude Code config root. |
