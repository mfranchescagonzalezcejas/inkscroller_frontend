# InkScroller — Product Requirements Document

> **Last updated:** April 2026
> **Stack:** Flutter (Dart) + FastAPI (Python)
> **Architecture reference:** [docs/ARCHITECTURE.md](ARCHITECTURE.md)
> **Design source of truth (Phase 6):** [`design/DESIGN.md`](../design/DESIGN.md) + screen mockups under [`design/`](../design/)

---

## Product Vision

InkScroller is a cross-platform manga reading app that aggregates content from MangaDex and MyAnimeList (via Jikan), presenting it through a clean, fast, and maintainable mobile experience. The long-term goal is a production-ready reader with offline support, rich metadata, and a scalable codebase that can grow without accumulating technical debt.

---

## Roadmap

| Phase | Name | Status | Detail |
|-------|------|--------|--------|
| 1 | Architecture Foundations | [Completed] | Clean Architecture, Riverpod, get_it, go_router, env config |
| 2 | Testing Infrastructure | [Completed] | Unit, widget, and integration test coverage; CI quality gate |
| 3 | UX & Feature Expansion | [Completed] | Offline cache, localization, settings, pagination, CI/CD pipeline |
| 4 | Architecture Hardening | [Completed] | [detail](PRD/phase-4-architecture-hardening.md) |
| 5 | Identity & Adaptive Reading | [MVP Completed — V1 Follow-up] | [detail](PRD/phase-5-identity-and-adaptive-reading.md) |
| 6 | Visual Refresh | [In Progress — Sprint 3] | [detail](PRD/phase-6-visual-refresh.md) |

---

## Current Planning Focus

### Cross-repo Sprint 3 focus (Control Tower)

**Primary focus now (active):**
- Phase 6 implementation in execution (Visual Refresh)
- Compliance/release readiness tracked from Control Tower P0/P1 checklist
- Sprint 3 sequencing aligned with current tasks (UI redesign + legal/release validation)

### Phase 5 — Identity & Adaptive Reading

**Current state:** MVP foundation completed and stable as entry base for Phase 6.
**Tracking note:** Phase 5 PRD docs are planning/historical references. For live repo state, use [`docs/PROJECT_STATUS.md`](PROJECT_STATUS.md).

**V1 / Phase 5 follow-up (not sprint-critical for release gate):**
- Cloud reading progress sync
- Cloud favorites
- Preference sync to account
- Smarter format defaults

### Phase 6 — Visual Refresh

> **Status:** In Progress — Sprint 3 active, focused on visual delivery + compliance/release gate closure.  
> See [PRD/phase-6-visual-refresh.md](PRD/phase-6-visual-refresh.md) for the full feature breakdown.

Phase 6 stays separate on purpose so visual redesign does not get mixed with auth, reader behavior, and backend contract work. The design system and all screen mockups already exist under `design/`; Phase 6 translates those assets into production UI once Phase 5 behavior is stable.

**Design assets available now:**
- [`design/DESIGN.md`](../design/DESIGN.md) — "The Cinematic Canvas" design system (authoritative)
- [`design/nocturnal_canvas/DESIGN.md`](../design/nocturnal_canvas/DESIGN.md) — duplicate; canonical source TBD (see Phase 6 PRD open questions)
- Screen mockups (HTML + PNG): `home/`, `explore/`, `library/`, `title_detail/`, `reader_settings_open/`, `profile_with_theme_toggle/`

---

## Roadmap Task Index

Concise next-action summary per phase. Phases 1–4 are complete. Phase 5 MVP is complete (V1 pending). Phase 6 is the active Sprint 3 execution phase.

### Phase 1–4 — Completed

All foundational phases are done. The codebase has Clean Architecture, test coverage, CI/CD, and an architecture-hardened presentation/data/domain split. No pending actions.

### Phase 5 — Identity & Adaptive Reading (MVP Complete; V1 Backlog)

**Objective:** Make the app user-aware and adapt the reader to user preferences without coupling to backend delivery.  
**Entry dependency:** None — can start from current HEAD.  
**Current state:** Sprint 1 planning and MVP foundation were completed; Firebase-auth-first baseline is established and now serves as input for Sprint 3 visual/compliance work.

**Sprint 1 — Historical planning snapshot (closed):**

| Task | Workstream | Status | Depends on |
|------|-----------|--------|------------|
| TASK-001 Refine PRD Phase 5 | M0 | ✅ Done | — |
| TASK-005 Map Backend Integration Points | WS-A | ✅ Done | TASK-001 |
| TASK-002 Compare Auth Approaches → Decision: Firebase Auth | WS-A/B | ✅ Done | TASK-005 |
| TASK-003 Define UserProfile Domain Model | WS-D | ✅ Done | TASK-002 |
| TASK-004 Define Adaptive Reader Mode Strategy | WS-C | ✅ Done | TASK-003 |

**Workstreams (resolved in Sprint 1 planning):**

| ID | Name | MVP / V1 |
|----|------|----------|
| WS-A | Backend Foundation (Firebase token verification + SQLite + user/preferences API) | MVP |
| WS-B | Flutter Auth Foundation (Firebase Auth module + route guard + profile entry) | MVP |
| WS-C | Adaptive Reader Foundation (dual-mode reader + preference chain) | MVP |
| WS-D | User Profile & Preferences (domain entities + local-first persistence) | MVP |
| WS-E | Cloud Sync Expansion (progress, favorites, pref sync) | V1 |

**Milestone sequence:** M0 (planning) → M1 (backend) → M2 (Flutter auth) → M3 (prefs + reader) → M4 (MVP integration) → M5 (V1 cloud sync)

**Architecture decisions locked in Sprint 1:**
- Auth: Firebase Auth for identity; backend verifies Firebase ID tokens and stores local user/preferences data
- Persistence: SQLite via `aiosqlite` (swappable to Postgres)
- Token/session storage: Firebase Auth SDK managed session persistence (platform-native secure storage under the hood)
- Domain: `UserProfile` + `ReadingPreferences` + `PerTitleOverride` as separate entities
- Reader: Strategy pattern (`ReaderModeResolver` → `VerticalReaderView` / `PagedReaderView`)
- Navigation: 4th bottom tab "Profile" added to existing 3-tab shell

**Historical milestone sequence (planning snapshot):**
- M1: Build backend Firebase token verification + SQLite + user/preferences API
- M2: Build Flutter Firebase Auth module, sign-in/up pages, route guard, profile tab
- M3: Build preferences module + dual-mode reader
- M4: Integration and MVP stabilization
- M5: Cloud sync (V1)

**Expected outcome:** App knows who the user is, persists their preferences, and adapts the reader to content format.

**Detail:** [`docs/PRD/phase-5-identity-and-adaptive-reading.md`](PRD/phase-5-identity-and-adaptive-reading.md) — full PRD with workstreams, milestones, API surface, and gap analysis.  
**Execution plan:** [`docs/PRD/phase-5-execution-plan.md`](PRD/phase-5-execution-plan.md) — task checklist, file targets, dependency map.

### Phase 6 — Visual Refresh (Active — Sprint 3)

**Objective:** Translate the existing "Cinematic Canvas" design system into production UI across all screens.  
**Entry dependency:** Phase 5 MVP foundation stable (auth, reader modes, backend contracts defined). ✅ satisfied

**Pre-implementation (before any code):**
1. Resolve `design/DESIGN.md` vs `design/nocturnal_canvas/DESIGN.md` canonical source decision
2. Decide design token implementation strategy (Dart constants vs ThemeData extensions)
3. Decide animation framework (Flutter built-ins vs `flutter_animate` vs Rive)
4. Decide cover glow shadow implementation (palette extraction vs static fallback)

**MVP delivery order:**
1. Implement design token constants (`AppColors`, `AppTypography`, `AppSpacing`, `AppLayout`)
2. Build shared components: Floating Bottom Nav, Hero Card, Chapter Row, Pill Chip
3. Redesign Home screen
4. Redesign Title Detail screen
5. Redesign Explore, Library, Reader Settings, Profile

**Control Tower alignment (Sprint 3):**
- P0/P1 compliance and release-readiness validation runs in parallel to visual rollout
- Do not mark P0 items as done without explicit evidence in release/legal checklists

**Expected outcome:** App has a premium, editorial-grade visual identity consistent across all screens and is aligned with Sprint 3 compliance/release gates.

### Engineering Track — Release Automation & CI/CD Hardening (TASK-031)

**Objective:** Replace the manual release process (GitHub Release UI + PowerShell-only distribution script) with a fully automated, tag-driven pipeline.  
**Entry dependency:** None — infrastructure track, runs parallel to any feature phase.  
**Status:** Complete (Sprint 4).

| Phase | Scope | Status |
|-------|-------|--------|
| 1 | Tag-driven `release.yml` workflow (quality gates + version validation) | ✅ Done |
| 2 | Firebase App Distribution integrated in release workflow | ✅ Done |
| 3 | Cross-platform release scripts (`release.sh` / `release.ps1`) | ✅ Done |
| 4 | Documentation update (`RELEASING.md`, `ci.md`, `App_Distribution.md`) | ✅ Done |
| 5 | RC tag validation + legacy `firebase-distribution.yml` removal | ✅ Done |

**Expected outcome:** A single `./scripts/release.sh X.Y.Z` command is all a developer needs to trigger a full release — quality gates, APK builds, GitHub Release, and Firebase distribution included.

**Detail:** [`docs/RELEASING.md`](RELEASING.md) — release flow, secrets, and rollback guidance.

---

## Future Directions

- Deep-link and universal link support via go_router
- Push notifications for chapter releases
- Backend caching improvements (shared Redis layer)
- Extended test coverage for data and domain layers
