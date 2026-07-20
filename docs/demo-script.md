# 🎬 Demo Video — Script paso a paso

> **Duración estimada:** 6-8 minutos  
> **Formato:** Grabación de pantalla + voz  
> **App:** InkScroller Flutter (dev flavor, API dev)

---

## 🎥 Escena 1 — Introducción (0:00 - 0:30)

**Pantalla:** Tu cara o logo + captura de pantalla de la app

**Texto/Voz:**
> "Hola, soy [tu nombre]. Este es InkScroller, una app de lectura de manga full-stack construida con Flutter y FastAPI como proyecto de fin de máster."

---

## 🎥 Escena 2 — Guest Flow: Home y Catálogo (0:30 - 2:00)

**Pantalla:** App abierta como invitado

| Paso | Acción | Qué se ve | Qué decís |
|------|--------|-----------|-----------|
| 1 | Abrir app | Home con hero carousel, discover, latest chapters | "La app arranca en el Home. Sin registrarse ya se puede explorar." |
| 2 | Swipear hero | Las cards del carrusel se deslizan | "Un carrusel con mangas destacados." |
| 3 | Navegar a Explore (segunda tab) | Catálogo con grid de mangas | "Acá está el catálogo completo con paginación." |
| 4 | Tocar un manga | Manga detail: cover, score, badges, descripción, capítulos | "Cada manga muestra su portada, score de MAL, badges, sinopsis y lista de capítulos." |
| 5 | Scrollear capítulos | Lista de capítulos con indicador de lectura | "Y podemos ver los capítulos disponibles." |

---

## 🎥 Escena 3 — Lector (2:00 - 3:00)

**Pantalla:** Reader abierto

| Paso | Acción | Qué se ve | Qué decís |
|------|--------|-----------|-----------|
| 1 | Tocar un capítulo | Lector en modo scroll | "Abrimos un capítulo. El lector tiene modo scroll continuo." |
| 2 | Swipear/scrollear | Páginas pasando | "Las páginas se cargan desde el CDN de MangaDex." |
| 3 | Tocar para controles | Controles flotantes (brightness, immersive, OLED, back) | "Controles de brillo, modo inmersivo y modo OLED." |
| 4 | Mostrar cambio a modo paged | Opción en settings | "También se puede cambiar a modo paginado desde preferencias." |

---

## 🎥 Escena 4 — Registro + Auth (3:00 - 4:30)

**Pantalla:** Perfil invitado → Registro

| Paso | Acción | Qué se ve | Qué decís |
|------|--------|-----------|-----------|
| 1 | Ir a Profile (3ra tab) | Guest view con icono, texto y botón | "En el perfil como invitado, tenemos opción de iniciar sesión o crear cuenta." |
| 2 | Tocar "Iniciar sesión / Crear cuenta" | Login page | "Podemos iniciar sesión o registrarnos." |
| 3 | Mostrar Register | Formulario de registro con email, contraseña, username, fecha | "El registro pide email, contraseña, nombre de usuario y fecha de nacimiento para el control de edad." |
| 4 | Iniciar sesión con test user | Login exitoso, redirige a Home | "Usamos el usuario de prueba: testuserdevdigi@proton.me." |
| 5 | Ir a Profile | Perfil autenticado con inicial, email, username | "Ya autenticados, vemos nuestro perfil con inicial."

---

## 🎥 Escena 5 — Biblioteca + Progreso (4:30 - 5:30)

**Pantalla:** Catálogo → Biblioteca

| Paso | Acción | Qué se ve | Qué decís |
|------|--------|-----------|-----------|
| 1 | Buscar un manga y abrirlo | Manga detail | "Buscamos un manga y lo agregamos a la biblioteca." |
| 2 | Tocar "Add to library" | Manga añadido, cambia a "In library" | "Con un toque lo añadimos." |
| 3 | Marcar progreso | Sección de tracking con tandas | "Podemos marcar nuestro progreso por tandas de capítulos." |
| 4 | Marcar "Mark through" | Progreso actualizado | "Y el progreso se guarda localmente y se sincroniza con el backend." |
| 5 | Volver al Home | Continue Reading aparece | "En el Home aparece Continue Reading con el manga que estamos leyendo." |

---

## 🎥 Escena 6 — Ajustes y Personalización (5:30 - 6:30)

**Pantalla:** Profile autenticado

| Paso | Acción | Qué se ve | Qué decís |
|------|--------|-----------|-----------|
| 1 | Scrollear ajustes | Preferencias: modo de lectura, idioma, content rating, demographic | "Las preferencias incluyen modo de lectura, idioma de la app, idioma de lectura..." |
| 2 | Tocar Content Rating | Diálogo con opciones (safe, suggestive) según edad | "Filtro de contenido por edad: un usuario menor de 16 solo ve contenido safe." |
| 3 | Tocar Demographic | Diálogo multi-select | "Filtro demográfico: shounen, shoujo, seinen, josei." |

---

## 🎥 Escena 7 — CI/CD y Calidad (6:30 - 7:30)

**Pantalla:** Repositorio en GitHub

| Paso | Acción | Qué se ve | Qué decís |
|------|--------|-----------|-----------|
| 1 | Abrir Actions | GitHub Actions CI pasando | "El proyecto tiene CI/CD con GitHub Actions: analyze + tests + builds." |
| 2 | Mostrar tests | Badge de tests o coverage | "Actualmente más de 550 tests." |
| 3 | Mostrar lefthook | Lefthook config | "Quality gates automáticos en cada commit con lefthook." |
| 4 | Mostrar Dependabot | Dependabot config | "Y Dependabot para mantener las dependencias actualizadas." |

---

## 🎥 Escena 8 — Cierre (7:30 - 8:00)

**Pantalla:** Slide final o logo

> "Eso es todo. El código está en github.com/mfranchescagonzalezcejas/inkscroller_frontend. Gracias por verlo."

---

## ⚡ Tips para la grabación

- **Audio**: Hablá claro, sin prisa. Mejor pausas que titubeos.
- **Entorno**: Grabá en un lugar silencioso.
- **Pantalla**: Limpiá notificaciones, poné la app en modo claro/oscuro consistente.
- **Errores**: Si te equivocás, repetí la frase. Se edita después.
- **Herramientas**: Podés usar OBS Studio (gratuito) para grabar pantalla + micrófono.
