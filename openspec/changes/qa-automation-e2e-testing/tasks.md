# Tasks: Automatización QA — Tests E2E en Flavor Dev

## Pronóstico de Carga de Trabajo

| Campo | Valor |
|-------|-------|
| Líneas estimadas cambiadas | ~1200-1400 |
| Riesgo presupuesto 400 líneas | **Alto** |
| PRs encadenados recomendados | **Sí** |
| División sugerida | PR 1 → PR 2 → PR 3 |
| Estrategia de entrega | stacked-to-main |
| Estrategia de cadena | stacked-to-main |

### Unidades de Trabajo Sugeridas

| Unidad | Objetivo | PR Probable | Notas |
|--------|----------|-------------|-------|
| 1 | Infraestructura E2E + helpers + keys de producción | PR 1 | Base; incluye flag `kIsE2E`, keys en widgets, 4 helpers. Tests no incluidos. |
| 2 | Tests de autenticación (5 tests) | PR 2 | Dependiente de PR 1; sign up, sign in, sign in inválido, email duplicado, sign out. |
| 3 | Tests de navegación + delete account (3 tests) | PR 3 | Dependiente de PR 1; guest navigation, authenticated navigation, delete account. |

**Decisión necesaria antes de apply:** Sí
**PRs encadenados recomendados:** Sí
**Estrategia de cadena:** stacked-to-main
**Riesgo presupuesto 400 líneas:** Alto

---

## Fase 1: Fundación — Flag E2E y Configuración

- [x] T1 — Agregar `kIsE2E` en `app_environment.dart`
  - **Archivos:** `lib/core/config/app_environment.dart`
  - **Dependencias:** ninguna
  - **Esfuerzo:** Bajo
  - **Criterio de aceptación:** `const bool kIsE2E = bool.fromEnvironment('E2E', defaultValue: false)` existe como constante global accesible. Sin `--dart-define=E2E=true`, el valor es `false`.
  - **Detalles:** Agregar la constante al final de la clase `AppEnvironment`, antes del cierre. Importar `package:flutter/foundation.dart` ya está presente. La constante es compile-time, cero overhead runtime.

- [x] T2 — Assert de flavor en `main_common.dart` cuando E2E
  - **Archivos:** `lib/main_common.dart`
  - **Dependencias:** T1
  - **Esfuerzo:** Bajo
  - **Criterio de aceptación:** Si `kIsE2E` es `true` y `flavor != Flavor.dev`, el assert falla con mensaje claro. Si `kIsE2E` es `false`, cero cambio de comportamiento.
  - **Detalles:** Importar `app_environment.dart`. Agregar `assert(!kIsE2E || flavor == Flavor.dev, 'E2E mode requires dev flavor');` como primera línea de `mainCommon`. El assert es no-op en release mode.

- [x] T3 — Documentar flag E2E en `main_dev.dart`
  - **Archivos:** `lib/main_dev.dart`
  - **Dependencias:** T1
  - **Esfuerzo:** Bajo
  - **Criterio de aceptación:** Comentario doc que explica el uso de `--dart-define=E2E=true` y `--dart-define=FIREBASE_WEB_API_KEY=...`. Sin cambio funcional.
  - **Detalles:** Agregar bloque `///` antes de `Future<void> main()` explicando los flags disponibles.

## Fase 2: Keys en Widgets de Producción

- [x] T4 — Agregar keys de test en widgets de auth y settings
  - **Archivos:**
    - `lib/features/auth/presentation/pages/login_page.dart` — `Key('emailField')` en email AuthField, `Key('passwordField')` en password AuthField
    - `lib/features/auth/presentation/pages/register_page.dart` — `Key('registerEmailField')`, `Key('registerPasswordField')`, `Key('registerConfirmPasswordField')`, `Key('registerUsernameField')`, `Key('registerBirthDateField')`
    - `lib/features/settings/presentation/widgets/delete_account_dialog.dart` — `Key('deleteConfirmField')` en el TextField
  - **Dependencias:** ninguna
  - **Esfuerzo:** Bajo
  - **Criterio de aceptación:** Los 8 keys están presentes como `const Key(...)` en los widgets correspondientes. Los keys son inertes — no afectan UX ni performance. Los tests pueden encontrar los widgets con `find.byKey(const Key('emailField'))`.
  - **Detalles:** En `AuthField`, el key se pasa al constructor `super.key` del widget padre (ya soportado). En `DeleteAccountDialog`, agregar `key: const Key('deleteConfirmField')` al `TextField` en línea 70.

## Fase 3: Helpers E2E

- [x] T5 — Crear `TestUser` con `factory fresh()`
  - **Archivos:** `test/e2e/helpers/test_user.dart`
  - **Dependencias:** ninguna
  - **Esfuerzo:** Bajo
  - **Criterio de aceptación:** `TestUser.fresh()` genera email único con patrón `test-{ms}-{rnd4}@e2e.inkscroller.dev`. Password fija `TestPass123!`. Username aleatorio `testuser{random}`. BirthDate = hace 20 años. Dos llamadas consecutivas producen emails distintos.
  - **Detalles:** Usar `DateTime.now().millisecondsSinceEpoch` + `Random().nextInt(9000) + 1000` para unicidad. Exponer `email`, `password`, `username`, `birthDate` como campos `final`.

- [x] T6 — Crear `pumpE2EApp()` para bootstrap de app real
  - **Archivos:** `test/e2e/helpers/test_app.dart`
  - **Dependencias:** T1
  - **Esfuerzo:** Medio
  - **Criterio de aceptación:** `pumpE2EApp(tester)` inicializa `IntegrationTestWidgetsFlutterBinding`, llama `app.main()` (de `main_dev.dart`), y espera a que el widget tree esté estable con `pumpAndSettle(timeout: Duration(seconds: 15))`. Sin mocks.
  - **Detalles:** Importar `package:integration_test/integration_test.dart` y `package:inkscroller_flutter/main_dev.dart` como `app`. Usar `TestWidgetsFlutterBinding.ensureInitialized()` como primer paso. La función no recibe parámetros de configuración — la app se configura sola vía `--dart-define`.

- [x] T7 — Crear `deleteTestUser()` vía Firebase Auth REST API
  - **Archivos:** `test/e2e/helpers/cleanup.dart`
  - **Dependencias:** ninguna
  - **Esfuerzo:** Medio
  - **Criterio de aceptación:** `deleteTestUser(email, password)` obtiene ID token vía `signInWithPassword` REST, luego llama `accounts:delete` con la web API key. Reintentos con backoff exponencial (max 3). No falla el test si la cuenta ya no existe (trata `user-not-found` como éxito).
  - **Detalles:** Usar `http` package. Endpoints: `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey` y `https://identitytoolkit.googleapis.com/v1/accounts:delete?key=$apiKey`. La API key viene de `const String.fromEnvironment('FIREBASE_WEB_API_KEY')`. Manejar `EMAIL_NOT_FOUND` y `INVALID_PASSWORD` como "cuenta ya no existe".

- [x] T8 — Crear `auth_flows.dart` con flujos reutilizables
  - **Archivos:** `test/e2e/helpers/auth_flows.dart`
  - **Dependencias:** T4, T5
  - **Esfuerzo:** Medio
  - **Criterio de aceptación:** `completeSignUp(tester, user)` completa el formulario de registro usando los keys de producción y presiona "Crear cuenta". `completeSignIn(tester, user)` completa login. `completeSignOut(tester)` navega a settings y presiona "Cerrar sesión". Cada función usa `tester.enterText(find.byKey(...))` y `tester.pumpAndSettle()`.
  - **Detalles:** `completeSignUp` debe: 1) navegar a `/register` si no está ahí, 2) llenar email, username, password, confirm password, birth date (tap para abrir date picker, seleccionar fecha), 3) tap "Crear cuenta", 4) esperar navegación a home. `completeSignOut` debe navegar a settings tab y tap "Cerrar sesión".

## Fase 4: Tests de Autenticación

- [x] T9 — `e2e_sign_up_test.dart` — Registro con datos válidos
  - **Archivos:** `integration_test/e2e_sign_up_test.dart`
  - **Dependencias:** T5, T6, T7, T8
  - **Esfuerzo:** Medio
  - **Criterio de aceptación:** Test crea `TestUser.fresh()`, llama `completeSignUp()`, verifica que la app navega a home (encuentra widget de library o home), verifica estado autenticado. `tearDown` llama `deleteTestUser()`.
  - **Detalles:** Estructura: `setUp` crea user, `testWidgets` ejecuta flujo, `tearDown` limpia. Verificar transición de página visible, no solo estado interno. Timeout de 15s en `pumpAndSettle`.

- [x] T10 — `e2e_sign_in_test.dart` — Login con credenciales válidas
  - **Archivos:** `integration_test/e2e_sign_in_test.dart`
  - **Dependencias:** T5, T6, T7, T8
  - **Esfuerzo:** Medio
  - **Criterio de aceptación:** `setUp` registra usuario con `completeSignUp()` + `completeSignOut()`. Test ejecuta `completeSignIn()`, verifica navegación a home. `tearDown` limpia.
  - **Detalles:** El setUp debe crear el usuario y volver a la pantalla de login antes del test.

- [x] T11 — `e2e_sign_in_invalid_test.dart` — Login con password incorrecta
  - **Archivos:** `integration_test/e2e_sign_in_invalid_test.dart`
  - **Dependencias:** T5, T6, T7
  - **Esfuerzo:** Bajo
  - **Criterio de aceptación:** `setUp` registra usuario. Test ingresa email correcto + password incorrecta, verifica mensaje de error visible en pantalla, verifica que permanece en login. `tearDown` limpia.
  - **Detalles:** Buscar texto de error por widget `Text` que contenga "Credenciales" o "invalid" o "incorrecta". Verificar que NO navega a home.

- [x] T12 — `e2e_duplicate_email_test.dart` — Registro con email duplicado
  - **Archivos:** `integration_test/e2e_duplicate_email_test.dart`
  - **Dependencias:** T5, T6, T7, T8
  - **Esfuerzo:** Bajo
  - **Criterio de aceptación:** `setUp` registra usuario con `completeSignUp()` + `completeSignOut()`. Test intenta registrar con el mismo email, verifica mensaje de error, permanece en registro. `tearDown` limpia.
  - **Detalles:** El segundo registro debe fallar en el backend. Verificar texto de error visible.

- [x] T13 — `e2e_sign_out_test.dart` — Logout desde settings
  - **Archivos:** `integration_test/e2e_sign_out_test.dart`
  - **Dependencias:** T5, T6, T7, T8
  - **Esfuerzo:** Bajo
  - **Criterio de aceptación:** `setUp` registra usuario. Test ejecuta `completeSignOut()`, verifica que la app vuelve a estado guest (login visible o home sin usuario). `tearDown` limpia.
  - **Detalles:** Verificar que `FirebaseAuth.instance.currentUser` es `null` después del sign out (si es accesible desde el test), o verificar que la pantalla de login es visible.

## Fase 5: Tests de Navegación

- [x] T14 — `e2e_guest_navigation_test.dart` — Guest browsing y redirect
  - **Archivos:** `integration_test/e2e_guest_navigation_test.dart`
  - **Dependencias:** T6
  - **Esfuerzo:** Medio
  - **Criterio de aceptación:** Test 1: Guest navega a Library, verifica que carga datos reales (mangas visibles), NO hay redirect a login. Test 2: Guest intenta acceder a `/profile`, verifica redirect automático a `/login`.
  - **Detalles:** No necesita `TestUser` ni cleanup. Usar `pumpE2EApp()` y navegar programáticamente con `GoRouter.of(context).go('/profile')`. Verificar que library es pública según `_protectedRoutes`.

- [x] T15 — `e2e_authenticated_navigation_test.dart` — Library → detail → reader → back
  - **Archivos:** `integration_test/e2e_authenticated_navigation_test.dart`
  - **Dependencias:** T5, T6, T7, T8
  - **Esfuerzo:** Alto
  - **Criterio de aceptación:** Test registra usuario, navega a Library, selecciona un manga de la lista, abre primer capítulo, verifica URL `/manga/:id/chapter/:chapterId`. Presiona back, verifica vuelta a detail. `tearDown` limpia.
  - **Detalles:** El test depende de que el backend dev tenga datos reales. Si no hay mangas, el test debe fallar con mensaje claro (no NPE). Tap en el primer manga de la lista, luego tap en el primer capítulo.

## Fase 6: Tests de Gestión de Cuenta

- [x] T16 — `e2e_delete_account_test.dart` — Eliminación de cuenta completa
  - **Archivos:** `integration_test/e2e_delete_account_test.dart`
  - **Dependencias:** T5, T6, T7, T8
  - **Esfuerzo:** Alto
  - **Criterio de aceptación:** Test 1: Registra usuario, navega a Settings, tap "Eliminar cuenta", escribe "DELETE", confirma. Verifica redirect a `/login` y estado guest. Test 2: Intenta re-login con las mismas credenciales, verifica que falla con error. Test 3: Verifica que sin escribir "DELETE" el botón está deshabilitado. No necesita `tearDown` — la cuenta ya fue eliminada.
  - **Detalles:** Encontrar el dialog por texto "Eliminar cuenta". El campo de confirmación se encuentra con `find.byKey(const Key('deleteConfirmField'))`. Verificar que el botón "Eliminar" está deshabilitado hasta que se escriba "DELETE" exacto (case-sensitive).

---

## Resumen de Cobertura

| Fase | Tareas | Enfoque |
|------|--------|---------|
| Fase 1: Fundación | 3 | Flag E2E, assert, docs |
| Fase 2: Keys producción | 1 | 8 keys en 3 widgets |
| Fase 3: Helpers | 4 | TestUser, pumpApp, cleanup, authFlows |
| Fase 4: Auth tests | 5 | Sign up, in, invalid, duplicate, out |
| Fase 5: Navigation tests | 2 | Guest, authenticated |
| Fase 6: Account tests | 1 | Delete account |
| **Total** | **16** | |
