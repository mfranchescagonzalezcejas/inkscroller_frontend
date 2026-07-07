import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/design_tokens.dart' show AppColors;
import '../providers/settings_provider.dart';

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
    final state = ref.watch(settingsProvider);
    final bool isPending = state.cleanupRecoveryPending;
    final bool needsPassword = state.requiresRecentLogin;
    final bool busy = _isDeleting || isPending;

    final bool canConfirm = isPending
        ? !_isDeleting && (!needsPassword || _passwordController.text.isNotEmpty)
        : _canDelete && !_isDeleting;

    return PopScope(
      canPop: !busy,
      child: AlertDialog(
        backgroundColor: AppColors.stage,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Eliminar cuenta',
          style: TextStyle(
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
                state.deleteError ??
                    'La eliminación está incompleta. '
                        'Es necesario finalizar la limpieza de datos.',
                key: const Key('deleteRecoveryMessage'),
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  color: AppColors.danger,
                ),
              ),
            ] else ...[
              const Text(
                'Esta acción es permanente e irreversible. Se eliminarán todos '
                'tus datos, incluyendo tu perfil, preferencias y progreso '
                'de lectura.',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Escribí DELETE para confirmar:',
                style: TextStyle(
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
              const Text(
                'Ingresá tu contraseña para reintentar:',
                style: TextStyle(
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
                  hintText: 'Contraseña',
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
            child: const Text(
              'Cancelar',
              style: TextStyle(
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
                      Navigator.of(context).pop(true);
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
                    isPending ? 'Finalizar' : 'Eliminar',
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
