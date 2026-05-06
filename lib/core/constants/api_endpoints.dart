/// URL path constants for the InkScroller backend API.
///
/// Used by data source implementations to build Dio request URLs relative to
/// the configured [ApiConfig.baseUrl].
class ApiEndpoints {
  // ── Library ───────────────────────────────────────────────────────────────
  static const manga = '/manga';
  static const chaptersByManga = '/chapters/manga';
  static const chapterPages = '/chapters';
  static const latestChapters = '/chapters/latest';

  // ── User / Auth (Phase 5) ─────────────────────────────────────────────────
  static const usersMe = '/users/me';
  static const usersMePreferences = '/users/me/preferences';
  static const usersMeLibrary = '/users/me/library';
}
