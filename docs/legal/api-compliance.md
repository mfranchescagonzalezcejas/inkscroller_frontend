# Cumplimiento de APIs externas — InkScroller Flutter

> **Última actualización:** Abril 2026  
> **Alcance:** Cliente Flutter — consumidor del backend InkScroller  
> **Referencia backend:** [`Inkscroller_backend/docs/legal/api-compliance.md`](../../../Inkscroller_backend/docs/legal/api-compliance.md)

---

## Tabla de contenidos

1. [Propósito](#1-propósito)
2. [Arquitectura de acceso a APIs](#2-arquitectura-de-acceso-a-apis)
3. [Obligaciones del cliente Flutter](#3-obligaciones-del-cliente-flutter)
4. [MangaDex — reglas para la UI](#4-mangadex--reglas-para-la-ui)
5. [Jikan / MAL — reglas para la UI](#5-jikan--mal--reglas-para-la-ui)
6. [Regla GO / NO-GO para release](#6-regla-go--no-go-para-release)
7. [Registro de revisión](#7-registro-de-revisión)

---

## 1. Propósito

Este documento establece las responsabilidades de cumplimiento legal que corresponden al cliente Flutter de InkScroller, en relación al contenido que proviene (de forma indirecta) de MangaDex y Jikan/MAL.

El cliente Flutter **no llama a MangaDex ni a Jikan directamente**. Sin embargo, muestra contenido de esas fuentes y por ello debe cumplir con requisitos de atribución y uso ético.

---

## 2. Arquitectura de acceso a APIs

```
inkscroller_flutter (este repo)
        │
        ▼ HTTP / Dio → autenticado con Firebase ID token
Inkscroller Backend (FastAPI)
        │
        ├──► MangaDex API v5   (catálogo, capítulos, imágenes)
        └──► Jikan API v4      (enriquecimiento: score, rank, géneros)
```

**El cliente Flutter NUNCA debe:**
- Agregar imports o llamadas directas a `api.mangadex.org`.
- Agregar imports o llamadas directas a `api.jikan.moe`.
- Implementar lógica de fetching que eluda el backend.

---

## 3. Obligaciones del cliente Flutter

### 3.1 Atribución visible en la UI

El contenido que proviene de fuentes externas debe ser atribuido visiblemente al usuario:

| Contenido | Atribución requerida |
|-----------|---------------------|
| Portadas, títulos, descripciones de manga | "Fuente: MangaDex" (mínimo en pantalla de detalle) |
| Score, rank, géneros (MAL/Jikan) | "Score: MAL / Jikan" o similar |
| Capítulos | Nombre del grupo de scanlation (cuando esté disponible en la respuesta) |

### 3.2 No monetización del contenido

- La app no puede estar detrás de un paywall para acceder a contenido de MangaDex.
- No se pueden implementar compras in-app que desbloqueen capítulos de MangaDex.
- Las funcionalidades premium (si existieran) deben ser de conveniencia UX, no de acceso a contenido.

### 3.3 No descarga masiva

- No implementar funcionalidad de descarga de capítulos completos para lectura offline.
- No implementar colas de prefetch que descarguen más de N páginas por adelantado sin interacción del usuario.
- La caché de imágenes (`cached_network_image`, TTL 7 días) es aceptable para UX — no para distribución.

### 3.4 Disclaimer visible

En la pantalla de Perfil/Configuración o en el About de la app, debe figurar:

> "InkScroller no está afiliado a MangaDex ni a MyAnimeList. El contenido pertenece a sus respectivos autores y grupos de scanlation."

---

## 4. MangaDex — reglas para la UI

### 4.1 Qué se puede mostrar

- Portadas de manga (URLs de `uploads.mangadex.org`)
- Títulos, descripciones, estado de publicación
- Lista de capítulos con número, título y fecha
- Páginas de capítulos (URLs de MangaDex@Home CDN)
- Nombre del grupo de scanlation (si el backend lo provee)

### 4.2 Qué NO se puede hacer

| Acción | Motivo |
|--------|--------|
| Descargar y guardar imágenes de páginas permanentemente | Redistribución de contenido protegido |
| Mostrar contenido `erotica/pornographic` sin verificación de edad | ToS de MangaDex + AppStore policies |
| Llamar directamente a `api.mangadex.org` desde Flutter | Viola el patrón de proxy y expone la API key si la hubiera |
| Mostrar capítulos sin mencionar el grupo de scanlation | Falta de atribución a los creadores de la traducción |

### 4.3 Manejo de errores de contenido

Si el backend retorna un capítulo como `external: true`, la UI debe:
1. Mostrar un mensaje claro: "Este capítulo está disponible en [nombre del sitio externo]".
2. Ofrecer abrir el `externalUrl` en el navegador.
3. NO intentar renderizar el capítulo en el reader interno.

---

## 5. Jikan / MAL — reglas para la UI

### 5.1 Disclaimer de no afiliación

En cualquier pantalla donde se muestren datos provenientes de MAL (score, rank, popularidad), incluir una nota:

> "Score y ranking: MyAnimeList (vía Jikan). InkScroller no está afiliado a MyAnimeList."

### 5.2 Datos nulos / no disponibles

Dado que Jikan puede fallar o no encontrar el manga, la UI debe manejar gracefully:

```dart
// ✅ Correcto
Text(manga.score != null ? '${manga.score}' : 'Sin puntaje MAL')

// ❌ Incorrecto — crash si score es null
Text('Score: ${manga.score!}')
```

### 5.3 Feature flag de enriquecimiento

Si el backend implementa `ENABLE_JIKAN_ENRICHMENT=false`, la UI debe degradar sin errores:
- Ocultar campos de score/rank si son null.
- No mostrar mensajes de error al usuario por datos MAL faltantes.

---

## 6. Regla GO / NO-GO para release

> **Referencia completa:** [`docs/release/checklist-legal.md`](../release/checklist-legal.md)

### Resumen rápido

| Condición | Decisión |
|-----------|----------|
| La app llama directamente a MangaDex o Jikan | ❌ NO-GO inmediato |
| Existe funcionalidad de descarga masiva de capítulos | ❌ NO-GO inmediato |
| Contenido adulto sin restricción de edad | ❌ NO-GO inmediato |
| No hay disclaimer de no afiliación visible | 🟡 Advertencia — documentar |
| No hay atribución de scanlation group en el reader | 🟡 Advertencia — documentar |
| Score/rank MAL se muestran sin nota de fuente | 🟡 Advertencia — documentar |

---

## 7. Registro de revisión

| Fecha | Versión | Cambio | Autor |
|-------|---------|--------|-------|
| 2026-04-07 | 1.0 | Creación inicial del documento | InkScroller Team |


