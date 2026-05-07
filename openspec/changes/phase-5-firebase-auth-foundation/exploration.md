# Exploration: phase-5-firebase-auth-foundation

> **Phase:** Explore
> **Change:** phase-5-firebase-auth-foundation
> **Date:** 2026-04-03
> **Status:** Complete — Ready for Proposal

---

## Current State

### Flutter app — exact Firebase state

Firebase is already fully bootstrapped. Three flavors (dev, staging, pro) each have:
- `android/app/src/<flavor>/google-services.json` ✅
- `ios/config/<flavor>/GoogleService-Info.plist` ✅
- `firebase_options.dart` with `FirebaseOptions` per flavor/platform ✅
- `Firebase.initializeApp()` called in `main_common.dart` ✅
- `FirebaseAnalytics` initialized and wired ✅

**What is NOT present:** `firebase_auth` package, `FirebaseAuth.instance`, any auth state, any auth UI, any auth feature folder.

### Backend — exact state

Pure stateless FastAPI proxy. Zero auth, zero persistence, zero user concept.

**What is NOT present:** `firebase-admin`, `python-jose`, `passlib`, `aiosqlite`, any JWT logic, any user model.

### Flutter architecture baseline

| Layer | Pattern | Relevant to auth |
|-------|---------|-----------------|
| DI | `get_it` + `initDI()` in `main_common.dart` | `FirebaseAuth.instance` registered as lazy singleton here |
| State | Riverpod `StateNotifier` + immutable state with `copyWith()` | Auth state as Riverpod notifier |
| Router | `go_router` with `GoRouter` + `StatefulShellRoute` | Auth guard via `redirect` callback |
| Network | `DioClient` singleton, no auth headers today | Add `Authorization: Bearer <id_token>` interceptor |
| Errors | `Failure` sealed class hierarchy | Add `AuthFailure` subclass |

---

## Firebase Auth in This Stack — How It Works

```
FirebaseAuth.instance.signInWithEmailAndPassword()
        │
        ▼
Firebase Auth service
        │
        ▼
User.getIdToken()  →  Firebase ID Token (JWT, RS256, valid 1h)
        │
        ▼
Dio interceptor adds:  Authorization: Bearer <id_token>
        │
        ▼
FastAPI backend
        │
        ▼
firebase-admin SDK verifies token (JWKS auto-fetched from Google)
        │
        ▼
Decoded payload: { uid, email, ... }
        │
        ▼
SQLite: SELECT/INSERT user by uid → app logic
```

---

## What Changes Are Required

### Flutter side (WS-A)

| # | What | Files | Impact |
|---|------|-------|--------|
| A1 | Add `firebase_auth` to `pubspec.yaml` | `pubspec.yaml` | NEW dependency |
| A2 | Register `FirebaseAuth.instance` in DI | `lib/core/di/injection.dart` | Tiny additive change |
| A3 | Create `auth` feature folder with Clean Architecture shape | `lib/features/auth/` | NEW feature |
| A4 | Domain: `AuthRepository` contract + `AppUser` entity + use cases (`SignIn`, `SignOut`, `GetCurrentUser`) | `lib/features/auth/domain/` | NEW, zero framework deps |
| A5 | Data: `FirebaseAuthDataSource` + `AuthRepositoryImpl` + `AppUserMapper` | `lib/features/auth/data/` | NEW |
| A6 | Presentation: `AuthState`, `AuthNotifier`, auth providers | `lib/features/auth/presentation/providers/` | NEW |
| A7 | Presentation: `LoginPage` (email+password fields, error display) | `lib/features/auth/presentation/pages/` | NEW |
| A8 | Add `AuthFailure` to domain failures | `lib/core/error/failures.dart` | Small additive |
| A9 | Add auth guard to `go_router` via `redirect` + `refreshListenable` | `lib/core/router/app_router.dart` | Moderate change |
| A10 | Add Dio interceptor: `getIdToken()` → `Authorization: Bearer` header | `lib/core/network/dio_client.dart` | Additive interceptor |

### Backend side (WS-B)

| # | What | Files | Impact |
|---|------|-------|--------|
| B1 | Add `firebase-admin` to `requirements.txt` | `requirements.txt` | NEW dependency |
| B2 | Initialize Firebase Admin SDK in lifespan | `main.py` | Additive |
| B3 | `FIREBASE_PROJECT_ID` env var (+ `SERVICE_ACCOUNT_KEY_PATH` optional) | `app/core/config.py` | Additive config |
| B4 | `verify_firebase_token(token: str) → dict` utility | `app/core/firebase_auth.py` | NEW file |
| B5 | `get_current_user` dependency: extract Bearer → verify → lookup/bootstrap | `app/core/dependencies.py` | Additive |
| B6 | SQLite: `users` table keyed by Firebase UID (TEXT), no `hashed_password` | `app/core/database.py` | NEW file |
| B7 | `reading_preferences` table keyed by `user_id` (Firebase UID) | same `database.py` | NEW file |
| B8 | `UserService`: `get_or_create_by_uid(uid, email, display_name)` | `app/services/user_service.py` | NEW service |
| B9 | `POST /users/me` (bootstrap/sync) or auto-bootstrap on first `GET /users/me` | `app/api/users.py` | NEW router |
| B10 | `GET /users/me/preferences` + `PUT /users/me/preferences` | same `app/api/users.py` | NEW endpoints |

---

## Comparison: Firebase Auth First vs Backend-JWT First (Superseded)

| Dimension | Backend-JWT (superseded) | Firebase Auth (chosen) |
|-----------|--------------------------|------------------------|
| **Auth logic location** | Backend owns password hashing + JWT signing | Firebase owns password/social/MFA; backend only verifies |
| **Flutter dependency** | Custom login → POST `/auth/login` → store JWT | `firebase_auth` → `getIdToken()` auto-managed |
| **Token lifecycle** | Manual refresh via `POST /auth/refresh` interceptor | Firebase SDK handles refresh automatically |
| **New backend files (auth)** | `app/core/auth.py`, `app/api/auth.py` (register/login/refresh) | `app/core/firebase_auth.py` (verify only) |
| **Superseded backend files** | `app/core/auth.py`, `app/api/auth.py`, `app/models/user.py` (password hash), `app/core/exceptions.py` (AuthenticationError, DuplicateUserError) | All password/JWT-sign logic eliminated |
| **Kept backend files** | `app/core/database.py`, `app/models/user.py` (no password), `app/services/user_service.py`, `app/api/users.py`, `app/core/dependencies.py` | Same shape, different user key (uid not email) |
| **SQLite schema** | `users(id UUID, email, display_name, hashed_password, created_at)` | `users(uid TEXT PK, email, display_name, created_at)` — no password column |
| **Backend secrets** | `JWT_SECRET_KEY` (required, app crashes if absent) | `FIREBASE_PROJECT_ID` (required); optionally service account key |
| **Social auth (Google, Apple)** | Requires full OAuth2 integration in backend | Firebase handles it natively; backend gets same verified token |
| **Emulator testing** | Standard TestClient + in-memory SQLite | Firebase Auth Emulator required; or mock `verify_firebase_token` |
| **Production security** | HS256 secret rotation risk | RS256 token, JWKS auto-rotated by Google |
| **Offline capability** | Token stored in Flutter secure storage | Firebase SDK caches user state natively |
| **Flutter code volume** | Higher (manual token storage, refresh, state) | Lower (Firebase SDK manages state + refresh) |
| **Backend code volume** | Higher (register/login/hash endpoints) | Lower (verify-only, no auth endpoint) |
| **Implementation effort** | Backend: High. Flutter: High | Backend: Medium. Flutter: Medium |

**Verdict:** Firebase Auth eliminates an entire auth subsystem from the backend and simplifies the Flutter side. The remaining backend work is almost identical — SQLite persistence + user/preferences endpoints — just with Firebase UID as the key and `firebase-admin` verification instead of `python-jose` signing.

---

## Persistence: What SQLite Still Stores

SQLite is still 100% justified. Firebase Auth stores identity only (email, password, social tokens). **The backend must store:**

| Table | Purpose | Keyed by |
|-------|---------|----------|
| `users` | Display name, created_at, any app-specific profile fields | `uid` (Firebase UID, TEXT) |
| `reading_preferences` | Reader mode, default language, zoom, etc. | `uid` (FK to users) |

**Eliminated from SQLite:** `hashed_password` column, any token revocation tables.

Firebase Firestore is NOT needed — the backend already has SQLite + a custom API, and adding Firestore would be over-engineering for an app that already has a FastAPI backend.

---

## Minimum Viable First Slice (MVP)

The narrowest first slice that delivers end-to-end value:

### Slice 1 — "Sign in and reach a protected page"

**Flutter:**
1. Add `firebase_auth: ^5.x.x` to pubspec
2. Create `AppUser` entity (uid, email, displayName)
3. Create `AuthRepository` contract + `FirebaseAuthDataSource` + `AuthRepositoryImpl`
4. Create `SignInWithEmailAndPassword` use case + `SignOut` use case + `GetAuthStateChanges` use case  
5. Create `AuthNotifier` (StateNotifier) + `authProvider` (StreamProvider watching `authStateChanges()`)
6. Create minimal `LoginPage` (email/password form)
7. Add auth guard to router: unauthenticated → `/login`, authenticated → `/`

**Backend:**
1. Add `firebase-admin` to requirements
2. Init Firebase Admin in lifespan
3. Add `FIREBASE_PROJECT_ID` to config
4. Create `app/core/firebase_auth.py` with `verify_firebase_token()`
5. Create `app/core/database.py` (SQLite init, WAL, schema)
6. Create `app/services/user_service.py` with `get_or_create_by_uid()`
7. Create `app/api/users.py` with `GET /users/me`
8. Add `get_current_user` dependency

**What this delivers:** User can sign in with email/password → app shows home → every API request carries a Firebase ID token → backend verifies it and bootstraps the user row on first call.

**What is deferred:** Registration UI (Firebase Console or SDK `createUserWithEmailAndPassword` — trivial add), preferences API, display name edit, social providers (Google/Apple).

---

## Migration Impact on Superseded `phase-5-backend-foundation` Artifacts

| Artifact | Status | Action |
|----------|--------|--------|
| `openspec/changes/phase-5-backend-foundation/exploration.md` | Superseded | Archive in place; new exploration replaces it |
| `openspec/changes/phase-5-backend-foundation/design.md` | Superseded | Archive; reuse structural patterns but remove auth/password sections |
| Engram tasks artifact (`sdd/phase-5-backend-foundation/tasks`) | Superseded | Replace with new tasks for `phase-5-firebase-auth-foundation` |
| Backend file `app/core/auth.py` | NOT created yet → skip | Not needed in Firebase Auth plan |
| Backend file `app/api/auth.py` | NOT created yet → skip | Not needed |
| SQLite schema `hashed_password` column | NOT created yet → skip | Schema changes to UID-keyed, no password |
| JWT secret management | NOT implemented → skip | Replace with `FIREBASE_PROJECT_ID` |
| `passlib`, `python-jose`, `bcrypt` deps | NOT installed → skip | Replace with `firebase-admin` |

**Net delta vs previous plan:**
- Eliminate: `app/core/auth.py`, `app/api/auth.py`, password hashing, JWT signing, `passlib`, `python-jose`, `bcrypt`, `JWT_SECRET_KEY`
- Add: `firebase-admin`, `FIREBASE_PROJECT_ID`, `app/core/firebase_auth.py`
- Keep (unchanged shape): `app/core/database.py`, `app/services/user_service.py`, `app/api/users.py`, `app/core/dependencies.py` (modified pattern)

---

## Affected Files

### Flutter (new)
- `pubspec.yaml` — add `firebase_auth`
- `lib/features/auth/` — entire new feature module
- `lib/core/di/injection.dart` — register FirebaseAuth, AuthRepository, use cases
- `lib/core/error/failures.dart` — add `AuthFailure`
- `lib/core/router/app_router.dart` — auth redirect guard
- `lib/core/network/dio_client.dart` — add Bearer token interceptor

### Backend (new)
- `requirements.txt` — add `firebase-admin`, keep `aiosqlite`, `python-dotenv`
- `app/core/config.py` — add `FIREBASE_PROJECT_ID`, `DB_PATH`
- `app/core/firebase_auth.py` — NEW: token verification
- `app/core/database.py` — NEW: SQLite init (UID-keyed schema)
- `app/core/dependencies.py` — add `get_db`, `get_user_service`, `get_current_user`
- `app/models/user.py` — NEW: `UserResponse`, `ReadingPreferencesResponse`, etc.
- `app/services/user_service.py` — NEW: `get_or_create_by_uid`, preferences CRUD
- `app/api/users.py` — NEW: `/users/me` + `/users/me/preferences`
- `main.py` — init Firebase Admin + DB in lifespan, include users router
- `.env.example` — NEW: documents required vars

---

## Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| **Firebase Auth Emulator required for local testing** | Medium | `flutter pub add firebase_emulator_suite` or use `FirebaseAuth.instance.useAuthEmulator()` in dev flavor; mock `verify_firebase_token` in pytest with monkeypatch |
| **`google-services.json` has no `oauth_client` for email/password** | Low | Email/password auth doesn't require OAuth client entries; only Google Sign-In does |
| **ID token expiry (1h) with no mid-session refresh** | Medium | `user.getIdToken(forceRefresh: false)` in Dio interceptor — Firebase SDK automatically returns a fresh token if the cached one is expired |
| **Dio interceptor must be async** | Low | Use `InterceptorsWrapper.onRequest` with `await user.getIdToken()` pattern |
| **Backend verifies token on every request** | Low | `firebase-admin` caches JWKS; local token validation is sub-millisecond after first fetch |
| **Service account key as secret** | High if using SA | For local dev, `GOOGLE_APPLICATION_DEFAULT_CREDENTIALS` works; for production deploy (Railway/Fly), use env var with JSON content |
| **Apple Sign-In future** | Low (planning) | Firebase Auth natively handles Apple SIWA; no backend change needed |
| **Google Sign-In future** | Low (planning) | Firebase Auth handles it; backend gets same verified token; `google_sign_in` Flutter package needed |
| **UID mapping: Firebase UID vs UUID** | Low | Firebase UIDs are opaque strings (~28 chars); use `TEXT` PK, never assume UUID format |
| **Multi-device / session invalidation** | Medium | Firebase Admin `revokeRefreshTokens(uid)` can force re-auth; deferred to V1 |
| **CORS still `*` in backend** | Low/High | Tighten before production; auth doesn't help if CORS is open |
| **No registration UI** | Low | `createUserWithEmailAndPassword` is one call; can defer registration to later or use Firebase Console for now |

---

## Recommended Workstreams and Implementation Order

```
Phase 5 — Firebase Auth Foundation
│
├── WS-A: Flutter Firebase Auth [~1 day]
│   ├── A1  pubspec: add firebase_auth
│   ├── A2  DI: register FirebaseAuth.instance
│   ├── A3  Domain: AppUser entity + AuthRepository contract
│   ├── A4  Domain: SignIn / SignOut / GetAuthStateChanges use cases
│   ├── A5  Data: FirebaseAuthDataSource + AuthRepositoryImpl + mapper
│   ├── A6  Presentation: AuthState + AuthNotifier + authProvider
│   ├── A7  Presentation: LoginPage (minimal email+password)
│   ├── A8  Router: auth guard (redirect unauthenticated → /login)
│   └── A9  Network: DioClient interceptor → getIdToken() → Bearer header
│
├── WS-B: Backend Firebase Auth [~0.5 day]
│   ├── B1  requirements.txt: firebase-admin, aiosqlite, python-dotenv
│   ├── B2  config.py: FIREBASE_PROJECT_ID, DB_PATH
│   ├── B3  core/firebase_auth.py: verify_firebase_token()
│   ├── B4  core/database.py: init_db(), WAL, UID-keyed schema
│   ├── B5  services/user_service.py: get_or_create_by_uid, preferences CRUD
│   ├── B6  models/user.py: Pydantic models (no password)
│   ├── B7  api/users.py: GET /users/me, GET+PUT /users/me/preferences
│   ├── B8  dependencies.py: get_db, get_user_service, get_current_user
│   └── B9  main.py: lifespan + routers
│
└── WS-C: Integration + Testing [~0.5 day]
    ├── C1  Backend: pytest with mocked verify_firebase_token
    ├── C2  Flutter: unit tests for AuthNotifier
    └── C3  Manual E2E: sign in → home → API call with Bearer → /users/me
```

**Order:** WS-B can start immediately (no Flutter dependency). WS-A A1–A6 can proceed in parallel. WS-A A8–A9 require WS-B to be running to test the full flow.

---

## Approaches

### Option A — Single change: `phase-5-firebase-auth-foundation` (recommended)

All WS-A + WS-B in one deliverable change.

- **Pros:** Complete end-to-end slice; unblocks all future features; one coherent PR
- **Cons:** Wider PR surface (~15 files across two repos)
- **Effort:** Medium (1.5–2 days)

### Option B — Backend first, Flutter second (two changes)

1. `phase-5-firebase-auth-backend` — WS-B only
2. `phase-5-firebase-auth-flutter` — WS-A only

- **Pros:** Smaller PRs; backend can be deployed and tested independently
- **Cons:** Critical path is longer; Flutter auth is blocked
- **Effort:** Same total, more coordination overhead

### Option C — Minimal spike: Flutter sign-in only (no backend)

Sign in with Firebase Auth locally, no backend token verification yet.

- **Pros:** Fastest to first sign-in UI
- **Cons:** API calls remain unauthenticated; backend can't identify users; not production-safe
- **Effort:** Low (0.5 day)

**→ Recommendation: Option A.** The backend work is small (no auth endpoint needed, only a verifier). Delivering the full end-to-end slice in one change is cleaner and more valuable.

---

## Recommendation

**Firebase Auth is the correct choice for Phase 5 and the redesign should happen now.**

Reasons:
1. Firebase is already initialized in the app for 3 flavors — adding `firebase_auth` is additive, not a rework.
2. The backend becomes simpler: no password hashing, no JWT signing, no register/login endpoints — only a token verifier.
3. SQLite still makes sense for user profile + preferences; Firebase Firestore is not needed.
4. Social auth (Google, Apple) becomes free in Phase 6 with zero backend changes.
5. Token lifecycle (refresh, invalidation) is handled by Firebase SDK — no Dio mutex needed for refresh races.
6. The previous `phase-5-backend-foundation` plan is superseded but ~70% of its architecture applies unchanged (SQLite pattern, `app.state.db`, `UserService`, preferences endpoints). Only the auth subsystem is replaced.

---

## Ready for Proposal

**YES.** All decisions are resolved. No blockers. The change can go directly to `propose` → `spec` → `design` → `tasks` → `apply`.
