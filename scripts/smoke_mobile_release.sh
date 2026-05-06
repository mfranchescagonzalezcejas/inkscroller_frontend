#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   scripts/smoke_mobile_release.sh pro
#   scripts/smoke_mobile_release.sh dev-lan
#   scripts/smoke_mobile_release.sh staging

MODE="${1:-pro}"
DEVICE_ID="${2:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
EVIDENCE_DIR="$PROJECT_DIR/.qa-evidence"
STAMP="$(date +%Y-%m-%d_%H-%M-%S)"

mkdir -p "$EVIDENCE_DIR"

if ! command -v adb >/dev/null 2>&1; then
  echo "ERROR: adb no está disponible en PATH" >&2
  exit 1
fi

if ! command -v fvm >/dev/null 2>&1; then
  echo "ERROR: fvm no está disponible en PATH" >&2
  exit 1
fi

if [[ -z "$DEVICE_ID" ]]; then
  DEVICE_ID="$(adb devices | awk 'NR>1 && $2=="device" {print $1; exit}')"
fi

if [[ -z "$DEVICE_ID" ]]; then
  echo "ERROR: no se detectó dispositivo Android físico conectado" >&2
  exit 1
fi

case "$MODE" in
  pro)
    ENTRYPOINT="lib/main_pro.dart"
    FLAVOR="pro"
    BASE_URL="https://inkscroller-backend-806863502436.us-central1.run.app"
    ;;
  staging)
    ENTRYPOINT="lib/main_staging.dart"
    FLAVOR="staging"
    BASE_URL="https://inkscroller-backend-391760656950.us-central1.run.app"
    ;;
  dev-cloud)
    ENTRYPOINT="lib/main_dev.dart"
    FLAVOR="dev"
    BASE_URL="https://inkscroller-backend-708894048002.us-central1.run.app"
    ;;
  dev-lan)
    "$PROJECT_DIR/scripts/update_lan_dart_defines.sh"
    BASE_URL="$(python3 - <<'PY'
import json
from pathlib import Path
cfg = json.loads(Path('.dart-defines/lan.auto.json').read_text())
print(cfg.get('API_BASE_URL', ''))
PY
)"
    ENTRYPOINT="lib/main_dev.dart"
    FLAVOR="dev"
    ;;
  *)
    echo "ERROR: modo inválido '$MODE'. Usá: pro | staging | dev-cloud | dev-lan" >&2
    exit 1
    ;;
esac

RUN_LOG="$EVIDENCE_DIR/smoke-mobile-${MODE}-${STAMP}.log"
SUMMARY_MD="$EVIDENCE_DIR/smoke-mobile-${MODE}-${STAMP}.md"

echo "[smoke] mode=$MODE device=$DEVICE_ID flavor=$FLAVOR entry=$ENTRYPOINT"
echo "[smoke] expected base url: $BASE_URL"

set +e
timeout 160s fvm flutter run \
  --flavor "$FLAVOR" \
  -t "$ENTRYPOINT" \
  --dart-define=API_BASE_URL="$BASE_URL" \
  -d "$DEVICE_ID" \
  >"$RUN_LOG" 2>&1
RUN_EXIT=$?
set -e

# timeout returns 124; treat as expected because we only need startup evidence.
if [[ $RUN_EXIT -ne 0 && $RUN_EXIT -ne 124 ]]; then
  echo "ERROR: flutter run falló con exit code $RUN_EXIT" >&2
fi

FLAVOR_OK="no"
BASE_OK="no"

grep -q "Flavor: Flavor.${FLAVOR}" "$RUN_LOG" && FLAVOR_OK="yes"
grep -q "Initializing with base URL: ${BASE_URL}" "$RUN_LOG" && BASE_OK="yes"

OVERALL="FAIL"
if [[ "$FLAVOR_OK" == "yes" && "$BASE_OK" == "yes" ]]; then
  OVERALL="PASS"
fi

cat > "$SUMMARY_MD" <<EOF
# Smoke Mobile Release — ${MODE}

- Date: $(date '+%Y-%m-%d %H:%M:%S')
- Device: ${DEVICE_ID}
- Mode: ${MODE}
- Flavor esperado: ${FLAVOR}
- API_BASE_URL esperada: ${BASE_URL}

## Resultado

- Flavor detectado correctamente: ${FLAVOR_OK}
- Base URL detectada correctamente: ${BASE_OK}
- Resultado global: **${OVERALL}**

## Archivos

- Log: \
  \
  ${RUN_LOG}
- Resumen: \
  \
  ${SUMMARY_MD}

## Nota

Este smoke valida arranque + flavor + API_BASE_URL en dispositivo físico.
No reemplaza QA funcional de features ni checklist legal completo.
EOF

echo "[smoke] summary: $SUMMARY_MD"
echo "[smoke] log:     $RUN_LOG"
echo "[smoke] result:  $OVERALL"

if [[ "$OVERALL" != "PASS" ]]; then
  exit 1
fi
