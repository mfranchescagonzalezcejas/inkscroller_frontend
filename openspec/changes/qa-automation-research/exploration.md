# Exploration — QA Automation Strategy for InkScroller

> Research artifact for GitHub issue #41 (status: approved).
> Goal: recommend which QA automation strategies are worth implementing
> for the InkScroller Flutter app, in what order, and with what effort.

---

## Current State

### Test footprint (52 test files today)

```
test/
├── core/                            (10 files)
│   ├── compliance/                  ← 3 P0-* guard tests (content rating, secrets, android id)
│   ├── design/                      ← 1 design-token regression test
│   ├── network/dio_client_test.dart ← Dio adapter + auth + base-URL fallback
│   ├── router/                      ← 2 routing tests
│   └── config/                      ← 2 startup config / env tests
├── empty_test.dart                  ← placeholder (delete candidate)
└── features/                        (41 files, one per feature)
    ├── auth/                        ← 2 (register_page, validators)
    ├── home/                        ← 3 (pages, providers)
    ├── library/                     ← 18 (data, domain, presentation, widgets)
    ├── preferences/                 ← 3
    ├── profile/                     ← 3
    ├── settings/                    ← 6
    └── about/                       ← 1
integration_test/
└── library_flow_test.dart           ← exists, NOT wired into CI
```

### How tests are written today

- **Layered mocking, not end-to-end.** The project mocks at three levels:
  1. **Use-case / repository** → `mocktail` mocks.
  2. **Data source** → a custom `HttpClientAdapter` (Dio-level) — see
     `test/features/settings/data/settings_remote_ds_impl_test.dart` and
     `test/core/network/dio_client_test.dart`. This is the **idiomatic** pattern
     and is reused across `settings`, `library`, `profile`, etc.
  3. **Widgets** → `ProviderScope.overrides` with stub notifiers; **no GetIt
     look-up** (see `test/features/library/presentation/pages/library_page_test.dart`).
- **Manual stubs** for the notifiers that page tests don't care about
  (`_makeStubAuthNotifier`, `_makeStubReadingProgressNotifier`, etc.).
  These are repeated per-file.
- **JSON parsing** (`MangaModel.fromJson`) is tested with inline
  `Map<String, dynamic>` literals — no JSON fixtures on disk.
- **Entities** are constructed inline everywhere
  (`Manga(id: '1', title: 'Berserk')` is repeated in ~10 test files).
- **One integration test** (`integration_test/library_flow_test.dart`) covers
  the search→detail flow with mocktail use-case mocks, but it is not run in CI.

### CI today (`.github/workflows/ci.yml` + `release.yml`)

| Job | Path filter | Status |
|---|---|---|
| `analyze` | `fvm flutter analyze` | **Blocks** |
| `unit-tests` | `core/ + domain/ + data/ + providers/` | **Blocks** |
| `ui-smoke` | 6 critical surface widget tests | **Blocks** |
| `ui-tests` | 4 page tests (`library_page`, `reader_page`, `home_*`, `about`) | `continue-on-error: true` (informational) |
| `solo_test` guard | regex against `test/` | **Blocks** |
| Release `fvm flutter test` | every `*_test.dart` | **Blocks** |

**Issues with the current CI:**

1. Integration tests are **never run** in CI (no `fvm flutter test integration_test/`).
2. The `ui-tests` job has `continue-on-error: true` — that means the
   `library_page_test.dart` and `reader_page_test.dart` can fail silently.
3. There is no coverage gate, no coverage report, and no trend tracking.
4. There is no platform-aware job (e.g. `flutter test --platform chrome`)
   even though the project has desktop build configs.

### Recent trajectory (from `git log`)

- Issue **#40** (commit `9ba30d1`): *audit and reduce low-value tests* — the
  team is **actively pruning** the test suite. Any new QA investment must
  justify itself; rote coverage-for-coverage's-sake is the wrong move.
- Issues #37, #38: register-form tests grew to **505 lines** with deep state
  coverage. The team knows how to write meaningful widget tests.
- `feat(settings): account deletion flow` (current branch) added **6 new
  test files** following the existing patterns.

### Data shape today (representative)

`MangaModel.fromJson` already does heavy defensive sanitization
(genres/authors filtering, `readChaptersCount` with 4 alias keys,
nested `progress.readChaptersCount` lookup). That logic is currently
covered by 2 inline tests in `manga_model_test.dart` — but **only** the
sanitization branch. Real backend responses, with `progress` and rank
populated, are **not** under test.

---

## Affected Areas

### Code
- `test/` — new factory helpers, JSON fixture file, golden test harness.
- `integration_test/` — promote `library_flow_test.dart` to CI; add
  reader-flow and library-empty-state integration tests.
- `lib/features/**/data/models/*_model.dart` — `fromJson` already there;
  no production change needed for fixtures to work.
- `pubspec.yaml` — add `golden_toolkit` (or use built-in `flutter_test`
  matchers); add `coverage` package (already implicit via `flutter test
  --coverage`).

### CI
- `.github/workflows/ci.yml` — add `integration-tests` job (with emulator
  or hosted macOS), tighten `ui-tests` from `continue-on-error: true` to
  blocking, add `coverage` job that uploads to Codecov / Coveralls.
- `.github/workflows/release.yml` — already runs full `fvm flutter test`,
  needs to add `fvm flutter test integration_test/` before the tag is
  published.

### Tooling / repo
- `openspec/changes/qa-automation-research/` — proposal/spec/design/tasks
  for the implementation phase.
- `scripts/smoke_mobile_release.sh` — already does an Android
  device-based smoke; this **stays** as the post-deploy safety net.

### NOT affected
- `lib/` production code (no change required to enable the test
  improvements).
- `flavors/` and `core/config/` (existing `FlavorConfig.resetForTesting`
  is already correct).
- `android/` and `ios/` folders (no platform change).

---

## Approaches

### A. Test data strategy

#### A1. Dart factory functions in `test/fixtures/factories.dart`

Centralized builders:

```dart
class MangaFactory {
  static Manga manga({String id = '1', String title = 'Berserk', ...}) => ...;
  static MangaModel mangaModel({...}) => ...;
  static List<Manga> many(int n) => List.generate(n, (i) => manga(id: '$i'));
  static List<MangaModel> manyModels(int n) => ...;
}
```

- **Pros:** type-safe; compiles to errors on field renames; no string
  keys; trivial to call from any test; matches what the issue itself
  says (*"Factory functions > archivos externos para datos dinámicos"*).
- **Cons:** every test file that needs the factory needs one import; can
  become a god-object if not split per-feature.
- **Effort:** Low (~half a day to set up + migrate top 3 test files).
- **Value:** High (kills ~20 lines of repeated `Manga(id: '1', title: ...)`
  per test file; makes new tests 3× cheaper to write).

#### A2. JSON fixtures in `test/fixtures/*.json`

Hand-curated files like `test/fixtures/manga_with_progress.json` that
load via `rootBundle.loadString` and decode with `MangaModel.fromJson`.

- **Pros:** realistic backend responses; great for testing
  `MangaModel.fromJson` sanitization with the actual production
  payload; version-controlled, diff-friendly; reproducible across
  feature teams.
- **Cons:** adds I/O to unit tests (need to use `File` not `rootBundle`,
  or include in `pubspec.yaml` assets which complicates
  production builds); harder to read in a test file.
- **Effort:** Medium (1-2 days for the file set + loaders).
- **Value:** Medium (only really useful for the `fromJson` defensive
  parsing tests; the rest of the test suite is happier with Dart
  factories).

#### A3. Mock server (e.g. `wiremock` via `dio` adapter, or `mockserver`)

A separate process that the integration test suite hits over HTTP.

- **Pros:** tests the real Dio configuration, the auth interceptor, the
  base-URL fallback, JSON parsing, and the repository wiring end-to-end.
- **Cons:** adds infra (a server to start in CI, ports to coordinate,
  state to reset between tests); **already solved** by the existing
  `HttpClientAdapter` pattern in `test/core/network/dio_client_test.dart`
  and the data source tests — which is **faster** and **flakeless**.
- **Effort:** High (1-2 weeks to wire up + CI integration).
- **Value:** Low. The current Dio-adapter mocking is the same coverage
  without the moving parts. A mock server only earns its keep when
  the real backend isn't available — and the team already has
  `dev-lan` / `dev-cloud` / `staging` / `pro` flavors for that.

**Recommendation:** **A1 + A2** together, scoped narrowly. A1 for
**dynamic test data** (any test that needs an entity to drive
behavior). A2 for **one curated fixture per model** to lock in the
defensive parsing contract (`MangaModel.fromJson` golden cases).
**Skip A3.**

### B. QA automation candidates

#### B1. Integration tests (`integration_test/`) wired into CI

Promote the existing `library_flow_test.dart` and add 2-3 more:
- `library_search_to_detail` (already exists).
- `library_offline_banner` (verifies the offline banner state).
- `register_form_validation` (regression for issue #35/#36/#37).
- `settings_delete_account_confirmation` (regression for the
  current branch).

Run on a GitHub-hosted runner using `fvm flutter test
integration_test/`. Android emulator is slow but free on
`ubuntu-latest`; macOS is faster but billable.

- **Pros:** catches the bugs that widget tests miss (router transitions,
  deep links, real provider rebuilds, real go_router); the existing
  test file is already 80% there.
- **Cons:** emulator start is ~5-10 min per CI run; flaky on resource-
  constrained runners; auth flows need a real Firebase test project.
- **Effort:** Medium (1 day to add 1-2 tests + CI job).
- **Value:** High. This is the **biggest unlock** in the issue.

#### B2. Golden tests for Library / Manga Detail / Reader

Use `matchesGoldenFile` to lock the rendered output of the 3 hero
screens.

- **Pros:** catches visual regressions in layout, spacing, theming;
  one file per screen.
- **Cons:** **incredibly brittle** with the current design — fonts,
  text scaling, shimmer animations, and `cached_network_image` will
  produce diffs on every run; needs a controlled `tester.view` size;
  every design change = regenerated files.
- **Effort:** Medium-High (1 day to set up + write 3 files, but
  ongoing maintenance burden).
- **Value:** Low-Medium. The team just shipped the home redesign
  and is iterating. Locking pixel-perfect goldens right now is the
  wrong moment.

**Recommendation:** **Defer B2** to when the visual system stabilizes
(after the current design iteration lands). The `core/design/
design_tokens_regression_test.dart` already gives token-level
regression coverage, which is a better tool for the current phase.

#### B3. Performance tests (scroll, image loading)

Use `flutter_driver` / `integration_test` to measure scroll FPS, jank
on the library grid, and `cached_network_image` cold-start times.

- **Pros:** manga reader = scroll-heavy UI; performance regressions
  here are **user-visible and silent** in unit tests.
- **Cons:** noisy in CI; hard to set reliable thresholds; need
  physical devices for meaningful numbers.
- **Effort:** High (1-2 weeks for a proper harness + a curated
  device matrix).
- **Value:** Medium. Worth doing for the **Reader screen** specifically
  (it's the screen users stare at the longest), but not the
  Library grid.

**Recommendation:** **Phase 4 work, not now.** Track in a separate
issue if it becomes a complaint. The team has bigger leverage
on B1 first.

#### B4. E2E with Firebase Test Lab

Cloud device farm run after each build.

- **Pros:** real Android/iOS devices, real network, real Firebase
  auth — catches environment-specific bugs.
- **Cons:** $$ (free tier is limited); another CI pipeline to
  maintain; auth credentials need careful secret management.
- **Effort:** High (1-2 weeks for setup + credential wiring + first
  test).
- **Value:** Low for a single-team Flutter app at this stage. The
  `scripts/smoke_mobile_release.sh` already exercises real devices
  on demand for releases.

**Recommendation:** **Skip for now.** Revisit when there's a real
device-specific bug the team can't reproduce in a widget test.

#### B5. Regression smoke tests post-deploy

The existing `scripts/smoke_mobile_release.sh` is exactly this — it
boots the app on a real device, verifies flavor + base URL, writes
evidence to `.qa-evidence/`.

- **Pros:** **already exists**, already works, already produces
  evidence files for review.
- **Cons:** only validates app boot, not feature behavior.
- **Effort:** Low (extend it to also exercise the library page after
  boot, ~half a day).
- **Value:** Medium.

**Recommendation:** **Extend B5**, do not replace. Add a "boot +
navigate to library + see the empty state" pass after the URL
check.

### C. CI gating policy

#### C1. Block on `analyze + unit + integration` (current behavior, hardened)

- **Pros:** catches broken code; deterministic; no false positives.
- **Cons:** no signal on **test quality** (you can have 200 tests
  that all pass and 0% coverage of the reader).
- **Effort:** Low (already the model).
- **Value:** High baseline.

#### C2. Block on coverage floor (e.g. ≥ 60% on `domain/` and `data/`)

- **Pros:** forces the team to test where it matters.
- **Cons:** easy to game; brittle to refactors; tends to push the
  team toward low-value coverage of `void` getters.
- **Effort:** Medium.
- **Value:** Low-Medium. The team's recent test-pruning (issue #40)
  shows they already self-regulate on test value.

**Recommendation:** **C1 hardened + C2 advisory.**
- C1: `analyze + unit + integration` **block** the PR. Remove
  `continue-on-error: true` from the `ui-tests` job.
- C2: report coverage on every PR; **fail** the build if it drops
  by more than 2% compared to `main`. Do not gate on a hard floor
  until the team has data on what a "normal" coverage number looks
  like for this codebase.

---

## Recommendation

### Implementation order (one PR per phase, each independently mergeable)

| Phase | Scope | Effort | Why first |
|---|---|---|---|
| **1. Factories** | `test/fixtures/factories.dart` with `MangaFactory`, `ChapterFactory`, `AppUserFactory`, `UserLibraryEntryFactory`. Migrate the top 3 most-duplicated test files (library_page, library_notifier, user_library_notifier). | ~0.5 day | Pays off every future test; no behavior change. |
| **2. Wire integration tests into CI** | Add a `integration-tests` job to `.github/workflows/ci.yml` that runs `fvm flutter test integration_test/`. Add 1-2 more integration tests (offline banner, registration form). | ~1 day | Highest-leverage single change. |
| **3. One curated JSON fixture per model** | `test/fixtures/manga_full.json` + `MangaModel.fromJson` golden test that pins down the defensive parsing contract. | ~0.5 day | Locks in the parsing contract the team already invested in. |
| **4. CI hardening** | Remove `continue-on-error: true` from `ui-tests`. Add a coverage report job (informational, no gate). Add coverage-drop guard. | ~0.5 day | Closes the leak the team is comfortable closing. |
| **5. Extend smoke script** | Add a "boot + navigate to library + verify empty state" pass to `scripts/smoke_mobile_release.sh`. | ~0.5 day | Cheap incremental value on existing infra. |
| **6. Defer** Golden tests (B2), performance (B3), FTL (B4), mock server (A3). | — | — | Don't invest in any of these until Phase 1-5 are merged and the team has run with them for at least one cycle. |

**Net effort for the recommended path: ~3 working days, spread across 5 PRs.**

### What the orchestrator should tell the user

1. We are NOT recommending a mock server — the existing Dio-adapter
   pattern is the right answer and is already battle-tested.
2. We ARE recommending Dart factory functions + 1 small JSON fixture
   per model (not a JSON-everything approach).
3. We ARE recommending the existing integration test be promoted to CI
   and the `ui-tests` job be hardened from `continue-on-error: true` to
   blocking.
4. We are NOT recommending golden tests right now — visual system is
   still iterating.
5. We are NOT recommending Firebase Test Lab or a coverage floor — both
   are higher cost than current team size warrants.
6. The full implementation is **~3 days of work** split across 5 small
   PRs. This is consistent with the team's existing PR cadence
   (issues #37, #38, #40, #17 were all small, focused PRs).

---

## Risks

- **Factory functions become a god-object.** Mitigate by splitting per
  feature (`MangaFactory`, `ChapterFactory`, etc.) and only adding
  helpers that **two or more** test files need.
- **Integration tests are flaky on CI.** Mitigate by using
  `tester.pumpAndSettle` with explicit timeouts and by pinning the
  emulator image; budget ~10% of CI failures as test flakiness and
  retry-once.
- **CI runtime grows.** Adding integration tests on a Linux runner
  with an Android emulator is **+5-10 min** per run. Mitigate by
  running integration tests in a separate job that doesn't gate the
  `analyze + unit + ui-smoke` fast-feedback path.
- **Coverage gate can drive bad tests.** Mitigate by reporting
  coverage without a hard floor; only fail on **drop vs `main`**.
- **The recommended path is a 5-PR roll-out.** If the team prefers
  a single PR, fold Phase 1+3+4 into one "test infrastructure"
  PR; the risk is the PR grows to >400 lines and warrants
  `chained-pr` slicing.
- **Smoke script extension depends on physical device availability.**
  The script is already gated on `adb devices`; the new check
  inherits the same constraint.

---

## Ready for Proposal

**Yes.**

The proposed scope is small (~3 days), follows the team's existing
patterns (mocktail + Dio adapters + Riverpod overrides), respects
issue #40's "no low-value tests" stance, and produces **5 small PRs**
instead of one giant one.

Next step: `sdd-propose` to draft the proposal.md with the
5-phase implementation plan above.
