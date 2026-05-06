import 'package:dio/dio.dart';
import 'package:inkscroller_flutter/core/constants/api_endpoints.dart';
import 'package:inkscroller_flutter/core/error/exceptions.dart';
import 'package:inkscroller_flutter/features/library/data/models/chapter_model.dart';
import '../models/manga_model.dart';
import 'library_remote_ds.dart';

/// Concrete HTTP implementation of [LibraryRemoteDataSource] using Dio.
///
/// Each method maps directly to one backend endpoint defined in [ApiEndpoints].
/// The raw JSON response is deserialized into DTO models (`MangaModel`, `ChapterModel`).
class LibraryRemoteDataSourceImpl implements LibraryRemoteDataSource {
  final Dio dio;

  const LibraryRemoteDataSourceImpl(this.dio);

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
  }) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        ApiEndpoints.manga,
        queryParameters: {
          'limit': limit,
          'offset': offset,
          if (genre != null) 'genre': genre,
          ...?order?.map((key, value) => MapEntry('order[$key]', value)),
        },
      );

      final List<dynamic> data = (response.data?['data'] as List<dynamic>?) ??
          <dynamic>[];

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
  @override
  Future<MangaModel> getMangaDetail(String mangaId) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '${ApiEndpoints.manga}/$mangaId',
      );

      return MangaModel.fromJson(response.data!);
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on Exception catch (error) {
      throw UnexpectedException(message: error.toString());
    }
  }

  // ─────────────────────────────
  // LISTA DE CAPÍTULOS (metadata)
  // ─────────────────────────────
  /// Fetches the chapter list for [mangaId] from `/chapters/manga/{id}`.
  @override
  Future<List<ChapterModel>> getMangaChapters(String mangaId) async {
    try {
      final response = await dio.get<List<dynamic>>(
        '${ApiEndpoints.chaptersByManga}/$mangaId',
      );

      return response.data!
          .whereType<Map<String, dynamic>>()
          .map(ChapterModel.fromJson)
          .toList();
    } on DioException catch (error) {
      throw _mapDioException(error);
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

      final data = response.data!;

      if (data['external'] == true) {
        throw const ServerException(message: 'Chapter is external only');
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
  /// Searches for manga via `/manga/search?q={query}`.
  ///
  /// Handles both a plain JSON array response and a wrapped `{"data": [...]}` response.
  @override
  Future<List<MangaModel>> searchManga(String query) async {
    try {
      final response = await dio.get<dynamic>(
        '${ApiEndpoints.manga}/search',
        queryParameters: {'q': query},
      );

      final body = response.data;

      final List<dynamic> rawList;
      if (body is List) {
        rawList = body;
      } else if (body is Map<String, dynamic>) {
        rawList = (body['data'] as List<dynamic>?) ?? <dynamic>[];
      } else {
        rawList = <dynamic>[];
      }

      return rawList
          .whereType<Map<String, dynamic>>()
          .map(MangaModel.fromJson)
          .toList();
    } on DioException catch (error) {
      throw _mapDioException(error);
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
      DioExceptionType.connectionError => NetworkException(
        message: 'No se pudo conectar con el servidor',
        code: statusCode,
      ),
      DioExceptionType.badResponse => ServerException(
        message: 'El servidor respondió con un error',
        code: statusCode,
      ),
      DioExceptionType.cancel => UnexpectedException(
        message: 'La solicitud fue cancelada',
        code: statusCode,
      ),
      DioExceptionType.badCertificate => UnexpectedException(
        message: 'Certificado inválido',
        code: statusCode,
      ),
      DioExceptionType.unknown => NetworkException(
        message: error.message ?? 'Ocurrió un error de red inesperado',
        code: statusCode,
      ),
    };
  }


}
