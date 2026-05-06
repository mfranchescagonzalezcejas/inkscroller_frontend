/// Design tokens for InkScroller — Spacing scale.
///
/// Uses a consistent spacing system based on DESIGN.md tokens.
/// No 1px borders — boundaries defined by surface shifts and negative space.
class AppSpacing {
  AppSpacing._();

  // ═══════════════════════════════════════════════════════════════════════
  // SPACING SCALE
  // ═══════════════════════════════════════════════════════════════════════

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double section = 40;

  // ═══════════════════════════════════════════════════════════════════════
  // LAYOUT CONSTRAINTS
  // ═══════════════════════════════════════════════════════════════════════

  /// Maximum content width for readable content
  static const double maxContentWidth = 390;

  /// Screen width reference (iPhone 14 Pro)
  static const double screenWidth = 390;

  /// Screen height reference (iPhone 14 Pro)
  static const double screenHeight = 844;

  // ═══════════════════════════════════════════════════════════════════════
  // BOTTOM NAV SPECS
  // ═══════════════════════════════════════════════════════════════════════

  /// Floating bottom nav specs — cornerRadius per inkscroller.pen (node LHiWR).
  /// NOTE: The .pen file (cornerRadius: 28) is the source of truth.
  /// DESIGN.md text says "20px" but the rendered design uses 28px.
  static const double bottomNavHeight = 72;
  static const double bottomNavWidth = 358;
  static const double bottomNavMargin = 16;
  static const double bottomNavRadius = 28;

  // ═══════════════════════════════════════════════════════════════════════
  // CARD SPECS
  // ═══════════════════════════════════════════════════════════════════════

  /// Card corner radius (radius-lg)
  static const double cardRadius = 16;

  /// Button corner radius (radius-md)
  static const double buttonRadius = 12;

  /// Card padding
  static const double cardPadding = 16;
}
