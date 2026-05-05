# Scope Policy

The reviewer protects the approved plan boundary.

## Acceptable scope drift

- Small implementation details that are consistent with the plan.
- Minor test fixture changes needed to validate acceptance criteria.
- Documentation notes that explain the implemented behavior.

## Concerning scope drift

- New dependencies not approved by the plan.
- Public API changes not discussed in the plan.
- Refactors unrelated to the task.
- Changes to deployment, security, auth, migrations, or data deletion that were not approved.

## Response

If scope drift is harmless but confusing, mark `[P2]` and ask for documentation or follow-up.

If scope drift changes behavior or introduces risk, mark `[P1]` and request changes.
