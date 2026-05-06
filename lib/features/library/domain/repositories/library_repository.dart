import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/chapter.dart';
import '../entities/manga.dart';

/// Domain contract for all library data operations.
///
/// Implementations live in the data layer ([LibraryRepositoryImpl]) and are
/// injected by the DI container. Use cases depend only on this interface,
/// keeping domain logic free of infrastructure concerns.
abstract class LibraryRepository {
  /// Returns a paginated list of manga titles.
  ///
  /// [genre] filters by genre name (e.g. "romance", "action").
  Future<Either<Failure, List<Manga>>> getMangaList({
    required int limit,
    required int offset,
    Map<String, String>? order,
    String? genre,
  });

  /// Fetches the full detail of a single manga by its [mangaId].
  Future<Either<Failure, Manga>> getMangaDetail(String mangaId);

  /// Returns all chapters available for the manga identified by [mangaId].
  Future<Either<Failure, List<Chapter>>> getMangaChapters(String mangaId);

  /// Returns the ordered list of page image URLs for the given [chapterId].
  ///
  /// Throws if the chapter is external-only (not hosted on the backend).
  Future<Either<Failure, List<String>>> getChapterPages(String chapterId);

  /// Searches for manga titles matching [query] and returns the results.
  Future<Either<Failure, List<Manga>>> searchManga(String query);

  /// Clears all persisted library cache entries.
  ///
  /// Returns [Right(null)] on success or [Left(Failure)] if the cache
  /// could not be cleared.
  Future<Either<Failure, void>> clearLibraryCache();
}
