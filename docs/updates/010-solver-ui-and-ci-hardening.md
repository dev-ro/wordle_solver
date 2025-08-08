# Update 010: Solver UI, Alignment, and CI Hardening

**Date:** 2025-08-08  
**Branch:** feat/ui-refresh-and-typing-flow  
**Type:** Enhancement  
**Impact:** High

## Overview

Improved the solver UX with auto-copy and submission flow, aligned board feedback semantics (prefix and greens lock-in), and fixed CI analyzer/formatting issues. Added a hard rule to always run `dart format` before opening PRs.

## What Changed

### UI/Typing Flow
- Added Auto-copy toggle in top controls; tapping a recommendation autofills and copies `!{word}` (lowercase) to clipboard and shows a toast
- Renamed action to "Submit" with a send icon; submission triggers recommendations
- Prefix letter is treated as green by default (correct position) and locked
- Green tiles are read-only and automatically carried forward to the next row to lock positions

### Solver Alignment
- If no feedback is set, assume black for all tiles; if prefix exists, first tile is green and others black
- Recommendations continue to appear after first guess; row is consumed when complete and a new row is appended

### CI Hardening
- Replaced deprecated `withOpacity` calls with `withValues(alpha: ...)`
- Removed unnecessary imports to satisfy the analyzer
- Added workflow rule to always run `dart format .` immediately before creating PRs
- Clarified the mandate that the last two steps are always: format, then commit (and if further edits occur, format again before committing)

## Why These Changes Matter

These changes streamline workflow during play (auto-copy, submit), ensure semantics match Wordle (greens/prefix lock-in), and keep CI green by enforcing formatting and analyzer compliance.

## Technical Highlights

- Clipboard integration via `Clipboard.setData(ClipboardData(text: '!'+word.toLowerCase()))`
- Locked tiles implemented by treating green tiles as read-only and transferring them to the next row
- Analyzer compliance via `Color.withValues(alpha: ...)` instead of deprecated `withOpacity`
- New rule in `.cursor/rules/10-git-workflow.mdc` to run `dart format .` pre-PR

## Impact on Users

- Faster submissions with auto-copy
- Clearer feedback alignment; correct letters are locked and carried forward automatically
- Fewer CI failures and faster merges

## Related Documentation

- `.cursor/rules/10-git-workflow.mdc`

---
*Building in public: Follow @YourHandle for more ZenSort development updates*

# Update 010: Solver UI, Solver Alignment, and CI Hardening

**Date:** 2025-08-08  
**Branch:** feat/ui-solver-screens  
**Type:** Feature  
**Impact:** High

## Overview

Implemented the initial responsive solver UI with improved typing/toggle UX, aligned Cloud Functions recommendation logic with the reference prototype, and hardened CI with formatting, tests, Android build fixes, and security scans.

## What Changed

### UI/UX
- Responsive `HomeScreen` with grid and recommendations panel
- Tap-to-cycle tile colors; long-press supported
- Auto-advance typing with focus handling; backspace navigation
- Uppercase display on input (stored lowercase for backend)
- Word length control via slider (3–20) with dynamic grid sizing

### Functions (Python)
- Recommend strictly from filtered candidates after feedback
- Score frequencies from full dictionary for stability (prototype parity)
- Lint/type fixes (flake8, mypy) and unit tests (11/11 green)

### CI/CD & Security
- Flutter 3.32.8 (Dart ^3.8.x) in workflows
- Android: minSdkVersion 23, NDK 27.0.12077973 to satisfy Firebase plugins
- Formatting via `scripts/format.sh` (used in CI)
- Minimal Flutter widget test avoiding Firebase init
- Security scans: pip-audit, OSV-Scanner, TruffleHog filesystem mode

## Why These Changes Matter

- Delivers the core end-to-end solver experience with fast feedback entry
- Ensures recommendation correctness and consistent scoring
- Establishes reliable CI with security posture improvements

## Technical Highlights

- Riverpod state controller for grid/feedback workflow
- Callable Functions integration (`calculate_next_move`)
- Provider overrides in tests to avoid Firebase initialization
- Robust TruffleHog install from releases; OSV scanning of manifests

## Impact on Users

- Faster, more accurate solver suggestions
- Smoother typing/toggle interactions and wide device support
- Greater reliability of builds and deployments

## Related Documentation

- `docs/references/Optimized Architectural Plan.md`
- `.github/workflows/*.yml`
- `functions/main.py`, `functions/test_main.py`
- `scripts/format.sh`

---
*Building in public: Follow @YourHandle for more Wordle Solver updates*
