import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/chapter.dart';
import '../entities/chapters_with_languages.dart';
import '../entities/manga.dart';
import '../entities/manga_tags.dart';
import '../entities/search_result.dart';

/// Domain contract for all library data operations.
///
/// Implementations live in the data layer ([LibraryRepositoryImpl]) and are
/// injected by the DI container. Use cases depend only on this interface,
/// keeping domain logic free of infrastructure concerns.
abstract class LibraryRepository {
  /// Returns a paginated list of manga titles.
  ///
  /// [genre] filters by genre name (e.g. "romance", "action").
  /// [demographics] filters by publication demographic (e.g. shounen).
  Future<Either<Failure, List<Manga>>> getMangaList({
    required int limit,
    required int offset,
    Map<String, String>? order,
    String? genre,
    String? contentRating,
    List<MangaDemographic>? demographics,
  });

  /// Fetches the full detail of a single manga by its [mangaId].
  Future<Either<Failure, Manga>> getMangaDetail(
    String mangaId, {
    String? language,
  });

  /// Returns all chapters available for the manga identified by [mangaId].
  ///
  /// [language] filters the chapters to the given language code (e.g. "es").
  Future<Either<Failure, List<Chapter>>> getMangaChapters(
    String mangaId, {
    String? language,
  });

  /// Returns the list of available chapter language codes for the manga
  /// identified by [mangaId].
  Future<Either<Failure, List<String>>> getMangaLanguages(String mangaId);

  /// Fetches available languages and chapters for the preferred language in
  /// a single call. Replaces the initial `getMangaLanguages` + `getMangaChapters`
  /// round trip.
  Future<Either<Failure, ChaptersWithLanguages>> getMangaChaptersWithLanguages(
    String mangaId, {
    String? preferredLang,
  });

  /// Returns the ordered list of page image URLs for the given [chapterId].
  ///
  /// Throws if the chapter is external-only (not hosted on the backend).
  Future<Either<Failure, List<String>>> getChapterPages(String chapterId);

  /// Searches for manga titles matching [query] and returns the results.
  ///
  /// [limit] and [offset] control pagination. The returned [SearchResult]
  /// contains both the page items and the backend pagination metadata.
  /// [demographics] filters by publication demographic.
  Future<Either<Failure, SearchResult>> searchManga(
    String query, {
    required int limit,
    required int offset,
    String? contentRating,
    List<MangaDemographic>? demographics,
  });

  /// Clears all persisted library cache entries.
  ///
  /// Returns [Right(null)] on success or [Left(Failure)] if the cache
  /// could not be cleared.
  Future<Either<Failure, void>> clearLibraryCache();
}
