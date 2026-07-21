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
  /// Returns the exact persisted value, or `null` for an unsupported token.
  static MangaDemographic? tryFromJson(String value) =>
      MangaDemographic.values.where((demo) => demo.name == value).firstOrNull;

  /// Parses a supported wire value.
  ///
  /// Call [tryFromJson] when handling untrusted persisted data.
  static MangaDemographic fromJson(String value) =>
      tryFromJson(value) ?? MangaDemographic.shounen;
}

/// Returns a deterministic cache-key fragment for a list of demographic tokens.
///
/// Sorts, deduplicates, and joins the values so that different orderings of
/// the same selection produce the same key.
String canonicalDemographicsKey(List<String>? demographics) {
  if (demographics == null || demographics.isEmpty) return 'none';
  final normalized = demographics.toSet().toList()..sort();
  return normalized.join(',');
}

/// String constants for manga publication status values.
class MangaStatus {
  static const String ongoing = 'ongoing';
  static const String completed = 'completed';
  static const String hiatus = 'hiatus';
  static const String cancelled = 'cancelled';
}
