import 'package:flutter/material.dart';

/// Configures Material 3 light and dark themes for InkScroller.
///
/// Exposes [light] and [dark] factory methods with the brand colour palette
/// (blue primary `#5DA9E9`, teal secondary `#4DB6AC`) and consistent text styles.
class AppTheme {
// 🔵 Brand colors (más calmados)
  static const _bluePrimary   = Color(0xFF5DA9E9); // azul más profundo
  static const _tealSecondary = Color(0xFF4DB6AC);
  static const _tealAccent    = Color(0xFF26A69A);


  // 🌙 Dark colors
  static const _darkBg = Color(0xFF0B1220);
  static const _darkSurface = Color(0xFF111A2E);
  static const _darkDivider = Color(0xFF1F2A44);
  static const _darkText = Color(0xFFE2E4E6);
  static const _darkTextSecondary = Color(0xFFAAB4C8);

  // ☀️ Light colors
  static const _lightBg = Color(0xFFF5F7FB);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightDivider = Color(0xFFDCE3F1);
  static const _lightTextSecondary = Color(0xFF5C6B85);

  // ☀️ LIGHT
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lightBg,
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: const Color(0xFF4FC3F7).withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      colorScheme: const ColorScheme.light(
        primary: _bluePrimary,
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
          color: Colors.black,
        ),
        iconTheme: IconThemeData(color: Colors.black87),
      ),

      cardTheme: CardThemeData(
        color: _lightSurface,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: _bluePrimary,
        textColor: Colors.black87,
      ),

      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 16),
        bodyMedium: TextStyle(fontSize: 14, color: _lightTextSecondary),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),

      dividerTheme: const DividerThemeData(color: _lightDivider, thickness: 1),

      iconTheme: const IconThemeData(color: _bluePrimary),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: _darkSurface,
        contentTextStyle: const TextStyle(color: _darkText),
        actionTextColor: _bluePrimary,
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
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkBg,
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: const Color(0xFF4FC3F7).withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      colorScheme: const ColorScheme.dark(
        primary: _bluePrimary,
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
        iconColor: _bluePrimary,
        textColor: Colors.white,
      ),

      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 16),
        bodyMedium: TextStyle(fontSize: 14, color: _darkTextSecondary),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),

      dividerTheme: const DividerThemeData(color: _darkDivider, thickness: 1),

      iconTheme: const IconThemeData(color: _bluePrimary),
    );
  }
}
