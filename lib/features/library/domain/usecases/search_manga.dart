import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/manga.dart';
import '../repositories/library_repository.dart';

/// Use case that searches for manga titles by a free-text [query].
class SearchManga {
  final LibraryRepository repository;

  SearchManga(this.repository);

  /// Returns manga whose title or metadata match [query].
  ///
  /// Accepts [limit] and [offset] for pagination. Returns a record of
  /// matching entities and the total result count.
  Future<Either<Failure, (List<Manga> items, int total)>> call(
    String query, {
    required int limit,
    required int offset,
  }) {
    return repository.searchManga(query, limit: limit, offset: offset);
  }
}
