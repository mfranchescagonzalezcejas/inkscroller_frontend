/// App-wide numeric and string constants used across layers.
///
/// Centralizes network timeouts, pagination limits, reader zoom bounds,
/// and cache TTL values to avoid magic numbers scattered through the codebase.
class AppConstants {
  // App
  static const String appName = 'InkScroller';

  // Network
  static const int connectTimeoutSeconds = 15;
  static const int receiveTimeoutSeconds = 15;

  // MangaDex
  static const int mangaPageLimit = 20;
  static const String defaultLanguage = 'en';
  static const String appLocalePreferenceKey = 'app.ui_locale';

  // Home carousels
  static const int homeCarouselItemLimit = 20;

  // Reader
  static const double defaultZoom = 1;
  static const double minZoom = 0.8;
  static const double maxZoom = 3;

  // Cache
  static const int imageCacheDays = 7;
  static const int mangaListCacheTtlMinutes = 10;
  static const int mangaDetailCacheTtlMinutes = 30;
  static const int mangaChaptersCacheTtlMinutes = 15;

  // Pagination
  static const int firstPageOffset = 0;
  static const int mangaListPrefetchExtent = 600;
}
