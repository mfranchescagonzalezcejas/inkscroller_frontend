import 'package:dartz/dartz.dart';
import '../../domain/entities/chapter.dart';
import '../../domain/entities/chapters_with_languages.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../datasources/library_local_ds.dart';
import '../models/chapter_model.dart';
import '../models/manga_model.dart';
import '../../domain/entities/manga.dart';
import '../../domain/entities/manga_tags.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/repositories/library_repository.dart';
import '../datasources/library_remote_ds.dart';
import '../mappers/chapter_mapper.dart';
import '../mappers/manga_mapper.dart';

/// Concrete implementation of [LibraryRepository].
///
/// Delegates all network calls to [LibraryRemoteDataSource] and converts the
/// resulting DTO models to domain entities via the extension mappers
/// ([MangaModelMapper], [ChapterModelMapper]).
class LibraryRepositoryImpl implements LibraryRepository {
  LibraryRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.mangaListCacheTtl,
    required this.mangaDetailCacheTtl,
    required this.mangaChaptersCacheTtl,
  });

  final LibraryRemoteDataSource remoteDataSource;
  final LibraryLocalDataSource localDataSource;
  final Duration mangaListCacheTtl;
  final Duration mangaDetailCacheTtl;
  final Duration mangaChaptersCacheTtl;

  // ponytail: in-memory search cache — no TTL, no DB table; cleared on restart.
  final Map<String, SearchResult> _searchCache = {};

  @override
  Future<Either<Failure, List<Manga>>> getMangaList({
    required int limit,
    required int offset,
    Map<String, String>? order,
    String? genre,
    String? contentRating,
    List<MangaDemographic>? demographics,
  }) async {
    try {
      final models = await remoteDataSource.getMangaList(
        limit: limit,
        offset: offset,
        order: order,
        genre: genre,
        contentRating: contentRating,
        demographics: demographics,
      );
      await _cacheMangaList(
        limit: limit,
        offset: offset,
        order: order,
        genre: genre,
        contentRating: contentRating,
        demographics: demographics?.map((d) => d.name).toList(),
        mangas: models,
      );

      return Right(models.map((e) => e.toEntity()).toList());
    } on AppException catch (error) {
      final cached = await _getCachedMangaList(
        limit: limit,
        offset: offset,
        order: order,
        genre: genre,
        contentRating: contentRating,
        demographics: demographics?.map((d) => d.name).toList(),
        maxAge: mangaListCacheTtl,
      );
      if (cached != null) {
        return Right(cached.map((e) => e.toEntity()).toList());
      }

      return Left(_mapExceptionToFailure(error));
    } on Exception catch (error) {
      return Left(UnexpectedFailure(message: error.toString()));
    }
  }

  @override
  Future<Either<Failure, Manga>> getMangaDetail(String mangaId) async {
    try {
      final model = await remoteDataSource.getMangaDetail(mangaId);
      await _cacheMangaDetail(mangaId, model);
      return Right(model.toEntity());
    } on AppException catch (error) {
      final cached = await _getCachedMangaDetail(
        mangaId,
        maxAge: mangaDetailCacheTtl,
      );
      if (cached != null) {
        return Right(cached.toEntity());
      }

      return Left(_mapExceptionToFailure(error));
    } on Exception catch (error) {
      return Left(UnexpectedFailure(message: error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Chapter>>> getMangaChapters(
    String mangaId, {
    String? language,
  }) async {
    try {
      final chapters = await remoteDataSource.getMangaChapters(
        mangaId,
        language: language,
      );
      await _cacheMangaChapters(mangaId, chapters, language: language);
      return Right(chapters.map((e) => e.toEntity()).toList());
    } on AppException catch (error) {
      final cached = await _getCachedMangaChapters(
        mangaId,
        maxAge: mangaChaptersCacheTtl,
        language: language,
      );
      if (cached != null) {
        return Right(cached.map((e) => e.toEntity()).toList());
      }

      return Left(_mapExceptionToFailure(error));
    } on Exception catch (error) {
      return Left(UnexpectedFailure(message: error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getMangaLanguages(String mangaId) async {
    try {
      final languages = await remoteDataSource.getMangaLanguages(mangaId);
      return Right(languages);
    } on AppException catch (error) {
      return Left(_mapExceptionToFailure(error));
    } on Exception catch (error) {
      return Left(UnexpectedFailure(message: error.toString()));
    }
  }

  @override
  Future<Either<Failure, ChaptersWithLanguages>> getMangaChaptersWithLanguages(
    String mangaId, {
    String? preferredLang,
  }) async {
    try {
      final response = await remoteDataSource.getMangaChaptersWithLanguages(
        mangaId,
        preferredLang: preferredLang,
      );
      // Seed offline cache with the matched-language chapters.
      await _cacheMangaChapters(
        mangaId,
        response.chapters,
        language: response.matchedLanguage,
      );
      // Also seed under the preferred language key so offline fallback
      // matches when the backend matched a variant (e.g. es → es-la).
      // Only alias for real variants, not unrelated fallback languages.
      if (preferredLang != null &&
          preferredLang != response.matchedLanguage) {
        final isVariant = response.matchedLanguage.startsWith('$preferredLang-') ||
            preferredLang.startsWith('${response.matchedLanguage}-');
        if (isVariant) {
          await _cacheMangaChapters(
            mangaId,
            response.chapters,
            language: preferredLang,
          );
        }
      }
      return Right(
        ChaptersWithLanguages(
          availableLanguages: response.availableLanguages,
          matchedLanguage: response.matchedLanguage,
          chapters: response.chapters.map((e) => e.toEntity()).toList(),
        ),
      );
    } on AppException catch (error) {
      // Try language-scoped cache first, then fall back to legacy unscoped
      // cache for users upgrading from a previous version (P2 Codex).
      var cached = await _getCachedMangaChapters(
        mangaId,
        maxAge: mangaChaptersCacheTtl,
        language: preferredLang,
      );
      bool usedLegacyFallback = false;
      if (cached == null && preferredLang != null) {
        cached = await _getCachedMangaChapters(
          mangaId,
          maxAge: mangaChaptersCacheTtl,
        );
        usedLegacyFallback = cached != null;
      }
      if (cached != null) {
        final fallbackLang = usedLegacyFallback ? 'en' : (preferredLang ?? 'en');
        return Right(
          ChaptersWithLanguages(
            availableLanguages: [fallbackLang],
            matchedLanguage: fallbackLang,
            chapters: cached.map((e) => e.toEntity()).toList(),
          ),
        );
      }
      return Left(_mapExceptionToFailure(error));
    } on Exception catch (error) {
      return Left(UnexpectedFailure(message: error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getChapterPages(String chapterId) async {
    try {
      final pages = await remoteDataSource.getChapterPages(chapterId);
      return Right(pages);
    } on AppException catch (error) {
      return Left(_mapExceptionToFailure(error));
    } on Exception catch (error) {
      return Left(UnexpectedFailure(message: error.toString()));
    }
  }

  String _searchCacheKey(
    String query,
    int limit,
    int offset,
    String? contentRating,
    List<String>? demographics,
  ) =>
      '$query:$limit:$offset:cr:${contentRating ?? 'default'}'
      ':d:${canonicalDemographicsKey(demographics)}';

  @override
  Future<Either<Failure, SearchResult>> searchManga(
    String query, {
    required int limit,
    required int offset,
    String? contentRating,
    List<MangaDemographic>? demographics,
  }) async {
    try {
      final model = await remoteDataSource.searchManga(
        query,
        limit: limit,
        offset: offset,
        contentRating: contentRating,
        demographics: demographics,
      );
      final entity = model.toEntity();
      final demographicTokens = demographics?.map((d) => d.name).toList();
      _searchCache[_searchCacheKey(
        query,
        limit,
        offset,
        contentRating,
        demographicTokens,
      )] = entity;
      return Right(entity);
    } on AppException catch (error) {
      // Fall back to cached search result for this page when offline.
      final demographicTokens = demographics?.map((d) => d.name).toList();
      final cached = _searchCache[_searchCacheKey(
        query,
        limit,
        offset,
        contentRating,
        demographicTokens,
      )];
      if (cached != null) {
        return Right(cached);
      }
      return Left(_mapExceptionToFailure(error));
    } on Exception catch (error) {
      return Left(UnexpectedFailure(message: error.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearLibraryCache() async {
    _searchCache.clear();
    try {
      await localDataSource.clearLibraryCache();
      return const Right(null);
    } on AppException catch (error) {
      return Left(_mapExceptionToFailure(error));
    } on Exception catch (error) {
      return Left(UnexpectedFailure(message: error.toString()));
    }
  }

  Failure _mapExceptionToFailure(AppException exception) {
    return switch (exception) {
      ServerException() => ServerFailure(
        message: exception.message,
        code: exception.code,
      ),
      NetworkException() => NetworkFailure(
        message: exception.message,
        code: exception.code,
      ),
      CacheException() => CacheFailure(
        message: exception.message,
        code: exception.code,
      ),
      UnexpectedException() => UnexpectedFailure(
        message: exception.message,
        code: exception.code,
      ),
    };
  }

  Future<void> _cacheMangaList({
    required int limit,
    required int offset,
    Map<String, String>? order,
    String? genre,
    String? contentRating,
    List<String>? demographics,
    required List<MangaModel> mangas,
  }) async {
    try {
      await localDataSource.cacheMangaList(
        limit: limit,
        offset: offset,
        order: order,
        genre: genre,
        contentRating: contentRating,
        demographics: demographics,
        mangas: mangas,
      );
    } on CacheException {
      // Cache writes are best-effort only.
    }
  }

  Future<void> _cacheMangaDetail(String mangaId, MangaModel manga) async {
    try {
      await localDataSource.cacheMangaDetail(mangaId, manga);
    } on CacheException {
      // Cache writes are best-effort only.
    }
  }

  Future<void> _cacheMangaChapters(
    String mangaId,
    List<ChapterModel> chapters, {
    String? language,
  }) async {
    try {
      await localDataSource.cacheMangaChapters(mangaId, chapters, language: language);
    } on CacheException {
      // Cache writes are best-effort only.
    }
  }

  Future<List<MangaModel>?> _getCachedMangaList({
    required int limit,
    required int offset,
    Map<String, String>? order,
    String? genre,
    String? contentRating,
    List<String>? demographics,
    required Duration maxAge,
  }) async {
    try {
      return await localDataSource.getCachedMangaList(
        limit: limit,
        offset: offset,
        order: order,
        genre: genre,
        contentRating: contentRating,
        demographics: demographics,
        maxAge: maxAge,
      );
    } on CacheException {
      return null;
    }
  }

  Future<MangaModel?> _getCachedMangaDetail(
    String mangaId, {
    required Duration maxAge,
  }) async {
    try {
      return await localDataSource.getCachedMangaDetail(
        mangaId,
        maxAge: maxAge,
      );
    } on CacheException {
      return null;
    }
  }

  Future<List<ChapterModel>?> _getCachedMangaChapters(
    String mangaId, {
    required Duration maxAge,
    String? language,
  }) async {
    try {
      return await localDataSource.getCachedMangaChapters(
        mangaId,
        maxAge: maxAge,
        language: language,
      );
    } on CacheException {
      return null;
    }
  }



}
