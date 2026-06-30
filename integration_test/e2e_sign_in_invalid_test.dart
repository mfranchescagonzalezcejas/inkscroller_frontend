// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/e2e/helpers/auth_flows.dart';
import '../test/e2e/helpers/cleanup.dart';
import '../test/e2e/helpers/test_app.dart';
import '../test/e2e/helpers/test_user.dart';

void main() {
  late TestUser user;

  setUp(() {
    user = TestUser.fresh();
  });

  tearDown(() async {
    await deleteTestUser(email: user.email, password: user.password);
  });

  testWidgets('Sign in with wrong password shows error and stays on login',
      (tester) async {
    // Register user so account exists.
    await pumpE2EApp(tester);
    await completeSignUp(tester, user);

    // Sign out directly via Firebase (bypasses SnackBar + provider timing).
    await FirebaseAuth.instance.signOut();
    await tester.pump(const Duration(seconds: 3));

    // After sign-out, app stays on home (public route). Tap navProfile
    // to trigger auth guard → redirect to /login.
    await tester.tap(find.byKey(const Key('navProfile')));
    await tester.pumpAndSettle();

    // We should now be on the login page.
    expect(find.byKey(const Key('emailField')), findsOneWidget);

    // Enter correct email but wrong password.
    await tester.enterText(
      find.byKey(const Key('emailField')),
      user.email,
    );
    await tester.pump(const Duration(milliseconds: 800));

    await tester.enterText(
      find.byKey(const Key('passwordField')),
      'WrongPassword999!',
    );
    await tester.pump(const Duration(milliseconds: 800));

    await tester.tap(
      find.byKey(const Key('signInButton')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle(const Duration(seconds: 15));

    // Assert: error SnackBar is visible (locale-independent).
    // AppFeedback.showError always shows a SnackBar on auth failure.
    expect(find.byType(SnackBar), findsOneWidget);

    // Assert: still on the login page (email field still visible).
    expect(find.byKey(const Key('emailField')), findsOneWidget);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
