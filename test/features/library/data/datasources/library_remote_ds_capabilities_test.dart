import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/library/data/datasources/library_remote_ds_impl.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late Dio dio;
  late LibraryRemoteDataSourceImpl dataSource;

  setUp(() {
    dio = _MockDio();
    dataSource = LibraryRemoteDataSourceImpl(dio);
  });

  test('treats a 404 capability response as unavailable', () async {
    when(() => dio.get<Map<String, dynamic>>(any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/manga/capabilities'),
        response: Response<void>(
          requestOptions: RequestOptions(path: '/manga/capabilities'),
          statusCode: 404,
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect((await dataSource.getMangaCapabilities()).supportsUnspecified, isFalse);
  });

  test('treats a network error as unavailable', () async {
    when(() => dio.get<Map<String, dynamic>>(any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/manga/capabilities'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect((await dataSource.getMangaCapabilities()).supportsUnspecified, isFalse);
  });
}
