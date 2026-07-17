import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/library_repository.dart';

/// Use case that retrieves available languages for a manga's chapters.
class GetMangaLanguages {
  final LibraryRepository repository;

  GetMangaLanguages(this.repository);

  /// Returns the list of language codes available for [mangaId].
  Future<Either<Failure, List<String>>> call(String mangaId) {
    return repository.getMangaLanguages(mangaId);
  }
}
