import 'chapter_model.dart';

/// Response from `GET /chapters/manga/{id}/languages?preferred_lang=...`
///
/// Contains the available languages, the best-matched language, and the
/// chapters for that matched language — all in a single call.
class MangaLanguagesResponse {
  /// All language codes available for this manga.
  final List<String> availableLanguages;

  /// The language that best matches the user's preference (or the first
  /// available when no match is found).
  final String matchedLanguage;

  /// Chapters for the [matchedLanguage] (may be empty).
  final List<ChapterModel> chapters;

  const MangaLanguagesResponse({
    required this.availableLanguages,
    required this.matchedLanguage,
    required this.chapters,
  });

  factory MangaLanguagesResponse.fromJson(Map<String, dynamic> json) {
    final available = (json['available'] as List<dynamic>?)
            ?.cast<String>() ??
        <String>['en'];
    final matched = (json['matched'] as String?) ?? 'en';
    // Ensure matchedLanguage is always included in availableLanguages so
    // the selector never has a selected value with no matching option.
    if (!available.contains(matched)) {
      available.add(matched);
    }
    return MangaLanguagesResponse(
      availableLanguages: available,
      matchedLanguage: matched,
      chapters: ((json['chapters'] as List<dynamic>?) ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(ChapterModel.fromJson)
          .toList(),
    );
  }
}
