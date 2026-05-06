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

  const MangaChaptersState({
    this.chapters = const [],
    this.isLoading = false,
    this.failure,
  });

  MangaChaptersState copyWith({
    List<Chapter>? chapters,
    bool? isLoading,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return MangaChaptersState(
      chapters: chapters ?? this.chapters,
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}
