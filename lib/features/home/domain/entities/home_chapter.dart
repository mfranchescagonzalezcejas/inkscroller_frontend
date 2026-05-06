/// Domain entity for a chapter item displayed in Home "New Chapters" section.
class HomeChapter {
  final String chapterId;
  final String mangaId;
  final String mangaTitle;
  final String? mangaCoverUrl;
  final String? chapterNumber;
  final String? chapterTitle;
  final DateTime? publishAt;
  final bool readable;
  final bool external;

  const HomeChapter({
    required this.chapterId,
    required this.mangaId,
    required this.mangaTitle,
    this.mangaCoverUrl,
    this.chapterNumber,
    this.chapterTitle,
    this.publishAt,
    required this.readable,
    required this.external,
  });
}
