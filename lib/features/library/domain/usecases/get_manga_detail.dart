import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/manga.dart';
import '../repositories/library_repository.dart';

/// Use case that retrieves the full details of a specific manga.
class GetMangaDetail {
  final LibraryRepository repository;

  GetMangaDetail(this.repository);

  /// Returns the [Manga] entity for the given [mangaId].
  ///
  /// [language] lets the backend return localized title/description (e.g. "es").
  Future<Either<Failure, Manga>> call(String mangaId, {String? language}) {
    return repository.getMangaDetail(mangaId, language: language);
  }
}
