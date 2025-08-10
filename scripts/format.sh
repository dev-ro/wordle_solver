#!/usr/bin/env bash
set -euo pipefail

# Run Dart formatter and fail if changes are needed
if ! command -v dart >/dev/null 2>&1; then
  echo "dart not found in PATH. Please install Flutter/Dart or source your environment." >&2
  exit 1
fi

echo "Running dart format with --set-exit-if-changed ..."
dart format --set-exit-if-changed .
echo "✅ Formatting check passed"

echo "Running flutter analyze with --fatal-infos ..."
flutter analyze --fatal-infos
echo "✅ Analyze check passed"
