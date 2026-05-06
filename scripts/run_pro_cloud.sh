#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

exec fvm flutter run \
  --flavor pro \
  -t lib/main_pro.dart \
  --dart-define=API_BASE_URL=https://inkscrollerbackend-pro.up.railway.app \
  "$@"
