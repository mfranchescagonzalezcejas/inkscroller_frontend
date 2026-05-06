/// Base type for infrastructure exceptions thrown by data sources.
sealed class AppException implements Exception {
  const AppException({required this.message, this.code});

  final String message;
  final int? code;
}

/// Exception for API/server-side failures.
final class ServerException extends AppException {
  const ServerException({required super.message, super.code});
}

/// Exception for network and connectivity failures.
final class NetworkException extends AppException {
  const NetworkException({required super.message, super.code});
}

/// Exception for cache and local storage failures.
final class CacheException extends AppException {
  const CacheException({required super.message, super.code});
}

/// Exception for unclassified failures.
final class UnexpectedException extends AppException {
  const UnexpectedException({required super.message, super.code});
}
