import '../entities/user_library_entry.dart';

/// Contract for local persistence of user library membership and status.
abstract class UserLibraryRepository {
  Future<Map<String, UserLibraryEntry>> getAll({String? userId});

  Future<Map<String, UserLibraryEntry>> hydrate(String userId);

  Future<void> save(UserLibraryEntry entry, {String? userId});

  Future<void> remove(String mangaId, {String? userId});

  /// Returns the last time the user's library was synced (null if never).
  Future<DateTime?> getLastSyncedAt(String userId);

  /// Checks if the user's library has been hydrated at least once.
  Future<bool> isHydrated(String userId);
}
