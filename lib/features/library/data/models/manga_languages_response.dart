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
    return MangaLanguagesResponse(
      availableLanguages: (json['available'] as List<dynamic>?)
              ?.cast<String>() ??
          <String>['en'],
      matchedLanguage: (json['matched'] as String?) ?? 'en',
      chapters: ((json['chapters'] as List<dynamic>?) ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(ChapterModel.fromJson)
          .toList(),
    );
  }
}
