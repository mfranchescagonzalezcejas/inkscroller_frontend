import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/chapter.dart';
import '../repositories/library_repository.dart';

/// Use case that retrieves the full chapter list for a given manga.
class GetMangaChapters {
  final LibraryRepository repository;

  GetMangaChapters(this.repository);

  /// Returns all [Chapter] entries available for the manga identified by [mangaId].
  Future<Either<Failure, List<Chapter>>> call(String mangaId) {
    return repository.getMangaChapters(mangaId);
  }
}
