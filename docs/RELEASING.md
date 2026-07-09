# Releasing InkScroller Flutter

Releases are **tag-driven**. Pushing a semver tag to `origin` triggers the full
release pipeline: quality gates → GitHub Release creation → APK build → Firebase
App Distribution for all three flavors.

## Related diagram

![Release Flow](diagrams/release-flow.svg)

Editable source: [`release-flow.drawio`](diagrams/release-flow.drawio)

---

## Release flow

```
1. All changes merged to main (normal flow)
2. Run the release script from main (it bumps pubspec.yaml, commits, pushes, tags)
3. CI does the rest automatically
```

### Step 1 — Merge to main

All changes must be on `main` before tagging. The release scripts enforce this.
You do **not** need to bump `pubspec.yaml` manually — the script handles it.

### Step 2 — Run the release script

**macOS / Linux:**
```bash
./scripts/release.sh 1.2.3
```

**Windows:**
```powershell
.\scripts\release.ps1 -Version 1.2.3
```

The script runs 6 pre-flight checks, then bumps `pubspec.yaml` and tags:

| Check | What it validates |
|-------|------------------|
| Branch | Must be on `main` |
| Clean tree | No uncommitted changes |
| Semver format | Argument must be `X.Y.Z` |
| pubspec parseable | `pubspec.yaml` must exist with a valid version line |
| Sync | Local `main` == `origin/main` |
| No duplicate tag | `vX.Y.Z` must not already exist locally or on `origin` |

If any check fails, the script exits with a clear error — no bump, no commit, no tag.

When checks pass, the script:
1. Computes the next build number (`N+1` from current, or `1` if none)
2. Writes `version: X.Y.Z+<next-build>` into `pubspec.yaml`
3. Commits the bump as `chore(release): bump version to X.Y.Z+<next-build>`
4. Creates the local `vX.Y.Z` tag on the bump commit
5. Pushes `main` and `vX.Y.Z` atomically, so remote `main` is not advanced without the tag

If the script already bumped `pubspec.yaml` for the requested semver but failed
before pushing the tag, rerun the same command. The script reuses the existing
build number instead of incrementing it again, then creates the missing tag.

### Step 3 — CI runs automatically

Once the tag `vX.Y.Z` is pushed, `.github/workflows/release.yml` triggers and:

1. Runs `fvm flutter analyze` + `fvm flutter test`
2. Validates tag format (`vX.Y.Z`)
3. Builds DEV / STAGING / PRO APKs
4. Creates the GitHub Release and attaches all APKs
5. Distributes APKs via Firebase App Distribution

Track progress at:
```
https://github.com/mfranchescagonzalezcejas/inkscroller_frontend/actions
```

---

## Required GitHub Secrets

Go to **Settings → Secrets and variables → Actions** and verify these are set:

### Firebase dart-defines

| Secret | Description |
|--------|-------------|
| `FIREBASE_DART_DEFINES_JSON` | Full contents of `.dart-defines/firebase.json` — all Firebase keys for all flavors |

### API Base URLs

| Secret | Description |
|--------|-------------|
| `API_BASE_URL_DEV` | Backend URL for DEV builds |
| `API_BASE_URL_STAGING` | Backend URL for STAGING builds |
| `API_BASE_URL_PRO` | Backend URL for PRO builds |

### Firebase App Distribution

| Secret | Description |
|--------|-------------|
| `FIREBASE_SERVICE_ACCOUNT_JSON_DEV` | Service account JSON for DEV Firebase project |
| `FIREBASE_SERVICE_ACCOUNT_JSON_STAGING` | Service account JSON for STAGING Firebase project |
| `FIREBASE_SERVICE_ACCOUNT_JSON_PRO` | Service account JSON for PRO Firebase project |
| `FIREBASE_APP_ID_DEV` | Firebase App ID for DEV flavor |
| `FIREBASE_APP_ID_STAGING` | Firebase App ID for STAGING flavor |
| `FIREBASE_APP_ID_PRO` | Firebase App ID for PRO flavor |
| `FIREBASE_TESTERS` | Comma-separated tester emails (no spaces) |

---

## Build-number semantics (source vs CI)

There are **two separate** build numbers in play:

| Layer | Where | Managed by | Purpose |
|-------|-------|-----------|---------|
| **Source** | `pubspec.yaml` `version: X.Y.Z+N` | Release script | Canonical source version stored in the tagged commit |
| **Artifact** | `--build-name` / `--build-number` passed to `fvm flutter build` | CI workflow | Version metadata stamped into the generated APK/AAB; does **not** change `pubspec.yaml` |

The release script persists the **source version** before the tag is created.
CI then passes `--build-name="${GITHUB_REF_NAME#v}"` and
`--build-number="$BUILD_NUMBER"` to Flutter when building artifacts. Those
build arguments override artifact metadata at build time, but they do not modify
`pubspec.yaml`.

---

## Rollback

If a release has a critical bug:

1. **Do not delete the tag** — it stays for history.
2. Fix the bug on a branch, merge to `main`.
3. Run the release script again with the next patch version (e.g. `1.2.4`).

There is no automated rollback — Firebase App Distribution testers will receive
the new build as an update.

---

## Checklist

- [ ] All changes merged to `main`
- [ ] `FIREBASE_DART_DEFINES_JSON` secret is up to date
- [ ] All other secrets configured (see table above)
- [ ] Run `./scripts/release.sh X.Y.Z` (or `.ps1` on Windows)
- [ ] Confirm GitHub Release created and APKs attached
- [ ] Confirm Firebase App Distribution emails sent
