# Spec: Automatización QA — Tests E2E en Flavor Dev

## Capability: e2e-test-infrastructure

### Descripción

Helpers compartidos que todos los tests E2E utilizan: generación de usuarios temporales únicos, detección del modo E2E en el bootstrap de la app, función `pumpE2EApp()` que envuelve la app real con `integration_test` binding, y limpieza automática de cuentas vía Firebase Auth REST API.

### Archivos

- `test/e2e/helpers/test_user.dart` — Factory `TestUser.fresh()` con email único (`test-{timestamp}-{random}@e2e.inkscroller.dev`), password fija (`TestPass123!`), username aleatorio
- `test/e2e/helpers/test_app.dart` — `pumpE2EApp()` que inicializa `IntegrationTestWidgetsFlutterBinding`, arranca la app real con `mainCommon(flavor: Flavor.dev)` y espera a que esté estable
- `test/e2e/helpers/cleanup.dart` — `deleteTestUser(email, password)` vía Firebase Auth REST API (`accounts:delete`) usando la web API key del proyecto dev
- `lib/main_common.dart` — Detección de flag `--dart-define=E2E=true` (early return que no afecta el camino normal sin el flag)
- `lib/main_dev.dart` — Acepta y propaga el flag E2E

### Escenarios

#### Escenario: TestUser.fresh() genera emails únicos
- DADO que dos tests llaman `TestUser.fresh()` con diferencia de ≥1ms
- CUANDO se comparan los emails generados
- ENTONCES los emails son distintos
- Y ambos matchean el patrón `test-{digits}-{digits}@e2e.inkscroller.dev`

#### Escenario: pumpE2EApp() arranca la app real
- DADO un emulador Android con Google Play Services
- CUANDO un test llama `await pumpE2EApp(tester)`
- ENTONCES la app se inicializa con Firebase dev real
- Y el widget tree está estable (`pumpAndSettle` completa sin timeout)

#### Escenario: Cleanup elimina cuenta temporal
- DADO una cuenta creada con `TestUser.fresh()`
- CUANDO se llama `await deleteTestUser(email, password)`
- ENTONCES la cuenta se elimina del proyecto Firebase dev
- Y un intento de login con esas credenciales falla con `user-not-found`

#### Escenario: Flag E2E no afecta producción
- DADO que la app se arranca SIN `--dart-define=E2E=true`
- CUANDO `mainCommon` se ejecuta
- ENTONCES el comportamiento es idéntico al actual (el flag es un early return no-op)

### Criterios de aceptación

- [ ] `TestUser.fresh()` produce emails únicos incluso bajo ejecución paralela de tests
- [ ] `pumpE2EApp()` funciona en emulador Android local sin mocks
- [ ] `deleteTestUser()` limpia la cuenta incluso si el test falló (se usa en `tearDown`)
- [ ] El flag `E2E=true` en `main_common.dart` es un early return que no modifica el camino normal
- [ ] Los helpers no importan `mocktail` ni ningún mock — usan servicios reales

---

## Capability: e2e-auth-flows

### Descripción

Cinco tests E2E que ejercen los flujos completos de autenticación contra Firebase Auth real y el backend real. Cada test crea su propio `TestUser.fresh()` y limpia en `tearDown`.

### Archivos

- `integration_test/e2e_sign_up_test.dart` — Registro con datos válidos
- `integration_test/e2e_sign_in_test.dart` — Login con credenciales válidas
- `integration_test/e2e_sign_in_invalid_test.dart` — Login con password incorrecta
- `integration_test/e2e_duplicate_email_test.dart` — Registro con email ya existente
- `integration_test/e2e_sign_out_test.dart` — Logout

### Escenarios

#### Escenario: Registro con datos válidos
- DADO un `TestUser.fresh()` con email, password y username únicos
- CUANDO el usuario completa el formulario de registro (email, password, confirmación, username, fecha de nacimiento) y presiona "Crear cuenta"
- ENTONCES la cuenta se crea en Firebase Auth
- Y el perfil se guarda en el backend
- Y la app navega a la pantalla principal (home)
- Y el estado de autenticación refleja el usuario logueado
- TEARDOWN `deleteTestUser()` limpia la cuenta

#### Escenario: Login con credenciales válidas
- DADO un `TestUser.fresh()` previamente registrado (sign up en `setUp`)
- CUANDO el usuario ingresa email y password correctos en la pantalla de login y presiona "Iniciar sesión"
- ENTONCES la app navega a la pantalla principal (home)
- Y el estado de autenticación refleja el usuario logueado

#### Escenario: Login con password incorrecta
- DADO un `TestUser.fresh()` previamente registrado
- CUANDO el usuario ingresa el email correcto pero un password incorrecto
- ENTONCES la app muestra un mensaje de error ("Credenciales inválidas" o equivalente)
- Y la app permanece en la pantalla de login
- Y el estado de autenticación NO cambia (sigue siendo guest)

#### Escenario: Registro con email duplicado
- DADO un `TestUser.fresh()` previamente registrado (email ya existe)
- CUANDO otro intento de registro usa el mismo email
- ENTONCES la app muestra un mensaje de error ("El email ya está registrado" o equivalente)
- Y la app permanece en la pantalla de registro
- Y no se crea una cuenta duplicada

#### Escenario: Logout
- DADO un usuario autenticado en la pantalla de settings
- CUANDO el usuario presiona "Cerrar sesión" (o equivalente)
- ENTONCES la sesión se cierra en Firebase Auth
- Y la app navega a la pantalla de login o home en modo guest
- Y el estado de autenticación refleja guest (user = null)

### Criterios de aceptación

- [ ] Cada test es independiente — no comparte estado con otros tests
- [ ] Cada test crea y limpia su propio `TestUser` (incluso si falla)
- [ ] Los tests verifican transiciones de página visibles (no solo estado interno)
- [ ] Los mensajes de error se verifican por texto visible en pantalla
- [ ] Tiempo total de los 5 tests < 3 minutos

---

## Capability: e2e-navigation-flows

### Descripción

Dos tests E2E que verifican el routing y la navegación: guest restringido de rutas protegidas, y flujo autenticado library → manga detail → reader → back.

### Archivos

- `integration_test/e2e_guest_navigation_test.dart` — Guest browsing y redirect a login
- `integration_test/e2e_authenticated_navigation_test.dart` — Library → detail → reader → back

### Escenarios

#### Escenario: Guest browsea library sin restricción
- DADO un usuario sin autenticar (guest)
- CUANDO la app arranca y navega a la pestaña Library
- ENTONCES la library carga datos reales del backend dev
- Y se muestran mangas en la lista
- Y NO hay redirect a login (library es pública)

#### Escenario: Guest redirigido a login en ruta protegida
- DADO un usuario sin autenticar
- CUANDO intenta acceder a la ruta `/profile` (ruta protegida)
- ENTONCES el router redirige automáticamente a `/login`
- Y la pantalla de login es visible

#### Escenario: Usuario autenticado navega library → detail → reader
- DADO un usuario autenticado con `TestUser.fresh()`
- CUANDO navega a Library, selecciona un manga de la lista, y abre el primer capítulo
- ENTONCES la app navega a `/manga/:mangaId` (página de detalle)
- Y luego a `/manga/:mangaId/chapter/:chapterId` (reader)
- Y el reader muestra contenido del capítulo

#### Escenario: Back desde reader vuelve a detail
- DADO un usuario en el reader (`/manga/:mangaId/chapter/:chapterId`)
- CUANDO presiona el botón "back" del sistema o de la app
- ENTONCES la app navega a `/manga/:mangaId` (página de detalle)
- Y los datos del manga siguen visibles

### Criterios de aceptación

- [ ] Los tests de navegación verifican URLs/rutas, no solo widgets visibles
- [ ] El test de guest usa datos reales del backend (no mocks de manga)
- [ ] El test autenticado completa el flujo completo library → reader
- [ ] El back navigation respeta el stack de GoRouter
- [ ] `_protectedRoutes` solo contiene `/profile` — library, explore, home son públicas

---

## Capability: e2e-account-management

### Descripción

Un test E2E que ejerce el flujo completo de eliminación de cuenta: settings → delete account → tipear "DELETE" → confirmar → cuenta eliminada → redirect a modo guest. Verifica que la cuenta queda realmente eliminada (no se puede re-login).

### Archivos

- `integration_test/e2e_delete_account_test.dart` — Flujo completo de eliminación de cuenta

### Escenarios

#### Escenario: Eliminación de cuenta con confirmación
- DADO un usuario autenticado con `TestUser.fresh()`
- CUANDO navega a Settings, presiona "Eliminar cuenta", tipea "DELETE" en el campo de confirmación, y presiona "Eliminar"
- ENTONCES el dialog muestra un indicador de carga mientras se procesa
- Y la cuenta se elimina en Firebase Auth y en el backend
- Y el dialog se cierra
- Y la app navega a `/login` (redirect post-eliminación)
- Y el estado de autenticación refleja guest (user = null)

#### Escenario: Cuenta eliminada no puede re-login
- DADO una cuenta que fue eliminada en el escenario anterior
- CUANDO se intenta hacer login con las mismas credenciales
- ENTONCES el login falla con error "Credenciales inválidas" o "user-not-found"
- Y la app permanece en la pantalla de login

#### Escenario: Dialog de eliminación sin confirmación
- DADO un usuario en el dialog de eliminación de cuenta
- CUANDO NO tipea "DELETE" en el campo de confirmación
- ENTONCES el botón "Eliminar" está deshabilitado
- Y al presionar "Cancelar" el dialog se cierra sin eliminar nada
- Y la cuenta sigue activa

### Criterios de aceptación

- [ ] El test verifica la eliminación real (intento de re-login falla)
- [ ] El test NO necesita cleanup manual — la cuenta ya fue eliminada por el flujo
- [ ] El dialog requiere exactamente "DELETE" (case-sensitive) para habilitar el botón
- [ ] Después de eliminar, `FirebaseAuth.instance.signOut()` se llama automáticamente
- [ ] El redirect post-eliminación va a `/login` (definido en `AccountSection._showDeleteAccountDialog`)

---

## Resumen de cobertura

| Capability | Tests | Happy paths | Edge cases | Error states |
|---|---|---|---|---|
| e2e-test-infrastructure | — (helpers) | 3 escenarios | 1 (unicidad emails) | — |
| e2e-auth-flows | 5 | 3 (sign up, sign in, sign out) | 1 (email duplicado) | 1 (password incorrecta) |
| e2e-navigation-flows | 2 | 3 (guest browse, auth navigation, back) | 1 (guest redirect) | — |
| e2e-account-management | 1 | 1 (delete account) | 1 (sin confirmación) | 1 (re-login falla) |
| **Total** | **8 tests** | **10 escenarios** | **3 edge cases** | **2 error states** |
