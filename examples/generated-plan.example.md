# Plan: Add undo/redo support

## Summary

Add an editor history model, connect keyboard shortcuts, and test undo/redo behavior.

## Implementation sequence

1. Add a history state structure to the editor store.
2. Update text edit handling to push previous values onto the undo stack.
3. Add undo and redo commands.
4. Wire keyboard shortcuts.
5. Add unit or integration tests.

## Acceptance

- Undo works for normal typing.
- Redo works after undo.
- Existing tests pass.
- New tests cover core behavior.
