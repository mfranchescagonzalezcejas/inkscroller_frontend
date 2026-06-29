# Design — Account Deletion Flow

## Arquitectura

Nueva feature `settings/` siguiendo Clean Architecture:

```
lib/features/settings/
├── domain/
│   ├── entities/           # (poco contenido, no necesita entidad propia)
│   └── repositories/
│       └── settings_repository.dart        ← contrato
├── data/
│   ├── repositories/
│   │   └── settings_repository_impl.dart   ← implementación
│   └── datasources/
│       └── settings_remote_ds.dart         ← HTTP call
│       └── settings_remote_ds_impl.dart
├── presentation/
│   ├── providers/
│   │   └── settings_provider.dart          ← Riverpod StateNotifier
│   ├── pages/
│   │   └── settings_page.dart
│   └── widgets/
│       ├── account_section.dart
│       └── delete_account_dialog.dart
```

**Reglas Clean Architecture**:
- Presentation NO importa Data
- Domain NO importa Flutter ni Dio
- SettingsRepositoryImpl llama a SettingsRemoteDataSource
- Mappers convierten modelos HTTP a entities si hiciera falta

---

## Flujo de datos

```
SettingsPage
  └── SettingsProvider (StateNotifier<SettingsState>)
        └── SettingsRepository (contrato)
              └── SettingsRepositoryImpl
                    └── SettingsRemoteDataSource
                          └── Dio → DELETE /users/me
```

### SettingsState

```dart
@freezed
class SettingsState with _$SettingsState {
  const factory SettingsState({
    @Default(false) bool isDeletingAccount,
    String? deleteError,
    @Default(false) bool accountDeleted,
  }) = _SettingsState;
}
```

### Providers

```dart
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return sl<SettingsRepository>();
});

final settingsProvider = StateNotifierProvider<SettingsProvider, SettingsState>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return SettingsProvider(repository, ref);
});
```

### Acciones del provider

| Método | Descripción |
|---|---|
| `deleteAccount()` | Llama al repo, maneja loading/error/success |
| `resetState()` | Limpia errores, vuelve a idle |
| `signOutAfterDeletion()` | Firebase signOut + redirigir |

---

## Routing

Agregar ruta en `go_router`:

```dart
GoRouter(
  routes: [
    // ... rutas existentes
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);
```

El acceso desde el área autenticada puede ser:
- Un `IconButton(icon: Icons.settings)` en el AppBar de LibraryPage o HomePage
- O un botón en el drawer/menú de usuario

---

## Diálogo de confirmación

```
┌──────────────────────────────────┐
│  ¿Eliminar cuenta?               │
│                                  │
│  Esta acción es irreversible.    │
│  Se borrarán tu perfil,          │
│  historial de lectura,           │
│  preferencias y datos            │
│  asociados.                      │
│                                  │
│  Escribí DELETE para confirmar   │
│  ┌──────────────────────────┐   │
│  │                          │   │
│  └──────────────────────────┘   │
│                                  │
│     [Cancelar]  [Eliminar]       │
│                (disabled)        │
└──────────────────────────────────┘
```

- Botón "Eliminar" habilitado solo cuando el texto ingresado es exactamente `"DELETE"`
- Al tocar "Eliminar": loading spinner, botones deshabilitados

---

## Manejo de errores

| Error | UX |
|---|---|
| Network error | Snackbar: "Error de conexión. Intentá de nuevo." + botón reintentar |
| 401 Unauthorized | Forzar refresh token + reintentar 1 vez. Si falla, redirigir a login |
| 500 Server error | Snackbar: "Error del servidor. Intentá más tarde." |
| Timeout | Snackbar genérico de red + reintentar |

---

## DI (get_it)

```dart
void initDI() {
  sl.registerLazySingleton<SettingsRemoteDataSource>(
    () => SettingsRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(remoteDataSource: sl()),
  );
}
```

---

## Tests

| Archivo | Descripción |
|---|---|
| `test/features/settings/presentation/settings_provider_test.dart` | StateNotifier: success, error, estados |
| `test/features/settings/presentation/settings_page_test.dart` | Widget: render, botones, diálogo |
| `test/features/settings/presentation/delete_account_dialog_test.dart` | Diálogo: confirmación, validación DELETE |
| `test/features/settings/data/settings_repository_impl_test.dart` | Repository: mapeo HTTP a dominio |
| `test/features/settings/data/settings_remote_ds_impl_test.dart` | DataSource: llamada HTTP |

---

## Archivos a crear

```
lib/features/settings/
├── domain/repositories/settings_repository.dart
├── data/
│   ├── repositories/settings_repository_impl.dart
│   ├── datasources/settings_remote_ds.dart
│   └── datasources/settings_remote_ds_impl.dart
├── presentation/
│   ├── providers/settings_provider.dart
│   ├── pages/settings_page.dart
│   └── widgets/
│       ├── account_section.dart
│       └── delete_account_dialog.dart
```

## Archivos a modificar

| Archivo | Cambio |
|---|---|
| `lib/core/di/injection_container.dart` | Agregar `initSettingsDI()` |
| `lib/core/router/app_router.dart` | Agregar ruta `/settings` |
| `lib/features/library/presentation/pages/library_page.dart` | Agregar ícono de settings |
| `lib/features/home/presentation/pages/home_page.dart` | Agregar ícono de settings (si aplica) |
