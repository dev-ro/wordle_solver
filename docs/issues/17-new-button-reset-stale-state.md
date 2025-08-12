# Issue #17 — New game must cancel stale computations and clear memory

## Summary
Selecting a recommended word after pressing "New" sometimes fills tiles using feedback from a previous game. The root cause is an in-flight recommendation request finishing after the reset and writing its old `lastResponse` into the fresh state.

## Expected
- Pressing "New" fully resets board, history, and any background work so subsequent recommendations and selection-fill use only the new game state.

## Actual
- After pressing "New", a previous async compute can still complete and update `lastResponse`. This makes the UI show a correct recommendation list, but auto-fill uses mismatched history leading to incorrect letter locks.

## Fix
- Introduce a monotonically increasing request token in `SolverController`.
- Increment the token on every new async recommendation request and on reset.
- Only apply async results when their token matches the latest value.

## Acceptance Criteria
- After pressing "New", no prior game response can update state.
- Selecting a word immediately after reset fills only according to the new board.
- No regressions to slider length changes, dictionary changes, or filler actions.

## Files Touched
- `lib/state/solver_state.dart`: add `_requestToken`, guard both `requestRecommendations` and `requestRecommendationsWithoutConsuming`, bump token on `resetGame`.

## Notes
- This is a UI/logic-only change; no API changes.

