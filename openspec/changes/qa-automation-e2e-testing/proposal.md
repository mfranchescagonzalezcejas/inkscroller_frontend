# Propuesta: Automatización QA — Tests E2E en Flavor Dev

## Intención

Reemplazar el QA manual en el flavor `dev` con tests E2E automatizados que ejercen Firebase Auth real y el backend real. Hoy se testea manualmente: 52 tests unitarios/widgets, **cero E2E**. El proceso actual es lento, propenso a error humano y no escala.

## Alcance

### Dentro del alcance
- **7 flows E2E**: sign up → perfil → library, login → library → reader, guest → login, credenciales inválidas, email duplicado, logout, delete account
- **Test helpers**: `TestUser.fresh()` con emails únicos, `pumpE2EApp()`, cleanup automático
- **Ejecución local**: `fvm flutter test integration_test/` en emulador Android
- **Modo E2E en la app**: flag `--dart-define=E2E=true` para usar backend dev real sin mocks

### Fuera del alcance
- CI/CD pipeline (no se modifica)
- Golden tests, tests de rendimiento, tests de regresión visual
- Cobertura de flavors `staging` o `pro`
- Device farm / multi-dispositivo / iOS

## Capacidades

> Esta sección es el CONTRACTO entre proposal y specs.
> `sdd-spec` la lee para saber qué archivos de spec crear.

### Nuevas capacidades
- `e2e-test-infrastructure`: Helpers compartidos — `TestUser`, `pumpE2EApp`, detección de modo E2E, cleanup vía Firebase Auth REST API. Archivos en `test/e2e/helpers/`.
- `e2e-auth-flows`: Registro, login, login inválido, email duplicado, logout. Cada test crea su propio usuario temporal y limpia.
- `e2e-navigation-flows`: Guest → browse → login, library → manga detail → reader. Depende de cuentas creadas por `e2e-auth-flows`.
- `e2e-account-management`: Settings → delete account con confirmación escrita "DELETE". El test limpia la cuenta que elimina.

### Capacidades modificadas
Ninguna — no existen specs previos en `openspec/specs/`.

## Enfoque

1. **Detección de modo E2E**: `mainCommon` recibe flag `--dart-define=E2E=true` y omite mocks/overrides, usando Firebase dev + backend dev real.
2. **TestUser**: Factory que genera `test-{timestamp}-{random}@e2e.inkscroller.dev` + password fija. Cada test llama `TestUser.fresh()`.
3. **Cleanup**: Cuentas temporales se eliminan vía Firebase Auth REST API (`accounts:delete`) con la web API key del proyecto dev. Delete account flow se autolimpia.
4. **Estructura**: 1 archivo de test por flow en `integration_test/`. Helpers en `test/e2e/helpers/`.

## Áreas afectadas

| Área | Impacto | Descripción |
|------|---------|-------------|
| `integration_test/` | Nuevo | 7 archivos de test, 1 por flow |
| `test/e2e/helpers/` | Nuevo | `test_user.dart`, `test_app.dart`, `cleanup.dart` |
| `lib/main_common.dart` | Modificado | Detección de flag `E2E=true` |
| `lib/main_dev.dart` | Modificado | Acepta `--dart-define=E2E=true` |

## Riesgos

| Riesgo | Probabilidad | Mitigación |
|--------|-------------|------------|
| Colisión de emails temporales | Baja | Timestamp ms + random 6 dígitos |
| Rate limiting de Firebase Auth | Media | Esperas entre tests, reintentos con backoff |
| Backend dev no disponible | Media | Timeouts claros, solo ejecución local |
| Cuentas huérfanas si test crashea | Media | Cleanup en `tearDown` + script de rescate manual |
| Emulador lento | Baja | `pumpAndSettle` con timeouts generosos |

## Plan de rollback

Revertir el commit. Los tests E2E solo agregan archivos — no modifican comportamiento de producción. El flag `E2E=true` en `main_common.dart` es un early return que no afecta el camino normal sin el flag.

## Dependencias

- Emulador Android con Google Play Services (requerido por Firebase Auth)
- Backend dev (`api.dev.inkscroller.devdigi.dev`) operativo
- Proyecto Firebase dev con email verification **deshabilitada**
- Web API key de Firebase dev (para cleanup vía REST)

## Criterios de éxito

- [ ] Los 7 flows pasan en emulador Android local
- [ ] No quedan cuentas huérfanas tras ejecución completa
- [ ] Tiempo total de ejecución < 5 minutos
- [ ] Cada test es independiente (sin estado compartido entre tests)
