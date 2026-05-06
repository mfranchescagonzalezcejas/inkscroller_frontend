import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkscroller_flutter/core/constants/app_constants.dart';
import 'package:inkscroller_flutter/core/design/design_tokens.dart';
import 'package:inkscroller_flutter/core/router/app_routes.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_state.dart';

/// Shared top bar used across Home, Explore, Library and Profile.
///
/// Source of truth: Home screen top bar.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// Current auth state to render avatar consistently with Home.
  final AuthState authState;

  /// Whether the left menu icon should open drawer.
  final bool enableDrawer;

  /// Optional override for the right-side widget.
  /// When null (default), renders the user avatar / person icon navigating to /profile.
  /// Pass a custom widget (e.g. a settings icon) to override.
  final Widget? rightWidget;

  const AppTopBar({
    super.key,
    required this.authState,
    this.enableDrawer = true,
    this.rightWidget,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.voidLowest,
      toolbarHeight: 56,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            GestureDetector(
              onTap: enableDrawer ? () => Scaffold.of(context).openDrawer() : null,
              child: Icon(
                Icons.menu,
                color: enableDrawer ? AppColors.onSurface : AppColors.outline,
                size: 24,
              ),
            ),
            Text(
              AppConstants.appName,
              style: AppTypography.titleLgStyle.copyWith(color: AppColors.primary),
            ),
            rightWidget ??
            GestureDetector(
              onTap: () => context.go(AppRoutes.profile),
              child: _buildAvatar(authState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(AuthState authState) {
    if (authState.user != null) {
      final String? displayName = authState.user!.displayName;
      final String initial =
          displayName != null && displayName.isNotEmpty
          ? displayName[0].toUpperCase()
          : authState.user!.email[0].toUpperCase();

      return Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: AppColors.cardHigh,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            initial,
            style: AppTypography.labelLgStyle.copyWith(color: AppColors.primary),
          ),
        ),
      );
    }

    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: AppColors.cardHigh,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person,
        color: AppColors.onSurfaceVariant,
        size: 20,
      ),
    );
  }
}
