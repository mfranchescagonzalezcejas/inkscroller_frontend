/// Content rating filter for catalogue results.
///
/// Maps to MangaDex content ratings:
/// - [safe]: safe content only
/// - [suggestive]: safe + suggestive content
/// - [all]: all content including erotica and pornographic
enum ContentRating {
  safe,
  suggestive,
  all;

  /// Wire value sent to the backend.
  String get wireValue => name;

  /// Options allowed for a given age and guest status.
  static List<ContentRating> valuesForAge(int? age, {required bool isGuest}) {
    if (isGuest || age == null || age < 16) return [ContentRating.safe];
    if (age < 18) return [ContentRating.safe, ContentRating.suggestive];
    return ContentRating.values;
  }

  /// Effective rating given stored preference and age constraints.
  static ContentRating effectiveForAge(
    int? age, {
    required bool isGuest,
    ContentRating? stored,
  }) {
    final allowed = valuesForAge(age, isGuest: isGuest);
    if (stored != null && allowed.contains(stored)) return stored;
    if (!isGuest && age != null && age >= 18) return ContentRating.suggestive;
    return ContentRating.safe;
  }
}
