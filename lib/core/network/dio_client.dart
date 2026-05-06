import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';

/// Wraps a pre-configured [Dio] HTTP client for the application.
///
/// The base URL is sourced from [ApiConfig.baseUrl], which in turn reads from
/// the active [FlavorConfig]. An [_AuthInterceptor] is attached so that all
/// outbound requests automatically carry the current Firebase ID token as a
/// `Bearer` authorization header when the user is authenticated.
///
/// Registered as a lazy singleton in the DI container so the same instance is
/// shared across all data sources.
class DioClient {
  /// The configured [Dio] instance ready for injection into data sources.
  late final Dio dio;

  late final List<String> _baseUrlCandidates;

  /// Creates a [DioClient] and configures the underlying [Dio] instance.
  ///
  /// Note: connectTimeout and receiveTimeout are set to 60 seconds to account for
  /// Cloud Run cold starts, which can take 10-30 seconds on the first request.
  DioClient({Future<String?> Function()? tokenProvider}) {
    _baseUrlCandidates = ApiConfig.baseUrlCandidates;

    // Debug logging for Cloud Run deployment
    if (kDebugMode) {
      debugPrint('[DioClient] Initializing with base URL: ${_baseUrlCandidates.first}');
      debugPrint('[DioClient] Fallback candidates: $_baseUrlCandidates');
    }

    dio = Dio(
      BaseOptions(
        baseUrl: _baseUrlCandidates.first,
        // Increased from 15s to 60s to handle Cloud Run cold starts
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: const {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      _BaseUrlFallbackInterceptor(
        dio: dio,
        baseUrlCandidates: _baseUrlCandidates,
      ),
    );
    dio.interceptors.add(_AuthInterceptor(tokenProvider: tokenProvider));
  }
}

class _BaseUrlFallbackInterceptor extends Interceptor {
  static const _attemptKey = 'baseUrlFallbackAttempt';

  final Dio _dio;
  final List<String> _baseUrlCandidates;

  _BaseUrlFallbackInterceptor({
    required Dio dio,
    required List<String> baseUrlCandidates,
  }) : _dio = dio,
       _baseUrlCandidates = baseUrlCandidates;

  bool _isRetryable(DioException exception) {
    return exception.type == DioExceptionType.connectionError ||
        exception.type == DioExceptionType.connectionTimeout ||
        exception.type == DioExceptionType.receiveTimeout ||
        exception.type == DioExceptionType.unknown;
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (kDebugMode) {
      debugPrint('[DioClient] Error on ${err.requestOptions.uri}: ${err.type}');
    }

    if (!_isRetryable(err)) {
      if (kDebugMode) {
        debugPrint('[DioClient] Non-retryable error, passing through');
      }
      handler.next(err);
      return;
    }

    final currentAttempt = (err.requestOptions.extra[_attemptKey] as int?) ?? 0;
    final nextAttempt = currentAttempt + 1;

    if (nextAttempt >= _baseUrlCandidates.length) {
      if (kDebugMode) {
        debugPrint('[DioClient] No more fallback candidates, passing error through');
      }
      handler.next(err);
      return;
    }

    final nextBaseUrl = _baseUrlCandidates[nextAttempt];
    
    if (kDebugMode) {
      debugPrint('[DioClient] Retrying with base URL: $nextBaseUrl (attempt $nextAttempt/${_baseUrlCandidates.length})');
    }
    
    final retriedRequest = err.requestOptions.copyWith(
      baseUrl: nextBaseUrl,
      extra: <String, Object?>{
        ...err.requestOptions.extra,
        _attemptKey: nextAttempt,
      },
    );

    try {
      final response = await _dio.fetch<dynamic>(retriedRequest);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }
}

/// Returns `true` when [path] targets a backend route that requires a Firebase
/// ID token (i.e. a route under `/users`).
///
/// Public routes such as `/ping` and `/manga` return `false` and are forwarded
/// without an `Authorization` header so unauthenticated access continues to
/// work normally.
bool isProtectedAuthPath(String path) {
  return _AuthInterceptor.isProtectedPath(path);
}

/// Attaches a `Bearer` authorization header to [options] when the request
/// targets a protected backend path.
///
/// [tokenProvider] is called only when [options.path] is a protected route.
/// If the provider returns `null`, an empty string, or throws, the header is
/// silently omitted — the backend will respond with HTTP 401 which the caller
/// is responsible for handling.
Future<void> attachAuthHeaderForRequest(
  RequestOptions options, {
  required Future<String?> Function() tokenProvider,
}) {
  return _AuthInterceptor.attachAuthHeader(
    options,
    tokenProvider: tokenProvider,
  );
}

class _AuthInterceptor extends Interceptor {
  static const _protectedPaths = <String>['/users'];

  final Future<String?> Function() _tokenProvider;

  _AuthInterceptor({Future<String?> Function()? tokenProvider})
    : _tokenProvider = tokenProvider ?? _emptyTokenProvider;

  static Future<String?> _emptyTokenProvider() async => null;

  static bool isProtectedPath(String path) {
    return _protectedPaths.any(path.startsWith);
  }

  static Future<void> attachAuthHeader(
    RequestOptions options, {
    required Future<String?> Function() tokenProvider,
  }) async {
    if (!isProtectedPath(options.path)) {
      return;
    }

    try {
      final token = await tokenProvider();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } on Exception {
      // Token retrieval failed - forward the request without auth header.
      // The backend will return 401, which the caller can handle.
    }
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    await attachAuthHeader(options, tokenProvider: _tokenProvider);

    handler.next(options);
  }
}
