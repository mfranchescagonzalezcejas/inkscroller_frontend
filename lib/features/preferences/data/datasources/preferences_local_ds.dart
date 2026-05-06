import '../../domain/entities/user_reading_preferences.dart';

/// Local datasource contract for cached user reading preferences.
///
/// Provides offline access to preferences when the backend is unreachable.
abstract class PreferencesLocalDataSource {
  /// Returns cached preferences, or null if none exist or cache is expired.
  Future<UserReadingPreferences?> getCachedPreferences();

  /// Saves preferences to local storage with the current timestamp.
  Future<void> savePreferences(UserReadingPreferences preferences);

  /// Clears all locally cached preferences.
  Future<void> clearCache();
}
