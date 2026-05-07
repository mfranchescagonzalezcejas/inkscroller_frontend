import 'package:flutter/material.dart';
import 'package:inkscroller_flutter/core/constants/layout.dart';
import 'package:inkscroller_flutter/core/design/design_tokens.dart';

/// Reusable tonal tab bar for catalogue and library filters.
///
/// Active tabs are communicated through tonal surface, text color, and weight —
/// not underline dividers — matching the Phase 6 component contract.
class TonalTabBar extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const TonalTabBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppLayout.tabBarHorizontalPadding,
        0,
        AppLayout.tabBarHorizontalPadding,
        AppLayout.tabBarBottomPadding,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.glassSurface,
          borderRadius: BorderRadius.circular(AppLayout.tonalTabRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppLayout.tonalTabPadding),
          child: Row(
            children: List<Widget>.generate(labels.length, (index) {
              final bool isActive = selectedIndex == index;
              return Expanded(
                child: Material(
                  color: isActive ? AppColors.cardHigh : Colors.transparent,
                  borderRadius: BorderRadius.circular(
                    AppLayout.tonalTabItemRadius,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(
                      AppLayout.tonalTabItemRadius,
                    ),
                    onTap: () => onSelected(index),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: AppLayout.tonalTabItemMinHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppLayout.tonalTabItemVerticalPadding,
                        ),
                        child: Center(
                          child: Text(
                            labels[index],
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelLgStyle.copyWith(
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : AppTypography.labelLgWeight,
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
