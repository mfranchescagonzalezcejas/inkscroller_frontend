# Phase 5 — Execution Plan

> **Status:** Historical execution snapshot (Phase 5 planning + implementation reference)
> **Auth baseline:** Firebase Auth (revised from JWT-first — see AD-1 in PRD)
> **Phase 5 foundation:** Implemented in historical sequence below
> **Live status source:** [`docs/PROJECT_STATUS.md`](../PROJECT_STATUS.md)
> **Parent PRD:** [`docs/PRD/phase-5-identity-and-adaptive-reading.md`](phase-5-identity-and-adaptive-reading.md)

This document is the execution-ready companion to the Phase 5 PRD, preserved as a historical snapshot. It captures the workstream breakdown, milestone task checklist, explicit dependency order, and new file targets for both repos at planning/implementation time.

---

## Workstream Overview

| ID | Name | Scope | Status |
|----|------|-------|--------|
| WS-A | Backend Foundation | ~~JWT auth~~ **Firebase token verification** + SQLite + user/prefs API | ✅ Foundation implemented |
| WS-B | Flutter Auth Foundation | Auth module, ~~secure storage~~ **Firebase Auth SDK**, route guard, profile tab | ✅ Foundation implemented (profile tab M3) |
| WS-C | Adaptive Reader Foundation | Dual-mode reader, preference chain, tests | Not started |
| WS-D | User Profile & Preferences | Domain entities, preferences feature, profile page | Not started |
| WS-E | Cloud Sync Expansion | Progress, favorites, preference cloud sync (V1) | Not started |

> ⚠️ **WS-A auth strategy revised:** The JWT-first plan (M1: `POST /auth/register`, `POST /auth/login`, `POST /auth/refresh`) is **superseded**. Firebase Auth is the identity provider; the backend verifies Firebase ID tokens and no longer handles password storage or JWT issuance.

---

## Milestone Task Checklist

### M0 — Sprint 1 Planning Closure

- [x] **T0.1** Update `docs/PRD/phase-5-identity-and-adaptive-reading.md` with WS-A..WS-E, M0..M5, MVP/V1/Later table, and critical-path note. *(Completed in the Phase 5 deep-planning pass.)*
- [x] **T0.2** Update `docs/PRD.md` Phase 5 section to reflect planning closure + workstream structure.
- [x] **T0.3** Update Obsidian Phase 5 PRD, Sprint 1 Overview, and TASK-005/002/003/004 notes with sequencing and workstream assignments.
- [x] **T0.4** Normalize Sprint 1 tasks: TASK-005→WS-A, TASK-002→WS-A/B, TASK-003→WS-D, TASK-004→WS-C; mark blockers explicitly.

### M1 — Backend Foundation (WS-A) — ✅ Firebase Auth variant implemented

> **Note:** Items A1/A3/A5 replaced by Firebase Auth variant below.

- [x] **A1-rev** Firebase Auth baseline: `requirements.txt` + `.env.example` + `app/core/config.py` updated for `firebase-admin`, `aiosqlite`, `python-dotenv`, `FIREBASE_PROJECT_ID`, `DB_PATH`.
- ~~[ ] **A1** Define contracts: JWT+SQLite ADR~~ — *Superseded by Firebase Auth*
- [x] **A2** Created `app/core/database.py` — SQLite via `aiosqlite`, WAL mode, `users` + `reading_preferences` tables.
- ~~[ ] **A3** `app/core/auth.py` — JWT / password hashing~~ — *Superseded by Firebase Auth*
- [x] **A3-rev** Created `app/core/firebase_auth.py` — `verify_firebase_token()` helper + `init_firebase_admin()`.
- [x] **A4** Created `app/models/user.py` — `UserProfile`, `ReadingPreferences`, `UpdatePreferencesRequest`.
- ~~[ ] **A5** `app/api/auth.py` — register/login/refresh router~~ — *Superseded by Firebase Auth*
- [x] **A6** Created `app/api/users.py` — `GET /users/me`, `GET /users/me/preferences`, `PUT /users/me/preferences`.
- [x] **A7** Created `app/services/user_service.py` — get-or-create by Firebase UID + preferences CRUD.
- [x] **A7b** Extended `app/core/dependencies.py` — `get_db()`, `get_user_service()`, `get_current_user()`.
- [x] **A7c** Extended `app/core/exceptions.py` — `AuthError` + `PreferencesValidationError` handlers.
- [x] **A8** Updated `main.py` — Firebase Admin init + DB init in lifespan, includes users router.
- [x] **A8b** Created `tests/test_users_auth.py` — user/preferences tests with in-memory SQLite + fake auth.

### M2 — Flutter Auth Foundation (WS-B) — ✅ Foundation implemented (profile tab deferred to M3)

> **Note:** B1/B3 replaced by Firebase Auth variant. Profile tab (B8) deferred to M3.

- ~~[ ] **B1** Add `flutter_secure_storage`~~ — *Not needed; Firebase Auth manages sessions natively*
- [x] **B1-rev** Added `firebase_auth ^5.5.2` to `pubspec.yaml`.
- [x] **B2** Created `lib/features/auth/` full clean-architecture module: domain entities, repository contract, use cases, Firebase data source, repository impl.
- ~~[ ] **B3** `auth_local_ds.dart` — SecureStorage wrapper~~ — *Not needed with Firebase Auth*
- [x] **B4** Created `lib/features/auth/presentation/providers/` — `auth_state.dart`, `auth_notifier.dart`, `auth_provider.dart`.
- [x] **B5** Created `lib/features/auth/presentation/pages/login_page.dart` + `register_page.dart`.
- [x] **B6** Updated `lib/core/di/injection.dart` — `FirebaseAuth.instance`, `FirebaseAuthDataSource`, `AuthRepository`, all auth use cases registered as `LazySingleton`.
- [x] **B7** Updated `lib/core/router/app_router.dart` — `/login`, `/register` routes; GoRouter redirect guard (auth-aware via `FirebaseAuth.authStateChanges`).
- [ ] **B8** Update `lib/features/navigation/presentation/pages/main_scaffold.dart` — Profile tab *(deferred to M3)*

### M3 — Preferences + Adaptive Reader (WS-C + WS-D)

- [ ] **D1** Define domain entities: `lib/features/preferences/domain/entities/reading_preferences.dart`, `reader_mode.dart` (enum), `per_title_override.dart`.
- [ ] **D2** Create `lib/features/preferences/` full clean-architecture module.
- [ ] **D3** Add DI registrations — `PreferencesLocalDS`, `PreferencesRepository`, `GetReadingPreferences`, `SetReadingPreferences`, `GetPerTitleOverride`, `SetPerTitleOverride`.
- [ ] **C1** Create `lib/features/preferences/domain/services/reader_mode_resolver.dart` — 4-level preference chain: per-title override → global pref → auto-detect → vertical default.
- [ ] **C2** Extract `lib/features/library/presentation/widgets/vertical_reader_view.dart` from existing `ReaderPage` logic.
- [ ] **C3** Create `lib/features/library/presentation/widgets/paged_reader_view.dart` — `PageView`-based paging reader.
- [ ] **C4** Update `lib/features/library/presentation/pages/reader_page.dart` — orchestrate mode resolution, delegate to `VerticalReaderView` or `PagedReaderView`.
- [ ] **C5** Update `lib/features/library/presentation/providers/reader/reader_state.dart` — add `readerMode` field. Update `lib/features/library/presentation/providers/reader/reader_notifier.dart` — add `setReaderMode()`.
- [ ] **C6** Add mode toggle to reader AppBar action.
- [ ] **C7** Add DI for `ReaderModeResolver`.
- [ ] **D4** Create `lib/features/profile/presentation/pages/profile_page.dart` + `profile_card.dart` + `preferences_section.dart`.

### M4 — MVP Integration & Stabilization

- [ ] **I1** Connect Flutter preferences module to backend: `GET/PUT /users/me/preferences`.
- [ ] **I2** Validate full auth → restore session → profile → preferences → reader mode flow.
- [ ] **I3** Add tests: auth notifier, route guard, DI resolution, reader mode switching, backend auth/preferences integration.
- [ ] **I4** Profile page polish: sign-in/sign-out state, preferences UI, display name.

### M5 — V1 Cloud Sync (WS-E)

- [ ] **E1** Backend: progress endpoints + Flutter `ReadingProgress` feature.
- [ ] **E2** Backend: favorites endpoints + Flutter `Favorite` feature.
- [ ] **E3** Preference cloud sync + conflict resolution rules; local-first fallback preserved.

---

## Dependency Map

```
Sprint 1 tasks:
  TASK-001 ✅ PRD refinement
  TASK-005 → backend gap audit → unblocks TASK-002
  TASK-002 → auth decision (→ AD-1: Firebase Auth) → unblocks TASK-003, A1-rev
  TASK-003 → UserProfile domain model (→ AD-4) → unblocks TASK-004, D1
  TASK-004 → Adaptive reader strategy (→ AD-5) → unblocks C1

Implementation dependency chain:
  A1 → A2 → A3/A4 → A5/A6/A7 → A8
  B1 → B2/B3 → B4/B5 → B6/B7/B8
  D1 → D2 → D3
  C1 (needs D1) → C2/C3 → C4/C5/C6/C7
  A8 + B8 + D3 + C7 → I1 → I2/I3/I4
  I4 stable → E1/E2/E3
```

---

## New File Targets

### Backend (`Inkscroller_backend/`) — Phase 5 foundation complete

| File | Purpose | Status |
|------|---------|--------|
| `requirements.txt` | Added `firebase-admin`, `aiosqlite`, `python-dotenv` | ✅ |
| `.env.example` | Environment variable reference with Firebase + DB config | ✅ |
| `app/core/config.py` | Added `firebase_project_id`, `db_path`, `python-dotenv` load | ✅ |
| `app/core/database.py` | SQLite setup via `aiosqlite`, WAL mode, table init | ✅ |
| `app/core/firebase_auth.py` | Firebase Admin token verification helper | ✅ |
| `app/models/user.py` | `UserProfile`, `ReadingPreferences`, `UpdatePreferencesRequest` | ✅ |
| `app/api/users.py` | User profile + preferences router | ✅ |
| `app/services/user_service.py` | Get-or-create by Firebase UID + preferences CRUD | ✅ |
| `app/core/dependencies.py` | Extended with `get_db`, `get_user_service`, `get_current_user` | ✅ |
| `app/core/exceptions.py` | Extended with `AuthError` + `PreferencesValidationError` | ✅ |
| `main.py` | Firebase Admin + DB init in lifespan, users router included | ✅ |
| `tests/test_users_auth.py` | Auth/user/preferences endpoint tests | ✅ |
| ~~`app/core/auth.py`~~ | ~~JWT/passlib auth~~ — **Superseded by Firebase Auth** | ❌ Not created |
| ~~`app/api/auth.py`~~ | ~~register/login/refresh router~~ — **Superseded by Firebase Auth** | ❌ Not created |

### Flutter (`lib/`) — Phase 5 foundation complete

| Path | Purpose | Status |
|------|---------|--------|
| `features/auth/domain/entities/app_user.dart` | Domain entity — pure Dart, no Firebase | ✅ |
| `features/auth/domain/repositories/auth_repository.dart` | Repository contract | ✅ |
| `features/auth/domain/usecases/*.dart` | SignIn, SignUp, SignOut, GetAuthState, GetIdToken | ✅ |
| `features/auth/data/datasources/firebase_auth_data_source.dart` | Firebase Auth wrapper | ✅ |
| `features/auth/data/repositories/auth_repository_impl.dart` | Repository implementation | ✅ |
| `features/auth/presentation/providers/auth_state.dart` | Immutable state with `copyWith` | ✅ |
| `features/auth/presentation/providers/auth_notifier.dart` | `StateNotifier` with sign-in/up/out | ✅ |
| `features/auth/presentation/providers/auth_provider.dart` | Riverpod provider bridging get_it | ✅ |
| `features/auth/presentation/pages/login_page.dart` | Email/password sign-in page | ✅ |
| `features/auth/presentation/pages/register_page.dart` | Email/password registration page | ✅ |
| `core/di/injection.dart` | Auth DI registrations added | ✅ |
| `core/router/app_router.dart` | `/login`, `/register`, redirect guard | ✅ |
| `core/network/dio_client.dart` | Bearer token interceptor for protected paths | ✅ |
| `core/constants/api_endpoints.dart` | `usersMe`, `usersMePreferences` constants | ✅ |
| `features/preferences/` | Clean-arch preferences feature module | M3 |
| `features/profile/presentation/` | Profile page + widgets | M3 |
| `features/navigation/presentation/pages/main_scaffold.dart` | Profile tab (4th tab) | M3 |
| `features/library/presentation/pages/reader_page.dart` | Dual-mode orchestration | M3 |

---

## Sprint 1 Status (closed)

| Task | Workstream | Status | Notes |
|------|-----------|--------|-------|
| TASK-001 Refine PRD Phase 5 | M0 | ✅ Done | — |
| TASK-005 Map Backend Integration Points | WS-A | ✅ Done | Covered during Phase 5 foundation implementation |
| TASK-002 Compare Auth Approaches | WS-A / WS-B | ✅ Done | **Firebase Auth chosen** — AD-1 revised |
| TASK-003 Define UserProfile Domain Model | WS-D | ✅ Done | `AppUser` entity + `UserProfile`/`ReadingPreferences` backend models |
| TASK-004 Define Adaptive Reader Mode Strategy | WS-C | 🔲 M3 | Planned — not in foundation scope |

## Sprint 2 Status (in progress)

| Task | Scope | Status |
|------|-------|--------|
| Phase 5 Firebase Auth foundation — backend | M1 | ✅ Done |
| Phase 5 Firebase Auth foundation — Flutter | M2 | ✅ Done |
| Profile tab (4th nav) | M2/M3 | 🔲 Next |
| Adaptive reader (dual-mode) | M3 | 🔲 Next |
| Preferences feature module | M3 | 🔲 Next |
