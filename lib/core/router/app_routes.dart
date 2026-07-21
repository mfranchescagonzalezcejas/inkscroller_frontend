/// Centralized route paths and route-name constants.
abstract final class AppRoutes {
  static const String home = '/';
  static const String explore = '/explore';
  static const String library = '/library';
  static const String profile = '/profile';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyEmail = '/verify-email';
  static const String settings = '/settings';
  static const String about = '/about';

  static const String mangaDetailPattern = '/manga/:mangaId';
  static const String readerPattern = '/manga/:mangaId/chapter/:chapterId';

  static String mangaDetailPath(String mangaId) => '/manga/$mangaId';

  static String readerPath({required String mangaId, required String chapterId}) =>
      '/manga/$mangaId/chapter/$chapterId';
}
