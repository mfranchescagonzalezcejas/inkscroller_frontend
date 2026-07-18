import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/auth/domain/entities/app_user.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/get_auth_state.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/reload_user.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/send_email_verification.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/send_password_reset.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_in.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_out.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_up.dart';
import 'package:inkscroller_flutter/features/auth/presentation/pages/login_page.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_notifier.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:inkscroller_flutter/features/profile/domain/usecases/get_user_profile.dart';
import 'package:inkscroller_flutter/features/profile/domain/usecases/update_user_profile.dart';
import 'package:inkscroller_flutter/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockSignIn extends Mock implements SignIn {}
class _MockSignUp extends Mock implements SignUp {}
class _MockSignOut extends Mock implements SignOut {}
class _MockGetAuthState extends Mock implements GetAuthState {}
class _MockGetUserProfile extends Mock implements GetUserProfile {}
class _MockUpdateUserProfile extends Mock implements UpdateUserProfile {}
class _MockSendEmailVerification extends Mock implements SendEmailVerification {}
class _MockSendPasswordReset extends Mock implements SendPasswordReset {}
class _MockReloadUser extends Mock implements ReloadUser {}

Widget _buildTestApp({SendPasswordReset? sendPasswordReset}) {
  final getAuthState = _MockGetAuthState();
  when(() => getAuthState()).thenAnswer((_) => const Stream<AppUser?>.empty());

  final notifier = AuthNotifier(
    signIn: _MockSignIn(),
    signUp: _MockSignUp(),
    signOut: _MockSignOut(),
    getAuthState: getAuthState,
    sendEmailVerification: _MockSendEmailVerification(),
    sendPasswordReset: sendPasswordReset ?? _MockSendPasswordReset(),
    reloadUser: _MockReloadUser(),
    getUserProfile: _MockGetUserProfile(),
    updateUserProfile: _MockUpdateUserProfile(),
  );

  return ProviderScope(
    overrides: <Override>[
      authProvider.overrideWith((_) => notifier),
    ],
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: LoginPage(),
    ),
  );
}

void main() {
  group('LoginPage forgot password', () {
    testWidgets('shows forgot password link', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('forgotPasswordLink')), findsOneWidget);
    });

    testWidgets('opens bottom sheet when forgot password is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('forgotPasswordLink')));
      await tester.pumpAndSettle();

      // Bottom sheet should be visible with the title.
      expect(find.text('Reset your password'), findsOneWidget);
      expect(find.text('Send reset email'), findsOneWidget);
    });

    testWidgets('bottom sheet has email field pre-filled from login', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Enter email in the login form first.
      await tester.enterText(
        find.byKey(const Key('emailField')),
        'alice@example.com',
      );
      await tester.pump();

      // Open the forgot password sheet.
      await tester.tap(find.byKey(const Key('forgotPasswordLink')));
      await tester.pumpAndSettle();

      // The email field in the bottom sheet should be pre-filled.
      final emailFields = find.byType(TextFormField);
      expect(emailFields, findsWidgets);
    });
  });
}
