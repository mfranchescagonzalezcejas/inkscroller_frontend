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

  /// True when backend deletion succeeded but cleanup is pending retry.
  final bool cleanupRecoveryPending;

  /// True when the cleanup exception requires recent login to proceed.
  final bool requiresRecentLogin;

  /// Creates the initial settings state.
  const SettingsState({
    this.isDeletingAccount = false,
    this.deleteError,
    this.accountDeleted = false,
    this.deleteWarning,
    this.cleanupRecoveryPending = false,
    this.requiresRecentLogin = false,
  });

  /// Returns a copy of this state with the provided fields overwritten.
  SettingsState copyWith({
    bool? isDeletingAccount,
    String? deleteError,
    bool? accountDeleted,
    bool clearError = false,
    String? deleteWarning,
    bool clearWarning = false,
    bool? cleanupRecoveryPending,
    bool? requiresRecentLogin,
  }) {
    return SettingsState(
      isDeletingAccount: isDeletingAccount ?? this.isDeletingAccount,
      deleteError: clearError ? null : deleteError ?? this.deleteError,
      accountDeleted: accountDeleted ?? this.accountDeleted,
      deleteWarning: clearWarning ? null : deleteWarning ?? this.deleteWarning,
      cleanupRecoveryPending:
          cleanupRecoveryPending ?? this.cleanupRecoveryPending,
      requiresRecentLogin: requiresRecentLogin ?? this.requiresRecentLogin,
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
  /// Supports a retry state machine: if the backend succeeded but Firebase
  /// cleanup failed previously, retrying skips the backend call and goes
  /// straight to cleanup with the provided [password].
  Future<void> deleteAccount({String? password}) async {
    if (state.isDeletingAccount) return;

    final isRetry = state.cleanupRecoveryPending;

    state = state.copyWith(
      isDeletingAccount: true,
      clearError: true,
      clearWarning: true,
      accountDeleted: false,
      requiresRecentLogin: isRetry && state.requiresRecentLogin,
    );

    // Skip backend only when the persisted cleanup marker belongs to the
    // current Firebase user. The in-memory flag drives UI state only; it must
    // not bypass the scoped marker check.
    final shouldSkipBackend = await _cleanupRepo.hasDeletionCleanupPending();

    if (!shouldSkipBackend) {
      final result = await _repository.deleteAccount();

      final failure = result.fold<Failure?>((failure) => failure, (_) => null);
      if (failure != null) {
        state = state.copyWith(
          isDeletingAccount: false,
          deleteError: failure.message,
          requiresRecentLogin: false,
        );
        return;
      }

      try {
        await _cleanupRepo.markDeletionCleanupPending();
      } on Exception catch (_) {
        // Marker persistence is recovery bookkeeping — best-effort.
      }
    }

    String? warning;
    try {
      warning = await _cleanupRepo.cleanUpAfterDeletion(password: password);
    } on AccountCleanupException catch (e) {
      state = state.copyWith(
        isDeletingAccount: false,
        cleanupRecoveryPending: true,
        deleteError: e.message,
        requiresRecentLogin: e.requiresRecentLogin,
      );
      return;
    } on Exception catch (_) {
      state = state.copyWith(
        isDeletingAccount: false,
        cleanupRecoveryPending: true,
        deleteError: 'Error durante la limpieza',
      );
      return;
    }

    await _cleanupRepo.clearDeletionCleanupPending();
    state = state.copyWith(
      isDeletingAccount: false,
      accountDeleted: true,
      cleanupRecoveryPending: false,
      requiresRecentLogin: false,
      deleteWarning: warning,
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
