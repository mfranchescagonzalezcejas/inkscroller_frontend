import 'package:flutter/material.dart';

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
  static const _tealAccent = AppColors.primaryDeepLight;

  // 🌙 Dark colors
  static const _darkBg = AppColors.stage;
  static const _darkSurface = AppColors.card;
  static const _darkDivider = AppColors.outlineVariant;
  static const _darkText = AppColors.onSurface;
  static const _darkTextSecondary = AppColors.onSurfaceVariant;

  // ☀️ Light colors
  static const _lightBg = AppColors.stageLight;
  static const _lightSurface = AppColors.cardLight;
  static const _lightDivider = AppColors.outlineLight;
  static const _lightText = AppColors.onSurfaceLight;
  static const _lightTextSecondary = AppColors.onSurfaceVariantLight;

  static const _minimumControlSize = Size(
    AppSpacing.minTouchTarget,
    AppSpacing.minTouchTarget,
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
        secondary: _tealSecondary,
        tertiary: _tealAccent,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: _lightPrimary,
        textColor: _lightText,
      ),

      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 16),
        bodyMedium: TextStyle(fontSize: 14, color: _lightTextSecondary),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),

      dividerTheme: const DividerThemeData(color: _lightDivider, thickness: 1),

      iconTheme: const IconThemeData(color: _lightPrimary),

      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(_minimumControlSize),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(_minimumControlSize),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(_minimumControlSize),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: _darkSurface,
        contentTextStyle: const TextStyle(color: _darkText),
        actionTextColor: _lightPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: _darkSurface,
        titleTextStyle: const TextStyle(
          color: _darkText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: _darkTextSecondary,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        secondary: _tealSecondary,
        tertiary: _tealAccent,
        surface: _darkSurface,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: _darkPrimary,
        textColor: _darkText,
      ),

      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 16),
        bodyMedium: TextStyle(fontSize: 14, color: _darkTextSecondary),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),

      dividerTheme: const DividerThemeData(color: _darkDivider, thickness: 1),

      iconTheme: const IconThemeData(color: _darkPrimary),

      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(_minimumControlSize),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(_minimumControlSize),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(_minimumControlSize),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
    );
  }
}
