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
    expect(colors.onPrimary, AppColors.onSurfaceLight);
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
  });
}
