import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/design_tokens.dart'
    show AppColors;
import '../providers/settings_provider.dart';

/// AlertDialog for permanent account deletion with typed confirmation.
///
/// The user must type "DELETE" to enable the confirm button.
class DeleteAccountDialog extends ConsumerStatefulWidget {
  /// Creates a [DeleteAccountDialog].
  const DeleteAccountDialog({super.key});

  @override
  ConsumerState<DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<DeleteAccountDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isDeleting = false;

  bool get _canDelete => _controller.text == 'DELETE';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
          const Text(
            'Esta acción es permanente e irreversible. Se eliminarán todos tus datos, '
            'incluyendo tu perfil, preferencias y progreso de lectura.',
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
      ),
      actions: <Widget>[
        TextButton(
          key: const Key('deleteCancelButton'),
          onPressed: _isDeleting
              ? null
              : () => Navigator.of(context).pop(false),
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
          onPressed: _canDelete && !_isDeleting
              ? () async {
                  setState(() => _isDeleting = true);
                  await ref.read(settingsProvider.notifier).deleteAccount();
                  if (!context.mounted) return;
                  Navigator.of(context).pop(true);
                }
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
          ),
          child: _isDeleting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.voidLowest,
                  ),
                )
              : const Text(
                  'Eliminar',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: AppColors.voidLowest,
                  ),
                ),
        ),
      ],
    );
  }
}
