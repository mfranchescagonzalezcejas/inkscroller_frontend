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

  // ═══════════════════════════════════════════════════════════════════════
  // BRAND COLORS
  // ═══════════════════════════════════════════════════════════════════════

  /// Primary — Teal accent for interactive elements
  static const Color primary = Color(0xFF80D5CB);

  /// Secondary — Teal accent for badges and highlights
  static const Color secondary = Color(0xFF4DDCC6);

  /// Accent — Used sparingly for "New Chapter" badges
  static const Color accent = Color(0xFF5EEAD4);

  // ═══════════════════════════════════════════════════════════════════════
  // TEXT COLORS
  // ═══════════════════════════════════════════════════════════════════════

  /// Primary text — Chapter titles, headers
  static const Color onSurface = Color(0xFFE2E4E6);

  /// Secondary text — Author names, metadata
  static const Color onSurfaceVariant = Color(0xFF888D93);

  /// Muted text — Timestamps, tertiary info
  static const Color outline = Color(0xFF4A4F55);

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
