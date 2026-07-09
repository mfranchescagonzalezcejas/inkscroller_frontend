#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

exec fvm flutter run \
  --flavor dev \
  -t lib/main_dev.dart \
  --dart-define=API_BASE_URL=https://api.dev.inkscroller.devdigi.dev \
  "$@"
