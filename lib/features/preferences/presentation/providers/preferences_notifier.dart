import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../domain/usecases/get_preferences.dart';
import '../../domain/usecases/update_preferences.dart';
import 'preferences_state.dart';

/// StateNotifier handling reading preferences UI flow.
class PreferencesNotifier extends StateNotifier<PreferencesState> {
  final GetPreferences getPreferences;
  final UpdatePreferences updatePreferences;
  final bool Function() isServerBackedSession;

  /// D: Evita que múltiples callers (sessionStartup + ProfilePage) disparen
  /// GETs duplicados. Mientras una carga esté en vuelto, devuelve la misma
  /// Future a todos los callers.
  Future<void>? _inflightLoad;

  /// True después de una carga exitosa desde el backend.
  /// Evita que syncGuestPreferencesToRemote() PUTee datos del server
  /// de vuelta al server en cold start, lo que dispara un refresh
  /// redundante en Home y sobreescribe lo que el backend tenga más actual.
  bool _prefsLoadedFromServer = false;

  PreferencesNotifier({
    required this.getPreferences,
    required this.updatePreferences,
    this.isServerBackedSession = _defaultServerBackedSession,
  }) : super(const PreferencesState());

  static bool _defaultServerBackedSession() => true;

  Future<void> loadPreferences() async {
    // Ya cargamos del server, ignorar callers tardíos (ProfilePage, etc.)
    if (_prefsLoadedFromServer) return;
    if (_inflightLoad != null) return _inflightLoad!;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      _inflightLoad = _doLoad(loadedFromServer: isServerBackedSession());
      await _inflightLoad;
    } finally {
      _inflightLoad = null;
    }
  }

  Future<void> _doLoad({required bool loadedFromServer}) async {
    final t0 = DateTime.now();
    final result = await getPreferences();
    final elapsed = DateTime.now().difference(t0).inMilliseconds;

    if (kDebugMode) {
      debugPrint(
        '[PERF] preferences ${result.isRight() ? "OK" : "FAIL"} in ${elapsed}ms',
      );
    }

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
      (preferences) {
        if (loadedFromServer) _prefsLoadedFromServer = true;
        state = state.copyWith(
          isLoading: false,
          preferences: preferences,
          clearError: true,
        );
      },
    );
  }

  Future<void> savePreferences({
    String? defaultReaderMode,
    String? defaultLanguage,
    String? contentRatingFilter,
    List<String>? demographicFilter,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await updatePreferences(
      defaultReaderMode: defaultReaderMode,
      defaultLanguage: defaultLanguage,
      contentRatingFilter: contentRatingFilter,
      demographicFilter: demographicFilter,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
      (preferences) => state = state.copyWith(
        isLoading: false,
        preferences: preferences,
        clearError: true,
      ),
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Syncs current guest preferences to the remote backend.
  ///
  /// Called when auth transitions from guest → verified. Pushes the local
  /// guest preferences to the server using a guest-wins merge strategy.
  ///
  /// En cold start NO hace nada porque `loadPreferences()` ya cargó los
  /// datos del server — PUTearlos de vuelta es redundante y sobreescribe
  /// lo que el backend tenga más actual.
  Future<void> syncGuestPreferencesToRemote() async {
    // Si ya cargamos del backend, no hay nada que sync — los datos ya
    // están en el server. Esto evita el PUT redundante que dispara
    // un refresh innecesario en Home.
    if (_prefsLoadedFromServer) {
      if (kDebugMode) {
        debugPrint(
          '[PERF] syncGuestPreferencesToRemote skipped: already loaded from server',
        );
      }
      return;
    }

    final prefs = state.preferences;
    if (prefs == null) return;

    await updatePreferences(
      defaultReaderMode: prefs.defaultReaderMode.name,
      defaultLanguage: prefs.defaultLanguage,
      contentRatingFilter: prefs.contentRatingFilter?.wireValue,
      demographicFilter: prefs.demographicFilter
          ?.map((d) => d.toJson())
          .toList(),
    );
  }

  /// Clears all cached preferences — called when the user signs out.
  void clearPreferences() {
    _prefsLoadedFromServer = false;
    state = const PreferencesState();
  }

  String _mapFailureToMessage(Failure failure) {
    return switch (failure) {
      ServerFailure(message: final message) => message,
      NetworkFailure(message: final message) => message,
      CacheFailure(message: final message) => message,
      UnexpectedFailure(message: final message) => message,
      ExternalChapterFailure(message: final message) => message,
      EmptyChapterFailure(message: final message) => message,
    };
  }
}
