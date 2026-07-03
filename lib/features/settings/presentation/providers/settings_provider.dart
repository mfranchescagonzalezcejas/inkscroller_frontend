import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/account_cleanup_repository.dart';
import '../../domain/repositories/settings_repository.dart';

/// State for account-level settings operations.
class SettingsState {
  /// True while the account deletion request is in-flight.
  final bool isDeletingAccount;

  /// Non-null when the last deletion attempt failed.
  final String? deleteError;

  /// True after the account has been successfully deleted.
  final bool accountDeleted;

  /// Non-null when backend deletion succeeded but local cleanup failed.
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
      deleteWarning: clearWarning ? null : deleteWarning ?? this.deleteWarning,
    );
  }
}

/// Manages account-level settings operations (e.g. account deletion).
class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsRepository _repository;
  final AccountCleanupRepository? _cleanup;

  /// Creates a [SettingsNotifier] with the given [repository] and [cleanup].
  ///
  /// Optionally inject [cleanup] for testability. When omitted, resolves
  /// lazily from `sl` inside [deleteAccount] after backend success.
  SettingsNotifier({
    required SettingsRepository repository,
    AccountCleanupRepository? cleanup,
  }) : _repository = repository,
       _cleanup = cleanup,
       super(const SettingsState());

  AccountCleanupRepository get _cleanupRepo =>
      _cleanup ?? sl<AccountCleanupRepository>();

  /// Deletes the authenticated user's account.
  ///
  /// Backend success or "already deleted" (404) marks deletion as complete
  /// only after Firebase Auth and local cleanup succeed. Cleanup exceptions
  /// (e.g. Firebase Auth deletion failure) are critical and prevent marking
  /// deletion. String warnings from cleanup are non-critical and shown
  /// alongside success.
  Future<void> deleteAccount() async {
    state = state.copyWith(
      isDeletingAccount: true,
      clearError: true,
      clearWarning: true,
      accountDeleted: false,
    );

    final result = await _repository.deleteAccount();

    result.fold((failure) {
      // On retry, backend may already be deleted (404) — treat as success
      // and proceed to Firebase/local cleanup.
      final isAlreadyDeleted = failure is ServerFailure && failure.code == 404;
      if (!isAlreadyDeleted) {
        state = state.copyWith(
          isDeletingAccount: false,
          deleteError: failure.message,
        );
        return;
      }
    }, (_) {});

    if (result.isRight() || _isAlreadyDeleted(result)) {
      String? warning;
      try {
        warning = await _cleanupRepo.cleanUpAfterDeletion();
      } on Exception catch (_) {
        state = state.copyWith(
          isDeletingAccount: false,
          deleteError: 'Error durante la limpieza',
        );
        return;
      }

      state = state.copyWith(
        isDeletingAccount: false,
        accountDeleted: true,
        deleteWarning: warning,
      );
    }
  }

  bool _isAlreadyDeleted(Either<Failure, void> result) {
    return result.fold(
      (failure) => failure is ServerFailure && failure.code == 404,
      (_) => false,
    );
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
