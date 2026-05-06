// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get offlineBannerMessage =>
      'Offline. Showing cached data when available.';

  @override
  String get searchMangaHint => 'Search manga…';

  @override
  String get clearAction => 'Clear';

  @override
  String get noMangasAvailable => 'No manga available';

  @override
  String noSearchResults(Object query) {
    return 'No results for \"$query\"';
  }

  @override
  String get noMoreMangaToLoad => 'No more manga to load';

  @override
  String get failedToLoadChapters => 'Could not load chapters';

  @override
  String get retryAction => 'Retry';

  @override
  String get noChaptersAvailable => 'No chapters available';

  @override
  String get chaptersTitle => 'Chapters';

  @override
  String get routeInvalidTitle => 'Invalid route';

  @override
  String get routeMissingMangaMessage =>
      'Missing manga data to open the detail page.';

  @override
  String get routeMissingChapterMessage =>
      'Could not find the requested chapter.';

  @override
  String get routeNotFoundTitle => 'Page not found';

  @override
  String get routeNotFoundMessage => 'The requested route does not exist.';

  @override
  String get backToHomeAction => 'Back to home';

  @override
  String get settingsComingSoon => 'Coming soon 👀';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppSectionTitle => 'App';

  @override
  String get settingsAppNameLabel => 'App name';

  @override
  String get settingsFlavorLabel => 'Flavor';

  @override
  String get settingsApiBaseUrlLabel => 'API base URL';

  @override
  String get settingsCacheSectionTitle => 'Cache';

  @override
  String get settingsMangaListCacheLabel => 'Manga list cache';

  @override
  String get settingsMangaDetailCacheLabel => 'Manga detail cache';

  @override
  String get settingsMangaChaptersCacheLabel => 'Chapter list cache';

  @override
  String settingsCacheMinutesValue(int minutes) {
    return '$minutes min';
  }

  @override
  String get settingsClearCacheAction => 'Clear cached data';

  @override
  String get settingsCacheClearedMessage => 'Cached data cleared';

  @override
  String get settingsCacheClearFailedMessage => 'Could not clear cached data';

  @override
  String get loadingChapter => 'Loading chapter';

  @override
  String chapterPagesProgress(int loadedPages, int totalPages) {
    return '$loadedPages / $totalPages pages';
  }

  @override
  String get readingChapter => 'Reading chapter';

  @override
  String chapterLabel(Object number) {
    return 'Chapter $number';
  }

  @override
  String get extraLabel => 'Extra';

  @override
  String get homeFeatured => '🔥 Featured';

  @override
  String get homeLatest => '🆕 Latest';

  @override
  String get homePopular => '🔥 Popular';

  @override
  String get homeDemographic => '📚 Demographics';

  @override
  String get homeNoMangas => 'No manga available';

  @override
  String get demographicShounen => 'Shounen';

  @override
  String get demographicShoujo => 'Shoujo';

  @override
  String get demographicSeinen => 'Seinen';

  @override
  String get demographicJosei => 'Josei';

  @override
  String get readNow => 'Read Now';

  @override
  String get addToLibrary => 'Add to Library';

  @override
  String get removeFromLibrary => 'Remove from Library';

  @override
  String libraryItemAdded(Object title) {
    return '$title added to your library';
  }

  @override
  String libraryItemRemoved(Object title) {
    return '$title removed from your library';
  }

  @override
  String get genreAll => 'All';

  @override
  String get genrePopular => 'Popular';

  @override
  String get genreRomance => 'Romance';

  @override
  String get genreAction => 'Action';

  @override
  String get libraryTitle => 'My Library';

  @override
  String libraryCollectionsCount(int count) {
    return '$count collections';
  }

  @override
  String get libraryTabAll => 'All';

  @override
  String get libraryTabReading => 'Reading';

  @override
  String get libraryTabCompleted => 'Completed';

  @override
  String get libraryTabOnHold => 'On Hold';

  @override
  String get libraryEmpty =>
      'Your library is empty. Add manga from Home or Manga Detail.';

  @override
  String get libraryEmptyTab => 'No manga in this tab yet.';

  @override
  String get libraryStatusReading => 'Mark as Reading';

  @override
  String get libraryStatusCompleted => 'Mark as Completed';

  @override
  String get libraryStatusPaused => 'Mark as Paused';

  @override
  String get libraryStatusUpdated => 'Library status updated';

  @override
  String get libraryUnknownMeta => 'Unknown';

  @override
  String libraryProgressValue(int readCount, int totalCount) {
    return '$readCount / $totalCount read';
  }

  @override
  String get exploreTitle => 'Explore';

  @override
  String get exploreSubtitle => 'Discover your next story';

  @override
  String get externalChapterTitle => 'External chapter';

  @override
  String get externalChapterMessage =>
      'This chapter is only available on the original site. It cannot be read inside InkScroller.';

  @override
  String get externalChapterOpenAction => 'Open on original site';

  @override
  String get externalChapterGoBackAction => 'Go back';

  @override
  String get readingProgressDialogTitle => 'Update reading progress';

  @override
  String readingProgressDialogMessage(int count, Object chapterLabel) {
    return 'This will mark $count chapters up to $chapterLabel as read.';
  }

  @override
  String readingProgressDialogExternalMessage(int count, Object chapterLabel) {
    return 'This chapter opens outside InkScroller. Do you want to mark $count chapters up to $chapterLabel before leaving?';
  }

  @override
  String get readingProgressConfirmAction => 'Mark as read';

  @override
  String get readingProgressOpenOnlyAction => 'Open without marking';

  @override
  String get readingProgressUndoAction => 'Undo';

  @override
  String get readingProgressUpdatedMessage => 'Reading progress updated';

  @override
  String get navHome => 'Home';

  @override
  String get navExplore => 'Explore';

  @override
  String get navLibrary => 'Library';

  @override
  String get navProfile => 'Profile';

  @override
  String get settingsCacheSizeLabel => 'Cached data';

  @override
  String settingsCacheSizeValue(Object size) {
    return '$size';
  }

  @override
  String get settingsCacheSizeLoading => 'Calculating…';

  @override
  String get refreshAction => 'Refresh';

  @override
  String get profileReadingPreferencesSection => 'Reading preferences';

  @override
  String get profileAppSettingsSection => 'App settings';

  @override
  String get profileReadingModeTitle => 'Reading mode';

  @override
  String get profileReadingModeVertical => 'Vertical';

  @override
  String get profileReadingModePaged => 'Paged';

  @override
  String get profilePreferredAppLanguageTitle => 'App language';

  @override
  String get profilePreferredReadingLanguageTitle => 'Manga reading language';

  @override
  String get profileCacheSettingsTitle => 'Cache & saved data';

  @override
  String get profileCacheSettingsSubtitle => 'Clear local data';

  @override
  String get profileAppInfoTitle => 'App information';

  @override
  String get profileAppInfoSubtitle => 'Version, licenses, credits';

  @override
  String get profileGuestTitle => 'You\'re using the app as a guest.';

  @override
  String get profileGuestSubtitle =>
      'Sign in or create an account to view your profile and manage your preferences.';

  @override
  String get profileGuestCta => 'Sign in or create account';

  @override
  String get profileSignOutAction => 'Sign out';

  @override
  String get profileSignOutSnackBar => 'Signed out. You are now in guest mode.';

  @override
  String get profileServerConnectionError => 'Could not connect to the server.';

  @override
  String profileVersionLabel(Object version, Object buildNumber) {
    return 'Version $version (Build $buildNumber)';
  }

  @override
  String get authSignInTitle => 'Sign in';

  @override
  String get authSignInSubtitle => 'Your manga collection awaits';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authSignInButton => 'Sign in';

  @override
  String get authNoAccount => 'Don\'t have an account? Create one';

  @override
  String get authContinueAsGuest => 'Continue as guest';

  @override
  String get authEmailRequired => 'Enter your email.';

  @override
  String get authEmailInvalid => 'Enter a valid email.';

  @override
  String get authPasswordRequired => 'Enter your password.';

  @override
  String get authPasswordTooShort => 'Password must be at least 6 characters.';

  @override
  String get authCreateAccountTitle => 'Create account';

  @override
  String get authCreateAccountSubtitle => 'Join the collection';

  @override
  String get authCreateAccountButton => 'Create account';

  @override
  String get authHaveAccount => 'Already have an account? Sign in';

  @override
  String get readerSettingsDirection => 'Reading direction';

  @override
  String get readerSettingsBrightness => 'Brightness';

  @override
  String get readerSettingsAmoled => 'AMOLED Black';

  @override
  String get readerSettingsAmoledSubtitle => 'Save battery on OLED screens';

  @override
  String get readerSettingsImmersive => 'Immersive mode';

  @override
  String get readerSettingsImmersiveSubtitle => 'Hide system navigation bars';

  @override
  String get readerSettingsConfirm => 'Confirm settings';

  @override
  String get readerDirectionLtr => 'LTR';

  @override
  String get readerDirectionRtl => 'RTL';

  @override
  String get readerDirectionVertical => 'Vertical';
}
