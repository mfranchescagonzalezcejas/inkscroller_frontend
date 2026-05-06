# CI / CD

This repository uses **GitHub Actions** for two pipelines:

1. **CI** on `push` / `pull_request` to `develop` → runs `fvm flutter analyze` and `fvm flutter test`
2. **Release** on `push` of semver tag (`vX.Y.Z`) → quality gates, APK builds, GitHub Release, Firebase App Distribution

The release pipeline builds and distributes **three flavors**: DEV, STAGING, PRODUCTION (PRO).

---

## When do workflows run?

### CI (`.github/workflows/ci.yml`)

- On every `push` to `develop`
- On every `pull_request` targeting `develop`

### Release (`.github/workflows/release.yml`)

Triggered automatically when a semver tag is pushed:

```text
git tag v1.2.3
git push origin v1.2.3
```

> Use the cross-platform release scripts — they enforce pre-flight checks before tagging.
> See [RELEASING.md](RELEASING.md) for the full release flow.

---

## Required GitHub Secrets

Go to: **Settings → Secrets and variables → Actions**

### Firebase dart-defines

| Secret | Description |
|--------|-------------|
| `FIREBASE_DART_DEFINES_JSON` | Full contents of `.dart-defines/firebase.json` — all Firebase keys for all flavors |

### API Base URLs

| Secret | Description |
|--------|-------------|
| `API_BASE_URL_DEV` | Backend base URL for DEV builds |
| `API_BASE_URL_STAGING` | Backend base URL for STAGING builds |
| `API_BASE_URL_PRO` | Backend base URL for PRODUCTION builds |

### Firebase App Distribution

| Secret | Description |
|--------|-------------|
| `FIREBASE_SERVICE_ACCOUNT_JSON_DEV` | Service account JSON for DEV Firebase project |
| `FIREBASE_SERVICE_ACCOUNT_JSON_STAGING` | Service account JSON for STAGING Firebase project |
| `FIREBASE_SERVICE_ACCOUNT_JSON_PRO` | Service account JSON for PRO Firebase project |
| `FIREBASE_APP_ID_DEV` | Firebase App ID for DEV flavor |
| `FIREBASE_APP_ID_STAGING` | Firebase App ID for STAGING flavor |
| `FIREBASE_APP_ID_PRO` | Firebase App ID for PRODUCTION flavor |
| `FIREBASE_TESTERS` | Comma-separated tester emails (no spaces) |

---

## Quality gates

Before distributing any build, the release workflow runs:

1. `fvm flutter analyze`
2. `fvm flutter test`
3. Version validation — `pubspec.yaml` semver must match the pushed tag

If any step fails, no APKs are distributed.

The CI workflow runs the same quality gate on every push/PR to `develop`.

---

## Versioning rules

```yaml
# pubspec.yaml
version: 1.2.3+45   # semver+build-number
```

- The **semver** (`1.2.3`) must match the tag (`v1.2.3`)
- The **build number** (`+45`) must be incremented on every release
- The release scripts enforce the pubspec ↔ tag match before creating the tag

---

## Release notes generation

Notes are generated from Git commit messages since the previous tag.

| Prefix | Included in notes |
|--------|------------------|
| `feat:` | ✅ New features |
| `fix:` | ✅ Bug fixes |
| `chore:`, `ci:`, etc. | ❌ Excluded |

### Per flavor

| Flavor | Included commits |
|--------|-----------------|
| DEV | `feat:` + `fix:` |
| STAGING | `fix:` only |
| PRODUCTION | `fix:` only |

If no matching commits are found, the notes default to `- No user-visible changes`.

---

## Build & distribution

For each release the workflow:

1. Builds APKs for all three flavors
2. Creates a GitHub Release and attaches all APKs
3. Distributes APKs via Firebase App Distribution

Generated artifacts:

- `app-dev-release.apk`
- `app-staging-release.apk`
- `app-pro-release.apk`

---

## Local development commands

```bash
fvm flutter run --flavor dev     -t lib/main_dev.dart
fvm flutter run --flavor staging -t lib/main_staging.dart
fvm flutter run --flavor pro     -t lib/main_pro.dart
```

---

## Design decisions

- Firebase keys are injected at build time via `--dart-define-from-file` using a single `FIREBASE_DART_DEFINES_JSON` CI secret — no hardcoded keys in source
- Release is tag-driven, not triggered by manually publishing a GitHub Release
- Cross-platform release scripts enforce 6 pre-flight checks before tagging
- Flutter version is pinned in CI via FVM for reproducibility
- Release notes rely on commit conventions instead of manual input

---

## Checklist before releasing

See [RELEASING.md](RELEASING.md) for the complete checklist.

Quick summary:

- [ ] `pubspec.yaml` version bumped (semver + build number)
- [ ] All changes merged to `master`
- [ ] `FIREBASE_DART_DEFINES_JSON` secret is up to date
- [ ] All other secrets configured
- [ ] Run `./scripts/release.sh X.Y.Z` (or `.ps1` on Windows)
