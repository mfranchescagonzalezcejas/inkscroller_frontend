# InkScroller Flutter

Flutter frontend (with FastAPI backend) for **InkScroller**, a manga reading experience focused on discoverability, personalized reading preferences, and an adaptive reader workflow.

This repository is prepared for **public portfolio visibility** and remains under active development.

![Flutter](https://img.shields.io/badge/Flutter-3.41.5-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.9-0175C2?logo=dart&logoColor=white)
![FVM](https://img.shields.io/badge/FVM-required-02569B?logo=flutter&logoColor=white)

## Project Status

- Portfolio + active development repository.
- The project is evolving and does **not** claim production service guarantees.
- This README intentionally avoids private operational details and secret values.

> 📘 **TFM submission** — See [TFM Deliverables](#tfm-deliverables) for submission materials.

## TFM Quick Links

| Resource | URL |
|---|---|
| Frontend repository | [mfranchescagonzalezcejas/inkscroller_frontend](https://github.com/mfranchescagonzalezcejas/inkscroller_frontend) |
| Backend repository | [mfranchescagonzalezcejas/Inkscroller_backend](https://github.com/mfranchescagonzalezcejas/Inkscroller_backend) |
| Deployment | [InkScroller App](https://inkscroller.dev) |
| Slides | <!-- TFM: add URL --> |
| Demo video | <!-- TFM: add URL --> |
| Test credentials | <!-- TFM: add user/password if login remains enabled --> |

## Tech Stack

- **Flutter / Dart**
- **State management:** Riverpod
- **Dependency injection:** get_it
- **Networking:** Dio
- **Navigation:** GoRouter
- **Firebase:** Core, Auth, Analytics
- **Architecture style:** Clean Architecture + Screaming Architecture

See [`pubspec.yaml`](pubspec.yaml) for exact dependency versions.

## Setup

### Prerequisites

- [FVM](https://fvm.app) (required)
- Flutter SDK managed via `.fvmrc`
- Android Studio or VS Code with Flutter tooling

### Install dependencies

```bash
fvm install
fvm flutter pub get
```

### Run by flavor

```bash
# dev
fvm flutter run --flavor dev -t lib/main_dev.dart

# staging
fvm flutter run --flavor staging -t lib/main_staging.dart

# pro
fvm flutter run --flavor pro -t lib/main_pro.dart
```

> Note: flavor runs may require local Firebase native config files and flavor-specific Dart defines.

## Firebase Configuration

Real Firebase configuration files are required for local/CI execution but are **not committed** in this repository.

- Use [`docs/firebase-config-example.md`](docs/firebase-config-example.md) for expected file structure and paths.
- Use `.dart-defines/firebase.example.json` as a safe template.
- Real `.dart-defines/firebase.json` remains local-only.
- Restore scripts are available for local/CI bootstrap:
  - `scripts/restore_firebase_config.ps1`
  - `scripts/restore_firebase_config.sh`

## Architecture

The codebase follows **Screaming Architecture** at the top level and **Clean Architecture** inside each feature:

- `features/` directories represent business domains.
- Layer direction: `Presentation → Domain ← Data`.
- **Presentation** depends on Domain (not Data).
- **Domain** stays framework-agnostic (no Flutter/Dio/Firebase dependencies).
- **Data** implements repository contracts and maps infrastructure models to domain entities.

Additional details: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)

## Testing & Quality

Run quality checks with FVM:

```bash
fvm flutter analyze
fvm flutter test
```

Depending on target flavor and integration paths, some runs may require local Firebase configuration artifacts.

## Project Structure

```
lib/
├── core/                   # Shared infrastructure
│   ├── di/                 # get_it dependency injection
│   ├── network/            # Dio client, interceptors
│   ├── router/             # GoRouter navigation
│   ├── theme/              # M3 theme (light/dark)
│   ├── design/             # Colors, typography, spacing tokens
│   ├── error/              # Exceptions and failure types
│   ├── constants/          # API endpoints and app constants
│   ├── widgets/            # Shared UI components
│   └── l10n/               # Localization delegates
├── features/               # Business domains (Screaming Architecture)
│   ├── auth/               # Login, register, session
│   ├── home/               # Latest chapters, genre tabs
│   ├── library/            # Manga catalog, search, reader
│   ├── explore/            # Browse and discover
│   ├── profile/            # User profile
│   ├── settings/           # Account, cache, delete
│   ├── preferences/        # Reading preferences
│   ├── navigation/         # App scaffold and tab bar
│   └── about/              # App info
├── flavors/                # Build flavor config (dev/staging/pro)
├── l10n/                   # ARB localization files (en, es)
└── main_*.dart             # Flavor entry points
```

Inside each feature: `presentation → domain ← data` (Clean Architecture).

## Main Features

- **Manga reader** — scroll and paged modes, reading progress tracking, per-title overrides
- **Manga catalog** — browse by genre, search, paginated lists with caching
- **User library** — follow/unfollow manga, track reading status
- **User profile** — avatar, username, birth date
- **Authentication** — email/password, Firebase Auth, age-aware registration
- **Localization** — English and Spanish
- **3 build flavors** — dev (development), staging (testing), pro (production)
- **CI/CD** — GitHub Actions, automated release workflow, Firebase Distribution

## Security & Public Readiness

Before changing repository visibility or preparing external distribution docs:

- [`docs/public-readiness.md`](docs/public-readiness.md)
- [`SECURITY_PUBLIC_READINESS.md`](SECURITY_PUBLIC_READINESS.md)

## Attribution

InkScroller consumes content through its backend integration and includes attribution/compliance context in:

- [`docs/legal/api-compliance.md`](docs/legal/api-compliance.md)

## TFM Deliverables

| Item | URL / Location |
|---|---|
| Frontend repository | [mfranchescagonzalezcejas/inkscroller_frontend](https://github.com/mfranchescagonzalezcejas/inkscroller_frontend) |
| Backend repository | [mfranchescagonzalezcejas/Inkscroller_backend](https://github.com/mfranchescagonzalezcejas/Inkscroller_backend) |
| Deployment | [InkScroller App](https://inkscroller.dev) |
| Slides | <!-- TFM: link to slides --> |
| Demo video | <!-- TFM: link to video --> |
| Test user | <!-- TFM: email / password --> |

For TFM evaluators: the app consists of a **Flutter frontend** and a **FastAPI backend**. The backend proxies MangaDex content and provides user management, auth, and reading progress APIs. See [`docs/API_INTEGRATION.md`](docs/API_INTEGRATION.md) for integration details.

## License

See [`LICENSE`](LICENSE).
