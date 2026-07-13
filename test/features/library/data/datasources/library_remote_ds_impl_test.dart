import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/constants/api_endpoints.dart';
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

  // ── searchManga ─────────────────────────────────────────────────────────

  group('searchManga', () {
    test('sends q, limit, offset and content_rating query parameters', () async {
      when(
        () => dio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: <String, dynamic>{
            'data': <Map<String, dynamic>>[
              <String, dynamic>{'id': '1', 'title': 'Berserk'},
            ],
            'limit': 20,
            'offset': 10,
            'total': 1,
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/manga/search'),
        ),
      );

      await dataSource.searchManga(
        'berserk',
        limit: 20,
        offset: 10,
        contentRating: 'safe',
      );

      verify(
        () => dio.get<dynamic>(
          '${ApiEndpoints.manga}/search',
          queryParameters: <String, dynamic>{
            'q': 'berserk',
            'limit': 20,
            'offset': 10,
            'content_rating': 'safe',
          },
        ),
      ).called(1);
    });

    test('parses envelope into SearchResultModel with metadata', () async {
      when(
        () => dio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: <String, dynamic>{
            'data': <Map<String, dynamic>>[
              <String, dynamic>{'id': '1', 'title': 'Berserk'},
              <String, dynamic>{'id': '2', 'title': 'Monster'},
            ],
            'limit': 20,
            'offset': 0,
            'total': 42,
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/manga/search'),
        ),
      );

      final result = await dataSource.searchManga(
        'monster',
        limit: 20,
        offset: 0,
      );

      expect(result.mangas, hasLength(2));
      expect(result.mangas.first.id, '1');
      expect(result.limit, 20);
      expect(result.offset, 0);
      expect(result.total, 42);
    });

    test('throws ServerException when response.data is null', () async {
      when(
        () => dio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 200,
          requestOptions: RequestOptions(path: '/manga/search'),
        ),
      );

      expect(
        () => dataSource.searchManga('berserk', limit: 20, offset: 0),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            'server/empty-response',
          ),
        ),
      );
    });
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
