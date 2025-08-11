## Issue #15 — Prefix deduction and tile outline clarity

### Overview
Keep the prefix feature, but remove manual prefix input from Settings. Automatically deduce the prefix from user input. Update tile borders so the selected tile is unmistakably distinct from the prefix indicator; only one tile should appear selected at a time.

### Problem
- Manual prefix input in Settings adds friction and can diverge from gameplay.
- Prefix tile border looks too similar to the selected tile border, making selection unclear.

### Proposed Changes

#### 1) Prefix deduction (replace manual prefix input)
- Remove the prefix input from Settings UI.
- Deduce the prefix when a user submits a guess that:
  - Starts with a green (correct) character in the first position, and
  - All remaining tiles in that word are unset/blank/black.
- When this pattern is detected, set that first green character as the global prefix.
- Treat the prefix as fixed until the user explicitly clears/resets it.

Notes:
- If a later guess conflicts with the deduced prefix, do not auto-clear. Provide a lightweight way to clear/reset prefix instead, keeping constraints consistent.

#### 2) Tile outline clarity (selection vs prefix)
- Exactly one tile can be selected at any time.
- Selection border must be visually dominant and unique.
- Prefix border must be visually distinct and clearly secondary to selection; when a prefix tile is selected, selection styling overrides.

Styling guidelines (adaptive, theme-aware, no hardcoded sizes):
- Use theme tokens (e.g., `Theme.of(context).colorScheme.*`) for colors.
- Use semantic border width tokens or theme-based values rather than fixed pixels.
- Avoid glows/shadows for the prefix state; keep it subtle compared to selection.
- Respect responsive/adaptive layout rules (no hardcoded widths/heights).

### UX Details
- Remove prefix field from Settings; do not add a replacement input.
- When a prefix is active, show a small, contextual “Clear prefix” control near the grid header or prefix indicator.
  - Action: clears the deduced prefix and re-runs filtering.
- If a UI prefix hint (badge/chip/label) is shown, ensure it cannot be confused with selection styling.
- When the prefix tile is selected, show selection styling only (prefix border suppressed).

### Acceptance Criteria
- [ ] Manual prefix input removed from Settings UI
- [ ] Submitting a word with first tile green and all others unset/blank/black deduces that first green character as the prefix
- [ ] Prefix is applied consistently to filtering/recommendations once deduced
- [ ] A visible, lightweight control exists to clear the prefix; clearing re-computes recommendations
- [ ] Exactly one tile appears selected at any time
- [ ] Selection border is visually dominant and distinct from prefix border
- [ ] Prefix border is visible only when the tile is not selected
- [ ] Styling is theme-aware, responsive, and accessible (sufficient contrast)

### Out of Scope
- Changes to non-prefix constraint logic
- Keyboard behavior changes beyond the deduction trigger described above

### Implementation Notes
- Likely touch points:
  - `lib/screens/home_screen.dart` (selection handling; settings area cleanup)
  - `lib/widgets/solver/feedback_row.dart`, `lib/widgets/solver/feedback_tile.dart` (border rendering/state)
  - `lib/state/solver_state.dart` and/or `lib/state/filler_state.dart` (store deduced prefix; clear action; recompute triggers)
  - `lib/widgets/solver/recommendations_panel.dart` (if displaying or depending on prefix)
- Add dedicated actions in state to set and clear the prefix; ensure downstream recomputation and UI updates.
- Keep all visuals theme-driven; avoid hardcoded pixel values.

### Test Scenarios
- Deduction fires only when: first tile is green and all other tiles are unset/blank/black
- Deduction does not fire if any non-first tile is non-blank, or the first tile is not green
- After deduction, the grid indicates the prefix appropriately and recommendations reflect it
- Clearing prefix removes the indicator and updates recommendations
- Selection is always unique and visually distinct; when selecting the prefix tile, selection styling overrides
