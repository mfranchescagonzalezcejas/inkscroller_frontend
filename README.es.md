<!-- ─────────────────────────────────────────────────────────────────────── -->
<!--  InkScroller Flutter README ES — paleta azul/teal                    -->
<!-- ─────────────────────────────────────────────────────────────────────── -->

<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:0f172a,25:1e40af,50:0d9488,75:3b82f6,100:0f172a&height=220&section=header&text=InkScroller&fontSize=56&fontColor=fafafa&fontAlignY=38&desc=App%20de%20manga%20con%20Flutter%20%E2%80%A2%20Clean%20Architecture%20%E2%80%A2%20Riverpod&descAlignY=58&descSize=16&descColor=fafafa&animation=fadeIn" width="100%"/>

[![Flutter](https://img.shields.io/badge/Flutter-3.41-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![FVM](https://img.shields.io/badge/FVM-requerido-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://fvm.app)
[![Licencia](https://img.shields.io/badge/licencia-MIT-0d9488?style=for-the-badge)](LICENSE)

<br/>

[![Build](https://github.com/mfranchescagonzalezcejas/inkscroller_frontend/actions/workflows/ci.yml/badge.svg)](https://github.com/mfranchescagonzalezcejas/inkscroller_frontend/actions)
[![Tests](https://img.shields.io/github/actions/workflow/status/mfranchescagonzalezcejas/inkscroller_frontend/ci.yml?label=tests&logo=github)](https://github.com/mfranchescagonzalezcejas/inkscroller_frontend/actions)
[![Backend](https://img.shields.io/badge/backend-Inkscroller-1e40af?logo=fastapi)](https://github.com/mfranchescagonzalezcejas/Inkscroller_backend)

</div>

<br/>

<div align="center">
  <sub><b>· &nbsp; A C E R C A &nbsp; D E &nbsp; ·</b></sub>
</div>

<br/>

**InkScroller** es una app de lectura de manga full-stack construida con **Flutter** (frontend) y **FastAPI** (backend).  
Incluye un lector fluido, biblioteca personalizada, filtrado de contenido por edad y automatización CI/CD.

El backend sirve como proxy del contenido de **MangaDex** (catálogo, capítulos, páginas vía MangaDex@Home), enriquece metadatos a través de **Jikan/MyAnimeList** y gestiona perfiles de usuario, preferencias de lectura y bibliotecas personales con PostgreSQL.

MangaDex agrega capítulos de grupos de scanlation y fuentes oficiales.  
Los capítulos alojados en la infraestructura de MangaDex se renderizan en la app;  
los capítulos externos (enlazados a plataformas oficiales como **Manga Plus**, **Viz Media**, **Mangatoon**, etc.) muestran un aviso y abren el enlace original en el sitio oficial.

🎓 &nbsp;**Entrega TFM** — Ver [entregables](#entregables-tfm) más abajo.

<br/>

<div align="center">
  <img width="55%" src="https://capsule-render.vercel.app/api?type=rect&color=0:0f172a,50:0d9488,100:0f172a&height=3&section=header" alt=""/>
</div>

<br/>

<!-- ─── STACK ─────────────────────────────────────────────────────────── -->

<div align="center">
  <sub><b>· &nbsp; T E C N O L O G Í A S &nbsp; ·</b></sub>
</div>

<br/>

<div align="center">

| Frontend | Backend |
|---|---|
| Flutter 3.41 / Dart 3.11 | FastAPI 0.128 / Python 3.12 |
| Riverpod (gestión de estado) | httpx (cliente HTTP asíncrono) |
| get_it (inyección de dependencias) | Firebase Admin SDK (auth) |
| Dio (red) | Cliente API MangaDex (catálogo, capítulos, páginas) |
| GoRouter (navegación) | Cliente API Jikan (enriquecimiento MAL) |
| Firebase Core + Auth + Analytics | PostgreSQL (Railway) / SQLite (local) |
| Clean + Screaming Architecture | Caché en memoria con TTL |
| 3 sabores (dev, staging, pro) | Desplegado en Railway |

</div>

<br/>

<div align="center">
  <img width="55%" src="https://capsule-render.vercel.app/api?type=rect&color=0:0f172a,50:0d9488,100:0f172a&height=3&section=header" alt=""/>
</div>

<br/>

<!-- ─── FEATURES ──────────────────────────────────────────────────────── -->

<div align="center">
  <sub><b>· &nbsp; F U N C I O N A L I D A D E S &nbsp; ·</b></sub>
</div>

<br/>

- 📖 **Lector de manga** — modos scroll y paginado, progreso de lectura, configuración por título. Lector interno para capítulos alojados en MangaDex; capítulos externos abren en la fuente oficial (Manga Plus, Viz Media, Mangatoon, etc.)
- 🔍 **Catálogo** — navegación por género, búsqueda con paginación, caché inteligente
- ❤️ **Biblioteca personal** — seguir/dejar de seguir mangas, estado de lectura
- 👤 **Perfil** — avatar, nombre de usuario, fecha de nacimiento, preferencias
- 🔐 **Auth** — email/contraseña, Firebase Auth, registro con verificación de edad
- 🌐 **Localización** — español e inglés
- 📦 **3 sabores de compilación** — dev, staging, pro
- ⚙️ **CI/CD** — GitHub Actions, flujo de release automatizado, Firebase Distribution

<br/>

<div align="center">
  <img width="55%" src="https://capsule-render.vercel.app/api?type=rect&color=0:0f172a,50:0d9488,100:0f172a&height=3&section=header" alt=""/>
</div>

<br/>

<!-- ─── SETUP ─────────────────────────────────────────────────────────── -->

<div align="center">
  <sub><b>· &nbsp; C O N F I G U R A C I Ó N &nbsp; ·</b></sub>
</div>

<br/>

### Requisitos previos

- [FVM](https://fvm.app) (obligatorio)
- Flutter SDK gestionado vía `.fvmrc`

### Instalación y ejecución

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

> Algunos sabores pueden requerir archivos de configuración de Firebase locales. Ver [`docs/firebase-config-example.md`](docs/firebase-config-example.md).

### Verificación de calidad

El proyecto usa **lefthook** + **GGA** para ejecutar gates de calidad automáticamente en cada commit y push:

| Gate | Cuándo | Qué ejecuta |
|------|--------|-------------|
| **GGA** | Antes de `git commit` | Code review por IA vía OpenCode (reglas en `AGENTS.md`) |
| **pre-commit** | Antes de `git commit` | `fvm flutter analyze` + `fvm flutter test` (en paralelo) |
| **commit-msg** | Antes de `git commit` | Valida formato Conventional Commit (`type(scope): desc`) |
| **pre-push** | Antes de `git push` | `fvm flutter build apk --debug` + tests de integración |

```bash
# Instalar lefthook (una vez)
#   macOS: brew install lefthook
#   Linux: npm install -g lefthook
lefthook install
```

```bash
# Verificación manual — gates pre-commit
fvm flutter analyze
fvm flutter test    # todos los tests en verde ✅

# Verificación manual — gates pre-push
fvm flutter build apk --debug
fvm flutter test integration_test/   # necesita dispositivo conectado
```

```bash
# Omitir gates en emergencias
LEFTHOOK=0 git commit -m "fix: urgente"
git push --no-verify
```

### Estrategia de code review

| Nivel | Cuándo | Herramienta | Bypass |
|-------|--------|-------------|--------|
| **GGA** | Cada commit | `gga run` (OpenCode) | `GGA_SKIP=1` |
| **Lefthook** | Cada commit/push | `fvm flutter analyze`, `test`, `build` | `LEFTHOOK=0` |
| **CodeRabbit** | Features grandes, merge develop→main, releases | `./scripts/review.sh develop` o `@coderabbit review` en PR | Opcional |

**Día a día** (features chicas, fixes, refactors): GGA + lefthook alcanza.  
**Features gordas, merge a main, releases**: CodeRabbit como filtro extra antes de mergear.

<br/>

<div align="center">
  <img width="55%" src="https://capsule-render.vercel.app/api?type=rect&color=0:0f172a,50:0d9488,100:0f172a&height=3&section=header" alt=""/>
</div>

<br/>

<!-- ─── ARCHITECTURE ──────────────────────────────────────────────────── -->

<div align="center">
  <sub><b>· &nbsp; A R Q U I T E C T U R A &nbsp; ·</b></sub>
</div>

<br/>

**Screaming Architecture** a alto nivel, **Clean Architecture** por cada funcionalidad:

```text
lib/
├── core/              # DI, red, router, tema, tokens de diseño, widgets
├── features/          # Dominios de negocio
│   ├── auth/          data · domain · presentation
│   ├── library/       data · domain · presentation  (catálogo + lector)
│   ├── home/          data · domain · presentation
│   ├── explore/       presentation
│   ├── profile/       data · domain · presentation
│   ├── settings/      data · domain · presentation
│   ├── preferences/   data · domain · presentation
│   └── navigation/    presentation
└── flavors/           dev · staging · pro
```

Dirección de capas: `Presentation → Domain ← Data` — el dominio no depende de infraestructura.

<br/>

<div align="center">
  <img width="55%" src="https://capsule-render.vercel.app/api?type=rect&color=0:0f172a,50:0d9488,100:0f172a&height=3&section=header" alt=""/>
</div>

<br/>

<a name="entregables-tfm"></a>

<!-- ─── TFM ───────────────────────────────────────────────────────────── -->

<div align="center">
  <sub><b>· &nbsp; E N T R E G A B L E S &nbsp; T F M &nbsp; ·</b></sub>
</div>

<br/>

<div align="center">

<table>
<thead>
<tr><th>Ítem</th><th>URL</th></tr>
</thead>
<tbody>
<tr><td>🗂️ <b>Repo frontend</b></td><td><a href="https://github.com/mfranchescagonzalezcejas/inkscroller_frontend">mfranchescagonzalezcejas/inkscroller_frontend</a></td></tr>
<tr><td>⚙️ <b>Repo backend</b></td><td><a href="https://github.com/mfranchescagonzalezcejas/Inkscroller_backend">mfranchescagonzalezcejas/Inkscroller_backend</a></td></tr>
<tr><td>📦 <b>Releases app</b></td><td><a href="https://github.com/mfranchescagonzalezcejas/inkscroller_frontend/releases">GitHub Releases</a> · publicación en Google Play en proceso</td></tr>
<tr><td>🔌 <b>APIs backend</b></td><td><code>dev</code> <code>https://api.dev.inkscroller.devdigi.dev</code> · <code>staging</code> <code>https://api.stg.inkscroller.devdigi.dev</code> · <code>pro</code> <code>https://api.inkscroller.devdigi.dev</code></td></tr>
<tr><td>📽️ <b>Diapositivas</b></td><td>En proceso — todavía no publicadas</td></tr>
<tr><td>🎬 <b>Vídeo demo</b></td><td>En proceso — todavía no publicado</td></tr>
<tr><td>👤 <b>Usuario prueba</b></td><td>No requerido — la app permite crear una cuenta desde el registro con email/contraseña</td></tr>
</tbody>
</table>

</div>

InkScroller es una **app móvil Flutter**, por lo que no existe un despliegue web público. GitHub Releases es el canal público actual de releases mientras la publicación en Google Play está en proceso.

La aplicación consiste en un **frontend Flutter** + **backend FastAPI** (Python 3.12, desplegado en Railway).  
El backend sirve como proxy del contenido de **MangaDex** (catálogo, capítulos, páginas vía MangaDex@Home), enriquece metadatos a través de **Jikan/MyAnimeList** y gestiona **perfiles de usuario**, **preferencias** de lectura y **bibliotecas personales** con PostgreSQL.  
Los capítulos alojados en MangaDex se renderizan en la app; los capítulos externos (plataformas oficiales como Manga Plus, Viz Media, Mangatoon) muestran un aviso y abren el enlace original en el sitio oficial.  
Ver [`docs/API_INTEGRATION.md`](docs/API_INTEGRATION.md) para detalles de integración.

<br/>

<div align="center">
  <img width="55%" src="https://capsule-render.vercel.app/api?type=rect&color=0:0f172a,50:0d9488,100:0f172a&height=3&section=header" alt=""/>
</div>

<br/>

<!-- ─── ATTRIBUTION ───────────────────────────────────────────────────── -->

<div align="center">
  <sub><b>· &nbsp; A T R I B U C I Ó N &nbsp; ·</b></sub>
</div>

<br/>

InkScroller es una **interfaz de lectura** — no aloja, almacena ni distribuye contenido protegido por derechos de autor.  
Los datos e imágenes de manga provienen de:

- **MangaDex** — catálogo principal, capítulos e imágenes de página vía MangaDex@Home. InkScroller no está afiliado a MangaDex. El contenido pertenece a sus respectivos autores y grupos de scanlation.
- **Jikan / MyAnimeList** — enriquecimiento de metadatos (puntuación, ranking, géneros). InkScroller no está afiliado a MyAnimeList ni a Jikan.

Los capítulos externos enlazan a plataformas oficiales (Manga Plus, Viz Media, Mangatoon, etc.).  
La app implementa control de acceso por edad según lo requerido por las políticas de las plataformas.

Ver [`docs/legal/api-compliance.md`](docs/legal/api-compliance.md) para más detalles de cumplimiento.

<br/>

<div align="center">
  <img width="55%" src="https://capsule-render.vercel.app/api?type=rect&color=0:0f172a,50:0d9488,100:0f172a&height=3&section=header" alt=""/>
</div>

<br/>

<!-- ─── FOOTER ────────────────────────────────────────────────────────── -->

<div align="center">

**InkScroller** — construido con Flutter + FastAPI  
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) · [`docs/API_INTEGRATION.md`](docs/API_INTEGRATION.md) · [`docs/legal/api-compliance.md`](docs/legal/api-compliance.md) · [`LICENSE`](LICENSE)

<br/>

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:0f172a,50:0d9488,100:0f172a&height=120&section=footer&animation=fadeIn" width="100%"/>

</div>
