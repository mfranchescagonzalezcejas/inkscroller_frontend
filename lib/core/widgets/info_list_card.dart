import 'package:flutter/material.dart';
import 'package:inkscroller_flutter/core/constants/layout.dart';
import 'package:inkscroller_flutter/core/design/design_tokens.dart';

/// Reusable section card for settings/profile information groups.
///
/// Uses spacing-led rows without hard dividers, following Phase 6 guidance.
class SettingsSectionCard extends StatelessWidget {
  final List<Widget> children;

  const SettingsSectionCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(
          AppLayout.settingsSectionCardRadius,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppLayout.settingsSectionCardHorizontalPadding,
          vertical: AppLayout.settingsSectionCardVerticalPadding,
        ),
        child: Column(children: children),
      ),
    );
  }
}

/// Reusable info-list card for read-only label/value metadata.
class InfoListCard extends SettingsSectionCard {
  const InfoListCard({super.key, required super.children});
}

/// Spacing-led row for [InfoListCard] and [SettingsSectionCard].
class InfoListRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const InfoListRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: AppLayout.infoListRowMinHeight,
      ),
      child: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            SizedBox(
              width: AppLayout.infoListIconSize,
              height: AppLayout.infoListIconSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.cardHigh,
                  borderRadius: BorderRadius.circular(
                    AppLayout.infoListIconRadius,
                  ),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: AppLayout.infoListIconGlyphSize,
                ),
              ),
            ),
            const SizedBox(width: AppLayout.infoListRowGap),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLgStyle.copyWith(
                    fontSize: 13,
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppLayout.infoListRowCopyGap),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelStyle.copyWith(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
