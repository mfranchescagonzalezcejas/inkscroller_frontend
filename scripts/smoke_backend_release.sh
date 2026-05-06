#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   scripts/smoke_backend_release.sh pro
#   scripts/smoke_backend_release.sh staging
#   scripts/smoke_backend_release.sh dev-cloud

MODE="${1:-pro}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
EVIDENCE_DIR="$PROJECT_DIR/.qa-evidence"
STAMP="$(date +%Y-%m-%d_%H-%M-%S)"

mkdir -p "$EVIDENCE_DIR"

if ! command -v curl >/dev/null 2>&1; then
  echo "ERROR: curl no está disponible" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: python3 no está disponible" >&2
  exit 1
fi

case "$MODE" in
  pro)
    BASE_URL="https://inkscroller-backend-806863502436.us-central1.run.app"
    ;;
  staging)
    BASE_URL="https://inkscroller-backend-391760656950.us-central1.run.app"
    ;;
  dev-cloud)
    BASE_URL="https://inkscroller-backend-708894048002.us-central1.run.app"
    ;;
  *)
    echo "ERROR: modo inválido '$MODE'. Usá: pro | staging | dev-cloud" >&2
    exit 1
    ;;
esac

LOG_FILE="$EVIDENCE_DIR/smoke-backend-${MODE}-${STAMP}.log"
SUMMARY_MD="$EVIDENCE_DIR/smoke-backend-${MODE}-${STAMP}.md"

PING_BODY="$EVIDENCE_DIR/ping-${MODE}-${STAMP}.json"
MANGA_BODY="$EVIDENCE_DIR/manga-${MODE}-${STAMP}.json"
CHAPTERS_BODY="$EVIDENCE_DIR/chapters-${MODE}-${STAMP}.json"

echo "[backend-smoke] mode=$MODE base=$BASE_URL" | tee "$LOG_FILE"

ping_code="$(curl -sS -o "$PING_BODY" -w "%{http_code}" "$BASE_URL/ping")"
manga_code="$(curl -sS -o "$MANGA_BODY" -w "%{http_code}" "$BASE_URL/manga?limit=5")"
chapters_code="$(curl -sS -o "$CHAPTERS_BODY" -w "%{http_code}" "$BASE_URL/chapters/latest?limit=8")"

echo "ping_code=$ping_code" | tee -a "$LOG_FILE"
echo "manga_code=$manga_code" | tee -a "$LOG_FILE"
echo "chapters_code=$chapters_code" | tee -a "$LOG_FILE"

ping_ok="no"
manga_ok="no"
chapters_ok="no"

[[ "$ping_code" == "200" ]] && ping_ok="yes"
[[ "$manga_code" == "200" ]] && manga_ok="yes"
[[ "$chapters_code" == "200" ]] && chapters_ok="yes"

overall="FAIL"
if [[ "$ping_ok" == "yes" && "$manga_ok" == "yes" && "$chapters_ok" == "yes" ]]; then
  overall="PASS"
fi

cat > "$SUMMARY_MD" <<EOF
# Smoke Backend Release — ${MODE}

- Date: $(date '+%Y-%m-%d %H:%M:%S')
- Base URL: ${BASE_URL}

## Resultado HTTP

- /ping: ${ping_code} (ok=${ping_ok})
- /manga?limit=5: ${manga_code} (ok=${manga_ok})
- /chapters/latest?limit=8: ${chapters_code} (ok=${chapters_ok})

Resultado global: **${overall}**

## Evidencia

- Log: ${LOG_FILE}
- Body /ping: ${PING_BODY}
- Body /manga: ${MANGA_BODY}
- Body /chapters/latest: ${CHAPTERS_BODY}
- Summary: ${SUMMARY_MD}

## Nota

Este smoke valida disponibilidad de endpoints críticos de release.
EOF

echo "[backend-smoke] summary: $SUMMARY_MD"
echo "[backend-smoke] result:  $overall"

if [[ "$overall" != "PASS" ]]; then
  exit 1
fi
