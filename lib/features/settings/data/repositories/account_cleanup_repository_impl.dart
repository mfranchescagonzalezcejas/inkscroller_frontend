import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/account_cleanup_repository.dart';

/// Handles local cleanup after backend account deletion.
///
/// Removes the Firebase user (critical — failure is rethrown to prevent the
/// provider from marking deletion as complete), clears local preferences,
/// and signs out.
class AccountCleanupRepositoryImpl implements AccountCleanupRepository {
  final FirebaseAuth _firebaseAuth;
  final SharedPreferences _prefs;

  /// Creates an [AccountCleanupRepositoryImpl].
  const AccountCleanupRepositoryImpl({
    required FirebaseAuth firebaseAuth,
    required SharedPreferences prefs,
  }) : _firebaseAuth = firebaseAuth,
       _prefs = prefs;

  @override
  Future<String?> cleanUpAfterDeletion() async {
    String? warning;

    try {
      final cleared = await _prefs.clear();
      if (!cleared) {
        warning = 'Prefs clear failed';
      }
    } on Exception catch (_) {
      warning = 'Prefs clear failed';
    }

    final user = _firebaseAuth.currentUser;
    if (user != null) {
      // Firebase Auth deletion is critical: failure here must prevent the
      // provider from marking account deletion as successful.
      //
      // `user-not-found` means the Firebase user was already deleted (e.g.
      // by a prior backend call or manual cleanup). Treat it as success.
      //
      // On non-user-not-found failure, preserve the session — the caller
      // still owns the account and must not be signed out.
      var shouldSignOut = true;
      try {
        await user.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code != 'user-not-found') {
          shouldSignOut = false;
          rethrow;
        }
      }
      if (shouldSignOut) await _firebaseAuth.signOut();
    } else {
      await _firebaseAuth.signOut();
    }

    return warning;
  }
}
