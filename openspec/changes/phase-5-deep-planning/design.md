# Design: Phase 5 — Identity & Adaptive Reading (Execution-Ready)

> **Historical note (2026-04-04):** This execution-ready design was written before the final auth decision changed.
> The reader-mode and profile planning remain relevant, but the auth sections that assume backend-owned JWTs are **superseded**.
> Current baseline: Firebase Auth for identity + backend verification of Firebase ID tokens.

## Technical Approach

Phase 5 adds user identity, reading preferences, and adaptive reader modes to an app that is currently anonymous and vertical-scroll-only. This design resolves all 6 blocking architectural decisions, establishes concrete Flutter feature modules and backend endpoints, and sequences delivery so each milestone has clean dependencies.

## Architecture Decisions

### AD-1: Auth Strategy

| Option | Tradeoffs | Verdict |
|--------|-----------|---------|
| Firebase Auth | Turnkey signup/social-login, free tier generous, Flutter SDK mature, no backend token infra needed, BUT vendor lock-in, complicates self-hosting, Firestore coupling temptation | **REJECTED** |
| Backend-owned JWT (FastAPI + `python-jose`) | Full control, no vendor lock-in, fits existing stateless proxy pattern, Flutter talks to ONE backend, BUT requires writing auth endpoints and password hashing | **CHOSEN** |

**Rationale**: Backend is already the Flutter app's single gateway. JWT auth keeps architecture clean: one base URL, one Dio client, one token interceptor. Firebase would create a second auth plane the backend still has to verify.

### AD-2: Backend Persistence / Storage

| Option | Tradeoffs | Verdict |
|--------|-----------|---------|
| PostgreSQL | Battle-tested, relational, great for user data, BUT heavier ops for solo dev | CONSIDERED |
| SQLite (via `aiosqlite`) | Zero-infra, single-file, async driver exists, sufficient for single-instance MVP, easy Postgres migration later | **CHOSEN** |

**Rationale**: Backend currently has ZERO persistence. SQLite is minimum viable step: no Docker, no cloud DB. Schema is small. Migration to Postgres is a schema export if needed.

### AD-3: Secure Token Storage (Flutter)

| Option | Tradeoffs | Verdict |
|--------|-----------|---------|
| `shared_preferences` | Already in pubspec, BUT plaintext on disk | REJECTED |
| `flutter_secure_storage` | OS keychain/keystore backed, encrypted at rest | **CHOSEN** |

### AD-4: UserProfile vs Progress/Favorites Boundary

**Choice**: Three separate domain entities — `UserProfile`, `ReadingProgress`, `Favorite`.

**Rationale**: Avoids contract bloat. MVP ships `UserProfile` + `ReadingPreferences` without touching progress/favorites.

### AD-5: Adaptive Reader Architecture

**Choice**: Strategy pattern — `ReaderPage` delegates to `VerticalReaderView` or `PagedReaderView` selected by `ReaderModeResolver`.

**Rationale**: Current `ReaderPage` hardcodes `ListView.builder`. Strategy pattern lets both modes share state pipeline (loading, pre-cache, error) but differ only in layout. `PageView` handles paging natively.

### AD-6: Profile/Navigation Entry Point

**Choice**: Add 4th bottom tab "Profile" (auth state, preferences). Settings tab stays for app-level config.

**Rationale**: Phase 6 PRD already assumes Profile tab exists. Adding now avoids navigation restructure later.

## Data Flow

### Auth Flow (MVP)
```
SignInPage ──POST /auth/login──► Backend (bcrypt verify → JWT)
     │                                    │
     ▼                                    ▼
SecureStorage.write(tokens)         200 {access_token, refresh_token}
     │
     ▼
DioInterceptor attaches Bearer ──► all subsequent requests
     │
     ▼
AuthNotifier.state = authenticated(UserProfile)
     │
     ▼
GoRouter redirect: unauthenticated → /sign-in
```

### Preference Resolution Chain
```
ReaderModeResolver.resolve(mangaId)
  1. PerTitleOverrideRepo.get(mangaId)  → ReaderMode?
  2. ReadingPreferencesRepo.getGlobal() → ReaderMode?
  3. AutoDetect(chapter metadata)       → ReaderMode?
  4. const ReaderMode.vertical          (system default)
  → First non-null wins
```

## Domain Design

```dart
enum ReaderMode { vertical, paged }

class UserProfile {
  final String id;
  final String email;
  final String? displayName;
  final DateTime createdAt;
}

class ReadingPreferences {
  final ReaderMode defaultReaderMode;
  final String defaultLanguage;
}

class PerTitleOverride {
  final String mangaId;
  final ReaderMode readerMode;
}
```

## File Changes

### New Flutter Feature Modules

| Path | Action | Description |
|------|--------|-------------|
| `lib/features/auth/` | Create | Full clean-arch auth feature (data/domain/presentation) |
| `lib/features/preferences/` | Create | Reading preferences feature (local-first) |
| `lib/features/profile/` | Create | Profile tab page + widgets |

### Modified Flutter Files

| File | Action | Description |
|------|--------|-------------|
| `lib/core/di/injection.dart` | Modify | Add auth, preferences, resolver DI registrations |
| `lib/core/router/app_router.dart` | Modify | Add Profile tab branch, sign-in/sign-up routes, redirect guard |
| `lib/features/navigation/presentation/pages/main_scaffold.dart` | Modify | Add 4th tab (Profile) |
| `lib/features/library/presentation/pages/reader_page.dart` | Modify | Extract to strategy pattern with mode resolver |
| `lib/features/library/presentation/providers/reader/reader_state.dart` | Modify | Add `readerMode` field |
| `pubspec.yaml` | Modify | Add `flutter_secure_storage` dependency |

### New Backend Files

| Path | Action | Description |
|------|--------|-------------|
| `app/core/database.py` | Create | SQLite setup via aiosqlite |
| `app/core/auth.py` | Create | JWT creation/verification, password hashing |
| `app/models/user.py` | Create | User + Preferences Pydantic models |
| `app/api/auth.py` | Create | Auth router (register, login, refresh) |
| `app/api/users.py` | Create | User profile + preferences router |
| `app/services/user_service.py` | Create | User CRUD + preference operations |

### Modified Backend Files

| File | Action | Description |
|------|--------|-------------|
| `main.py` | Modify | Register auth + users routers, init database on lifespan |
| `app/core/config.py` | Modify | Add JWT secret, DB path, token expiry settings |
| `requirements.txt` | Modify | Add python-jose, passlib, bcrypt, aiosqlite |

## Backend API Surface

### MVP Endpoints
| Method | Path | Purpose |
|--------|------|---------|
| POST | `/auth/register` | Create account |
| POST | `/auth/login` | Authenticate → JWT pair |
| POST | `/auth/refresh` | Refresh access token |
| GET | `/users/me` | Get current user profile |
| GET | `/users/me/preferences` | Get reading preferences |
| PUT | `/users/me/preferences` | Update reading preferences |

### V1 Endpoints (planned, not MVP)
| Method | Path | Purpose |
|--------|------|---------|
| GET/PUT | `/users/me/progress[/{manga_id}]` | Reading progress CRUD |
| GET/POST/DELETE | `/users/me/favorites[/{manga_id}]` | Favorites CRUD |

## Testing Strategy

| Layer | What | Approach |
|-------|------|----------|
| Unit | Entities, use cases, ReaderModeResolver | Pure Dart + mocktail |
| Unit | Notifiers (Auth, Preferences, Reader) | Mocktail mocks for use cases |
| Unit | Backend auth/user services | pytest + in-memory SQLite |
| Integration | Auth flow end-to-end | pytest + httpx TestClient |
| Widget | Reader mode switching | WidgetTester + mocked provider |

## Delivery Milestones

| Milestone | Scope | Dependencies |
|-----------|-------|--------------|
| M0 — Planning Closure | This design + task breakdown + docs sync | None |
| M1 — Backend Foundation | SQLite + auth + user/preferences endpoints | M0 |
| M2 — Flutter Auth | Auth feature module + secure storage + router guard | M1 |
| M3 — Preferences + Reader | Preferences module + ReaderModeResolver + dual-mode reader | M1 (backend prefs endpoint) |
| M4 — MVP Stabilization | Connect prefs to backend, validate full flow | M2 + M3 |
| M5 — V1 Cloud Sync | Progress + favorites + preference cloud sync | M4 |

## Migration / Rollout

No data migration needed — zero existing user data. Backend gets fresh SQLite database. Flutter gets new feature modules alongside existing ones. Anonymous reading continues until auth guard is enabled.

## Open Questions

None blocking. All 6 pre-implementation decisions are resolved.
