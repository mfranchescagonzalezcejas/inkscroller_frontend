import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  /// Creates the initial settings state.
  const SettingsState({
    this.isDeletingAccount = false,
    this.deleteError,
    this.accountDeleted = false,
  });

  /// Returns a copy of this state with the provided fields overwritten.
  SettingsState copyWith({
    bool? isDeletingAccount,
    String? deleteError,
    bool? accountDeleted,
    bool clearError = false,
  }) {
    return SettingsState(
      isDeletingAccount: isDeletingAccount ?? this.isDeletingAccount,
      deleteError: clearError ? null : deleteError ?? this.deleteError,
      accountDeleted: accountDeleted ?? this.accountDeleted,
    );
  }
}

/// Manages account-level settings operations (e.g. account deletion).
class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsRepository _repository;

  /// Creates a [SettingsNotifier] with the given [repository].
  SettingsNotifier({required SettingsRepository repository})
    : _repository = repository,
      super(const SettingsState());

  /// Deletes the authenticated user's account.
  ///
  /// Transitions through loading → success (accountDeleted=true + signOut) or
  /// error state.
  Future<void> deleteAccount() async {
    state = state.copyWith(
      isDeletingAccount: true,
      clearError: true,
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
      await _signOutAfterDeletion();
      state = state.copyWith(
        isDeletingAccount: false,
        accountDeleted: true,
      );
    }
  }

  /// Signs out the user after successful account deletion.
  Future<void> _signOutAfterDeletion() async {
    try {
      await FirebaseAuth.instance.signOut();
    } on FirebaseAuthException catch (_) {
      // Sign-out failure after deletion is non-critical — the backend account
      // is already deleted. The auth stream listener will pick up the state.
    }
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
