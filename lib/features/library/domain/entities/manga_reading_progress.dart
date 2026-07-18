import 'dart:math' as math;

/// Immutable domain entity that represents reading progress for one manga.
class MangaReadingProgress {
  const MangaReadingProgress({
    required this.mangaId,
    this.readChapterIds = const <String>{},
    this.totalChaptersCount = 0,
    this.manuallyMarkedCount = 0,
    this.batchSize = 25,
  });

  final String mangaId;
  final Set<String> readChapterIds;
  final int totalChaptersCount;

  /// Self-reported chapter count independent of MangaDex chapter IDs.
  final int manuallyMarkedCount;

  /// Number of chapters per batch in the batching UI.
  final int batchSize;

  /// Returns the effective read count — the larger of the MangaDex set size
  /// and the self-reported manual count.
  int get readChaptersCount =>
      math.max(readChapterIds.length, manuallyMarkedCount);

  bool get hasKnownTotal => totalChaptersCount > 0;

  bool isChapterRead(String chapterId) => readChapterIds.contains(chapterId);

  MangaReadingProgress copyWith({
    Set<String>? readChapterIds,
    int? totalChaptersCount,
    int? manuallyMarkedCount,
    int? batchSize,
  }) {
    return MangaReadingProgress(
      mangaId: mangaId,
      readChapterIds: readChapterIds ?? this.readChapterIds,
      totalChaptersCount: totalChaptersCount ?? this.totalChaptersCount,
      manuallyMarkedCount: manuallyMarkedCount ?? this.manuallyMarkedCount,
      batchSize: batchSize ?? this.batchSize,
    );
  }
}
