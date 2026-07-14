import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/constants/api_endpoints.dart';
import 'package:inkscroller_flutter/features/library/data/datasources/library_remote_ds_impl.dart';
import 'package:inkscroller_flutter/features/library/data/models/search_result_model.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga_tags.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late LibraryRemoteDataSourceImpl dataSource;

  setUp(() {
    dio = MockDio();
    dataSource = LibraryRemoteDataSourceImpl(dio);
  });

  Response<Map<String, dynamic>> mockMangaListResponse() {
    return Response(
      data: <String, dynamic>{
        'data': <Map<String, dynamic>>[],
      },
      statusCode: 200,
      requestOptions: RequestOptions(path: ApiEndpoints.manga),
    );
  }

  Response<dynamic> mockSearchResponse() {
    return Response(
      data: <String, dynamic>{
        'data': <Map<String, dynamic>>[],
        'limit': 20,
        'offset': 0,
        'total': 0,
        'has_more': false,
      },
      statusCode: 200,
      requestOptions: RequestOptions(path: '${ApiEndpoints.manga}/search'),
    );
  }

  group('getMangaList demographic params', () {
    test('sends single demographic as repeated query param', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => mockMangaListResponse());

      await dataSource.getMangaList(
        limit: 20,
        offset: 0,
        demographics: [MangaDemographic.shounen],
      );

      verify(
        () => dio.get<Map<String, dynamic>>(
          ApiEndpoints.manga,
          queryParameters: <String, dynamic>{
            'limit': 20,
            'offset': 0,
            'demographic': ['shounen'],
          },
        ),
      ).called(1);
    });

    test('sends multiple demographics as repeated query params', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => mockMangaListResponse());

      await dataSource.getMangaList(
        limit: 20,
        offset: 0,
        demographics: [
          MangaDemographic.shounen,
          MangaDemographic.shoujo,
          MangaDemographic.seinen,
        ],
      );

      verify(
        () => dio.get<Map<String, dynamic>>(
          ApiEndpoints.manga,
          queryParameters: <String, dynamic>{
            'limit': 20,
            'offset': 0,
            'demographic': ['shounen', 'shoujo', 'seinen'],
          },
        ),
      ).called(1);
    });

    test('omits demographic param when null', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => mockMangaListResponse());

      await dataSource.getMangaList(
        limit: 20,
        offset: 0,
      );

      final captured = verify(
        () => dio.get<Map<String, dynamic>>(
          ApiEndpoints.manga,
          queryParameters: captureAny(named: 'queryParameters'),
        ),
      ).captured.single as Map<String, dynamic>;

      expect(captured.containsKey('demographic'), isFalse);
    });

    test('omits demographic param when empty list', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => mockMangaListResponse());

      await dataSource.getMangaList(
        limit: 20,
        offset: 0,
        demographics: [],
      );

      final captured = verify(
        () => dio.get<Map<String, dynamic>>(
          ApiEndpoints.manga,
          queryParameters: captureAny(named: 'queryParameters'),
        ),
      ).captured.single as Map<String, dynamic>;

      expect(captured.containsKey('demographic'), isFalse);
    });
  });

  group('searchManga demographic params', () {
    test('sends named + unspecified demographics as repeated query params', () async {
      when(
        () => dio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => mockSearchResponse());

      await dataSource.searchManga(
        'mystery',
        limit: 20,
        offset: 0,
        demographics: [
          MangaDemographic.shounen,
          MangaDemographic.unspecified,
        ],
      );

      verify(
        () => dio.get<dynamic>(
          '${ApiEndpoints.manga}/search',
          queryParameters: <String, dynamic>{
            'q': 'mystery',
            'limit': 20,
            'offset': 0,
            'demographic': ['shounen', 'unspecified'],
          },
        ),
      ).called(1);
    });

    test('omits demographic param when null', () async {
      when(
        () => dio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => mockSearchResponse());

      await dataSource.searchManga(
        'mystery',
        limit: 20,
        offset: 0,
      );

      final captured = verify(
        () => dio.get<dynamic>(
          '${ApiEndpoints.manga}/search',
          queryParameters: captureAny(named: 'queryParameters'),
        ),
      ).captured.single as Map<String, dynamic>;

      expect(captured.containsKey('demographic'), isFalse);
    });

    test('returns parsed SearchResultModel', () async {
      when(
        () => dio.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => mockSearchResponse());

      final result = await dataSource.searchManga(
        'mystery',
        limit: 20,
        offset: 0,
        demographics: [MangaDemographic.shounen],
      );

      expect(result, isA<SearchResultModel>());
    });
  });
}
