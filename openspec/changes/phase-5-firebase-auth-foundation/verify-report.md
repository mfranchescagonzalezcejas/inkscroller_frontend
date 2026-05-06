# Verification Report

**Change**: phase-5-firebase-auth-foundation  
**Version**: N/A  
**Mode**: Standard

---

### Completeness
| Metric | Value |
|--------|-------|
| Tasks total | 18 |
| Tasks complete | 17 |
| Tasks incomplete | 1 |

Incomplete tasks from the tracked task list:
- 4.3 Update `lib/features/navigation/presentation/pages/main_scaffold.dart` — deferred to M3

Focused task-artifact recheck:
- ✅ The stale checkbox issue is resolved in `openspec/changes/phase-5-firebase-auth-foundation/tasks.md`: task 5.3 is now checked and matches `../Inkscroller_backend/.github/workflows/ci.yml`.
- ⚠️ The Engram `apply-progress` artifact is now stale on this point because it still says 5.3 was deferred.

---

### Build & Tests Execution

**Build**: ➖ Skipped by instruction (`Do NOT run builds`).

**Tests**: ❌ Not executed in this environment
```text
Flutter: `fvm` is not installed / not on PATH, so `fvm flutter test` cannot run.
Backend: `python` / `py` are not available on PATH, so backend unittest execution cannot run.
Detected repo pins still exist: Flutter `.fvmrc` -> 3.41.5, backend `.python-version` -> 3.12.10.
```

**Coverage**: ➖ Not available (tests could not be executed)

---

### Spec Compliance Matrix
| Requirement | Scenario | Test | Result |
|-------------|----------|------|--------|
| R1 Flutter email/password auth | user signs in with Firebase Auth | `test/features/auth/presentation/providers/auth_notifier_test.dart` exists but was not executed in this environment | ❌ UNTESTED |
| R2 Auth-aware routing/session | unauthenticated user is redirected | `test/core/router/app_router_test.dart` exists but was not executed in this environment | ❌ UNTESTED |
| R2 Auth-aware routing/session | authenticated user restores session | `test/core/router/app_router_test.dart` exists but was not executed in this environment | ❌ UNTESTED |
| R3 Token propagation | authenticated request reaches backend | `test/core/network/dio_client_test.dart` exists but was not executed in this environment | ❌ UNTESTED |
| R4 Backend verifies Firebase tokens | valid Firebase token accepted | `tests/test_users_auth.py` happy-path tests exist, but they override `get_current_user` and could not be executed here | ⚠️ PARTIAL |
| R4 Backend verifies Firebase tokens | invalid or missing token rejected | `tests/test_users_auth.py` contains rejection tests, but they could not be executed here | ❌ UNTESTED |
| R5 Bootstrap local user | first authenticated request bootstraps local user | `tests/test_users_auth.py` exists but could not be executed here | ❌ UNTESTED |
| R6 `/users/me` profile | authenticated user fetches profile | `tests/test_users_auth.py` exists but could not be executed here | ❌ UNTESTED |
| R7 Preferences read/update | read preferences | `tests/test_users_auth.py` exists but could not be executed here | ❌ UNTESTED |
| R7 Preferences read/update | update preferences | `tests/test_users_auth.py` exists but could not be executed here | ❌ UNTESTED |
| R8 Explicit/safe error handling | common failure cases | backend wiring is present statically; no executed runtime proof in this pass | ⚠️ PARTIAL |
| R9 Out-of-scope guardrails | MVP remains narrow | no runtime test applicable; static evidence only | ⚠️ PARTIAL |
| R10 Docs/auth pivot | docs reflect new implementation path | no runtime test applicable; static doc review only | ⚠️ PARTIAL |

**Compliance summary**: 0/12 scenarios behaviorally proven in this verification run

---

### Correctness (Static — Structural Evidence)
| Requirement | Status | Notes |
|------------|--------|-------|
| Flutter integrates Firebase email/password auth | ✅ Implemented | `pubspec.yaml` adds `firebase_auth`; auth clean-architecture slice, login/register pages, and use cases exist. |
| Auth-aware navigation/session handling exists | ✅ Implemented | `app_router.dart` uses `FirebaseAuth.instance.currentUser` plus `authStateChanges()` refresh to guard protected routes and redirect auth surfaces appropriately. |
| Firebase ID token propagation exists | ✅ Implemented | `dio_client.dart` attaches `Authorization: Bearer <token>` for `/users*` requests. |
| Backend verifies Firebase tokens | ✅ Implemented | `app/core/firebase_auth.py` defines `verify_firebase_token()` and `dependencies.py` invokes it in `get_current_user()`. |
| Backend bootstraps local user by UID | ✅ Implemented | `user_service.py` inserts `users(firebase_uid, email, display_name, created_at)` on first authenticated access. |
| `/users/me` endpoint exists and matches intent | ✅ Implemented | `app/api/users.py` exposes `GET /users/me` returning `UserProfile`. |
| `/users/me/preferences` endpoints exist and persist to SQLite | ✅ Implemented | `app/api/users.py` exposes GET/PUT; `user_service.py` creates defaults and persists updates. |
| Explicit/safe error handling | ✅ Implemented (static) | `get_current_user()` raises `AuthError`; `update_preferences()` can raise `PreferencesValidationError`; both handlers are registered in `register_exception_handlers()` and emit the shared `_error_response()` shape. |
| Social login/progress/favorites remain out of scope | ✅ Implemented | No Google/Apple auth providers, sync routes, favorites, or progress endpoints were added. |
| Docs/auth pivot | ⚠️ Partial | Vault PRD now uses Firebase-auth-first wording with JWT references explicitly superseded, but the repo PRD still contains active JWT-first planning text and `/auth/*` endpoint scope in multiple sections. |

---

### Coherence (Design)
| Decision | Followed? | Notes |
|----------|-----------|-------|
| Flutter uses `firebase_auth` clean-architecture slice | ✅ Yes | Auth feature structure matches design (`domain`, `data`, `presentation`). |
| Router redirects based on auth session | ✅ Yes | `GoRouter` guard is implemented with Firebase session awareness. |
| Dio attaches Bearer token for protected paths | ⚠️ Slight deviation | Implemented, but interceptor reads `FirebaseAuth.instance` directly instead of going through the auth use case/repository abstraction described in the design text. |
| Backend verifies Firebase tokens via Firebase Admin | ✅ Yes | `firebase-admin` helper exists and is wired in request dependency chain. |
| SQLite keyed by Firebase UID for profile/preferences | ✅ Yes | Schema and service layer match design. |
| Auth-safe/custom error response shape | ✅ Yes (static) | The active dependency/update flow now routes through `AuthError` / `PreferencesValidationError` handlers instead of relying only on default FastAPI behavior. |
| Docs fully mark JWT-first as superseded | ⚠️ Deviated | Vault PRD is clean enough for the pivot; repo PRD still contains unsuperseded JWT-first planning text. |

---

### Focused Re-Validation Findings

- **Vault PRD leftover JWT wording**: ✅ Revalidated. In `1-PROJECTS/InkScroller Flutter/01 - PRD/Phase 5 - Identity & Adaptive Reading.md`, JWT mentions are now framed as revised/superseded history, not active baseline. However, one separate stale scope line still lists backend `/auth/*` endpoints as MVP, which is not JWT wording but is still outdated scope.
- **Task artifact stale checkbox**: ✅ Resolved in the filesystem task artifact (`5.3` now checked).
- **Backend auth/preferences custom error handling**: ✅ Revalidated statically. `AuthError` and `PreferencesValidationError` are wired to the active dependency/service paths and share `_error_response()`.
- **Remaining true runtime blockers**: only behavioral proof items remain blocked by missing runtime tooling/tests: unavailable Python/FVM, missing Flutter auth tests, and lack of executed proof for real Firebase happy-path verification.

---

### Issues Found

**CRITICAL** (must fix before archive):
- Runtime verification still cannot complete because this environment lacks working Python and Flutter/FVM toolchains, so no spec scenario was behaviorally proven in this rerun.
- Flutter auth scenarios (sign-in, route guard, session restore, token propagation) have test files in `test/`, but they remain unproven in this verification pass because tests were not executed in this environment.

**WARNING** (should fix):
- Repo PRD `docs/PRD/phase-5-identity-and-adaptive-reading.md` still contains active JWT-first planning text (`WS-A`, milestone M1, dependency map, backend API surface, risks, and Sprint 1 task wording) that contradicts the Firebase-auth-first pivot.
- Backend happy-path tests override `get_current_user`, so even once Python is available they still will not prove the real Firebase verification success path unless adjusted.
- Engram `sdd/phase-5-firebase-auth-foundation/apply-progress` is stale on task 5.3 status.

**SUGGESTION** (nice to have):
- Add a backend test that patches `verify_firebase_token()` instead of overriding `get_current_user`, so the real dependency chain is exercised while staying hermetic.
- Add focused Flutter unit/widget tests for `AuthNotifier`, router redirect behavior, and Dio token injection before archive.

---

### Verdict
FAIL

The warning-fix pass resolved the targeted non-runtime issues in the vault PRD, task checklist, and backend custom error wiring, but verification still cannot pass because runtime proof is still unavailable and the repo PRD still contains stale JWT-first planning text.
