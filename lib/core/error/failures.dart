/// Base type for all domain-safe failures exposed to presentation.
sealed class Failure {
  const Failure({required this.message, this.code});

  final String message;
  final int? code;
}

/// Failure caused by HTTP/server responses.
final class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});
}

/// Failure caused by connectivity or request timeout issues.
final class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code});
}

/// Failure caused by cache or local persistence issues.
final class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}

/// Failure used for unknown or unexpected conditions.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure({required super.message, super.code});
}

/// Failure emitted when a chapter is marked as external-only and cannot be
/// rendered inside the in-app reader.
///
/// [externalUrl] carries the URL where the chapter can be opened, if known.
/// Used by [ReaderPage] to show a redirect/warning screen instead of the reader.
final class ExternalChapterFailure extends Failure {
  const ExternalChapterFailure({
    required super.message,
    this.externalUrl,
  });

  /// The URL to which the user should be directed, or `null` if unknown.
  final String? externalUrl;
}
