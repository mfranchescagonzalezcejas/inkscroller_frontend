import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design_tokens.dart';
import '../../../../core/l10n/l10n.dart';

/// Root scaffold that hosts the floating bottom navigation bar and tab pages.
///
/// Uses a [StatefulNavigationShell] to preserve each tab's scroll state when
/// switching while still allowing declarative routing.
/// Tabs: Home, Explore, Library, and Profile.
///
/// Follows inkscroller.pen (node LHiWR) specs:
/// - 358px width, 16px margins (floating)
/// - 72px height, 28px radius
/// - Glassmorphism: #111416 at 50% opacity + stronger blur
/// - Ambient shadow for separation on dark content
/// - Inactive icon/label color: onSurfaceVariant (#888D93)
class MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // 👈 para efecto flotante
      body: navigationShell,
      bottomNavigationBar: _FloatingBottomBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

class _FloatingBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingBottomBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.bottomNavMargin,
        0,
        AppSpacing.bottomNavMargin,
        bottomInset > 0 ? bottomInset : AppSpacing.md,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.bottomNavRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
          child: Container(
            height: AppSpacing.bottomNavHeight,
            decoration: BoxDecoration(
              color: AppColors.glassSurface.withValues(alpha: 0.50),
              borderRadius: BorderRadius.circular(AppSpacing.bottomNavRadius),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000), // rgba(0,0,0,0.4)
                  blurRadius: 40,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            // El espacio entre borde e ícono inicial define el padding visual,
            // y se replica entre todos los ítems con `spaceEvenly`.
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  isActive: currentIndex == 0,
                  onTap: () => onTap(0),
                  color: AppColors.primary,
                  label: l10n.navHome,
                ),
                _NavItem(
                  icon: Icons.explore_outlined,
                  activeIcon: Icons.explore,
                  isActive: currentIndex == 1,
                  onTap: () => onTap(1),
                  color: AppColors.primary,
                  label: l10n.navExplore,
                ),
                _NavItem(
                  icon: Icons.collections_bookmark_outlined,
                  activeIcon: Icons.collections_bookmark,
                  isActive: currentIndex == 2,
                  onTap: () => onTap(2),
                  color: AppColors.primary,
                  label: l10n.navLibrary,
                ),
                _NavItem(
                  icon: Icons.person_outlined,
                  activeIcon: Icons.person,
                  isActive: currentIndex == 3,
                  onTap: () => onTap(3),
                  color: AppColors.primary,
                  label: l10n.navProfile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final VoidCallback onTap;
  final Color color;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.onTap,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isActive ? activeIcon : icon,
              key: ValueKey(isActive),
              color: isActive ? color : AppColors.onSurfaceVariant,
              size: 24,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: AppTypography.label,
              fontWeight: AppTypography.labelWeight,
              color: isActive ? color : AppColors.onSurfaceVariant,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
