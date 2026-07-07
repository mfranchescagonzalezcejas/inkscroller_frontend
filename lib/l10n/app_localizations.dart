import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @offlineBannerMessage.
  ///
  /// In en, this message translates to:
  /// **'Offline. Showing cached data when available.'**
  String get offlineBannerMessage;

  /// No description provided for @searchMangaHint.
  ///
  /// In en, this message translates to:
  /// **'Search manga…'**
  String get searchMangaHint;

  /// No description provided for @clearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearAction;

  /// No description provided for @noMangasAvailable.
  ///
  /// In en, this message translates to:
  /// **'No manga available'**
  String get noMangasAvailable;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String noSearchResults(Object query);

  /// No description provided for @noMoreMangaToLoad.
  ///
  /// In en, this message translates to:
  /// **'No more manga to load'**
  String get noMoreMangaToLoad;

  /// No description provided for @failedToLoadChapters.
  ///
  /// In en, this message translates to:
  /// **'Could not load chapters'**
  String get failedToLoadChapters;

  /// No description provided for @retryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryAction;

  /// No description provided for @noChaptersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No chapters available'**
  String get noChaptersAvailable;

  /// No description provided for @chaptersTitle.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get chaptersTitle;

  /// No description provided for @routeInvalidTitle.
  ///
  /// In en, this message translates to:
  /// **'Invalid route'**
  String get routeInvalidTitle;

  /// No description provided for @routeMissingMangaMessage.
  ///
  /// In en, this message translates to:
  /// **'Missing manga data to open the detail page.'**
  String get routeMissingMangaMessage;

  /// No description provided for @routeMissingChapterMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not find the requested chapter.'**
  String get routeMissingChapterMessage;

  /// No description provided for @routeNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get routeNotFoundTitle;

  /// No description provided for @routeNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'The requested route does not exist.'**
  String get routeNotFoundMessage;

  /// No description provided for @backToHomeAction.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get backToHomeAction;

  /// No description provided for @settingsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon 👀'**
  String get settingsComingSoon;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settingsAppSectionTitle;

  /// No description provided for @settingsAppNameLabel.
  ///
  /// In en, this message translates to:
  /// **'App name'**
  String get settingsAppNameLabel;

  /// No description provided for @settingsFlavorLabel.
  ///
  /// In en, this message translates to:
  /// **'Flavor'**
  String get settingsFlavorLabel;

  /// No description provided for @settingsApiBaseUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'API base URL'**
  String get settingsApiBaseUrlLabel;

  /// No description provided for @settingsCacheSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Cache'**
  String get settingsCacheSectionTitle;

  /// No description provided for @settingsMangaListCacheLabel.
  ///
  /// In en, this message translates to:
  /// **'Manga list cache'**
  String get settingsMangaListCacheLabel;

  /// No description provided for @settingsMangaDetailCacheLabel.
  ///
  /// In en, this message translates to:
  /// **'Manga detail cache'**
  String get settingsMangaDetailCacheLabel;

  /// No description provided for @settingsMangaChaptersCacheLabel.
  ///
  /// In en, this message translates to:
  /// **'Chapter list cache'**
  String get settingsMangaChaptersCacheLabel;

  /// No description provided for @settingsCacheMinutesValue.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String settingsCacheMinutesValue(int minutes);

  /// No description provided for @settingsClearCacheAction.
  ///
  /// In en, this message translates to:
  /// **'Clear cached data'**
  String get settingsClearCacheAction;

  /// No description provided for @settingsCacheClearedMessage.
  ///
  /// In en, this message translates to:
  /// **'Cached data cleared'**
  String get settingsCacheClearedMessage;

  /// No description provided for @settingsCacheClearFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not clear cached data'**
  String get settingsCacheClearFailedMessage;

  /// No description provided for @loadingChapter.
  ///
  /// In en, this message translates to:
  /// **'Loading chapter'**
  String get loadingChapter;

  /// No description provided for @chapterPagesProgress.
  ///
  /// In en, this message translates to:
  /// **'{loadedPages} / {totalPages} pages'**
  String chapterPagesProgress(int loadedPages, int totalPages);

  /// No description provided for @readingChapter.
  ///
  /// In en, this message translates to:
  /// **'Reading chapter'**
  String get readingChapter;

  /// No description provided for @chapterLabel.
  ///
  /// In en, this message translates to:
  /// **'Chapter {number}'**
  String chapterLabel(Object number);

  /// No description provided for @extraLabel.
  ///
  /// In en, this message translates to:
  /// **'Extra'**
  String get extraLabel;

  /// No description provided for @homeFeatured.
  ///
  /// In en, this message translates to:
  /// **'🔥 Featured'**
  String get homeFeatured;

  /// No description provided for @homeLatest.
  ///
  /// In en, this message translates to:
  /// **'🆕 Latest'**
  String get homeLatest;

  /// No description provided for @homePopular.
  ///
  /// In en, this message translates to:
  /// **'🔥 Popular'**
  String get homePopular;

  /// No description provided for @homeDemographic.
  ///
  /// In en, this message translates to:
  /// **'📚 Demographics'**
  String get homeDemographic;

  /// No description provided for @homeNoMangas.
  ///
  /// In en, this message translates to:
  /// **'No manga available'**
  String get homeNoMangas;

  /// No description provided for @demographicShounen.
  ///
  /// In en, this message translates to:
  /// **'Shounen'**
  String get demographicShounen;

  /// No description provided for @demographicShoujo.
  ///
  /// In en, this message translates to:
  /// **'Shoujo'**
  String get demographicShoujo;

  /// No description provided for @demographicSeinen.
  ///
  /// In en, this message translates to:
  /// **'Seinen'**
  String get demographicSeinen;

  /// No description provided for @demographicJosei.
  ///
  /// In en, this message translates to:
  /// **'Josei'**
  String get demographicJosei;

  /// No description provided for @readNow.
  ///
  /// In en, this message translates to:
  /// **'Read Now'**
  String get readNow;

  /// No description provided for @addToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Add to Library'**
  String get addToLibrary;

  /// No description provided for @removeFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Remove from Library'**
  String get removeFromLibrary;

  /// No description provided for @libraryItemAdded.
  ///
  /// In en, this message translates to:
  /// **'{title} added to your library'**
  String libraryItemAdded(Object title);

  /// No description provided for @libraryItemRemoved.
  ///
  /// In en, this message translates to:
  /// **'{title} removed from your library'**
  String libraryItemRemoved(Object title);

  /// No description provided for @genreAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get genreAll;

  /// No description provided for @genrePopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get genrePopular;

  /// No description provided for @genreRomance.
  ///
  /// In en, this message translates to:
  /// **'Romance'**
  String get genreRomance;

  /// No description provided for @genreAction.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get genreAction;

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'My Library'**
  String get libraryTitle;

  /// No description provided for @libraryCollectionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} collections'**
  String libraryCollectionsCount(int count);

  /// No description provided for @libraryTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get libraryTabAll;

  /// No description provided for @libraryTabReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get libraryTabReading;

  /// No description provided for @libraryTabCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get libraryTabCompleted;

  /// No description provided for @libraryTabOnHold.
  ///
  /// In en, this message translates to:
  /// **'On Hold'**
  String get libraryTabOnHold;

  /// No description provided for @libraryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your library is empty. Add manga from Home or Manga Detail.'**
  String get libraryEmpty;

  /// No description provided for @libraryEmptyTab.
  ///
  /// In en, this message translates to:
  /// **'No manga in this tab yet.'**
  String get libraryEmptyTab;

  /// No description provided for @libraryStatusReading.
  ///
  /// In en, this message translates to:
  /// **'Mark as Reading'**
  String get libraryStatusReading;

  /// No description provided for @libraryStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark as Completed'**
  String get libraryStatusCompleted;

  /// No description provided for @libraryStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Mark as Paused'**
  String get libraryStatusPaused;

  /// No description provided for @libraryStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Library status updated'**
  String get libraryStatusUpdated;

  /// No description provided for @libraryUnknownMeta.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get libraryUnknownMeta;

  /// No description provided for @libraryProgressValue.
  ///
  /// In en, this message translates to:
  /// **'{readCount} / {totalCount} read'**
  String libraryProgressValue(int readCount, int totalCount);

  /// No description provided for @exploreTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get exploreTitle;

  /// No description provided for @exploreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discover your next story'**
  String get exploreSubtitle;

  /// No description provided for @externalChapterTitle.
  ///
  /// In en, this message translates to:
  /// **'External chapter'**
  String get externalChapterTitle;

  /// No description provided for @externalChapterMessage.
  ///
  /// In en, this message translates to:
  /// **'This chapter is only available on the original site. It cannot be read inside InkScroller.'**
  String get externalChapterMessage;

  /// No description provided for @externalChapterOpenAction.
  ///
  /// In en, this message translates to:
  /// **'Open on original site'**
  String get externalChapterOpenAction;

  /// No description provided for @externalChapterGoBackAction.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get externalChapterGoBackAction;

  /// No description provided for @readingProgressDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Update reading progress'**
  String get readingProgressDialogTitle;

  /// No description provided for @readingProgressDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'This will mark {count} chapters up to {chapterLabel} as read.'**
  String readingProgressDialogMessage(int count, Object chapterLabel);

  /// No description provided for @readingProgressDialogExternalMessage.
  ///
  /// In en, this message translates to:
  /// **'This chapter opens outside InkScroller. Do you want to mark {count} chapters up to {chapterLabel} before leaving?'**
  String readingProgressDialogExternalMessage(int count, Object chapterLabel);

  /// No description provided for @readingProgressConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get readingProgressConfirmAction;

  /// No description provided for @readingProgressOpenOnlyAction.
  ///
  /// In en, this message translates to:
  /// **'Open without marking'**
  String get readingProgressOpenOnlyAction;

  /// No description provided for @readingProgressUndoAction.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get readingProgressUndoAction;

  /// No description provided for @readingProgressUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Reading progress updated'**
  String get readingProgressUpdatedMessage;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get navExplore;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @settingsCacheSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Cached data'**
  String get settingsCacheSizeLabel;

  /// No description provided for @settingsCacheSizeValue.
  ///
  /// In en, this message translates to:
  /// **'{size}'**
  String settingsCacheSizeValue(Object size);

  /// No description provided for @settingsCacheSizeLoading.
  ///
  /// In en, this message translates to:
  /// **'Calculating…'**
  String get settingsCacheSizeLoading;

  /// No description provided for @refreshAction.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshAction;

  /// No description provided for @profileReadingPreferencesSection.
  ///
  /// In en, this message translates to:
  /// **'Reading preferences'**
  String get profileReadingPreferencesSection;

  /// No description provided for @profileAppSettingsSection.
  ///
  /// In en, this message translates to:
  /// **'App settings'**
  String get profileAppSettingsSection;

  /// No description provided for @profileReadingModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading mode'**
  String get profileReadingModeTitle;

  /// No description provided for @profileReadingModeVertical.
  ///
  /// In en, this message translates to:
  /// **'Vertical'**
  String get profileReadingModeVertical;

  /// No description provided for @profileReadingModePaged.
  ///
  /// In en, this message translates to:
  /// **'Paged'**
  String get profileReadingModePaged;

  /// No description provided for @profilePreferredAppLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get profilePreferredAppLanguageTitle;

  /// No description provided for @profilePreferredReadingLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Manga reading language'**
  String get profilePreferredReadingLanguageTitle;

  /// No description provided for @profileCacheSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Cache & saved data'**
  String get profileCacheSettingsTitle;

  /// No description provided for @profileCacheSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clear local data'**
  String get profileCacheSettingsSubtitle;

  /// No description provided for @profileAppInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'App information'**
  String get profileAppInfoTitle;

  /// No description provided for @profileAppInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Version, licenses, credits'**
  String get profileAppInfoSubtitle;

  /// No description provided for @profileGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re using the app as a guest.'**
  String get profileGuestTitle;

  /// No description provided for @profileGuestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in or create an account to view your profile and manage your preferences.'**
  String get profileGuestSubtitle;

  /// No description provided for @profileGuestCta.
  ///
  /// In en, this message translates to:
  /// **'Sign in or create account'**
  String get profileGuestCta;

  /// No description provided for @profileSignOutAction.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileSignOutAction;

  /// No description provided for @profileSignOutSnackBar.
  ///
  /// In en, this message translates to:
  /// **'Signed out. You are now in guest mode.'**
  String get profileSignOutSnackBar;

  /// No description provided for @profileServerConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the server.'**
  String get profileServerConnectionError;

  /// No description provided for @profileVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version} (Build {buildNumber})'**
  String profileVersionLabel(Object version, Object buildNumber);

  /// No description provided for @authSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignInTitle;

  /// No description provided for @authSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your manga collection awaits'**
  String get authSignInSubtitle;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authSignInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignInButton;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Create one'**
  String get authNoAccount;

  /// No description provided for @authContinueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get authContinueAsGuest;

  /// No description provided for @authEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email.'**
  String get authEmailRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email.'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get authPasswordRequired;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get authPasswordTooShort;

  /// No description provided for @authCreateAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccountTitle;

  /// No description provided for @authCreateAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join the collection'**
  String get authCreateAccountSubtitle;

  /// No description provided for @authCreateAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccountButton;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authHaveAccount;

  /// No description provided for @readerSettingsDirection.
  ///
  /// In en, this message translates to:
  /// **'Reading direction'**
  String get readerSettingsDirection;

  /// No description provided for @readerSettingsBrightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get readerSettingsBrightness;

  /// No description provided for @readerSettingsAmoled.
  ///
  /// In en, this message translates to:
  /// **'AMOLED Black'**
  String get readerSettingsAmoled;

  /// No description provided for @readerSettingsAmoledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save battery on OLED screens'**
  String get readerSettingsAmoledSubtitle;

  /// No description provided for @readerSettingsImmersive.
  ///
  /// In en, this message translates to:
  /// **'Immersive mode'**
  String get readerSettingsImmersive;

  /// No description provided for @readerSettingsImmersiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hide system navigation bars'**
  String get readerSettingsImmersiveSubtitle;

  /// No description provided for @readerSettingsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm settings'**
  String get readerSettingsConfirm;

  /// No description provided for @readerDirectionLtr.
  ///
  /// In en, this message translates to:
  /// **'LTR'**
  String get readerDirectionLtr;

  /// No description provided for @readerDirectionRtl.
  ///
  /// In en, this message translates to:
  /// **'RTL'**
  String get readerDirectionRtl;

  /// No description provided for @readerDirectionVertical.
  ///
  /// In en, this message translates to:
  /// **'Vertical'**
  String get readerDirectionVertical;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
