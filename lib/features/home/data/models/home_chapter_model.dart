import '../../domain/entities/home_chapter.dart';

/// DTO for backend `/chapters/latest` response.
class HomeChapterModel {
  final String chapterId;
  final String mangaId;
  final String mangaTitle;
  final String? mangaCoverUrl;
  final String? chapterNumber;
  final String? chapterTitle;
  final DateTime? publishAt;
  final bool readable;
  final bool external;

  const HomeChapterModel({
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

  factory HomeChapterModel.fromJson(Map<String, dynamic> json) {
    return HomeChapterModel(
      chapterId: json['chapterId'] as String,
      mangaId: json['mangaId'] as String,
      mangaTitle: json['mangaTitle'] as String,
      mangaCoverUrl: json['mangaCoverUrl'] as String?,
      chapterNumber: json['chapterNumber']?.toString(),
      chapterTitle: json['chapterTitle'] as String?,
      publishAt: json['publishAt'] != null
          ? DateTime.tryParse(json['publishAt'] as String)
          : null,
      readable: json['readable'] as bool? ?? false,
      external: json['external'] as bool? ?? false,
    );
  }

  HomeChapter toEntity() {
    return HomeChapter(
      chapterId: chapterId,
      mangaId: mangaId,
      mangaTitle: mangaTitle,
      mangaCoverUrl: mangaCoverUrl,
      chapterNumber: chapterNumber,
      chapterTitle: chapterTitle,
      publishAt: publishAt,
      readable: readable,
      external: external,
    );
  }
}
