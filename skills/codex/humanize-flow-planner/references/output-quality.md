# Output Quality

A humanize-flow plan should be clear enough for another agent to execute later without relying on hidden conversation context.

## Quality bar

- The plan explains what changes and why.
- The plan lists important alternatives considered when there are tradeoffs.
- Acceptance criteria are observable and testable.
- Task boundaries are small and sequenced.
- Risks are not hand-waved.
- Non-goals are explicit.
- The handoff JSON is valid and portable.

## Avoid

- Vague tasks such as "Implement the feature".
- Hidden assumptions.
- Asking the worker to rediscover architecture that the planner already inspected.
- Creating Beads tasks before the plan is approved.
- Embedding local absolute paths in handoff artifact paths.
