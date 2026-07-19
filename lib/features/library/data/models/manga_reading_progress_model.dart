/// Data Transfer Object for persisted manga reading progress.
///
/// Represents the storage JSON payload used by local persistence.
class MangaReadingProgressModel {
  const MangaReadingProgressModel({
    required this.mangaId,
    this.readChapterIds = const <String>{},
    this.totalChaptersCount = 0,
    this.manuallyMarkedCount = 0,
    this.batchSize = 25,
    this.updatedAt,
  });

  final String mangaId;
  final Set<String> readChapterIds;
  final int totalChaptersCount;
  final int manuallyMarkedCount;
  final int batchSize;

  /// UTC timestamp of the last user-facing progress change.
  ///
  /// Legacy records decode to the epoch so they sort after real progress.
  final DateTime? updatedAt;

  /// Deserializes persisted JSON into a [MangaReadingProgressModel].
  factory MangaReadingProgressModel.fromJson(Map<String, dynamic> json) {
    return MangaReadingProgressModel(
      mangaId: json['mangaId'] as String,
      readChapterIds:
          ((json['readChapterIds'] as List<dynamic>?) ?? const <dynamic>[])
              .whereType<String>()
              .toSet(),
      totalChaptersCount: (json['totalChaptersCount'] as num?)?.toInt() ?? 0,
      manuallyMarkedCount: (json['manuallyMarkedCount'] as num?)?.toInt() ?? 0,
      batchSize: (json['batchSize'] as num?)?.toInt() ?? 25,
      updatedAt: _parseUpdatedAt(json['updatedAt']),
    );
  }

  static DateTime? _parseUpdatedAt(dynamic value) {
    if (value == null) {
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      return parsed?.toUtc();
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true);
    }
    return null;
  }

  /// Serializes this model into a stable JSON structure for storage.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'mangaId': mangaId,
      'readChapterIds': readChapterIds.toList()..sort(),
      'totalChaptersCount': totalChaptersCount,
      'manuallyMarkedCount': manuallyMarkedCount,
      'batchSize': batchSize,
    };

    final updatedAt = this.updatedAt;
    if (updatedAt != null) {
      json['updatedAt'] = updatedAt.toUtc().toIso8601String();
    }

    return json;
  }
}
