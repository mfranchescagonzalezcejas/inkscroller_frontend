import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../models/home_chapter_model.dart';
import 'home_remote_ds.dart';

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final Dio dio;

  const HomeRemoteDataSourceImpl(this.dio);

  @override
  Future<List<HomeChapterModel>> getLatestChapters({int limit = 10}) async {
    try {
      final response = await dio.get<List<dynamic>>(
        ApiEndpoints.latestChapters,
        queryParameters: {'limit': limit},
      );

      final raw = response.data ?? <dynamic>[];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(HomeChapterModel.fromJson)
          .toList();
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      throw ServerException(
        message: 'Failed to load latest chapters',
        code: statusCode,
      );
    } on Exception catch (error) {
      throw UnexpectedException(message: error.toString());
    }
  }
}
