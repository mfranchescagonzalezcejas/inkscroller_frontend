import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inkscroller_flutter/core/router/app_routes.dart';
import 'package:inkscroller_flutter/features/auth/domain/entities/app_user.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/get_auth_state.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_in.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_out.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_up.dart';
import 'package:inkscroller_flutter/features/auth/presentation/pages/register_page.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_notifier.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_state.dart';
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

class _RecordingAuthNotifier extends AuthNotifier {
  int signUpCalls = 0;
  int completeProfileCalls = 0;
  String? completedUsername;
  DateTime? completedBirthDate;
  final bool initialSignUpFirebaseFails;

  _RecordingAuthNotifier({
    required bool profileCompletionPending,
    this.initialSignUpFirebaseFails = false,
  }) : super(
         signIn: _MockSignIn(),
         signUp: _MockSignUp(),
         signOut: _MockSignOut(),
         getAuthState: _emptyAuthState(),
         getUserProfile: _MockGetUserProfile(),
         updateUserProfile: _MockUpdateUserProfile(),
       ) {
    state = AuthState(profileCompletionPending: profileCompletionPending);
  }

  static GetAuthState _emptyAuthState() {
    final getAuthState = _MockGetAuthState();
    when(
      () => getAuthState(),
    ).thenAnswer((_) => const Stream<AppUser?>.empty());
    return getAuthState;
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required DateTime birthDate,
  }) async {
    signUpCalls++;
    state = state.copyWith(isLoading: true, registrationInProgress: true);
    await Future<void>.delayed(Duration.zero);

    if (initialSignUpFirebaseFails) {
      state = state.copyWith(
        isLoading: false,
        error: 'Firebase sign-up failed',
        registrationInProgress: false,
      );
      return;
    }

    state = state.copyWith(
      user: const AppUser(uid: 'user-1', email: 'alice@example.com'),
      isLoading: false,
      clearError: true,
      profileCompletionPending: false,
      registrationInProgress: false,
    );
  }

  @override
  Future<void> completeProfile({
    required String username,
    required DateTime birthDate,
  }) async {
    completeProfileCalls++;
    completedUsername = username;
    completedBirthDate = birthDate;
    state = state.copyWith(clearError: true, profileCompletionPending: false);
  }
}

void main() {
  Future<void> pumpRegisterPage(
    WidgetTester tester,
    _RecordingAuthNotifier notifier,
  ) {
    final router = GoRouter(
      initialLocation: AppRoutes.register,
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.register,
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const Text('Login'),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const Text('Home'),
        ),
      ],
    );

    return tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[authProvider.overrideWith((_) => notifier)],
        child: MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
  }

  Finder authField(String label) {
    return find.ancestor(
      of: find.text(label),
      matching: find.byType(TextFormField),
    );
  }

  Future<DateTime> selectDefaultBirthDate(WidgetTester tester) async {
    final now = DateTime.now();
    final selectedDate = DateTime(now.year - 18, now.month, now.day);

    await tester.tap(authField('Birth date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    return selectedDate;
  }

  Future<void> fillInitialRegistrationForm(
    WidgetTester tester, {
    String password = 's3cr3t',
    String confirmPassword = 's3cr3t',
    bool acceptTerms = true,
  }) async {
    await tester.enterText(authField('Email'), 'alice@example.com');
    await tester.enterText(authField('Username'), 'alice_02');
    await tester.enterText(authField('Password'), password);
    await tester.enterText(authField('Confirm password'), confirmPassword);
    await selectDefaultBirthDate(tester);
    if (acceptTerms) {
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
    }
  }

  Future<void> submitCreateAccount(WidgetTester tester) async {
    final createAccountButton = find.text('Create account').last;
    await tester.ensureVisible(createAccountButton);
    await tester.tap(createAccountButton);
  }

  testWidgets('successful initial sign-up navigates to home', (tester) async {
    final notifier = _RecordingAuthNotifier(profileCompletionPending: false);

    await pumpRegisterPage(tester, notifier);

    await fillInitialRegistrationForm(tester);
    await submitCreateAccount(tester);
    await tester.pumpAndSettle();

    expect(notifier.signUpCalls, 1);
    expect(notifier.completeProfileCalls, 0);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Email'), findsNothing);
  });

  testWidgets('birth date field is picker-owned and read-only', (tester) async {
    final notifier = _RecordingAuthNotifier(profileCompletionPending: false);

    await pumpRegisterPage(tester, notifier);

    final birthDateField = find.descendant(
      of: authField('Birth date'),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(birthDateField).readOnly, isTrue);
  });

  testWidgets('Firebase sign-up failure stays on the registration form', (
    tester,
  ) async {
    final notifier = _RecordingAuthNotifier(
      profileCompletionPending: false,
      initialSignUpFirebaseFails: true,
    );

    await pumpRegisterPage(tester, notifier);

    await fillInitialRegistrationForm(tester);
    await submitCreateAccount(tester);
    await tester.pumpAndSettle();

    expect(notifier.signUpCalls, 1);
    expect(notifier.completeProfileCalls, 0);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Complete your profile'), findsNothing);
    expect(find.text('Home'), findsNothing);
  });

  testWidgets('terms acknowledgement is required before submission', (
    tester,
  ) async {
    final notifier = _RecordingAuthNotifier(profileCompletionPending: false);

    await pumpRegisterPage(tester, notifier);

    await fillInitialRegistrationForm(tester, acceptTerms: false);
    await submitCreateAccount(tester);
    await tester.pump();

    expect(notifier.signUpCalls, 0);
    expect(
      find.text('You must agree to the Terms and Privacy Policy.'),
      findsOneWidget,
    );
  });

  testWidgets('confirm-password mismatch blocks submission', (tester) async {
    final notifier = _RecordingAuthNotifier(profileCompletionPending: false);

    await pumpRegisterPage(tester, notifier);

    await fillInitialRegistrationForm(tester, confirmPassword: 'different');
    await submitCreateAccount(tester);
    await tester.pump();

    expect(notifier.signUpCalls, 0);
    expect(find.text('Passwords do not match.'), findsOneWidget);
  });
}
