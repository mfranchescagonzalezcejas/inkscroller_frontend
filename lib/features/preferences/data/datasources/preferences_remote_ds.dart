import '../models/user_preferences_model.dart';

/// Remote datasource contract for authenticated preferences endpoints.
abstract class PreferencesRemoteDataSource {
  /// Reads `/users/me/preferences`.
  Future<UserPreferencesModel> getPreferences();

  /// Updates `/users/me/preferences`.
  Future<UserPreferencesModel> updatePreferences({
    String? defaultReaderMode,
    String? defaultLanguage,
  });
}
