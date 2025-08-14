# Feedback dialog (AppBar button) writing to Firestore with IP rate limiting

## Overview

Add a user-facing feedback dialog accessible from the AppBar (next to the Help button) that allows any user to submit general feedback and feature requests. Submissions are written to Firestore. Protect against spam by restricting submissions to at most one per IP address per hour.

## Goals

- Provide a clearly labeled Feedback button in the AppBar, next to the existing Help icon.
- Show a modal dialog with a multiline text field and optional metadata (e.g., contact optional), and a Submit button.
- On submit, write a document to Firestore under `feedback/appImprovements` (or a new `feedback/appFeedback`) with fields: `message`, `createdAt`, `clientIpHash` (or `ip` if stored via backend), and `appVersion` if available.
- Enforce rate limit of one submission per IP per hour.

## Context and References

- AppBar and Help button: `lib/screens/home_screen.dart` → `_AppBarWithHelp`
- Firestore rules: `firestore.rules` currently allow `create` under `feedback/**` for authenticated users.
- Firebase project: `wordle-solver-kyle`

## Requirements

- UI
  - Add a Feedback icon/button to the right of the Help icon in `_AppBarWithHelp`.
  - Modal dialog with labeled textarea and character counter; disable submit when empty or over limit (e.g., 1–2k chars).
- Data write
  - Create document fields: `{ message: string, createdAt: serverTimestamp, platform: string, appVersion?: string }`.
- Rate limiting
  - Use a backend guard to enforce one-per-IP-per-hour. Options:
    1) Cloud Function HTTP endpoint that forwards to Firestore with IP limit enforcement (preferred, avoids exposing IP from client).
    2) Temporary client-side hash of public IP via a service and store hash; still needs backend validation for true enforcement.
  - Implement solution (1) as part of this issue scope: a minimal Cloud Function endpoint that checks a TTL key (e.g., Firestore/RTDB doc or in-memory + Firestore) and rejects if within an hour.
- Auth
  - Allow anonymous auth; ensure client initializes Firebase before making the request.

## Acceptance Criteria

- Feedback button is visible next to Help in the AppBar on all platforms.
- Submitting valid feedback creates a record in Firestore via the guarded endpoint; rejected within one hour if multiple attempts from same IP.
- UI prevents empty submissions and provides success/error feedback.
- Security rules remain satisfied; no sensitive data written by unauthenticated users beyond allowed feedback collection.

## Notes

- If deploying a function is out-of-scope for this sprint, implement the UI and wire it to a placeholder service; keep the IP-rate-limit guard behind a feature flag until the endpoint is live.
