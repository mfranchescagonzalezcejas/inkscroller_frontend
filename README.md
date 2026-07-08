<!-- ─────────────────────────────────────────────────────────────────────── -->
<!--  InkScroller Flutter README — blue/teal palette                      -->
<!-- ─────────────────────────────────────────────────────────────────────── -->

<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:0f172a,25:1e40af,50:0d9488,75:3b82f6,100:0f172a&height=220&section=header&text=InkScroller&fontSize=56&fontColor=fafafa&fontAlignY=38&desc=Flutter%20manga%20reader%20%E2%80%A2%20Clean%20Architecture%20%E2%80%A2%20Riverpod&descAlignY=58&descSize=16&descColor=fafafa&animation=fadeIn" width="100%"/>

[![Flutter](https://img.shields.io/badge/Flutter-3.41-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![FVM](https://img.shields.io/badge/FVM-required-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://fvm.app)
[![License](https://img.shields.io/badge/license-MIT-0d9488?style=for-the-badge)](LICENSE)

<br/>

[![Build](https://github.com/mfranchescagonzalezcejas/inkscroller_frontend/actions/workflows/ci.yml/badge.svg)](https://github.com/mfranchescagonzalezcejas/inkscroller_frontend/actions)
[![Tests](https://img.shields.io/badge/tests-197%20passed-0d9488?logo=github)](https://github.com/mfranchescagonzalezcejas/inkscroller_frontend/actions)
[![Backend](https://img.shields.io/badge/backend-Inkscroller-1e40af?logo=fastapi)](https://github.com/mfranchescagonzalezcejas/Inkscroller_backend)

</div>

<br/>

<div align="center">
  <sub><b>· &nbsp; A B O U T &nbsp; ·</b></sub>
</div>

**InkScroller** is a full-stack manga reading app built with Flutter and FastAPI.  
It features a smooth reader, personalized library, age-aware content filtering, and CI/CD automation.

Content sourced through **MangaDex** — chapters hosted on MangaDex servers are proxied through the backend and rendered in-app;  
external-only chapters (hosted on platforms like Mangatoon) display the official link to read on the original site.

🎓 &nbsp;**TFM submission** — See [deliverables](#tfm-deliverables) below.

<br/>

<div align="center">
  <img width="55%" src="https://capsule-render.vercel.app/api?type=rect&color=0:0f172a,50:0d9488,100:0f172a&height=3&section=header" alt=""/>
</div>

<br/>

<!-- ─── STACK ─────────────────────────────────────────────────────────── -->

<div align="center">
  <sub><b>· &nbsp; T E C H &nbsp; S T A C K &nbsp; ·</b></sub>
</div>

<br/>

<div align="center">

| Frontend | Backend |
|---|---|
| Flutter 3.41 / Dart 3.9 | FastAPI (Python) |
| Riverpod (state management) | Firebase Auth integration |
| get_it (dependency injection) | MangaDex API proxy (manga, chapters, covers) |
| Dio (networking) | Age-based content gating |
| GoRouter (navigation) | REST API |
| Firebase Core + Auth + Analytics | PostgreSQL |
| Clean + Screaming Architecture | Deployed on devdigi.dev |

</div>

<br/>

<div align="center">
  <img width="55%" src="https://capsule-render.vercel.app/api?type=rect&color=0:0f172a,50:0d9488,100:0f172a&height=3&section=header" alt=""/>
</div>

<br/>

<!-- ─── FEATURES ──────────────────────────────────────────────────────── -->

<div align="center">
  <sub><b>· &nbsp; F E A T U R E S &nbsp; ·</b></sub>
</div>

<br/>

- 📖 **Manga reader** — scroll & paged modes, reading progress, per-title overrides. Internal reader for MangaDex-hosted chapters; external chapters open on the official source (Mangatoon, etc.)
- 🔍 **Catalog** — browse by genre, search with pagination, smart caching
- ❤️ **User library** — follow/unfollow manga, track reading status
- 👤 **Profile** — avatar, username, birth date, reading preferences
- 🔐 **Auth** — email/password, Firebase Auth, age-aware registration
- 🌐 **Localization** — English & Spanish
- 📦 **3 build flavors** — dev, staging, pro
- ⚙️ **CI/CD** — GitHub Actions, automated release workflow, Firebase Distribution

<br/>

<div align="center">
  <img width="55%" src="https://capsule-render.vercel.app/api?type=rect&color=0:0f172a,50:0d9488,100:0f172a&height=3&section=header" alt=""/>
</div>

<br/>

<!-- ─── SETUP ─────────────────────────────────────────────────────────── -->

<div align="center">
  <sub><b>· &nbsp; S E T U P &nbsp; ·</b></sub>
</div>

### Prerequisites

- [FVM](https://fvm.app) (required)
- Flutter SDK managed via `.fvmrc`

### Install & run

```bash
fvm install
fvm flutter pub get

# dev
fvm flutter run --flavor dev -t lib/main_dev.dart

# staging
fvm flutter run --flavor staging -t lib/main_staging.dart

# pro
fvm flutter run --flavor pro -t lib/main_pro.dart
```

> Flavor runs may require local Firebase config files. See [`docs/firebase-config-example.md`](docs/firebase-config-example.md).

### Quality checks

```bash
fvm flutter analyze
fvm flutter test    # 197 tests — all green ✅
```

<br/>

<div align="center">
  <img width="55%" src="https://capsule-render.vercel.app/api?type=rect&color=0:0f172a,50:0d9488,100:0f172a&height=3&section=header" alt=""/>
</div>

<br/>

<!-- ─── ARCHITECTURE ──────────────────────────────────────────────────── -->

<div align="center">
  <sub><b>· &nbsp; A R C H I T E C T U R E &nbsp; ·</b></sub>
</div>

**Screaming Architecture** at the top level, **Clean Architecture** per feature:

```
lib/
├── core/              # DI, networking, router, theme, design tokens, widgets
├── features/          # Business domains
│   ├── auth/          data · domain · presentation
│   ├── library/       data · domain · presentation  (catalog + reader)
│   ├── home/          data · domain · presentation
│   ├── explore/       presentation
│   ├── profile/       data · domain · presentation
│   ├── settings/      data · domain · presentation
│   ├── preferences/   data · domain · presentation
│   └── navigation/    presentation
└── flavors/           dev · staging · pro
```

Layer direction: `Presentation → Domain ← Data` — domain stays framework-agnostic.

<br/>

<div align="center">
  <img width="55%" src="https://capsule-render.vercel.app/api?type=rect&color=0:0f172a,50:0d9488,100:0f172a&height=3&section=header" alt=""/>
</div>

<br/>

<!-- ─── TFM ───────────────────────────────────────────────────────────── -->

<div align="center">
  <sub><b>· &nbsp; T F M &nbsp; D E L I V E R A B L E S &nbsp; ·</b></sub>
</div>

<br/>

<div align="center">

| Item | URL |
|---|---|
| 🗂️ **Frontend repo** | [mfranchescagonzalezcejas/inkscroller_frontend](https://github.com/mfranchescagonzalezcejas/inkscroller_frontend) |
| ⚙️ **Backend repo** | [mfranchescagonzalezcejas/Inkscroller_backend](https://github.com/mfranchescagonzalezcejas/Inkscroller_backend) |
| 🌐 **Deployment** | [InkScroller App](https://inkscroller.dev) |
| 📽️ **Slides** | <!-- TFM: add URL --> |
| 🎬 **Demo video** | <!-- TFM: add URL --> |
| 👤 **Test user** | <!-- TFM: add email/password --> |

</div>

The app consists of a **Flutter frontend** + **FastAPI backend**.  
The backend proxies **MangaDex** content (manga, chapters, covers) and manages users, auth, and reading progress.  
Chapters hosted on MangaDex servers are proxied through the backend and rendered in-app with scroll/paged modes; external-only chapters (hosted on platforms like Mangatoon) show a warning and open the official link on the original site.  
See [`docs/API_INTEGRATION.md`](docs/API_INTEGRATION.md) for integration details.

<br/>

<div align="center">
  <img width="55%" src="https://capsule-render.vercel.app/api?type=rect&color=0:0f172a,50:0d9488,100:0f172a&height=3&section=header" alt=""/>
</div>

<br/>

<!-- ─── FOOTER ────────────────────────────────────────────────────────── -->

<div align="center">

**InkScroller** — built with Flutter + FastAPI  
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) · [`docs/API_INTEGRATION.md`](docs/API_INTEGRATION.md) · [`docs/public-readiness.md`](docs/public-readiness.md) · [`LICENSE`](LICENSE)

<br/>

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:0f172a,50:0d9488,100:0f172a&height=120&section=footer&animation=fadeIn" width="100%"/>

</div>
