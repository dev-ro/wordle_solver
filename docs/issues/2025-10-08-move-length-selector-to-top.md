# Move length selector to the top of the layout

## Overview

- The word length selector currently appears in the middle section of the page, rendered between the game grid and recommendations.
- We want the length selector positioned at the top of the main content area for quicker access before users interact with the board.

## Goals

- Relocate the length selector UI to the top area of the screen, above the grid.
- Preserve existing behavior for `controller.setWordLength(len)` and any related state updates/debounce.

## Context and References

- Current rendering order: `lib/screens/home_screen.dart` → `_GridSection` → `_LengthSelectorSection` (search for Text `Length: ${state.config.wordLength}`)
- Top controls container: `lib/screens/home_screen.dart` → `_TopControls`

## Requirements

- Render the length selector above the grid on standard layouts (desktop/tablet/phone) while keeping a clean, consistent spacing with `_TopControls`.
- Ensure the layout remains responsive using `LayoutBuilder`/`MediaQuery` and preserves 40–44 logical px tap targets on mobile.
- Do not change the solver logic or the contract of `controller.setWordLength`.

## Acceptance Criteria

- On all platforms, the length selector appears above the game board with appropriate spacing.
- Changing the length triggers the same logic as before; no regression in solver behavior or prefix reset behavior.
- No visual regressions in `_TopControls` spacing or `_GridSection` layout.

## Implementation Plan

1) Move `_LengthSelectorSection` so it renders above `_GridSection` in the main column on `HomeScreen`.
2) Align margins/padding with surrounding top controls to ensure consistent rhythm.
3) Verify responsiveness and tap target sizes across phone, tablet, and desktop.
4) Manually validate that recommendations recompute as before after a length change.

## Out of Scope

- Solver algorithms, scoring, and recommendation logic remain unchanged.
- Additional UI refactors or style changes beyond the length selector move.


