# Exploration: phase-5-auth-decision-finalization

> **Historical note (2026-04-04):** This exploration is retained as decision history.
> Its JWT-first recommendation is **not** the current product baseline anymore.
> Final active direction for Phase 5: Firebase Auth on Flutter, backend verification of Firebase ID tokens, no backend-issued `/auth/*` JWT flow.

> **Phase:** Explore
> **Change:** phase-5-auth-decision-finalization
> **Date:** 2026-04-03
> **Status:** Complete — Ready for Proposal

---

## Current State

### Flutter app — Firebase reality check

Firebase is present but scoped to three non-auth purposes:
- `firebase_core: ^4.3.0` — bootstrap / SDK init in `mainCommon()`
- `firebase_analytics: ^12.1.1` — `AnalyticsObserver` (screen views) + one user-property (flavor)
- Firebase App Distribution — CI scripts only (not a runtime SDK)

**No `firebase_auth` is in `pubspec.yaml`.** Firebase's runtime role is 100% observability + distribution. Identity is completely untouched.

Three separate Firebase projects (dev / staging / pro) already exist, all configured via `firebase_options.dart` → `FirebaseOptionsSelector`. If `firebase_auth` were added it would inherit this multi-project setup automatically — no Firebase console work needed.

### Flutter architecture — what auth would land in

| Area | Current state |
|------|--------------|
| DI (`injection.dart`) | All lazy singletons via get_it; no auth-related registrations |
| Network (`DioClient`) | Bare `Dio`, no interceptors. One file, 27 lines. |
| Token storage | `flutter_secure_storage` — **NOT in pubspec.yaml**. Must be added. |
| Router | `app_router.dart` — no redirect guard. Must be added regardless of auth approach. |
| Profile tab | Does not exist. AD-6 specifies it as M2 deliverable. |
| User entities | None. `UserProfile`, `ReadingPreferences` designed (AD-4) but not implemented. |
| `auth` feature module | Does not exist. |

### Backend — what auth would land in

The backend is a pure stateless proxy — zero auth, zero persistence, zero user model:

```
requirements.txt (pinned):
fastapi==0.128.0 | httpx==0.28.1 | pydantic==2.12.5 | uvicorn==0.40.0
starlette==0.50.0 | pydantic_core==2.41.5 | (transitive)

NOT present: python-jose, passlib, aiosqlite, bcrypt, pytest, pytest-asyncio
```

The `phase-5-backend-foundation` change already has a complete **exploration**, **design**, and **tasks** artifact for backend-owned JWT. Switching to Firebase Auth would require discarding all three.

---

## Approaches

### Option A — Backend-owned JWT ✅ RECOMMENDED

**Backend changes:**

| Component | Action |
|-----------|--------|
| `python-jose[cryptography]` + `passlib[bcrypt]` | JWT signing + password hashing |
| `aiosqlite` + `python-dotenv` | Async SQLite + `.env` loading |
| `app/core/database.py` | SQLite init, WAL mode, schema DDL |
| `app/core/auth.py` | `hash_password`, `verify_password`, `create_token`, `decode_token` |
| `app/models/user.py` | `UserCreate`, `UserResponse`, `UserInDB`, `ReadingPreferencesModel` |
| `app/services/user_service.py` | CRUD for users + preferences |
| `app/api/auth.py` | `POST /auth/register`, `POST /auth/login`, `POST /auth/refresh` |
| `app/api/users.py` | `GET /users/me`, `GET/PUT /users/me/preferences` |
| `app/core/config.py` | Add `JWT_SECRET_KEY` (required), `DB_PATH`, token TTLs |
| `app/core/dependencies.py` | Add `get_current_user` (decode Bearer → `UserInDB`) |

SQLite schema:
```sql
users (id TEXT PK, email TEXT UNIQUE, display_name TEXT, hashed_password TEXT, created_at TEXT)
reading_preferences (user_id TEXT PK FK, default_reader_mode TEXT, default_language TEXT, updated_at TEXT)
```

Token design: Access JWT HS256 (15 min) + Refresh JWT HS256 (30 days), both stateless.

**Flutter changes:**

- Add `flutter_secure_storage` — stores access + refresh tokens
- Add `AuthInterceptor` to `DioClient` — attaches Bearer, handles 401 → refresh
- Add `auth` feature module (domain: `UserProfile`, `ReadingPreferences` entities; data: `AuthRepository`; presentation: login/register UI)
- Add auth-aware redirect in `app_router.dart`
- Add Profile tab (M2)

**Pros:**
- Self-contained — no external dependency for token validation
- Fully testable locally: `JWT_SECRET_KEY=test-secret` in CI, no emulator
- Zero impact on existing Firebase setup (analytics/core untouched)
- All SDD artifacts already written — ready to execute immediately
- Single identity plane: one backend, one token, one interceptor
- Total control over JWT payload claims

**Cons:**
- Must implement register/login/refresh endpoints (but these are well-understood and already designed)
- Must manage `JWT_SECRET_KEY` secret per environment

**Effort:** Medium (already fully designed — implementation only)

---

### Option B — Firebase Auth (full)

**Backend changes:**

- `firebase-admin` Python SDK + Google service account JSON or ADC
- SQLite still needed (Firebase does NOT own app data — preferences, progress, etc.)
- `users` table: `firebase_uid` replaces `hashed_password`; no `/auth/register` or `/auth/login`
- Token validation: `firebase_admin.auth.verify_id_token(token)` — requires network call to Google JWKS
- "First-login upsert": when Flutter signs in via Firebase, the backend must auto-create a local user record on the first `/users/me` call

**Flutter changes:**

- Add `firebase_auth` package — inherits existing 3 Firebase projects
- `FirebaseAuth.instance.signInWithEmailAndPassword()` for email/password
- `FirebaseAuth.instance.authStateChanges()` stream for session state
- Dio interceptor calls `await currentUser?.getIdToken()` per request (Firebase SDK auto-refreshes)
- `flutter_secure_storage` still useful for caching token locally (though Firebase SDK caches internally)

**Pros:**
- Firebase SDK handles token refresh automatically
- Social login (Google, Apple, etc.) available without OAuth implementation — relevant if social login is planned
- No custom register/login endpoints on the backend

**Cons:**
- Backend complexity INCREASES: firebase-admin + Google credential + JWKS validation + first-login upsert logic
- Backend has external runtime dependency on Google servers for token validation
- All existing SDD artifacts (`phase-5-backend-foundation`: design + tasks) must be discarded and rewritten
- Test experience degrades: CI needs Firebase emulator or a live Firebase project — no simple `JWT_SECRET_KEY=test` solution
- Social login (Firebase's main value proposition) is NOT in Phase 5 scope
- Two user-creation flows to synchronize (Firebase Auth + local DB)
- Firebase owns identity → vendor lock-in

**Effort:** High (requires discarding all existing SDD artifacts, new backend design)

---

### Option C — Hybrid / Double-plane (Firebase Auth + backend JWT)

Flutter logs in via Firebase → gets Firebase idToken → sends to backend → backend validates via Firebase Admin → backend issues its own JWT → Flutter uses backend JWT.

**Verdict: Rejected.** This combines the full complexity of both options with no unique benefit:
- Two auth SDKs in Flutter
- Two token systems in the backend (firebase-admin + python-jose)
- Extra network round-trip on every session start
- The only use case where this makes sense (need Firebase social login + full JWT payload control) is not in Phase 5 scope.

---

## Option Comparison Matrix

| Criterion | Backend JWT | Firebase Auth | Hybrid |
|-----------|-------------|---------------|--------|
| Social login (Phase 5) | ❌ Not needed | ✅ Native | ✅ Native |
| Backend complexity | Low | Medium-High | Very High |
| Backend external runtime dependency | None | Google JWKS | Google JWKS + python-jose |
| Flutter interceptor complexity | Medium (custom) | Low (SDK auto-refresh) | High (both) |
| Local testability | ✅ Full | ❌ Emulator needed | ❌ Emulator needed |
| Existing SDD artifacts reusable | ✅ 100% | ❌ Discard all | ❌ Discard all |
| JWT payload control | ✅ Full | Limited (Custom Claims) | ✅ Full |
| Vendor lock-in | None | Firebase/Google | Firebase/Google |
| First-login upsert complexity | None | Present | Present |
| flutter_secure_storage needed | Yes | Optional | Yes |
| firebase_auth package needed | No | Yes | Yes |
| Path to social login later | Medium (OAuth impl) | Trivial | Trivial |

---

## Recommendation

**Option A — Backend-owned JWT.**

### Why

1. **Firebase Auth's primary advantage does not apply.** Email + password only in Phase 5. Social login is a Phase 6+ concern — and it is explicitly absent from the PRD roadmap for Phase 5.

2. **All existing SDD work is reusable.** The `phase-5-backend-foundation` exploration, design, and tasks are complete and execution-ready. Switching to Firebase Auth requires discarding and rewriting all three.

3. **Backend is simpler, not more complex.** Firebase Auth does not eliminate backend work — it changes it. The backend still needs SQLite (for app data) and still needs `/users/me` + preferences endpoints. It additionally gains: firebase-admin dependency, Google credential management, JWKS validation, and first-login upsert complexity. Backend JWT eliminates all of these.

4. **Test experience stays clean.** `JWT_SECRET_KEY=test-secret` in CI — no Firebase emulator, no live project dependency.

5. **Firebase Auth can be added later without significant pain.** When social login becomes a real requirement (Phase 6+), `firebase_auth` can be introduced. The migration path is well-documented: add `firebase_uid` as a nullable column to the users table, add a social login code path in Flutter, add firebase-admin validation to the backend. The existing user model and preferences data remain intact.

6. **Single identity plane.** One backend, one token, one Dio interceptor. The architecture stays coherent.

### Impact on prior planning

**Nothing changes.** AD-1 should now be formally **closed** (not reopened). The decision is: **Backend-owned JWT (python-jose + passlib + SQLite)**. All existing `phase-5-backend-foundation` artifacts are valid and execution can proceed.

The Obsidian vault doc `Phase 5 Architecture Decisions.md` — AD-1 — should be updated from `🟡 Reopened` to `✅ Closed — Backend JWT confirmed`.

---

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Social login added to Phase 5 scope | High — would invalidate this recommendation | Confirm social login is out of scope before closing AD-1 |
| `JWT_SECRET_KEY` rotation invalidates all sessions | Medium | Document rotation procedure; V1 can add refresh token revocation table |
| Token refresh race condition (Flutter) | Medium | MVP: simple serial refresh in interceptor; V1: Dio interceptor mutex |
| SQLite single-writer under multiple Uvicorn workers | Low (MVP is single-worker) | WAL mode handles it; note for future multi-worker deployment |
| Firebase emulator not needed | None | Confirmed — backend JWT has no Firebase emulator dependency |

---

## Ready for Proposal

**YES.**

- AD-1 should be closed with Backend JWT as the final decision
- `phase-5-backend-foundation` SDD artifacts are valid and ready to execute
- No re-design needed
- The orchestrator should communicate to the user: "The auth decision is Backend JWT. We can now close AD-1 and proceed to implement `phase-5-backend-foundation`."
