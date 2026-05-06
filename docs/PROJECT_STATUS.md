# InkScroller Flutter — Project Status

> **Cross-repo source of truth:** Obsidian under `1-PROJECTS/InkScroller/`
> **Repo role:** frontend implementation status for the Flutter app
> **Last updated:** 2026-04-10 (Sprint 3 in progress — post TASK-027 lib structure alignment)

---

## 1. Purpose of this document

This file is the **frontend-side status mirror** of the product's shared planning.

- Use **Obsidian** for product planning, tasks, sprint tracking, and cross-repo decisions
- Use this file for **frontend implementation reality**
- Treat `docs/PRD/phase-5-*.md` as **historical/planning snapshots** (not live status)
- If this file disagrees with Obsidian, update one of them immediately

---

## 2. Current phase

| Field | Value |
|------|-------|
| Product phase | Phase 6 — Visual Refresh |
| Frontend phase state | **Sprint 3 in progress** |
| Current sprint mirror | Sprint 3 — **active** |
| Repo status | Active |
| Current branch | `chore/task-027-lib-structure-alignment` → target `master` |
| Version | v0.5.0+21 |
| Total tests | 97+ passing |

---

## 3. Completed in this repo

### M2 — Flutter auth foundation

- Firebase Auth module is present
- Sign-in and sign-up pages exist
- Route guard exists
- `AuthNotifier` exists
- Auth token provider is wired through DI / use case flow

### M3 — Complete (merged 2026-04-05)

| Item | Status | PR |
|------|--------|-----|
| `features/preferences` — Clean Arch | ✅ Done | #30 |
| `features/profile` — Clean Arch | ✅ Done | #33 |
| `ProfilePage` | ✅ Done | #33 |
| Adaptive reader — VerticalReaderView | ✅ Done | #33 |
| Adaptive reader — PagedReaderView | ✅ Done | #33 |
| `ResolveReaderMode` use case — connected to flow | ✅ Done | #34 |
| `ResolveReaderMode` unit tests | ✅ Done | #34 |
| Local-first preferences (SharedPreferences) | ✅ Done | #35 |
| Offline conflict resolution (timestamp comparison) | ✅ Done | #35 |
| Per-title reader mode override (MangaDetailPage) | ✅ Done | #39 |
| Profile resilient offline (non-blocking banner) | ✅ Done | #37 |
| Clear preferences on logout | ✅ Done | #38 |
| `PreferencesNotifier` tests | ✅ Done | #36 |
| `UserProfileNotifier` tests | ✅ Done | #36 |
| Navigation — 3 tabs (Home, Library, Profile) | ✅ Done | #33 |
| Settings as sub-route | ✅ Done | #33 |

### Existing product foundation already in place

- Library flow (`/manga`, `/manga/search`, detail, chapters, reader)
- Local library cache and fallback behavior
- Shared Android Studio run configs + bootstrap script
- Localization (en/es)
- Firebase Analytics screen tracking
- IPv4 forced for LAN connectivity
- Physical device setup docs (`docs/PHYSICAL_DEVICE.md`)

---

## 4. Remaining work in this repo

| Item | Priority | Notes |
|------|----------|-------|
| Manga type field (manga/manhwa/manhua) | Medium | Need backend to provide `originalLanguage` field - currently uses placeholder |
| Explore screen redesign | Medium | Sprint 3 active workstream |
| Manga Detail redesign | Medium | Sprint 3 active workstream |
| Profile redesign | Low | Sprint 3 active workstream |
| Reader Settings redesign | Low | Sprint 3 active workstream |
| Offline mode (connectivity logic) | Low | `connectivity_plus` in pubspec, no feature logic |
| Reader performance optimization | Low | Pre-caching improvements, lazy loading |

---

## 5. Cross-repo dependencies

### Consumed from backend

| Contract | Status | Notes |
|---------|--------|-------|
| Public manga API | ✅ Available | Working locally |
| `/users/me` | ✅ Implemented | Live validation pending Firebase env |
| `/users/me/preferences` | ✅ Implemented | Required for real preference sync |
| Firebase token verification | ✅ Implemented | Requires backend env config |
| Deploy target / stable URLs | ✅ Deployed & tested | Google Cloud (Cloud Run) — 3 environments deployed and validated on physical device (2026-04-06) |

### Backend URL Configuration

El frontend usa `app_environment.dart` para manejar múltiples environments:

```dart
// lib/core/config/app_environment.dart
static const String localBaseUrl = 'http://127.0.0.1:8000';
static const String androidEmulatorBaseUrl = 'http://10.0.2.2:8000';

// Cloud Run deployment URLs:
static const String cloudRunBaseUrl = 'https://inkscroller-backend-xxx.us-central1.run.app';
```

#### Deployment URLs por Flavor

| Flavor | Firebase Project | Backend URL | Run Config |
|--------|------------------|-------------|------------|
| dev | `inkscroller-aed59` | `localhost:8000` (local) / Cloud Run | Dev Physical / Dev Physical (Cloud Run) |
| staging | `inkscroller-stg` | Cloud Run | Staging Physical (Cloud Run) |
| prod | `inkscroller-8fa87` | Cloud Run | Pro Physical (Cloud Run) |

#### Cloud Run URLs (production)

| Environment | URL |
|------------|-----|
| dev | `https://inkscroller-backend-708894048002.us-central1.run.app` |
| staging | `https://inkscroller-backend-391760656950.us-central1.run.app` |
| prod | `https://inkscroller-backend-806863502436.us-central1.run.app` |

#### Run Configurations Actualizadas

Los `.run` configs para staging y prod ahora usan Cloud Run URL:
- `Flutter Staging Physical.run.xml` → Cloud Run URL
- `Flutter Pro Physical.run.xml` → Cloud Run URL

Para development local, seguir usando `localhost` o IP LAN (`192.168.1.38:8000`).

### What this repo provides to product flow

- Auth UI / auth state handling
- Route protection
- Consumer of manga and preferences APIs
- Profile/preferences UI and adaptive reader UI
- Per-title reading preferences (local-first)

---

## 6. Known blockers / validation gaps

| Topic | Type | Impact |
|------|------|--------|
| Staging `/users/me` returns error for new users | validation | Expected — user doesn't exist in staging Firebase project yet |

---

## 7. Source-of-truth links

### Obsidian

- `InkScroller/Gestión/Gestión del proyecto.md`
- `InkScroller/Gestión/Matriz de dependencias cross-repo.md`
- `InkScroller/Gestión/Protocolo de sincronización cross-repo.md`
- `InkScroller/Sprints/Sprint 2.md`
- `InkScroller/Tareas/_Índice de tareas.md`
- `InkScroller/QA/_Índice de QA.md`

### Repo docs

- `docs/PRD.md`
- `docs/PRD/phase-5-identity-and-adaptive-reading.md`
- `docs/PRD/phase-5-execution-plan.md`
- `docs/API_INTEGRATION.md`
- `docs/ANDROID_STUDIO_SETUP.md`
- `docs/PHYSICAL_DEVICE.md`

---

## 8. Update rules

Update this file when:

1. a frontend milestone moves state (`todo` → `in progress` → `done`)
2. a backend dependency changes frontend sequencing
3. local validation gaps become real end-to-end validated flows
4. the active phase or sprint changes

Do **not** use this file as the main task tracker. That lives in Obsidian.
