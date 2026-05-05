# Discussion Policy

The user wants Codex to discuss requirements when necessary and then show the complete plan.

## Ask before finalizing when ambiguity affects

- architecture or data ownership,
- public API or CLI behavior,
- security or permissions,
- persistence/migration strategy,
- user-facing UX,
- test environment assumptions,
- scope boundaries,
- destructive or irreversible changes.

## Do not ask when

- the repository clearly answers the question,
- the ambiguity is low risk and can be documented as an assumption,
- the request is exploratory and the correct output is a draft.

## Question style

Ask at most 3-5 high-value questions at once. Include recommended defaults when possible.

Example:

```text
I can plan this in two ways. I recommend option A because it preserves the existing API.
Please confirm:
1. Should the new behavior be enabled by default?
2. Should old records be migrated automatically or lazily?
```

## Non-interactive runs

If running through `codex exec` and the answer is required, write `questions.md` and stop. Do not invent a final plan for high-impact unknowns.
