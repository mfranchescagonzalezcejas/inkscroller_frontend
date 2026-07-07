# Inkscroller — Architecture Document

> **Last updated:** March 2026  
> **Stack:** Flutter (Dart) + FastAPI (Python)  
> **State management:** Riverpod (`StateNotifier`)  
> **DI:** get_it  
> **Navigation:** `MaterialApp.router` + `go_router` (`StatefulShellRoute.indexedStack`)

## Related diagrams

![App Architecture](diagrams/app-architecture.svg)

Editable source: [`app-architecture.drawio`](diagrams/app-architecture.drawio)

![Data Flow](diagrams/data-flow.svg)

Editable source: [`data-flow.drawio`](diagrams/data-flow.drawio)

![Deployment and Environment Flow](diagrams/deployment-environment-flow.svg)

Editable source: [`deployment-environment-flow.drawio`](diagrams/deployment-environment-flow.drawio)

---

## Table of Contents

1. [Overview](#1-overview)
2. [Flutter Architecture](#2-flutter-architecture)
   - 2.1 [Clean Architecture Layers](#21-clean-architecture-layers)
   - 2.2 [Layer Responsibilities](#22-layer-responsibilities)
   - 2.3 [Dependency Flow](#23-dependency-flow)
   - 2.4 [State Management: Riverpod + StateNotifier](#24-state-management-riverpod--statenotifier)
   - 2.5 [Dependency Injection: get_it](#25-dependency-injection-get_it)
   - 2.6 [Navigation](#26-navigation)
   - 2.7 [Flavor System](#27-flavor-system)
3. [Backend Architecture](#3-backend-architecture)
   - 3.1 [Layered Architecture](#31-layered-architecture)
   - 3.2 [Layer Responsibilities](#32-layer-responsibilities)
   - 3.3 [External Integrations](#33-external-integrations)
   - 3.4 [Data Enrichment Flow](#34-data-enrichment-flow)
   - 3.5 [Caching Strategy](#35-caching-strategy)
4. [Flutter ↔ Backend Integration](#4-flutter--backend-integration)
   - 4.1 [End-to-End Request Flow](#41-end-to-end-request-flow)
   - 4.2 [Environment Configuration Chain](#42-environment-configuration-chain)
   - 4.3 [API Contract](#43-api-contract)
5. [Key Design Decisions](#5-key-design-decisions)

---

## 1. Overview

**Inkscroller** is a manga reading application composed of two independent systems:

- **Flutter app** — cross-platform mobile client for browsing, searching, and reading manga.
- **FastAPI backend** — aggregation API that normalizes data from two external sources (MangaDex + Jikan) into a single clean contract consumed by the app.

The backend is **not a database-backed service** — it is a **stateless aggregation proxy** with in-process TTL caching. The source of truth for manga data is always MangaDex + Jikan.

```
┌─────────────────────────────────────────────────────────────────────┐
│                         INKSCROLLER SYSTEM                          │
│                                                                     │
│  ┌──────────────────────────────┐   HTTP/JSON                       │
│  │       Flutter App            │ ──────────────────────────────┐   │
│  │  (iOS / Android / Desktop)   │                               │   │
│  │                              │ ◄─────────────────────────────┘   │
│  │  Riverpod StateNotifier      │                                   │
│  │  get_it DI                   │        ┌───────────────────────┐  │
│  │  Clean Architecture          │        │   FastAPI Backend     │  │
│  └──────────────────────────────┘        │                       │  │
│                                          │  /manga               │  │
│                                          │  /manga/{id}          │  │
│                                          │  /manga/search        │  │
│                                          │  /chapters/manga/{id} │  │
│                                          │  /chapters/{id}/pages │  │
│                                          │  /health              │  │
│                                          └──────────┬────────────┘  │
│                                                     │               │
│                             ┌───────────────────────┼               │
│                             │                       │               │
│                   ┌─────────▼──────────┐   ┌────────▼─────────┐     │
│                   │  MangaDex API      │   │  Jikan API (MAL) │     │
│                   │  api.mangadex.org  │   │  api.jikan.moe   │     │
│                   │  (chapters/pages)  │   │  (scores/genres) │     │
│                   └────────────────────┘   └──────────────────┘     │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 2. Flutter Architecture

### 2.1 Screaming Architecture + Clean Architecture

The Flutter app combines two complementary patterns:

- **Screaming Architecture** (outer level) — the `features/` directory screams *what the app does*, not what framework it uses. Each subdirectory is a business domain concept (`library`, `reader`, `auth`, `preferences`), not a technical construct (`controllers`, `services`, `models`).
- **Clean Architecture** (inner level) — inside each feature, dependencies flow inward through three layers: `domain → data → presentation`.

```
lib/
├── core/                              # Shared infrastructure (cross-feature)
│   ├── analytics/                     # Firebase Analytics observer
│   ├── config/                        # ApiConfig, AppEnvironment, AppVersionProvider
│   ├── constants/                     # ApiEndpoints, AppConstants, AppLayout
│   ├── design/                        # Design tokens: AppColors, AppSpacing, AppTypography
│   ├── di/injection.dart              # get_it registration (initDI)
│   ├── error/                         # Failures, Exceptions
│   ├── l10n/                          # AppLocaleProvider, l10n helpers
│   ├── network/                       # DioClient, connectivity provider
│   ├── router/app_router.dart         # go_router route table
│   ├── theme/                         # App theme
│   └── widgets/                       # Shared UI: AppTopBar, CatalogTabBar, shimmer
│
├── features/                          # ← Screaming Architecture
│   ├── about/
│   │   └── presentation/pages/        # AboutPage (static)
│   │
│   ├── auth/
│   │   ├── data/                      # FirebaseAuthDataSource, AuthRepositoryImpl
│   │   ├── domain/                    # AppUser, AuthRepository, use cases
│   │   └── presentation/              # LoginPage, RegisterPage, AuthNotifier
│   │
│   ├── explore/
│   │   └── presentation/pages/        # ExplorePage (reuses library providers)
│   │
│   ├── home/
│   │   ├── data/                      # HomeRemoteDataSource, HomeRepositoryImpl
│   │   ├── domain/                    # HomeChapter, HomeRepository, use cases
│   │   └── presentation/
│   │       ├── constants/             # HomeLayout (home_layout.dart) + Home UI dimensions
│   │       ├── pages/                 # HomePage
│   │       └── providers/             # HomeState, HomeClassifier, derived providers
│   │
│   ├── library/
│   │   ├── data/                      # ← DATA LAYER
│   │   │   ├── datasources/           # LibraryRemoteDataSource + impl, LibraryLocalDataSource + impl
│   │   │   ├── mappers/               # MangaModel → Manga, ChapterModel → Chapter
│   │   │   ├── models/                # DTOs: MangaModel, ChapterModel
│   │   │   └── repositories/          # LibraryRepositoryImpl, PerTitleOverrideRepositoryImpl
│   │   │
│   │   ├── domain/                    # ← DOMAIN LAYER (pure Dart, no Flutter)
│   │   │   ├── entities/              # Manga, Chapter, ReaderMode, MangaTags
│   │   │   ├── repositories/          # LibraryRepository, PerTitleOverrideRepository (abstract)
│   │   │   └── usecases/              # GetMangaList, GetMangaDetail, SearchManga, etc.
│   │   │
│   │   └── presentation/              # ← PRESENTATION LAYER
│   │       ├── constants/             # LibraryUiConstants
│   │       ├── pages/                 # LibraryPage, MangaDetailPage, ReaderPage, UserLibraryPage
│   │       ├── providers/
│   │       │   ├── chapters/          # MangaChaptersNotifier, MangaChapterProvider
│   │       │   ├── reader/            # ReaderNotifier, ReaderProvider, ReaderState
│   │       │   └── library/           # LibraryNotifier, LibraryState, dedupe_mangas.dart
│   │       └── widgets/               # MangaTile, ChapterTile, CoverImage, shimmer variants
│   │
│   ├── navigation/
│   │   └── presentation/pages/        # MainScaffold (floating bottom nav shell)
│   │
│   ├── preferences/
│   │   ├── data/                      # PreferencesLocalDataSource + impl, remote + impl
│   │   ├── domain/                    # UserReadingPreferences, use cases
│   │   └── presentation/providers/    # PreferencesNotifier, PreferencesState
│   │
│   ├── profile/
│   │   ├── data/                      # UserProfileRemoteDataSource + impl, repository impl
│   │   ├── domain/                    # UserProfile, use cases
│   │   └── presentation/              # ProfilePage, UserProfileNotifier
│   │
│   └── settings/
│       └── presentation/              # SettingsPage, SettingsCacheController
│
├── flavors/                           # FlavorConfig, FlavorBanner
├── flutter_app.dart                   # MaterialApp.router entry point
└── main_common.dart                   # App bootstrap (shared entry point)
```

### 2.2 Layer Responsibilities

#### Data Layer

| Component | Responsibility |
|-----------|---------------|
| `LibraryRemoteDataSource` (abstract) | Defines the data contract for HTTP calls |
| `LibraryRemoteDataSourceImpl` | Implements HTTP calls via `Dio`; parses raw JSON into models |
| `MangaModel` / `ChapterModel` | DTOs: JSON deserialization via `fromJson()` |
| `manga_mapper.dart` / `chapter_mapper.dart` | Extension method `.toEntity()` — converts model → domain entity |
| `LibraryRepositoryImpl` | Orchestrates datasource calls; converts models to entities via mappers |

The data layer is the **only** layer that knows about JSON, HTTP, or the backend API shape.

#### Domain Layer

| Component | Responsibility |
|-----------|---------------|
| `Manga` / `Chapter` (entities) | Pure Dart value objects. No JSON, no Flutter. |
| `LibraryRepository` (abstract) | Port that the domain layer depends on. Defines the contract. |
| Use Cases (`GetMangaList`, `GetMangaDetail`, `GetMangaChapters`, `GetChapterPages`, `SearchManga`) | Single-responsibility callables (`call()` operator). Delegate to repository. |

The domain layer has **zero external dependencies** — no Dio, no Flutter, no get_it. This is the most stable part of the codebase.

#### Presentation Layer

| Component | Responsibility |
|-----------|---------------|
| `LibraryNotifier` / `ReaderNotifier` / etc. (`StateNotifier`) | Business logic for UI state; calls use cases; emits new `LibraryState` |
| `LibraryState` / `ReaderState` / etc. | Immutable state snapshots with `copyWith()` |
| `libraryProvider` / `readerProvider` / etc. (`StateNotifierProvider`) | Riverpod providers that wire the notifier to the widget tree |
| Pages (`HomePage`, `LibraryPage`, `MangaDetailPage`, `ReaderPage`, `SettingsPage`) | `ConsumerWidget`/`StatelessWidget` screens that compose UI and watch providers; contain no business logic |
| Widgets (`MangaTile`, `ChapterTile`, shimmer variants) | Pure presentational components |

### 2.3 Dependency Flow

The **Dependency Rule** of Clean Architecture states that dependencies only point inward. The presentation layer never imports from the data layer directly.

```
┌──────────────────────────────────────────────────────────────────┐
│  PRESENTATION                                                    │
│  (StateNotifier, Providers, Pages, Widgets)                      │
│  knows about: UseCases, Entities, States                         │
└───────────────────────────────┬──────────────────────────────────┘
                                │ depends on
                                ▼
┌──────────────────────────────────────────────────────────────────┐
│  DOMAIN                                                          │
│  (Entities, Repository interfaces, Use Cases)                    │
│  knows about: nothing external                                   │
└───────────────────────────────┬──────────────────────────────────┘
                                │ depends on (via interface)
                                ▼
┌──────────────────────────────────────────────────────────────────┐
│  DATA                                                            │
│  (DataSource impls, Models, Mappers, Repository impls)           │
│  knows about: Dio, JSON, backend API, Domain entities            │
└──────────────────────────────────────────────────────────────────┘
```

The data layer **implements** the `LibraryRepository` interface defined in the domain layer. At runtime, get_it wires the implementation to the interface — the domain and presentation layers never directly reference the concrete implementation.

### 2.4 State Management: Riverpod + StateNotifier

The app uses **Riverpod** with the `StateNotifier` pattern (not BLoC, despite the initial description). Each feature area has a `StateNotifier` subclass paired with an immutable state class.

**Pattern:**

```
                   User action
                       │
                       ▼
           ┌───────────────────────┐
           │   ConsumerWidget      │
           │   ref.watch(provider) │◄──── Riverpod rebuilds here
           │   ref.read(provider   │
           │        .notifier)     │
           │        .someMethod()  │
           └───────────┬───────────┘
                       │ calls method on
                       ▼
           ┌───────────────────────┐
           │   StateNotifier       │
           │   (LibraryNotifier)   │
           │                       │
           │   - calls use case    │
           │   - builds new state  │
           │   - state = newState  │◄──── triggers rebuild above
           └───────────┬───────────┘
                       │ calls
                       ▼
           ┌───────────────────────┐
           │   Use Case            │
           │   (GetMangaList)      │
           └───────────┬───────────┘
                       │ calls
                       ▼
           ┌───────────────────────┐
           │   Repository          │
           │   (LibraryRepository) │
           └───────────────────────┘
```

**State shape example — `LibraryState`:**

```dart
class LibraryState {
  final List<Manga> mangas;
  final bool isLoading;      // initial full-screen load
  final bool isLoadingMore;  // pagination spinner
  final bool hasMore;        // controls whether loadMore() fires
  final String query;        // current search text
  final bool isSearching;    // search request in-flight
  final String? error;
}
```

Notable patterns in the notifiers:
- **Debounce** (350ms) on `setQuery()` in `LibraryNotifier` to avoid firing a search request on every keystroke.
- **Race condition guard** — `_activeQuery` is compared after the async call returns; stale responses are discarded.
- **Deduplication** — `_dedupe()` uses a Map keyed by `manga.id` to eliminate duplicate entries from pagination.
- **Image pre-caching** in `ReaderNotifier` — each page URL is pre-cached via `ImageStream` before the reader is displayed, with incremental `loadedPages` progress tracking.

### 2.5 Dependency Injection: get_it

All dependencies are registered in `lib/core/di/injection.dart` via `initDI()`, which is called once during app bootstrap in `mainCommon()`.

**Registration strategy:**

```dart
final sl = GetIt.instance;   // global service locator

// Core (registered once, reused everywhere)
sl.registerLazySingleton<DioClient>(() => DioClient());

// DataSource (singleton — stateless, shares Dio instance)
sl.registerLazySingleton<LibraryRemoteDataSource>(
    () => LibraryRemoteDataSourceImpl(sl<DioClient>().dio));

// Repository (singleton — stateless, wraps datasource)
sl.registerLazySingleton<LibraryRepository>(
    () => LibraryRepositoryImpl(sl()));

// Use Cases (singletons — pure functions wrapping repository)
sl.registerLazySingleton<GetMangaList>(() => GetMangaList(sl()));
sl.registerLazySingleton<GetMangaDetail>(() => GetMangaDetail(sl()));
sl.registerLazySingleton<GetMangaChapters>(() => GetMangaChapters(sl()));
sl.registerLazySingleton<GetChapterPages>(() => GetChapterPages(sl<LibraryRepository>()));
sl.registerLazySingleton<SearchManga>(() => SearchManga(sl<LibraryRepository>()));
```

**All registrations are `LazySingleton`** — objects are created on first access, not at startup. Since the notifiers are created by Riverpod providers (not get_it), they themselves are not registered; they pull use cases from `sl` directly.

```
bootstrap
    │
    ├── FlavorConfig.instance (configured)
    ├── Firebase.initialize()
    └── initDI()
            │
            ├── sl<DioClient>
            │       └── reads ApiConfig.baseUrl
            │               └── reads FlavorConfig.instance.apiBaseUrl
            │
            ├── sl<LibraryRemoteDataSource>
            │       └── depends on sl<DioClient>.dio
            │
            ├── sl<LibraryRepository>
            │       └── depends on sl<LibraryRemoteDataSource>
            │
            └── sl<GetMangaList>, sl<GetMangaDetail>, ...
                    └── depend on sl<LibraryRepository>
```

### 2.6 Navigation

Navigation is implemented with **`MaterialApp.router` + `go_router`**.

The app uses a centralized router in `lib/core/router/app_router.dart` with
**`StatefulShellRoute.indexedStack`** so bottom tabs keep their state while
detail/reader flows use declarative route paths.

**Route table:**

```dart
StatefulShellRoute.indexedStack(
  branches: [
    GoRoute(path: '/', builder: (_) => const HomePage()),
    GoRoute(path: '/library', builder: (_) => const LibraryPage()),
    GoRoute(path: '/settings', builder: (_) => const SettingsPage()),
  ],
)

GoRoute(path: '/manga/:mangaId', builder: (_) => MangaDetailPage(...))
GoRoute(path: '/manga/:mangaId/chapter/:chapterId', builder: (_) => ReaderPage(...))
```

**Tab structure via `MainScaffold`:**

The app uses a `StatefulNavigationShell` backed by `StatefulShellRoute.indexedStack`. Tabs are stateful — switching tabs preserves their scroll position.

```
MainScaffold (StatefulNavigationShell)
├── Tab 0: HomePage       — Featured, Latest, Popular, Demographics sections
├── Tab 1: LibraryPage    — Full catalogue with search and infinite scroll
└── Tab 2: SettingsPage   — Placeholder settings screen for future app options

Pushed routes:
└── /manga/:mangaId → MangaDetailPage (+ Chapter list)
    └── /manga/:mangaId/chapter/:chapterId → ReaderPage
```

### 2.7 Flavor System

The app supports three build flavors controlled by a **Singleton `FlavorConfig`**.

```dart
enum Flavor { dev, staging, pro }

class FlavorConfig {
  final Flavor flavor;
  final String apiBaseUrl;
  final String name;

  // Singleton: initialized once at bootstrap, throws if accessed before init
  static FlavorConfig? _instance;
}
```

**Bootstrap flow:**

```
main_dev.dart      ──┐
main_staging.dart  ──┤──► mainCommon(flavor: Flavor.X, apiBaseUrl: AppEnvironment.apiBaseUrl, name: "...")
main_pro.dart      ──┘         │
                           ├── FlavorConfig(...)   ← singleton initialized here
                           ├── Firebase.initializeApp(options: FirebaseOptionsSelector.current)
                           ├── FirebaseAnalytics.setUserProperty(name, flavor.name)
                           └── initDI()            ← DioClient reads FlavorConfig.instance.apiBaseUrl
```

**Config chain:**

```
FlavorConfig.instance.apiBaseUrl
        │
        ▼
ApiConfig.baseUrl (static getter)
        │
        ▼
DioClient → Dio(BaseOptions(baseUrl: ApiConfig.baseUrl))
```

The flavor also controls:
- `FlavorBanner` — shows a colored ribbon in non-production builds
- `AppBar` title — uses `FlavorConfig.instance.name`
- Firebase Analytics user property — tags sessions by environment

---

## 3. Backend Architecture

### 3.1 Layered Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      FastAPI Application                    │
│                         main.py                             │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                   API LAYER (Routers)               │   │
│  │  /manga          /chapters          /health         │   │
│  │  manga.py        chapters.py        health.py       │   │
│  │  pages.py        (pages sub-routes)                 │   │
│  └──────────────────────────┬──────────────────────────┘   │
│                             │ calls                         │
│  ┌──────────────────────────▼──────────────────────────┐   │
│  │                 SERVICE LAYER                       │   │
│  │  MangaService    ChapterService    ChapterPagesService│  │
│  │                                                     │   │
│  │  • Cache check (SimpleCache, TTL 5 min)             │   │
│  │  • Orchestrates source calls                        │   │
│  │  • Data enrichment (MangaDex + Jikan merge)         │   │
│  │  • Mapping to response dicts                        │   │
│  └──────────┬──────────────────────────┬───────────────┘   │
│             │ calls                    │ calls              │
│  ┌──────────▼────────┐    ┌────────────▼────────────────┐  │
│  │  SOURCES LAYER    │    │  SOURCES LAYER              │  │
│  │  MangaDexClient   │    │  JikanClient                │  │
│  │  (httpx async)    │    │  (httpx async)              │  │
│  └──────────┬────────┘    └────────────┬────────────────┘  │
│             │                          │                    │
└─────────────┼──────────────────────────┼────────────────────┘
              │                          │
              ▼                          ▼
     api.mangadex.org            api.jikan.moe/v4
```

### 3.2 Layer Responsibilities

#### API Layer (`app/api/`)

Thin HTTP adapters. Each router file owns a single resource.

| File | Prefix | Endpoints |
|------|--------|-----------|
| `manga.py` | `/manga` | `GET /manga` (list), `GET /manga/search`, `GET /manga/{id}` |
| `chapters.py` | `/chapters` | `GET /chapters/manga/{manga_id}` |
| `pages.py` | `/chapters` | `GET /chapters/{chapter_id}/pages` |
| `health.py` | `/` | `GET /health` |

Responsibilities:
- Declare query parameter schemas (FastAPI `Query()` with validation)
- Response model typing via Pydantic (`response_model=List[Manga]`)
- Raise `HTTPException` for not-found cases
- Input sanitization (`.strip()` on path parameters)
- **No business logic** — delegate immediately to service layer

#### Service Layer (`app/services/`)

Contains all business logic: caching, orchestration, enrichment, and mapping.

| Service | Responsibility |
|---------|---------------|
| `MangaService` | List/search/detail for manga; merges MangaDex + Jikan data on detail |
| `ChapterService` | Fetches and filters chapters by language; only returns readable chapters |
| `ChapterPagesService` | Resolves chapter page URLs from MangaDex AT-Home server |
| `manga_mapper.py` | `map_mangadex_manga()` + `map_jikan_manga()` — raw dict → normalized dict |
| `chapter_mapper.py` | MangaDex chapter payload → normalized chapter dict |

Each service owns its own `SimpleCache` instance with a 5-minute TTL.

#### Sources Layer (`app/sources/`)

Pure external API clients. They make HTTP calls and return raw JSON — no transformation.

| Client | Base URL | Purpose |
|--------|----------|---------|
| `MangaDexClient` | `https://api.mangadex.org` | Manga metadata, covers, chapters, page server |
| `JikanClient` | `https://api.jikan.moe/v4` | MAL-enriched data: scores, genres, authors, demographics |

Both use `httpx.AsyncClient` for non-blocking I/O compatible with FastAPI's async request cycle.

#### Models Layer (`app/models/`)

Pydantic `BaseModel` classes used as response schemas.

```python
class Manga(BaseModel):
    id: str
    title: str
    description: Optional[str]
    coverUrl: Optional[str]
    demographic: Optional[str]
    status: Optional[str]
    # From Jikan enrichment:
    score: Optional[float]
    rank: Optional[int]
    popularity: Optional[int]
    members: Optional[int]
    favorites: Optional[int]
    authors: List[str]
    serialization: Optional[str]
    genres: List[str]
    chapters: Optional[int]
    startYear: Optional[int]
    endYear: Optional[int]
```

### 3.3 External Integrations

#### MangaDex API

- **Role:** Primary source. Provides manga metadata, chapters, cover art, and page image URLs.
- **Cover art** — requires `includes[]=cover_art` in requests; the cover URL is assembled manually: `{COVER_BASE_URL}/{manga_id}/{fileName}.256.jpg`
- **Page resolution** — uses the `/at-home/server/{chapter_id}` endpoint, which returns a `baseUrl` + `hash` + file list. Final page URLs are `{baseUrl}/data/{hash}/{file}`.
- **Language filtering** — chapters are filtered by `translatedLanguage[]=en` by default.

#### Jikan API (MyAnimeList proxy)

- **Role:** Enrichment source. Provides social and editorial metadata missing from MangaDex: scores, ranks, genres, authors, serializations, publication dates, demographic.
- **Only called on `get_by_id`** — not on list or search (performance concern).
- **Fail-safe:** wrapped in `try/except Exception: pass` — Jikan errors never surface to the client.
- **Merge strategy:** Jikan data fills only **empty fields** from MangaDex. MangaDex data is never overwritten.

### 3.4 Data Enrichment Flow

The detail endpoint (`GET /manga/{id}`) performs a two-phase enrichment:

```
GET /manga/{id}
       │
       ▼
MangaService.get_by_id(manga_id)
       │
       ├── 1. Cache check → HIT? return immediately
       │
       ├── 2. MangaDexClient.get_manga(manga_id)
       │       └── map_mangadex_manga(item) → base dict
       │           (id, title, description, coverUrl, demographic, status)
       │           (score=None, genres=[], authors=[], ...)  ← empty slots
       │
       ├── 3. JikanClient.search_manga(result["title"])
       │       └── map_jikan_manga(payload) → enrichment dict
       │           (description, score, rank, genres, authors, demographic, dates...)
       │
       ├── 4. Merge: for each key in jikan_data:
       │       if result[key] is None/[]/""  AND  jikan_data[key] is not None/[]/""
       │           result[key] = jikan_data[key]    ← fill the gap
       │       else:
       │           keep MangaDex value               ← never overwrite
       │
       ├── 5. Cache result (TTL 5 min)
       │
       └── 6. Return enriched Manga dict
```

### 3.5 Caching Strategy

```python
class SimpleCache:
    def __init__(self, ttl_seconds: int = 300):
        self._store: dict[str, tuple[float, Any]] = {}

    def get(self, key: str) -> Any | None:
        # returns None if expired (and deletes entry)

    def set(self, key: str, value: Any) -> None:
        # stores (expires_at_timestamp, value)
```

| Characteristic | Value |
|----------------|-------|
| Type | In-process dict (per-worker memory) |
| TTL | 5 minutes (300 seconds) |
| Scope | Per-service instance (not shared between workers) |
| Eviction | Lazy — on `get()` if expired |
| Key format | `"manga:{id}"`, `"search:{query}:{limit}"`, `"chapters:{id}:{lang}"`, `"pages:{id}"` |

**Tradeoffs:**
- ✅ Zero infrastructure dependencies (no Redis/Memcached)
- ✅ Fast (in-memory dict lookup)
- ⚠️ Not shared across multiple Uvicorn workers (each worker maintains its own cache)
- ⚠️ Cleared on process restart
- ⚠️ No size limit — unbounded memory growth under heavy load

---

## 4. Flutter ↔ Backend Integration

### 4.1 End-to-End Request Flow

The following traces a user scrolling to the bottom of the library list (triggering `loadMore()`):

```
USER ACTION: scrolls to bottom of LibraryPage
         │
         ▼
LibraryPage (ConsumerWidget)
  └─ detects scroll end → calls ref.read(libraryProvider.notifier).loadMore()
         │
         ▼
LibraryNotifier.loadMore()
  ├─ guard: isLoadingMore || !hasMore → abort
  ├─ state = state.copyWith(isLoadingMore: true)   ← triggers LibraryPage rebuild (spinner)
  └─ calls _getMangaList(limit: 20, offset: _offset)
         │
         ▼
GetMangaList.call(limit: 20, offset: 40)
  └─ delegates to repository.getMangaList(...)
         │
         ▼
LibraryRepositoryImpl.getMangaList(limit, offset)
  └─ calls remoteDataSource.getMangaList(limit, offset)
         │
         ▼
LibraryRemoteDataSourceImpl.getMangaList(limit, offset)
  └─ dio.get('/manga', queryParameters: {limit: 20, offset: 40})
         │
         ▼  HTTP GET http://{apiBaseUrl}/manga?limit=20&offset=40
         │
         ▼
FastAPI: GET /manga
  └─ list_manga(limit=20, offset=40)
         │
         ▼
MangaService.list_manga(limit=20, offset=40)
  ├─ cache_key = "manga:list:20:40:None:None:None:None"
  ├─ SimpleCache.get(cache_key) → MISS
  ├─ MangaDexClient.list_manga(limit=20, offset=40)
  │       └─ httpx GET https://api.mangadex.org/manga?limit=20&offset=40&includes[]=cover_art
  ├─ [map_mangadex_manga(item) for item in payload["data"]]
  ├─ SimpleCache.set(cache_key, response)
  └─ return { data: [...], limit: 20, offset: 40, total: N }
         │
         ▼  HTTP 200 JSON
         │
         ▼
LibraryRemoteDataSourceImpl
  └─ parses response.data["data"] → List<MangaModel> via MangaModel.fromJson()
         │
         ▼
LibraryRepositoryImpl
  └─ models.map((e) => e.toEntity()).toList() → List<Manga>
         │
         ▼
GetMangaList.call() returns List<Manga>
         │
         ▼
LibraryNotifier.loadMore()
  ├─ _offset += mangas.length
  ├─ combined = _dedupe([...state.mangas, ...newMangas])
  └─ state = state.copyWith(mangas: combined, isLoadingMore: false, hasMore: ...)
         │
         ▼
Riverpod: libraryProvider emits new LibraryState
         │
         ▼
LibraryPage rebuilds
  └─ renders new manga tiles (no spinner)
```

### 4.2 Environment Configuration Chain

```
Build-time entry point
  main_dev.dart / main_staging.dart / main_pro.dart
        │
        ▼
AppEnvironment.<flavor>ApiBaseUrl
  ├─ String.fromEnvironment('API_BASE_URL') override when provided
  └─ flavor default custom domain
       dev     → https://api.dev.inkscroller.devdigi.dev
       staging → https://api.stg.inkscroller.devdigi.dev
       pro     → https://api.inkscroller.devdigi.dev
        │
        ▼
mainCommon(flavor: Flavor.X, apiBaseUrl: AppEnvironment.<flavor>ApiBaseUrl, name: "Inkscroller")
        │
        ▼
FlavorConfig._instance = FlavorConfig._(flavor, apiBaseUrl, name)
        │
        ▼
initDI() → DioClient()
        │
        ▼
ApiConfig.baseUrl
  └─ return FlavorConfig.instance.apiBaseUrl   ← single source of truth
        │
        ▼
Dio(BaseOptions(baseUrl: API_BASE_URL))
  connectTimeout: 15s
  receiveTimeout: 15s
  headers: { Content-Type: application/json }
```

**IPv4 override:** `HttpOverrides.global = IPv4HttpOverrides()` is set before network activity to force IPv4 resolution. This prevents mobile devices from attempting IPv6 connections to a local dev server that only listens on IPv4.

### 4.3 API Contract

The Flutter client expects these endpoints on the configured `apiBaseUrl`:

| Method | Endpoint | Flutter caller | Response |
|--------|----------|---------------|----------|
| GET | `/manga?limit=N&offset=N` | `getMangaList` | `{ data: Manga[], total: int, limit: int, offset: int }` |
| GET | `/manga/{id}` | `getMangaDetail` | `Manga` |
| GET | `/manga/search?q=...` | `searchManga` | `Manga[]` or `{ data: Manga[] }` |
| GET | `/chapters/manga/{id}` | `getMangaChapters` | `Chapter[]` |
| GET | `/chapters/{id}/pages` | `getChapterPages` | `{ readable: bool, external: bool, pages: string[] }` |

**`Manga` JSON contract** (as consumed by `MangaModel.fromJson()`):

```json
{
  "id": "string",
  "title": "string",
  "description": "string | null",
  "coverUrl": "string | null",
  "demographic": "string | null",
  "status": "string | null",
  "genres": ["string"],
  "score": "number | null"
}
```

**`Chapter` JSON contract** (as consumed by `ChapterModel.fromJson()`):

```json
{
  "id": "string",
  "number": "number | null",
  "title": "string | null",
  "date": "string | null",
  "readable": "boolean",
  "external": "boolean",
  "externalUrl": "string | null"
}
```

---

## 5. Key Design Decisions

### Why Screaming Architecture + Clean Architecture?

**Problem:** Organizing by technical type (`controllers/`, `models/`, `widgets/`) hides what the app does. As the feature set grows, finding everything related to "reader mode" requires jumping between unrelated files across multiple top-level directories.

**Decision:** Organize by business domain at the outer level (Screaming Architecture), then enforce Clean Architecture layers inside each feature. The top-level `features/` directory communicates intent — `library`, `auth`, `preferences`, `reader` — while the inner `domain/data/presentation` split enforces the dependency rule and testability.

**Consequence:** Adding a new feature means adding a new directory under `features/` with its own three-layer structure. The cost is predictable boilerplate; the benefit is that each feature is self-contained and can be understood, tested, and modified independently.

---

### Why Clean Architecture?

**Problem:** In a vanilla Flutter app, it is tempting to put Dio calls directly inside widgets or providers. This couples the UI to the network layer, making it impossible to test the business logic in isolation and expensive to swap out the data source.

**Decision:** Enforce the Clean Architecture Dependency Rule: presentation → domain ← data. The domain layer is a pure Dart library with no external dependencies. It can be unit-tested without spinning up Dio or a server.

**Consequence:** Every field added to the API response requires changes in three places (model, entity, mapper). This is the explicit cost of the boundary — accepted in exchange for testability and swappability.

---

### Why Riverpod (StateNotifier) and not BLoC?

**Problem:** BLoC requires defining an `Event` sealed class, a `State` sealed class, and an `on<EventType>` handler for each interaction. For a feature like the library list (which has: loading, pagination, search with debounce, mode switching, and deduplication), this adds significant boilerplate.

**Decision:** Use Riverpod's `StateNotifier` + `StateNotifierProvider`. A `StateNotifier` exposes methods directly (e.g., `loadMore()`, `setQuery()`, `clearSearch()`), eliminating the event dispatch indirection. State is a single immutable class with `copyWith()`.

**Consequence:** Less boilerplate, more readable method names. The tradeoff is that `StateNotifier` does not have a built-in event stream, so replaying UI events for debugging requires manual effort (vs. BLoC's built-in `Transition` stream).

---

### Why get_it?

**Problem:** Flutter has no built-in DI container. Passing dependencies down the widget tree via constructors or `InheritedWidget` becomes unwieldy at scale.

**Decision:** Use `get_it` as a service locator. It is simple, has no code generation requirement, and integrates well with Riverpod — providers can call `sl<UseCase>()` to get their dependencies without being nested inside a widget tree.

**Consequence:** `get_it` is a service locator, not a true DI container. Dependencies are pulled by the consumer, not pushed by the container. This makes the dependency graph implicit — you cannot ask get_it to show you the full graph. Accepted for the current scale of the project.

---

### Why go_router with StatefulShellRoute?

**Problem:** The app needs centralized, declarative navigation for detail and reader flows, but it must preserve tab state when users switch between Home, Library, and Settings.

**Decision:** Use `go_router` with `StatefulShellRoute.indexedStack`. This keeps the UX benefit of the previous `IndexedStack` shell while removing scattered imperative navigation and route-switch logic.

**Tradeoff:** The router setup is more explicit and verbose than `Navigator.push`, but it gives a single route table, typed path parameters, and a cleaner path for future deep-link support.

---

### Why FastAPI + external aggregation (no database)?

**Problem:** Building and maintaining a database with manga metadata would require scraping or mirroring MangaDex's content, handling updates, and managing storage — significant operational complexity.

**Decision:** Use FastAPI as a **thin aggregation layer** that proxies and normalizes data from two authoritative external APIs (MangaDex for content, Jikan for editorial metadata). The backend owns no data of its own.

**Consequence:**
- ✅ Zero database infrastructure
- ✅ Always up-to-date data (sourced from live APIs)
- ✅ Simple horizontal scaling (stateless process)
- ⚠️ Latency depends on external API response times
- ⚠️ Subject to external API rate limits and downtime
- ⚠️ In-process cache is not shared across Uvicorn workers

The caching layer (5-minute TTL in-process `SimpleCache`) mitigates the latency and rate-limit concerns for the most common queries (list, detail by ID). The Jikan enrichment is wrapped in a fail-safe `try/except` to ensure that a Jikan outage never breaks the core manga detail endpoint.

---

*End of document.*
