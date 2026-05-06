# Firebase App Distribution

Firebase App Distribution is handled **automatically by CI** when a semver tag is pushed.
There is no manual distribution script — the release pipeline covers all three flavors.

See [RELEASING.md](RELEASING.md) for the full release flow and [ci.md](ci.md) for workflow details.

---

## How it works

1. Push a semver tag via the release scripts (`release.sh` / `release.ps1`)
2. `.github/workflows/release.yml` triggers automatically
3. CI builds DEV / STAGING / PRO APKs
4. APKs are attached to the GitHub Release
5. Firebase App Distribution sends download emails to all configured testers

---

## Flavors distributed

| Flavor | Entry point | Firebase project |
|--------|-------------|-----------------|
| DEV | `lib/main_dev.dart` | DEV Firebase project |
| STAGING | `lib/main_staging.dart` | STAGING Firebase project |
| PRO | `lib/main_pro.dart` | PRO Firebase project |

---

## Required secrets

| Secret | Description |
|--------|-------------|
| `FIREBASE_DART_DEFINES_JSON` | Full contents of `.dart-defines/firebase.json` |
| `FIREBASE_SERVICE_ACCOUNT_JSON_DEV` | Service account JSON for DEV |
| `FIREBASE_SERVICE_ACCOUNT_JSON_STAGING` | Service account JSON for STAGING |
| `FIREBASE_SERVICE_ACCOUNT_JSON_PRO` | Service account JSON for PRO |
| `FIREBASE_APP_ID_DEV` | Firebase App ID — DEV flavor |
| `FIREBASE_APP_ID_STAGING` | Firebase App ID — STAGING flavor |
| `FIREBASE_APP_ID_PRO` | Firebase App ID — PRO flavor |
| `FIREBASE_TESTERS` | Comma-separated tester emails (no spaces) |

---

## Local builds (development only)

To build an APK locally for manual testing, use the `.run` configs in the IDE or:

```bash
fvm flutter build apk \
  --flavor dev \
  -t lib/main_dev.dart \
  --dart-define-from-file=.dart-defines/firebase.json \
  --dart-define=API_BASE_URL=http://your-backend-url
```

Replace `dev` / `main_dev.dart` with the target flavor as needed.

> Local `.dart-defines/firebase.json` must exist. Copy from `.dart-defines/firebase.example.json`
> and fill in your keys. This file is gitignored and never committed.
