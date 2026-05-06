#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/restore_firebase_config.sh --flavor <dev|staging|pro|all> [--android-only|--ios-only]

Restores Firebase native config files from base64 environment variables.

Required variables by flavor:
  GOOGLE_SERVICES_<FLAVOR>_BASE64
  GOOGLE_SERVICE_INFO_IOS_<FLAVOR>_BASE64

Examples:
  scripts/restore_firebase_config.sh --flavor staging
  scripts/restore_firebase_config.sh --flavor all
  scripts/restore_firebase_config.sh --flavor staging --android-only
  scripts/restore_firebase_config.sh --flavor staging --ios-only
EOF
}

flavor=""
android_only=false
ios_only=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --flavor)
      flavor="${2:-}"
      shift 2
      ;;
    --android-only)
      android_only=true
      shift
      ;;
    --ios-only)
      ios_only=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

case "$flavor" in
  dev|staging|pro|all) ;;
  *)
    echo "Missing or invalid --flavor. Expected one of: dev, staging, pro, all." >&2
    usage >&2
    exit 1
    ;;
esac

if [[ "$android_only" == true && "$ios_only" == true ]]; then
  echo "Use either --android-only or --ios-only, not both." >&2
  exit 1
fi

restore_android=true
restore_ios=true
flavors=("$flavor")

if [[ "$flavor" == "all" ]]; then
  flavors=(dev staging pro)
fi

if [[ "$ios_only" == true ]]; then
  restore_android=false
fi

if [[ "$android_only" == true ]]; then
  restore_ios=false
fi

restore_base64_file() {
  local env_var="$1"
  local output_path="$2"
  local value="${!env_var:-}"

  if [[ -z "$value" ]]; then
    echo "Missing required environment variable: $env_var" >&2
    exit 1
  fi

  mkdir -p "$(dirname "$output_path")"
  printf '%s' "$value" | base64 --decode > "$output_path"
  echo "Restored $output_path from $env_var"
}

for current_flavor in "${flavors[@]}"; do
  flavor_token="${current_flavor^^}"

  if [[ "$restore_android" == true ]]; then
    restore_base64_file \
      "GOOGLE_SERVICES_${flavor_token}_BASE64" \
      "android/app/src/${current_flavor}/google-services.json"
  fi

  if [[ "$restore_ios" == true ]]; then
    restore_base64_file \
      "GOOGLE_SERVICE_INFO_IOS_${flavor_token}_BASE64" \
      "ios/config/${current_flavor}/GoogleService-Info.plist"
  fi
done
