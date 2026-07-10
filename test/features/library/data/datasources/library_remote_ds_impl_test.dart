import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/error/exceptions.dart';
import 'package:inkscroller_flutter/features/library/data/datasources/library_remote_ds_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late LibraryRemoteDataSourceImpl dataSource;

  setUp(() {
    dio = MockDio();
    dataSource = LibraryRemoteDataSourceImpl(dio);
  });

  // ── getMangaDetail ──────────────────────────────────────────────────────

  group('getMangaDetail', () {
    test(
      'throws ServerException when response.data is null',
      () async {
        when(
          () => dio.get<Map<String, dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => Response(
            statusCode: 200,
            requestOptions: RequestOptions(path: '/manga/1'),
          ),
        );

        expect(
          () => dataSource.getMangaDetail('1'),
          throwsA(
            isA<ServerException>().having(
              (e) => e.message,
              'message',
              'server/empty-response',
            ),
          ),
        );
      },
    );
  });

  // ── getMangaChapters ────────────────────────────────────────────────────

  group('getMangaChapters', () {
    test(
      'throws ServerException when response.data is null',
      () async {
        when(
          () => dio.get<List<dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => Response(
            statusCode: 200,
            requestOptions: RequestOptions(path: '/chapters/manga/1'),
          ),
        );

        expect(
          () => dataSource.getMangaChapters('1'),
          throwsA(
            isA<ServerException>().having(
              (e) => e.message,
              'message',
              'server/empty-response',
            ),
          ),
        );
      },
    );
  });

  // ── getChapterPages ─────────────────────────────────────────────────────

  group('getChapterPages', () {
    test(
      'throws ServerException when response.data is null',
      () async {
        when(
          () => dio.get<Map<String, dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => Response(
            statusCode: 200,
            requestOptions: RequestOptions(path: '/chapters/1/pages'),
          ),
        );

        expect(
          () => dataSource.getChapterPages('1'),
          throwsA(
            isA<ServerException>().having(
              (e) => e.message,
              'message',
              'server/empty-response',
            ),
          ),
        );
      },
    );

    test(
      'throws ServerException (not UnexpectedException) for external chapters',
      () async {
        when(
          () => dio.get<Map<String, dynamic>>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: {'external': true},
            statusCode: 200,
            requestOptions: RequestOptions(path: '/chapters/1/pages'),
          ),
        );

        expect(
          () => dataSource.getChapterPages('1'),
          throwsA(
            isA<ServerException>().having(
              (e) => e.message,
              'message',
              'chapter/external-only',
            ),
          ),
        );
      },
    );
  });
}
