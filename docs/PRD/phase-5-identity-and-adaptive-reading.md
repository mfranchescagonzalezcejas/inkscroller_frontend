# Phase 5 — Identity & Adaptive Reading

> **Document status:** Historical baseline / planning reference (not live sprint tracking)
> **Auth baseline:** Firebase Auth (email/password MVP) — **AD-1 superseded** (see below)
> **Live implementation status:** see [`docs/PROJECT_STATUS.md`](../PROJECT_STATUS.md)
> **Execution snapshot:** see `phase-5-execution-plan.md`

## Goal

Make InkScroller user-aware and adapt the reading experience to both user preferences and content format without over-coupling the reader to backend delivery.

## Why This Phase Exists

- The app already has a solid browsing and reading foundation (Phase 4 complete).
- The next product step is continuity: the app should know who the user is, how they prefer to read, and eventually where they left off.
- This phase focuses on product behavior and account-aware reading, not visual redesign.

---

## MVP / V1 / Later Scope

| Capability | Scope |
|------------|-------|
| User auth foundation (sign in, restore session, sign out) | **MVP** |
| `UserProfile` domain entity + `ReadingPreferences` | **MVP** |
| Adaptive reader (paging + vertical) with preference chain | **MVP** |
| Local-first persistence for reader prefs + per-title overrides | **MVP** |
| Profile tab (4th bottom nav tab) | **MVP** |
| Firebase Auth email/password integration (Flutter + backend token verification) | **MVP — ✅ Implemented** |
| Backend `/users/me` + `/users/me/preferences` (CRUD, SQLite-backed) | **MVP — ✅ Implemented** |
| Backend auth endpoints (register, login, refresh) via backend-owned JWT | ~~MVP~~ **Superseded by Firebase Auth** |
| Cloud reading progress sync | **V1** |
| Cloud favorites | **V1** |
| Preference sync to account (local-first → cloud-backed) | **V1** |
| Smarter format auto-detection | **V1** |
| External reader fallback | **Later** |
| Cross-device "continue reading" polish | **Later** |
| More advanced per-title behavior rules | **Later** |

---

## Workstreams

Phase 5 is organized into five parallel execution tracks. Cloud sync (WS-E) is blocked until the other tracks deliver MVP.

| ID | Workstream | Purpose | Scope |
|----|-----------|---------|-------|
| **WS-A** | Backend Foundation | ~~JWT auth~~ **Firebase token verification** + SQLite + user/preferences API — ✅ Foundation implemented | MVP |
| **WS-B** | Flutter Auth Foundation | `auth` feature module, ~~`flutter_secure_storage`~~ **Firebase Auth SDK**, DIO interceptor, session restore, route guard, Profile tab nav — ✅ Foundation implemented (profile tab M3) | MVP |
| **WS-C** | Adaptive Reader Foundation | Strategy-pattern reader (`VerticalReaderView` / `PagedReaderView`), `ReaderModeResolver`, mode toggle, reader tests | MVP |
| **WS-D** | User Profile & Preferences | `preferences` feature module, `UserProfile` + `ReadingPreferences` + `PerTitleOverride` domain entities, local-first persistence, profile page UI | MVP |
| **WS-E** | Cloud Sync Expansion | Progress sync, favorites sync, preference cloud backup | V1 |

---

## Milestone Sequence

| Milestone | Name | Entry Gate | Delivers |
|-----------|------|-----------|---------|
| **M0** | Sprint 1 Closure | Now | Planning docs, workstreams, ADRs, task normalization |
| **M1** | Backend Foundation | M0 complete | ~~JWT auth~~ Firebase token verification + SQLite + user/preferences API — ✅ Implemented |
| **M2** | Flutter Auth Foundation | M1 (auth API) | `auth` module, ~~secure storage~~ **Firebase Auth SDK**, session restore, route guard — ✅ Implemented (profile tab deferred to M3) |
| **M3** | Preferences + Adaptive Reader | M2 (auth stable) + WS-D | Dual-mode reader, preference chain, mode toggle |
| **M4** | MVP Integration & Stabilization | M1+M2+M3 | Full auth→preferences→reader flow, E2E tests |
| **M5** | V1 Cloud Sync | M4 (MVP stable) | Progress, favorites, preference cloud sync |

---

## Critical Path and Dependency Order

```
M0 (planning closure)
  └── A1: Backend schema contracts (Firebase UID + SQLite + user/prefs tables)
  └── B1: Flutter secure-session prerequisite (Firebase Auth SDK, auth interceptor contract)
  └── D1: Domain boundary freeze (UserProfile, ReadingPreferences, PerTitleOverride)
  └── C1: Reader architecture decision (strategy pattern + preference chain)
        │
        ▼
  A2: Backend MVP endpoints (GET+PUT /users/me*)    [WS-A]
        │
        ▼
  B2: Route guard + Profile tab nav                               [WS-B]
  D2: Local preferences persistence                               [WS-D]
  C2: Reader dual-mode implementation                             [WS-C]
        │
        ▼
  M4: Integration — connect Flutter auth+prefs to backend
        │
        ▼
  M5: Cloud sync (V1 — WS-E, unblocked after M4 stable)
```

**Key constraints:**
- Route guard depends on restore-session contract (B1 before B2).
- Reader mode toggle depends on `ReadingPreferences` contract (D1 before C2).
- All V1 cloud features (WS-E) are blocked until WS-A, WS-B, and WS-D MVP are stable.

---

## Architecture Decisions (Resolved)

All blocking decisions are resolved. AD-1 was revised after Sprint 1 planning — see note below.

### AD-1 — Auth Strategy: **Firebase Auth (REVISED — JWT-first plan superseded)**

> ⚠️ **REVISED:** The Sprint 1 planning pass initially selected backend-owned JWT (`python-jose` + `passlib`). This decision was **superseded** after further evaluation. **Firebase Auth is now the canonical identity provider for Phase 5.**
>
> **Reason for revision:** Firebase Auth eliminates backend password storage and token rotation complexity, aligns with the existing Firebase Core/Analytics dependency already in the app, and future-proofs social login without any backend changes. The backend remains the verifier (`firebase-admin`) and the owner of local user profile/preferences data keyed by Firebase UID.
>
> **Implementation:** `firebase_auth ^5.5.2` added to Flutter. Backend uses `firebase-admin` to verify ID tokens. Flutter DIO interceptor attaches `Bearer <Firebase ID token>` to protected requests. **`flutter_secure_storage` is not needed** — Firebase Auth SDK manages its own session persistence securely on both platforms.

### AD-2 — Backend Persistence: SQLite via `aiosqlite`

PostgreSQL was considered. SQLite chosen for MVP (zero infrastructure, single-file, async driver available). Repository pattern ensures the storage layer is swappable to Postgres if scaling is needed. **Implemented in Phase 5 foundation.**

### AD-3 — Token Storage: Firebase Auth SDK (replaces flutter_secure_storage plan)

> **REVISED from Sprint 1:** `flutter_secure_storage` was the original plan for storing JWT access/refresh tokens. With Firebase Auth as the identity provider, the Firebase SDK manages its own secure session persistence natively (Android Keystore / iOS Keychain under the hood). `flutter_secure_storage` is **not added** in this implementation.

### AD-4 — UserProfile Boundary: Three separate domain entities

`UserProfile` (identity + preferences reference), `ReadingProgress`, `Favorite` are three separate domain entities — NOT a monolithic UserProfile aggregate. `ReadingProgress` and `Favorite` are V1 entities, designed but not implemented in MVP. **User profile and reading preferences endpoints are implemented in Phase 5 foundation.**

### AD-5 — Adaptive Reader: Strategy pattern

`ReaderPage` delegates to `VerticalReaderView` or `PagedReaderView` via a `ReaderModeResolver`. Both views implement an abstract `ReaderView` interface. Mode toggle is available via AppBar action in the reader. *(Planned for M3 — not in Phase 5 foundation scope.)*

### AD-6 — Profile Navigation: 4th bottom tab

A "Profile" tab is added to the bottom nav (alongside Home, Library, Settings). *(Planned for M2/M3 — not in Phase 5 foundation scope.)*

---

## Implementation Status (historical snapshot)

> **Sprint 1 planning identified the gaps below. Sprint 2 foundation is now complete. Remaining items are M3+ scope.**

### Backend (WS-A) — ✅ M1 complete
| Capability | WS | Status |
|-----------|----|----|
| ~~`/auth/*` register/login/refresh~~ | WS-A | ❌ **Superseded by Firebase Auth** — not implemented by design |
| Firebase token verification (`firebase-admin`) | WS-A | ✅ Implemented |
| User model + SQLite schema (keyed by Firebase UID) | WS-A | ✅ Implemented |
| `/users/me` profile endpoint | WS-A | ✅ Implemented |
| `/users/me/preferences` CRUD | WS-A | ✅ Implemented |
| Progress/favorites endpoints | WS-E | 🔲 M5 (V1) |

### Flutter (WS-B/C/D) — M2 complete; M3 pending
| Capability | WS | Status |
|-----------|----|----|
| `auth` feature module | WS-B | ✅ Implemented |
| ~~`flutter_secure_storage`~~ | WS-B | ❌ **Superseded** — Firebase Auth SDK manages sessions natively |
| `firebase_auth ^5.5.2` dependency | WS-B | ✅ Implemented |
| Sign-in / sign-up pages | WS-B | ✅ Implemented |
| Route guard (GoRouter redirect) | WS-B | ✅ Implemented |
| DI registrations for auth use cases | WS-B | ✅ Implemented |
| Bearer token Dio interceptor | WS-B | ✅ Implemented |
| Profile tab (4th nav tab) | WS-B | 🔲 M3 |
| `preferences` feature module | WS-D | 🔲 M3 |
| `profile` feature module | WS-B/D | 🔲 M3 |
| `UserProfile`, `ReadingPreferences`, `PerTitleOverride` entities | WS-D | 🔲 M3 |
| DI registrations for preferences, reader resolver | WS-D/C | 🔲 M3 |
| `ReaderModeResolver` + dual-mode reader | WS-C | 🔲 M3 |
| `ReaderMode` enum, `ReaderState.readerMode` field | WS-C | 🔲 M3 |

---

## Backend API Surface

> ⚠️ **Auth strategy revised (AD-1):** `/auth/*` endpoints (register, login, refresh) were the Sprint 1 plan but are **superseded by Firebase Auth**. Authentication is handled entirely by Firebase; the backend only verifies Firebase ID tokens. No password storage or JWT issuance on the backend.

### MVP Endpoints (WS-A / M1) — ✅ Implemented

| Method | Path | Purpose | Status |
|--------|------|---------|--------|
| ~~POST~~ | ~~`/auth/register`~~ | ~~Create account~~ | ❌ Superseded by Firebase Auth |
| ~~POST~~ | ~~`/auth/login`~~ | ~~Authenticate → JWT pair~~ | ❌ Superseded by Firebase Auth |
| ~~POST~~ | ~~`/auth/refresh`~~ | ~~Refresh access token~~ | ❌ Superseded by Firebase Auth |
| GET | `/users/me` | Get current user profile (requires Firebase ID token) | ✅ Implemented |
| GET | `/users/me/preferences` | Get reading preferences | ✅ Implemented |
| PUT | `/users/me/preferences` | Update reading preferences | ✅ Implemented |

### V1 Endpoints (WS-E / M5)

| Method | Path | Purpose |
|--------|------|---------|
| GET/PUT | `/users/me/progress/{manga_id}` | Reading progress |
| GET/POST/DELETE | `/users/me/favorites/{manga_id}` | Favorites |
| PUT | `/users/me/preferences/sync` | Cloud preference sync |

---

## New Flutter Feature Modules

| Path | WS | Milestone |
|------|----|-----------|
| `lib/features/auth/` | WS-B | M2 |
| `lib/features/preferences/` | WS-D | M3 |
| `lib/features/profile/` | WS-B/D | M2/M3 |

---

## Sprint 1 Task Map

Sprint 1 is planning and foundation closure. The tasks below map directly to workstreams and unlock the critical path.

| Task | Title | Maps to | Unblocks |
|------|-------|---------|---------|
| TASK-001 ✅ | Refine PRD Phase 5 | M0 | TASK-005, TASK-002 |
| TASK-005 ✅ | Map Backend Integration Points | WS-A → M0→M1 gate | TASK-002 |
| TASK-002 ✅ | Compare Auth Approaches → **Decision: Firebase Auth** (AD-1 revised) | WS-A/B → AD-1 | TASK-003 |
| TASK-003 ✅ | Define UserProfile Domain Model | WS-D → AD-4 | TASK-004, M1/M2 |
| TASK-004 🔲 | Define Adaptive Reader Mode Strategy | WS-C → AD-5 | C1/C2, M3 |

Sprint 1 is closed. TASK-001/005/002/003 completed during Phase 5 foundation implementation. TASK-004 (adaptive reader strategy) is deferred to M3.

---

## Technical Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| SQLite single-writer bottleneck | Medium | WAL mode; migrate to Postgres if scaling |
| ~~JWT refresh race condition~~ | ~~Medium~~ | ~~Token refresh mutex in Dio interceptor~~ — **N/A:** Firebase Auth SDK manages token refresh internally |
| Firebase ID token expiry (1 h) causes request failures | Medium | `_AuthInterceptor` calls `user.getIdToken(false)` — Firebase refreshes automatically if needed; test with expired-token scenario |
| Reader mode auto-detection unreliable | Low | Default to vertical (current behavior); auto-detect is lowest priority in chain |
| ~~`flutter_secure_storage` platform quirks`~~ | ~~Low~~ | ~~Pin version; test on physical devices early in M2~~ — **N/A:** Firebase Auth SDK manages sessions natively |
| Breaking change to existing `ReaderPage` | Medium | Extract views behind interface first; keep vertical as default; feature-flag paged mode |

---

## Business Rationale

- Auth unlocks retention features, but only when tied to real user value.
- Preferences and adaptive reading improve usability immediately, even before cloud sync is complete.
- Cloud progress and favorites are high-value retention features but must not block the foundation.

## Backend Dependency

This phase requires coordinated changes in `Inkscroller_backend`. See execution plan for file-level breakdown: [`docs/PRD/phase-5-execution-plan.md`](phase-5-execution-plan.md).
