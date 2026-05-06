/// Immutable domain entity that represents reading progress for one manga.
class MangaReadingProgress {
  const MangaReadingProgress({
    required this.mangaId,
    this.readChapterIds = const <String>{},
    this.totalChaptersCount = 0,
  });

  final String mangaId;
  final Set<String> readChapterIds;
  final int totalChaptersCount;

  int get readChaptersCount => readChapterIds.length;

  bool get hasKnownTotal => totalChaptersCount > 0;

  bool isChapterRead(String chapterId) => readChapterIds.contains(chapterId);

  MangaReadingProgress copyWith({
    Set<String>? readChapterIds,
    int? totalChaptersCount,
  }) {
    return MangaReadingProgress(
      mangaId: mangaId,
      readChapterIds: readChapterIds ?? this.readChapterIds,
      totalChaptersCount: totalChaptersCount ?? this.totalChaptersCount,
    );
  }
}
