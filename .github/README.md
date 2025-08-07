# GitHub Actions CI/CD Pipeline

This repository uses GitHub Actions for automated testing, building, and deployment of the Wordle Solver application.

## 🔄 Workflows Overview

### 1. **Continuous Integration** (`ci.yml`)
**Triggers:** Pull requests to `main` or `develop`, pushes to `develop`

- ✅ Flutter code analysis and formatting
- ✅ Flutter tests with coverage reporting
- ✅ Python code linting and type checking
- ✅ Security scanning
- ✅ Build verification (web + Android debug)

### 2. **Deploy to Firebase Hosting** (`firebase-hosting-merge.yml`)
**Triggers:** Push to `main` branch

- ✅ Flutter web build (production)
- ✅ Deploy to Firebase Hosting live channel
- ✅ Automatic deployment on merge

### 3. **Preview Deployment** (`firebase-hosting-pull-request.yml`)
**Triggers:** Pull requests

- ✅ Flutter web build
- ✅ Deploy preview to Firebase Hosting
- ✅ Comment with preview URL on PR

### 4. **Deploy Cloud Functions** (`deploy-functions.yml`)
**Triggers:** Changes to `functions/` directory, manual dispatch

- ✅ Python syntax validation
- ✅ Dependency installation and testing
- ✅ Deploy to Firebase Functions
- ✅ Function health check

### 5. **Deploy Database Rules** (`deploy-database.yml`)
**Triggers:** Changes to `firestore.rules`, `firestore.indexes.json`, `storage.rules`

- ✅ Validate Firestore security rules
- ✅ Deploy Firestore rules and indexes
- ✅ Deploy Storage security rules

### 6. **Update Dictionaries** (`update-dictionaries.yml`)
**Triggers:** Changes to `assets/words/` directory, manual dispatch

- ✅ Validate JSON dictionary files
- ✅ Upload to Cloud Storage
- ✅ Deploy Storage rules
- ✅ Verification of uploaded files

## 🔐 Required Secrets

The following GitHub secrets must be configured in your repository settings:

| Secret Name | Description | Source |
|-------------|-------------|---------|
| `FIREBASE_SERVICE_ACCOUNT_WORDLE_SOLVER_KYLE` | Firebase service account JSON | Firebase Console → Project Settings → Service Accounts |

## 🚀 Manual Deployment Commands

You can also deploy manually using these commands:

```bash
# Deploy everything
npm run deploy:all

# Deploy specific components
npm run deploy:functions
npm run deploy:hosting
npm run deploy:database

# Upload dictionaries
npm run upload-dictionaries
```

## 📋 Workflow Status Badges

Add these badges to your main README.md:

```markdown
![CI](https://github.com/dev-ro/wordle_solver/workflows/Continuous%20Integration/badge.svg)
![Deploy](https://github.com/dev-ro/wordle_solver/workflows/Deploy%20to%20Firebase%20Hosting%20on%20merge/badge.svg)
![Functions](https://github.com/dev-ro/wordle_solver/workflows/Deploy%20Cloud%20Functions/badge.svg)
```

## 🔧 Workflow Configuration

### Flutter Version
- **Version:** 3.24.5 (stable channel)
- **Caching:** Enabled for faster builds

### Python Version
- **Version:** 3.12
- **Virtual Environment:** Automatically created and managed

### Node.js Version
- **Version:** 18 (LTS)
- **Package Manager:** npm with caching

## 📊 Code Quality

- **Flutter:** `flutter analyze --fatal-infos`
- **Dart Formatting:** `dart format --set-exit-if-changed`
- **Python Linting:** `flake8` with max line length 100
- **Python Formatting:** `black`
- **Type Checking:** `mypy` for Python functions
- **Security:** TruffleHog for secret detection

## 🧪 Testing

- **Flutter Tests:** `flutter test --coverage`
- **Coverage Reporting:** Uploaded to Codecov
- **Python Tests:** `pytest` with coverage (when test files exist)

## 🔄 Branch Protection

Recommended branch protection rules for `main`:

- ✅ Require pull request reviews
- ✅ Require status checks to pass:
  - `Flutter CI`
  - `Python Functions CI`
  - `Security Scan`
- ✅ Require branches to be up to date
- ✅ Restrict pushes to matching branches

## 📝 Contributing

1. Create a feature branch from `develop`
2. Make your changes
3. Ensure all CI checks pass
4. Create a pull request to `develop`
5. After review, merge to `develop`
6. Create a release PR from `develop` to `main`

## 🚨 Troubleshooting

### Common Issues

1. **Firebase Authentication Errors**
   - Verify `FIREBASE_SERVICE_ACCOUNT_WORDLE_SOLVER_KYLE` secret is set
   - Check service account has necessary permissions

2. **Flutter Build Failures**
   - Ensure Flutter version matches workflow (3.24.5)
   - Check for dependency conflicts in `pubspec.yaml`

3. **Python Function Deployment**
   - Verify `requirements.txt` is up to date
   - Check Python syntax with `python -m py_compile main.py`

4. **Dictionary Upload Issues**
   - Ensure Firebase Storage is enabled in console
   - Verify JSON files are valid arrays of strings

### Debug Commands

```bash
# Test locally
flutter analyze
flutter test
dart format --set-exit-if-changed .

# Validate Firebase config
firebase projects:list
firebase use wordle-solver-kyle

# Check function syntax
cd functions && python -m py_compile main.py
```
