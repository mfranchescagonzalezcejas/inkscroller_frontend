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
  final FirebaseAuth? _firebaseAuth;

  /// Creates a [SettingsNotifier] with the given [repository].
  ///
  /// Optionally inject [firebaseAuth] for testability. When omitted,
  /// `FirebaseAuth.instance` is resolved lazily at deletion time to
  /// avoid touching Firebase before `initializeApp`.
  SettingsNotifier({
    required SettingsRepository repository,
    FirebaseAuth? firebaseAuth,
  })  : _repository = repository,
        _firebaseAuth = firebaseAuth,
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
      } on Exception catch (_) {
        // ponytail: safe message, no raw exception text for user-facing state
        warning = 'Local cleanup failed';
        cleanupFailed = true;
      }
      // Surface any cleanup issue (exception or warning) as a visible error.
      cleanupFailed = cleanupFailed || warning != null;
      state = state.copyWith(
        isDeletingAccount: false,
        accountDeleted: !cleanupFailed,
        deleteError: cleanupFailed
            ? 'Account deleted, but cleanup failed. Please sign in again if needed.'
            : null,
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
    final auth = _firebaseAuth ?? FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user != null) {
      try {
        await user.delete();
      } on Exception catch (_) {
        // ponytail: safe message, no raw exception text for user-facing state
        warning = 'Firebase user deletion failed';
      }
    }

    final prefs = sl<SharedPreferences>();
    try {
      final cleared = await prefs.clear();
      if (!cleared) {
        warning =
            warning != null ? '$warning; Prefs clear failed' : 'Prefs clear failed';
      }
    } on Exception catch (_) {
      // ponytail: catch prefs.clear() exceptions so signOut always runs
      warning =
          warning != null ? '$warning; Prefs clear failed' : 'Prefs clear failed';
    }

    await auth.signOut();
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
