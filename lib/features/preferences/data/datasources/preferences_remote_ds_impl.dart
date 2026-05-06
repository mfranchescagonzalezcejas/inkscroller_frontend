import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_preferences_model.dart';
import 'preferences_remote_ds.dart';

/// Dio-backed implementation of preferences endpoints.
class PreferencesRemoteDataSourceImpl implements PreferencesRemoteDataSource {
  final Dio dio;

  PreferencesRemoteDataSourceImpl({required DioClient dioClient})
    : dio = dioClient.dio;

  @override
  Future<UserPreferencesModel> getPreferences() async {
    try {
      final Response<Map<String, dynamic>> response = await dio
          .get<Map<String, dynamic>>(ApiEndpoints.usersMePreferences);

      final data = response.data;
      if (data == null) {
        throw const ServerException(message: 'Preferences response was empty.');
      }

      return UserPreferencesModel.fromJson(data);
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  @override
  Future<UserPreferencesModel> updatePreferences({
    String? defaultReaderMode,
    String? defaultLanguage,
  }) async {
    try {
      final payload =
          UserPreferencesModel(
            firebaseUid: '',
            defaultReaderMode: defaultReaderMode ?? 'vertical',
            defaultLanguage: defaultLanguage ?? 'en',
            updatedAt: '',
          ).toUpdateJson(
            defaultReaderMode: defaultReaderMode,
            defaultLanguage: defaultLanguage,
          );

      final Response<Map<String, dynamic>> response = await dio
          .put<Map<String, dynamic>>(
            ApiEndpoints.usersMePreferences,
            data: payload,
          );

      final data = response.data;
      if (data == null) {
        throw const ServerException(
          message: 'Updated preferences response was empty.',
        );
      }

      return UserPreferencesModel.fromJson(data);
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
            'Network error while reaching preferences endpoint.',
      );
    }

    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;
    final responseMessage = responseData is Map<String, dynamic>
        ? responseData['detail'] as String?
        : null;

    return ServerException(
      code: statusCode,
      message:
          responseMessage ?? error.message ?? 'Preferences request failed.',
    );
  }
}
