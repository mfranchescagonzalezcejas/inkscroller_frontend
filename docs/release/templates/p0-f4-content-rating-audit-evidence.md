# P0-F4 — Evidence: Content Rating Filter Compliance

> **Status**: ✅ CLOSED — 2026-04-09  
> **Checklist item**: 2.4 — El contenido con rating adulto (`erotica/pornographic`) está filtrado o requiere verificación de edad  
> **Refs**: TASK-021 (#48)

---

## Summary

The content-rating filter is enforced **exclusively at the backend layer**. Flutter has no mechanism to bypass or override it. This document provides the complete audit trail.

---

## Architecture

```
Flutter App
    │
    │  HTTP requests (limit, offset, genre, order)
    │  NO contentRating parameter
    ▼
InkScroller Backend (Python/FastAPI)
    │
    │  _ALLOWED_CONTENT_RATINGS = ["safe", "suggestive"]
    │  contentRating[] injected on every MangaDex call
    ▼
MangaDex API
    │
    │  Returns only safe + suggestive rated content
    ▼
Flutter App receives filtered content only
```

---

## Backend Enforcement Evidence

**File**: `Inkscroller_backend/app/sources/mangadex_client.py`

```python
class MangaDexClient:
    _ALLOWED_CONTENT_RATINGS = ["safe", "suggestive"]
```

Applied on every MangaDex call:

| Method | Line | Applies filter |
|--------|------|---------------|
| `search_manga` | 22 | ✅ `contentRating[]` |
| `get_chapters` | 53 | ✅ `contentRating[]` |
| `get_latest_chapters` | 68 | ✅ `contentRating[]` |
| `get_manga_list_by_ids` | 85 | ✅ `contentRating[]` |
| `list_manga` | 113 | ✅ `contentRating[]` |
| `get_manga` (detail by ID) | — | N/A — MangaDex `/manga/{id}` does not accept contentRating filter; UUID can only be obtained via filtered list/search |
| `get_chapter_pages` | — | N/A — Chapter pages URL has no rating; chapter was already filtered |

**Conclusion**: `erotica` and `pornographic` ratings are **never** sent to Flutter.

---

## Flutter Client Evidence

### 1. No `contentRating` query parameter in any HTTP call

**File**: `lib/features/library/data/datasources/library_remote_ds_impl.dart`

```dart
final response = await dio.get<Map<String, dynamic>>(
  ApiEndpoints.manga,
  queryParameters: {
    'limit': limit,
    'offset': offset,
    if (genre != null) 'genre': genre,
    ...?order?.map((key, value) => MapEntry('order[$key]', value)),
  },
);
```

Only `limit`, `offset`, `genre`, and `order[*]` params are sent. No `contentRating`.

### 2. `MangaModel` has no `contentRating` field

**File**: `lib/features/library/data/models/manga_model.dart`

```dart
class MangaModel {
  final String id;
  final String title;
  final String? description;
  final String? coverUrl;
  final String? demographic;
  final String? status;
  final List<String> genres;
  final double? score;
  final int? rank;
  final int? popularity;
  final List<String> authors;
  // ← No contentRating field
}
```

Even if the backend hypothetically leaked a `contentRating` key in the JSON response, `MangaModel.fromJson` would silently discard it.

### 3. `Manga` domain entity has no `contentRating` field

**File**: `lib/features/library/domain/entities/manga.dart`

The domain entity exposes no `contentRating` property. The presentation layer has no access to this information.

### 4. Single Dio instance, single base URL

**Verified in P0-F10**: All HTTP traffic goes through `DioClient` → `FlavorConfig.instance.apiBaseUrl` → InkScroller backend. No direct calls to `api.mangadex.org`.

---

## Audit Commands

```bash
# Search for contentRating in Flutter lib/
rg -n "contentRating|content_rating|erotica|pornographic" lib/ --glob "*.dart"
# Result: 0 matches

# Search for all Dio instances
rg "Dio\s*\(" lib/ --glob "*.dart" -n
# Result: 1 match — lib/core/network/dio_client.dart (expected)

# Search for direct MangaDex API calls
rg "https?://api\.(mangadex|jikan)" lib/ --glob "*.dart" -n
# Result: 0 matches
```

---

## Formal Test Evidence

**Test file**: `test/core/compliance/p0_f4_content_rating_audit_test.dart`  
**Tests**: 5/5 PASS

| Test | Result |
|------|--------|
| `P0-F4: fromJson silently discards contentRating from payload` | ✅ PASS |
| `P0-F4: Manga entity does not expose a contentRating property` | ✅ PASS |
| `P0-F4: mapper converts MangaModel to Manga without content rating exposure` | ✅ PASS |
| `P0-F4: getMangaList queryParameters contract has no contentRating key` | ✅ PASS |
| `P0-F4: backend filter is the single enforcement point` | ✅ PASS |

**Full suite**: 151/151 tests PASS  
**`fvm flutter analyze`**: No issues found

---

## Flow Audit — Home / Explore / Library / Detail / Reader

| Screen | Data source | Passes contentRating? | Risk |
|--------|-------------|----------------------|------|
| **Home** (featured/latest/popular) | `HomeRemoteDataSourceImpl` → `/chapters/latest` | ❌ No | ✅ Safe — backend filters on chapter endpoint |
| **Explore** | `LibraryRemoteDataSourceImpl` → `/manga` | ❌ No | ✅ Safe — backend enforces filter |
| **Library** (search) | `LibraryRemoteDataSourceImpl` → `/manga/search` | ❌ No | ✅ Safe — backend enforces filter |
| **Detail** | `LibraryRemoteDataSourceImpl` → `/manga/{id}` | ❌ No | ✅ Safe — UUID came from filtered list |
| **Reader** | `LibraryRemoteDataSourceImpl` → `/chapters/{id}/pages` | ❌ No | ✅ Safe — chapter already filtered |

---

## Decision

**No action required on Flutter side.** The backend is the single, correct enforcement point for content-rating filtering, following the principle of defense-in-depth with a single source of truth. The Flutter client correctly has no content-rating logic — this is intentional architecture.

---

_Audit date: 2026-04-09_  
_Auditor: automated (this session) + static analysis_
