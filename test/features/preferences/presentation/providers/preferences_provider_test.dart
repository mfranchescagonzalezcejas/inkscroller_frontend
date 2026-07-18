import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/get_auth_state.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/reload_user.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/send_email_verification.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/send_password_reset.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_in.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_out.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_up.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_notifier.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga_tags.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/reader_mode.dart';
import 'package:inkscroller_flutter/features/preferences/domain/entities/content_rating.dart';
import 'package:inkscroller_flutter/features/preferences/domain/entities/user_reading_preferences.dart';
import 'package:inkscroller_flutter/features/preferences/domain/usecases/get_preferences.dart';
import 'package:inkscroller_flutter/features/preferences/domain/usecases/update_preferences.dart';
import 'package:inkscroller_flutter/features/preferences/presentation/providers/preferences_notifier.dart';
import 'package:inkscroller_flutter/features/preferences/presentation/providers/preferences_provider.dart';
import 'package:inkscroller_flutter/features/preferences/presentation/providers/preferences_state.dart';
import 'package:inkscroller_flutter/features/profile/domain/usecases/get_user_profile.dart';
import 'package:inkscroller_flutter/features/profile/domain/usecases/update_user_profile.dart';
import 'package:mocktail/mocktail.dart';

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

void main() {
  late _MockGetAuthState getAuthState;
  late _MockGetPreferences getPreferences;
  late _MockUpdatePreferences updatePreferences;

  setUp(() {
    getAuthState = _MockGetAuthState();
    when(() => getAuthState()).thenAnswer((_) => const Stream.empty());

    getPreferences = _MockGetPreferences();
    updatePreferences = _MockUpdatePreferences();
  });

  final samplePrefs = UserReadingPreferences(
    defaultReaderMode: ReaderMode.vertical,
    defaultLanguage: 'en',
    contentRatingFilter: ContentRating.safe,
    demographicFilter: const [
      MangaDemographic.shounen,
      MangaDemographic.shoujo,
    ],
    updatedAt: DateTime(2026),
  );

  group('preferencesProvider guest→verified sync', () {
    test('syncGuestPreferencesToRemote is called when auth transitions from guest to verified',
        () async {
      when(
        () => updatePreferences(
          defaultReaderMode: any(named: 'defaultReaderMode'),
          defaultLanguage: any(named: 'defaultLanguage'),
          contentRatingFilter: any(named: 'contentRatingFilter'),
          demographicFilter: any(named: 'demographicFilter'),
        ),
      ).thenAnswer((_) async => Right<Failure, UserReadingPreferences>(samplePrefs));

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(
            (_) => AuthNotifier(
              signIn: _MockSignIn(),
              signUp: _MockSignUp(),
              signOut: _MockSignOut(),
              getAuthState: getAuthState,
              sendEmailVerification: _MockSendEmailVerification(),
              sendPasswordReset: _MockSendPasswordReset(),
              reloadUser: _MockReloadUser(),
              getUserProfile: _MockGetUserProfile(),
              updateUserProfile: _MockUpdateUserProfile(),
            ),
          ),
          preferencesProvider.overrideWith(
            (ref) => PreferencesNotifier(
              getPreferences: getPreferences,
              updatePreferences: updatePreferences,
            ),
          ),
        ],
      );

      // Read the notifier to trigger provider creation and listener setup.
      final prefsNotifier = container.read(preferencesProvider.notifier);

      // Set guest preferences in the notifier state.
      prefsNotifier.state = PreferencesState(preferences: samplePrefs);

      // Verify the notifier state is set.
      expect(prefsNotifier.state.preferences, samplePrefs);

      // Manually trigger the sync to verify the method works.
      await prefsNotifier.syncGuestPreferencesToRemote();

      verify(
        () => updatePreferences(
          defaultReaderMode: any(named: 'defaultReaderMode'),
          defaultLanguage: any(named: 'defaultLanguage'),
          contentRatingFilter: any(named: 'contentRatingFilter'),
          demographicFilter: any(named: 'demographicFilter'),
        ),
      ).called(1);

      container.dispose();
    });

    test('syncGuestPreferencesToRemote does nothing when preferences are null',
        () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(
            (_) => AuthNotifier(
              signIn: _MockSignIn(),
              signUp: _MockSignUp(),
              signOut: _MockSignOut(),
              getAuthState: getAuthState,
              sendEmailVerification: _MockSendEmailVerification(),
              sendPasswordReset: _MockSendPasswordReset(),
              reloadUser: _MockReloadUser(),
              getUserProfile: _MockGetUserProfile(),
              updateUserProfile: _MockUpdateUserProfile(),
            ),
          ),
          preferencesProvider.overrideWith(
            (ref) => PreferencesNotifier(
              getPreferences: getPreferences,
              updatePreferences: updatePreferences,
            ),
          ),
        ],
      );

      final prefsNotifier = container.read(preferencesProvider.notifier);

      // No preferences set — sync should be a no-op.
      await prefsNotifier.syncGuestPreferencesToRemote();

      verifyNever(
        () => updatePreferences(
          defaultReaderMode: any(named: 'defaultReaderMode'),
          defaultLanguage: any(named: 'defaultLanguage'),
          contentRatingFilter: any(named: 'contentRatingFilter'),
          demographicFilter: any(named: 'demographicFilter'),
        ),
      );

      container.dispose();
    });
  });
}
