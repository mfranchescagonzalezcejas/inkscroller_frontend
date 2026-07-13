import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/search_result.dart';
import '../repositories/library_repository.dart';

/// Use case that searches for manga titles by a free-text [query].
class SearchManga {
  final LibraryRepository repository;

  SearchManga(this.repository);

  /// Returns manga whose title or metadata match [query].
  ///
  /// [limit] controls the page size and [offset] skips the first N results.
  /// The returned [SearchResult] includes both the page items and the backend
  /// pagination metadata.
  Future<Either<Failure, SearchResult>> call(
    String query, {
    required int limit,
    required int offset,
    String? contentRating,
  }) {
    return repository.searchManga(
      query,
      limit: limit,
      offset: offset,
      contentRating: contentRating,
    );
  }
}
