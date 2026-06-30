# Exploration: QA Automation — E2E Tests for Local Dev

## Context

Replace manual QA testing on the **dev flavor** with automated E2E tests that exercise real Firebase Auth and the real backend API. Tests run **locally** on an Android emulator or physical device — no CI changes needed.

## Current State

- **52 unit/widget tests** cover isolated layers (use cases, repositories, data sources, providers, widgets)
- **Mocking**: mocktail + Dio `HttpClientAdapter` + Riverpod `ProviderScope.overrides`
- **No E2E tests** that exercise the real app against real Firebase + real backend
- **Existing `integration_test/library_flow_test.dart`** uses mocked providers, not real data
- **QA is manual**: user runs the app on dev and manually tests flows

## Target Flows

### Core flows (replace manual QA)

1. **Sign up → complete profile → browse** — Crear cuenta en Firebase dev, completar metadata de perfil, navegar a library/home
2. **Login → library → manga detail → reader** — El journey principal del usuario autenticado
3. **Settings → delete account** — Confirmación escrita "DELETE", eliminación de cuenta, redirect
4. **Guest → browse → login** — Modo invitado, navegación, transición a usuario autenticado
5. **Login with invalid credentials** — Error message, no redirect, formulario se mantiene
6. **Logout** — Settings → sign out → redirect a login/guest home
7. **Sign up with existing email** — Error "email ya registrado", no se crea cuenta duplicada

### Test data strategy

- **Temporary emails**: `test-{timestamp}-{random}@e2e.inkscroller.dev` — timestamp + random garantiza unicidad
- **Password**: fija (`TestPass123!`) para simplificar
- **Email verification**: deshabilitada en Firebase dev para que las cuentas se creen sin confirmación
- **Cleanup**: 
  - Delete account flow: el propio test limpia la cuenta
  - Sign-up-only tests: cleanup via Firebase Auth REST API (`POST accounts:delete` con web API key de dev)

## Architecture

- Framework: `integration_test` (ya en pubspec.yaml)
- Runner: `fvm flutter test integration_test/` en emulador Android
- Dev backend: `https://api.dev.inkscroller.devdigi.dev`
- Firebase: proyecto dev de Firebase con dart-define existentes

### Test helpers needed

- `test/e2e/helpers/test_user.dart` — `TestUser.fresh()` genera email único
- `test/e2e/helpers/test_app.dart` — `pumpE2EApp()` configura la app para E2E
- `test/e2e/helpers/cleanup.dart` — limpieza de cuentas via REST API

## Ready for Proposal

Yes. Scope is well-defined, approach is clear, dependencies are known.
