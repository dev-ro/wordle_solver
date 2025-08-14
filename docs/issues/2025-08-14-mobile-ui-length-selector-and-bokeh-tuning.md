# Mobile UI – Move length selector below board, relocate Green/Black toggle, and tone down bokeh

## Overview

- On vertical mobile view, the word length selector grid is cramped in the top controls area.
- The "Toggle all tiles Green/Black" control is currently in the top row, far from the color selector tiles directly under the board.
- The bokeh background effect is visually heavy with too many orbs and an overly solid inner core.

## Goals

- Relocate the word length selector to its own dedicated section placed below the game board and above recommendations (mobile-first layout).
- Move the "Toggle all tiles Green/Black" button to the right of the green/yellow color selector tiles under the board, with matching size and tap target.
- Reduce the number and intensity of bokeh orbs and redesign the center to avoid a harsh solid circle, improving legibility.

## Context and References

- Length selector (current): `lib/screens/home_screen.dart` → `_TopControls` → `Wrap` of numeric tiles (see Text 'Length: ${state.config.wordLength}')
- Board and color selector row: `lib/screens/home_screen.dart` → `_GridSection` → color selector `Wrap` (green/yellow tiles)
- Toggle action: `lib/state/solver_state.dart` → `toggleAllGreenForCurrentRow()`
- Toggle button location (current): `lib/screens/home_screen.dart` top settings row (near Auto-copy)
- Bokeh background: `lib/widgets/common/bokeh_background.dart` (see `_generateOrbs` and `_BokehPainter.paint` inner circle pass)

## Requirements

- Length selector
  - Create a new section widget (e.g., `LengthSelectorSection`) positioned between the grid and recommendations.
  - On small widths, use a responsive `Wrap` or compact grid with adequate spacing and 40–44 logical px tap targets.
  - Preserve existing behavior of `controller.setWordLength(len)` and resetting prefix; debounce recommendation recompute remains intact.
- Toggle relocation
  - Place the "Toggle all tiles Green/Black" control inline to the right of the color selector tiles under the board.
  - Match the visual dimensions of the color tiles (icon size/padding) and include a tooltip.
  - Action remains `controller.toggleAllGreenForCurrentRow()`.
- Bokeh tuning
  - Reduce orb count on small screens; lower alpha and/or radius slightly.
  - Replace or soften the inner solid core: remove the hard inner circle or render a subtle radial falloff/ring with lower opacity.
  - Maintain performance (animated builder + repaint boundary) while improving readability of foreground UI.

## Acceptance Criteria

- On a narrow/mobile viewport (portrait), the length selector is clearly spaced, fits without cramping, and has comfortable tap targets.
- The all-green/black toggle appears next to the color tiles under the board, sized consistently, and behaves as before.
- The background bokeh has fewer, softer orbs without a harsh solid inner core; foreground content becomes more legible.
- Layout adapts across phone, tablet, and desktop using `LayoutBuilder`/`MediaQuery` and avoids hardcoded screen sizes.

## Implementation Plan

1) Extract length control from `_TopControls` into a new `LengthSelectorSection` and render it between `_GridSection` and `_RecommendationsSection`.
2) Move the toggle button from the top settings row into the color selector row under the board; align icon and padding with color tiles.
3) Update `BokehBackground`:
   - `_generateOrbs`: lower `baseCount` on small `shortestSide`, slightly tweak radii/alpha.
   - `_BokehPainter.paint`: remove or reduce the inner bright core; replace with softer radial falloff.
4) Verify responsiveness with `LayoutBuilder` and spacing that scales on small widths.
5) Add tests/Golden snapshots where feasible; manually verify mobile portrait on web and device/emulator.

## Out of Scope

- Solver logic, scoring, and recommendation algorithms remain unchanged.
