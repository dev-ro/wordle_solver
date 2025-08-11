# Wordle Solver (Flutter + Firebase)

A fast, feedback‑driven Wordle assistant with a clean Flutter UI and a fully client‑side solver. Firebase is used for auth and hosting dictionaries in Storage.

## Play and test

- Live app: [wordle-solver-kyle.web.app](https://wordle-solver-kyle.web.app/)
- Twitch Wordle (primary target the UI is optimized for): [twitch.tv/twordletv](https://www.twitch.tv/twordletv)
- Official Wordle (NYT): https://www.nytimes.com/games/wordle

## Overview

I paused development on ZenSort (my YouTube likes organizer) to productize my Wordle solver script into a public, user‑friendly app. The refactor is largely complete and deployed; current efforts focus on dictionary coverage and multi‑language support.

## Features

- Variable word length (3–20) with responsive single‑row fit
- Prefix deduction: first green on first submission auto‑locks the prefix; quick Clear control available (see [PR #27](https://github.com/dev-ro/wordle_solver/pull/27))
- Tap‑to‑color tiles: cycle Gray → Yellow → Green; greens carry forward to the next row (see [PR #9](https://github.com/dev-ro/wordle_solver/pull/9))
- Keyboard support: type letters, Enter to submit, Backspace navigation; selection management across tiles (see [PR #26](https://github.com/dev-ro/wordle_solver/pull/26), closes [#13](https://github.com/dev-ro/wordle_solver/issues/13))
- Ranked recommendations strictly from remaining candidates; scores computed from full dictionary for stability (see [PR #4](https://github.com/dev-ro/wordle_solver/pull/4))
- Remaining words preview and count
- Filler words
  - Manual search: type letters like "bhptw" to find words covering them
  - Auto‑suggest: derives letters from variable positions in remaining candidates (see [PR #25](https://github.com/dev-ro/wordle_solver/pull/25))
- Auto‑copy toggle: tapping a recommendation can autofill and copy `!word` for Twitch chat (see [Issue #7](https://github.com/dev-ro/wordle_solver/issues/7), [PR #9](https://github.com/dev-ro/wordle_solver/pull/9))

## How to use (Web)

1. Open the app: `https://wordle-solver-kyle.web.app/`
2. Set word length (default 5). Prefix is deduced automatically the first time you submit with a green first tile.
3. Type a guess or tap a recommendation to auto‑fill. Optional: enable Auto‑copy for Twitch.
4. Tap tiles to cycle feedback: Gray → Yellow → Green.
5. Submit to get updated recommendations and remaining‑words count.
6. Repeat until solved. Use Confirm Win/New Game when done (see [PR #28](https://github.com/dev-ro/wordle_solver/pull/28)).

## Dictionaries: limitations and roadmap

The solver is only as good as its dictionaries. Missing words won’t be suggested.

Current dictionaries:
- `assets/words/english.json`
- `assets/words/spanish.json`

Planned improvements:
- Community dictionary workflow and Firebase Storage pipeline (see open [#16](https://github.com/dev-ro/wordle_solver/issues/16))
- Expanded coverage and additional languages (see open [#17](https://github.com/dev-ro/wordle_solver/issues/17))
- In‑app “missing word” feedback UX

Contribute now:
- Open an issue tagged “dictionary” with missing words or sources
- Submit a PR updating the JSON lists (lowercase, one word per entry)

## Architecture

Frontend (Flutter):
- Riverpod state (`lib/state/solver_state.dart`, `lib/state/filler_state.dart`)
- UI in `lib/screens/home_screen.dart` with responsive layout and keyboard handling
- Components: `lib/widgets/solver/feedback_row.dart`, `feedback_tile.dart`, `recommendations_panel.dart`, `filler_results.dart`
- Local dictionary loading for filler features (`lib/services/filler_words_service.dart`)

Backend:
- None required on the critical path. Solver runs fully client-side.
- Firebase Storage hosts dictionaries; app reads via client SDK with asset fallback.

CI/CD & Security:
- Workflows in `.github/workflows/ci.yml` for Flutter, coverage, and security scans (OSV‑Scanner, TruffleHog)
- Bash scripts: `scripts/format.sh`, `scripts/deploy.sh`, `scripts/upload-dictionaries.sh`

Further reading:
- `docs/updates/009-firebase-ci-cd-setup.md`
- `docs/updates/010-solver-ui-and-ci-hardening.md`
- `docs/references/Optimized Architectural Plan.md`
- Issue notes: `docs/issues/15-prefix-deduction-and-tile-outline.md`, `docs/issues/ui-length-layout-and-recommendations-styling.md` (addressed by [PR #23](https://github.com/dev-ro/wordle_solver/pull/23))

## Project status and history

Highlights (recent merged PRs):
- [PR #33](https://github.com/dev-ro/wordle_solver/pull/33) keyboard overwrite of green/prefix tiles (fixes [#31](https://github.com/dev-ro/wordle_solver/issues/31))
- [PR #32](https://github.com/dev-ro/wordle_solver/pull/32) unlock prefix on filler; auto‑fill greens (fixes [#30](https://github.com/dev-ro/wordle_solver/issues/30))
- [PR #27](https://github.com/dev-ro/wordle_solver/pull/27) prefix deduction + borders (see [#15](https://github.com/dev-ro/wordle_solver/issues/15))
- [PR #25](https://github.com/dev-ro/wordle_solver/pull/25) advanced filler words
- [PR #23](https://github.com/dev-ro/wordle_solver/pull/23) length reset, long‑word layout, color cycling, 3×3 styled recommendations (addresses [#22](https://github.com/dev-ro/wordle_solver/issues/22))
- [PR #9](https://github.com/dev-ro/wordle_solver/pull/9) UI refresh: auto‑copy, submit flow, green‑lock behavior
- [PR #4](https://github.com/dev-ro/wordle_solver/pull/4) solver UI and alignment

Open focus areas:
- [#17](https://github.com/dev-ro/wordle_solver/issues/17) Research and Implement an Expanded Dictionary
- [#16](https://github.com/dev-ro/wordle_solver/issues/16) Community Dictionary Updates via Firebase Storage

Repo:
- `dev-ro/wordle_solver` — https://github.com/dev-ro/wordle_solver

## Local development

Prerequisites: Flutter 3.32.x and Dart ^3.8.x.

1) Install
```bash
git clone https://github.com/dev-ro/wordle_solver.git
cd wordle_solver
flutter pub get
```

2) Run
```bash
flutter run
```

3) Scripts
```bash
./scripts/format.sh
./scripts/deploy.sh
./scripts/upload-dictionaries.sh
```

## Contributing

- Issues‑first; one logical change per PR using Conventional Commits
- Before committing Dart changes, run:
```bash
./scripts/format.sh
```

Dictionary PR tips: lowercase entries, one per JSON element; include a short source/rationale.

## License

MIT. See `LICENSE`.

## Acknowledgments

Inspired by Wordle (Josh Wardle). Built with Flutter and Firebase. Thanks to open‑source word lists for seeds.

— Happy Wordling!