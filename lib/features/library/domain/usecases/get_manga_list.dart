import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/manga.dart';
import '../repositories/library_repository.dart';

/// Use case that fetches a paginated, optionally sorted list of manga titles.
///
/// Delegates directly to [LibraryRepository.getMangaList]. Pass an [order] map
/// such as `{'followedCount': 'desc'}` to request a server-side sort.
class GetMangaList {
  final LibraryRepository repository;

  GetMangaList(this.repository);

  /// Executes the use case.
  ///
  /// Returns up to [limit] manga starting at [offset].
  /// Pass [genre] to filter server-side (e.g. "romance", "action").
  Future<Either<Failure, List<Manga>>> call({
    required int limit,
    required int offset,
    Map<String, String>? order,
    String? genre,
  }) {
    return repository.getMangaList(
      limit: limit,
      offset: offset,
      order: order,
      genre: genre,
    );
  }
}
