import 'package:dartz/dartz.dart';
import '../../domain/entities/chapter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../datasources/library_local_ds.dart';
import '../models/chapter_model.dart';
import '../models/manga_model.dart';
import '../../domain/entities/manga.dart';
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

  @override
  Future<Either<Failure, List<Manga>>> getMangaList({
    required int limit,
    required int offset,
    Map<String, String>? order,
    String? genre,
  }) async {
    try {
      final models = await remoteDataSource.getMangaList(
        limit: limit,
        offset: offset,
        order: order,
        genre: genre,
      );
      await _cacheMangaList(
        limit: limit,
        offset: offset,
        order: order,
        mangas: models,
      );

      return Right(models.map((e) => e.toEntity()).toList());
    } on AppException catch (error) {
      final cached = await _getCachedMangaList(
        limit: limit,
        offset: offset,
        order: order,
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
  Future<Either<Failure, List<Chapter>>> getMangaChapters(String mangaId) async {
    try {
      final chapters = await remoteDataSource.getMangaChapters(mangaId);
      await _cacheMangaChapters(mangaId, chapters);
      return Right(chapters.map((e) => e.toEntity()).toList());
    } on AppException catch (error) {
      final cached = await _getCachedMangaChapters(
        mangaId,
        maxAge: mangaChaptersCacheTtl,
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

  @override
  Future<Either<Failure, List<Manga>>> searchManga(String query) async {
    try {
      final models = await remoteDataSource.searchManga(query);
      return Right(models.map((e) => e.toEntity()).toList());
    } on AppException catch (error) {
      return Left(_mapExceptionToFailure(error));
    } on Exception catch (error) {
      return Left(UnexpectedFailure(message: error.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearLibraryCache() async {
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
    required List<MangaModel> mangas,
  }) async {
    try {
      await localDataSource.cacheMangaList(
        limit: limit,
        offset: offset,
        order: order,
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
    List<ChapterModel> chapters,
  ) async {
    try {
      await localDataSource.cacheMangaChapters(mangaId, chapters);
    } on CacheException {
      // Cache writes are best-effort only.
    }
  }

  Future<List<MangaModel>?> _getCachedMangaList({
    required int limit,
    required int offset,
    Map<String, String>? order,
    required Duration maxAge,
  }) async {
    try {
      return await localDataSource.getCachedMangaList(
        limit: limit,
        offset: offset,
        order: order,
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
  }) async {
    try {
      return await localDataSource.getCachedMangaChapters(
        mangaId,
        maxAge: maxAge,
      );
    } on CacheException {
      return null;
    }
  }



}
