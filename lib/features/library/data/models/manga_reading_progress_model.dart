/// Data Transfer Object for persisted manga reading progress.
///
/// Represents the storage JSON payload used by local persistence.
class MangaReadingProgressModel {
  const MangaReadingProgressModel({
    required this.mangaId,
    this.readChapterIds = const <String>{},
    this.totalChaptersCount = 0,
  });

  final String mangaId;
  final Set<String> readChapterIds;
  final int totalChaptersCount;

  /// Deserializes persisted JSON into a [MangaReadingProgressModel].
  factory MangaReadingProgressModel.fromJson(Map<String, dynamic> json) {
    return MangaReadingProgressModel(
      mangaId: json['mangaId'] as String,
      readChapterIds:
          ((json['readChapterIds'] as List<dynamic>?) ?? const <dynamic>[])
              .whereType<String>()
              .toSet(),
      totalChaptersCount: (json['totalChaptersCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// Serializes this model into a stable JSON structure for storage.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'mangaId': mangaId,
      'readChapterIds': readChapterIds.toList()..sort(),
      'totalChaptersCount': totalChaptersCount,
    };
  }
}
