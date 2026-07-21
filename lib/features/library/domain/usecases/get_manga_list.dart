import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/manga.dart';
import '../entities/manga_tags.dart';
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
  /// Pass [demographics] to filter by publication demographic.
  Future<Either<Failure, List<Manga>>> call({
    required int limit,
    required int offset,
    Map<String, String>? order,
    String? genre,
    String? contentRating,
    List<MangaDemographic>? demographics,
    String? language,
  }) {
    return repository.getMangaList(
      limit: limit,
      offset: offset,
      order: order,
      genre: genre,
      contentRating: contentRating,
      demographics: demographics,
      language: language,
    );
  }
}
