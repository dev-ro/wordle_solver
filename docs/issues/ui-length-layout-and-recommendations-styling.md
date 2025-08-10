# UI: Length slider reset, long-word layout fixes, color cycling, and recommendations styling

Repo: `dev-ro/wordle_solver`

Assignee: `@dev-ro`

Labels: `ui`, `bug`, `enhancement`, `priority: medium`

## Summary

Several UI issues need addressing to improve responsiveness and interaction:

- Reset recommendations when the word length slider changes
- Fix letter centering and spacing for long words (≥ 15), ensure the row always fits on one line (no wrap/overflow up to length 20)
- Correct tap color cycling order on tiles
- Update recommendations panel to a 3×3 layout with rectangular tiles and style words by top 3 unique scores (gold/silver/bronze)

## A. Length slider should reset recommendations

### Current
- Adjusting length via the slider keeps prior recommendations visible.

### Expected
- When the length slider is changed, recommendations reset to the default placeholder state (no results until Submit is pressed again).

### Acceptance Criteria
- Changing length clears `lastResponse` so the recommendations panel shows the default prompt.
- Any in-flight loading state is reset.

### References
- Slider change wiring: `lib/screens/home_screen.dart` (length slider)
- State update logic: `lib/state/solver_state.dart` `setWordLength(...)` currently does not clear `lastResponse`.

## B. Long-word layout: centering, spacing, one-line fit

### Current
- For length ≥ 15, letters appear slightly low within tiles.
- At length 20, spacing between tiles is too large and can cause overflow/wrapping.

### Expected
- Each letter is fully centered vertically and horizontally in its tile across all lengths.
- Tile size and inter-tile spacing dynamically adjust so the entire word always fits on a single line (no wrapping) up to length 20.

### Acceptance Criteria
- Vertically/horizontally centered letters for all states (editable and locked).
- No overflow or wrapping at any supported length (3–20). The row fits within available width.
- Spacing and tile size are responsive to the container width and word length. Longer words result in smaller tiles and reduced gaps to maintain one-line fit.

### References
- Row layout and sizing: `lib/widgets/solver/feedback_row.dart` (computes `side` and `gap`) 
- Tile widget: `lib/widgets/solver/feedback_tile.dart` (TextField alignment/centering)

## C. Tap color cycling order on tiles

### Current
- Tapping through tile colors stops at green and does not return to black as expected.
- Likely due to tiles becoming read-only/locked when green, preventing further cycling.

### Expected
- On each tap, cycle feedback in this order: green → yellow → black → green → ...
- Cycling should not be blocked when a tile is green (unless it’s explicitly locked by prefix rules).

### Acceptance Criteria
- Single-tap on a tile cycles `green → yellow → black → green` repeatedly.
- Prefix-locked tiles remain immutable as intended; non-locked tiles always cycle.

### References
- Cycling utility: `lib/state/solver_state.dart` `nextFeedback(...)` supports cycling.
- Interaction wiring: 
  - `lib/widgets/solver/feedback_row.dart` (tap/long-press handlers)
  - `lib/widgets/solver/feedback_tile.dart` (currently sets `isLocked` when feedback is green)

## D. Recommendations panel layout and styling by top unique scores

### Current
- Grid columns are responsive (2–4) with `childAspectRatio: 1.2` and up to 12 items.
- No styling differences for top-ranked scores; top tile emphasized only by hover tile.

### Expected
- Display a 3×3 grid of recommendation tiles (up to 9 items), with rectangular aspect (shorter height than width).
- Compute the top 3 unique score values from the list.
  - Words with the top unique score: shiny glassy gold styling.
  - Words with the second unique score: glassy silver styling.
  - Words with the third unique score: glassy bronze styling.
- If fewer than 3 unique scores exist, style what exists and leave others with default styling.

### Acceptance Criteria
- Fixed 3 columns, up to 9 items shown, rectangular tiles (e.g., `childAspectRatio` > 1.0).
- Styling logic consistently applies to all words sharing the same score within the top 3 unique values.
- Interaction (tap to autofill; clipboard behavior) remains unchanged.

### References
- Recommendations panel: `lib/widgets/solver/recommendations_panel.dart`
- Server scoring API: `functions/main.py` (recommendations and scores)

## Steps to Reproduce

1) Length slider not resetting recommendations
- Launch app
- Press Submit to generate recommendations
- Move the length slider
- Observe recommendations remain displayed (should reset)

2) Long-word layout issues
- Set length to 15 or higher
- Type letters into tiles; observe vertical centering appears low
- Set length to 20 and observe the row may overflow or wrap due to spacing

3) Tap color cycling stuck at green
- Tap on a tile repeatedly; observe that once green, it does not cycle back to black

4) Recommendations layout and styling
- Generate recommendations
- Observe current grid count/aspect and lack of top 3 unique score styling

## Implementation Notes (non-exhaustive)

- A. Reset recommendations on length change
  - In `setWordLength(...)`, also set `lastResponse: null` and ensure loading/error states are cleared to default.

- B. One-line fit and centering for long words
  - In `FeedbackRow`, compute `gap` and `side` from available width so: `tiles.length * side + (tiles.length - 1) * gap <= maxWidth` with no clamping that forces wrap.
  - For centering in `FeedbackTile`, ensure vertical alignment for `TextField` (e.g., `textAlignVertical: TextAlignVertical.center`, consistent `StrutStyle`, and zero internal padding). Verify alignment when read-only and editable.

- C. Color cycling order
  - Allow tapping to cycle even when feedback is green. Lock only when prefix-locked instead of locking on green state.
  - Ensure the single-tap handler cycles `green → yellow → black → green`.

- D. Recommendations grid and styling
  - Use fixed `crossAxisCount: 3` and `itemCount: min(9, recs.length)`.
  - Increase `childAspectRatio` to make tiles rectangular.
  - Compute top 3 unique `score` values and branch styles accordingly (gold/silver/bronze), preserving the existing aurora/glassy aesthetic.

## Definition of Done

- All acceptance criteria in sections A–D are met.
- Verified on narrow and wide layouts; no overflow, no wrapping up to length 20.
- Color cycling works by tap as specified; long-press behavior remains consistent or is simplified to a single consistent mechanism.
- Recommendations display in a 3×3 rectangular grid with correct gold/silver/bronze styling for the top 3 unique scores.
- Unit/UI tests updated or added where practical.

## GitHub Issue Creation Instructions

- Create an issue in `dev-ro/wordle_solver` using this document content.
- Assign: `@dev-ro`
- Labels: `ui`, `bug`, `enhancement`, `priority: medium`
- Link to relevant files in the description:
  - `lib/screens/home_screen.dart`
  - `lib/state/solver_state.dart`
  - `lib/widgets/solver/feedback_row.dart`
  - `lib/widgets/solver/feedback_tile.dart`
  - `lib/widgets/solver/recommendations_panel.dart`


