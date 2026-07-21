import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inkscroller_flutter/core/router/app_routes.dart';
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
import 'package:inkscroller_flutter/features/profile/domain/usecases/get_user_profile.dart';
import 'package:inkscroller_flutter/features/profile/domain/usecases/update_user_profile.dart';
import 'package:inkscroller_flutter/features/settings/domain/repositories/account_cleanup_repository.dart';
import 'package:inkscroller_flutter/features/settings/domain/repositories/settings_repository.dart';
import 'package:inkscroller_flutter/features/settings/presentation/providers/settings_provider.dart';
import 'package:inkscroller_flutter/features/settings/presentation/widgets/account_section.dart';
import 'package:inkscroller_flutter/features/settings/presentation/widgets/delete_account_dialog.dart';
import 'package:inkscroller_flutter/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

class _MockAccountCleanupRepository extends Mock
    implements AccountCleanupRepository {}

class _MockSignIn extends Mock implements SignIn {}

class _MockSignUp extends Mock implements SignUp {}

class _MockSignOut extends Mock implements SignOut {}

class _MockGetAuthState extends Mock implements GetAuthState {}

class _MockGetUserProfile extends Mock implements GetUserProfile {}

class _MockUpdateUserProfile extends Mock implements UpdateUserProfile {}

class _MockSendEmailVerification extends Mock implements SendEmailVerification {}

class _MockSendPasswordReset extends Mock implements SendPasswordReset {}

class _MockReloadUser extends Mock implements ReloadUser {}

/// Creates an [AuthNotifier] that starts with a logged-in user.
AuthNotifier _makeLoggedInAuthNotifier() {
  final getAuthState = _MockGetAuthState();
  when(() => getAuthState()).thenAnswer(
    (_) => Stream<AppUser?>.value(
      const AppUser(uid: 'test-uid', email: 'test@test.com'),
    ),
  );

  final getUserProfile = _MockGetUserProfile();
  when(() => getUserProfile()).thenAnswer(
    (_) async => const Left(ServerFailure(message: 'test')),
  );

  return AuthNotifier(
    signIn: _MockSignIn(),
    signUp: _MockSignUp(),
    signOut: _MockSignOut(),
    getAuthState: getAuthState,
    sendEmailVerification: _MockSendEmailVerification(),
    sendPasswordReset: _MockSendPasswordReset(),
    reloadUser: _MockReloadUser(),
    getUserProfile: getUserProfile,
    updateUserProfile: _MockUpdateUserProfile(),
  );
}

/// Builds the test app with a logged-in user and mock settings services.
Widget _buildTestApp({
  required SettingsRepository repo,
  required AccountCleanupRepository cleanup,
}) {
  final router = GoRouter(
    initialLocation: AppRoutes.settings,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, __) => const Scaffold(body: AccountSection()),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const Scaffold(body: Text('Home Page')),
      ),
    ],
  );

  return ProviderScope(
    overrides: <Override>[
      authProvider.overrideWith((_) => _makeLoggedInAuthNotifier()),
      settingsRepositoryProvider.overrideWithValue(repo),
      settingsProvider.overrideWith((ref) {
        return SettingsNotifier(
          repository: repo,
          cleanup: cleanup,
        );
      }),
    ],
    child: MaterialApp.router(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void main() {
  group('AccountSection navigation', () {
    late SettingsRepository repo;
    late _MockAccountCleanupRepository mockCleanup;

    setUp(() {
      repo = _MockSettingsRepository();
      mockCleanup = _MockAccountCleanupRepository();
      when(() => mockCleanup.currentCleanupUserId).thenReturn('uid-1');
      when(
        () => repo.deleteAccount(),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => mockCleanup.cleanUpAfterDeletion(
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => null);
      when(
        () => mockCleanup.hasDeletionCleanupPending(),
      ).thenAnswer((_) async => false);
      when(
        () => mockCleanup.markDeletionCleanupPending(),
      ).thenAnswer((_) async {});
      when(
        () => mockCleanup.clearDeletionCleanupPending(),
      ).thenAnswer((_) async {});
    });

    testWidgets('navigates to /login after successful account deletion', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(repo: repo, cleanup: mockCleanup),
      );
      await tester.pumpAndSettle();

      // AccountSection is visible because user is logged in.
      expect(
        find.byKey(const Key('deleteAccountButton')),
        findsOneWidget,
      );

      // Open the delete dialog.
      await tester.tap(find.byKey(const Key('deleteAccountButton')));
      await tester.pumpAndSettle();

      expect(find.byType(DeleteAccountDialog), findsOneWidget);

      // Type DELETE to enable the confirm button.
      await tester.enterText(find.byType(TextField), 'DELETE');
      await tester.pump();

      // Tap confirm.
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      // Verify navigation to home happened after account deletion.
      expect(find.text('Home Page'), findsOneWidget);
    });

    testWidgets('does not navigate when dialog is cancelled', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(repo: repo, cleanup: mockCleanup),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('deleteAccountButton')));
      await tester.pumpAndSettle();

      // Cancel the dialog.
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      // Should still be on settings page, not on home.
      expect(find.text('Home Page'), findsNothing);
    });
  });
}
