import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../../library/presentation/providers/per_title_override_provider.dart';
import '../../../library/presentation/providers/reading_progress_provider.dart';
import '../../../library/presentation/providers/user_library_provider.dart';
import '../../../preferences/presentation/providers/preferences_provider.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
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
  final AccountCleanupRepository _cleanup;
  final VoidCallback? _onAccountDeleted;

  /// In-memory recovery signal: stores the UID for which the backend DELETE
  /// was called successfully. Retries skip the backend only when the stored
  /// UID matches the current cleanup user identity, preventing cross-user
  /// or cross-session stale skips.
  String? _backendSucceededUid;

  /// Creates a [SettingsNotifier] with the given [repository] and [cleanup].
  ///
  /// [onAccountDeleted] is called after Firebase/local cleanup succeeds and
  /// before publishing `accountDeleted: true`. Use it to invalidate
  /// user-scoped providers (e.g. reading progress).
  SettingsNotifier({
    required SettingsRepository repository,
    required AccountCleanupRepository cleanup,
    VoidCallback? onAccountDeleted,
  }) : _repository = repository,
       _cleanup = cleanup,
       _onAccountDeleted = onAccountDeleted,
       super(const SettingsState());

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

    // Skip backend when either the persisted marker (scoped to current UID)
    // OR the in-memory flag (scoped to the current session's user identity)
    // confirms backend already succeeded.
    final currentUserId = _cleanup.currentCleanupUserId;
    final shouldSkipBackend =
        (_backendSucceededUid != null &&
            _backendSucceededUid == currentUserId) ||
        await _cleanup.hasDeletionCleanupPending();

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

      _backendSucceededUid = currentUserId;

      try {
        await _cleanup.markDeletionCleanupPending();
      } on Exception catch (_) {
        // Marker write failed after backend succeeded. The UID-scoped
        // _backendSucceededUid preserves the recovery signal so retries
        // within this session skip the backend. The durable marker
        // handles cross-session retries.
      }
    }

    String? warning;
    try {
      warning = await _cleanup.cleanUpAfterDeletion(password: password);
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

    // ponytail: best-effort marker clear — account is gone, don't block success.
    try {
      await _cleanup.clearDeletionCleanupPending();
    } on Exception catch (_) {
      // Marker clear failed after backend + Firebase cleanup succeeded.
      // The account is already deleted; a stale marker will not match a new
      // user's UID, so this is safe to swallow.
    }

    _backendSucceededUid = null;
    _onAccountDeleted?.call();
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

/// Account cleanup repository provider bridging get_it to Riverpod.
final accountCleanupRepositoryProvider = Provider<AccountCleanupRepository>((
  ref,
) {
  return sl<AccountCleanupRepository>();
});

/// StateNotifier provider for account-level settings.
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    return SettingsNotifier(
      repository: ref.watch(settingsRepositoryProvider),
      cleanup: ref.watch(accountCleanupRepositoryProvider),
      onAccountDeleted: () {
        ref.invalidate(readingProgressProvider);
        ref.invalidate(userProfileProvider);
        ref.invalidate(userLibrarySyncingProvider);
        ref.invalidate(userLibraryProvider);
        ref.invalidate(preferencesProvider);
        ref.invalidate(perTitleOverrideProvider);
      },
    );
  },
);
