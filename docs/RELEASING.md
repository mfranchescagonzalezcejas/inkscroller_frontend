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
1. Bump version in pubspec.yaml
2. Commit, PR → develop → master (normal flow)
3. Run the release script from master
4. CI does the rest automatically
```

### Step 1 — Bump pubspec.yaml

```yaml
# pubspec.yaml
version: 1.2.3+45   # semver+build-number
```

- The **semver** (`1.2.3`) must match the tag you will create.
- The **build number** (`+45`) must be incremented on every release.

### Step 2 — Merge to master

All changes must be on `master` before tagging. The release scripts enforce this.

### Step 3 — Run the release script

**macOS / Linux:**
```bash
./scripts/release.sh 1.2.3
```

**Windows:**
```powershell
.\scripts\release.ps1 -Version 1.2.3
```

The script runs 6 pre-flight checks before creating the tag:

| Check | What it validates |
|-------|------------------|
| Branch | Must be on `master` |
| Clean tree | No uncommitted changes |
| Semver format | Argument must be `X.Y.Z` |
| pubspec match | Arg must match `pubspec.yaml` semver |
| Sync | Local `master` == `origin/master` |
| No duplicate tag | `vX.Y.Z` must not already exist |

If any check fails, the script exits with a clear error — no tag is created.

### Step 4 — CI runs automatically

Once the tag `vX.Y.Z` is pushed, `.github/workflows/release.yml` triggers and:

1. Runs `fvm flutter analyze` + `fvm flutter test`
2. Validates tag matches `pubspec.yaml`
3. Builds DEV / STAGING / PRO APKs
4. Creates the GitHub Release and attaches all APKs
5. Distributes APKs via Firebase App Distribution

Track progress at:
```
https://github.com/mfranchescagonzalezcejas/inkscroller_flutter/actions
```

---

## Required GitHub Secrets

Go to **Settings → Secrets and variables → Actions** and verify these are set:

### Firebase dart-defines

| Secret | Description |
|--------|-------------|
| `FIREBASE_DART_DEFINES_JSON` | Full contents of `.dart-defines/firebase.json` — all Firebase keys for all flavors |

### Android release signing

Use one of these secure approaches:

1. **local file** `android/key.properties` (non-committed)
2. **environment variables** in CI/local shells

#### Secrets / env vars used by `android/app/build.gradle.kts`

| Secret / Env | Description |
|--------------|-------------|
| `KEY_ALIAS` | Keystore key alias |
| `KEY_PASSWORD` | Password for the signing key |
| `KEYSTORE_PASSWORD` | Keystore password |
| `KEYSTORE_FILE_PATH` *(optional)* | Relative path to keystore file (resolved from `android/app`); defaults to `upload-keystore.jks` which maps to `android/app/upload-keystore.jks` |
| `KEYSTORE_BASE64` | Base64-encoded keystore contents for CI restore |

`KEYSTORE_FILE_PATH` is optional when your `android/key.properties` contains `storeFile`.

`android/key.properties` example (with placeholders):

```properties
storePassword=<keystore-password>
keyPassword=<key-password>
keyAlias=<key-alias>
storeFile=upload-keystore.jks
```

#### Local setup

1. Generate/import your upload keystore as `android/app/upload-keystore.jks`.
2. Create `android/key.properties` (ignored by git) with the values above.
3. Run release tasks.

#### CI setup

1. Store keystore and signing values as GitHub secrets.
2. In release workflow, restore keystore from `KEYSTORE_BASE64` to `android/app/upload-keystore.jks`.
3. Write `android/key.properties` with `${{ secrets.KEY_ALIAS }}`, `${{ secrets.KEY_PASSWORD }}`, `${{ secrets.KEYSTORE_PASSWORD }}`.

If these values are not present, release builds fail fast with a clear message instead of using debug signing.

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

## Rollback

If a release has a critical bug:

1. **Do not delete the tag** — it stays for history.
2. Fix the bug on a branch, merge to `master`.
3. Bump `pubspec.yaml` to the next patch version (e.g. `1.2.4`).
4. Run the release script again with the new version.

There is no automated rollback — Firebase App Distribution testers will receive
the new build as an update.

---

## Checklist

- [ ] `pubspec.yaml` version bumped (semver + build number)
- [ ] All changes merged to `master`
- [ ] `FIREBASE_DART_DEFINES_JSON` secret is up to date
- [ ] All other secrets configured (see table above)
- [ ] Android signing config (`android/key.properties` or signing env vars) is configured for release
- [ ] Run `./scripts/release.sh X.Y.Z` (or `.ps1` on Windows)
- [ ] Confirm GitHub Release created and APKs attached
- [ ] Confirm Firebase App Distribution emails sent
