#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

# 1) Detect current LAN IP and regenerate dart-defines file.
"$PROJECT_DIR/scripts/update_lan_dart_defines.sh"

# 2) Run Flutter with the generated define file.
exec fvm flutter run \
  --flavor dev \
  -t lib/main_dev.dart \
  --dart-define-from-file=.dart-defines/lan.auto.json \
  "$@"
