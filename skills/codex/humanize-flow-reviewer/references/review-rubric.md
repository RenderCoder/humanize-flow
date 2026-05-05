# Review Rubric

## Severity

- `[P0]`: Critical. Data loss, security vulnerability, or change that can break the project immediately.
- `[P1]`: Must fix before completion. Acceptance criteria not met, tests failing due to the change, or scope mismatch.
- `[P2]`: Important. Should fix soon, but may be accepted if explicitly deferred.
- `[P3]`: Suggestion or cleanup.

Only `[P0]` and `[P1]` findings block a `pass` verdict by default.

## Acceptance checks

For each criterion:

- `pass`: evidence shows it is satisfied.
- `fail`: evidence shows it is not satisfied.
- `unknown`: evidence is missing or inconclusive.

`unknown` on a critical criterion should normally produce `blocked` or `changes_requested`.

## Scope checks

Flag changes that are unrelated to the approved task. If unrelated changes are harmless but confusing, mark `[P2]`. If they alter behavior or risk stability, mark `[P1]`.

## Test checks

A task can pass without running every possible test, but the review must explain why the test evidence is sufficient. Missing tests for new behavior are usually `[P1]` unless the plan explicitly waived them.
