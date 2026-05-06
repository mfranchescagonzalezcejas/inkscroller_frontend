import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/manga.dart';
import '../repositories/library_repository.dart';

/// Use case that searches for manga titles by a free-text [query].
class SearchManga {
  final LibraryRepository repository;

  SearchManga(this.repository);

  /// Returns manga whose title or metadata match [query].
  Future<Either<Failure, List<Manga>>> call(String query) {
    return repository.searchManga(query);
  }
}
