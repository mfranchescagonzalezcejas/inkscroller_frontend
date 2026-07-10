// ponytail: stable failure codes replace hardcoded user-facing messages — the
// presentation layer resolves these codes via resolveCleanupErrorText().

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

  static const _deletionCleanupPendingKey =
      'settings.accountDeletionCleanupPending';
  static const _deletionCleanupPendingUidKey =
      'settings.accountDeletionCleanupPendingUid';

  /// Creates an [AccountCleanupRepositoryImpl].
  const AccountCleanupRepositoryImpl({
    required FirebaseAuth firebaseAuth,
    required SharedPreferences prefs,
  }) : _firebaseAuth = firebaseAuth,
       _prefs = prefs;

  @override
  Future<String?> cleanUpAfterDeletion({String? password}) async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      // Reauthenticate if password is provided — needed when Firebase
      // requires a recent login for sensitive operations.
      if (password != null) {
        try {
          await user.reauthenticateWithCredential(
            EmailAuthProvider.credential(
              email: user.email!,
              password: password,
            ),
          );
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            throw const AccountCleanupException(
              message: 'requires-recent-login',
              requiresRecentLogin: true,
              code: 'requires-recent-login',
            );
          }
          // Wrap other reauth errors (wrong password, user mismatch, etc.)
          // so the caller can display the Firebase error message.
          final (:message, :code) = _reauthError(e);
          throw AccountCleanupException(
            message: code,
            requiresRecentLogin: false,
            code: code,
          );
        }
      }

      // Firebase Auth deletion is critical: failure here must prevent the
      // provider from marking account deletion as successful.
      //
      // `user-not-found` means the Firebase user was already deleted (e.g.
      // by a prior backend call or manual cleanup). Treat it as success.
      //
      // `requires-recent-login` means the user must re-authenticate.
      // Throw a typed exception so the caller can prompt for login.
      //
      // On non-user-not-found failure, preserve the session — the caller
      // still owns the account and must not be signed out.
      var shouldSignOut = true;
      try {
        await user.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          // Already deleted — treat as success.
        } else if (e.code == 'requires-recent-login') {
          throw const AccountCleanupException(
            message: 'requires-recent-login',
            requiresRecentLogin: true,
            code: 'requires-recent-login',
          );
        } else {
          shouldSignOut = false;
          throw const AccountCleanupException(
            message: 'firebase-delete-failed',
            requiresRecentLogin: false,
            code: 'firebase-delete-failed',
          );
        }
      }
      if (shouldSignOut) await _firebaseAuth.signOut();
    } else {
      await _firebaseAuth.signOut();
    }

    String? warning;
    try {
      final cleared = await _prefs.clear();
      if (!cleared) {
        warning = 'Prefs clear failed';
      }
    } on Exception catch (_) {
      warning = 'Prefs clear failed';
    }

    return warning;
  }

  @override
  Future<void> markDeletionCleanupPending() async {
    // UID-first: a crash between writes leaves pending=false with a UID (safe),
    // never pending=true without UID (which would skip backend for wrong user).
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) {
      await _prefs.remove(_deletionCleanupPendingUidKey);
      return;
    }
    await _prefs.setString(_deletionCleanupPendingUidKey, uid);
    await _prefs.setBool(_deletionCleanupPendingKey, true);
  }

  @override
  Future<bool> hasDeletionCleanupPending() async {
    final pendingUid = _prefs.getString(_deletionCleanupPendingUidKey);
    final currentUid = _firebaseAuth.currentUser?.uid;
    if (pendingUid == null || pendingUid != currentUid) return false;

    // UID-only marker (crash between UID write and bool write) is still
    // pending — the backend DELETE succeeded but cleanup never completed.
    return _prefs.getBool(_deletionCleanupPendingKey) ?? true;
  }

  @override
  Future<void> clearDeletionCleanupPending() async {
    await _prefs.remove(_deletionCleanupPendingKey);
    await _prefs.remove(_deletionCleanupPendingUidKey);
  }

  @override
  String? get currentCleanupUserId => _firebaseAuth.currentUser?.uid;

  /// Returns a (message, code) pair for a Firebase reauth error.
  ({String message, String code}) _reauthError(FirebaseAuthException e) {
    return switch (e.code) {
      'wrong-password' => (message: 'wrong-password', code: 'wrong-password'),
      'user-mismatch' => (message: 'user-mismatch', code: 'user-mismatch'),
      'invalid-credential' => (
        message: 'invalid-credential',
        code: 'invalid-credential',
      ),
      'too-many-requests' => (
        message: 'too-many-requests',
        code: 'too-many-requests',
      ),
      _ => (message: 'auth-error', code: 'auth-error'),
    };
  }
}
