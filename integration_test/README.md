# E2E Testing — InkScroller

End-to-end tests that run on a **real device** against the **dev Firebase project** and **dev backend API**. No mocks, no fakes — the tests exercise the full stack from Flutter UI to Firebase Auth to the backend.

## Prerequisites

1. **Physical Android device** connected via USB (or emulator with Google Play Services)
2. **Flutter/FVM** installed (`fvm use` should resolve to 3.41.5+)
3. **Firebase config** at `.dart-defines/firebase.json` (gitignored, never committed)
4. **Dev backend** running at `https://api.dev.inkscroller.devdigi.dev`
5. **Firebase email verification** disabled in the dev project

### Check your device

```bash
fvm flutter devices
# Should show your device with an ID like "SM G991B" or similar
```

### Verify Firebase config

```bash
cat .dart-defines/firebase.json
# Should contain: FIREBASE_API_KEY, FIREBASE_APP_ID, FIREBASE_PROJECT_ID, etc.
```

> **REST cleanup requires `FIREBASE_WEB_API_KEY`** — the Firebase Identity
> Toolkit REST API (`accounts:signInWithPassword`, `accounts:delete`) needs the
> *Web* API key, not the Android/iOS platform keys. Add it to your
> `.dart-defines/firebase.json` or pass it via
> `--dart-define=FIREBASE_WEB_API_KEY=<key>`. Without it, `deleteTestUser()`
> throws a `StateError` during cleanup/tearDown — fail-fast, no silent fallback.

## Running Tests

### All tests

```bash
fvm flutter test integration_test/ \
  --flavor dev \
  --dart-define=E2E=true \
  --dart-define-from-file=.dart-defines/firebase.json \
  -d "YOUR_DEVICE_ID" \
  --timeout 600s
```

### Single test file

```bash
fvm flutter test integration_test/e2e_sign_up_test.dart \
  --flavor dev \
  --dart-define=E2E=true \
  --dart-define-from-file=.dart-defines/firebase.json \
  -d "YOUR_DEVICE_ID" \
  --timeout 300s
```

### Available test files

| File | What it tests | Time |
|------|--------------|------|
| `e2e_guest_navigation_test.dart` | Home → Explore → Library → Profile (unauthenticated) | ~7s |
| `e2e_sign_up_test.dart` | Registration with valid data | ~35s |
| `e2e_sign_in_test.dart` | Login with valid credentials | ~70s |
| `e2e_sign_in_invalid_test.dart` | Login with wrong password → error message | ~70s |
| `e2e_sign_out_test.dart` | Sign out → redirect to guest state | ~40s |
| `e2e_duplicate_email_test.dart` | Register with existing email → error | ~75s |
| `e2e_authenticated_navigation_test.dart` | Library → manga detail → reader → back | ~40s |
| `e2e_delete_account_test.dart` | Delete account (confirm, re-login fails, cancel) | ~5min |

**Total suite time: ~10–12 minutes** on a physical device.

## Architecture

### Test flow

```
pumpE2EApp()          → Resets GetIt, signs out Firebase, launches app
  ↓
TestUser.fresh()      → Generates unique email + fixed password
  ↓
completeSignUp()      → Navigates to register, fills form, submits
  ↓
[Test-specific flow]  → Sign in, navigate, delete, etc.
  ↓
deleteTestUser()      → REST API cleanup (safety net)
```

### Helper files

| File | Purpose |
|------|---------|
| `test/e2e/helpers/test_app.dart` | `pumpE2EApp()` — bootstraps the real app |
| `test/e2e/helpers/test_user.dart` | `TestUser.fresh()` — generates unique test users |
| `test/e2e/helpers/auth_flows.dart` | `completeSignUp()`, `completeSignIn()`, `completeSignOut()`, `openDeleteDialog()`, `fillRegistrationForm()` |
| `test/e2e/helpers/cleanup.dart` | `deleteTestUser()` — REST API user deletion |

### Key conventions

- **Use `Key(...)` finders, not text finders** — the app can be in English or Spanish depending on device locale. All interactive elements have production keys.
- **No `pumpAndSettle()`** — infinite gradient/shimmer animations prevent settling. Use finite pump loops: `for (var i = 0; i < N; i++) { await tester.pump(Duration(seconds: 1)); }`
- **Human-like delays** — typing delays, pauses between taps, realistic interaction timing.
- **`warnIfMissed: false`** — required for CheckboxListTile, AuthGradientButton, and other widgets with hit-test quirks.
- **Unique emails** — `TestUser.fresh()` generates `test-{timestamp}-{random}@e2e.inkscroller.dev` to avoid collisions.

### Cleanup strategy

1. **Primary**: Each test's `tearDown` calls `deleteTestUser()` via Firebase Auth REST API
2. **Safety net**: `delete_account_test.dart` has a group-level `tearDown` as backup
3. **Edge cases**: `deleteTestUser()` treats `EMAIL_NOT_FOUND`, `INVALID_PASSWORD`, and `INVALID_LOGIN_CREDENTIALS` as "already cleaned"

## Adding a new test

1. Create `integration_test/e2e_<name>_test.dart`
2. Import the helpers:

```dart
import '../test/e2e/helpers/auth_flows.dart';
import '../test/e2e/helpers/cleanup.dart';
import '../test/e2e/helpers/test_app.dart';
import '../test/e2e/helpers/test_user.dart';
```

3. Follow this structure:

```dart
void main() {
  late TestUser user;

  setUp(() {
    user = TestUser.fresh();
  });

  tearDown(() async {
    await deleteTestUser(email: user.email, password: user.password);
  });

  testWidgets('My test description', (tester) async {
    await pumpE2EApp(tester);
    await completeSignUp(tester, user);

    // ... your test logic ...

    // Use Key(...) finders, not text finders
    expect(find.byKey(const Key('navProfile')), findsOneWidget);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
```

4. Add a production key to any new widget you need to find
5. Run on device: `fvm flutter test integration_test/e2e_<name>_test.dart --flavor dev --dart-define=E2E=true --dart-define-from-file=.dart-defines/firebase.json -d "YOUR_DEVICE_ID" --timeout 300s`

## Troubleshooting

### "Couldn't find constructor 'Key'"

Missing `import 'package:flutter/material.dart';`. Add it to your test file.

### Test hangs forever

`pumpAndSettle()` is blocked by infinite animations. Replace with a finite pump loop.

### "ProviderContainer already disposed" after test passes

Add post-test pumps before the test ends:
```dart
for (var i = 0; i < 4; i++) {
  await tester.pump(const Duration(seconds: 1));
}
```

### User not cleaned up

Check `deleteTestUser()` output. If you see `INVALID_LOGIN_CREDENTIALS`, the user was already deleted by the UI flow — that's fine.

### Device not found

Run `adb devices` to verify the device is connected. The `-d` flag must match the device name from `fvm flutter devices`.

### Firebase config missing

Ensure `.dart-defines/firebase.json` exists and contains all required keys. This file is gitignored — ask a team member for the dev config.

## What we DON'T test

- **CI/CD** — tests run locally on physical device only
- **iOS** — Android only (physical Samsung Galaxy S21)
- **Staging/Prod** — tests target the dev Firebase project
- **Edge cases on slow networks** — tests assume stable connection to dev backend
