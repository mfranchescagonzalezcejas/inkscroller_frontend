import '../../../../../core/error/failures.dart';
import '../../../domain/entities/chapter.dart';

/// Immutable snapshot of the chapter list loading state for a manga.
///
/// Holds the fetched [Chapter] list, loading flag, and optional error message.
/// Consumed by [MangaDetailPage] via [mangaChapterProvider].
class MangaChaptersState {
  final List<Chapter> chapters;
  final bool isLoading;
  final Failure? failure;
  final bool sortDescending;
  final bool filterUnreadOnly;
  final List<String> availableLanguages;
  final String selectedLanguage;
  final bool isLanguageLoading;

  const MangaChaptersState({
    this.chapters = const [],
    this.isLoading = false,
    this.failure,
    this.sortDescending = false,
    this.filterUnreadOnly = false,
    this.availableLanguages = const ['en'],
    this.selectedLanguage = 'en',
    this.isLanguageLoading = false,
  });

  MangaChaptersState copyWith({
    List<Chapter>? chapters,
    bool? isLoading,
    Failure? failure,
    bool clearFailure = false,
    bool? sortDescending,
    bool? filterUnreadOnly,
    List<String>? availableLanguages,
    String? selectedLanguage,
    bool? isLanguageLoading,
  }) {
    return MangaChaptersState(
      chapters: chapters ?? this.chapters,
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure ? null : failure ?? this.failure,
      sortDescending: sortDescending ?? this.sortDescending,
      filterUnreadOnly: filterUnreadOnly ?? this.filterUnreadOnly,
      availableLanguages: availableLanguages ?? this.availableLanguages,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      isLanguageLoading: isLanguageLoading ?? this.isLanguageLoading,
    );
  }
}
