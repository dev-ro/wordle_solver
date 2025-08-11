## Issue #16 — Migrate solver to client-side (remove Cloud Functions dependency)

### Overview
Make the app faster and more resilient by running the Wordle solver logic entirely on the client. Keep dictionaries in Firebase Storage. Remove server-side Cloud Functions from the solve path while preserving identical results and UX.

### Problem
- Current flow calls a Cloud Function (`calculate_next_move`) for every submit, adding network latency and cold-start penalties.
- Solver logic is already deterministic and stateless; it is suitable for client execution.
- Dictionaries are centrally managed; we still need a single source of truth (Firebase Storage) but can cache aggressively client-side.

### Goals
- Eliminate Cloud Function calls for solver logic.
- Preserve results parity with the existing Python implementation.
- Load dictionaries from Firebase Storage with in-memory caching and an offline fallback to bundled assets.
- Keep UI unchanged; use isolates to avoid jank.

### Non-Goals
- Removing Firebase Storage or changing dictionary authoring/upload pipeline.
- Large UI/UX changes beyond wiring to the local solver.
- Removing server code immediately (keep a short deprecation window).

### Proposed Changes
1) Add a client-side solver module in Dart mirroring Python logic in `functions/main.py`:
   - `calculateLetterFrequency`
   - `normalizeLetterFrequencies`
   - `calculateGuessScore`
   - `filterPossibleWords`
   - `recommendGuesses`
   - `findVariableLetterPositions`

2) Introduce a `DictionaryService` to fetch and cache word lists:
   - Primary source: Firebase Storage path `dictionaries/<name>.json` (auth via existing anonymous auth).
   - In-memory cache keyed by dictionary filename.
   - Offline fallback: `assets/words/<name>.json` (already bundled).
   - Optional: persistent cache (future enhancement).

3) Replace `SolverRepository` implementation:
   - Keep the public method signature `calculateNextMove({config, history})` so `SolverController.requestRecommendations()` remains unchanged.
   - Internally, load dictionary via `DictionaryService`, apply Python-parity filtering/scoring, and return `SolverResponse`.
   - Run the heavy work in an isolate (`Isolate.run`/`compute`) to keep UI responsive.

4) Deprecate Cloud Functions path:
   - Feature flag or provider swap to toggle local vs remote during rollout.
   - Remove `cloud_functions` dependency once validated.
   - Keep server function for a short fallback period, then delete.

### Acceptance Criteria
- [ ] Submitting a guess no longer calls `FirebaseFunctions.httpsCallable('calculate_next_move')`.
- [ ] Local solver returns recommendations, remaining words/count, variable positions, and filler suggestions identical to server for a test corpus of scenarios.
- [ ] No jank on UI thread (main solve runs in an isolate for 5–10 letter words with typical dictionary sizes).
- [ ] Dictionary loads from Firebase Storage when online; falls back to bundled assets when offline.
- [ ] Caching prevents re-downloading the same dictionary during the session.
- [ ] Works on Android, iOS, Web, macOS, Windows, Linux.

### Implementation Plan
Phase 1 — Foundations
- [ ] Create `lib/services/dictionary_service.dart` with:
  - `Future<List<String>> loadDictionary(String filename)`
  - Source: Firebase Storage (`firebase_storage`), path `dictionaries/`.
  - Fallback: `rootBundle` from `assets/words/`.
  - In-memory cache Map<String, List<String>>.

- [ ] Create `lib/solver/solver_engine.dart` with ported functions from Python:
  - Unit-tested, pure functions; no I/O.

Phase 2 — Repository swap
- [ ] Add `lib/repositories/solver_repository_local.dart` implementing `calculateNextMove` using the new engine and dictionary service; return `SolverResponse`.
- [ ] Wire `solverRepositoryProvider` to the local implementation (feature flag or direct swap).
- [ ] Ensure `SolverController.requestRecommendations()` remains unchanged.

Phase 3 — Performance + parity
- [ ] Execute solver in an isolate using `compute`/`Isolate.run` with a DTO payload to/from the isolate.
- [ ] Add unit tests translating `functions/test_main.py` into Dart `test/` covering parity cases.
- [ ] Add a small golden set of history/config inputs to assert identical outputs vs. captured server responses.

Phase 4 — Cleanup
- [ ] Remove `cloud_functions` dependency from `pubspec.yaml` and imports in `lib/repositories/solver_repository.dart`.
- [ ] Gate or remove server code in `functions/` after a deprecation window; update deployment scripts accordingly.
- [ ] Update docs and README.

### Touch Points
- `lib/repositories/solver_repository.dart` (replace remote with local)
- `lib/state/solver_state.dart` (no API changes; ensure loading/error flows remain)
- `lib/services/filler_words_service.dart` (optionally reuse logic or unify with solver for filler suggestions)
- `lib/main.dart` (no changes; anonymous auth stays for Storage)

### Risks / Mitigations
- Performance on low-end devices: Mitigate with isolates and minimal allocations.
- Large dictionaries on web: Consider chunked download or rely on cached CDN; enforce reasonable `maxSize` when using `getData`.
- Result parity drift: Lock parity tests and sample fixtures before decommissioning the server.

### Telemetry (optional)
- Track dictionary load source (storage vs assets) and solve durations (main + isolate) for performance insights.

### Dev Notes
- Follow Flutter guidance for background computation using `Isolate.run`/`compute`.
- Keep functions pure and testable; avoid UI dependencies in solver code.
- Maintain commit standards and run `flutter analyze --fatal-infos` and `dart format .` before commits/PRs.

### Definition of Done
- Local solver is the default path across platforms, passes parity tests, and meets performance targets.
- Cloud Function path is removed or disabled by default.

