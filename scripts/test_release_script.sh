#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

LAST_REPO=""
LAST_ORIGIN=""

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

assert_eq() {
  local expected=$1
  local actual=$2
  local message=$3

  if [ "$expected" != "$actual" ]; then
    fail "$message: expected '$expected', got '$actual'"
  fi
}

setup_repo() {
  local name=$1
  local version=$2
  local case_dir="$WORK_DIR/$name"

  mkdir -p "$case_dir"
  git init --bare "$case_dir/origin.git" >/dev/null
  git init "$case_dir/work" >/dev/null
  git -C "$case_dir/work" config user.email release-test@example.com
  git -C "$case_dir/work" config user.name "Release Test"
  git -C "$case_dir/work" checkout -b main >/dev/null

  mkdir -p "$case_dir/work/scripts"
  cp "$ROOT_DIR/scripts/release.sh" "$case_dir/work/scripts/release.sh"
  chmod +x "$case_dir/work/scripts/release.sh"
  cat > "$case_dir/work/pubspec.yaml" <<EOF
name: release_test
version: $version
EOF

  git -C "$case_dir/work" add pubspec.yaml scripts/release.sh
  git -C "$case_dir/work" commit -m "chore: seed release test" >/dev/null
  git -C "$case_dir/work" remote add origin "$case_dir/origin.git"
  git -C "$case_dir/work" push -u origin main >/dev/null

  LAST_REPO="$case_dir/work"
  LAST_ORIGIN="$case_dir/origin.git"
}

version_line() {
  grep '^version:' "$LAST_REPO/pubspec.yaml"
}

test_normal_release_bumps_and_tags() {
  setup_repo normal 1.0.1+31

  (cd "$LAST_REPO" && ./scripts/release.sh 1.0.6 >/dev/null)

  assert_eq "version: 1.0.6+32" "$(version_line)" "normal release should bump pubspec"
  assert_eq "$(git -C "$LAST_REPO" rev-parse HEAD)" \
    "$(git -C "$LAST_REPO" rev-parse v1.0.6)" \
    "tag should point to the bumped commit"
  assert_eq "$(git -C "$LAST_REPO" rev-parse HEAD)" \
    "$(git --git-dir="$LAST_ORIGIN" rev-parse refs/heads/main)" \
    "origin/main should contain the bumped commit"
}

test_retry_reuses_existing_release_build() {
  setup_repo retry 1.0.6+32
  local before_count
  before_count=$(git -C "$LAST_REPO" rev-list --count HEAD)

  (cd "$LAST_REPO" && ./scripts/release.sh 1.0.6 >/dev/null)

  assert_eq "version: 1.0.6+32" "$(version_line)" "retry should not bump to a new build"
  assert_eq "$before_count" "$(git -C "$LAST_REPO" rev-list --count HEAD)" \
    "retry should not create a second bump commit"
  assert_eq "$(git -C "$LAST_REPO" rev-parse HEAD)" \
    "$(git -C "$LAST_REPO" rev-parse v1.0.6)" \
    "retry tag should point to existing bumped commit"
}

test_remote_duplicate_tag_fails_before_bump() {
  setup_repo remote_duplicate 1.0.1+31
  local remote_main_before
  remote_main_before=$(git --git-dir="$LAST_ORIGIN" rev-parse refs/heads/main)

  git -C "$LAST_REPO" tag v1.0.6
  git -C "$LAST_REPO" push origin v1.0.6 >/dev/null
  git -C "$LAST_REPO" tag -d v1.0.6 >/dev/null

  if (cd "$LAST_REPO" && ./scripts/release.sh 1.0.6 >/dev/null 2>&1); then
    fail "release should fail when tag exists on origin"
  fi

  assert_eq "version: 1.0.1+31" "$(version_line)" \
    "remote duplicate tag should fail before modifying pubspec"
  assert_eq "$remote_main_before" "$(git --git-dir="$LAST_ORIGIN" rev-parse refs/heads/main)" \
    "remote duplicate tag should fail before pushing main"
}

test_rejected_tag_push_does_not_advance_origin_main() {
  setup_repo rejected_tag_push 1.0.1+31
  local remote_main_before
  remote_main_before=$(git --git-dir="$LAST_ORIGIN" rev-parse refs/heads/main)

  cat > "$LAST_ORIGIN/hooks/pre-receive" <<'EOF'
#!/usr/bin/env bash
while read -r _old _new ref; do
  if [ "$ref" = "refs/tags/v1.0.6" ]; then
    exit 1
  fi
done
EOF
  chmod +x "$LAST_ORIGIN/hooks/pre-receive"

  if (cd "$LAST_REPO" && ./scripts/release.sh 1.0.6 >/dev/null 2>&1); then
    fail "release should fail when remote rejects tag push"
  fi

  assert_eq "$remote_main_before" "$(git --git-dir="$LAST_ORIGIN" rev-parse refs/heads/main)" \
    "atomic push should not advance origin/main when tag push is rejected"
}

test_missing_pubspec_version_fails_clearly() {
  setup_repo missing_version 1.0.1+31
  cat > "$LAST_REPO/pubspec.yaml" <<'EOF'
name: release_test
EOF
  git -C "$LAST_REPO" add pubspec.yaml
  git -C "$LAST_REPO" commit -m "chore: remove version for test" >/dev/null
  git -C "$LAST_REPO" push origin main >/dev/null

  if (cd "$LAST_REPO" && ./scripts/release.sh 1.0.6 >/dev/null 2>&1); then
    fail "release should fail when pubspec.yaml has no version line"
  fi
}

test_normal_release_bumps_and_tags
test_retry_reuses_existing_release_build
test_remote_duplicate_tag_fails_before_bump
test_rejected_tag_push_does_not_advance_origin_main
test_missing_pubspec_version_fails_clearly

echo "release script tests passed"
