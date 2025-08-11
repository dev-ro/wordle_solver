# Wordle Solver (Flutter + Firebase)

Solve Wordle-style puzzles faster with intelligent, feedback-driven recommendations.

Try it now: `https://wordle-solver-kyle.web.app/`

## What is this?

I paused work on ZenSort (my YouTube likes organizer) to turn my portfolio Wordle script into a user‑friendly, cross‑platform app powered by Firebase. The refactor is mostly complete; remaining work focuses on dictionary coverage and multi‑language expansion.

## How to use (Web)

1. Open the app: `https://wordle-solver-kyle.web.app/`
2. Choose word length (default 5). Optionally set a prefix.
3. Type a guess or tap a recommendation to auto‑fill.
4. Tap tiles to cycle feedback: Gray → Yellow → Green.
5. Submit to get the next set of optimal recommendations and remaining‑words count.
6. Repeat until solved.

Tips:
- Prefix letters are treated as locked greens (when set).
- Recommendations favor distinct, high‑information letters early; later guesses allow duplicates when helpful.

## Live features

- Multi‑language baseline: English and Spanish
- Variable word length and optional prefix
- Tap‑to‑color feedback grid and responsive layout
- Ranked recommendations and filler‑word analysis

## Where to play/test

- Live app: [wordle-solver-kyle.web.app](https://wordle-solver-kyle.web.app/)
- Twitch Wordle (optimized target): [twitch.tv/twordletv](https://www.twitch.tv/twordletv)
- Official Wordle (NYT): https://www.nytimes.com/games/wordle

## Limitations and roadmap (dictionaries)

The solver is only as good as its dictionaries. If a word is missing, it will not be suggested.

Current dictionaries:
- `assets/words/english.json`
- `assets/words/spanish.json`

Planned improvements:
- Community‑supported dictionary contributions (additions/removals with review)
- Automated CI to validate and publish dictionary updates
- Additional languages (research ongoing) and better handling of proper nouns/variants

How you can help today:
- Open an issue tagged “dictionary” with missing words, sources, or language packs
- Or submit a PR updating the JSON lists (keep all lowercase, one word per entry)

## Project status and tracking

- Active development; core refactor largely done
- Focus: dictionary quality and language expansion
- See repository Issues and Pull Requests for all open/closed work items

## Architecture overview

- Flutter front end with clean, responsive UI (Riverpod state, repository pattern)
- Python Cloud Functions backend with in‑memory cached dictionaries
- Firebase Hosting, Firestore (feedback), and Cloud Storage (dictionaries)

Further reading: `docs/references/Optimized Architectural Plan.md`

## Local development

Prerequisites: Flutter SDK and Dart.

1. Clone and install
   ```bash
   git clone <this-repo-url>
   cd wordle_solver
   flutter pub get
   ```
2. Run
   ```bash
   flutter run
   ```

Scripts for CI/CD and operations live in `scripts/` (e.g., `analyze.sh`, `format.sh`, `deploy.sh`, `upload-dictionaries.sh`).

## Repository tour

- `lib/` Flutter app (UI, state, services)
- `functions/` Python solver API and tests
- `assets/words/` Dictionaries (JSON)
- `scripts/` DevOps helpers
- `docs/` Updates, references, and issue notes

## Contributing

Contributions are welcome—especially for dictionary coverage and new languages. Please keep PRs focused and reference the related issue.

Before committing Dart changes, run:
```bash
flutter analyze --fatal-infos
dart format .
```

## License

MIT. See `LICENSE`.

## Acknowledgments

- Inspired by Wordle by Josh Wardle
- Built with Flutter and Firebase
- Thanks to community word‑list projects for seed dictionaries

— Happy Wordling!