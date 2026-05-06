#!/usr/bin/env bash
# scripts/release.sh — InkScroller release trigger
#
# Usage: ./scripts/release.sh <version>
#   version  Semver without the 'v' prefix (e.g. 1.2.3)
#
# Pre-flight checks (all must pass before tagging):
#   1. Must run from the master branch
#   2. Working tree must be clean
#   3. Version argument must be a valid semver (X.Y.Z)
#   4. Version must match pubspec.yaml
#   5. Local master must be in sync with origin/master
#   6. Tag must not already exist
#
# On success: creates and pushes vX.Y.Z tag → triggers release.yml in CI

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

fail() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }
ok()   { echo -e "${GREEN}[OK]${NC}    $1"; }
info() { echo -e "${YELLOW}[INFO]${NC}  $1"; }

# ── 1. Branch check ──────────────────────────────────────────────────────────

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "master" ]; then
  fail "Must release from master. Current branch: $CURRENT_BRANCH"
fi
ok "On master branch"

# ── 2. Clean tree ────────────────────────────────────────────────────────────

if ! git diff --quiet || ! git diff --cached --quiet; then
  fail "Working tree has uncommitted changes. Commit or stash before releasing."
fi
ok "Working tree is clean"

# ── 3. Version argument ──────────────────────────────────────────────────────

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
  fail "Version argument required. Usage: ./scripts/release.sh <version>  (e.g. 1.2.3)"
fi

if ! echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  fail "Version must be semver format X.Y.Z (no 'v' prefix). Got: $VERSION"
fi
ok "Version format valid: $VERSION"

# ── 4. Version matches pubspec.yaml ──────────────────────────────────────────

PUBSPEC_VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //')
PUBSPEC_SEMVER="${PUBSPEC_VERSION%%+*}"

if [ "$PUBSPEC_SEMVER" != "$VERSION" ]; then
  fail "pubspec.yaml version ($PUBSPEC_VERSION) does not match $VERSION. Bump pubspec.yaml first."
fi
ok "pubspec.yaml version matches: $PUBSPEC_VERSION"

# ── 5. Local/origin sync ─────────────────────────────────────────────────────

git fetch origin master --quiet

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/master)

if [ "$LOCAL" != "$REMOTE" ]; then
  fail "Local master is out of sync with origin/master. Pull or push before releasing."
fi
ok "Local master is in sync with origin"

# ── 6. Tag must not exist ────────────────────────────────────────────────────

TAG="v$VERSION"

if git rev-parse "$TAG" >/dev/null 2>&1; then
  fail "Tag $TAG already exists. Did you forget to bump the version?"
fi
ok "Tag $TAG does not exist yet"

# ── Tag and push ─────────────────────────────────────────────────────────────

info "Creating and pushing tag $TAG..."
git tag "$TAG"
git push origin "$TAG"

echo ""
echo -e "${GREEN}Released $TAG${NC} — CI workflow triggered."
echo "Track progress at: https://github.com/mfranchescagonzalezcejas/inkscroller_flutter/actions"
