# Update: Dictionary ingestion — Firestore first + scheduled publisher

## Overview

Change the ingestion flow so new words are written to Firestore first (after validation), then a scheduled job runs every 6 hours to merge approved submissions into the authoritative dictionary automatically.

## New Requirements

- Client submissions do not write directly to Cloud Storage.
- New words must be validated before being accepted into Firestore:
  - Correct length and charset
  - Lowercase normalized
  - Meets all existing solver validity criteria
  - Consistent with all prior feedback constraints (greens/yellows/blacks) captured so far
  - Submission MUST include the full game feedback history (per-guess `guess`/`feedback` pairs) used to discover the missing word; backend will validate the word against this history
- A scheduled backend process runs every 6 hours to publish:
  - Reads pending submissions from Firestore
  - Performs a second validation pass (idempotent)
  - Deduplicates and resolves conflicts
  - Updates the source-of-truth dictionary
  - Refreshes caches

## Data Model (updated)

- Collection: `dictionary/submissions` (or `feedback/missingWords`)
  - Fields:
    - `word: string` — lowercased candidate word
    - `language: string` — e.g., `en`, `es`
    - `dictionary: string` — e.g., `english.json`, `spanish.json`
    - `wordLength: number` — e.g., 5, 6, 7
    - `prefix?: string` — optional first-letter prefix constraint for some game modes
    - `feedbackHistory: Array<{ guess: string, feedback: string }>` — complete history from the specific game where the missing word was discovered; `feedback` uses `g` (green), `y` (yellow), `b` (black); lengths must match `wordLength`
    - `gameId?: string` — optional client/session identifier
    - `submittedAt: timestamp`
    - `submitterId?: string`
    - `status: 'pending' | 'approved' | 'rejected'`
    - `reasons?: string[]` — machine-generated reasons on rejection (e.g., `does not contain letter X`, `yellow L cannot be at position 4`, `must have L at position 2`, `exceeds allowed count of letter D`)
    - `processedAt?: timestamp`
    - `processorVersion?: string` — semantic version or commit identifying the validator
- Collection (optional): `dictionary/published`
  - Audit records for published batches

## Scheduled Publisher (every 6 hours)

- Name: `scheduledPublishDictionaries`
- Steps:
  1. Query `status == 'pending'`
  2. Validate each word again (same rules as above) using the same constraint logic as the client solver against `feedbackHistory`
  3. Merge into dictionary (Storage or repo-backed source of truth)
  4. Mark processed items as `approved` or `rejected` with `reasons[]`
  5. Update any in-memory/edge caches
- Properties:
  - Idempotent (safe to retry)
  - Logs and metrics for visibility

## Implementation Notes

- Runtime: Google Cloud Functions (2nd gen) using Python 3.12 (venv for local dev)
- Trigger: HTTPS function invoked by Cloud Scheduler every 6 hours; also invokable on-demand
- Dictionary location: Firebase Storage path `dictionaries/<dictionary>` (e.g., `dictionaries/english.json`)
- Validator logic: mirror of client `filterPossibleWords` (see `lib/solver/solver_engine.dart`) and prototype `docs/references/wordle.py`. On rejection, populate human-readable `reasons[]` derived from the first failing constraint(s).

## Acceptance Criteria

- New words are not written to Storage directly.
- Only validated words make it into Firestore, and only approved words are published by the scheduled job.
- Publisher runs every 6 hours and can be triggered manually for backfills.
- Validation enforces length, charset, normalization, and compatibility with all prior feedback.
- Submissions include `feedbackHistory` and the backend uses it to validate/approve.
- Rejections include `reasons[]` populated by the validator.
