import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/network/dio_client.dart';

void main() {
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

    test('P0-F7: does not attach header when token provider returns null', () async {
      final options = RequestOptions(path: '/users/me');

      await attachAuthHeaderForRequest(
        options,
        tokenProvider: () async => null,
      );

      expect(options.headers.containsKey('Authorization'), isFalse);
    });

    test('P0-F7: does not attach header when token provider returns empty string',
        () async {
      final options = RequestOptions(path: '/users/me');

      await attachAuthHeaderForRequest(
        options,
        tokenProvider: () async => '',
      );

      expect(options.headers.containsKey('Authorization'), isFalse);
    });
  });
}
