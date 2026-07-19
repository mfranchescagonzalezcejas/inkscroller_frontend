/// Dimension constants for the [HomePage] carousels and horizontal rows.
///
/// Groups all magic numbers that govern card sizes and row heights for the
/// home screen.
class HomeLayout {
  // Hero carousel
  /// Height of the featured hero carousel.
  static const double heroCarouselHeight = 460;

  // Manga card dimensions
  /// Height of a horizontal manga card row.
  static const double mangaCardRowHeight = 220;

  /// Width of a single manga card tile.
  static const double mangaCardWidth = 130;

  /// Row height for the Discover manga row — matches how MangaTile
  /// naturally sizes in Explore's MasonryGridView.
  static const double discoverRowHeight = 240;

  // Continue Reading card dimensions
  /// Width of a Continue Reading card tile.
  static const double continueReadingCardWidth = 120;

  /// Height of a Continue Reading card tile.
  static const double continueReadingCardHeight = 180;
}
