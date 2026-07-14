/// Publication demographic categories for manga titles.
///
/// Maps to MangaDex demographic values. Serialises to lowercase string
/// form for API requests via [toJson] / [fromJson].
///
/// `kodomo` was removed because MangaDex does not support it (only shounen,
/// shoujo, seinen, josei).
enum MangaDemographic {
  shounen,
  shoujo,
  seinen,
  josei,
  unspecified;

  /// Wire value sent to the backend (lowercase name).
  String toJson() => name;

  /// Parses a wire string into a [MangaDemographic].
  ///
  /// Falls back to [unspecified] for unknown values so cached/preference data
  /// with removed entries (e.g. `kodomo`) does not crash on load.
  static MangaDemographic fromJson(String value) {
    for (final demo in MangaDemographic.values) {
      if (demo.name == value) return demo;
    }
    return MangaDemographic.unspecified;
  }
}

/// String constants for manga publication status values.
class MangaStatus {
  static const String ongoing = 'ongoing';
  static const String completed = 'completed';
  static const String hiatus = 'hiatus';
  static const String cancelled = 'cancelled';
}
