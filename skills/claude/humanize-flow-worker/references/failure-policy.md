# Failure Policy

## Plan is wrong

If the approved plan conflicts with repository reality:

1. Stop implementation.
2. Record the conflict in the implementation summary.
3. Add a Beads note to the task.
4. Create a follow-up or blocker issue if possible.
5. Ask the user to send the task back to the planner.

## Tests fail before changes

If baseline tests fail before your change:

- record the baseline failure,
- continue only if the task can be verified independently,
- do not hide baseline failures as task failures.

## Tool missing

If `bd`, `humanize`, or a test tool is missing:

- state exactly what is missing,
- use the safest fallback that preserves role boundaries,
- do not install global tools unless the user asked.

## Permission blocked

If a command requires permission you do not have, stop and explain the exact permission needed. Do not switch to broad bypass modes yourself.
