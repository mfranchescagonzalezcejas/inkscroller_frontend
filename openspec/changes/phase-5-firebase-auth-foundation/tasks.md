# Tasks: Firebase-auth-first foundation

## Phase 1: Backend foundation
- [x] 1.1 Update `../Inkscroller_backend/requirements.txt`, `.env.example`, and `app/core/config.py` for `firebase-admin`, `aiosqlite`, `python-dotenv`, `FIREBASE_PROJECT_ID`, `DB_PATH`, and service-account/env loading.
- [x] 1.2 Create `../Inkscroller_backend/app/core/database.py` with shared `aiosqlite` init, WAL mode, and DDL for `users(firebase_uid ...)` and `reading_preferences(firebase_uid ...)`.
- [x] 1.3 Create `../Inkscroller_backend/app/core/firebase_auth.py` with `verify_firebase_token()` returning UID/email/display name and explicit auth failures.
- [x] 1.4 Create `../Inkscroller_backend/app/models/user.py` for profile + preferences request/response models keyed by Firebase UID.

## Phase 2: Backend services and routes
- [x] 2.1 Create `../Inkscroller_backend/app/services/user_service.py` for get-or-create user bootstrap, default preferences, and preferences read/update.
- [x] 2.2 Extend `../Inkscroller_backend/app/core/dependencies.py` with `get_db()`, `get_user_service()`, and `get_current_user()` that verifies Bearer tokens.
- [x] 2.3 Extend `../Inkscroller_backend/app/core/exceptions.py` for auth-safe 401/422 responses using the existing `_error_response()` shape.
- [x] 2.4 Create `../Inkscroller_backend/app/api/users.py` with `GET /users/me`, `GET /users/me/preferences`, and `PUT /users/me/preferences`.
- [x] 2.5 Update `../Inkscroller_backend/main.py` to init DB + Firebase Admin in lifespan, store `app.state.db`, and include the users router.

## Phase 3: Flutter auth module and wiring
- [x] 3.1 Add `firebase_auth` to `pubspec.yaml`; keep Firebase bootstrap through `lib/main_common.dart` and flavor entry points unchanged.
- [x] 3.2 Create `lib/features/auth/` clean-architecture slice: `domain/entities/app_user.dart`, repository contract, use cases, `data/datasources/firebase_auth_data_source.dart`, and repository impl.
- [x] 3.3 Create auth presentation files under `lib/features/auth/presentation/` for immutable auth state, `AuthNotifier`, provider, and minimal `login_page.dart` / registration surface.
- [x] 3.4 Update `lib/core/di/injection.dart` to register `FirebaseAuth.instance` and all auth dependencies as `LazySingleton`.

## Phase 4: Flutter route/session/network integration
- [x] 4.1 Update `lib/core/router/app_router.dart` to expose auth routes and redirect unauthenticated users away from protected shells/details while restoring existing sessions.
- [x] 4.2 Update `lib/core/network/dio_client.dart` with an interceptor that calls the auth layer for `getIdToken()` and attaches `Authorization: Bearer <token>` only for protected API paths.
- [ ] 4.3 Update `lib/features/navigation/presentation/pages/main_scaffold.dart` and add a minimal profile/auth entry so authenticated state has a reachable post-login destination. *(Deferred to M3)*

## Phase 5: Verification and doc/state cleanup
- [x] 5.1 Add Flutter tests for `AuthNotifier`, router redirect behavior, and Dio token propagation under `test/features/auth/`, `test/core/router/`, and `test/core/network/`.
- [x] 5.2 Add backend tests in `../Inkscroller_backend/tests/test_users_auth.py` covering valid token, missing/invalid token, bootstrap-on-first-request, default preferences, and update persistence.
- [x] 5.3 Update `../Inkscroller_backend/.github/workflows/ci.yml` for the new backend test path and emulator/mock verification strategy; do not add build steps.
- [x] 5.4 Update `docs/PRD/phase-5-identity-and-adaptive-reading.md`, `docs/PRD/phase-5-execution-plan.md`, and Obsidian vault notes so Firebase Auth is canonical and JWT-first is marked superseded.

## Critical path
1.1→1.2→1.3→1.4→2.1→2.2→2.4→2.5→3.1→3.2→3.4→4.1/4.2→5.1/5.2→5.4
