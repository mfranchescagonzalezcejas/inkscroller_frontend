/// Domain contract for post-deletion local cleanup.
///
/// Handles Firebase user removal, local data clearing, and sign-out after the
/// backend has successfully deleted the account. Presentation depends on this
/// contract instead of on Firebase/SharedPreferences directly.
// ignore: one_member_abstracts
abstract class AccountCleanupRepository {
  /// Clears local state and signs the user out after backend account deletion.
  ///
  /// Returns a warning string if any non-critical step failed, or `null` on
  /// full success. Throws only on critical failures that prevent sign-out.
  Future<String?> cleanUpAfterDeletion();
}
