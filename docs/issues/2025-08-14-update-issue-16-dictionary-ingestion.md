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
- A scheduled backend process runs every 6 hours to publish:
  - Reads pending submissions from Firestore
  - Performs a second validation pass (idempotent)
  - Deduplicates and resolves conflicts
  - Updates the source-of-truth dictionary
  - Refreshes caches

## Data Model (proposed)

- Collection: `dictionary/submissions` (or `feedback/missingWords`)
  - Fields: `{ word: string, language: string, submittedAt: timestamp, submitterId?: string, status: 'pending'|'approved'|'rejected', reason?: string }`
- Collection (optional): `dictionary/published`
  - Audit records for published batches

## Scheduled Publisher (every 6 hours)

- Name: `scheduledPublishDictionaries`
- Steps:
  1. Query `status == 'pending'`
  2. Validate each word again (same rules as above)
  3. Merge into dictionary (Storage or repo-backed source of truth)
  4. Mark processed items as `approved` or `rejected` with `reason`
  5. Update any in-memory/edge caches
- Properties:
  - Idempotent (safe to retry)
  - Logs and metrics for visibility

## Acceptance Criteria

- New words are not written to Storage directly.
- Only validated words make it into Firestore, and only approved words are published by the scheduled job.
- Publisher runs every 6 hours and can be triggered manually for backfills.
- Validation enforces length, charset, normalization, and compatibility with all prior feedback.
