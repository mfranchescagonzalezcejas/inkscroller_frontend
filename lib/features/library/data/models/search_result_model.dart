import '../../domain/entities/search_result.dart';
import '../mappers/manga_mapper.dart';
import 'manga_model.dart';

/// Data Transfer Object (DTO) for the paginated `/manga/search` response.
///
/// Mirrors the backend envelope shape (`data`, `limit`, `offset`, `total`) and
/// converts nested manga JSON into [MangaModel] instances. Use [toEntity] to
/// obtain the domain [SearchResult].
class SearchResultModel {
  const SearchResultModel({
    required this.mangas,
    required this.limit,
    required this.offset,
    required this.total,
  });

  final List<MangaModel> mangas;
  final int limit;
  final int offset;
  final int total;

  /// Deserializes a [SearchResultModel] from the backend envelope.
  factory SearchResultModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as List<dynamic>?) ?? <dynamic>[];

    return SearchResultModel(
      mangas: data
          .whereType<Map<String, dynamic>>()
          .map(MangaModel.fromJson)
          .toList(growable: false),
      limit: (json['limit'] as num?)?.toInt() ?? 0,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }

  /// Converts this DTO into the corresponding domain [SearchResult].
  SearchResult toEntity() {
    return SearchResult(
      mangas: mangas.map((model) => model.toEntity()).toList(growable: false),
      limit: limit,
      offset: offset,
      total: total,
    );
  }
}
