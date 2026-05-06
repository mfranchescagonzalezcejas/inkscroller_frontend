/// Data Transfer Object (DTO) for a manga as returned by the backend API.
///
/// Mirrors the fields of the [Manga] domain entity but is coupled to the JSON
/// shape of the API response. Use [MangaModelMapper.toEntity] to convert to [Manga].
class MangaModel {
  final String id;
  final String title;
  final String? description;
  final String? coverUrl;
  final String? demographic;
  final String? status;
  final List<String> genres;
  final double? score;
  final int? rank;
  final int? popularity;
  final List<String> authors;
  final int? readChaptersCount;
  final int? totalChaptersCount;

  const MangaModel({
    required this.id,
    required this.title,
    this.description,
    this.coverUrl,
    this.demographic,
    this.status,
    this.genres = const [],
    this.score,
    this.rank,
    this.popularity,
    this.authors = const [],
    this.readChaptersCount,
    this.totalChaptersCount,
  });

  /// Deserializes a [MangaModel] from the JSON map returned by the API.
  factory MangaModel.fromJson(Map<String, dynamic> json) {
    return MangaModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      coverUrl: json['coverUrl'] as String?,
      demographic: json['demographic'] as String?,
      status: json['status'] as String?,
      genres: _parseStringList(json['genres']),
      score: (json['score'] as num?)?.toDouble(),
      rank: (json['rank'] as num?)?.toInt(),
      popularity: json['popularity'] as int?,
      authors: _parseStringList(json['authors']),
      readChaptersCount: _readInt(json, const <String>[
        'readChaptersCount',
        'readCount',
        'chaptersRead',
        'read_chapters_count',
      ]),
      totalChaptersCount: _readInt(json, const <String>[
        'totalChaptersCount',
        'totalCount',
        'chaptersTotal',
        'total_chapters_count',
      ]),
    );
  }

  /// Serializes this model back into JSON for local caching.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'coverUrl': coverUrl,
      'demographic': demographic,
      'status': status,
      'genres': genres,
      'score': score,
      'rank': rank,
      'popularity': popularity,
      'authors': authors,
      'readChaptersCount': readChaptersCount,
      'totalChaptersCount': totalChaptersCount,
    };
  }

  static int? _readInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final dynamic value = json[key];
      if (value is num) {
        return value.toInt();
      }
    }

    for (final containerKey in const <String>['progress', 'readingProgress']) {
      final dynamic container = json[containerKey];
      if (container is! Map<String, dynamic>) {
        continue;
      }

      for (final key in keys) {
        final dynamic value = container[key];
        if (value is num) {
          return value.toInt();
        }
      }
    }

    return null;
  }

  static List<String> _parseStringList(Object? rawList) {
    if (rawList is! List) {
      return const <String>[];
    }

    return rawList
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }
}
