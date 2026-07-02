import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/di/injection.dart';
import '../../domain/repositories/settings_repository.dart';

/// State for account-level settings operations.
class SettingsState {
  /// True while the account deletion request is in-flight.
  final bool isDeletingAccount;

  /// Non-null when the last deletion attempt failed.
  final String? deleteError;

  /// True after the account has been successfully deleted.
  final bool accountDeleted;

  /// Non-null when backend deletion succeeded but Firebase user cleanup failed.
  final String? deleteWarning;

  /// Creates the initial settings state.
  const SettingsState({
    this.isDeletingAccount = false,
    this.deleteError,
    this.accountDeleted = false,
    this.deleteWarning,
  });

  /// Returns a copy of this state with the provided fields overwritten.
  SettingsState copyWith({
    bool? isDeletingAccount,
    String? deleteError,
    bool? accountDeleted,
    bool clearError = false,
    String? deleteWarning,
    bool clearWarning = false,
  }) {
    return SettingsState(
      isDeletingAccount: isDeletingAccount ?? this.isDeletingAccount,
      deleteError: clearError ? null : deleteError ?? this.deleteError,
      accountDeleted: accountDeleted ?? this.accountDeleted,
      deleteWarning:
          clearWarning ? null : deleteWarning ?? this.deleteWarning,
    );
  }
}

/// Manages account-level settings operations (e.g. account deletion).
class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsRepository _repository;
  final FirebaseAuth _firebaseAuth;

  /// Creates a [SettingsNotifier] with the given [repository].
  ///
  /// Optionally inject [firebaseAuth] for testability; defaults to
  /// `FirebaseAuth.instance` in production.
  SettingsNotifier({
    required SettingsRepository repository,
    FirebaseAuth? firebaseAuth,
  })  : _repository = repository,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        super(const SettingsState());

  /// Deletes the authenticated user's account.
  ///
  /// Transitions through loading → success (accountDeleted=true + signOut) or
  /// error state.
  Future<void> deleteAccount() async {
    state = state.copyWith(
      isDeletingAccount: true,
      clearError: true,
      clearWarning: true,
      accountDeleted: false,
    );

    final result = await _repository.deleteAccount();

    result.fold(
      (failure) {
        state = state.copyWith(
          isDeletingAccount: false,
          deleteError: failure.message,
        );
      },
      (_) {},
    );

    if (result.isRight()) {
      String? warning;
      var cleanupFailed = false;
      try {
        warning = await _signOutAfterDeletion();
      } on Exception catch (e) {
        warning = 'Local cleanup failed: $e';
        cleanupFailed = true;
      }
      state = state.copyWith(
        isDeletingAccount: false,
        accountDeleted: !cleanupFailed,
        deleteError: cleanupFailed ? warning : null,
        deleteWarning: cleanupFailed ? null : warning,
      );
    }
  }

  /// Signs out the user after successful account deletion.
  ///
  /// Attempts to delete the Firebase user (non-blocking on failure),
  /// then clears local data and signs out. Returns a warning string
  /// if Firebase user deletion failed, null otherwise.
  Future<String?> _signOutAfterDeletion() async {
    String? warning;
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      try {
        await user.delete();
      } on Exception catch (e) {
        warning = 'Firebase user deletion failed: $e';
      }
    }

    final prefs = sl<SharedPreferences>();
    final cleared = await prefs.clear();
    if (!cleared) {
      throw Exception('SharedPreferences clear failed');
    }

    await _firebaseAuth.signOut();
    return warning;
  }

  /// Clears the current error state.
  void resetState() {
    state = state.copyWith(clearError: true);
  }
}

/// Repository provider bridging get_it to Riverpod.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return sl<SettingsRepository>();
});

/// StateNotifier provider for account-level settings.
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    return SettingsNotifier(repository: ref.watch(settingsRepositoryProvider));
  },
);
