#!/usr/bin/env bash
# scripts/release.sh — InkScroller release trigger
#
# Usage: ./scripts/release.sh <version>
#   version  Semver without the 'v' prefix (e.g. 1.2.3)
#
# Pre-flight checks (all must pass before bumping):
#   1. Must run from the main branch
#   2. Working tree must be clean
#   3. Version argument must be a valid semver (X.Y.Z)
#   4. pubspec.yaml must exist with a parseable version line
#   5. Local main must be in sync with origin/main
#   6. Tag must not already exist locally or on origin
#
# After checks pass:
#   7. Computes next build number from current pubspec.yaml
#      (reuses the existing build when retrying the same X.Y.Z, otherwise N+1)
#   8. Bumps pubspec.yaml to X.Y.Z+<next-build>
#   9. Commits, pushes main, creates and pushes vX.Y.Z tag → triggers CI
#
# Build-number semantics:
#   The script increments the source build number in pubspec.yaml,
#   except when retrying an already-bumped same-semver release.
#   CI may additionally pass --build-name and --build-number to Flutter
#   for artifact metadata. See docs/RELEASING.md for the full explanation.

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
if [ "$CURRENT_BRANCH" != "main" ]; then
  fail "Must release from main. Current branch: $CURRENT_BRANCH"
fi
ok "On main branch"

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

# ── 4. Parse pubspec.yaml, compute next build number ─────────────────────────

if [ ! -f pubspec.yaml ]; then
  fail "pubspec.yaml not found. Are you in the project root?"
fi

CURRENT_VERSION_LINE=$(grep -m1 '^version:' pubspec.yaml || true)
if [ -z "$CURRENT_VERSION_LINE" ]; then
  fail "Could not find version in pubspec.yaml"
fi
# shellcheck disable=SC2001
CURRENT_VERSION=$(echo "$CURRENT_VERSION_LINE" | sed 's/version: *//')

if [ -z "$CURRENT_VERSION" ]; then
  fail "Could not parse version from pubspec.yaml"
fi

# Extract current semver and build number, if any (X.Y.Z+N)
CURRENT_SEMVER="${CURRENT_VERSION%%+*}"
if echo "$CURRENT_VERSION" | grep -q '+'; then
  # shellcheck disable=SC2001
  CURRENT_BUILD=$(echo "$CURRENT_VERSION" | sed 's/.*+//')
  if ! echo "$CURRENT_BUILD" | grep -qE '^[0-9]+$'; then
    fail "pubspec.yaml build number is not numeric: +${CURRENT_BUILD}"
  fi
else
  CURRENT_BUILD=0
fi

if [ "$CURRENT_SEMVER" = "$VERSION" ] && [ "$CURRENT_BUILD" -gt 0 ]; then
  NEXT_BUILD=$CURRENT_BUILD
  info "pubspec.yaml already uses release semver ${VERSION}; reusing build ${NEXT_BUILD}"
else
  NEXT_BUILD=$((CURRENT_BUILD + 1))
fi

NEW_VERSION="${VERSION}+${NEXT_BUILD}"
ok "pubspec.yaml — current: ${CURRENT_VERSION}, next: ${NEW_VERSION}"

# ── 5. Local/origin sync ─────────────────────────────────────────────────────

git fetch origin main --quiet

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)

if [ "$LOCAL" != "$REMOTE" ]; then
  fail "Local main is out of sync with origin/main. Pull or push before releasing."
fi
ok "Local main is in sync with origin"

# ── 6. Tag must not exist ────────────────────────────────────────────────────

TAG="v$VERSION"

if git rev-parse "$TAG" >/dev/null 2>&1; then
  fail "Tag $TAG already exists. Did you forget to bump the version?"
fi
ok "Local tag $TAG does not exist yet"

git ls-remote --exit-code --tags origin "refs/tags/$TAG" >/dev/null 2>&1
RC=$?
if [ "$RC" -eq 0 ]; then
  fail "Tag $TAG already exists on origin. Did you forget to bump the version?"
elif [ "$RC" -ne 2 ]; then
  fail "Could not check remote tag (ls-remote exited $RC). Network or auth error?"
fi
ok "Remote tag $TAG does not exist yet"

# ── Bump pubspec.yaml ────────────────────────────────────────────────────────

NEW_VERSION_LINE="version: ${NEW_VERSION}"

if [ "$CURRENT_VERSION_LINE" = "$NEW_VERSION_LINE" ]; then
  info "pubspec.yaml already at ${NEW_VERSION}, skipping bump"
else
  info "Bumping pubspec.yaml to ${NEW_VERSION}"

  # portable temp-file replacement (no sed -i, works on macOS and Linux)
  TMPFILE=$(mktemp)
  # shellcheck disable=SC2064
  sed "s/^version: .*/version: ${NEW_VERSION}/" pubspec.yaml > "$TMPFILE"
  mv "$TMPFILE" pubspec.yaml

  git add pubspec.yaml
fi

# ── Commit, push, tag ────────────────────────────────────────────────────────

# Only commit if there are staged changes (i.e. pubspec was actually bumped)
if git diff --cached --quiet; then
  info "No changes to commit — pubspec was already at target version"
else
  COMMIT_MSG="chore(release): bump version to ${NEW_VERSION}"
  info "Committing: ${COMMIT_MSG}"
  git commit -m "$COMMIT_MSG"
fi

info "Creating tag $TAG..."
git tag "$TAG"
info "Pushing main and $TAG atomically..."
if ! git push --atomic origin main "$TAG"; then
  git tag -d "$TAG" >/dev/null 2>&1 || true
  fail "Atomic push failed; removed local tag $TAG so the release can be retried"
fi

echo ""
echo -e "${GREEN}Released $TAG${NC} — CI workflow triggered."
echo "Track progress at: https://github.com/mfranchescagonzalezcejas/inkscroller_frontend/actions"
