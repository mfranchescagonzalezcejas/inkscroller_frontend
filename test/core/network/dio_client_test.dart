import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/config/api_config.dart';
import 'package:inkscroller_flutter/core/config/app_environment.dart';
import 'package:inkscroller_flutter/core/network/dio_client.dart';
import 'package:inkscroller_flutter/flavors/flavor_config.dart';

void main() {
  setUp(FlavorConfig.resetForTesting);

  // ── isProtectedAuthPath ──────────────────────────────────────────────────

  group('isProtectedAuthPath', () {
    test('P0-F6: /users and sub-paths are protected', () {
      expect(isProtectedAuthPath('/users'), isTrue);
      expect(isProtectedAuthPath('/users/me'), isTrue);
      expect(isProtectedAuthPath('/users/preferences'), isTrue);
    });

    test('P0-F6: public paths are not protected', () {
      expect(isProtectedAuthPath('/ping'), isFalse);
      expect(isProtectedAuthPath('/manga'), isFalse);
      expect(isProtectedAuthPath('/chapters/latest'), isFalse);
    });
  });

  // ── attachAuthHeaderForRequest ───────────────────────────────────────────

  group('DioClient auth interceptor (P0-F6)', () {
    test('attaches Bearer token to /users protected requests', () async {
      final options = RequestOptions(path: '/users/me');

      await attachAuthHeaderForRequest(
        options,
        tokenProvider: () async => 'token-123',
      );

      expect(options.headers['Authorization'], 'Bearer token-123');
    });

    test('attaches Bearer token to /users/preferences', () async {
      final options = RequestOptions(path: '/users/preferences');

      await attachAuthHeaderForRequest(
        options,
        tokenProvider: () async => 'tok-abc',
      );

      expect(options.headers['Authorization'], 'Bearer tok-abc');
    });

    test('does not attach token to /ping', () async {
      final options = RequestOptions(path: '/ping');

      await attachAuthHeaderForRequest(
        options,
        tokenProvider: () async => 'token-123',
      );

      expect(options.headers.containsKey('Authorization'), isFalse);
    });

    test('does not attach token to /manga routes', () async {
      final options = RequestOptions(path: '/manga');

      await attachAuthHeaderForRequest(
        options,
        tokenProvider: () async => 'token-123',
      );

      expect(options.headers.containsKey('Authorization'), isFalse);
    });

    test('P0-F7: silently skips auth header when token provider throws — '
        'request is not blocked', () async {
      final options = RequestOptions(path: '/users/me');

      // Must not throw; request should proceed without auth header.
      await expectLater(
        attachAuthHeaderForRequest(
          options,
          tokenProvider: () async => throw Exception('token revoked'),
        ),
        completes,
      );

      expect(options.headers.containsKey('Authorization'), isFalse);
    });

    test(
      'P0-F7: does not attach header when token provider returns null',
      () async {
        final options = RequestOptions(path: '/users/me');

        await attachAuthHeaderForRequest(
          options,
          tokenProvider: () async => null,
        );

        expect(options.headers.containsKey('Authorization'), isFalse);
      },
    );

    test(
      'P0-F7: does not attach header when token provider returns empty string',
      () async {
        final options = RequestOptions(path: '/users/me');

        await attachAuthHeaderForRequest(
          options,
          tokenProvider: () async => '',
        );

        expect(options.headers.containsKey('Authorization'), isFalse);
      },
    );
  });

  group('DioClient base URL fallback', () {
    test(
      'retries unauthenticated dev requests against the next fallback',
      () async {
        FlavorConfig(
          flavor: Flavor.dev,
          apiBaseUrl: AppEnvironment.devCloudBaseUrl,
          name: 'InkScroller Test',
        );
        final adapter = _FailThenSucceedAdapter();
        final client = DioClient()..dio.httpClientAdapter = adapter;
        final expectedFallbackOrigin = Uri.parse(
          ApiConfig.baseUrlCandidates[1],
        ).origin;

        final response = await client.dio.get<dynamic>('/ping');

        expect(response.statusCode, 200);
        expect(adapter.requests, hasLength(2));
        expect(
          adapter.requests.first.uri.origin,
          AppEnvironment.devCloudBaseUrl,
        );
        expect(adapter.requests.last.uri.origin, expectedFallbackOrigin);
        expect(
          adapter.requests.last.headers.containsKey('Authorization'),
          isFalse,
        );
      },
    );

    test('does not retry authenticated requests across origins', () async {
      FlavorConfig(
        flavor: Flavor.dev,
        apiBaseUrl: AppEnvironment.devCloudBaseUrl,
        name: 'InkScroller Test',
      );
      final adapter = _FailThenSucceedAdapter();
      final client = DioClient(tokenProvider: () async => 'token-123')
        ..dio.httpClientAdapter = adapter;

      await expectLater(
        client.dio.get<dynamic>('/users/me'),
        throwsA(isA<DioException>()),
      );

      expect(adapter.requests, hasLength(1));
      expect(
        adapter.requests.single.headers['Authorization'],
        'Bearer token-123',
      );
    });

    test('does not use local fallback candidates outside dev', () async {
      FlavorConfig(
        flavor: Flavor.staging,
        apiBaseUrl: AppEnvironment.stagingCloudBaseUrl,
        name: 'InkScroller Test',
      );
      final adapter = _FailThenSucceedAdapter();
      final client = DioClient()..dio.httpClientAdapter = adapter;

      await expectLater(
        client.dio.get<dynamic>('/ping'),
        throwsA(isA<DioException>()),
      );

      expect(adapter.requests, hasLength(1));
      expect(
        adapter.requests.single.uri.origin,
        AppEnvironment.stagingCloudBaseUrl,
      );
    });
  });
}

class _FailThenSucceedAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    if (requests.length == 1) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        error: 'connection refused',
      );
    }

    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
