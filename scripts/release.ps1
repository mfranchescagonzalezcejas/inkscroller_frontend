# scripts/release.ps1 — InkScroller release trigger (Windows)
#
# Usage: .\scripts\release.ps1 -Version <version>
#   Version  Semver without the 'v' prefix (e.g. 1.2.3)
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
#   9. Commits, pushes main, creates and pushes vX.Y.Z tag -> triggers CI
#
# Build-number semantics:
#   The script increments the source build number in pubspec.yaml,
#   except when retrying an already-bumped same-semver release.
#   CI may additionally pass --build-name and --build-number to Flutter
#   for artifact metadata. See docs/RELEASING.md for the full explanation.

param(
    [Parameter(Mandatory = $true)]
    [string]$Version
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Fail  { param([string]$msg) Write-Host "[ERROR] $msg" -ForegroundColor Red;   exit 1 }
function Ok    { param([string]$msg) Write-Host "[OK]    $msg" -ForegroundColor Green        }
function Info  { param([string]$msg) Write-Host "[INFO]  $msg" -ForegroundColor Yellow       }

# ── 1. Branch check ──────────────────────────────────────────────────────────

$currentBranch = git rev-parse --abbrev-ref HEAD
if ($currentBranch -ne 'main') {
    Fail "Must release from main. Current branch: $currentBranch"
}
Ok "On main branch"

# ── 2. Clean tree ────────────────────────────────────────────────────────────

$status = git status --porcelain
if ($status) {
    Fail "Working tree has uncommitted changes. Commit or stash before releasing."
}
Ok "Working tree is clean"

# ── 3. Version argument ──────────────────────────────────────────────────────

if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    Fail "Version must be semver format X.Y.Z (no 'v' prefix). Got: $Version"
}
Ok "Version format valid: $Version"

# ── 4. Parse pubspec.yaml, compute next build number ─────────────────────────

if (-not (Test-Path 'pubspec.yaml')) {
    Fail "pubspec.yaml not found. Are you in the project root?"
}

$pubspecLine = Select-String -Path 'pubspec.yaml' -Pattern '^version:' | Select-Object -First 1
if (-not $pubspecLine) { Fail "Could not find version in pubspec.yaml" }

$currentVersionLine = $pubspecLine.Line
$currentVersion     = $currentVersionLine -replace 'version:\s*', ''

if (-not $currentVersion) { Fail "Could not parse version from pubspec.yaml" }

# Extract current semver and build number, if any (X.Y.Z+N)
$currentSemver = $currentVersion -replace '\+.*', ''
if ($currentVersion -match '\+') {
    $currentBuild = $currentVersion -replace '.*\+', ''
    if ($currentBuild -notmatch '^\d+$') {
        Fail "pubspec.yaml build number is not numeric: +$currentBuild"
    }
} else {
    $currentBuild = 0
}

if (($currentSemver -eq $Version) -and ([int]$currentBuild -gt 0)) {
    $nextBuild = [int]$currentBuild
    Info "pubspec.yaml already uses release semver ${Version}; reusing build ${nextBuild}"
} else {
    $nextBuild = [int]$currentBuild + 1
}

$newVersion = "${Version}+${nextBuild}"
Ok "pubspec.yaml - current: ${currentVersion}, next: ${newVersion}"

# ── 5. Local/origin sync ─────────────────────────────────────────────────────

git fetch origin main --quiet

$local  = git rev-parse HEAD
$remote = git rev-parse origin/main

if ($local -ne $remote) {
    Fail "Local main is out of sync with origin/main. Pull or push before releasing."
}
Ok "Local main is in sync with origin"

# ── 6. Tag must not exist ────────────────────────────────────────────────────

$tag = "v$Version"

$existingTag = git rev-parse $tag 2>$null
if ($LASTEXITCODE -eq 0) {
    Fail "Tag $tag already exists. Did you forget to bump the version?"
}
Ok "Local tag $tag does not exist yet"

git ls-remote --exit-code --tags origin "refs/tags/$tag" 2>$null | Out-Null
$rc = $LASTEXITCODE
if ($rc -eq 0) {
    Fail "Tag $tag already exists on origin. Did you forget to bump the version?"
} elseif ($rc -ne 2) {
    Fail "Could not check remote tag (ls-remote exited $rc). Network or auth error?"
}
Ok "Remote tag $tag does not exist yet"

# ── Bump pubspec.yaml ────────────────────────────────────────────────────────

$newVersionLine = "version: ${newVersion}"

if ($currentVersionLine -eq $newVersionLine) {
    Info "pubspec.yaml already at ${newVersion}, skipping bump"
} else {
    Info "Bumping pubspec.yaml to ${newVersion}"

    # portable temp-file replacement
    $tmpFile = [System.IO.Path]::GetTempFileName()
    $content = Get-Content 'pubspec.yaml' -Raw
    $content = $content -replace '(?m)^version: .*', "version: ${newVersion}"
    Set-Content -Path $tmpFile -Value $content -NoNewline
    Move-Item -Force $tmpFile 'pubspec.yaml'

    git add pubspec.yaml
}

# ── Commit, push, tag ────────────────────────────────────────────────────────

# Only commit if there are staged changes (i.e. pubspec was actually bumped)
git diff --cached --quiet | Out-Null
if ($LASTEXITCODE -eq 0) {
    Info "No changes to commit - pubspec was already at target version"
} else {
    $commitMsg = "chore(release): bump version to ${newVersion}"
    Info "Committing: ${commitMsg}"
    git commit -m $commitMsg
}

Info "Creating tag $tag..."
git tag $tag
Info "Pushing main and $tag atomically..."
git push --atomic origin main $tag
if ($LASTEXITCODE -ne 0) {
    git tag -d $tag 2>$null | Out-Null
    Fail "Atomic push failed; removed local tag $tag so the release can be retried"
}

Write-Host ""
Write-Host "Released $tag - CI workflow triggered." -ForegroundColor Green
Write-Host "Track progress at: https://github.com/mfranchescagonzalezcejas/inkscroller_frontend/actions"
