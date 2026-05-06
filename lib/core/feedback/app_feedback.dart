import 'package:flutter/material.dart';
import '../design/app_colors.dart';

/// Unified feedback patterns for InkScroller.
///
/// Provides consistent snackbars and dialogs following the "Void" aesthetic:
/// - Background blur effect
/// - Rounded corners (22px for snackbars, 16px for dialogs)
/// - Proper color coding for different states (success, error, warning, info)
///
/// Usage:
/// ```dart
/// AppFeedback.showSuccess(context, 'Download complete', 'Shadow of the Infinite saved offline');
/// AppFeedback.showError(context, 'Download failed', 'Check your connection and try again');
/// AppFeedback.showUndo(context, 'Chapter removed', 'Shadow of the Infinite · Chapter 128', onUndo: () {});
/// ```
class AppFeedback {
  AppFeedback._();

  // ═══════════════════════════════════════════════════════════════════════
  // SNACKBAR STATES
  // ═══════════════════════════════════════════════════════════════════════

  /// Shows a success snackbar with checkmark icon.
  static void showSuccess(
    BuildContext context, {
    required String title,
    String? body,
  }) {
    _showSnackBar(
      context,
      icon: Icons.check_circle_outline,
      iconColor: AppColors.primary,
      iconBackground: AppColors.primary.withValues(alpha: 0.12),
      title: title,
      body: body,
    );
  }

  /// Shows an error snackbar with error icon.
  static void showError(
    BuildContext context, {
    required String title,
    String? body,
  }) {
    _showSnackBar(
      context,
      icon: Icons.error_outline,
      iconColor: const Color(0xFFF44336),
      iconBackground: const Color(0xFFF44336).withValues(alpha: 0.12),
      title: title,
      body: body,
    );
  }

  /// Shows a warning snackbar with warning icon.
  static void showWarning(
    BuildContext context, {
    required String title,
    String? body,
  }) {
    _showSnackBar(
      context,
      icon: Icons.warning_amber_outlined,
      iconColor: const Color(0xFFFF9800),
      iconBackground: const Color(0xFFFF9800).withValues(alpha: 0.12),
      title: title,
      body: body,
    );
  }

  /// Shows an info snackbar with info icon.
  static void showInfo(
    BuildContext context, {
    required String title,
    String? body,
  }) {
    _showSnackBar(
      context,
      icon: Icons.info_outline,
      iconColor: const Color(0xFF2196F3),
      iconBackground: const Color(0xFF2196F3).withValues(alpha: 0.12),
      title: title,
      body: body,
    );
  }

  /// Shows a snackbar with undo action.
  static void showUndo(
    BuildContext context, {
    required String title,
    String? body,
    required VoidCallback onUndo,
    String undoLabel = 'UNDO',
  }) {
    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.glassSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      content: Row(
        children: [
          // Icon chip
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.delete_outline,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          // Text content
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (body != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // UNDO action
          TextButton(
            onPressed: () {
              onUndo();
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
            child: Text(
              undoLabel,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Shows a dismissible snackbar with close button.
  static void showDismissible(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? body,
  }) {
    _showSnackBar(
      context,
      icon: icon,
      iconColor: iconColor,
      iconBackground: iconColor.withValues(alpha: 0.12),
      title: title,
      body: body,
      showClose: true,
    );
  }

  /// Shows a progress snackbar.
  static void showProgress(
    BuildContext context, {
    required String title,
    double progress = 0.0,
  }) {
    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.glassSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      content: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.download_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.outlineVariant,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // ══════════════════════════════════════════════════════════════���
  // DIALOGS
  // ═══════════════════════════════════════════════════════════════

  /// Shows a confirmation dialog.
  static Future<bool> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.stage,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelText,
              style: const TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: isDestructive ? const Color(0xFFF44336) : AppColors.primary,
            ),
            child: Text(
              confirmText,
              style: const TextStyle(color: AppColors.voidLowest),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ═══════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════

  static void _showSnackBar(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String title,
    String? body,
    bool showClose = false,
  }) {
    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.glassSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      duration: const Duration(seconds: 3),
      content: Row(
        children: [
          // Icon chip
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          // Text content
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (body != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: const TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Close button (optional)
          if (showClose)
            IconButton(
              icon: const Icon(
                Icons.close,
                color: AppColors.outline,
                size: 20,
              ),
              onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
