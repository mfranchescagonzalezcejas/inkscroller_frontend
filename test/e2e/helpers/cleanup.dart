import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:inkscroller_flutter/core/config/app_environment.dart';
import 'package:inkscroller_flutter/core/constants/api_endpoints.dart';

/// Firebase Web API key for the dev project.
///
/// Provide via `--dart-define=FIREBASE_WEB_API_KEY=...` at compile time.
/// Falls back to `FIREBASE_ANDROID_DEV_API_KEY` — Firebase API keys are
/// project-level, so the Android key works for the REST cleanup endpoint too.
const _firebaseWebApiKey = String.fromEnvironment('FIREBASE_WEB_API_KEY');
const _firebaseAndroidDevApiKey = String.fromEnvironment(
  'FIREBASE_ANDROID_DEV_API_KEY',
);

/// Resolves the Firebase cleanup API key with explicit priority.
///
/// Returns [webApiKey] when non-empty, otherwise [androidDevApiKey].
/// Extracted so tests can call it with fake values to prove the fallback
/// decision without needing compile-time dart-defines.
String resolveFirebaseCleanupApiKey({
  String? webApiKey,
  String? androidDevApiKey,
}) {
  final effectiveWebApiKey = webApiKey ?? _firebaseWebApiKey;
  final effectiveAndroidDevApiKey =
      androidDevApiKey ?? _firebaseAndroidDevApiKey;
  return effectiveWebApiKey.isNotEmpty
      ? effectiveWebApiKey
      : effectiveAndroidDevApiKey;
}

String get firebaseWebApiKey => resolveFirebaseCleanupApiKey();

/// Deletes a test user from both the backend and Firebase Auth.
///
/// Signs in with [email] / [password] to obtain an ID token, then:
/// 1. Calls `DELETE /users/me` on the backend.
/// 2. Calls Firebase `accounts:delete` to remove the account.
///
/// Defaults [backendBaseUrl] to [AppEnvironment.apiBaseUrl] (respects
/// `API_BASE_URL` dart-define). No new defines needed.
///
/// Retries up to 3 times with exponential backoff.
/// Treats "already gone" responses as success on both backend and Firebase.
/// Backend non-2xx/non-404 errors block Firebase deletion so retry can
/// still clean backend while the Firebase user exists.
Future<void> deleteTestUser({
  required String email,
  required String password,
  String? backendBaseUrl,
  String? firebaseApiKey,
  String Function()? resolveApiKey,
  Future<String> Function(String url, Map<String, Object?> body)? postFn,
  Future<int> Function(Uri uri, String idToken)? deleteFn,
}) async {
  final effectiveApiKey =
      firebaseApiKey ??
      (resolveApiKey?.call() ?? resolveFirebaseCleanupApiKey());
  if (effectiveApiKey.isEmpty) {
    throw StateError(
      'No Firebase API key available for cleanup. '
      'Provide it via --dart-define=FIREBASE_WEB_API_KEY=<key> (primary) or '
      '--dart-define=FIREBASE_ANDROID_DEV_API_KEY=<key> (fallback). '
      'Keys are accepted via dart-defines or project config.',
    );
  }

  const maxRetries = 3;
  var attempt = 0;

  final effectiveBaseUrl = backendBaseUrl ?? AppEnvironment.apiBaseUrl;

  while (attempt < maxRetries) {
    try {
      await _deleteAccount(
        email: email,
        password: password,
        backendBaseUrl: effectiveBaseUrl,
        firebaseApiKey: effectiveApiKey,
        postFn: postFn,
        deleteFn: deleteFn,
      );
      return; // Success.
    } on SocketException {
      attempt++;
      if (attempt >= maxRetries) rethrow;
      await Future<void>.delayed(
        Duration(milliseconds: 1000 * (1 << (attempt - 1))),
      );
    } on TimeoutException {
      attempt++;
      if (attempt >= maxRetries) rethrow;
      await Future<void>.delayed(
        Duration(milliseconds: 1000 * (1 << (attempt - 1))),
      );
    } on HttpException {
      attempt++;
      if (attempt >= maxRetries) rethrow;
      await Future<void>.delayed(
        Duration(milliseconds: 1000 * (1 << (attempt - 1))),
      );
    }
  }
}

/// Signs in, deletes the backend account, then deletes the Firebase account.
Future<void> _deleteAccount({
  required String email,
  required String password,
  required String backendBaseUrl,
  required String firebaseApiKey,
  Future<String> Function(String url, Map<String, Object?> body)? postFn,
  Future<int> Function(Uri uri, String idToken)? deleteFn,
}) async {
  // Step 1: Sign in to get the ID token.
  final signInResponse = await _post(
    url:
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$firebaseApiKey',
    body: {'email': email, 'password': password, 'returnSecureToken': true},
    postFn: postFn,
  );

  final signInBody = jsonDecode(signInResponse) as Map<String, dynamic>;

  // If sign-in fails because the user doesn't exist, that's fine.
  if (signInBody['error'] != null) {
    final errorMap = signInBody['error'] as Map<String, dynamic>;
    final errorCode = errorMap['message'] as String? ?? '';
    if (errorCode == 'EMAIL_NOT_FOUND' ||
        errorCode == 'INVALID_LOGIN_CREDENTIALS') {
      return; // Account already gone — treat as cleaned.
    }
    throw HttpException('Firebase sign-in failed: $errorCode');
  }

  final idToken = signInResponse.isNotEmpty
      ? (jsonDecode(signInResponse) as Map<String, dynamic>)['idToken']
            as String?
      : null;

  if (idToken == null) {
    throw const HttpException('No ID token returned from sign-in');
  }

  // Step 2: Delete backend account.
  await _deleteBackendAccount(
    backendBaseUrl: backendBaseUrl,
    idToken: idToken,
    deleteFn: deleteFn,
  );

  // Step 3: Delete the Firebase account.
  final deleteResponse = await _post(
    url:
        'https://identitytoolkit.googleapis.com/v1/accounts:delete?key=$firebaseApiKey',
    body: {'idToken': idToken},
    postFn: postFn,
  );

  final deleteBody = jsonDecode(deleteResponse) as Map<String, dynamic>;

  if (deleteBody['error'] != null) {
    final errorMap = deleteBody['error'] as Map<String, dynamic>;
    final errorCode = errorMap['message'] as String? ?? '';
    // User already deleted — treat as success.
    if (errorCode == 'USER_NOT_FOUND' || errorCode == 'user-not-found') {
      return;
    }
    throw HttpException('Firebase account deletion failed: $errorCode');
  }
}

/// Calls `DELETE /users/me` on the backend.
///
/// 404 is treated as success (user already gone).
/// [deleteFn] is injectable for testing; defaults to real HTTP.
Future<void> _deleteBackendAccount({
  required String backendBaseUrl,
  required String idToken,
  Future<int> Function(Uri uri, String idToken)? deleteFn,
}) async {
  final normalizedBaseUrl = backendBaseUrl.replaceFirst(RegExp(r'/+$'), '');
  final url = '$normalizedBaseUrl${ApiEndpoints.usersMe}';
  final uri = Uri.parse(url);

  final statusCode = deleteFn != null
      ? await deleteFn(uri, idToken)
      : await _httpDelete(uri, idToken);

  assertBackendCleanupStatus(statusCode);
}

/// Real HTTP DELETE — ponytail: separate so tests can inject a fake.
Future<int> _httpDelete(Uri uri, String idToken) async {
  final client = HttpClient();
  try {
    client.connectionTimeout = const Duration(seconds: 15);
    final request = await client
        .deleteUrl(uri)
        .timeout(const Duration(seconds: 15));
    request.headers.set('Authorization', 'Bearer $idToken');

    final response = await request.close().timeout(const Duration(seconds: 15));
    return response.statusCode;
  } finally {
    client.close(force: true);
  }
}

/// Throws if [statusCode] is not a cleanup success (2xx or 404).
///
/// Package-internal helper — visible for unit tests in this directory.
void assertBackendCleanupStatus(int statusCode) {
  if (statusCode >= 200 && statusCode < 300) return;
  if (statusCode == 404) return;

  // Non-2xx/non-404 must fail before Firebase deletion so retry can
  // still clean backend while the Firebase user exists.
  throw HttpException('Backend cleanup failed with status $statusCode');
}

/// Sends a POST request and returns the response body as a string.
///
/// The [HttpClient] is disposed after each request to prevent resource leaks.
/// All I/O operations have a 15-second timeout to avoid hanging indefinitely.
Future<String> _post({
  required String url,
  required Map<String, Object?> body,
  Future<String> Function(String url, Map<String, Object?> body)? postFn,
}) async {
  if (postFn != null) return postFn(url, body);

  final uri = Uri.parse(url);
  final client = HttpClient();
  try {
    client.connectionTimeout = const Duration(seconds: 15);
    final request = await client
        .postUrl(uri)
        .timeout(const Duration(seconds: 15));
    request.headers.set('Content-Type', 'application/json');
    request.write(jsonEncode(body));

    final response = await request.close().timeout(const Duration(seconds: 15));
    final responseBody = await response.transform(utf8.decoder).join();

    return responseBody;
  } finally {
    client.close(force: true);
  }
}
