/// Domain contract for post-deletion local cleanup.
///
/// Handles Firebase user removal (critical — throws on failure), local data
/// clearing, and sign-out after the backend has successfully deleted the
/// account. Presentation depends on this contract instead of on
/// Firebase/SharedPreferences directly.
// ignore: one_member_abstracts
abstract class AccountCleanupRepository {
  /// Clears local state and signs the user out after backend account deletion.
  ///
  /// When [password] is provided and the Firebase user still exists, the user
  /// is reauthenticated before deletion.
  ///
  /// Returns a warning string if any non-critical step failed, or `null` on
  /// full success. Throws on critical failures (e.g. Firebase Auth deletion)
  /// that prevent the caller from marking deletion as complete.
  Future<String?> cleanUpAfterDeletion({String? password});

  /// Marks that a deletion cleanup is pending (backend succeeded but
  /// Firebase/local cleanup has not completed).
  Future<void> markDeletionCleanupPending();

  /// Whether a deletion cleanup is pending.
  Future<bool> hasDeletionCleanupPending();

  /// Clears the pending deletion cleanup marker.
  Future<void> clearDeletionCleanupPending();

  /// Returns the UID of the current Firebase user, or `null` if signed out.
  String? get currentCleanupUserId;
}

/// Thrown when Firebase account deletion fails with a recoverable error.
///
/// [requiresRecentLogin] indicates the user must re-authenticate before
/// retrying the deletion.
class AccountCleanupException implements Exception {
  /// Creates an [AccountCleanupException].
  const AccountCleanupException({
    required this.message,
    required this.requiresRecentLogin,
    this.code,
  });

  /// User-facing error message.
  final String message;

  /// Whether the user must re-login before retrying.
  final bool requiresRecentLogin;

  /// Stable machine-readable label so presentation can map to l10n.
  final String? code;

  @override
  String toString() => 'AccountCleanupException: $message';
}
