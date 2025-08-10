#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter not found in PATH. Please install Flutter or source your environment." >&2
  exit 1
fi

echo "Running flutter analyze with --fatal-infos ..."
flutter analyze --fatal-infos
echo "✅ Analyze check passed"


