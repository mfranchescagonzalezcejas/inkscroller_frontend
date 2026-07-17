import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import 'settings_remote_ds.dart';

/// Dio-backed implementation of settings account endpoints.
class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  final Dio dio;

  /// Creates a [SettingsRemoteDataSourceImpl] with the shared [DioClient].
  SettingsRemoteDataSourceImpl({required DioClient dioClient})
    : dio = dioClient.dio;

  @override
  Future<void> deleteAccount() async {
    try {
      await dio.delete<void>(ApiEndpoints.usersMe);
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on Exception catch (_) {
      throw UnexpectedException(
        message: 'An unexpected error occurred while deleting the account.',
      );
    }
  }

  AppException _mapDioException(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return NetworkException(
        message:
            error.message ?? 'Network error while deleting account.',
      );
    }

    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;
    final responseMessage = responseData is Map<String, dynamic>
        ? _extractResponseMessage(responseData['detail'])
        : null;

    return ServerException(
      code: statusCode,
      message: responseMessage ?? error.message ?? 'Account deletion failed.',
    );
  }

  String? _extractResponseMessage(Object? detail) {
    if (detail is String && detail.isNotEmpty) {
      return detail;
    }

    if (detail is List || detail is Map<String, dynamic>) {
      return 'Account deletion request failed.';
    }

    return null;
  }
}
