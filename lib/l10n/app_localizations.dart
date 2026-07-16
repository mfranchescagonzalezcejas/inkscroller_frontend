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

  /// No description provided for @demographicUnspecified.
  ///
  /// In en, this message translates to:
  /// **'Unspecified'**
  String get demographicUnspecified;

  /// No description provided for @profileDemographicTitle.
  ///
  /// In en, this message translates to:
  /// **'Demographics shown'**
  String get profileDemographicTitle;

  /// No description provided for @profileDemographicCount.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =1{1 selected} other{{count} selected}}'**
  String profileDemographicCount(int count);

  /// No description provided for @profileDemographicSelectionRequired.
  ///
  /// In en, this message translates to:
  /// **'Select at least one demographic'**
  String get profileDemographicSelectionRequired;

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

  /// No description provided for @authCompleteProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get authCompleteProfileTitle;

  /// No description provided for @authCompleteProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your account was created. Add the required profile details to continue.'**
  String get authCompleteProfileSubtitle;

  /// No description provided for @authCompleteProfileButton.
  ///
  /// In en, this message translates to:
  /// **'Complete profile'**
  String get authCompleteProfileButton;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authHaveAccount;

  /// No description provided for @authUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get authUsernameLabel;

  /// No description provided for @authUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a username.'**
  String get authUsernameRequired;

  /// No description provided for @authUsernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use 3–30 lowercase letters, numbers, underscores, or hyphens.'**
  String get authUsernameInvalid;

  /// No description provided for @authConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPasswordLabel;

  /// No description provided for @authConfirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password.'**
  String get authConfirmPasswordRequired;

  /// No description provided for @authConfirmPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get authConfirmPasswordMismatch;

  /// No description provided for @authBirthDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Birth date'**
  String get authBirthDateLabel;

  /// No description provided for @authBirthDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Select your birth date.'**
  String get authBirthDateRequired;

  /// No description provided for @authBirthDateInvalid.
  ///
  /// In en, this message translates to:
  /// **'You must be at least 13 years old.'**
  String get authBirthDateInvalid;

  /// No description provided for @authTermsAcknowledgement.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms and Privacy Policy.'**
  String get authTermsAcknowledgement;

  /// No description provided for @authTermsRequired.
  ///
  /// In en, this message translates to:
  /// **'You must agree to the Terms and Privacy Policy.'**
  String get authTermsRequired;

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

  /// No description provided for @dialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get dialogConfirm;

  /// No description provided for @dialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialogCancel;

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

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountWarningBody.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent and irreversible. All your data, including your profile, preferences, and reading progress, will be deleted.'**
  String get deleteAccountWarningBody;

  /// No description provided for @deleteAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm:'**
  String get deleteAccountPrompt;

  /// No description provided for @deleteAccountPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to retry:'**
  String get deleteAccountPasswordLabel;

  /// No description provided for @deleteAccountPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get deleteAccountPasswordHint;

  /// No description provided for @deleteAccountCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get deleteAccountCancelAction;

  /// No description provided for @deleteAccountFinalizeAction.
  ///
  /// In en, this message translates to:
  /// **'Finalize'**
  String get deleteAccountFinalizeAction;

  /// No description provided for @deleteAccountDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAccountDeleteAction;

  /// No description provided for @deleteAccountIncompleteRecoveryMessage.
  ///
  /// In en, this message translates to:
  /// **'The deletion is incomplete. Cleanup must be finalized.'**
  String get deleteAccountIncompleteRecoveryMessage;

  /// No description provided for @accountSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get accountSectionLabel;

  /// No description provided for @settingsAccountDeletedWithWarnings.
  ///
  /// In en, this message translates to:
  /// **'Account deleted with warnings'**
  String get settingsAccountDeletedWithWarnings;

  /// No description provided for @settingsAccountDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully'**
  String get settingsAccountDeletedSuccessfully;

  /// No description provided for @cleanupUnexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Error during cleanup'**
  String get cleanupUnexpectedError;

  /// No description provided for @readerPageLoading.
  ///
  /// In en, this message translates to:
  /// **'Page {pageNumber}'**
  String readerPageLoading(int pageNumber);

  /// No description provided for @readerPageLoadingVerbose.
  ///
  /// In en, this message translates to:
  /// **'Loading page {pageNumber}…'**
  String readerPageLoadingVerbose(int pageNumber);

  /// No description provided for @readerPageLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load page {pageNumber}'**
  String readerPageLoadError(int pageNumber);

  /// No description provided for @readerNoPages.
  ///
  /// In en, this message translates to:
  /// **'Chapter has no pages'**
  String get readerNoPages;

  /// No description provided for @readerErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong loading the chapter.'**
  String get readerErrorGeneric;

  /// No description provided for @cleanupRequiresRecentLogin.
  ///
  /// In en, this message translates to:
  /// **'You need to sign in again to complete the deletion.'**
  String get cleanupRequiresRecentLogin;

  /// No description provided for @cleanupFirebaseDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t delete your Firebase account. Try again.'**
  String get cleanupFirebaseDeleteFailed;

  /// No description provided for @cleanupReauthWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password.'**
  String get cleanupReauthWrongPassword;

  /// No description provided for @cleanupReauthUserMismatch.
  ///
  /// In en, this message translates to:
  /// **'The user doesn\'t match the current session.'**
  String get cleanupReauthUserMismatch;

  /// No description provided for @cleanupReauthInvalidCredential.
  ///
  /// In en, this message translates to:
  /// **'Invalid credential.'**
  String get cleanupReauthInvalidCredential;

  /// No description provided for @cleanupReauthTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a moment and try again.'**
  String get cleanupReauthTooManyRequests;

  /// No description provided for @cleanupReauthAuthError.
  ///
  /// In en, this message translates to:
  /// **'Authentication error.'**
  String get cleanupReauthAuthError;

  /// No description provided for @cleanupPrefsClearWarning.
  ///
  /// In en, this message translates to:
  /// **'Some local data could not be cleared.'**
  String get cleanupPrefsClearWarning;

  /// No description provided for @cleanupSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Please sign in again and retry.'**
  String get cleanupSessionExpired;

  /// No description provided for @deleteAccountGenericError.
  ///
  /// In en, this message translates to:
  /// **'Could not delete account. Please try again.'**
  String get deleteAccountGenericError;

  /// No description provided for @authSessionVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Session could not be verified. Sign in again.'**
  String get authSessionVerificationFailed;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get authInvalidCredentials;

  /// No description provided for @authEmailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered.'**
  String get authEmailAlreadyInUse;

  /// No description provided for @authWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak — use at least 6 characters.'**
  String get authWeakPassword;

  /// No description provided for @authTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait and try again.'**
  String get authTooManyRequests;

  /// No description provided for @authNetworkError.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your network.'**
  String get authNetworkError;

  /// No description provided for @authUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please try again.'**
  String get authUnknownError;

  /// No description provided for @authEmailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email before signing in. Check your inbox and click the verification link.'**
  String get authEmailNotVerified;

  /// No description provided for @authVerifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get authVerifyEmailTitle;

  /// No description provided for @authVerifyEmailBody.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification link to {email}. Click the link in the email to activate your account.'**
  String authVerifyEmailBody(String email);

  /// No description provided for @authVerifyEmailSent.
  ///
  /// In en, this message translates to:
  /// **'✅ Verification email sent'**
  String get authVerifyEmailSent;

  /// No description provided for @authVerifyEmailContinue.
  ///
  /// In en, this message translates to:
  /// **'I\'ve verified — continue'**
  String get authVerifyEmailContinue;

  /// No description provided for @authVerifyEmailResend.
  ///
  /// In en, this message translates to:
  /// **'Resend verification email'**
  String get authVerifyEmailResend;

  /// No description provided for @authVerifyEmailWait.
  ///
  /// In en, this message translates to:
  /// **'Wait a moment before resending'**
  String get authVerifyEmailWait;

  /// No description provided for @authVerifyEmailDifferentEmail.
  ///
  /// In en, this message translates to:
  /// **'Use a different email'**
  String get authVerifyEmailDifferentEmail;

  /// No description provided for @authVerifyEmailSuccess.
  ///
  /// In en, this message translates to:
  /// **'Email verified! Welcome to InkScroller.'**
  String get authVerifyEmailSuccess;

  /// No description provided for @authVerifyEmailNotYet.
  ///
  /// In en, this message translates to:
  /// **'Your email hasn\'t been verified yet. Check your inbox and click the link.'**
  String get authVerifyEmailNotYet;

  /// No description provided for @authVerifyEmailResent.
  ///
  /// In en, this message translates to:
  /// **'Verification email resent.'**
  String get authVerifyEmailResent;

  /// No description provided for @authVerifyInProfile.
  ///
  /// In en, this message translates to:
  /// **'Verify email'**
  String get authVerifyInProfile;

  /// No description provided for @authVerifyInProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unverified account'**
  String get authVerifyInProfileSubtitle;

  /// No description provided for @libraryErrorNetworkNoConnection.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the server.'**
  String get libraryErrorNetworkNoConnection;

  /// No description provided for @libraryErrorServerBadResponse.
  ///
  /// In en, this message translates to:
  /// **'The server responded with an error.'**
  String get libraryErrorServerBadResponse;

  /// No description provided for @libraryErrorRequestCancelled.
  ///
  /// In en, this message translates to:
  /// **'The request was cancelled.'**
  String get libraryErrorRequestCancelled;

  /// No description provided for @libraryErrorInvalidCertificate.
  ///
  /// In en, this message translates to:
  /// **'Invalid certificate.'**
  String get libraryErrorInvalidCertificate;

  /// No description provided for @libraryErrorNetworkUnknown.
  ///
  /// In en, this message translates to:
  /// **'An unexpected network error occurred.'**
  String get libraryErrorNetworkUnknown;

  /// No description provided for @libraryErrorEmptyResponse.
  ///
  /// In en, this message translates to:
  /// **'The server returned an empty response.'**
  String get libraryErrorEmptyResponse;

  /// No description provided for @libraryErrorExternalChapter.
  ///
  /// In en, this message translates to:
  /// **'This chapter is only available on the original site.'**
  String get libraryErrorExternalChapter;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version} (Build {build})'**
  String aboutVersion(String version, String build);

  /// No description provided for @aboutAppDescription.
  ///
  /// In en, this message translates to:
  /// **'Personal manga reader — open source'**
  String get aboutAppDescription;

  /// No description provided for @aboutDisclaimerTitle.
  ///
  /// In en, this message translates to:
  /// **'DISCLAIMER'**
  String get aboutDisclaimerTitle;

  /// No description provided for @aboutDisclaimerMangadexTitle.
  ///
  /// In en, this message translates to:
  /// **'Not affiliated with MangaDex'**
  String get aboutDisclaimerMangadexTitle;

  /// No description provided for @aboutDisclaimerMangadexBody.
  ///
  /// In en, this message translates to:
  /// **'{appName} is not affiliated, associated, authorized, or endorsed by MangaDex. The name \"MangaDex\" and its logo are trademarks of their respective owners. Use of the public MangaDex API is subject to its Terms of Use.'**
  String aboutDisclaimerMangadexBody(String appName);

  /// No description provided for @aboutDisclaimerMalTitle.
  ///
  /// In en, this message translates to:
  /// **'Not affiliated with MyAnimeList'**
  String get aboutDisclaimerMalTitle;

  /// No description provided for @aboutDisclaimerMalBody.
  ///
  /// In en, this message translates to:
  /// **'{appName} is not affiliated, associated, authorized, or endorsed by MyAnimeList (MAL). The name \"MyAnimeList\" and its logo are trademarks of their respective owners. Additional metadata is sourced through the public Jikan API, an unofficial MAL API, used for informational purposes only.'**
  String aboutDisclaimerMalBody(String appName);

  /// No description provided for @aboutDisclaimerCopyrightTitle.
  ///
  /// In en, this message translates to:
  /// **'Content copyright'**
  String get aboutDisclaimerCopyrightTitle;

  /// No description provided for @aboutDisclaimerCopyrightBody.
  ///
  /// In en, this message translates to:
  /// **'All manga content (images, chapters, covers) belongs to their respective authors and publishers. {appName} does not store or redistribute copyrighted content. This app only consumes data from third-party public APIs.'**
  String aboutDisclaimerCopyrightBody(String appName);

  /// No description provided for @aboutCreditsTitle.
  ///
  /// In en, this message translates to:
  /// **'CREDITS AND APIs'**
  String get aboutCreditsTitle;

  /// No description provided for @aboutCreditMangadexDescription.
  ///
  /// In en, this message translates to:
  /// **'Catalog, chapters, and covers'**
  String get aboutCreditMangadexDescription;

  /// No description provided for @aboutCreditJikanDescription.
  ///
  /// In en, this message translates to:
  /// **'Additional metadata (MAL)'**
  String get aboutCreditJikanDescription;

  /// No description provided for @aboutCreditCloudRunDescription.
  ///
  /// In en, this message translates to:
  /// **'Backend infrastructure'**
  String get aboutCreditCloudRunDescription;

  /// No description provided for @aboutCreditFirebaseDescription.
  ///
  /// In en, this message translates to:
  /// **'User authentication'**
  String get aboutCreditFirebaseDescription;

  /// No description provided for @profileContentRatingTitle.
  ///
  /// In en, this message translates to:
  /// **'Content rating'**
  String get profileContentRatingTitle;

  /// No description provided for @profileContentRatingSafe.
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get profileContentRatingSafe;

  /// No description provided for @profileContentRatingSuggestive.
  ///
  /// In en, this message translates to:
  /// **'Safe + Suggestive'**
  String get profileContentRatingSuggestive;

  /// No description provided for @profileContentRatingAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get profileContentRatingAll;

  /// No description provided for @chaptersSortAsc.
  ///
  /// In en, this message translates to:
  /// **'Number ↑'**
  String get chaptersSortAsc;

  /// No description provided for @chaptersSortDesc.
  ///
  /// In en, this message translates to:
  /// **'Number ↓'**
  String get chaptersSortDesc;

  /// No description provided for @chaptersFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All chapters'**
  String get chaptersFilterAll;

  /// No description provided for @chaptersFilterUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread only'**
  String get chaptersFilterUnread;

  /// No description provided for @markAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get markAsRead;

  /// No description provided for @markAsUnread.
  ///
  /// In en, this message translates to:
  /// **'Mark as unread'**
  String get markAsUnread;

  /// No description provided for @chaptersFilteredOut.
  ///
  /// In en, this message translates to:
  /// **'No chapters match the current filter'**
  String get chaptersFilteredOut;
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
