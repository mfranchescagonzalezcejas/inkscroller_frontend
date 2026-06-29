# Diseño: Automatización QA — Tests E2E en Flavor Dev

## Enfoque Técnico

Agregar flag `--dart-define=E2E=true` que actúe como sentinel de modo E2E. Helpers en `test/e2e/helpers/` encapsulan: generación de usuarios temporales únicos, bootstrap de la app real con `IntegrationTestWidgetsFlutterBinding`, y limpieza vía Firebase Auth REST API. Ocho archivos de test en `integration_test/` ejercen flujos completos contra Firebase dev y backend dev reales. Cada test es independiente: crea su propio `TestUser`, verifica transiciones de página visibles, y limpia en `tearDown`.

## Decisiones de Arquitectura

| Decisión | Opciones | Trade-offs | Elegido |
|---|---|---|---|
| Detección de modo E2E | A) `bool.fromEnvironment('E2E')` global. B) Parámetro en `mainCommon`. C) Variable de entorno del SO. | A es compile-time, cero overhead, no-op cuando es `false`. B modifica la firma de `mainCommon`. C requiere acceso a `Platform.environment` que difiere entre plataformas. | **A**: constante global `kIsE2E` en `app_environment.dart`, early-return `if (kIsE2E) { ... }` en `main_common.dart`. |
| Bootstrap de la app en tests | A) Llamar `main_dev.dart` como `app.main()`. B) Extraer widget de `mainCommon`. C) Replicar inicialización en helper. | A es el patrón estándar de Flutter integration tests: ejecuta la app real sin refactorizar `mainCommon`. B requiere extraer `runApp` de `mainCommon`. C es propenso a desincronizarse. | **A**: `pumpE2EApp` llama `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` y luego `app.main()`. |
| Cleanup de cuentas temporales | A) Firebase Auth REST API (`accounts:delete`). B) Firebase Admin SDK. C) `FirebaseAuth.instance.currentUser?.delete()` desde el test. | A funciona sin dependencias extras y sin necesidad de que el usuario esté logueado en el test. B requiere credenciales de servicio y paquete `firebase_admin`. C requiere que el test mantenga la sesión abierta hasta el final. | **A**: `deleteTestUser` obtiene ID token vía `signInWithPassword` REST y luego llama `accounts:delete` con la web API key. |
| Estrategia de búsqueda de widgets | A) Agregar `Key` a widgets de producción. B) Buscar por texto visible. C) Buscar por tipo + ancestro. | A mejora robustez del test pero toca código de producción. B es frágil ante cambios de copy. C es verboso. | **Híbrido**: se agregan `Key` estratégicos en campos de auth (mínimo impacto, máxima fiabilidad); el resto se encuentra por texto/tipo. |

## Flujo de Datos

```
Test E2E → pumpE2EApp() → IntegrationTestWidgetsFlutterBinding
                                ↓
                        app.main() (main_dev.dart)
                                ↓
                        mainCommon(flavor: dev)
                                ↓
                    Firebase.initializeApp(dev) + initDI()
                                ↓
                        runApp(MyApp()) → GoRouter real
                                ↓
                        Firebase Auth REST ← deleteTestUser()
```

## Cambios de Archivos

| Archivo | Acción | Descripción |
|---|---|---|
| `lib/core/config/app_environment.dart` | Modificar | Agrega `const bool kIsE2E = bool.fromEnvironment('E2E', defaultValue: false);` |
| `lib/main_common.dart` | Modificar | Assert `flavor == Flavor.dev` cuando `kIsE2E` es `true`; sin cambio de comportamiento cuando es `false` |
| `lib/main_dev.dart` | Modificar | Documenta que propaga el flag E2E (sin cambio funcional, ya que `kIsE2E` es global) |
| `test/e2e/helpers/test_user.dart` | Crear | `TestUser` con `factory fresh()` que genera `test-{ms}-{rnd4}@e2e.inkscroller.dev` |
| `test/e2e/helpers/test_app.dart` | Crear | `pumpE2EApp()` que inicializa binding y llama `app.main()` |
| `test/e2e/helpers/cleanup.dart` | Crear | `deleteTestUser()` vía REST API con reintentos exponenciales |
| `test/e2e/helpers/auth_flows.dart` | Crear | `completeSignUp()`, `completeSignIn()`, `completeSignOut()` reutilizables |
| `integration_test/e2e_sign_up_test.dart` | Crear | Registro válido |
| `integration_test/e2e_sign_in_test.dart` | Crear | Login válido |
| `integration_test/e2e_sign_in_invalid_test.dart` | Crear | Login con password incorrecta |
| `integration_test/e2e_duplicate_email_test.dart` | Crear | Registro con email duplicado |
| `integration_test/e2e_sign_out_test.dart` | Crear | Logout desde settings |
| `integration_test/e2e_guest_navigation_test.dart` | Crear | Guest en library + redirect en profile |
| `integration_test/e2e_authenticated_navigation_test.dart` | Crear | Auth: library → detail → reader → back |
| `integration_test/e2e_delete_account_test.dart` | Crear | Delete account con confirmación + re-login fallido |

## Interfaces / Contratos

### TestUser
```dart
class TestUser {
  final String email;
  final String password;
  final String username;
  final DateTime birthDate;
  factory TestUser.fresh();
}
```

### Helpers
```dart
Future<void> pumpE2EApp(WidgetTester tester);
Future<void> deleteTestUser({required String email, required String password});
Future<void> completeSignUp(WidgetTester tester, TestUser user);
Future<void> completeSignIn(WidgetTester tester, TestUser user);
Future<void> completeSignOut(WidgetTester tester);
```

### Keys agregados a producción (mínimos)
- `const Key('emailField')` en `LoginPage` email `AuthField`
- `const Key('passwordField')` en `LoginPage` password `AuthField`
- `const Key('registerEmailField')` en `RegisterPage` email `AuthField`
- `const Key('registerPasswordField')` en `RegisterPage` password `AuthField`
- `const Key('registerConfirmPasswordField')` en `RegisterPage` confirm `AuthField`
- `const Key('registerUsernameField')` en `RegisterPage` username `AuthField`
- `const Key('registerBirthDateField')` en `RegisterPage` birth date `AuthField`
- `const Key('deleteConfirmField')` en `DeleteAccountDialog` text field

## Estrategia de Testing

| Capa | Qué probar | Enfoque |
|---|---|---|
| Unit | `TestUser.fresh()` genera emails únicos | Test de propiedad (dos instancias distintas, regex match) |
| Integration | `pumpE2EApp`, `deleteTestUser`, flujos auth | Cada test arranca app real, usa Firebase real, limpia en `tearDown` |
| E2E | Navegación guest/auth, delete account | Verifica widgets visibles + rutas de GoRouter por estado del árbol |

## Migración / Rollout

Sin migración de datos. El flag `E2E=true` es compile-time: cuando no está presente, el comportamiento es idéntico al actual. Revertir = eliminar los nuevos archivos de `integration_test/` y `test/e2e/`. Los `Key` agregados a producción son inertes (no afectan UX ni performance).

## Preguntas Abiertas

- [ ] ¿Se dispone de la **Web API Key** del proyecto Firebase dev para el cleanup REST? Requiere `--dart-define=FIREBASE_WEB_API_KEY=...`
- [ ] ¿El backend dev tiene email verification **deshabilitado**? Los tests de registro fallarían si Firebase envía verificación.
- [ ] ¿Cuál es el timeout aceptable para `pumpAndSettle` en el CI actual? Los tests usan 15s por defecto; en emulador lento puede necesitar 30s.
