import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/user_library_entry.dart';
import '../../domain/entities/user_library_status.dart';
import '../models/user_library_remote_entry_model.dart';
import 'user_library_remote_ds.dart';

/// Dio-backed remote datasource for authenticated user-library endpoints.
class UserLibraryRemoteDataSourceImpl implements UserLibraryRemoteDataSource {
  final Dio dio;

  UserLibraryRemoteDataSourceImpl({required DioClient dioClient})
    : dio = dioClient.dio;

  @override
  Future<Map<String, UserLibraryEntry>> getLibrary() async {
    try {
      final Response<List<dynamic>> response = await dio.get<List<dynamic>>(
        ApiEndpoints.usersMeLibrary,
      );

      final List<dynamic> rawList = response.data ?? <dynamic>[];
      final Map<String, UserLibraryEntry> byMangaId =
          <String, UserLibraryEntry>{};

      for (final dynamic item in rawList) {
        if (item is! Map<String, dynamic>) {
          continue;
        }

        final UserLibraryRemoteEntryModel model =
            UserLibraryRemoteEntryModel.fromJson(item);
        final UserLibraryEntry entry = model.toEntity();
        byMangaId[entry.manga.id] = entry;
      }

      return byMangaId;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  @override
  Future<void> addToLibrary(
    String mangaId, {
    String? title,
    String? coverUrl,
    List<String> authors = const [],
  }) async {
    try {
      await dio.post<void>(
        '${ApiEndpoints.usersMeLibrary}/$mangaId',
        data: <String, dynamic>{
          if (title != null) 'title': title,
          if (coverUrl != null) 'cover_url': coverUrl,
          if (authors.isNotEmpty) 'authors': authors,
        },
      );
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  @override
  Future<void> updateLibraryStatus(
    String mangaId,
    UserLibraryStatus status,
  ) async {
    try {
      await dio.patch<void>(
        '${ApiEndpoints.usersMeLibrary}/$mangaId',
        data: <String, String>{'library_status': status.storageValue},
      );
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  @override
  Future<void> removeFromLibrary(String mangaId) async {
    try {
      await dio.delete<void>('${ApiEndpoints.usersMeLibrary}/$mangaId');
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  AppException _mapDioException(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return NetworkException(
        message:
            error.message ??
            'Network error while reaching user library endpoint.',
      );
    }

    final int? statusCode = error.response?.statusCode;
    final dynamic responseData = error.response?.data;
    final String? responseMessage = responseData is Map<String, dynamic>
        ? responseData['detail'] as String?
        : null;

    return ServerException(
      code: statusCode,
      message:
          responseMessage ?? error.message ?? 'User library request failed.',
    );
  }
}
