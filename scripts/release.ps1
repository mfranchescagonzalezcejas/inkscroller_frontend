# scripts/release.ps1 — InkScroller release trigger (Windows)
#
# Usage: .\scripts\release.ps1 -Version <version>
#   Version  Semver without the 'v' prefix (e.g. 1.2.3)
#
# Pre-flight checks (all must pass before tagging):
#   1. Must run from the main branch
#   2. Working tree must be clean
#   3. Version argument must be a valid semver (X.Y.Z)
#   4. Version must match pubspec.yaml
#   5. Local main must be in sync with origin/main
#   6. Tag must not already exist
#
# On success: creates and pushes vX.Y.Z tag -> triggers release.yml in CI

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

# ── 4. Version matches pubspec.yaml ──────────────────────────────────────────

$pubspecLine = Select-String -Path 'pubspec.yaml' -Pattern '^version:' | Select-Object -First 1
if (-not $pubspecLine) { Fail "Could not find version in pubspec.yaml" }

$pubspecVersion = $pubspecLine.Line -replace 'version:\s*', ''
$pubspecSemver  = $pubspecVersion -replace '\+.*', ''

if ($pubspecSemver -ne $Version) {
    Fail "pubspec.yaml version ($pubspecVersion) does not match $Version. Bump pubspec.yaml first."
}
Ok "pubspec.yaml version matches: $pubspecVersion"

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
Ok "Tag $tag does not exist yet"

# ── Tag and push ─────────────────────────────────────────────────────────────

Info "Creating and pushing tag $tag..."
git tag $tag
git push origin $tag

Write-Host ""
Write-Host "Released $tag - CI workflow triggered." -ForegroundColor Green
Write-Host "Track progress at: https://github.com/mfranchescagonzalezcejas/inkscroller_flutter/actions"
