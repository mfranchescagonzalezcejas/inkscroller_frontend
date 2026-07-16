import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/design_tokens.dart' show AppColors;
import '../../../../core/l10n/l10n.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';

/// Resolves a stable cleanup error key to its localized message.
///
/// Returns the corresponding l10n string for known keys, or a generic
/// localized error for keys that cannot be recognized.
String resolveCleanupErrorText(String? errorKey, AppLocalizations l10n) {
  return switch (errorKey) {
    'requires-recent-login' => l10n.cleanupRequiresRecentLogin,
    'firebase-delete-failed' => l10n.cleanupFirebaseDeleteFailed,
    'wrong-password' => l10n.cleanupReauthWrongPassword,
    'user-mismatch' => l10n.cleanupReauthUserMismatch,
    'invalid-credential' => l10n.cleanupReauthInvalidCredential,
    'too-many-requests' => l10n.cleanupReauthTooManyRequests,
    'auth-error' => l10n.cleanupReauthAuthError,
    'cleanup-session-expired' => l10n.cleanupSessionExpired,
    cleanupUnexpectedErrorKey => l10n.cleanupUnexpectedError,
    cleanupWarningKey => l10n.cleanupPrefsClearWarning,
    _ => l10n.cleanupUnexpectedError, // fallback: catch-all for unknown codes
  };
}

/// AlertDialog for permanent account deletion with typed confirmation.
///
/// The user must type "DELETE" to enable the confirm button.
/// Supports cleanup retry: keeps dialog open while `cleanupRecoveryPending`
/// and optionally shows a password field when `requiresRecentLogin`.
class DeleteAccountDialog extends ConsumerStatefulWidget {
  /// Creates a [DeleteAccountDialog].
  const DeleteAccountDialog({super.key});

  @override
  ConsumerState<DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<DeleteAccountDialog> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isDeleting = false;

  bool get _canDelete => _controller.text == 'DELETE';

  @override
  void dispose() {
    _controller.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(settingsProvider);
    final bool isPending = state.cleanupRecoveryPending;
    final bool needsPassword = state.requiresRecentLogin;
    final bool busy = _isDeleting || isPending;

    final bool canConfirm = isPending
        ? !_isDeleting &&
              (!needsPassword || _passwordController.text.isNotEmpty)
        : _canDelete && !_isDeleting;

    final String? recoveryErrorText = isPending && state.deleteError != null
        ? resolveCleanupErrorText(state.deleteError, l10n)
        : null;

    return PopScope(
      canPop: !busy,
      child: AlertDialog(
        backgroundColor: AppColors.stage,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.deleteAccountTitle,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (isPending) ...[
              Text(
                recoveryErrorText ??
                    l10n.deleteAccountIncompleteRecoveryMessage,
                key: const Key('deleteRecoveryMessage'),
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  color: AppColors.danger,
                ),
              ),
            ] else ...[
              Text(
                l10n.deleteAccountWarningBody,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.deleteAccountPrompt,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('deleteConfirmField'),
                controller: _controller,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  color: AppColors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'DELETE',
                  hintStyle: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    color: AppColors.outline.withValues(alpha: 0.5),
                  ),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: AppColors.outline),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: AppColors.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.danger),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
            if (needsPassword) ...[
              const SizedBox(height: 16),
              Text(
                l10n.deleteAccountPasswordLabel,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('deletePasswordField'),
                controller: _passwordController,
                obscureText: true,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  color: AppColors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: l10n.deleteAccountPasswordHint,
                  hintStyle: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    color: AppColors.outline.withValues(alpha: 0.5),
                  ),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: AppColors.outline),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: AppColors.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.danger),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: <Widget>[
          TextButton(
            key: const Key('deleteCancelButton'),
            onPressed: busy ? null : () => Navigator.of(context).pop(false),
            child: Text(
              l10n.deleteAccountCancelAction,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          FilledButton(
            key: const Key('deleteConfirmButton'),
            onPressed: canConfirm
                ? () async {
                    setState(() => _isDeleting = true);
                    final String? password = needsPassword
                        ? _passwordController.text
                        : null;
                    await ref
                        .read(settingsProvider.notifier)
                        .deleteAccount(password: password);
                    if (!context.mounted) return;
                    final latestState = ref.read(settingsProvider);
                    if (latestState.accountDeleted) {
                      // Defer the pop to the next frame so GoRouter's auth
                      // redirect re-evaluation (triggered by Firebase auth
                      // state change during deleteAccount) settles before
                      // we interact with the Navigator.
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!context.mounted) return;
                        Navigator.of(context).pop(true);
                      });
                    } else {
                      setState(() => _isDeleting = false);
                    }
                  }
                : null,
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: _isDeleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.voidLowest,
                    ),
                  )
                : Text(
                    isPending
                        ? l10n.deleteAccountFinalizeAction
                        : l10n.deleteAccountDeleteAction,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      color: AppColors.voidLowest,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
