#!/usr/bin/env sh
set -e

BASE="${1:-main}"

if ! command -v coderabbit >/dev/null 2>&1; then
  echo "❌ coderabbit CLI not found. Install: npm install -g @coderabbitai/cli"
  exit 1
fi

echo "🔍 Running CodeRabbit review against $BASE..."
coderabbit review --base "$BASE"
