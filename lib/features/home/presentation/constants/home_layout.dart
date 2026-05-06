/// Dimension constants for the [HomePage] carousels and segmented tab control.
///
/// Groups all magic numbers that govern card sizes, row heights, border radii,
/// animation duration, and typography for the home screen.
class HomeLayout {
  // Manga card dimensions
  /// Height of a horizontal manga card row.
  static const double mangaCardRowHeight = 220;

  /// Width of a single manga card tile.
  static const double mangaCardWidth = 130;

  // Segmented control
  /// Total height of the segmented tab bar container.
  static const double segmentedBarHeight = 56;

  /// Outer border radius of the segmented bar pill container.
  static const double segmentedBarRadius = 28;

  /// Inner border radius of the selected tab pill.
  static const double segmentedTabRadius = 22;

  /// Padding inside the segmented bar container.
  static const double segmentedBarPadding = 6;

  // Shadow
  /// Blur radius for the segmented bar drop shadow.
  static const double segmentedShadowBlur = 16;

  /// Vertical offset of the segmented bar drop shadow.
  static const double segmentedShadowOffsetY = 8;

  // Tab content
  /// Height of the demographic TabBarView content area.
  static const double demographicTabViewHeight = 280;

  /// Number of demographic tabs.
  static const int demographicTabCount = 4;

  // Typography
  /// Font size for tab labels in the segmented control.
  static const double segmentedTabFontSize = 13.5;

  /// Letter spacing for tab labels.
  static const double segmentedTabLetterSpacing = 0.2;

  // Animation
  /// Duration in milliseconds for the segmented tab selection animation.
  static const int segmentedAnimationMs = 250;

  // Opacity
  /// Surface alpha for segmented bar in dark mode.
  static const double segmentedSurfaceAlphaDark = 0.7;

  /// Surface alpha for segmented bar in light mode.
  static const double segmentedSurfaceAlphaLight = 0.9;

  /// Shadow alpha for segmented bar in dark mode.
  static const double segmentedShadowAlphaDark = 0.25;

  /// Shadow alpha for segmented bar in light mode.
  static const double segmentedShadowAlphaLight = 0.08;

  /// Fill alpha for the selected segmented tab.
  static const double segmentedSelectedAlpha = 0.85;

  /// Border alpha for the selected segmented tab.
  static const double segmentedSelectedBorderAlpha = 0.15;

  /// Text alpha for unselected segmented tabs.
  static const double segmentedUnselectedTextAlpha = 0.55;
}
