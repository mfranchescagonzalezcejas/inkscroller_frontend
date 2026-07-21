import 'package:dio/dio.dart';
import 'package:inkscroller_flutter/core/constants/api_endpoints.dart';
import 'package:inkscroller_flutter/core/error/exceptions.dart';
import 'package:inkscroller_flutter/features/library/data/models/chapter_model.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga_tags.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga_capabilities.dart';
import '../models/manga_languages_response.dart';
import '../models/manga_model.dart';
import '../models/search_result_model.dart';
import 'library_remote_ds.dart';

/// Concrete HTTP implementation of [LibraryRemoteDataSource] using Dio.
///
/// Each method maps directly to one backend endpoint defined in [ApiEndpoints].
/// The raw JSON response is deserialized into DTO models (`MangaModel`, `ChapterModel`).
class LibraryRemoteDataSourceImpl implements LibraryRemoteDataSource {
  final Dio dio;

  const LibraryRemoteDataSourceImpl(this.dio);

  /// Builds the full path for the manga languages endpoint.
  String _languagesPath(String mangaId) =>
      '${ApiEndpoints.chaptersLanguagesBase}/$mangaId/languages';

  /// Filtra `unspecified` de demographics antes de mandarlo a la API.
  /// MangaDex es ~40x más lento cuando se incluye `unspecified` en la query.
  /// Los mangas sin demografía se siguen mostrando porque MangaDex los
  /// devuelve con `demographic: null` — el frontend los clasifica igual.
  Map<String, dynamic> _demographicParam(List<MangaDemographic> demographics) {
    final filtered = demographics
        .where((d) => d != MangaDemographic.unspecified)
        .map((e) => e.toJson())
        .toList();
    if (filtered.isEmpty) return const {};
    return {'demographic': filtered};
  }

  @override
  Future<MangaCapabilities> getMangaCapabilities() async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        ApiEndpoints.mangaCapabilities,
      );
      return MangaCapabilities.fromJson(response.data ?? <String, Object?>{});
    } on DioException {
      return const MangaCapabilities(supportsUnspecified: false);
    } on Exception {
      return const MangaCapabilities(supportsUnspecified: false);
    }
  }

  // ─────────────────────────────
  // LISTA DE MANGAS
  // ─────────────────────────────
  /// Fetches [limit] manga starting at [offset] from the `/manga` endpoint.
  @override
  Future<List<MangaModel>> getMangaList({
    required int limit,
    required int offset,
    Map<String, String>? order,
    String? genre,
    String? contentRating,
    List<MangaDemographic>? demographics,
    String? language,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        ApiEndpoints.manga,
        queryParameters: {
          'limit': limit,
          'offset': offset,
          if (genre != null) 'genre': genre,
          if (contentRating != null) 'content_rating': contentRating,
          if (demographics != null && demographics.isNotEmpty)
            ..._demographicParam(demographics),
          if (language != null) 'language': language,
          ...?order?.map((key, value) => MapEntry('order[$key]', value)),
        },
      );

      final List<dynamic> data =
          (response.data?['data'] as List<dynamic>?) ?? <dynamic>[];

      return data
          .whereType<Map<String, dynamic>>()
          .map(MangaModel.fromJson)
          .toList();
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on Exception catch (error) {
      throw UnexpectedException(message: error.toString());
    }
  }

  // ─────────────────────────────
  // DETALLE DE MANGA
  // ─────────────────────────────
  /// Fetches the full detail for the manga with the given [mangaId] from `/manga/{id}`.
  /// [language] requests localized title/description (e.g. "es").
  @override
  Future<MangaModel> getMangaDetail(String mangaId, {String? language}) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '${ApiEndpoints.manga}/$mangaId',
        queryParameters: {
          if (language != null) 'language': language,
        },
      );

      final data = response.data;
      if (data == null) {
        throw const ServerException(message: 'server/empty-response');
      }
      return MangaModel.fromJson(data);
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on AppException {
      rethrow;
    } on Exception catch (error) {
      throw UnexpectedException(message: error.toString());
    }
  }

  // ─────────────────────────────
  // LISTA DE CAPÍTULOS (metadata)
  // ─────────────────────────────
  /// Fetches the chapter list for [mangaId] from `/chapters/manga/{id}`.
  ///
  /// When [language] is provided, the request includes `lang=<language>`.
  @override
  Future<List<ChapterModel>> getMangaChapters(
    String mangaId, {
    String? language,
  }) async {
    try {
      final response = await dio.get<List<dynamic>>(
        '${ApiEndpoints.chaptersByManga}/$mangaId',
        queryParameters: {
          if (language != null) 'lang': language,
        },
      );

      final data = response.data;
      if (data == null) {
        throw const ServerException(message: 'server/empty-response');
      }
      return data
          .whereType<Map<String, dynamic>>()
          .map(ChapterModel.fromJson)
          .toList();
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on AppException {
      rethrow;
    } on Exception catch (error) {
      throw UnexpectedException(message: error.toString());
    }
  }

  // ─────────────────────────────
  // IDIOMAS DISPONIBLES
  // ─────────────────────────────
  /// Fetches the available chapter language codes for [mangaId].
  ///
  /// Returns the raw list from `/chapters/manga/{id}/languages`, defaulting to
  /// `['en']` when the backend returns an empty body.
  @override
  Future<List<String>> getMangaLanguages(String mangaId) async {
    try {
      final response = await dio.get<List<dynamic>>(
        _languagesPath(mangaId),
      );
      return response.data?.cast<String>() ?? <String>['en'];
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on AppException {
      rethrow;
    } on Exception catch (error) {
      throw UnexpectedException(message: error.toString());
    }
  }

  @override
  Future<MangaLanguagesResponse> getMangaChaptersWithLanguages(
    String mangaId, {
    String? preferredLang,
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        _languagesPath(mangaId),
        queryParameters: {
          if (preferredLang != null) 'preferred_lang': preferredLang,
        },
      );
      final data = response.data;
      if (data == null) {
        throw const ServerException(message: 'server/empty-response');
      }
      return MangaLanguagesResponse.fromJson(data);
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on AppException {
      rethrow;
    } on Exception catch (error) {
      throw UnexpectedException(message: error.toString());
    }
  }

  // ─────────────────────────────
  // PÁGINAS DEL CAPÍTULO (READER)
  // ─────────────────────────────
  /// Fetches the page URLs for [chapterId] from `/chapters/{id}/pages`.
  ///
  /// Throws a [ServerException] if the backend signals that the chapter is external-only.
  @override
  Future<List<String>> getChapterPages(String chapterId) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '${ApiEndpoints.chapterPages}/$chapterId/pages',
      );

      final data = response.data;
      if (data == null) {
        throw const ServerException(message: 'server/empty-response');
      }

      if (data['external'] == true) {
        throw const ServerException(message: 'chapter/external-only');
      }

      return List<String>.from(data['pages'] as List<dynamic>? ?? <dynamic>[]);
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on AppException {
      rethrow;
    } on Exception catch (error) {
      throw UnexpectedException(message: error.toString());
    }
  }

  // ─────────────────────────────
  // BUSQUEDA DE MANGAS
  // ─────────────────────────────
  /// Searches for manga via `/manga/search?q={query}&limit={limit}&offset={offset}`.
  ///
  /// Parses the paginated envelope into a [SearchResultModel]. Throws a
  /// [ServerException] when the response body is missing.
  @override
  Future<SearchResultModel> searchManga(
    String query, {
    required int limit,
    required int offset,
    String? contentRating,
    List<MangaDemographic>? demographics,
    String? language,
  }) async {
    try {
      final response = await dio.get<dynamic>(
        '${ApiEndpoints.manga}/search',
        queryParameters: {
          'q': query,
          'limit': limit,
          'offset': offset,
          if (contentRating != null) 'content_rating': contentRating,
          if (demographics != null && demographics.isNotEmpty)
            ..._demographicParam(demographics),
          if (language != null) 'language': language,
        },
        options: Options(extra: {'concurrency_priority': 'high'}),
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const ServerException(message: 'server/empty-response');
      }

      return SearchResultModel.fromJson(data);
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on AppException {
      rethrow;
    } on Exception catch (error) {
      throw UnexpectedException(message: error.toString());
    }
  }

  AppException _mapDioException(DioException error) {
    final statusCode = error.response?.statusCode;

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout => const NetworkException(
        message: 'network/timeout',
      ),
      DioExceptionType.connectionError => const NetworkException(
        message: 'network/no-connection',
      ),
      DioExceptionType.badResponse => ServerException(
        message: 'server/bad-response',
        code: statusCode,
      ),
      DioExceptionType.cancel => const UnexpectedException(
        message: 'client/cancelled',
      ),
      DioExceptionType.badCertificate => const UnexpectedException(
        message: 'server/invalid-certificate',
      ),
      DioExceptionType.unknown => const NetworkException(
        message: 'network/unknown',
      ),
    };
  }
}
