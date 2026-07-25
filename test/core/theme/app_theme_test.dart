import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/design/app_colors.dart';
import 'package:inkscroller_flutter/core/theme/app_theme.dart';

void main() {
  test('light theme maps Material surface roles to light design tokens', () {
    final ThemeData theme = AppTheme.light();
    final ColorScheme colors = theme.colorScheme;

    expect(theme.scaffoldBackgroundColor, AppColors.stageLight);
    expect(colors.surface, AppColors.cardLight);
    expect(colors.surfaceContainerLowest, AppColors.stageLight);
    expect(colors.surfaceContainerLow, AppColors.glassLight);
    expect(colors.surfaceContainer, AppColors.cardLight);
    expect(colors.surfaceContainerHigh, AppColors.cardHighLight);
    expect(colors.surfaceContainerHighest, AppColors.cardHighLight);
    expect(colors.outlineVariant, AppColors.outlineLight);
    expect(colors.onSurface, AppColors.onSurfaceLight);
    expect(colors.onSurfaceVariant, AppColors.onSurfaceVariantLight);
    expect(colors.onPrimary, AppColors.voidLowest);
    expect(colors.error, AppColors.dangerLight);
    expect(colors.onError, AppColors.voidLowest);
    expect(colors.outline, AppColors.outlineLight);
    expect(colors.tertiary, AppColors.scoreGold);
    expect(colors.primaryContainer, AppColors.brandGradientStart);
    expect(colors.secondaryContainer, AppColors.brandGradientEnd);
  });

  test('dark theme maps Material surface roles to dark design tokens', () {
    final ThemeData theme = AppTheme.dark();
    final ColorScheme colors = theme.colorScheme;

    expect(theme.scaffoldBackgroundColor, AppColors.stage);
    expect(colors.surface, AppColors.card);
    expect(colors.surfaceContainerLowest, AppColors.stage);
    expect(colors.surfaceContainerLow, AppColors.glassSurface);
    expect(colors.surfaceContainer, AppColors.card);
    expect(colors.surfaceContainerHigh, AppColors.cardHigh);
    expect(colors.surfaceContainerHighest, AppColors.cardHigh);
    expect(colors.outlineVariant, AppColors.outlineVariant);
    expect(colors.onSurface, AppColors.onSurface);
    expect(colors.onSurfaceVariant, AppColors.onSurfaceVariant);
    expect(colors.onPrimary, AppColors.voidLowest);
    expect(colors.error, AppColors.danger);
    expect(colors.onError, AppColors.voidLowest);
    expect(colors.outline, AppColors.outlineDark);
    expect(colors.tertiary, AppColors.scoreGold);
    expect(colors.primaryContainer, AppColors.brandGradientStart);
    expect(colors.secondaryContainer, AppColors.brandGradientEnd);
  });

  test('runtime color migration paths do not access AppColors directly', () {
    const runtimePaths = <String>[
      'lib/flutter_app.dart',
      'lib/core/widgets/app_top_bar.dart',
      'lib/core/feedback/app_feedback.dart',
      'lib/core/widgets/inkscroller_shimmer.dart',
      'lib/features/auth/presentation/pages/login_page.dart',
      'lib/features/auth/presentation/pages/register_page.dart',
      'lib/features/auth/presentation/pages/verify_email_page.dart',
      'lib/features/auth/presentation/widgets/auth_form_widgets.dart',
      'lib/features/home/presentation/widgets/hero_carousel.dart',
      'lib/features/home/presentation/widgets/home_recommended_section.dart',
      'lib/features/library/presentation/widgets/manga_tile.dart',
      'lib/features/library/presentation/widgets/reader_settings_sheet.dart',
      'lib/features/profile/presentation/pages/profile_page.dart',
    ];

    for (final path in runtimePaths) {
      expect(File(path).readAsStringSync(), isNot(contains('AppColors.')),
          reason: '$path must use Theme.of(context).colorScheme');
    }
  });
}
