# Optimize Suggest action: omit known green letters and reset between games

## Background
The Suggest action auto-searches for words containing provided letters at variable positions and fills the search bar. It currently may include letters already confirmed green in the active game, reducing usefulness. Also, previously green letters from past games can leak into a new session if state is not reset.

## Requirements / Acceptance Criteria
- Exclude letters currently marked as green in the active game from the auto-generated search string.
- Reset green-letter state when a new game starts so no stale letters carry over between games.
- Preserve existing Suggest behavior (variable-position letter matching; auto-fill search input).
- Add/adjust unit tests to cover exclusion and reset behavior.
- No regressions to existing solver flows.

## Technical Notes
- Ensure per-game state management for confirmed-greens in `state/solver_state.dart` (or related) and clear on New game or equivalent trigger.
- When composing the search string in the Suggest action (likely in `widgets/solver/recommendations_panel.dart` or relevant service), remove any letters present in the current game's green set.
- Be careful not to exclude yellow letters; only omit known greens.

## QA
- Reproduce: mark some letters green; trigger Suggest; verify no green letters are included in the generated search string.
- Start a new game; ensure previously green letters are not considered.
- Run test suite; verify added tests pass.

## Labels
- type: optimization
- area: solver
- area: ui
- area: suggest
- priority: medium

/assign @dev-ro


