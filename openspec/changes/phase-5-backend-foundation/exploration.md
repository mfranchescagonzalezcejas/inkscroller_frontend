# Exploration: phase-5-backend-foundation

> **Historical note (2026-04-04):** This exploration describes the original JWT-first backend-auth approach.
> It remains useful as design history, but it is **superseded** by the later Firebase Auth decision for Phase 5.
> Treat `/auth/*`, password hashing, and backend-issued JWTs in this document as historical planning, not the current baseline.

> **Phase:** Explore
> **Change:** phase-5-backend-foundation
> **Date:** 2026-04-02
> **Status:** Complete — Ready for Proposal

---

## Current State

The backend (`Inkscroller_backend`) is a **pure stateless proxy** — FastAPI 0.128 / Python 3.12 / Pydantic v2. It has **ZERO persistence, ZERO auth, ZERO user concept**.

### What exists

| Layer | Files | Description |
|-------|-------|-------------|
| Entry | `main.py` | `create_app()` factory + lifespan (httpx clients + SimpleCache) |
| Core | `app/core/config.py` | Plain `Settings` class (bare `os.getenv`, no pydantic-settings) |
| Core | `app/core/dependencies.py` | DI factories via `request.app.state.*` |
| Core | `app/core/cache.py` | In-memory TTL dict cache (SimpleCache) |
| Core | `app/core/exceptions.py` | Global handlers: HTTPStatusError / Timeout / ConnectError / UpstreamServiceError |
| Core | `app/core/resilience.py` | `@with_retry()` exponential backoff decorator |
| Core | `app/core/logging.py` | Structured stdout logging |
| API | `app/api/health.py` | `GET /ping` |
| API | `app/api/manga.py` | `GET /manga`, `/manga/search`, `/manga/{id}` |
| API | `app/api/chapters.py` | `GET /chapters/manga/{id}`, `/chapters/{id}/pages` |
| Models | `app/models/manga.py`, `chapter.py` | Pydantic response models |
| Services | `app/services/` | MangaService, ChapterService, ChapterPagesService + mappers |
| Sources | `app/sources/` | MangaDexClient, JikanClient (async httpx) |
| Tests | `tests/test_app.py` | unittest-based smoke tests with `dependency_overrides` pattern |
| CI | `.github/workflows/ci.yml` | ruff lint/format → unittest (GitHub Actions) |

### Current dependencies (requirements.txt — all pinned)

```
fastapi==0.128.0   httpx==0.28.1   pydantic==2.12.5   uvicorn==0.40.0
starlette==0.50.0  pydantic_core==2.41.5  (+ transitive)
```

**NOT present:** python-jose, passlib, aiosqlite, bcrypt, pytest, pytest-asyncio

---

## What is Missing for Phase 5 MVP

Everything in WS-A must be built from scratch:

| Missing | Category |
|---------|----------|
| Any auth endpoints (`/auth/*`) | Feature |
| JWT library (`python-jose[cryptography]`) | Dependency |
| Password hashing (`passlib[bcrypt]`) | Dependency |
| Async SQLite driver (`aiosqlite`) | Dependency |
| SQLite DB init + schema | Infrastructure |
| User model + ReadingPreferences model | Domain |
| `/auth/*` router | API |
| `/users/me` + `/users/me/preferences` router | API |
| `UserService` (CRUD + preferences) | Service |
| JWT secret management (env var, required) | Config/Security |
| `.env` / pydantic-settings support | Config |

---

## Reusable Patterns from Existing Code

These patterns are well-established and **must be followed** for new auth/user code:

1. **Router** — `APIRouter(prefix="/xxx", tags=["Xxx"])` + `app.include_router(xxx_router)` in `create_app()`
2. **Dependency injection** — `def get_xxx(request: Request) -> XxxService:` in `dependencies.py`, consumed via `Depends(get_xxx)`
3. **Lifespan** — `@asynccontextmanager async def lifespan(app)` initializes shared state, stored in `app.state.*`. SQLite DB init goes here.
4. **Error response format** — `{"error": "...", "detail": "..."}` via `_error_response()` helper — add `401 unauthorized` and `403 forbidden` handlers to `register_exception_handlers()`
5. **Pydantic models** — `BaseModel` with `Optional` fields, separate request/response/DB models where needed
6. **Test pattern** — `unittest.TestCase` + `TestClient` + `dependency_overrides` — auth tests can follow this pattern or use pytest (both work with `python -m unittest discover`)

---

## Minimum Viable M1 Slice

The entire Phase 5 M1 backend foundation is **6 new files + changes to 4 existing files**:

### New files

| File | Purpose |
|------|---------|
| `app/core/database.py` | aiosqlite init, WAL mode, `CREATE TABLE IF NOT EXISTS` for `users` + `reading_preferences` |
| `app/core/auth.py` | JWT encode/decode (`python-jose`), bcrypt hash/verify (`passlib`) |
| `app/models/user.py` | `UserCreate`, `UserResponse`, `UserInDB`, `ReadingPreferencesModel` Pydantic models |
| `app/api/auth.py` | `POST /auth/register`, `POST /auth/login`, `POST /auth/refresh` |
| `app/api/users.py` | `GET /users/me`, `GET /users/me/preferences`, `PUT /users/me/preferences` |
| `app/services/user_service.py` | `create_user`, `get_user_by_email`, `get_preferences`, `set_preferences` |

### Files to modify

| File | Change |
|------|--------|
| `app/core/config.py` | Add `JWT_SECRET_KEY` (required, no default), `JWT_ALGORITHM` (HS256), `ACCESS_TOKEN_EXPIRE_MINUTES` (15), `REFRESH_TOKEN_EXPIRE_DAYS` (30), `DB_PATH` (default `inkscroller.db`) |
| `app/core/dependencies.py` | Add `get_current_user` — decodes Bearer token → `UserInDB` |
| `main.py` | Include `auth_router`, `users_router`; call SQLite init in lifespan |
| `requirements.txt` | Add `python-jose[cryptography]`, `passlib[bcrypt]`, `aiosqlite`, `pytest`, `pytest-asyncio` |

---

## API Surface — Phase 5 MVP Endpoints

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| `POST` | `/auth/register` | No | Create account (email + password) |
| `POST` | `/auth/login` | No | Authenticate → `{access_token, refresh_token, token_type}` |
| `POST` | `/auth/refresh` | No (refresh token in body) | Get new access token |
| `GET` | `/users/me` | Bearer | Current user profile |
| `GET` | `/users/me/preferences` | Bearer | Reading preferences |
| `PUT` | `/users/me/preferences` | Bearer | Update reading preferences |

---

## SQLite Schema

```sql
CREATE TABLE IF NOT EXISTS users (
    id            TEXT PRIMARY KEY,           -- UUID
    email         TEXT UNIQUE NOT NULL,
    display_name  TEXT,
    hashed_password TEXT NOT NULL,            -- bcrypt hash
    created_at    TEXT NOT NULL               -- ISO 8601 UTC
);

CREATE TABLE IF NOT EXISTS reading_preferences (
    user_id              TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    default_reader_mode  TEXT NOT NULL DEFAULT 'vertical',  -- 'vertical' | 'paged'
    default_language     TEXT NOT NULL DEFAULT 'en',
    updated_at           TEXT NOT NULL                       -- ISO 8601 UTC
);
```

---

## Token Design

| Token | Algorithm | Expiry | Payload |
|-------|-----------|--------|---------|
| Access | JWT HS256 | 15 min | `{sub: user_id, email, exp}` |
| Refresh | JWT HS256 | 30 days | `{sub: user_id, type: "refresh", exp}` |

MVP: both tokens are stateless JWTs (no revocation DB). V1 can add a `refresh_tokens` table for revocation.

---

## Approaches

### Option A — Full M1 in one change (recommended)
All 6 new files + 4 modified files delivered in `phase-5-backend-foundation`.
- **Pros:** Complete WS-A/M1 deliverable; unblocks WS-B immediately; backend is small enough that this is tractable
- **Cons:** Larger PR surface
- **Effort:** High (5–8h)

### Option B — Auth infra + register/login/refresh only
Deliver JWT plumbing; `/users/me` in a follow-up change.
- **Pros:** Smaller surface area per change
- **Cons:** WS-B still partially blocked (Flutter needs `/users/me` for profile rendering)
- **Effort:** Medium (3–4h)

### Option C — Foundation only: database + config, no endpoints
- **Pros:** Lowest risk; proves SQLite + JWT core works
- **Cons:** Nothing Flutter-consumable; makes the critical path longer
- **Effort:** Low (1–2h)

**→ Recommendation: Option A.** The backend is minimal, patterns are established, and a complete M1 delivery is more valuable than incremental partial states.

---

## Migration and Risk Concerns

| Risk | Impact | Mitigation |
|------|--------|------------|
| `JWT_SECRET_KEY` with no default — app crash if unset | High | Fail fast at startup: `raise ValueError("JWT_SECRET_KEY not set")` in Settings |
| SQLite WAL mode under multiple uvicorn workers | Medium | WAL mode handles readers OK; single-writer limit is fine for single-worker MVP |
| aiosqlite connection lifecycle | Medium | Open a shared connection in lifespan, store in `app.state.db`; use `async with db.execute()` |
| Password storage via bcrypt | Low — correct | Use `passlib.context.CryptContext(schemes=["bcrypt"])` |
| JWT refresh race condition | Medium (Flutter-side) | MVP: single refresh call OK; V1: Dio interceptor mutex on Flutter side |
| `CORS_ORIGINS = "*"` | Low (dev) / High (prod) | Config env var already exists; tighten before production deployment |
| Test runner (unittest vs pytest) | Low | New auth tests can use `pytest` style; both are discovered by `python -m unittest discover` if classes extend `unittest.TestCase`; OR switch CI to `pytest` |
| `requirements.txt` currently has no dev/prod separation | Low | Add inline `# dev` comments or split into `requirements-dev.txt` (pytest, pytest-asyncio) |
| No `.env` loading (bare `os.getenv`) | Medium | Add `python-dotenv` and `load_dotenv()` call OR switch to `pydantic-settings`; latter is preferred |

---

## Docs and Tasks to Update After Implementation

### Vault (Obsidian) — after apply phase completes

- `Tasks/TASK-005` — status: `todo` → `done` (backend mapped AND implemented)
- `Tasks/TASK-002` — status: `todo` → `done` (auth decision AD-1 formalized and implemented)
- `Sprints/Sprint 1 Overview` — WS-A status: Not Started → Complete
- `Inkscroller Backend/Inkscroller Backend.md` — update feature list with auth + persistence

### Repo docs — after apply phase completes

- `docs/PRD/phase-5-execution-plan.md` — check A1–A8 tasks as done
- `Inkscroller_backend/README.md` — add new endpoints, auth header requirement, new Tech Stack entries

### SDD artifacts still needed for this change

1. `propose` — define intent, scope, success criteria
2. `spec` — requirements and acceptance scenarios
3. `design` — detailed technical design (schema, JWT flow, service contracts)
4. `tasks` — implementation task checklist
5. `apply` — actual implementation
6. `verify` — verify implementation vs spec/design

---

## Ready for Proposal

**YES.** All 6 architectural decisions are resolved (AD-1 through AD-6). The backend is minimal and well-understood. The full M1 slice is deliverable in one change with clear file targets.

The `propose` phase can immediately commit to Option A scope.
