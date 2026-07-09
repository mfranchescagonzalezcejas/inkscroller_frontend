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
[![Tests](https://img.shields.io/github/actions/workflow/status/mfranchescagonzalezcejas/inkscroller_frontend/ci.yml?label=tests&logo=github)](https://github.com/mfranchescagonzalezcejas/inkscroller_frontend/actions)
[![Backend](https://img.shields.io/badge/backend-Inkscroller-1e40af?logo=fastapi)](https://github.com/mfranchescagonzalezcejas/Inkscroller_backend)

</div>

<br/>

<div align="center">
  <sub><b>· &nbsp; A B O U T &nbsp; ·</b></sub>
</div>

<br/>

**InkScroller** is a full-stack manga reading app built with **Flutter** (frontend) and **FastAPI** (backend).  
It features a smooth reader, personalized library, age-aware content filtering, and CI/CD automation.

The backend proxies **MangaDex** content (catalogue, chapters, pages via MangaDex@Home), enriches metadata through **Jikan/MyAnimeList**, and manages user profiles, reading preferences, and personal libraries with PostgreSQL persistence.

MangaDex aggregates chapters from scanlation groups and official sources.  
Chapters hosted on MangaDex's own infrastructure are proxied through the backend and rendered in-app;  
external-only chapters (linked to official platforms such as **Manga Plus**, **Viz Media**, **Mangatoon**, etc.) show a warning and open the original link on the official site.

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
| Flutter 3.41 / Dart 3.9 | FastAPI 0.128 / Python 3.12 |
| Riverpod (state management) | httpx (async HTTP client) |
| get_it (dependency injection) | Firebase Admin SDK (auth) |
| Dio (networking) | MangaDex API client (catalogue, chapters, pages) |
| GoRouter (navigation) | Jikan API client (MAL metadata enrichment) |
| Firebase Core + Auth + Analytics | PostgreSQL (Railway) / SQLite (local) |
| Clean + Screaming Architecture | In-memory TTL cache |
| 3 flavors (dev, staging, pro) | Deployed on Railway |

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

- 📖 **Manga reader** — scroll & paged modes, reading progress, per-title overrides. Internal reader for MangaDex-hosted chapters; external chapters open on the official source (Manga Plus, Viz Media, Mangatoon, etc.)
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

<br/>

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
fvm flutter test    # all green ✅
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

<br/>

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

| Item                 | URL                                                                                                               |
| -------------------- | ----------------------------------------------------------------------------------------------------------------- |
| 🗂️ **Frontend repo** | [mfranchescagonzalezcejas/inkscroller_frontend](https://github.com/mfranchescagonzalezcejas/inkscroller_frontend) |
| ⚙️ **Backend repo**  | [mfranchescagonzalezcejas/Inkscroller_backend](https://github.com/mfranchescagonzalezcejas/Inkscroller_backend)   |
| 📦 **App releases**  | [GitHub Releases](https://github.com/mfranchescagonzalezcejas/inkscroller_frontend/releases) · Google Play publication in progress |
| 🔌 **Backend APIs**  | `dev` `https://api.dev.inkscroller.devdigi.dev` · `staging` `https://api.stg.inkscroller.devdigi.dev` · `pro` `https://api.inkscroller.devdigi.dev` |
| 📽️ **Slides**        | Work in progress — not published yet                                                                              |
| 🎬 **Demo video**    | Work in progress — not published yet                                                                              |
| 👤 **Test user**     | Not required — users can create an account from the app with email/password registration                          |

</div>

InkScroller is a **mobile Flutter app**, so there is no public web deployment. GitHub Releases is the current public release channel while Google Play publication is in progress.

The app consists of a **Flutter frontend** + **FastAPI backend** (Python 3.12, deployed on Railway).  
The backend proxies **MangaDex** content (catalogue, chapters, pages via MangaDex@Home), enriches metadata through **Jikan/MyAnimeList**, and manages **user profiles**, reading **preferences**, and **personal libraries** with PostgreSQL.  
Chapters hosted on MangaDex servers are rendered in-app with scroll/paged modes; external-only chapters (official platforms like Manga Plus, Viz Media, Mangatoon) show a warning and open the original link on the official site.  
See [`docs/API_INTEGRATION.md`](docs/API_INTEGRATION.md) for integration details.

<br/>

<div align="center">
  <img width="55%" src="https://capsule-render.vercel.app/api?type=rect&color=0:0f172a,50:0d9488,100:0f172a&height=3&section=header" alt=""/>
</div>

<br/>

<!-- ─── ATTRIBUTION ───────────────────────────────────────────────────── -->

<div align="center">
  <sub><b>· &nbsp; A T T R I B U T I O N &nbsp; ·</b></sub>
</div>

<br/>

InkScroller is a **reading interface** — it does not host, store, or distribute any copyrighted content.  
All manga data and images are sourced through:

- **MangaDex** — primary catalogue, chapters, and page images via MangaDex@Home. InkScroller is not affiliated with MangaDex. Content belongs to its respective authors and scanlation groups.
- **Jikan / MyAnimeList** — metadata enrichment (score, rank, genres). InkScroller is not affiliated with MyAnimeList or Jikan.

External chapters link to official platforms (Manga Plus, Viz Media, Mangatoon, etc.).  
The app implements age-gated content access as required by platform policies.

See [`docs/legal/api-compliance.md`](docs/legal/api-compliance.md) for full compliance details.

<br/>

<div align="center">
  <img width="55%" src="https://capsule-render.vercel.app/api?type=rect&color=0:0f172a,50:0d9488,100:0f172a&height=3&section=header" alt=""/>
</div>

<br/>

<!-- ─── FOOTER ────────────────────────────────────────────────────────── -->

<div align="center">

**InkScroller** — built with Flutter + FastAPI  
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) · [`docs/API_INTEGRATION.md`](docs/API_INTEGRATION.md) · [`docs/legal/api-compliance.md`](docs/legal/api-compliance.md) · [`LICENSE`](LICENSE)

<br/>

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:0f172a,50:0d9488,100:0f172a&height=120&section=footer&animation=fadeIn" width="100%"/>

</div>
