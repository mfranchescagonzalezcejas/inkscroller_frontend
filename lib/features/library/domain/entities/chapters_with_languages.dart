import 'chapter.dart';

/// Result of loading both available languages and chapters for a manga in one
/// operation — used by the unified languages+chapters endpoint.
class ChaptersWithLanguages {
  /// All language codes available for this manga.
  final List<String> availableLanguages;

  /// The language code that best matches the user's preference.
  final String matchedLanguage;

  /// Chapters for the [matchedLanguage] (may be empty).
  final List<Chapter> chapters;

  const ChaptersWithLanguages({
    required this.availableLanguages,
    required this.matchedLanguage,
    required this.chapters,
  });
}
