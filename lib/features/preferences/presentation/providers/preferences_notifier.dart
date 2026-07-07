import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../domain/usecases/get_preferences.dart';
import '../../domain/usecases/update_preferences.dart';
import 'preferences_state.dart';

/// StateNotifier handling reading preferences UI flow.
class PreferencesNotifier extends StateNotifier<PreferencesState> {
  final GetPreferences getPreferences;
  final UpdatePreferences updatePreferences;

  PreferencesNotifier({
    required this.getPreferences,
    required this.updatePreferences,
  }) : super(const PreferencesState());

  Future<void> loadPreferences() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await getPreferences();

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

  Future<void> savePreferences({
    String? defaultReaderMode,
    String? defaultLanguage,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await updatePreferences(
      defaultReaderMode: defaultReaderMode,
      defaultLanguage: defaultLanguage,
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

  /// Clears all cached preferences — called when the user signs out.
  void clearPreferences() {
    state = const PreferencesState();
  }

  String _mapFailureToMessage(Failure failure) {
    return switch (failure) {
      ServerFailure(message: final message) => message,
      NetworkFailure(message: final message) => message,
      CacheFailure(message: final message) => message,
      UnexpectedFailure(message: final message) => message,
      ExternalChapterFailure(message: final message) => message,
    };
  }
}
