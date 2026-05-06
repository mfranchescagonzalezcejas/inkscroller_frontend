import '../../domain/entities/user_reading_preferences.dart';

/// Immutable UI state for user reading preferences.
class PreferencesState {
  final bool isLoading;
  final UserReadingPreferences? preferences;
  final String? error;

  const PreferencesState({
    this.isLoading = false,
    this.preferences,
    this.error,
  });

  PreferencesState copyWith({
    bool? isLoading,
    UserReadingPreferences? preferences,
    String? error,
    bool clearPreferences = false,
    bool clearError = false,
  }) {
    return PreferencesState(
      isLoading: isLoading ?? this.isLoading,
      preferences: clearPreferences ? null : preferences ?? this.preferences,
      error: clearError ? null : error ?? this.error,
    );
  }
}
