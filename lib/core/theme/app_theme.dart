import 'package:flutter/material.dart';

import '../constants/layout.dart';
import '../design/design_tokens.dart';

/// Configures Material 3 light and dark themes for InkScroller.
///
/// Exposes [light] and [dark] factory methods with the Cinematic Canvas token
/// roles and consistent Material control sizing.
class AppTheme {
  // Brand and semantic colors.
  static const _darkPrimary = AppColors.primary;
  static const _lightPrimary = AppColors.primaryLight;
  static const _tealSecondary = AppColors.secondary;
  static const _score = AppColors.scoreGold;
  static const _brandGradientStart = AppColors.brandGradientStart;
  static const _brandGradientEnd = AppColors.brandGradientEnd;
  static const _darkError = AppColors.danger;
  static const _lightError = AppColors.dangerLight;
  static const _onAction = AppColors.voidLowest;

  // Dark colors
  static const _darkBg = AppColors.stage;
  static const _darkGlass = AppColors.glassSurface;
  static const _darkSurface = AppColors.card;
  static const _darkSurfaceHigh = AppColors.cardHigh;
  static const _darkDivider = AppColors.outlineVariant;
  static const _darkOutline = AppColors.outlineDark;
  static const _darkText = AppColors.onSurface;
  static const _darkTextSecondary = AppColors.onSurfaceVariant;

  // Light colors
  static const _lightBg = AppColors.stageLight;
  static const _lightGlass = AppColors.glassLight;
  static const _lightSurface = AppColors.cardLight;
  static const _lightSurfaceHigh = AppColors.cardHighLight;
  static const _lightDivider = AppColors.outlineLight;
  static const _lightText = AppColors.onSurfaceLight;
  static const _lightTextSecondary = AppColors.onSurfaceVariantLight;

  static const _minimumControlSize = Size(
    AppLayout.minTouchTarget,
    AppLayout.minTouchTarget,
  );

  // Shared text theme — derives from AppTypography named roles.
  static TextTheme _buildTextTheme(Color? bodyColor) => TextTheme(
    titleLarge: AppTypography.titleLgStyle.copyWith(color: _lightText),
    titleMedium: AppTypography.titleMdStyle,
    bodyLarge: AppTypography.bodyLgStyle,
    bodyMedium: AppTypography.bodyStyle.copyWith(color: bodyColor),
    labelLarge: AppTypography.labelLgStyle,
  );

  // Shared button theme
  static ButtonStyle _buttonStyle() => ButtonStyle(
    minimumSize: WidgetStateProperty.all(_minimumControlSize),
    tapTargetSize: MaterialTapTargetSize.padded,
  );

  // ☀️ LIGHT
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lightBg,
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: const Color(0xFF4FC3F7).withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      colorScheme: const ColorScheme.light(
        primary: _lightPrimary,
        onPrimary: _onAction,
        secondary: _tealSecondary,
        tertiary: _score,
        primaryContainer: _brandGradientStart,
        secondaryContainer: _brandGradientEnd,
        error: _lightError,
        onError: _onAction,
        onSurface: _lightText,
        onSurfaceVariant: _lightTextSecondary,
        surfaceContainerLowest: _lightBg,
        surfaceContainerLow: _lightGlass,
        surfaceContainer: _lightSurface,
        surfaceContainerHigh: _lightSurfaceHigh,
        surfaceContainerHighest: _lightSurfaceHigh,
        outlineVariant: _lightDivider,
        outline: _lightDivider,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: _lightBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: _lightText,
        ),
        iconTheme: IconThemeData(color: _lightText),
      ),

      cardTheme: CardThemeData(
        color: _lightSurface,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppLayout.cardRadius),
        ),
      ),

      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: _lightPrimary,
        textColor: _lightText,
      ),

      textTheme: _buildTextTheme(_lightTextSecondary),

      dividerTheme: const DividerThemeData(color: _lightDivider, thickness: 1),

      iconTheme: const IconThemeData(color: _lightPrimary),

      iconButtonTheme: IconButtonThemeData(style: _buttonStyle()),
      textButtonTheme: TextButtonThemeData(style: _buttonStyle()),
      elevatedButtonTheme: ElevatedButtonThemeData(style: _buttonStyle()),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: _lightSurface,
        contentTextStyle: const TextStyle(color: _lightText),
        actionTextColor: _lightPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: _lightSurface,
        titleTextStyle: AppTypography.titleMdStyle.copyWith(color: _lightText),
        contentTextStyle: AppTypography.bodyStyle.copyWith(
          color: _lightTextSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppLayout.cardRadius),
        ),
      ),
    );
  }

  // 🌙 DARK
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkBg,
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: const Color(0xFF4FC3F7).withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      colorScheme: const ColorScheme.dark(
        primary: _darkPrimary,
        onPrimary: _onAction,
        secondary: _tealSecondary,
        tertiary: _score,
        primaryContainer: _brandGradientStart,
        secondaryContainer: _brandGradientEnd,
        error: _darkError,
        onError: _onAction,
        surface: _darkSurface,
        onSurface: _darkText,
        onSurfaceVariant: _darkTextSecondary,
        surfaceContainerLowest: _darkBg,
        surfaceContainerLow: _darkGlass,
        surfaceContainer: _darkSurface,
        surfaceContainerHigh: _darkSurfaceHigh,
        surfaceContainerHighest: _darkSurfaceHigh,
        outlineVariant: _darkDivider,
        outline: _darkOutline,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: _darkBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),

      cardTheme: CardThemeData(
        color: _darkSurface,
        elevation: 4,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppLayout.cardRadius),
        ),
      ),

      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: _darkPrimary,
        textColor: _darkText,
      ),

      textTheme: _buildTextTheme(_darkTextSecondary),

      dividerTheme: const DividerThemeData(color: _darkDivider, thickness: 1),

      iconTheme: const IconThemeData(color: _darkPrimary),

      iconButtonTheme: IconButtonThemeData(style: _buttonStyle()),
      textButtonTheme: TextButtonThemeData(style: _buttonStyle()),
      elevatedButtonTheme: ElevatedButtonThemeData(style: _buttonStyle()),
    );
  }
}
