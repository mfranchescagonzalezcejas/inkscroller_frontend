import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import 'reading_progress_remote_ds.dart';

/// Dio-backed remote data source for reading progress sync.
class ReadingProgressRemoteDataSourceImpl
    implements ReadingProgressRemoteDataSource {
  ReadingProgressRemoteDataSourceImpl({required DioClient dioClient})
    : _dio = dioClient.dio;

  final Dio _dio;

  @override
  Future<bool> updateProgress(String mangaId, int chaptersRead) async {
    try {
      await _dio.patch<void>(
        '${ApiEndpoints.usersMeLibrary}/$mangaId/progress',
        data: <String, dynamic>{'chapters_read': chaptersRead},
      );
      return true;
    } on DioException catch (error) {
      // 404 = manga not in library → not an error, just skip
      if (error.response?.statusCode == 404) return false;
      // Network errors are non-fatal — progress stays local
      return false;
    } on AppException {
      return false;
    }
  }
}
