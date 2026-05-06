# Code Review Rules — InkScroller Flutter

## Dart / Flutter

- Use `const` constructors wherever possible
- Prefer `final` for local variables that are not reassigned
- No `dynamic` types — always declare explicit types on public APIs
- Use `///` dartdoc comments on all public classes, enums, and top-level functions
- Follow [Effective Dart](https://dart.dev/effective-dart) naming conventions

## Clean Architecture + Screaming Architecture

- `features/` directories represent **business domains** (e.g. `library`, `reader`, `profile`) — not technical constructs. This is Screaming Architecture: the folder tree screams what the app does, not what framework it uses.
- Inside each feature, strict Clean Architecture layers apply: `Presentation → Domain ← Data`
- **Presentation** must NOT import from **Data** — only from **Domain**
- **Domain** must NOT import Flutter, Dio, or any infrastructure package
- Entities are pure Dart value objects — no `fromJson`, no framework dependencies
- Use cases have a single `call()` method and delegate to repository contracts
- Mappers live in the Data layer and convert models to domain entities

## State Management (Riverpod)

- `StateNotifier` subclasses contain UI-related business logic only
- State classes must be immutable with `copyWith()` methods
- Providers resolve use cases from `get_it` (`sl<T>()`), not from constructors
- No business logic in widgets — widgets only watch/read providers

## Dependency Injection (get_it)

- All registrations must be `LazySingleton`
- Registration happens in `initDI()` — nowhere else
- Riverpod providers bridge get_it singletons to the widget tree

## Project Conventions

- FVM is required — all Flutter/Dart commands must use `fvm flutter` / `fvm dart`
- Three build flavors: `dev`, `staging`, `pro` — each with its own entry point
- Conventional Commits format: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`
- No hardcoded strings for API paths — use `ApiEndpoints` constants
- No magic numbers — use `AppConstants`, `AppSpacing`, or `AppLayout`
