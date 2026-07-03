import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/account_cleanup_repository.dart';

/// Handles local cleanup after backend account deletion.
///
/// Removes the Firebase user (non-blocking on failure), clears local
/// preferences, and signs out. Returns a warning string if any non-critical
/// step failed.
class AccountCleanupRepositoryImpl implements AccountCleanupRepository {
  final FirebaseAuth _firebaseAuth;
  final SharedPreferences _prefs;

  /// Creates an [AccountCleanupRepositoryImpl].
  const AccountCleanupRepositoryImpl({
    required FirebaseAuth firebaseAuth,
    required SharedPreferences prefs,
  })  : _firebaseAuth = firebaseAuth,
        _prefs = prefs;

  @override
  Future<String?> cleanUpAfterDeletion() async {
    String? warning;
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      try {
        await user.delete();
      } on Exception catch (_) {
        // ponytail: safe message, no raw exception text for user-facing state
        warning = 'Firebase user deletion failed';
      }
    }

    try {
      final cleared = await _prefs.clear();
      if (!cleared) {
        warning =
            warning != null ? '$warning; Prefs clear failed' : 'Prefs clear failed';
      }
    } on Exception catch (_) {
      warning =
          warning != null ? '$warning; Prefs clear failed' : 'Prefs clear failed';
    }

    await _firebaseAuth.signOut();
    return warning;
  }
}
