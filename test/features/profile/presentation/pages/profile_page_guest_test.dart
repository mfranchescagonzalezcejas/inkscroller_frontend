import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inkscroller_flutter/core/l10n/app_locale_provider.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/get_auth_state.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/reload_user.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/send_email_verification.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/send_password_reset.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_in.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_out.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_up.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_notifier.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_state.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga_tags.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga_capabilities.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/reader_mode.dart';
import 'package:inkscroller_flutter/features/preferences/domain/entities/content_rating.dart';
import 'package:inkscroller_flutter/features/preferences/domain/entities/demographic_resolution.dart';
import 'package:inkscroller_flutter/features/preferences/domain/entities/user_reading_preferences.dart';
import 'package:inkscroller_flutter/features/preferences/domain/usecases/get_preferences.dart';
import 'package:inkscroller_flutter/features/preferences/domain/usecases/update_preferences.dart';
import 'package:inkscroller_flutter/features/preferences/presentation/providers/content_rating_resolution_provider.dart';
import 'package:inkscroller_flutter/features/preferences/presentation/providers/demographic_resolution_provider.dart';
import 'package:inkscroller_flutter/features/preferences/presentation/providers/manga_capabilities_provider.dart';
import 'package:inkscroller_flutter/features/preferences/presentation/providers/preferences_notifier.dart';
import 'package:inkscroller_flutter/features/preferences/presentation/providers/preferences_provider.dart';
import 'package:inkscroller_flutter/features/preferences/presentation/providers/preferences_state.dart';
import 'package:inkscroller_flutter/features/profile/domain/usecases/get_user_profile.dart';
import 'package:inkscroller_flutter/features/profile/domain/usecases/update_user_profile.dart';
import 'package:inkscroller_flutter/features/profile/presentation/pages/profile_page.dart';
import 'package:inkscroller_flutter/features/profile/presentation/providers/user_profile_notifier.dart';
import 'package:inkscroller_flutter/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:inkscroller_flutter/features/profile/presentation/providers/user_profile_state.dart';
import 'package:inkscroller_flutter/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────

class _MockSignIn extends Mock implements SignIn {}
class _MockSignUp extends Mock implements SignUp {}
class _MockSignOut extends Mock implements SignOut {}
class _MockGetAuthState extends Mock implements GetAuthState {}
class _MockSendEmailVerification extends Mock implements SendEmailVerification {}
class _MockSendPasswordReset extends Mock implements SendPasswordReset {}
class _MockReloadUser extends Mock implements ReloadUser {}
class _MockGetUserProfile extends Mock implements GetUserProfile {}
class _MockUpdateUserProfile extends Mock implements UpdateUserProfile {}
class _MockGetPreferences extends Mock implements GetPreferences {}
class _MockUpdatePreferences extends Mock implements UpdatePreferences {}

// ── Fakes ──────────────────────────────────────────────────────────────────

class _FakeAuthNotifier extends AuthNotifier {
  // ignore: use_super_parameters — explicit for test clarity
  _FakeAuthNotifier({required GetAuthState getAuthState})
      : super(
          signIn: _MockSignIn(),
          signUp: _MockSignUp(),
          signOut: _MockSignOut(),
          getAuthState: getAuthState,
          sendEmailVerification: _MockSendEmailVerification(),
          sendPasswordReset: _MockSendPasswordReset(),
          reloadUser: _MockReloadUser(),
          getUserProfile: _MockGetUserProfile(),
          updateUserProfile: _MockUpdateUserProfile(),
        );

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendVerificationEmail() async {}
}

class _FakePrefsNotifier extends PreferencesNotifier {
  _FakePrefsNotifier()
      : super(
          getPreferences: _MockGetPreferences(),
          updatePreferences: _MockUpdatePreferences(),
        );
}

class _FakeProfileNotifier extends UserProfileNotifier {
  _FakeProfileNotifier()
      : super(
          getUserProfile: _MockGetUserProfile(),
          updateUserProfile: _MockUpdateUserProfile(),
        );
}

void main() {
  late _FakeAuthNotifier authNotifier;
  late _FakePrefsNotifier prefsNotifier;
  late _FakeProfileNotifier profileNotifier;
  late SharedPreferences sharedPreferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();

    final getAuthState = _MockGetAuthState();
    when(() => getAuthState()).thenAnswer((_) => const Stream.empty());

    authNotifier = _FakeAuthNotifier(getAuthState: getAuthState);
    // Force guest state (user == null).
    authNotifier.state = const AuthState();

    prefsNotifier = _FakePrefsNotifier();
    prefsNotifier.state = PreferencesState(
      preferences: UserReadingPreferences(
        defaultReaderMode: ReaderMode.vertical,
        defaultLanguage: 'en',
        updatedAt: DateTime(2026),
      ),
    );

    profileNotifier = _FakeProfileNotifier();
    profileNotifier.state = const UserProfileState();
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith((_) => authNotifier),
        preferencesProvider.overrideWith((_) => prefsNotifier),
        userProfileProvider.overrideWith((_) => profileNotifier),
        mangaCapabilitiesProvider.overrideWith(
          (_) async => const MangaCapabilities(supportsUnspecified: false),
        ),
        contentRatingResolutionProvider.overrideWith(
          (_) => const ContentRatingResolution(
            effectiveRating: ContentRating.safe,
            allowedOptions: [ContentRating.safe],
            isEditable: false,
          ),
        ),
        appLocaleProvider.overrideWith(
          (_) => AppLocaleNotifier(sharedPreferences: sharedPreferences),
        ),
        demographicResolutionProvider.overrideWith(
          (_) => const DemographicResolution(
            effectiveFilter: [
              MangaDemographic.shounen,
              MangaDemographic.shoujo,
            ],
            allowedOptions: [
              MangaDemographic.shounen,
              MangaDemographic.shoujo,
            ],
          ),
        ),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          initialLocation: '/profile',
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfilePage(),
            ),
            GoRoute(
              path: '/login',
              builder: (context, state) => const Scaffold(body: Text('Login')),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) =>
                  const Scaffold(body: Text('Settings')),
            ),
            GoRoute(
              path: '/about',
              builder: (context, state) =>
                  const Scaffold(body: Text('About')),
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('guest view shows reader mode, app language, and reading language',
      (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Reading mode'), findsOneWidget);
    expect(find.text('App language'), findsOneWidget);
    expect(find.text('Manga reading language'), findsOneWidget);
  });

  testWidgets('guest view does not show age-restricted fields',
      (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Content rating'), findsNothing);
    expect(find.text('Demographic'), findsNothing);
  });

  testWidgets('guest view shows localized Sign In button', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Sign in', skipOffstage: false), findsOneWidget);
  });

  testWidgets('guest view shows app settings section', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('App settings'), findsOneWidget);
    expect(find.text('Cache & saved data'), findsOneWidget);
    expect(find.text('App information'), findsOneWidget);
  });

  testWidgets('guest view does not show settings gear icon', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.settings_outlined), findsNothing);
  });
}
