import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/core/l10n/app_locale_provider.dart';
import 'package:inkscroller_flutter/features/auth/domain/entities/app_user.dart';
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
import 'package:inkscroller_flutter/features/profile/domain/entities/user_profile.dart';
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
  _FakeAuthNotifier({required super.getAuthState})
      : super(
          signIn: _MockSignIn(),
          signUp: _MockSignUp(),
          signOut: _MockSignOut(),
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
  _FakeProfileNotifier({required super.getUserProfile})
      : super(
          updateUserProfile: _MockUpdateUserProfile(),
        );
}

/// Widget tests for [ProfilePage] covering the authenticated _AvatarSection
/// rendering: username header, initials priority, blank-username fallback, and
/// email-only fallback.
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
    // Force authenticated state.
    authNotifier.state = const AuthState(
      user: AppUser(
        uid: 'uid-123',
        email: 'alice@example.com',
        isEmailVerified: true,
      ),
    );

    prefsNotifier = _FakePrefsNotifier();
    prefsNotifier.state = PreferencesState(
      preferences: UserReadingPreferences(
        defaultReaderMode: ReaderMode.vertical,
        defaultLanguage: 'en',
        updatedAt: DateTime(2026),
      ),
    );

    // profileNotifier is created in buildTestWidget with proper stubs.
  });

  Widget buildTestWidget({UserProfile? profile}) {
    // Create a stubbed profile notifier with the desired profile.
    final mockGetUserProfile = _MockGetUserProfile();
    if (profile != null) {
      when(
        () => mockGetUserProfile(),
      ).thenAnswer((_) async => Right<Failure, UserProfile>(profile));
    }
    profileNotifier = _FakeProfileNotifier(getUserProfile: mockGetUserProfile);
    profileNotifier.state = UserProfileState(profile: profile);

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

  testWidgets(
      'avatar section shows username as header when username is available',
      (tester) async {
    await tester.pumpWidget(buildTestWidget(
      profile: UserProfile(
        firebaseUid: 'uid-123',
        email: 'alice@example.com',
        username: 'zoe',
        displayName: 'Bob',
        createdAt: DateTime(2024),
      ),
    ));
    await tester.pumpAndSettle();

    // Header shows username (preferred over displayName).
    // The username also appears in the account-section pref row.
    expect(find.text('zoe'), findsAtLeastNWidgets(1));
    // Email still shown below
    expect(find.text('alice@example.com'), findsOneWidget);
  });

  testWidgets('avatar section shows initials from username', (tester) async {
    await tester.pumpWidget(buildTestWidget(
      profile: UserProfile(
        firebaseUid: 'uid-123',
        email: 'alice@example.com',
        username: 'zoe',
        displayName: 'Bob',
        createdAt: DateTime(2024),
      ),
    ));
    await tester.pumpAndSettle();

    // Initial is 'Z' from username 'zoe', not 'B' from displayName or 'A' from email
    expect(find.text('Z'), findsOneWidget);
  });

  testWidgets(
      'avatar section falls back to displayName when username is blank',
      (tester) async {
    await tester.pumpWidget(buildTestWidget(
      profile: UserProfile(
        firebaseUid: 'uid-123',
        email: 'alice@example.com',
        username: '',
        displayName: 'Bob',
        createdAt: DateTime(2024),
      ),
    ));
    await tester.pumpAndSettle();

    // Header shows displayName when username is blank
    expect(find.text('Bob'), findsOneWidget);
    // Initial is 'B' from displayName
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets(
      'avatar section falls back to email when username and displayName are null',
      (tester) async {
    await tester.pumpWidget(buildTestWidget(
      profile: UserProfile(
        firebaseUid: 'uid-123',
        email: 'alice@example.com',
        createdAt: DateTime(2024),
      ),
    ));
    await tester.pumpAndSettle();

    // No header name shown (no username or displayName)
    expect(find.text('alice@example.com'), findsOneWidget);
    // Initial is 'A' from email
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('authenticated view does not show settings gear icon',
      (tester) async {
    await tester.pumpWidget(buildTestWidget(
      profile: UserProfile(
        firebaseUid: 'uid-123',
        email: 'alice@example.com',
        username: 'alice',
        createdAt: DateTime(2024),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.settings_outlined), findsNothing);
  });

  testWidgets('authenticated view shows app settings section in body',
      (tester) async {
    await tester.pumpWidget(buildTestWidget(
      profile: UserProfile(
        firebaseUid: 'uid-123',
        email: 'alice@example.com',
        username: 'alice',
        createdAt: DateTime(2024),
      ),
    ));
    // pumpAndSettle may hang on the FutureProvider; use explicit pumps
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // Use skipOffstage: false because the section may be below the scroll fold
    expect(find.text('App settings', skipOffstage: false), findsOneWidget);
    expect(find.text('Cache & saved data', skipOffstage: false), findsOneWidget);
    expect(find.text('App information', skipOffstage: false), findsOneWidget);
  });
}
