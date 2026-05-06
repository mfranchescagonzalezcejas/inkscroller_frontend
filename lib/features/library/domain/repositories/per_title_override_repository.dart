import '../entities/reading_preferences.dart';

/// Domain contract for per-title reader mode overrides.
abstract class PerTitleOverrideRepository {
  /// Returns the override for the given manga, or null if none exists.
  Future<PerTitleOverride?> getOverride(String mangaId);

  /// Saves or updates the override for the given manga.
  Future<void> saveOverride(PerTitleOverride override);

  /// Removes the override for the given manga.
  Future<void> removeOverride(String mangaId);
}
