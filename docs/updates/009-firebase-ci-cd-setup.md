# Update 009: Firebase Backend, Anonymous Auth, and CI/CD Setup

**Date:** 2025-08-07  
**Branch:** main  
**Type:** Architecture  
**Impact:** High

## Overview

Set up Firebase across web, Android, and iOS with Anonymous Authentication, Python Cloud Functions for the solver engine, Firestore and Storage security rules, Hosting deploys, and a robust GitHub Actions CI/CD pipeline. Added bash scripts to standardize local and CI operations. Uploaded initial dictionaries to Cloud Storage.

## What Changed

### Firebase Configuration
- Initialized project `wordle-solver-kyle` for web, Android, iOS
- Generated `lib/firebase_options.dart` via FlutterFire
- Enabled Anonymous Auth and app initialization in `lib/main.dart`

### Cloud Functions (Python)
- Implemented stateless solver API with in-memory dictionary cache (`functions/main.py`)
- Functions: `calculate_next_move` (callable), `health_check`
- Reads dictionaries from `gs://wordle-solver-kyle.firebasestorage.app/dictionaries/`

### Firestore & Storage Rules
- Firestore: user-scoped reads/writes; authenticated create to `feedback/**`
- Storage: authenticated read for `dictionaries/**`; user-scoped paths under `users/{uid}/**`

### Hosting
- Web app build and deploy via GitHub Actions to live channel on merges to `main`

### CI/CD Workflows
- `ci.yml`: Flutter analyze/tests, Python lint/type-check/tests, bash scripts validation, secret scan
- `firebase-hosting-merge.yml`: Build and deploy web to Hosting on merge
- `firebase-hosting-pull-request.yml`: Build + preview deploys on PRs
- `deploy-functions.yml`: Validate and deploy Python Functions
- `deploy-database.yml`: Validate and deploy Firestore/Storage rules
- `update-dictionaries.yml`: Validate JSON and upload to Storage

### Developer Tooling (Bash Scripts)
- `scripts/setup.sh`: environment checks and Flutter setup
- `scripts/deploy.sh`: deploy targets (all/hosting/functions/database/firestore/storage)
- `scripts/upload-dictionaries.sh`: validate and upload `assets/words/*.json`

## Why These Changes Matter

- Establishes a secure, scalable backend with minimal latency (warm cache)
- Ensures frictionless auth via anonymous sign-in
- Automates quality gates and deployments
- Provides repeatable, dev-friendly workflows without Node/npm coupling

## Technical Highlights

- In-memory dictionary caching inside Cloud Functions to avoid repeated GCS reads
- Callable function contract for solver; strict input validation
- Storage bucket uses new Firebase domain: `wordle-solver-kyle.firebasestorage.app`
- CI replaces npm scripts with bash, improving portability and clarity

## Impact on Users

- Faster solver responses after warm start
- Anonymous usage out-of-the-box
- Reliable releases via automated build/test/deploy

## Related Documentation

- `firebase.json`, `firestore.rules`, `storage.rules`
- `functions/main.py`, `functions/requirements.txt`
- `.github/workflows/*`
- `scripts/*.sh` (deployment and operations)

---
*Building in public: Follow @YourHandle for more updates*
