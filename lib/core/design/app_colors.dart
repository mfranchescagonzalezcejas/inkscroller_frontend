/// Design tokens for InkScroller — Cinematic Canvas theme.
///
/// Colors following the "Void" aesthetic: deep atmospheric teal and neutral
/// tones. No pure black (#000000) — always use Void neutrals for premium
/// ink-like depth.
///
/// References:
/// - design/DESIGN.md
/// - design/pencil/inkscroller.pen
library;

import 'package:flutter/material.dart';

/// Cinematic Canvas color roles for InkScroller.
class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════════════════════════
  // THE VOID — Surface Hierarchy
  // ═══════════════════════════════════════════════════════════════════════

  /// Level 0: The Void — Base canvas for reader
  static const Color voidLowest = Color(0xFF080F10);

  /// Level 1: The Stage — Primary background for lists and feeds
  static const Color stage = Color(0xFF0D1516);

  /// Level 2: The Card — Individual content modules
  static const Color card = Color(0xFF1A2122);

  /// Level 3: The Floating — Elements requiring highest prominence
  static const Color floating = Color(0xFF333A3C);

  // Surface variants
  static const Color cardHigh = Color(0xFF242B2C);
  static const Color cardHighest = Color(0xFF2F3637);
  static const Color surfaceHighest = Color(0xFF181B1E);

  // Light mode role translations.
  static const Color voidLight = Color(0xFFF8FBFA);
  static const Color stageLight = Color(0xFFDDEBE8);
  static const Color glassLight = Color(0xFFCFE0DC);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardHighLight = Color(0xFFC1D7D2);
  static const Color outlineLight = Color(0xFF7F918E);

  // ═══════════════════════════════════════════════════════════════════════
  // BRAND COLORS
  // ═══════════════════════════════════════════════════════════════════════

  /// Primary — Teal accent for interactive elements
  static const Color primary = Color(0xFF80D5CB);

  /// Secondary — Teal accent for badges and highlights
  static const Color secondary = Color(0xFF4DDCC6);

  /// Accent — Used sparingly for "New Chapter" badges
  static const Color accent = Color(0xFF5EEAD4);

  /// Danger — Destructive actions and unrecoverable error states.
  static const Color danger = Color(0xFFFF5A6A);

  /// Primary translation for light-mode action/selection states.
  static const Color primaryLight = Color(0xFF2FAFA3);

  /// Gold — Star ratings and score badges
  static const Color scoreGold = Color(0xFFFFC107);

  /// Pressed/active depth token for light mode.
  static const Color primaryDeepLight = Color(0xFF0F766E);

  /// Destructive action token for light mode.
  static const Color dangerLight = Color(0xFFD94A5B);

  // ═══════════════════════════════════════════════════════════════════════
  // TEXT COLORS
  // ═══════════════════════════════════════════════════════════════════════

  /// Primary text — Chapter titles, headers
  static const Color onSurface = Color(0xFFE2E4E6);

  /// Secondary text — Author names, metadata
  static const Color onSurfaceVariant = Color(0xFF888D93);

  /// Muted text — Timestamps, tertiary info
  static const Color outline = Color(0xFF4A4F55);

  /// Primary readable text on light surfaces.
  static const Color onSurfaceLight = Color(0xFF061314);

  /// Muted readable text on light surfaces.
  static const Color onSurfaceVariantLight = Color(0xFF5B6769);

  // Outline variants (for borders)
  static const Color outlineVariant = Color(0xFF3E4947);

  // ═══════════════════════════════════════════════════════════════════════
  // BRAND GRADIENT — Reserved for Logo and "Start Reading" CTA only
  // ═══════════════════════════════════════════════════════════════════════

  /// Signature gradient: linear-gradient(135deg, #0F766E, #1E40AF)
  static const List<Color> brandGradient = [
    Color(0xFF0F766E),
    Color(0xFF1E40AF),
  ];

  // ═══════════════════════════════════════════════════════════════════════
  // GLASSMORPHISM — For floating elements
  // ═══════════════════════════════════════════════════════════════════════

  /// Floating surface: surface (#111416) at 75% opacity
  static const Color glassSurface = Color(0xFF111416);

  /// Glass opacity for backdrop blur effect
  static const double glassOpacity = 0.75;
}
