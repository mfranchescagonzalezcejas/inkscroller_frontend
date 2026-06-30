import 'dart:convert';
import 'dart:io';

/// Firebase Web API key for the dev project.
///
/// Provide via `--dart-define=FIREBASE_WEB_API_KEY=...` at compile time.
const String firebaseWebApiKey = String.fromEnvironment('FIREBASE_WEB_API_KEY');

/// Deletes a test user from Firebase Auth via the REST API.
///
/// Signs in with [email] / [password] to obtain an ID token, then calls
/// `accounts:delete` to remove the account. Retries up to 3 times with
/// exponential backoff.
///
/// Treats `EMAIL_NOT_FOUND` and `user-not-found` as success (account
/// already cleaned up).
Future<void> deleteTestUser({
  required String email,
  required String password,
}) async {
  if (firebaseWebApiKey.isEmpty) {
    // No API key configured — skip cleanup silently.
    return;
  }

  const maxRetries = 3;
  var attempt = 0;

  while (attempt < maxRetries) {
    try {
      await _deleteAccount(email: email, password: password);
      return; // Success.
    } on SocketException {
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

/// Signs in and deletes the Firebase Auth account.
Future<void> _deleteAccount({
  required String email,
  required String password,
}) async {
  // Step 1: Sign in to get the ID token.
  final signInResponse = await _post(
    url:
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$firebaseWebApiKey',
    body: {
      'email': email,
      'password': password,
      'returnSecureToken': true,
    },
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
    throw HttpException(
      'Firebase sign-in failed: $errorCode',
    );
  }

  final idToken = signInResponse.isNotEmpty
      ? (jsonDecode(signInResponse) as Map<String, dynamic>)['idToken']
          as String?
      : null;

  if (idToken == null) {
    throw const HttpException('No ID token returned from sign-in');
  }

  // Step 2: Delete the account.
  final deleteResponse = await _post(
    url:
        'https://identitytoolkit.googleapis.com/v1/accounts:delete?key=$firebaseWebApiKey',
    body: {'idToken': idToken},
  );

  final deleteBody = jsonDecode(deleteResponse) as Map<String, dynamic>;

  if (deleteBody['error'] != null) {
    final errorMap = deleteBody['error'] as Map<String, dynamic>;
    final errorCode = errorMap['message'] as String? ?? '';
    // User already deleted — treat as success.
    if (errorCode == 'USER_NOT_FOUND' || errorCode == 'user-not-found') {
      return;
    }
    throw HttpException(
      'Firebase account deletion failed: $errorCode',
    );
  }
}

/// Sends a POST request and returns the response body as a string.
///
/// The [HttpClient] is disposed after each request to prevent resource leaks.
/// All I/O operations have a 15-second timeout to avoid hanging indefinitely.
Future<String> _post({required String url, required Map<String, dynamic> body}) async {
  final uri = Uri.parse(url);
  final client = HttpClient();
  try {
    client.connectionTimeout = const Duration(seconds: 15);
    final request = await client.postUrl(uri).timeout(const Duration(seconds: 15));
    request.headers.set('Content-Type', 'application/json');
    request.write(jsonEncode(body));

    final response = await request.close().timeout(const Duration(seconds: 15));
    final responseBody = await response.transform(utf8.decoder).join();

    return responseBody;
  } finally {
    client.close(force: true);
  }
}
