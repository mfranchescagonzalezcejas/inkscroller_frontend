/// Layout dimension constants shared across features.
///
/// Used by [CoverImage] to compute responsive cover dimensions.
class AppLayout {
  // Bottom navigation bar
  static const double bottomBarHeight = 64;
  static const double bottomBarSpacing = 24;

  // Cover image sizing (base reference at ~375px mobile viewport)
  static const double baseViewportWidth = 375;
  static const double smallCoverWidth = 50;
  static const double smallCoverHeight = 70;
  static const double coverBorderRadius = 4;
}
