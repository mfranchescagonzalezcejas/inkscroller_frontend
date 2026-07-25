/// Layout dimension constants shared across features.
///
/// Component-specific named dimensions. Pure spacing scale lives in [AppSpacing].
class AppLayout {
  AppLayout._();

  // ═══════════════════════════════════════════════════════════════════════
  // PLATFORM COMFORT
  // ═══════════════════════════════════════════════════════════════════════

  /// Minimum Android touch target from Material guidance.
  static const double minTouchTarget = 48;

  /// Minimum iOS touch target from Apple Human Interface Guidelines.
  static const double iosMinTouchTarget = 44;

  // ═══════════════════════════════════════════════════════════════════════
  // VIEWPORT
  // ═══════════════════════════════════════════════════════════════════════

  /// Maximum content width for readable content
  static const double maxContentWidth = 390;

  /// Screen width reference (iPhone 14 Pro)
  static const double screenWidth = 390;

  /// Screen height reference (iPhone 14 Pro)
  static const double screenHeight = 844;

  /// Base viewport width for responsive cover scaling
  static const double baseViewportWidth = 375;

  // ═══════════════════════════════════════════════════════════════════════
  // FLOATING BOTTOM NAV
  // ═══════════════════════════════════════════════════════════════════════

  /// Floating bottom nav specs — cornerRadius per inkscroller.pen (node LHiWR).
  static const double bottomNavHeight = 72;
  static const double bottomNavWidth = 358;
  static const double bottomNavMargin = 16;
  static const double bottomNavRadius = 28;

  /// Bottom nav item touch targets
  static const double bottomBarItemMinWidth = minTouchTarget;
  static const double bottomBarItemMinHeight = minTouchTarget;

  // ═══════════════════════════════════════════════════════════════════════
  // CARDS & BUTTONS
  // ═══════════════════════════════════════════════════════════════════════

  /// Card corner radius (radius-lg)
  static const double cardRadius = 16;

  /// Button corner radius (radius-md)
  static const double buttonRadius = 12;

  /// Card padding
  static const double cardPadding = 16;

  // ═══════════════════════════════════════════════════════════════════════
  // COVER IMAGE
  // ═══════════════════════════════════════════════════════════════════════

  static const double smallCoverWidth = 50;
  static const double smallCoverHeight = 70;
  static const double coverBorderRadius = 4;

  // ═══════════════════════════════════════════════════════════════════════
  // TAB BAR
  // ═══════════════════════════════════════════════════════════════════════

  static const double tabBarHorizontalPadding = 20;
  static const double tabBarBottomPadding = 16;
  static const double tonalTabPadding = 6;
  static const double tonalTabRadius = 14;
  static const double tonalTabItemRadius = tonalTabRadius - tonalTabPadding;
  static const double tonalTabItemVerticalPadding = 10;
  static const double tonalTabItemMinHeight = minTouchTarget;

  /// Fill opacity for the active tonal tab indicator.
  static const double tonalTabActiveFillOpacity = 0.16;

  // ═══════════════════════════════════════════════════════════════════════
  // SETTINGS
  // ═══════════════════════════════════════════════════════════════════════

  static const double settingsSectionCardRadius = 20;
  static const double settingsSectionCardHorizontalPadding = 12;
  static const double settingsSectionCardVerticalPadding = 16;

  // ═══════════════════════════════════════════════════════════════════════
  // AUTH
  // ═══════════════════════════════════════════════════════════════════════

  static const double authFieldRadius = 16;
  static const double authButtonRadius = 14;
  static const double authButtonMinHeight = minTouchTarget;

  // ═══════════════════════════════════════════════════════════════════════
  // INFO LIST
  // ═══════════════════════════════════════════════════════════════════════

  static const double infoListIconSize = 38;
  static const double infoListIconGlyphSize = 20;
  static const double infoListIconRadius = 13;
  static const double infoListRowGap = 12;
  static const double infoListRowMinHeight = 56;
  static const double infoListRowCopyGap = 3;

  // ═══════════════════════════════════════════════════════════════════════
  // MANGA DETAIL
  // ═══════════════════════════════════════════════════════════════════════

  static const double mangaDetailHorizontalPadding = 20;
  static const double mangaDetailDescriptionHeight = 120;
  static const double mangaDetailBadgeHorizontalPadding = 10;
  static const double mangaDetailBadgeRadius = 20;
  static const double mangaDetailBadgeIndicatorSize = 6;

  // ═══════════════════════════════════════════════════════════════════════
  // READER
  // ═══════════════════════════════════════════════════════════════════════

  static const double readerFloatingControlSize = 40;
  static const double readerFloatingControlRadius = 12;
  static const double readerFloatingControlBackgroundOpacity = 0.6;
}
