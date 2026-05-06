# Evidencia P0-F10 — Auditoría de red Flutter (no llamadas directas a MangaDex/Jikan)

> **Ítem checklist:** 1.1 / 1.2 / 1.3  
> **Fecha de auditoría:** 2026-04-09  
> **Resultado:** ✅ PASS — Flutter no realiza ninguna llamada directa a `api.mangadex.org` ni `api.jikan.moe`

---

## Metodología

Auditoría estática completa del árbol `lib/` del proyecto Flutter (`inkscroller_flutter`).  
Herramienta: `rg` (ripgrep) sobre todos los archivos `.dart`.

---

## Búsqueda 1 — Dominios externos hardcodeados

```
rg -i "mangadex|jikan|api\.mangadex\.org|api\.jikan\.moe|myanimelist" lib/ --glob "*.dart" -n
```

**Resultado:**

```
lib/core/constants/app_constants.dart:13:  // MangaDex
lib/features/library/data/datasources/library_remote_ds.dart:13:  /// a MangaDex tag UUID on the backend.
lib/features/library/domain/entities/manga.dart:31:  /// Source: MangaDex returns this in the "originalLanguage" field.
lib/features/library/domain/entities/manga.dart:36:  /// - MangaDex: "originalLanguage" field maps to type
lib/features/library/data/mappers/mangadex_tag_mapper.dart:1:/// Maps MangaDex tag UUIDs to their human-readable English names.
lib/features/library/data/mappers/mangadex_tag_mapper.dart:3:/// MangaDex returns tags as opaque UUID strings.
lib/features/library/data/mappers/mangadex_tag_mapper.dart:6:class MangaDexTagMapper {
lib/features/library/data/mappers/mangadex_tag_mapper.dart:27:  /// Returns the human-readable tag name for the given MangaDex tag [id],
```

**Análisis:** Todos los matches son **comentarios/docstrings de documentación** o **nombres de clases de dominio** (mapper local de UUIDs a strings legibles). Ninguno contiene una URL o llamada HTTP a un dominio externo.

---

## Búsqueda 2 — URLs HTTP a dominios externos

```
rg "http[s]?://api\.(mangadex|jikan)" lib/ --glob "*.dart" -n
```

**Resultado:** _(sin salida — 0 matches)_ ✅

---

## Búsqueda 3 — Todas las URLs HTTP hardcodeadas en lib/

```
rg "http[s]?://" lib/ --glob "*.dart" -n
```

**Resultado (completo):**

```
lib/core/config/app_environment.dart:15:  static const String localBaseUrl = 'http://127.0.0.1:8000';
lib/core/config/app_environment.dart:18:  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:8000';
lib/core/config/app_environment.dart:29:  static const String cloudRunBaseUrl = 'https://inkscroller-backend-708894048002.us-central1.run.app';
lib/core/config/app_environment.dart:68:    addCandidate('http://localhost:8000');
```

**Análisis:** Las 4 URLs son **exclusivamente URLs del backend InkScroller**:
- `127.0.0.1:8000` → backend local (desarrollo)
- `10.0.2.2:8000` → backend vía Android emulator loopback
- `inkscroller-backend-*.us-central1.run.app` → backend en Cloud Run (dev)
- `localhost:8000` → backend local (fallback)

Ninguna URL apunta a `api.mangadex.org`, `api.jikan.moe`, ni ningún dominio de tercero externo.

---

## Búsqueda 4 — Instancias de Dio

```
rg "Dio\s*\(" lib/ --glob "*.dart" -n
```

**Resultado:**

```
lib/core/network/dio_client.dart:34:    dio = Dio(
```

**Análisis:** Solo existe **una instancia de `Dio`** en todo el proyecto, creada en `DioClient`. Ninguna feature ni datasource instancia su propio cliente Dio.

---

## Búsqueda 5 — Clientes HTTP directos

```
rg "http\.get|http\.post|HttpClient\(\)|Uri\.parse\s*\(" lib/ --glob "*.dart" -n
```

**Resultado:**

```
lib/features/library/presentation/pages/reader_page.dart:173:  final uri = Uri.parse(externalUrl!);
lib/features/library/presentation/pages/manga_detail_page.dart:186:  final uri = Uri.parse(chapter.externalUrl!);
```

**Análisis:** Los únicos `Uri.parse()` son para abrir URLs externas de capítulos marcados como `external: true` **en el navegador del sistema** vía `url_launcher` (P0-F2, ya cerrado). No son llamadas HTTP en el cliente — son apertura de browser externo con una URL que proviene del backend InkScroller.

---

## Búsqueda 6 — Datasources: verificación de inyección única de DioClient

```
rg "Dio|DioClient|baseUrl" lib/features/ --glob "*_impl.dart" -n
```

**Resultado:** Todos los datasource impls (`library_remote_ds_impl`, `home_remote_ds_impl`, `preferences_remote_ds_impl`, `user_profile_remote_ds_impl`) reciben `DioClient` inyectado vía constructor — ninguno crea su propio cliente con URL externa.

---

## Arquitectura de red confirmada

```
Flutter App
    └── DioClient (singleton, registrado en injection.dart)
            ├── baseUrl = ApiConfig.baseUrl = FlavorConfig.instance.apiBaseUrl
            │       → --dart-define=API_BASE_URL (runtime)
            │       → fallback: 127.0.0.1:8000 (dev local)
            ├── _BaseUrlFallbackInterceptor (fallback entre candidatos InkScroller)
            └── _AuthInterceptor (Bearer token en /users/*)
                    ↓
         Backend InkScroller (Cloud Run / local)
                    ↓
         Backend → MangaDex API / Jikan API  (invisible para Flutter)
```

Flutter **nunca** comunica con `api.mangadex.org` ni `api.jikan.moe` directamente.  
Toda la comunicación de Flutter es con el backend InkScroller.

---

## Archivos auditados

| Archivo | Rol | Resultado |
|---------|-----|-----------|
| `lib/core/network/dio_client.dart` | Cliente HTTP único | ✅ baseUrl = backend InkScroller |
| `lib/core/config/api_config.dart` | Resuelve baseUrl | ✅ → `FlavorConfig.apiBaseUrl` |
| `lib/core/config/app_environment.dart` | URLs hardcodeadas | ✅ Solo URLs de backend local/Cloud Run |
| `lib/core/di/injection.dart` | Registro DI del DioClient | ✅ Un solo DioClient compartido |
| `lib/features/library/data/datasources/library_remote_ds_impl.dart` | DS library | ✅ Usa DioClient inyectado |
| `lib/features/home/data/datasources/home_remote_ds_impl.dart` | DS home | ✅ Usa DioClient inyectado |
| `lib/features/preferences/data/datasources/preferences_remote_ds_impl.dart` | DS preferences | ✅ Usa DioClient inyectado |
| `lib/features/profile/data/datasources/user_profile_remote_ds_impl.dart` | DS profile | ✅ Usa DioClient inyectado |
| `lib/features/library/data/mappers/mangadex_tag_mapper.dart` | Mapper UUIDs → labels | ✅ Tabla estática local, sin HTTP |

---

## Conclusión

**P0-F10: PASS ✅**

- 0 llamadas HTTP directas a `api.mangadex.org` en código Flutter
- 0 llamadas HTTP directas a `api.jikan.moe` en código Flutter
- 0 instancias de Dio con baseUrl externo
- Arquitectura: Flutter → backend InkScroller (único destino) → MangaDex/Jikan (backend only)
- Ítems checklist 1.1, 1.2, 1.3: **✅ GO**
