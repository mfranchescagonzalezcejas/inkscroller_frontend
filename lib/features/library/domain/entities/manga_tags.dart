/// Publication demographic categories for manga titles.
///
/// Maps to MangaDex demographic values. Serialises to lowercase string
/// form for API requests via [toJson] / [fromJson].
enum MangaDemographic {
  kodomo,
  shounen,
  shoujo,
  seinen,
  josei,
  unspecified;

  /// Wire value sent to the backend (lowercase name).
  String toJson() => name;

  /// Parses a wire string into a [MangaDemographic].
  ///
  /// Throws [ArgumentError] if [value] is not a valid demographic.
  static MangaDemographic fromJson(String value) => values.byName(value);
}

/// String constants for manga publication status values.
class MangaStatus {
  static const String ongoing = 'ongoing';
  static const String completed = 'completed';
  static const String hiatus = 'hiatus';
  static const String cancelled = 'cancelled';
}
