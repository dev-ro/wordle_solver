# Update 011: Public Web App, ZenSort Pause, and Community Dictionary Roadmap

**Date:** 2025-08-11  
**Branch:** main  
**Type:** Announcement  
**Impact:** High

## Overview

Paused development on ZenSort (YouTube likes organizer) to productize my portfolio Wordle solver into a user‑friendly Firebase app. The refactor is largely complete and the web app is live. The next focus area is dictionary quality and multi‑language expansion via a community‑supported workflow.

## What Changed

- Responsive Flutter UI with tap‑to‑color feedback and recommendation flow
- Python Cloud Functions with in‑memory dictionary caching
- CI/CD pipelines for analyze/format, tests, hosting deploys, and dictionary uploads
- Live web deployment for immediate access

## Where to play/test

- Live app: https://wordle-solver-kyle.web.app/
- Twitch Wordle (optimized target): https://www.twitch.tv/twordletv
- Official Wordle (NYT): https://www.nytimes.com/games/wordle

## Why This Matters

The solver is only as good as the dictionaries behind it. Opening the project publicly enables faster iteration on coverage, language support, and overall result quality.

## Roadmap

- Community dictionary contributions with validation and automated publishing
- Research and add more languages; improve handling of variants and proper nouns
- Feedback UX for missing words directly in‑app (ties to backend review queue)
- Solver analytics (opt‑in) to guide dictionary improvements

## How to Contribute

- File an issue tagged “dictionary” with missing words or sources
- Submit a PR updating `assets/words/english.json` or `assets/words/spanish.json` (lowercase entries)
- Propose additional language packs

## Related Documentation

- `README.md` (usage, limitations, and contribution guidance)
- `docs/references/Optimized Architectural Plan.md`
- `functions/main.py`, `functions/test_main.py`
- `scripts/upload-dictionaries.sh`

---
*Building in public: follow for more Wordle Solver updates*


