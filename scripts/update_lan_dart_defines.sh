#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$PROJECT_DIR/.dart-defines"
OUTPUT_FILE="$OUTPUT_DIR/lan.auto.json"
PORT="${1:-8000}"

mkdir -p "$OUTPUT_DIR"

LAN_IP="$(ip route get 1.1.1.1 | sed -n 's/.*src \([0-9.]*\).*/\1/p' | head -n 1)"

if [[ -z "$LAN_IP" ]]; then
  echo "No pude detectar la IP LAN automáticamente." >&2
  echo "Tip: revisá 'ip a' y conectividad de red." >&2
  exit 1
fi

API_URL="http://${LAN_IP}:${PORT}"

cat > "$OUTPUT_FILE" <<EOF
{
  "API_BASE_URL": "${API_URL}",
  "API_FALLBACK_URL": "http://127.0.0.1:${PORT}"
}
EOF

echo "Generado: $OUTPUT_FILE"
echo "API_BASE_URL=$API_URL"
