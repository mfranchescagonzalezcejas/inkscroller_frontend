/// Layout dimension constants shared across features.
///
/// Used by [CoverImage] to compute responsive cover dimensions.
class AppLayout {
  AppLayout._();

  // Platform comfort and accessibility
  static const double androidMinTouchTarget = 48;
  static const double iosMinTouchTarget = 44;
  static const double minTouchTarget = androidMinTouchTarget;

  // Bottom navigation bar
  static const double bottomBarHeight = 64;
  static const double bottomBarSpacing = 24;
  static const double bottomBarItemMinWidth = minTouchTarget;
  static const double bottomBarItemMinHeight = minTouchTarget;

  // Cover image sizing (base reference at ~375px mobile viewport)
  static const double baseViewportWidth = 375;
  static const double smallCoverWidth = 50;
  static const double smallCoverHeight = 70;
  static const double coverBorderRadius = 4;

  // Component library contracts
  static const double tabBarHorizontalPadding = 20;
  static const double tabBarBottomPadding = 16;
  static const double tonalTabPadding = 6;
  static const double tonalTabRadius = 14;
  static const double tonalTabItemRadius = 18;
  static const double tonalTabItemVerticalPadding = 10;
  static const double tonalTabItemMinHeight = minTouchTarget;
  static const double settingsSectionCardRadius = 20;
  static const double settingsSectionCardHorizontalPadding = 12;
  static const double settingsSectionCardVerticalPadding = 16;
  static const double authFieldRadius = 16;
  static const double authButtonRadius = 14;
  static const double authButtonMinHeight = minTouchTarget;
  static const double infoListIconSize = 38;
  static const double infoListIconGlyphSize = 20;
  static const double infoListIconRadius = 13;
  static const double infoListRowGap = 12;
  static const double infoListRowMinHeight = 56;
  static const double infoListRowCopyGap = 3;
}
