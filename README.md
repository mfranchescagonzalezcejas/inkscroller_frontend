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

| Frontend | Backend |
|---|---|
| Flutter 3.41 / Dart 3.9 | FastAPI (Python) |
| Riverpod (state management) | Firebase Auth integration |
| get_it (dependency injection) | MangaDex API proxy |
| Dio (networking) | Age-based content gating |
| GoRouter (navigation) | REST API |
| Firebase Core + Auth + Analytics | PostgreSQL |
| Clean + Screaming Architecture | Deployed on devdigi.dev |

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

<div align="center">

📖 **Manga reader** — scroll & paged modes, reading progress, per-title overrides  
🔍 **Catalog** — browse by genre, search with pagination, smart caching  
❤️ **User library** — follow/unfollow, track reading status  
👤 **Profile** — avatar, username, birth date, preferences  
🔐 **Auth** — email/password, Firebase Auth, age-aware registration  
🌐 **Localization** — English & Spanish  
📦 **3 flavors** — dev, staging, pro  
⚙️ **CI/CD** — GitHub Actions, automated releases, Firebase Distribution  

</div>

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

| Item | URL |
|---|---|
| 🗂️ **Frontend repo** | [mfranchescagonzalezcejas/inkscroller_frontend](https://github.com/mfranchescagonzalezcejas/inkscroller_frontend) |
| ⚙️ **Backend repo** | [mfranchescagonzalezcejas/Inkscroller_backend](https://github.com/mfranchescagonzalezcejas/Inkscroller_backend) |
| 🌐 **Deployment** | [InkScroller App](https://inkscroller.dev) |
| 📽️ **Slides** | <!-- TFM: add URL --> |
| 🎬 **Demo video** | <!-- TFM: add URL --> |
| 👤 **Test user** | <!-- TFM: add email/password --> |

The app consists of a **Flutter frontend** + **FastAPI backend**.  
The backend proxies MangaDex content and manages users, auth, and reading progress.  
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
