#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

exec fvm flutter run \
  --flavor staging \
  -t lib/main_staging.dart \
  --dart-define=API_BASE_URL=https://api.stg.inkscroller.devdigi.dev \
  --dart-define-from-file=.dart-defines/firebase.json \
  "$@"
