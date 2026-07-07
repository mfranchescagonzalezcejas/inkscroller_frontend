import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_profile_model.dart';
import 'user_profile_remote_ds.dart';

/// Dio-backed implementation of user profile endpoints.
class UserProfileRemoteDataSourceImpl implements UserProfileRemoteDataSource {
  final Dio dio;

  UserProfileRemoteDataSourceImpl({required DioClient dioClient})
    : dio = dioClient.dio;

  @override
  Future<UserProfileModel> getProfile() async {
    try {
      final Response<Map<String, dynamic>> response = await dio
          .get<Map<String, dynamic>>(ApiEndpoints.usersMe);

      final data = response.data;
      if (data == null) {
        throw const ServerException(message: 'Profile response was empty.');
      }

      return UserProfileModel.fromJson(data);
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
            error.message ?? 'Network error while reaching profile endpoint.',
      );
    }

    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;
    final responseMessage = responseData is Map<String, dynamic>
        ? responseData['detail'] as String?
        : null;

    return ServerException(
      code: statusCode,
      message: responseMessage ?? error.message ?? 'Profile request failed.',
    );
  }
}
