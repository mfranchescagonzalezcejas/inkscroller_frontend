# Tasks — Account Deletion Flow

## Review Workload Forecast
- **Estimated changed lines**: ~350-400
- **400-line budget risk**: Low
- **Chained PRs recommended**: No
- **Decision needed before apply**: No

---

## Tareas

### T1 — Data layer: Remote DataSource ✅
**Archivos**: `settings_remote_ds.dart`, `settings_remote_ds_impl.dart`
**Estimación**: ~40 líneas

- [x] Crear contrato `SettingsRemoteDataSource` con método `Future<void> deleteAccount()`
- [x] Implementación con Dio: `DELETE /users/me` con token de Firebase
- [x] Manejar excepciones HTTP (401, 500, timeout, network)

**Tests**: `settings_remote_ds_impl_test.dart` — mockear Dio, probar success y errores

---

### T2 — Domain layer: Repository contract ✅
**Archivos**: `settings_repository.dart`
**Estimación**: ~15 líneas

- [x] Crear abstract class `SettingsRepository` con método `Future<Either<Failure, void>> deleteAccount()`
- [x] Usar `Either` de `dartz` o el tipo `Failure` existente del proyecto

---

### T3 — Data layer: Repository implementation ✅
**Archivos**: `settings_repository_impl.dart`
**Estimación**: ~25 líneas

- [x] Implementar `SettingsRepositoryImpl` llamando a `SettingsRemoteDataSource`
- [x] Convertir excepciones HTTP a `Failure` del dominio

**Tests**: `settings_repository_impl_test.dart`

---

### T4 — Presentation: SettingsProvider [x]
**Archivos**: `settings_provider.dart`
**Estimación**: ~60 líneas

- Crear `SettingsState` con freezed: `isDeletingAccount`, `deleteError`, `accountDeleted`
- Crear `SettingsProvider extends StateNotifier<SettingsState>`:
  - `deleteAccount()` → llama repo → loading → success/error
  - En success: `signOutAfterDeletion()` → FirebaseAuth signOut
  - `resetState()`
- Provider para bridge con get_it

**Tests**: `settings_provider_test.dart`

---

### T5 — Presentation: DeleteAccountDialog [x]
**Archivos**: `delete_account_dialog.dart`
**Estimación**: ~80 líneas

- Dialog con:
  - Título y advertencia
  - TextField para escribir "DELETE"
  - Botón "Eliminar" habilitado solo cuando el texto coincide exactamente
  - Botón "Cancelar"
  - Loading state mientras se procesa

**Tests**: `delete_account_dialog_test.dart`

---

### T6 — Presentation: AccountSection [x]
**Archivos**: `account_section.dart`
**Estimación**: ~40 líneas

- Widget con:
  - Email del usuario autenticado
  - Botón "Eliminar cuenta" que abre el dialog

---

### T7 — Presentation: SettingsPage [x]
**Archivos**: `settings_page.dart`
**Estimación**: ~50 líneas

- Scaffold con AppBar "Configuración"
- Cuerpo con `AccountSection`
- Escucha `SettingsProvider` para detectar success → navegar a login
- Snackbar de error cuando `deleteError` no es null

**Tests**: `settings_page_test.dart`

---

### T8 — DI: Injection container ✅
**Archivos**: `injection_container.dart` (modificar)
**Estimación**: ~10 líneas

- [x] Agregar `initSettingsDI()` con registros de DataSource y Repository

---

### T9 — Routing [x]
**Archivos**: `app_router.dart` (modificar)
**Estimación**: ~15 líneas

- Agregar ruta `/settings` con `GoRoute`
- Importar `SettingsPage`

---

### T10 — Navigation entry point [x]
**Archivos**: `library_page.dart` (modificar)
**Estimación**: ~15 líneas

- Agregar `IconButton` de settings en AppBar
- Navegar a `/settings` con `context.push()`

---

### T11 — Tests de integración [x]
**Archivos**: tests de provider + widgets
**Estimación**: ~100 líneas

- `settings_provider_test.dart` — states
- `settings_page_test.dart` — render y navegación
- `delete_account_dialog_test.dart` — confirmación
- `settings_repository_impl_test.dart` — mapeo
- `settings_remote_ds_impl_test.dart` — HTTP
