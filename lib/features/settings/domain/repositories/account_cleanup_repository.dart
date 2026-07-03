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
  /// Returns a warning string if any non-critical step failed, or `null` on
  /// full success. Throws on critical failures (e.g. Firebase Auth deletion)
  /// that prevent the caller from marking deletion as complete.
  Future<String?> cleanUpAfterDeletion();
}
