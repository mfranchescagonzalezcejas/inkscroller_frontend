# Checklist Legal — Release InkScroller Flutter

> **Propósito:** Validar el cumplimiento legal, de APIs y de stores antes de publicar una release.  
> **Usar en:** Cada release a `staging` y `pro` (App Distribution / Play Store / App Store).  
> **Referencia:** [`docs/legal/api-compliance.md`](../legal/api-compliance.md)

---

## Regla GO / NO-GO

> **Un NO en cualquier ítem marcado con 🔴 bloquea el release.**  
> Los ítems 🟡 son advertencias — documentar la decisión si se omiten.

---

## Bloque 1 — Acceso a APIs (arquitectura)

| # | Ítem | Criticidad | Estado |
|---|------|-----------|--------|
| 1.1 | Flutter **no** llama directamente a `api.mangadex.org` — todo va por el backend InkScroller | 🔴 BLOQUEANTE | ✅ 2026-04-09 |
| 1.2 | Flutter **no** llama directamente a `api.jikan.moe` — todo va por el backend InkScroller | 🔴 BLOQUEANTE | ✅ 2026-04-09 |
| 1.3 | `DioClient` apunta al backend InkScroller, no a APIs de terceros | 🔴 BLOQUEANTE | ✅ 2026-04-09 |
| 1.4 | El flavor `pro` tiene configurado el `API_BASE_URL` de Railway (no una URL local) | 🔴 BLOQUEANTE | ✅ 2026-04-07 |

## Bloque 2 — Contenido y monetización

| # | Ítem | Criticidad | Estado |
|---|------|-----------|--------|
| 2.1 | No existe funcionalidad de descarga masiva o bulk download de capítulos | 🔴 BLOQUEANTE | ☐ |
| 2.2 | No hay paywall que bloquee acceso a contenido de MangaDex | 🔴 BLOQUEANTE | ☐ |
| 2.3 | No hay compras in-app para desbloquear capítulos de MangaDex | 🔴 BLOQUEANTE | ☐ |
| 2.4 | El contenido con rating adulto (`erotica/pornographic`) está filtrado o requiere verificación de edad | 🔴 BLOQUEANTE | ✅ 2026-04-09 |

## Bloque 3 — Atribución visible en la UI

| # | Ítem | Criticidad | Estado |
|---|------|-----------|--------|
| 3.1 | La pantalla de detalle de manga muestra la fuente (MangaDex) | 🟡 ADVERTENCIA | ☐ |
| 3.2 | El lector de capítulos muestra el grupo de scanlation (cuando el backend lo provee) | 🟡 ADVERTENCIA | ☐ |
| 3.3 | Los datos de score/rank muestran "MyAnimeList" o "MAL" como fuente | 🟡 ADVERTENCIA | ☐ |
| 3.4 | Existe pantalla de About/Créditos con disclaimer de no afiliación a MangaDex y MAL | 🟡 ADVERTENCIA | ☐ |

## Bloque 4 — Manejo de errores y degradación

| # | Ítem | Criticidad | Estado |
|---|------|-----------|--------|
| 4.1 | Capítulos `external: true` se manejan correctamente (no se renderiza en reader interno) | 🔴 BLOQUEANTE | ☐ |
| 4.2 | La UI no crashea cuando `score`, `rank`, `genres` o `authors` son `null` (datos Jikan) | 🔴 BLOQUEANTE | ☐ |
| 4.3 | Si el backend está caído, la app muestra estado de error sin crash | 🔴 BLOQUEANTE | ☐ |
| 4.4 | El banner de offline se muestra correctamente cuando no hay conectividad | 🟡 ADVERTENCIA | ☐ |

## Bloque 5 — Calidad y flavors

| # | Ítem | Criticidad | Estado |
|---|------|-----------|--------|
| 5.1 | Tests pasan (`fvm flutter test`) — mínimo 97 tests passing | 🔴 BLOQUEANTE | ✅ 2026-04-09 |
| 5.2 | El flavor `pro` no tiene banners de DEBUG ni indicadores de entorno | 🔴 BLOQUEANTE | ☐ |
| 5.3 | Los íconos de launcher son correctos por flavor (`dev` / `staging` / `pro`) | 🟡 ADVERTENCIA | ☐ |
| 5.4 | Firebase `google-services.json` / `GoogleService-Info.plist` del entorno correcto están en su lugar | 🔴 BLOQUEANTE | ☐ |

## Bloque 6 — Seguridad

| # | Ítem | Criticidad | Estado |
|---|------|-----------|--------|
| 6.1 | No hay secrets ni API keys hardcodeadas en el código Dart | 🔴 BLOQUEANTE | ✅ 2026-04-09 |
| 6.2 | `AuthInterceptor` adjunta Firebase ID token en todas las solicitudes autenticadas | 🔴 BLOQUEANTE | ☐ |
| 6.3 | Las rutas protegidas tienen route guard activo | 🔴 BLOQUEANTE | ☐ |

---

## Resultado final

```
Fecha de release: ___________
Flavor / entorno: ☐ staging  ☐ pro
Versión de build: ___________
Revisado por: ___________

Bloqueos encontrados (ítems 🔴 en NO):
- [ ] Ninguno → GO ✅
- [ ] (listar si los hay) → NO-GO ❌

Advertencias documentadas:
- (listar ítems 🟡 en NO con justificación)

Decisión final: ☐ GO  ☐ NO-GO
Firma: ___________
```

---

## Planned / TODO — Deuda técnica detectada

> Estos ítems fueron detectados durante auditoría de compliance (2026-04-07).
> **No están implementados aún.** Deben resolverse antes del primer release público a stores.
> No borrar hasta que el ítem correspondiente esté implementado y verificado.

| # | Gap | Ítem relacionado en checklist | Repos | Prioridad |
|---|-----|-------------------------------|-------|-----------|
| P-1 | Crear pantalla About/Créditos con disclaimer de no afiliación a MangaDex y MAL | 3.4 | `inkscroller_flutter` | Media |
| P-2 | El reader de capítulos muestra `scanlation_group` solo cuando el backend lo provee — **depende de que el backend exponga el campo** (gap P-1 del backend) | 3.2 | `inkscroller_flutter` + `Inkscroller_backend` | Media |
| P-3 | *(Para Backend)* Retry/backoff ante HTTP 429 de MangaDex | 1.6 (backend) | `Inkscroller_backend` | Media |
| P-4 | *(Para Backend)* Fallback graceful en cliente Jikan ante error o 429 | 2.2 (backend) | `Inkscroller_backend` | Media |
| P-5 | *(Para Backend)* Feature flag `ENABLE_JIKAN_ENRICHMENT` en `.env.example` | 2.5 (backend) | `Inkscroller_backend` | Baja |

---

## Tracking P0 — Estado de compliance por ítem (Control Tower V1.0)

> Espejo del tracking de Control Tower V1.0 en Obsidian. La fuente de verdad es Obsidian.
> Mantener sincronizado cuando cambia el estado de un ítem P0 en la fuente.

| Ítem | Descripción | Checklist ref | Estado |
|------|------------|---------------|--------|
| **P0-F1** | **Flavor `pro` apunta al `API_BASE_URL` de Railway (no URL local)** | **1.4** | **✅ 2026-04-07** |
| **P0-F2** | **Capítulos `external: true` no se renderizan en el reader interno** | **4.1** | **✅ 2026-04-08 (PR #46)** |
| **P0-F3** | **La UI no crashea con `score`, `rank`, `genres`, `authors` en `null`** | **4.2** | **✅ 2026-04-08 (PR #47)** |
| **P0-F4** | **Filtro de contenido adulto (`erotica/pornographic`) activo o con verificación de edad** | **2.4** | **✅ 2026-04-09** |
| **P0-F5** | **No hay API keys ni secrets hardcodeados en código Dart** | **6.1** | **✅ 2026-04-09** |
| **P0-F6** | **`AuthInterceptor` adjunta Firebase ID token en todas las rutas autenticadas** | **6.2** | **✅ 2026-04-09** |
| **P0-F7** | **Route guards activos en rutas protegidas** | **6.3** | **✅ 2026-04-09** |
| **P0-F8** | **Mínimo 97 tests passing en `fvm flutter test`** | **5.1** | **✅ 2026-04-09** |
| **P0-F9** | **Firebase `google-services.json` / `GoogleService-Info.plist` del entorno `pro` en su lugar** | **5.4** | **✅ 2026-04-08** |
| **P0-F10** | **Flutter NO llama directamente a `api.mangadex.org` ni `api.jikan.moe`** | **1.1 / 1.2** | **✅ 2026-04-09** |

### Evidencias — P0-F1

- **Qué**: El flavor `pro` debe estar configurado con el `API_BASE_URL` apuntando a Railway, no a `localhost` ni a una IP LAN.
- **Verificación**: QA smoke — run config `Flutter Pro Physical.run.xml` revisado con URL de backend desplegado. Revalidar contra Railway antes de release público.
- **Fecha de cierre**: 2026-04-07
- **Referencia cruzada**: Control Tower V1.0 (Obsidian) → P0-F1 marcado ✅ 2026-04-07

### Evidencias — P0-F2

- **Qué**: Se validó que capítulos con `external: true` no se renderizan en el reader interno.
- **Verificación**: Implementación y validación documentada en **PR #46**.
- **Fecha de cierre**: 2026-04-08
- **Referencia cruzada**: Control Tower V1.0 (Obsidian) → P0-F2 marcado ✅

### Evidencias — P0-F3

- **Qué**: Null safety implementada en toda la UI para `score`, `rank`, `genres` y `authors` — la app no crashea cuando la API Jikan devuelve estos campos como `null`.
- **Verificación**: Implementación documentada en **[PR #47](https://github.com/mfranchescagonzalezcejas/inkscroller_flutter/pull/47)** — mergeado `develop` 2026-04-08. Archivos afectados: `home_page.dart`, `manga_detail_page.dart`, `manga_tile.dart`, `manga_model.dart`, `manga.dart`, `manga_mapper.dart` + 3 test files.
- **Fecha de cierre**: 2026-04-08
- **Referencia cruzada**: Control Tower V1.0 (Obsidian) → P0-F3 marcado ✅; TASK-021 actualizada; TASK-022 con evidencia cruzada registrada.

### Evidencias — P0-F9

- **Qué**: Verificación estática de la configuración Firebase del flavor `pro` — archivos de credenciales, wiring de build y consistencia de IDs entre plataformas.
- **Verificación**:
  - **Android**: `android/app/src/pro/google-services.json` presente. `package_name: com.example.inkscroller` coincide con `applicationId` efectivo del flavor `pro` (sin `applicationIdSuffix` en `build.gradle.kts`). `mobilesdk_app_id: 1:806863502436:android:afa6aa67fc46d548a83371` coincide con `firebase_options.dart` → `Flavor.pro` Android `appId`. ✅
  - **iOS**: `ios/config/pro/GoogleService-Info.plist` presente. `BUNDLE_ID: com.example.inkscroller` coincide con `PRODUCT_BUNDLE_IDENTIFIER` de las build configurations `Debug-pro` / `Release-pro` en `project.pbxproj`. `GOOGLE_APP_ID: 1:806863502436:ios:540e8642319749c9a83371` coincide con `firebase_options.dart` → `Flavor.pro` iOS `appId`. ✅
  - **Build phase iOS**: Script de build en Xcode copia automáticamente `config/${environment}/GoogleService-Info.plist` al bundle en cada build — `environment` se extrae de `$CONFIGURATION` (ej. `Release-pro` → `pro`). ✅
  - **`firebase_options.dart`**: `FirebaseOptionsSelector` usa `FlavorConfig.instance.flavor` para seleccionar las opciones correctas en runtime — todos los campos de `Flavor.pro` son consistentes con los archivos de credenciales. ✅
  - **`FlavorBanner`**: El flavor `pro` no muestra ningún banner de debug en la UI. ✅
  - **Corrección aplicada**: `ios/Runner/GoogleService-Info.plist` (placeholder en repo) contenía config de `staging` — corregido para reflejar el entorno `pro` y documentado con comentario explicativo sobre el rol de este archivo vs. el build phase. ✅
- **Pendiente manual**: Los archivos físicos de credenciales Firebase (`google-services.json` / `GoogleService-Info.plist`) **no deben versionarse en repos públicos**. Si el repo se hace público: (1) mover estos archivos a `.gitignore`, (2) distribuir via secret manager o CI/CD secrets, (3) documentar el proceso de bootstrapping en `docs/ANDROID_STUDIO_SETUP.md` y `docs/firebase-config-example.md` (con validación en `docs/PHYSICAL_DEVICE.md`). En repo privado: aceptable si el equipo es controlado.
- **Fecha de cierre**: 2026-04-08
- **Referencia cruzada**: Control Tower V1.0 (Obsidian) → P0-F9 marcado ✅; TASK-021 y TASK-022 actualizados

### Evidencias — P0-F6

- **Qué**: Se validó que `_AuthInterceptor` en `lib/core/network/dio_client.dart` adjunta el Firebase ID token como `Bearer` en todas las rutas bajo `/users` (rutas autenticadas del backend). El token se obtiene de `GetIdToken` → `AuthRepository.getIdToken()` vía el `tokenProvider` inyectado en el DI.
- **Arquitectura**:
  - `_AuthInterceptor._protectedPaths = ['/users']` — define qué rutas reciben el token.
  - `_AuthInterceptor.attachAuthHeader()` — lógica de adjuntar token, expuesta como `attachAuthHeaderForRequest()` para testabilidad.
  - `DioClient` en `injection.dart` registra el cliente con `tokenProvider: () async { ... sl<GetIdToken>()() ... }`.
  - Si el token es `null`, vacío, o la obtención lanza excepción, el request se reenvía **sin** header — el backend retorna 401 y el caller lo gestiona. El flujo público no se interrumpe.
- **Verificación**: Tests unitarios formales en `test/core/network/dio_client_test.dart`:
  - `isProtectedAuthPath`: `/users`, `/users/me`, `/users/preferences` → protegidos; `/ping`, `/manga`, `/chapters/latest` → públicos.
  - `attachAuthHeaderForRequest`: token adjunto en `/users`; no adjunto en `/ping` ni `/manga`; no adjunto si provider retorna `null`/vacío/excepción.
  - **7 tests** PASS en este módulo.
- **Fecha de cierre**: 2026-04-09
- **Referencia cruzada**: Control Tower V1.0 (Obsidian) → P0-F6 marcado ✅; TASK-021 y TASK-022 actualizados. PR `feature/p0-f6-f7-auth-guard-hardening` → `develop`.

### Evidencias — P0-F7

- **Qué**: Se hardenearon los route guards en `lib/core/router/app_router.dart` y se corrigió el manejo de errores del stream de auth en `lib/features/auth/presentation/providers/auth_notifier.dart`.
- **Cambios en el router** (`app_router.dart`):
  - Se definen explícitamente `_protectedRoutes = ['/profile']` y `_authOnlyRoutes = ['/login', '/register']`.
  - `resolveAuthRedirect()`: guest en `/profile` → redirige a `/login`; usuario autenticado en `/login`/`/register` → redirige a `/`; rutas públicas (`/`, `/explore`, `/library`, `/manga/:id`, `/reader`) → sin redirect para cualquier estado de auth.
- **Cambios en `AuthNotifier`** (`auth_notifier.dart`):
  - `_listenToAuthState()` ahora incluye `onError` callback. Si el stream de auth emite un error (token revocado, fallo de red en refresh), el notifier: (1) limpia el usuario → modo guest, (2) `isLoading = false` → sin estado inconsistente, (3) setea un mensaje de error en estado para que la UI lo muestre de forma no bloqueante.
  - Las rutas públicas permanecen accesibles porque `resolveAuthRedirect(currentUser: null)` no bloquea ningún route público.
- **Verificación**: Tests unitarios formales:
  - `test/core/router/app_router_test.dart`: 9 tests → guest accede a público ✓, guest bloqueado en `/profile` ✓, auth user redirigido fuera de login/register ✓, null user (fallback de error) no bloquea público ✓.
  - `test/features/auth/presentation/providers/auth_notifier_test.dart`: 2 tests nuevos → stream error limpia user y setea error ✓, after error usuario queda en null/guest sin isLoading ✓.
  - **Suite completa**: 116/116 tests PASS. `fvm flutter analyze` → No issues found.
- **Fecha de cierre**: 2026-04-09
- **Referencia cruzada**: Control Tower V1.0 (Obsidian) → P0-F7 marcado ✅; TASK-021 y TASK-022 actualizados. PR `feature/p0-f6-f7-auth-guard-hardening` → `develop`.

### Evidencias — P0-F8

- **Qué**: Ejecución completa de `fvm flutter test` — 116 tests passing, superando el gate mínimo de 97.
- **Verificación**:
  - Comando: `fvm flutter test --no-pub` en rama `feature/p0-f8-f10-release-gates`
  - Resultado: **116/116 tests PASS** — 0 failures, 0 skipped.
  - `fvm flutter analyze` → **No issues found.**
  - Cobertura de módulos: domain use cases, repository impls, presentation notifiers, router guards, auth interceptor, widget tests, page tests.
- **Fecha de cierre**: 2026-04-09
- **Referencia cruzada**: Control Tower V1.0 (Obsidian) → P0-F8 marcado ✅; TASK-021 y TASK-022 actualizados. PR `feature/p0-f8-f10-release-gates` → `develop`.

### Evidencias — P0-F10

- **Qué**: Auditoría estática completa del árbol `lib/` de Flutter — confirmación de que ninguna llamada HTTP directa se realiza a `api.mangadex.org`, `api.jikan.moe`, ni ningún dominio externo de terceros.
- **Verificación**:
  - Búsqueda por dominios: `rg -i "mangadex|jikan|api\.mangadex\.org|api\.jikan\.moe|myanimelist" lib/ --glob "*.dart" -n` → solo comentarios/docstrings y nombres de clases de dominio (mapper de UUIDs). **0 URLs HTTP**.
  - Búsqueda por URLs directas a APIs: `rg "http[s]?://api\.(mangadex|jikan)" lib/ --glob "*.dart" -n` → **0 matches**.
  - Búsqueda de todas las URLs hardcodeadas: `rg "http[s]?://" lib/ --glob "*.dart" -n` → solo URLs del backend InkScroller o endpoints locales permitidos.
  - Instancias de Dio: `rg "Dio\s*\(" lib/ --glob "*.dart" -n` → **solo 1 instancia** en `dio_client.dart` con `baseUrl = ApiConfig.baseUrl = FlavorConfig.instance.apiBaseUrl`.
  - Todos los datasources impls usan `DioClient` inyectado vía DI — ninguno instancia su propio cliente.
  - Los únicos `Uri.parse()` detectados son para apertura de capítulos `external: true` en el browser del sistema vía `url_launcher` (P0-F2, ya cerrado) — no son llamadas HTTP propias.
- **Evidencia formal completa**: [`docs/release/templates/p0-f10-network-audit-evidence.md`](templates/p0-f10-network-audit-evidence.md)
- **Arquitectura confirmada**: Flutter → backend InkScroller (único destino) → MangaDex/Jikan (backend only, invisible para Flutter).
- **Fecha de cierre**: 2026-04-09
- **Referencia cruzada**: Control Tower V1.0 (Obsidian) → P0-F10 marcado ✅; TASK-021 y TASK-022 actualizados. PR `feature/p0-f8-f10-release-gates` → `develop`. Issues #48 y #49.

### Evidencias — P0-F4

- **Qué**: Auditoría completa del flujo Home/Explore/Library/Detail/Reader para confirmar que Flutter no bypassa el filtro de contenido adulto del backend.
- **Arquitectura confirmada**: El backend InkScroller aplica `_ALLOWED_CONTENT_RATINGS = ["safe", "suggestive"]` en todos los métodos de `MangaDexClient` que listan/buscan manga y capítulos (`search_manga`, `get_chapters`, `get_latest_chapters`, `get_manga_list_by_ids`, `list_manga`). Flutter no envía ningún parámetro `contentRating` — no tiene forma de bypassar el filtro.
- **Modelo sin exposición**: `MangaModel` y `Manga` entity no tienen campo `contentRating` — incluso si el backend filtrara mal, el dato no llegaría a la UI.
- **Tests formales**: 5 tests en `test/core/compliance/p0_f4_content_rating_audit_test.dart` — **5/5 PASS**.
- **Evidencia formal completa**: [`docs/release/templates/p0-f4-content-rating-audit-evidence.md`](templates/p0-f4-content-rating-audit-evidence.md)
- **Fecha de cierre**: 2026-04-09
- **Referencia cruzada**: Control Tower V1.0 (Obsidian) → P0-F4 marcado ✅; TASK-021 y TASK-022 actualizados. PR `feature/p0-f4-f5-final-frontend-compliance` → `develop`. Issues #48 y #49.

### Evidencias — P0-F5

- **Qué**: Auditoría estática exhaustiva de `lib/**/*.dart` buscando patrones de secretos hardcodeados: OpenAI/Stripe `sk-...`, GitHub tokens `gh[poa]_...`, AWS `AKIA...`, Slack `xox...`, SendGrid `SG....`, GitLab `glpat-...`, Bearer tokens con valores, passwords hardcodeados, llamadas directas a `api.mangadex.org` / `api.jikan.moe`.
- **Resultado**: **0 secretos reales encontrados.** El único hallazgo son los Firebase API keys (`REDACTED_FIREBASE_API_KEY...`) en `lib/firebase_options.dart`, que son **known-safe** por diseño de Firebase para apps mobile (ver https://firebase.google.com/docs/projects/api-keys — no son secretos, son identificadores de proyecto restringidos por Security Rules + SHA-1/bundle ID).
- **URLs hardcodeadas**: URLs encontradas, todas del backend InkScroller (`localhost`, Android emulator loopback, Railway/backend configurado). Ninguna URL de terceros.
- **Bearer token**: `'Bearer '` en `dio_client.dart` es un prefijo estático de header, no un valor. El token se obtiene en runtime de `FirebaseAuth.getIdToken()`.
- **Tests formales**: 12 tests en `test/core/compliance/p0_f5_secrets_audit_test.dart` — **12/12 PASS**.
- **Evidencia formal completa**: [`docs/release/templates/p0-f5-secrets-audit-evidence.md`](templates/p0-f5-secrets-audit-evidence.md)
- **Fecha de cierre**: 2026-04-09
- **Referencia cruzada**: Control Tower V1.0 (Obsidian) → P0-F5 marcado ✅; TASK-021 y TASK-022 actualizados. PR `feature/p0-f4-f5-final-frontend-compliance` → `develop`. Issues #48 y #49.

---

## Referencias

- [`docs/legal/api-compliance.md`](../legal/api-compliance.md) — reglas detalladas de cumplimiento
- [`docs/API_INTEGRATION.md`](../API_INTEGRATION.md) — contratos de API y capa de datos
- [`docs/PROJECT_STATUS.md`](../PROJECT_STATUS.md) — estado actual del proyecto
- [`docs/ci.md`](../ci.md) — pipeline de CI/CD
