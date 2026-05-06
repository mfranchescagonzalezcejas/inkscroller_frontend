# Phase 4 — Architecture Hardening

> **Status:** [Completed] — March 2026
> **PRs:** #9, #10, #11, #12

---

## Context

A structured code review of the codebase after Phase 3 surfaced four architectural violations and maintainability gaps that were blocking a clean path to future feature work:

1. The `SettingsCacheController` in the Presentation layer was directly importing `LibraryLocalDataSource` from the Data layer — a hard violation of the Clean Architecture Dependency Rule.
2. UI and layout values (page sizes, grid counts, opacity levels, tile heights) were scattered as inline magic numbers, making changes fragile and inconsistent.
3. The manga deduplication logic (`_dedupe`) was duplicated independently in both `LibraryNotifier` and `ReaderNotifier`, with no shared contract or test coverage.
4. Home section classification logic was split across `home_classifiers.dart`, `home_provider.dart`, and `home_page.dart`, with stale behavior in the classifiers file and business logic embedded in widgets.

Phase 4 resolved all four problems without changing any user-visible behavior.

---

## Goals

- Restore the Clean Architecture boundary between Presentation and Data in the settings flow.
- Replace all magic numbers in UI and display-limit code with named semantic constants.
- Extract the shared dedupe logic into a single, tested utility.
- Centralize home section classification into a canonical `HomeClassifier`, make the provider a thin delegator, and remove all business logic from `home_page.dart`.

---

## Scope

### In Scope
- Presentation → Data boundary fix for settings cache clear.
- New domain use case: `ClearLibraryCache`.
- `AppConstants`, `AppLayout`, and `HomeLayout` constant files (`lib/features/home/presentation/constants/home_layout.dart`).
- `dedupeMangas` shared utility in the library feature.
- `HomeClassifier` class and associated unit tests.

### Non-Goals
- No new user-visible features.
- No changes to the FastAPI backend.
- No changes to navigation, routing, or DI registration.
- No refactoring of the library or reader notifiers beyond dedupe extraction.

---

## Changes

### 4.1 Fix Settings Data Violation
- **Branch:** `feature/fix-settings-data-violation`
- **PR:** #9
- **Status:** [Completed]
- **Summary:** `SettingsCacheController` was calling `LibraryLocalDataSource.clearCache()` directly, bypassing the domain layer. The fix adds `clearLibraryCache()` to the `LibraryRepository` contract, implements it in `LibraryRepositoryImpl`, and introduces a `ClearLibraryCache` use case. `SettingsCacheController` now depends only on the use case — the Presentation layer no longer knows the Data layer exists.

### 4.2 Extract Magic Numbers
- **Branch:** `feature/extract-magic-numbers`
- **PR:** #10
- **Status:** [Completed]
- **Summary:** Inline sizing, limit, and display values across the library and home features were replaced with named constants in `AppConstants` (shared limits: page size, search caps), `AppLayout`, and `HomeLayout` (`lib/features/home/presentation/constants/home_layout.dart`) for home UI sizing (tile heights, grid counts, opacity values). No behavior changed — all values are identical to what was previously hardcoded.

### 4.3 Extract Dedupe Utility
- **Branch:** `feature/extract-dedupe-utility`
- **PR:** #11
- **Status:** [Completed]
- **Summary:** The `_dedupe(List<Manga>)` function existed independently inside `LibraryNotifier` and `ReaderNotifier`. It was extracted into a shared `dedupeMangas` top-level function in `lib/features/library/presentation/providers/library/dedupe_mangas.dart` and covered with focused unit tests. Both notifiers now delegate to the shared utility.

### 4.4 Refactor Home Classifiers
- **Branch:** `feature/refactor-home-classifiers`
- **PR:** #12
- **Status:** [Completed]
- **Summary:** `home_classifiers.dart` contained stale derivation logic that no longer matched the runtime behavior in `home_provider.dart` and `home_page.dart`. The fix canonicalizes classification in a `HomeClassifier` class with a single `classify(List<Manga>)` method returning a `HomeData` value object. `homeProvider` becomes a thin delegator; `home_page.dart` consumes provider-derived state and contains no classification logic. 14 unit tests lock the classifier behavior.

---

## Key Learnings

- **Layer boundary violations are subtle.** The `SettingsCacheController` case looked like a "small helper import" but was a real architectural violation. The fix required three coordinated changes (repository contract, impl, use case) — which is exactly what Clean Architecture demands and why the boundary matters.
- **Magic number extraction is behavioral-lock-first work.** The extraction only makes sense after the numbers have test coverage or are confirmed to be purely cosmetic — otherwise renaming them gives false confidence.
- **Shared utilities reveal duplication that was hidden by file locality.** The dedupe logic was identical in both notifiers but went unnoticed because the files are far apart in the tree. Extracting it proved they were truly identical (no silent behavioral drift).
- **Widget business logic accumulates invisibly.** `home_page.dart` had accumulated classification conditions that appeared to be view logic but were in fact domain-level decisions. The refactor made the boundary explicit.
- **Async delegation can silently fail.** During this phase, several background task delegations returned empty payloads or JSON EOF errors. Synchronous task execution was required to reliably complete the apply phases.

---

## Follow-Up

Identified but not scheduled for Phase 5:

- `dedupeMangas` utility could have a private constructor to signal it is not meant to be instantiated (currently a top-level function — low priority).
- `CoverImageWidget` cache size documentation may not reflect actual eviction behavior — a comment accuracy review would clarify this.
- Phases 1–3 do not yet have their own detail documents in `docs/PRD/`. Backfilling them would complete the historical record.
- Consider adding a linting rule or architecture test (e.g., `dart_code_metrics` or a custom analyzer plugin) to automatically catch Presentation→Data imports in CI.
