import '../../domain/entities/user_reading_preferences.dart';

/// Local datasource contract for cached user reading preferences.
///
/// Provides offline access to preferences when the backend is unreachable.
abstract class PreferencesLocalDataSource {
  /// Returns cached preferences, or null if none exist or cache is expired.
  ///
  /// When [isGuest] is true, reads from guest-scoped storage keys.
  Future<UserReadingPreferences?> getCachedPreferences({bool isGuest = false});

  /// Saves preferences to local storage with the current timestamp.
  ///
  /// When [isGuest] is true, writes to guest-scoped storage keys.
  Future<void> savePreferences(UserReadingPreferences preferences, {bool isGuest = false});

  /// Clears cached preferences for the given scope.
  ///
  /// When [isGuest] is true, clears only guest-scoped keys.
  /// When [isGuest] is false (default), clears only authenticated keys.
  /// When both scopes need clearing, call twice with different [isGuest] values.
  Future<void> clearCache({bool isGuest = false});
}
