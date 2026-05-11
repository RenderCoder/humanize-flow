# CLI Reference

The CLI is a lightweight orchestrator. It is intentionally shell-based so the workflow is easy to inspect and modify.

For the recommended command sequence and recovery rules, read [Best Practices](best-practices.md). In short: use normal `run` plus explicit `review` for daily work, use `run --yolo` for trusted automated loops, run `status --ai` before assuming a task is stuck, and record manual verification with `verify` before delivery commands.

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

The generated planner prompt includes the configured workflow language. The default is English; use `humanize-flow i18n zh` to switch to Simplified Chinese. The language policy covers `request.md`, `jira-requirement.md`, `plan.md`, `acceptance.md`, `bd-plan.md`, handoff prose, and generated Beads epic/task titles, descriptions, and acceptance criteria.

`jira-requirement.md` is a Jira-style Markdown requirement for internal collaboration systems. It should explain WHY/context before HOW/WHAT, use plain language for cross-functional readers, and separate technical notes when needed.

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

The generated planner prompt applies the configured workflow language to generated planning prose, `jira-requirement.md`, `bd-plan.md`, and handoff `bd.*` task prose while preserving source IDs and machine-readable literals. Raw source task text is preserved in `bd-source.json`.

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
humanize-flow run <bd-id> --yolo
humanize-flow run <bd-id> --yolo --max-round 5
humanize-flow run <bd-id> --yolo --retry 5 --retry-delay 20
humanize-flow run <handoff-slug-or-epic-id> --yolo --review-at-end
humanize-flow run <bd-id> --interactive
humanize-flow run <bd-id> --model claude-sonnet-4-6
humanize-flow run <bd-id> --humanize-mode auto
humanize-flow run <bd-id> --no-humanize
humanize-flow run <bd-id> --env-file .humanize-flow/claude-provider.env
```

Default worker runs use Claude Code print mode with `stream-json` internally, partial message chunks, hook events, `--verbose`, model `claude-sonnet-4-6`, permission mode `bypassPermissions`, and `claude.humanize=required`. The terminal shows a human-readable progress log. The run directory contains both `claude-final.md` for the readable log and `claude-final.jsonl` for the raw Claude event stream. Lower Claude permissions for one run with `--permission-mode auto`, for one command with `HUMANIZE_FLOW_CLAUDE_PERMISSION_MODE=auto`, or globally with `humanize-flow config set claude.permission_mode auto`.

Humanize modes are:

- `required`: default. The CLI preflights humanize availability and the worker prompt requires Claude to start humanize/RLCR from the approved plan before editing code. If humanize cannot start, Claude must stop and report the blocker.
- `auto`: use humanize/RLCR for complex work when available; tiny or incompatible runs may implement directly while preserving Codex review.
- `off`: do not start humanize/RLCR.

Override one run with `--humanize`, `--humanize-mode required|auto|off`, or `--no-humanize`. Set the global default with `humanize-flow config set claude.humanize <mode>` or override one command with `HUMANIZE_FLOW_CLAUDE_HUMANIZE`.

Claude provider environment files are opt-in. By default, `run` uses the Claude Code process environment and Claude Code's normal global provider/auth configuration. Use `--env-file <file>` to load provider variables for one run, `HUMANIZE_FLOW_CLAUDE_ENV_FILE=<file>` for one shell command, or `humanize-flow config set claude.env_file <file>` for a persistent default. Use `--no-env-file` to ignore a configured file. Relative paths are resolved from the repository root. Keep these files untracked when they contain tokens.

`--yolo` starts a Claude+Codex loop for an approved Humanize Flow handoff. It forces Claude Code permission mode `bypassPermissions`, forces `--humanize-mode off` to avoid nested humanize/RLCR review loops, runs Codex review in yolo mode, parses the review verdict, and continues with the latest review as the next correction target until the verdict is `pass` or `--max-round` is reached. The default maximum is 3 rounds per target task.

`--review-at-end` changes Epic/handoff YOLO review scheduling. Instead of reviewing each child task as soon as Claude finishes it, the CLI implements all ready handoff children first, closes each child as "implemented; final review pending" so Beads dependencies can unblock, then runs one final full-scope Codex review against the handoff slug or Epic ID. If that final review returns `changes_requested` or `blocked`, the CLI runs a full-scope Claude correction and reviews again until `pass` or `--max-round` is reached. `--final-review-only` is an alias. Use this when per-child reviews are too slow or too narrow and you want Codex to assess the whole Epic at once. The tradeoff is later defect detection: downstream child tasks may build on unreviewed child output until the final review.

`--max-round` counts business correction rounds only: one Claude worker run plus one Codex review. Transient command failures are handled by `--retry` and `--retry-delay` instead. YOLO retries failed phases such as Claude provider calls, Codex review calls, `bd ready`, and Beads close operations before giving up. These retries do not consume a correction round. If retries are exhausted, the error includes a copyable `humanize-flow run ... --yolo` command so you can continue later after the network or provider recovers.

YOLO automates implementation and Codex review only. It does not automatically complete the human verification gate. After a `pass` review, follow the review report's `Human verification guide`, then run `humanize-flow verify <bd-id>` before delivery commands such as `commit`, `push`, `pr`, or release.

When the target is a handoff slug or Beads Epic ID, YOLO treats the handoff as an Epic queue. At startup it reads the handoff child tasks and recovers progress from Beads children that are already closed, so retrying after an interrupted run does not lose completed-child progress. Before each remaining child task it re-queries `bd ready --json`, intersects the ready set with the remaining handoff children, and selects the next ready child in Beads' ready order. The handoff limits the allowed child set; it does not impose a static execution order. Non-ready children are skipped until Beads dependencies unblock them. By default, after a child task passes review, the CLI closes that Beads task with a reason pointing at the passing review artifact so downstream dependencies can become ready. Each child task receives its own Claude correction loop and Codex review. The generated review prompt scopes Codex to the current child task, so unfinished sibling tasks in the same Epic are not valid failure reasons for that child-task review. Use `--review-at-end` when you prefer one final full-Epic acceptance review instead of per-child reviews.

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
humanize-flow config set claude.model claude-sonnet-4-6
humanize-flow config set claude.permission_mode bypassPermissions
humanize-flow config get claude.humanize
humanize-flow config set claude.humanize required
humanize-flow config get claude.env_file
humanize-flow config set claude.env_file .humanize-flow/claude-provider.env
humanize-flow config get codex.model
humanize-flow config set codex.model gpt-5.5
humanize-flow config get codex.reasoning_effort
humanize-flow config set codex.reasoning_effort high
humanize-flow config get review.yolo
humanize-flow config set review.yolo false
humanize-flow config get review.sandbox
humanize-flow config set review.sandbox workspace-write
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

The default is `en`. Setting `zh` switches the full workflow to Simplified Chinese for planning docs including `jira-requirement.md` and `bd-plan.md`, handoff prose, materialized Beads epic/task titles, descriptions, acceptance criteria, implementation summaries, review reports, pull request text, and commit message prose. Machine-readable literals remain canonical.

## `humanize-flow review`

Run Codex reviewer for one Beads task.

```bash
humanize-flow review <bd-id>
humanize-flow review <handoff-slug>
humanize-flow review <bd-id> --no-yolo
humanize-flow review <bd-id> --sandbox workspace-write
```

Use the actual Beads task id when possible. Handoff slugs are also accepted and resolved to the matching handoff before the review path is chosen.

Review defaults to yolo mode and passes Codex `--dangerously-bypass-approvals-and-sandbox` to avoid approval prompts blocking the review loop. Disable that default with `humanize-flow config set review.yolo false`, `HUMANIZE_FLOW_REVIEW_YOLO=false`, or a one-run `--no-yolo`. When yolo is disabled, change the sandbox with `humanize-flow config set review.sandbox <mode>` or `HUMANIZE_FLOW_REVIEW_SANDBOX`; override one run with `--sandbox <mode>`. Passing `--sandbox` also disables yolo for that run. Supported modes are `read-only`, `workspace-write`, and `danger-full-access`.

When the verdict is `pass`, the review report includes a human verification guide with manual test steps and a checklist to complete before commit/push. When the verdict is `changes_requested` or `blocked`, the report includes human correction options that can be fed into `review-feedback`.

Review reports also include one machine-readable ASCII verdict line such as `Humanize-Flow-Verdict: pass`. That line is not localized; it is the stable contract used by `run --yolo`, `status`, `verify`, and PR guide collection.

## `humanize-flow verify`

Record that a human completed the manual verification gate for a task or handoff.

```bash
humanize-flow verify <bd-id>
humanize-flow verify <handoff-slug>
humanize-flow verify <bd-id> --note "Manual smoke test passed in staging."
humanize-flow verify <bd-id> --review docs/humanize-flow/<slug>/reviews/<review>.md
humanize-flow verify <bd-id> --yes
```

If a latest passing review is available, `verify` links the confirmation to that review. If no review is available, it records a standalone manual verification instead of blocking. When `--review FILE` is passed explicitly, the selected review must have verdict `pass`; this avoids linking manual confirmation to a failed or unparseable review by mistake.

`verify` writes a local verification artifact under `.humanize-flow/verifications/` and updates the handoff's `latest_human_verification` artifact when a matching handoff exists. This is the explicit signal that the human gate is complete and delivery commands can proceed.

## `humanize-flow review-feedback`

Merge human manual-test feedback or review corrections into a new Codex review report.

```bash
humanize-flow review-feedback <bd-id>
humanize-flow review-feedback <bd-id> --note "Manual test found the empty state still overlaps."
humanize-flow review-feedback <bd-id> --from docs/manual-test-notes.md
humanize-flow review-feedback <handoff-slug> --review docs/humanize-flow/<slug>/reviews/<file>.md --from docs/manual-test-notes.md
humanize-flow review-feedback <bd-id> --no-yolo
humanize-flow review-feedback <bd-id> --sandbox workspace-write
```

Without `--note` or `--from`, the command opens `${VISUAL:-${EDITOR:-vi}}` so the human can write feedback directly. It saves the human feedback under `.humanize-flow/runs/<timestamp>-review-feedback-*/human-feedback.md`, reads the prior review, handoff, plan, acceptance criteria, git status, and diff, then writes a consolidated review under `docs/humanize-flow/<slug>/reviews/`. Codex must re-evaluate the final verdict after considering the human feedback; feedback can add a new finding, supply missing verification evidence, correct review scope, or invalidate a prior finding. `review-feedback` uses the same review yolo default, `--no-yolo`, and `--sandbox` override behavior as `review`.

Options:

- `--note <text>`: inline human feedback.
- `--from <file>`: Markdown file containing manual-test notes or review correction context.
- `--review <file>`: prior review to merge. If omitted, the latest review for the handoff slug is used.

## `humanize-flow commit`

Use Codex to select commit paths, draft a Lore commit message, and commit the selected changes.

```bash
humanize-flow commit
humanize-flow commit --yes
```

Codex always selects which changed file paths belong in the commit based on `git status`, staged diff, unstaged diff, untracked files, and repository guidance such as `AGENTS.md` or `CLAUDE.md`. Existing staged changes are advisory context only: Codex may include related unstaged paths and exclude accidentally staged paths. The CLI stages the selected paths, writes them to `.humanize-flow/runs/<timestamp>-commit/commit-paths.txt`, writes the generated message under `.humanize-flow/runs/<timestamp>-commit/commit-message.txt`, and writes the selected change preview to `selected-diffstat.txt` and `selected-diff.patch`. In interactive mode, it opens `selected-diff.patch` in your pager before confirmation; press `q` to return, then approve or reject the commit. The command commits only the selected paths unless the confirmation is rejected. Pass `--yes` to skip the preview confirmation prompt.

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

The command inspects the branch commits, diff, Humanize Flow artifacts, handoffs, implementation summaries, review reports, and repository guidance. It asks Codex for a structured PR draft, writes `.humanize-flow/runs/<timestamp>-pr/pr-title.txt` and `pr-body.md`, shows the draft, then calls `gh pr create --repo ... --title ... --body-file ...`.

The PR prompt prioritizes WHY over HOW and WHAT: the body should explain the problem, user or maintainer impact, constraints, decision rationale, and then the implementation details. When passing Codex review reports contain a `Human verification guide`, the command provides those guide snippets to Codex and also appends them to the PR body if the draft omits them, so reviewers can see the manual-test checklist and stop conditions in the PR.

`humanize-flow pr` requires GitHub CLI (`gh`) and checks `gh auth status` before creation. It creates the PR only through `gh pr create`; if that command fails, stdout and stderr are saved in the run directory for troubleshooting.

Options:

- `--base <branch>`: base branch. Defaults to branch `gh-merge-base`, `origin/HEAD`, `main`, then `master`.
- `--head <branch>`: PR head branch. Defaults to the current branch.
- `--draft`: create a draft PR.
- `--push`: push the current branch before creating the PR.
- `--remote <name>`: GitHub remote/repository used for PR creation and by `--push`.
- `--yes`: skip confirmation after showing the generated PR draft.
- `--dry-run`: generate and show the draft without creating the PR.

If exactly one remote exists, the CLI uses it as the GitHub repository for `gh pr create --repo`. If multiple remotes exist, it lists their names and URLs and asks for a number or remote name. In non-interactive mode, pass `--remote`.

The PR title and body follow the configured workflow language from `humanize-flow i18n` or `HUMANIZE_FLOW_LANGUAGE`. File paths, commands, labels, JSON keys, APIs, Beads IDs, branch names, and commit hashes stay canonical.

## `humanize-flow status`

Show a one-glance workflow status view.

```bash
humanize-flow status
humanize-flow status --json
humanize-flow status --ai
humanize-flow status --explain
```

The default view summarizes the repository state, latest Humanize Flow run/review activity, latest review verdicts, Beads ready queue, approved handoffs, inner humanize/RLCR traces, suspicious blocker signals, and suggested next actions. It is deterministic and does not call AI.

`--json` prints the same snapshot as machine-readable JSON for automation or for another agent to inspect.

`--ai` first prints the deterministic status view, then asks Codex to explain the current status snapshot in plain human language using the configured workflow language. `--explain` is an alias. The prompt and explanation are saved under `.humanize-flow/runs/<timestamp>-status/`.

## Environment variables

| Variable | Purpose |
| --- | --- |
| `HUMANIZE_FLOW_HOME` | Distribution root when installed. |
| `HUMANIZE_FLOW_CLAUDE_ARGS` | Extra arguments for `claude -p`. |
| `HUMANIZE_FLOW_CLAUDE_MODEL` | Override the configured Claude Code worker model. |
| `HUMANIZE_FLOW_CLAUDE_PERMISSION_MODE` | Override the configured Claude Code permission mode. |
| `HUMANIZE_FLOW_CLAUDE_HUMANIZE` | Override Claude Code humanize mode (`required`, `auto`, or `off`). |
| `HUMANIZE_FLOW_CLAUDE_ENV_FILE` | Opt-in env file loaded into Claude Code worker runs. |
| `HUMANIZE_FLOW_CODEX_MODEL` | Override the configured Codex model for planner/review/commit/pr runs. |
| `HUMANIZE_FLOW_CODEX_REASONING_EFFORT` | Override the configured Codex reasoning effort for planner/review/commit/pr runs. |
| `HUMANIZE_FLOW_REVIEW_YOLO` | Override whether review/review-feedback pass Codex `--dangerously-bypass-approvals-and-sandbox`. |
| `HUMANIZE_FLOW_REVIEW_SANDBOX` | Override Codex sandbox for review/review-feedback runs. |
| `HUMANIZE_FLOW_LANGUAGE` | Override generated artifact language for one command. |
| `HUMANIZE_FLOW_CODEX_ARGS` | Extra arguments for `codex exec`. |
| `HUMANIZE_FLOW_BIN_DIR` | Install location for the CLI. |
| `CODEX_SKILLS_DIR` | Override Codex user skill path. |
| `CLAUDE_CONFIG_DIR` | Override Claude Code config root. |
