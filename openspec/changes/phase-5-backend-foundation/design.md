# Design: Phase 5 Backend Foundation

> **Historical note (2026-04-04):** This design captures the earlier JWT-first backend-auth plan.
> It is preserved for traceability, but it is **superseded** by the Firebase Auth direction adopted later in Phase 5.
> Current baseline: Firebase Auth provides identity, the backend verifies Firebase ID tokens, and backend-owned `/auth/*` JWT issuance is no longer the active plan.

## Technical Approach

Add SQLite persistence, backend-owned JWT auth, and user/preferences endpoints to the existing stateless FastAPI proxy. Follows every existing pattern (lifespan init, `app.state.*`, DI via `dependencies.py`, `_error_response()` format, `APIRouter` convention). Six new files, four modified files.

## Architecture Decisions

| Decision | Choice | Alternatives rejected | Rationale |
|----------|--------|----------------------|-----------|
| Password hashing | `passlib[bcrypt]` (CryptContext, bcrypt scheme, rounds=12) | argon2-cffi (heavier C dep), plain hashlib (insecure) | bcrypt is the Python standard for password hashing; passlib wraps it cleanly; 12 rounds balances security/speed for MVP |
| JWT library | `python-jose[cryptography]` | PyJWT (fewer features), authlib (overkill) | python-jose is the FastAPI ecosystem standard; `cryptography` backend is robust |
| JWT subject strategy | `sub` = user UUID (TEXT PK), email in custom claim | sub=email (PII in every token), sub=integer (no UUID portability) | UUID sub is stable, non-PII, portable to Postgres later; email as optional claim for display convenience |
| Token design | Access JWT (HS256, 30 min) + Refresh JWT (HS256, 30 days), both stateless | Refresh in DB (revocable but adds complexity), opaque tokens (lose self-contained benefit) | Stateless MVP; refresh-revocation table deferred to V1. Single `JWT_SECRET_KEY` signs both (type claim differentiates) |
| DB connection | Single `aiosqlite.connect()` opened in lifespan, stored in `app.state.db`, WAL mode | Connection pool (unnecessary for SQLite), per-request connect (wasteful) | SQLite is single-writer; shared async connection via lifespan matches existing `app.state.*` pattern exactly |
| Config/secrets | Add `python-dotenv`, call `load_dotenv()` at top of `config.py`; `JWT_SECRET_KEY` required (raise on missing), `DB_PATH` defaults to `./inkscroller.db` | pydantic-settings (heavier migration), bare os.getenv (no .env file support) | Minimal change to existing `Settings` class; python-dotenv is lightweight; `.env.example` documents required vars |
| Test runner | Add `pytest` + `pytest-asyncio` for new auth tests; keep existing unittest tests untouched; update CI to run both | Migrate all to pytest (risky scope creep), stay unittest-only (painful for async) | Incremental; existing tests keep passing; new tests get modern async support |
| Error handling | Add `AuthenticationError` and `DuplicateUserError` custom exceptions to `exceptions.py`; register handlers in `register_exception_handlers()` | Use raw HTTPException (loses consistent format), middleware-based (over-engineered) | Follows existing `UpstreamServiceError` pattern exactly; keeps `{"error": "...", "detail": "..."}` response shape |

## Data Flow

```
Client --Bearer--> FastAPI --Depends(get_current_user)--> Router
                      |              |
                      |         decode JWT -> user_id
                      |              |
                      |         app.state.db -> SELECT user
                      |              |
                      +-------- UserService --aiosqlite--> SQLite
```

Register/Login flow:
```
POST /auth/register -> validate body -> hash password -> INSERT user + default prefs -> return UserResponse
POST /auth/login    -> validate body -> SELECT user by email -> verify hash -> sign access+refresh JWT -> return tokens
POST /auth/refresh  -> decode refresh JWT (type=refresh) -> SELECT user exists -> sign new access JWT -> return token
```

## SQLite Schema

```sql
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,            -- uuid4
    email TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL DEFAULT '',
    hashed_password TEXT NOT NULL,
    created_at TEXT NOT NULL         -- ISO 8601
);

CREATE TABLE IF NOT EXISTS reading_preferences (
    user_id TEXT PRIMARY KEY REFERENCES users(id),
    default_reader_mode TEXT NOT NULL DEFAULT 'vertical',
    default_language TEXT NOT NULL DEFAULT 'en',
    updated_at TEXT NOT NULL         -- ISO 8601
);
```

Init in lifespan: `await db.executescript(SCHEMA_SQL)` + `PRAGMA journal_mode=WAL`.

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `app/core/database.py` | Create | `init_db(db_path)` opens aiosqlite, WAL mode, runs schema DDL, returns connection |
| `app/core/auth.py` | Create | `hash_password()`, `verify_password()` (passlib CryptContext), `create_token(sub, type, exp)`, `decode_token(token)` (python-jose) |
| `app/models/user.py` | Create | Pydantic models: `UserCreate`, `UserLogin`, `UserResponse`, `UserInDB`, `TokenResponse`, `ReadingPreferencesResponse`, `ReadingPreferencesUpdate` |
| `app/services/user_service.py` | Create | `UserService(db)` with `create_user()`, `get_by_email()`, `get_by_id()`, `get_preferences()`, `upsert_preferences()` |
| `app/api/auth.py` | Create | `APIRouter(prefix="/auth", tags=["Auth"])`: POST `/register`, POST `/login`, POST `/refresh` |
| `app/api/users.py` | Create | `APIRouter(prefix="/users", tags=["Users"])`: GET `/me`, GET `/me/preferences`, PUT `/me/preferences` |
| `app/core/config.py` | Modify | Add `load_dotenv()`, `jwt_secret_key` (required), `jwt_algorithm`, `access_token_expire_minutes`, `refresh_token_expire_days`, `db_path` |
| `app/core/dependencies.py` | Modify | Add `get_db()`, `get_user_service()`, `get_current_user()` |
| `app/core/exceptions.py` | Modify | Add `AuthenticationError`, `DuplicateUserError` + handlers |
| `main.py` | Modify | Import routers + `init_db`; init DB in lifespan; include auth/users routers |
| `requirements.txt` | Modify | Add `python-jose[cryptography]`, `passlib[bcrypt]`, `bcrypt`, `aiosqlite`, `python-dotenv`, `pytest`, `pytest-asyncio` |
| `.env.example` | Create | Documents `JWT_SECRET_KEY`, `DB_PATH`, existing vars |
| `tests/test_auth.py` | Create | pytest: register/login/me/preferences roundtrip + error cases |
| `.github/workflows/ci.yml` | Modify | Add `JWT_SECRET_KEY` env + pytest step |

## Interfaces / Contracts

### Endpoint contracts

**POST /auth/register** — Request: `{"email": str, "password": str, "display_name": str?}` — Response 201: `{"id": str, "email": str, "display_name": str, "created_at": str}`

**POST /auth/login** — Request: `{"email": str, "password": str}` — Response 200: `{"access_token": str, "refresh_token": str, "token_type": "bearer"}`

**POST /auth/refresh** — Request: `{"refresh_token": str}` — Response 200: `{"access_token": str, "token_type": "bearer"}`

**GET /users/me** — Headers: `Authorization: Bearer <token>` — Response 200: `{"id": str, "email": str, "display_name": str, "created_at": str}`

**GET /users/me/preferences** — Headers: Bearer — Response 200: `{"default_reader_mode": str, "default_language": str, "updated_at": str}`

**PUT /users/me/preferences** — Headers: Bearer, Request: `{"default_reader_mode": str?, "default_language": str?}` — Response 200: full preferences object

### Error shape (all errors)

`{"error": "<error_code>", "detail": "<human message>"}` — matches existing `_error_response()`.

Error codes: `duplicate_email` (409), `invalid_credentials` (401), `authentication_required` (401), `invalid_token` (401), `user_not_found` (404), `validation_error` (422).

### DI dependency: `get_current_user`

```python
async def get_current_user(request: Request) -> UserInDB:
    # 1. Extract Bearer token from Authorization header
    # 2. decode_token() -> payload; verify type == "access"
    # 3. get_user_service(request).get_by_id(payload["sub"])
    # 4. Raise AuthenticationError if any step fails
```

Injected via `Depends(get_current_user)` on protected endpoints.

## Testing Strategy

| Layer | What to Test | Approach |
|-------|-------------|----------|
| Unit | hash/verify password, create/decode token, expiry | pytest, no DB |
| Integration | register->login->me->preferences roundtrip | pytest + TestClient + SQLite `:memory:` |
| Integration | Duplicate registration returns 409 | pytest + TestClient |
| Integration | Invalid credentials returns 401 | pytest + TestClient |
| Integration | Missing/expired/invalid Bearer returns 401 | pytest + TestClient |
| Integration | Preferences default + update persistence | pytest + TestClient |
| CI | Both unittest + pytest run | `JWT_SECRET_KEY=test-secret-for-ci` |

## Migration / Rollout

No data migration — greenfield schema. SQLite created on first startup. `.env.example` documents config. Existing endpoints unaffected.

## Open Questions

None — all decisions resolved. Ready for task breakdown.
