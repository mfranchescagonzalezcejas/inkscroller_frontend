import 'dart:async';

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
import 'package:inkscroller_flutter/features/profile/domain/usecases/update_user_profile.dart';
import 'package:inkscroller_flutter/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockSignIn extends Mock implements SignIn {}

class _MockSignUp extends Mock implements SignUp {}

class _MockSignOut extends Mock implements SignOut {}

class _MockGetAuthState extends Mock implements GetAuthState {}

class _MockUpdateUserProfile extends Mock implements UpdateUserProfile {}

class _RecordingAuthNotifier extends AuthNotifier {
  int signUpCalls = 0;
  int completeProfileCalls = 0;
  String? completedUsername;
  DateTime? completedBirthDate;
  final bool completeProfileSucceeds;
  final bool initialSignUpFirebaseFails;
  final bool initialSignUpProfileFails;
  final Completer<void>? signUpGate;

  _RecordingAuthNotifier({
    required bool profileCompletionPending,
    this.completeProfileSucceeds = true,
    this.initialSignUpFirebaseFails = false,
    this.initialSignUpProfileFails = false,
    this.signUpGate,
  }) : super(
         signIn: _MockSignIn(),
         signUp: _MockSignUp(),
         signOut: _MockSignOut(),
         getAuthState: _emptyAuthState(),
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
    await (signUpGate?.future ?? Future<void>.delayed(Duration.zero));

    if (initialSignUpFirebaseFails) {
      state = state.copyWith(
        isLoading: false,
        error: 'Firebase sign-up failed',
        registrationInProgress: false,
      );
      return;
    }

    if (!initialSignUpProfileFails) {
      state = state.copyWith(
        user: const AppUser(uid: 'user-1', email: 'alice@example.com'),
        isLoading: false,
        clearError: true,
        profileCompletionPending: false,
        registrationInProgress: false,
      );
      return;
    }

    state = state.copyWith(
      user: const AppUser(uid: 'user-1', email: 'alice@example.com'),
      isLoading: false,
      error: 'Profile update failed',
      profileCompletionPending: true,
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
    state = completeProfileSucceeds
        ? state.copyWith(clearError: true, profileCompletionPending: false)
        : state.copyWith(
            error: 'Profile update failed',
            profileCompletionPending: true,
          );
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

  testWidgets('in-flight registration blocks secondary navigation', (
    tester,
  ) async {
    final signUpGate = Completer<void>();
    final notifier = _RecordingAuthNotifier(
      profileCompletionPending: false,
      initialSignUpProfileFails: true,
      signUpGate: signUpGate,
    );

    await pumpRegisterPage(tester, notifier);

    await tester.enterText(authField('Email'), 'alice@example.com');
    await tester.enterText(authField('Username'), 'alice_02');
    await tester.enterText(authField('Password'), 's3cr3t');
    await tester.enterText(authField('Confirm password'), 's3cr3t');
    await tester.enterText(authField('Birth date'), '2001-02-03');
    await tester.tap(find.byType(CheckboxListTile));
    final createAccountButton = find.text('Create account').last;
    await tester.ensureVisible(createAccountButton);
    await tester.tap(createAccountButton);
    await tester.pump();

    expect(notifier.signUpCalls, 1);
    expect(notifier.state.isLoading, isTrue);
    expect(notifier.state.registrationInProgress, isTrue);
    final backButton = find.ancestor(
      of: find.byIcon(Icons.arrow_back),
      matching: find.byType(IconButton),
    );
    expect(tester.widget<IconButton>(backButton).onPressed, isNull);
    expect(
      tester
          .widget<TextButton>(
            find.widgetWithText(TextButton, 'Already have an account? Sign in'),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextButton>(
            find.widgetWithText(TextButton, 'Continue as guest'),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.widgetWithText(TextButton, 'Continue as guest'));
    await tester.tap(
      find.widgetWithText(TextButton, 'Already have an account? Sign in'),
    );
    await tester.ensureVisible(backButton);
    await tester.tap(backButton);
    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.text('Home'), findsNothing);
    expect(find.text('Login'), findsNothing);
    expect(find.text('Create account'), findsOneWidget);

    signUpGate.complete();
    await tester.pumpAndSettle();

    expect(find.text('Complete your profile'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    expect(find.text('Login'), findsNothing);
    expect(find.text('Continue as guest'), findsNothing);
  });

  testWidgets('successful initial sign-up navigates to home', (tester) async {
    final notifier = _RecordingAuthNotifier(profileCompletionPending: false);

    await pumpRegisterPage(tester, notifier);

    await tester.enterText(authField('Email'), 'alice@example.com');
    await tester.enterText(authField('Username'), 'alice_02');
    await tester.enterText(authField('Password'), 's3cr3t');
    await tester.enterText(authField('Confirm password'), 's3cr3t');
    await tester.enterText(authField('Birth date'), '2001-02-03');
    await tester.tap(find.byType(CheckboxListTile));
    final createAccountButton = find.text('Create account').last;
    await tester.ensureVisible(createAccountButton);
    await tester.tap(createAccountButton);
    await tester.pumpAndSettle();

    expect(notifier.signUpCalls, 1);
    expect(notifier.completeProfileCalls, 0);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Email'), findsNothing);
  });

  testWidgets('Firebase sign-up failure stays on the registration form', (
    tester,
  ) async {
    final notifier = _RecordingAuthNotifier(
      profileCompletionPending: false,
      initialSignUpFirebaseFails: true,
    );

    await pumpRegisterPage(tester, notifier);

    await tester.enterText(authField('Email'), 'alice@example.com');
    await tester.enterText(authField('Username'), 'alice_02');
    await tester.enterText(authField('Password'), 's3cr3t');
    await tester.enterText(authField('Confirm password'), 's3cr3t');
    await tester.enterText(authField('Birth date'), '2001-02-03');
    await tester.tap(find.byType(CheckboxListTile));
    final createAccountButton = find.text('Create account').last;
    await tester.ensureVisible(createAccountButton);
    await tester.tap(createAccountButton);
    await tester.pumpAndSettle();

    expect(notifier.signUpCalls, 1);
    expect(notifier.completeProfileCalls, 0);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Complete your profile'), findsNothing);
    expect(find.text('Home'), findsNothing);
  });

  testWidgets(
    'profile completion retry submits metadata without retrying Firebase sign-up',
    (tester) async {
      final notifier = _RecordingAuthNotifier(profileCompletionPending: true);

      await pumpRegisterPage(tester, notifier);

      expect(find.text('Complete your profile'), findsOneWidget);
      expect(find.text('Email'), findsNothing);
      expect(find.text('Password'), findsNothing);
      expect(find.text('Continue as guest'), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsNothing);

      await tester.enterText(authField('Username'), 'alice_02');
      await tester.enterText(authField('Birth date'), '2001-02-03');
      await tester.ensureVisible(find.text('Complete profile'));
      await tester.tap(find.text('Complete profile'));
      await tester.pumpAndSettle();

      expect(notifier.signUpCalls, 0);
      expect(notifier.completeProfileCalls, 1);
      expect(notifier.completedUsername, 'alice_02');
      expect(notifier.completedBirthDate, DateTime(2001, 2, 3));
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Complete your profile'), findsNothing);
      expect(find.text('Email'), findsNothing);
      expect(find.text('Continue as guest'), findsNothing);
    },
  );

  testWidgets('profile completion failure keeps the recovery form visible', (
    tester,
  ) async {
    final notifier = _RecordingAuthNotifier(
      profileCompletionPending: true,
      completeProfileSucceeds: false,
    );

    await pumpRegisterPage(tester, notifier);

    await tester.enterText(authField('Username'), 'alice_02');
    await tester.enterText(authField('Birth date'), '2001-02-03');
    await tester.ensureVisible(find.text('Complete profile'));
    await tester.tap(find.text('Complete profile'));
    await tester.pumpAndSettle();

    expect(notifier.signUpCalls, 0);
    expect(notifier.completeProfileCalls, 1);
    expect(find.text('Complete your profile'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    expect(find.text('Email'), findsNothing);
    expect(find.text('Continue as guest'), findsNothing);
  });

  testWidgets(
    'initial sign-up metadata failure shows recovery form instead of home',
    (tester) async {
      final notifier = _RecordingAuthNotifier(
        profileCompletionPending: false,
        initialSignUpProfileFails: true,
      );

      await pumpRegisterPage(tester, notifier);

      await tester.enterText(authField('Email'), 'alice@example.com');
      await tester.enterText(authField('Username'), 'alice_02');
      await tester.enterText(authField('Password'), 's3cr3t');
      await tester.enterText(authField('Confirm password'), 's3cr3t');
      await tester.enterText(authField('Birth date'), '2001-02-03');
      await tester.tap(find.byType(CheckboxListTile));
      final createAccountButton = find.text('Create account').last;
      await tester.ensureVisible(createAccountButton);
      await tester.tap(createAccountButton);
      await tester.pumpAndSettle();

      expect(notifier.signUpCalls, 1);
      expect(notifier.completeProfileCalls, 0);
      expect(find.text('Complete your profile'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
      expect(find.text('Email'), findsNothing);
      expect(find.text('Continue as guest'), findsNothing);

      await tester.enterText(authField('Username'), 'alice_03');
      await tester.enterText(authField('Birth date'), '2001-02-04');
      await tester.ensureVisible(find.text('Complete profile'));
      await tester.tap(find.text('Complete profile'));
      await tester.pumpAndSettle();

      expect(notifier.signUpCalls, 1);
      expect(notifier.completeProfileCalls, 1);
      expect(find.text('Home'), findsOneWidget);
    },
  );
}
