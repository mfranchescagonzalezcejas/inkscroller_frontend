import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/config/app_environment.dart';

import 'cleanup.dart';

void main() {
  group('deleteTestUser', () {
    test('is a function with expected signature', () {
      expect(deleteTestUser, isA<Function>());
    });

    test('default base URL uses AppEnvironment.apiBaseUrl', () {
      // AppEnvironment.apiBaseUrl resolves API_BASE_URL dart-define or
      // falls back to devCloudBaseUrl — never empty.
      expect(AppEnvironment.apiBaseUrl, isNotEmpty);
    });

    test(
      'sign-in happens before backend DELETE before Firebase DELETE',
      () async {
        final calls = <String>[];

        await deleteTestUser(
          email: 'test@example.com',
          password: 'pass123',
          firebaseApiKey: 'fake-test-key',
          postFn: (url, body) async {
            if (url.contains('signInWithPassword')) {
              calls.add('signin');
              return '{"idToken":"tok123","email":"test@example.com"}';
            }
            // accounts:delete
            calls.add('firebase');
            return '{}';
          },
          deleteFn: (uri, idToken) async {
            calls.add('backend');
            return 200;
          },
        );

        expect(calls, ['signin', 'backend', 'firebase']);
      },
    );

    test(
      'backend 500 retries 3 times, then throws; Firebase never reached',
      () async {
        final calls = <String>[];

        await expectLater(
          () => deleteTestUser(
            email: 'test@example.com',
            password: 'pass123',
            firebaseApiKey: 'fake-test-key',
            postFn: (url, body) async {
              calls.add('signin');
              return '{"idToken":"tok123","email":"test@example.com"}';
            },
            deleteFn: (uri, idToken) async {
              calls.add('backend');
              return 500;
            },
          ),
          throwsA(isA<HttpException>()),
        );

        // ponytail: production retries 3x on HttpException — assert all attempts
        expect(calls, [
          'signin',
          'backend',
          'signin',
          'backend',
          'signin',
          'backend',
        ]);
      },
    );

    test(
      'backend timeout retries 3 times, then throws; Firebase never reached',
      () async {
        final calls = <String>[];

        await expectLater(
          () => deleteTestUser(
            email: 'test@example.com',
            password: 'pass123',
            firebaseApiKey: 'fake-test-key',
            postFn: (url, body) async {
              calls.add('signin');
              return '{"idToken":"tok123","email":"test@example.com"}';
            },
            deleteFn: (uri, idToken) async {
              calls.add('backend');
              throw TimeoutException('backend timeout');
            },
          ),
          throwsA(isA<TimeoutException>()),
        );

        expect(calls, [
          'signin',
          'backend',
          'signin',
          'backend',
          'signin',
          'backend',
        ]);
      },
    );

    test(
      'backend 404 is treated as success and Firebase DELETE still happens',
      () async {
        final calls = <String>[];

        await deleteTestUser(
          email: 'test@example.com',
          password: 'pass123',
          firebaseApiKey: 'fake-test-key',
          postFn: (url, body) async {
            if (url.contains('signInWithPassword')) {
              calls.add('signin');
              return '{"idToken":"tok123","email":"test@example.com"}';
            }
            calls.add('firebase');
            return '{}';
          },
          deleteFn: (uri, idToken) async {
            calls.add('backend');
            return 404;
          },
        );

        expect(calls, ['signin', 'backend', 'firebase']);
      },
    );

    test('normalizes trailing slash before backend DELETE path', () async {
      late Uri backendUri;

      await deleteTestUser(
        email: 'test@example.com',
        password: 'pass123',
        backendBaseUrl: 'https://api.example.test/',
        firebaseApiKey: 'fake-test-key',
        postFn: (url, body) async {
          if (url.contains('signInWithPassword')) {
            return '{"idToken":"tok123","email":"test@example.com"}';
          }
          return '{}';
        },
        deleteFn: (uri, idToken) async {
          backendUri = uri;
          return 200;
        },
      );

      expect(backendUri.toString(), 'https://api.example.test/users/me');
    });

    test('sign-in failure EMAIL_NOT_FOUND skips silently', () async {
      final calls = <String>[];

      await deleteTestUser(
        email: 'gone@example.com',
        password: 'pass123',
        firebaseApiKey: 'fake-test-key',
        postFn: (url, body) async {
          calls.add('signin');
          return '{"error":{"message":"EMAIL_NOT_FOUND"}}';
        },
        deleteFn: (uri, idToken) async {
          calls.add('backend');
          return 200;
        },
      );

      // Only sign-in was attempted — no backend or firebase call.
      expect(calls, ['signin']);
    });

    test('no firebaseApiKey (empty const) throws StateError', () async {
      await expectLater(
        () => deleteTestUser(
          email: 'test@example.com',
          password: 'pass123',
          firebaseApiKey: '',
          postFn: (url, body) async {
            return '{}';
          },
          deleteFn: (uri, idToken) async {
            return 200;
          },
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('FIREBASE_WEB_API_KEY'),
              contains('FIREBASE_ANDROID_DEV_API_KEY'),
            ),
          ),
        ),
      );
    });

    test(
      'explicit firebaseApiKey param overrides compile-time constant',
      () async {
        late String usedApiKey;

        await deleteTestUser(
          email: 'test@example.com',
          password: 'pass123',
          firebaseApiKey: 'explicit-key-override',
          postFn: (url, body) async {
            usedApiKey = Uri.parse(url).queryParameters['key'] ?? '';
            return '{"idToken":"tok123","email":"test@example.com"}';
          },
          deleteFn: (uri, idToken) async {
            return 200;
          },
        );

        expect(usedApiKey, 'explicit-key-override');
      },
    );

    test(
      'resolveApiKey seam: fallback key is used when no explicit key',
      () async {
        late String usedApiKey;

        await deleteTestUser(
          email: 'test@example.com',
          password: 'pass123',
          resolveApiKey: () => 'fallback-android-key',
          postFn: (url, body) async {
            usedApiKey = Uri.parse(url).queryParameters['key'] ?? '';
            return '{"idToken":"tok123","email":"test@example.com"}';
          },
          deleteFn: (uri, idToken) async {
            return 200;
          },
        );

        expect(usedApiKey, 'fallback-android-key');
      },
    );

    test(
      'resolveApiKey seam: explicit param still wins over resolveApiKey',
      () async {
        late String usedApiKey;

        await deleteTestUser(
          email: 'test@example.com',
          password: 'pass123',
          firebaseApiKey: 'explicit-wins',
          resolveApiKey: () => 'should-not-be-used',
          postFn: (url, body) async {
            usedApiKey = Uri.parse(url).queryParameters['key'] ?? '';
            return '{"idToken":"tok123","email":"test@example.com"}';
          },
          deleteFn: (uri, idToken) async {
            return 200;
          },
        );

        expect(usedApiKey, 'explicit-wins');
      },
    );

    test('resolveApiKey seam: empty fallback throws StateError', () async {
      await expectLater(
        () => deleteTestUser(
          email: 'test@example.com',
          password: 'pass123',
          resolveApiKey: () => '',
          postFn: (url, body) async => '{}',
          deleteFn: (uri, idToken) async => 200,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('resolveFirebaseCleanupApiKey', () {
    test('web key wins when present', () {
      expect(
        resolveFirebaseCleanupApiKey(
          webApiKey: 'web-key-123',
          androidDevApiKey: 'android-key-456',
        ),
        'web-key-123',
      );
    });

    test('android dev key fallback when web key is empty', () {
      expect(
        resolveFirebaseCleanupApiKey(
          webApiKey: '',
          androidDevApiKey: 'android-key-456',
        ),
        'android-key-456',
      );
    });

    test('empty when neither is present', () {
      expect(
        resolveFirebaseCleanupApiKey(webApiKey: '', androidDevApiKey: ''),
        '',
      );
    });
  });

  group('assertBackendCleanupStatus', () {
    test('200 is treated as success', () {
      expect(() => assertBackendCleanupStatus(200), returnsNormally);
    });

    test('204 is treated as success', () {
      expect(() => assertBackendCleanupStatus(204), returnsNormally);
    });

    test('404 is treated as success', () {
      expect(() => assertBackendCleanupStatus(404), returnsNormally);
    });

    test('500 throws HttpException with status in message', () {
      expect(
        () => assertBackendCleanupStatus(500),
        throwsA(
          isA<HttpException>().having(
            (e) => e.message,
            'message',
            contains('500'),
          ),
        ),
      );
    });

    test('403 throws HttpException', () {
      expect(
        () => assertBackendCleanupStatus(403),
        throwsA(isA<HttpException>()),
      );
    });

    test('401 throws HttpException', () {
      expect(
        () => assertBackendCleanupStatus(401),
        throwsA(isA<HttpException>()),
      );
    });
  });
}
