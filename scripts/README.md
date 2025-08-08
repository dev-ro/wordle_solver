# Wordle Solver Scripts

This directory contains bash scripts for managing the Wordle Solver Flutter application.

## 🚀 Available Scripts

### `./scripts/setup.sh`
**Setup development environment**
- Checks Flutter, Firebase CLI, and Google Cloud CLI installation
- Configures Flutter dependencies
- Verifies Firebase project setup
- Makes all scripts executable

```bash
./scripts/setup.sh
```

### `./scripts/deploy.sh [target]`
**Deploy to Firebase**

Available targets:
- `all` - Deploy everything (default)
- `hosting` - Deploy Flutter web app to Firebase Hosting
- `functions` - Deploy Cloud Functions
- `database` - Deploy Firestore and Storage rules
- `firestore` - Deploy Firestore rules only
- `storage` - Deploy Storage rules only

```bash
# Deploy everything
./scripts/deploy.sh all

# Deploy specific targets
./scripts/deploy.sh hosting
./scripts/deploy.sh functions
./scripts/deploy.sh database
```

### `./scripts/upload-dictionaries.sh`
**Upload dictionary files to Cloud Storage**
- Validates JSON dictionary files
- Uploads to Firebase Storage
- Sets proper metadata and caching
- Deploys storage rules

```bash
./scripts/upload-dictionaries.sh
```

### `./scripts/format.sh`
**Format Dart code (CI-consistent)**

Runs `dart format --set-exit-if-changed .` to ensure consistent formatting locally and in CI.

```bash
./scripts/format.sh
```

## 📋 Prerequisites

### Required Tools:
- **Flutter SDK** - For building the mobile/web app
- **Firebase CLI** - For deployment and project management
- **Google Cloud CLI** - For advanced storage operations (optional)

### Installation:

```bash
# Flutter (follow official guide)
# https://flutter.dev/docs/get-started/install

# Firebase CLI
npm install -g firebase-tools
# OR
curl -sL https://firebase.tools | bash

# Google Cloud CLI (optional)
# https://cloud.google.com/sdk/docs/install
```

## 🔐 Authentication

Make sure you're authenticated with:

```bash
# Firebase
firebase login

# Google Cloud (optional, for dictionary uploads)
gcloud auth login
gcloud config set project wordle-solver-kyle
```

## 🎯 Common Workflows

### Initial Setup
```bash
# 1. Setup development environment
./scripts/setup.sh

# 2. Deploy everything for first time
./scripts/deploy.sh all

# 3. Upload dictionaries
./scripts/upload-dictionaries.sh
```

### Development Workflow
```bash
# Make changes to Flutter code
flutter run -d web  # Test locally

# Deploy web app
./scripts/deploy.sh hosting

# Deploy functions after changes
./scripts/deploy.sh functions
```

### Dictionary Management
```bash
# Add new words to assets/words/*.json files
# Then upload them:
./scripts/upload-dictionaries.sh
```

## 🛠️ Script Features

- **🎨 Colored output** - Easy to read logs
- **✅ Error checking** - Scripts exit on failures
- **🔍 Validation** - JSON validation for dictionaries
- **📊 Progress feedback** - Clear status messages
- **🔧 Flexible targets** - Deploy only what you need

## 🚨 Troubleshooting

### "Permission denied" errors
```bash
chmod +x scripts/*.sh
```

### "Firebase CLI not found"
```bash
npm install -g firebase-tools
# OR
curl -sL https://firebase.tools | bash
```

### "Flutter not found"
Make sure Flutter is in your PATH:
```bash
export PATH="$PATH:/path/to/flutter/bin"
```

### Authentication issues
```bash
firebase login
gcloud auth login
```

## 📝 Notes

- Scripts are designed for Unix-like systems (Linux, macOS, WSL)
- Windows users should use Git Bash or WSL
- All scripts include comprehensive error checking
- Logs are colored for better readability
- Scripts can be run from any directory in the project
