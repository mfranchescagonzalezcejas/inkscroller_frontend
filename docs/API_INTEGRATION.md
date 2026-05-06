# API Integration — Inkscroller

> **Last updated:** April 2026  
> **Backend:** FastAPI 0.1.0 · Python 3.11+  
> **Flutter HTTP client:** Dio  
> **Data sources:** MangaDex API + Jikan API (enrichment layer, internal to backend)

---

## Table of Contents

1. [Overview](#1-overview)
2. [HTTP Client Setup](#2-http-client-setup)
3. [Environments](#3-environments)
4. [Flavor System](#4-flavor-system)
5. [Endpoint Reference](#5-endpoint-reference)
   - [GET /ping](#51-get-ping)
   - [GET /manga](#52-get-manga)
   - [GET /manga/search](#53-get-mangasearch)
   - [GET /manga/{manga_id}](#54-get-mangamanga_id)
   - [GET /chapters/manga/{manga_id}](#55-get-chaptersmangamanga_id)
   - [GET /chapters/{chapter_id}/pages](#56-get-chapterschapter_idpages)
6. [Flutter Data Layer](#6-flutter-data-layer)
7. [Error Handling](#7-error-handling)
8. [Caching](#8-caching)
9. [Adding a New Endpoint](#9-adding-a-new-endpoint)

---

## 1. Overview

The Inkscroller backend is a **FastAPI proxy** that aggregates two external upstream sources:

| Source | Role |
|--------|------|
| **MangaDex API** | Primary source — manga catalog, chapters, page images |
| **Jikan API** (MyAnimeList) | Enrichment layer — fills in score, rank, genres, authors, synopsis when MangaDex data is sparse |

The Flutter app **never calls MangaDex or Jikan directly**. It only talks to the Inkscroller backend, which handles aggregation, mapping, and in-memory caching (TTL: 5 minutes).

```
Flutter App
    │
    ▼ HTTP (Dio)
Inkscroller Backend  ──► MangaDex API
    │                ──► Jikan API (enrichment for /manga/{id})
    ▼
JSON response mapped to Flutter models
```

This document covers the **catalog endpoints** only (`/manga`, `/chapters`). All Dio requests automatically attach a Firebase ID token via the `AuthInterceptor` on `DioClient`. User-specific endpoints (`GET /users/me`, `GET /users/me/preferences`, `PUT /users/me/preferences`) require a valid token and are not covered here — see the `auth` and `preferences` features.

---

## 2. HTTP Client Setup

**File:** `lib/core/network/dio_client.dart`

```dart
class DioClient {
  late final Dio dio;

  DioClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,      // resolved via FlavorConfig singleton
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
  }
}
```

### Key configuration

| Property | Value | Notes |
|----------|-------|-------|
| `baseUrl` | `FlavorConfig.instance.apiBaseUrl` | Resolved at runtime based on active flavor |
| `connectTimeout` | `15s` | Time to establish TCP connection |
| `receiveTimeout` | `15s` | Time to receive the full response body |
| `Content-Type` | `application/json` | Sent on every request |

### Base URL resolution chain

```
main_dev.dart / main_staging.dart / main_pro.dart
    │
    └─► FlavorConfig(flavor: ..., apiBaseUrl: AppEnvironment.apiBaseUrl)
            │
            └─► ApiConfig.baseUrl   (lib/core/config/api_config.dart)
                    │
                    └─► DioClient.BaseOptions.baseUrl
```

**File:** `lib/core/config/api_config.dart`

```dart
class ApiConfig {
  static String get baseUrl => FlavorConfig.instance.apiBaseUrl;
}
```

---

## 3. Environments

| Flavor | Entry Point | Base URL | Notes |
|--------|-------------|----------|-------|
| `dev` | `main_dev.dart` | `--dart-define=API_BASE_URL=...` | Falls back to local LAN URL if omitted |
| `staging` | `main_staging.dart` | `--dart-define=API_BASE_URL=...` | Falls back to local LAN URL if omitted |
| `pro` | `main_pro.dart` | `--dart-define=API_BASE_URL=...` | Must be set to public API for release |

> **Note:** If `API_BASE_URL` is omitted, the app uses `http://192.168.1.38:8000` as a developer-friendly default.

**File:** `lib/core/config/app_environment.dart`

```dart
abstract final class AppEnvironment {
  static const String localBaseUrl = 'http://192.168.1.38:8000';

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: localBaseUrl,
  );
}
```

---

## 4. Flavor System

**File:** `lib/flavors/flavor_config.dart`

`FlavorConfig` is a **singleton** initialized at app startup. It must be initialized before any network call is made.

```dart
enum Flavor { dev, staging, pro }

class FlavorConfig {
  final Flavor flavor;
  final String apiBaseUrl;
  final String name;
  // ...
  static bool isDev()     => instance.flavor == Flavor.dev;
  static bool isStaging() => instance.flavor == Flavor.staging;
  static bool isPro()     => instance.flavor == Flavor.pro;
}
```

Each `main_*.dart` initializes the singleton before `runApp`:

```dart
// main_dev.dart
await mainCommon(
  flavor: Flavor.dev,
  apiBaseUrl: AppEnvironment.apiBaseUrl,
  name: AppConstants.appName,
);
```

> ⚠️ If `FlavorConfig` is not initialized before `DioClient` is constructed, it will throw `Exception('FlavorConfig not initialized')`.

---

## 5. Endpoint Reference

### Flutter endpoint constants

**File:** `lib/core/constants/api_endpoints.dart`

```dart
class ApiEndpoints {
  static const manga          = '/manga';
  static const chaptersByManga = '/chapters/manga';
  static const chapterPages   = '/chapters';
}
```

---

### 5.1 GET /ping

**Health check.** Verifies the backend is reachable.

#### Parameters
None.

#### curl example
```bash
curl http://192.168.1.38:8000/ping
```

#### Response

**HTTP 200 OK**

```json
{ "ok": true }
```

| Field | Type | Description |
|-------|------|-------------|
| `ok` | `boolean` | Always `true` when the server is up |

#### Flutter data source
Not called by a dedicated data source. Suitable for a connectivity check or startup validation.

---

### 5.2 GET /manga

**Paginated manga list.** Returns a page of manga summaries with total count for pagination UI.

#### Query parameters

| Name | Type | Required | Default | Constraints | Description |
|------|------|----------|---------|-------------|-------------|
| `limit` | `int` | No | `20` | `1–100` | Number of results per page |
| `offset` | `int` | No | `0` | `≥ 0` | Zero-based pagination offset |
| `title` | `string` | No | — | — | Filter by title (partial match) |
| `demographic` | `string` | No | — | `shounen`, `shoujo`, `josei`, `seinen` | Filter by target demographic |
| `status` | `string` | No | — | `ongoing`, `completed`, `hiatus`, `cancelled` | Filter by publication status |
| `order` | `string` | No | — | — | Sort order (forwarded to MangaDex) |

#### curl example
```bash
curl "http://192.168.1.38:8000/manga?limit=20&offset=0"

# With filters
curl "http://192.168.1.38:8000/manga?limit=10&offset=20&demographic=shounen&status=ongoing"
```

#### Response

**HTTP 200 OK**

```json
{
  "data": [
    {
      "id": "a1c7c817-4e59-43b7-9365-09675a149a6f",
      "title": "One Piece",
      "description": "Gol D. Roger was known as the Pirate King...",
      "coverUrl": "https://uploads.mangadex.org/covers/a1c7c817-4e59-43b7-9365-09675a149a6f/cover.256.jpg",
      "demographic": "shounen",
      "status": "ongoing",
      "genres": ["action", "adventure", "comedy"],
      "score": 9.2,
      "rank": 2,
      "popularity": 1,
      "members": 850000,
      "favorites": 120000,
      "authors": ["Oda Eiichiro"],
      "serialization": "Weekly Shounen Jump",
      "chapters": 1100,
      "startYear": 1997,
      "endYear": null
    }
  ],
  "limit": 20,
  "offset": 0,
  "total": 4821
}
```

#### Response model

**Envelope:**

| Field | Type | Description |
|-------|------|-------------|
| `data` | `Manga[]` | Array of manga objects |
| `limit` | `int` | Echoes the requested limit |
| `offset` | `int` | Echoes the requested offset |
| `total` | `int` | Total number of matching manga (use for pagination math) |

**`Manga` object:**

| Field | Type | Nullable | Source | Description |
|-------|------|----------|--------|-------------|
| `id` | `string` | No | MangaDex | Unique MangaDex UUID |
| `title` | `string` | No | MangaDex | English title, falls back to first available language |
| `description` | `string` | Yes | MangaDex / Jikan | English synopsis |
| `coverUrl` | `string` | Yes | MangaDex | Thumbnail URL (256px JPEG) |
| `demographic` | `string` | Yes | MangaDex / Jikan | `shounen`, `shoujo`, `josei`, `seinen` |
| `status` | `string` | Yes | MangaDex / Jikan | `ongoing`, `completed`, `hiatus`, `cancelled` |
| `genres` | `string[]` | No | Jikan | List of genre names (lowercase) |
| `score` | `float` | Yes | Jikan | MyAnimeList score (0–10) |
| `rank` | `int` | Yes | Jikan | MyAnimeList rank |
| `popularity` | `int` | Yes | Jikan | Popularity rank |
| `members` | `int` | Yes | Jikan | Number of MAL members tracking it |
| `favorites` | `int` | Yes | Jikan | Number of MAL favorites |
| `authors` | `string[]` | No | Jikan | Author names |
| `serialization` | `string` | Yes | Jikan | Magazine/serialization name |
| `chapters` | `int` | Yes | MangaDex | Total chapter count |
| `startYear` | `int` | Yes | Jikan | Year publication started |
| `endYear` | `int` | Yes | Jikan | Year publication ended (`null` if ongoing) |

> **Note:** The `list_manga` endpoint does **not** call Jikan for enrichment. Jikan enrichment only happens on `GET /manga/{id}`. The list returns MangaDex data only, so `genres`, `score`, `authors`, etc. will be empty/null.

#### Flutter data source
```dart
// lib/features/library/data/datasources/library_remote_ds_impl.dart
Future<List<MangaModel>> getMangaList({
  required int limit,
  required int offset,
  Map<String, String>? order,
})
```

**Flutter `MangaModel` fields** (subset mapped from full response):

| Dart field | JSON key | Type |
|------------|----------|------|
| `id` | `id` | `String` |
| `title` | `title` | `String` |
| `description` | `description` | `String?` |
| `coverUrl` | `coverUrl` | `String?` |
| `demographic` | `demographic` | `String?` |
| `status` | `status` | `String?` |
| `genres` | `genres` | `List<String>` |
| `score` | `score` | `double?` |

---

### 5.3 GET /manga/search

**Manga search.** Quick lookup returning up to 5 results. Optimized for search-as-you-type UI.

> ⚠️ **Route ordering:** `/manga/search` **must** be registered before `/manga/{manga_id}` in the FastAPI router, otherwise FastAPI will interpret `search` as a `manga_id`. The backend already handles this correctly.

#### Query parameters

| Name | Type | Required | Default | Constraints | Description |
|------|------|----------|---------|-------------|-------------|
| `q` | `string` | **Yes** | — | `min_length=1` | Search query string |

#### curl example
```bash
curl "http://192.168.1.38:8000/manga/search?q=berserk"
```

#### Response

**HTTP 200 OK** — returns a plain array (no envelope wrapper)

```json
[
  {
    "id": "801513ba-a712-498c-8f57-cae55b38cc92",
    "title": "Berserk",
    "description": "Guts, a former mercenary now known as the 'Black Swordsman'...",
    "coverUrl": "https://uploads.mangadex.org/covers/801513ba-a712-498c-8f57-cae55b38cc92/cover.256.jpg",
    "demographic": "seinen",
    "status": "ongoing",
    "genres": [],
    "score": null,
    "rank": null,
    "popularity": null,
    "members": null,
    "favorites": null,
    "authors": [],
    "serialization": null,
    "chapters": null,
    "startYear": null,
    "endYear": null
  }
]
```

> **Note:** Search results come from MangaDex only (no Jikan enrichment). `genres`, `score`, `authors`, etc. will be empty/null.

**HTTP 422 Unprocessable Entity** — if `q` is missing or empty:
```json
{
  "detail": [
    {
      "loc": ["query", "q"],
      "msg": "field required",
      "type": "value_error.missing"
    }
  ]
}
```

#### Flutter data source
```dart
Future<List<MangaModel>> searchManga(String query)
```

The Flutter implementation defensively handles both a plain `List` response and a `Map` with a `data` key:
```dart
final body = response.data;
final List<dynamic> rawList;
if (body is List) {
  rawList = body;
} else if (body is Map<String, dynamic>) {
  rawList = (body['data'] as List<dynamic>?) ?? <dynamic>[];
} else {
  rawList = <dynamic>[];
}
```

---

### 5.4 GET /manga/{manga_id}

**Manga detail.** Returns the full manga object for a single title, enriched with Jikan data.

#### Path parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `manga_id` | `string` | **Yes** | MangaDex UUID (e.g. `a1c7c817-4e59-43b7-9365-09675a149a6f`) |

> The backend automatically strips leading/trailing whitespace from `manga_id`.

#### curl example
```bash
curl "http://192.168.1.38:8000/manga/a1c7c817-4e59-43b7-9365-09675a149a6f"
```

#### Response

**HTTP 200 OK**

```json
{
  "id": "a1c7c817-4e59-43b7-9365-09675a149a6f",
  "title": "One Piece",
  "description": "Gol D. Roger was known as the Pirate King, the strongest and most infamous being to have sailed the Grand Line...",
  "coverUrl": "https://uploads.mangadex.org/covers/a1c7c817-4e59-43b7-9365-09675a149a6f/cover.256.jpg",
  "demographic": "shounen",
  "status": "ongoing",
  "genres": ["action", "adventure", "comedy", "drama", "fantasy"],
  "score": 9.2,
  "rank": 2,
  "popularity": 1,
  "members": 850000,
  "favorites": 120000,
  "authors": ["Oda Eiichiro"],
  "serialization": "Weekly Shounen Jump",
  "chapters": 1100,
  "startYear": 1997,
  "endYear": null
}
```

**HTTP 404 Not Found**

```json
{ "detail": "Manga not found" }
```

#### Response model
Same `Manga` object as described in [§5.2](#52-get-manga). On this endpoint, Jikan enrichment **is applied** — `genres`, `score`, `rank`, `authors`, etc. will be populated when available.

**Enrichment logic:** MangaDex fields take priority. Jikan only fills fields that MangaDex left as `null`, `[]`, or `""`.

#### Flutter data source
```dart
Future<MangaModel> getMangaDetail(String mangaId)
```

---

### 5.5 GET /chapters/manga/{manga_id}

**Chapter list for a manga.** Returns all readable (or externally-linked) chapters for a given manga in a specified language.

> **Filtering:** Only chapters with at least 1 page OR an `externalUrl` are returned. Chapters with 0 pages and no external URL are silently dropped by the backend.

#### Path parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `manga_id` | `string` | **Yes** | MangaDex UUID of the manga |

#### Query parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `lang` | `string` | No | `"en"` | Language code (`en`, `es`, `fr`, `pt-br`, etc.) |

#### curl example
```bash
curl "http://192.168.1.38:8000/chapters/manga/a1c7c817-4e59-43b7-9365-09675a149a6f"

# Spanish chapters
curl "http://192.168.1.38:8000/chapters/manga/a1c7c817-4e59-43b7-9365-09675a149a6f?lang=es"
```

#### Response

**HTTP 200 OK**

```json
[
  {
    "id": "e86ec2c4-c5e4-4710-bfaa-7604f00939c7",
    "number": "1",
    "title": "Romance Dawn",
    "date": "2021-04-10T13:27:57+00:00",
    "readable": true,
    "external": false,
    "externalUrl": null
  },
  {
    "id": "b3c7892a-1234-5678-abcd-ef0123456789",
    "number": "1100",
    "title": null,
    "date": "2024-02-18T09:00:00+00:00",
    "readable": false,
    "external": true,
    "externalUrl": "https://mangaplus.shueisha.co.jp/viewer/1234567"
  }
]
```

**HTTP 404 Not Found** — if no chapters exist for the given manga + language:
```json
{ "detail": "No chapters found" }
```

#### Response model — `Chapter` object

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `id` | `string` | No | MangaDex chapter UUID |
| `number` | `string` | Yes | Chapter number as string (e.g. `"1"`, `"10.5"`) |
| `title` | `string` | Yes | Chapter title (often `null`) |
| `date` | `string (ISO 8601)` | Yes | Publication date with timezone |
| `readable` | `boolean` | No | `true` if pages are available via `/pages` endpoint |
| `external` | `boolean` | No | `true` if chapter is hosted on an external site (e.g. MangaPlus) |
| `externalUrl` | `string` | Yes | External reader URL (only present when `external: true`) |

#### Flutter data source
```dart
Future<List<ChapterModel>> getMangaChapters(String mangaId)
```

**Flutter `ChapterModel`:**

| Dart field | JSON key | Type |
|------------|----------|------|
| `id` | `id` | `String` |
| `number` | `number` | `String?` |
| `title` | `title` | `String?` |
| `date` | `date` | `DateTime?` (parsed via `DateTime.tryParse`) |
| `readable` | `readable` | `bool` |
| `external` | `external` | `bool` |
| `externalUrl` | `externalUrl` | `String?` |

---

### 5.6 GET /chapters/{chapter_id}/pages

**Chapter page images.** Returns the full list of page image URLs for an in-app-readable chapter. Page URLs are constructed from the MangaDex @ Home CDN.

> ⚠️ **Check `readable` before calling this endpoint.** If `ChapterModel.readable == false`, this endpoint will return `external: true` with an empty pages array. The Flutter client raises an exception in this case — always check the chapter's `readable` flag from the chapter list first.

#### Path parameters

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `chapter_id` | `string` | **Yes** | MangaDex chapter UUID |

#### curl example
```bash
curl "http://192.168.1.38:8000/chapters/e86ec2c4-c5e4-4710-bfaa-7604f00939c7/pages"
```

#### Response

**HTTP 200 OK — Readable chapter**

```json
{
  "readable": true,
  "external": false,
  "pages": [
    "https://uploads.mangadex.org/data/abc123hash/x1-page001.jpg",
    "https://uploads.mangadex.org/data/abc123hash/x2-page002.jpg",
    "https://uploads.mangadex.org/data/abc123hash/x3-page003.jpg"
  ]
}
```

**HTTP 200 OK — External-only chapter** (chapter hosted on MangaPlus or similar)

```json
{
  "readable": false,
  "pages": [],
  "external": true
}
```

> The backend returns HTTP 200 even for external chapters — it does **not** return 404. The Flutter client treats `external: true` as an exception.

**HTTP 404 Not Found** — if MangaDex can't find the chapter at all, the backend also returns the external fallback:
```json
{
  "readable": false,
  "pages": [],
  "external": true
}
```

#### Response model

| Field | Type | Description |
|-------|------|-------------|
| `readable` | `boolean` | `true` if `pages` contains URLs |
| `external` | `boolean` | `true` if chapter is only available externally |
| `pages` | `string[]` | Ordered list of full image URLs (empty if `external: true`) |

Page URL format:
```
{baseUrl}/data/{hash}/{filename}
```
Example: `https://uploads.mangadex.org/data/abc123.../x1-cover.jpg`

#### Flutter data source
```dart
Future<List<String>> getChapterPages(String chapterId)
```

The Flutter implementation parses the response and throws if the chapter is external:
```dart
final data = response.data!;
if (data['external'] == true) {
  throw Exception('Chapter is external only');
}
return List<String>.from(data['pages']);
```

---

## 6. Flutter Data Layer

All HTTP calls go through a single abstract interface, `LibraryRemoteDataSource`, with one concrete implementation.

### Architecture

```
UI / Riverpod (StateNotifier)
      │
      ▼
LibraryRemoteDataSource          ← abstract interface
      │
      ▼
LibraryRemoteDataSourceImpl      ← injects Dio, calls backend
      │
      ▼
DioClient.dio                    ← configured Dio instance
      │
      ▼
Inkscroller Backend (HTTP)
```

### Interface

**File:** `lib/features/library/data/datasources/library_remote_ds.dart`

```dart
abstract class LibraryRemoteDataSource {
  Future<List<MangaModel>> getMangaList({
    required int limit,
    required int offset,
    Map<String, String>? order,
  });

  Future<MangaModel> getMangaDetail(String mangaId);

  Future<List<ChapterModel>> getMangaChapters(String mangaId);

  Future<List<String>> getChapterPages(String chapterId);

  Future<List<MangaModel>> searchManga(String query);
}
```

### Method → Endpoint mapping

| Method | HTTP call | Endpoint |
|--------|-----------|----------|
| `getMangaList(limit, offset)` | `GET /manga?limit=N&offset=N` | [§5.2](#52-get-manga) |
| `getMangaDetail(mangaId)` | `GET /manga/{manga_id}` | [§5.4](#54-get-mangamanga_id) |
| `searchManga(query)` | `GET /manga/search?q=...` | [§5.3](#53-get-mangasearch) |
| `getMangaChapters(mangaId)` | `GET /chapters/manga/{manga_id}` | [§5.5](#55-get-chaptersmangamanga_id) |
| `getChapterPages(chapterId)` | `GET /chapters/{chapter_id}/pages` | [§5.6](#56-get-chapterschapter_idpages) |

---

## 7. Error Handling

### Backend-level errors

The FastAPI backend uses standard HTTP status codes:

| Code | When | Body |
|------|------|------|
| `200` | Success | Response payload |
| `404` | Resource not found (`/manga/{id}`, `/chapters/manga/{id}`) | `{ "detail": "..." }` |
| `422` | Validation error (missing required param, out-of-range value) | FastAPI error detail array |
| `500` | Unhandled exception in backend | FastAPI default error body |

> External chapter pages (MangaDex 404) are normalized to HTTP 200 with `{ "readable": false, "external": true, "pages": [] }`. The Flutter client handles this as an application-level exception.

### Flutter-level: current state

The data source implementation now **does catch `DioException`** in the remote data source layer and maps them to app-level exceptions.

- `lib/features/library/data/datasources/library_remote_ds_impl.dart` catches `DioException`
- transport failures are mapped to `NetworkException`
- backend responses with error status are mapped to `ServerException`
- unexpected failures are mapped to `UnexpectedException`

Current pattern:

```dart
// Current approach: catch DioException in the remote data source
Future<MangaModel> getMangaDetail(String mangaId) async {
  try {
    final response = await dio.get<Map<String, dynamic>>(
      '${ApiEndpoints.manga}/$mangaId',
    );
    return MangaModel.fromJson(response.data!);
  } on DioException catch (error) {
    throw _mapDioException(error);
  }
}
```

An interceptor-based error mapper is still a valid future refactor, but it is **not** the current implementation.

### Common `DioException` types

| `DioExceptionType` | Cause | Suggested handling |
|--------------------|-------|--------------------|
| `connectionTimeout` | Server unreachable within 15s | Show offline/retry UI |
| `receiveTimeout` | Response too slow | Show timeout message |
| `badResponse` | 4xx / 5xx status code | Check `e.response?.statusCode` |
| `connectionError` | No network / DNS failure | Show no-connection state |
| `cancel` | Request was cancelled | Silently ignore |

---

## 8. Caching

Caching is handled in **two layers**:

1. **Server-side**, in the FastAPI backend using an in-memory `SimpleCache`
2. **Client-side**, in Flutter for selected library payloads using `SharedPreferences`

| Service | Cache TTL | Cache key pattern |
|---------|-----------|-------------------|
| `MangaService.list_manga` | 5 min | `manga:list:{limit}:{offset}:{title}:{demographic}:{status}:{order}` |
| `MangaService.search` | 5 min | `search:{query}:{limit}` |
| `MangaService.get_by_id` | 5 min | `manga:{manga_id}` |
| `ChapterService.get_chapters` | 5 min | `chapters:{manga_id}:{language}` |
| `ChapterPagesService.get_pages` | 5 min | `pages:{chapter_id}` |

The Flutter app **does** implement local caching for the library flow.

- `lib/features/library/data/datasources/library_local_ds_impl.dart` persists cached payloads in `SharedPreferences`
- `lib/features/library/data/repositories/library_repository_impl.dart` writes successful responses to cache
- when remote calls fail with `AppException`, the repository attempts a cache fallback for manga list, manga detail, and chapter list

Current behavior:

| Surface | Local cache | Fallback on remote failure |
|---------|-------------|----------------------------|
| Manga list | Yes | Yes |
| Manga detail | Yes | Yes |
| Chapter list | Yes | Yes |
| Chapter pages | No | No |
| Search | No | No |

The backend still keeps its own in-memory `SimpleCache`, so the current system is **server-side cache + Flutter local cache** for selected library endpoints.

---

## 9. Adding a New Endpoint

Follow these steps when adding a new API endpoint to both the backend and the Flutter client.

### Step 1 — Backend: create the route

Create or add to an existing router file under `app/api/`:

```python
# app/api/authors.py
from fastapi import APIRouter
from app.services.author_service import AuthorService

router = APIRouter(prefix="/authors", tags=["Authors"])
service = AuthorService()

@router.get("/{author_id}")
async def get_author(author_id: str):
    author_id = author_id.strip()
    author = await service.get_by_id(author_id)
    if author is None:
        raise HTTPException(status_code=404, detail="Author not found")
    return author
```

### Step 2 — Backend: register the router

Add the new router to `main.py`:

```python
# main.py
from app.api.authors import router as authors_router

app.include_router(authors_router)
```

### Step 3 — Backend: add a Pydantic response model

Add to `app/models/` to get automatic validation and OpenAPI docs:

```python
# app/models/author.py
from pydantic import BaseModel
from typing import Optional

class Author(BaseModel):
    id: str
    name: str
    biography: Optional[str] = None
```

Update the route to declare the response model:
```python
@router.get("/{author_id}", response_model=Author)
```

### Step 4 — Flutter: add the endpoint constant

**File:** `lib/core/constants/api_endpoints.dart`

```dart
class ApiEndpoints {
  static const manga          = '/manga';
  static const chaptersByManga = '/chapters/manga';
  static const chapterPages   = '/chapters';
  static const authors        = '/authors';   // ← add this
}
```

### Step 5 — Flutter: create a response model

```dart
// lib/features/library/data/models/author_model.dart
class AuthorModel {
  final String id;
  final String name;
  final String? biography;

  const AuthorModel({
    required this.id,
    required this.name,
    this.biography,
  });

  factory AuthorModel.fromJson(Map<String, dynamic> json) {
    return AuthorModel(
      id: json['id'] as String,
      name: json['name'] as String,
      biography: json['biography'] as String?,
    );
  }
}
```

### Step 6 — Flutter: add the method to the abstract data source

```dart
// lib/features/library/data/datasources/library_remote_ds.dart
abstract class LibraryRemoteDataSource {
  // ... existing methods ...
  Future<AuthorModel> getAuthor(String authorId);  // ← add this
}
```

### Step 7 — Flutter: implement the method

```dart
// lib/features/library/data/datasources/library_remote_ds_impl.dart
@override
Future<AuthorModel> getAuthor(String authorId) async {
  final response = await dio.get<Map<String, dynamic>>(
    '${ApiEndpoints.authors}/$authorId',
  );
  return AuthorModel.fromJson(response.data!);
}
```

### Step 8 — Verify

1. Run the FastAPI server and open `http://192.168.1.38:8000/docs` — your new endpoint should appear in the Swagger UI
2. Test with curl: `curl http://192.168.1.38:8000/authors/{some_id}`
3. Call the Flutter data source method and verify the model maps correctly

---

## Appendix: Full Endpoint Summary

| Method | Path | Flutter method | Description |
|--------|------|----------------|-------------|
| `GET` | `/ping` | — | Health check |
| `GET` | `/manga` | `getMangaList()` | Paginated manga list |
| `GET` | `/manga/search?q=` | `searchManga()` | Quick search (max 5 results) |
| `GET` | `/manga/{manga_id}` | `getMangaDetail()` | Full manga detail with Jikan enrichment |
| `GET` | `/chapters/manga/{manga_id}` | `getMangaChapters()` | Chapter list for a manga |
| `GET` | `/chapters/{chapter_id}/pages` | `getChapterPages()` | Page image URLs for reader |
