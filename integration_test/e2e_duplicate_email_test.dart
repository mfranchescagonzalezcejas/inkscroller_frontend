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

  testWidgets('Sign up with duplicate email shows error', (tester) async {
    // Register the user first so the email already exists.
    await pumpE2EApp(tester);
    await completeSignUp(tester, user);

    // Sign out directly via Firebase.
    await FirebaseAuth.instance.signOut();
    // Pump enough for auth state to propagate and SnackBar to expire.
    await tester.pump(const Duration(seconds: 8));

    // Tap navProfile to trigger auth guard → redirect to /login.
    await tester.tap(find.byKey(const Key('navProfile')));
    await tester.pumpAndSettle(const Duration(seconds: 10));

    // Navigate to register page via the key.
    await tester.tap(find.byKey(const Key('registerLink')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1200));

    // Fill the registration form with the same email (shared helper).
    await fillRegistrationForm(tester, user);

    // Submit the form.
    await tester.tap(
      find.byKey(const Key('createAccountButton')),
      warnIfMissed: false,
    );
    // Don't use pumpAndSettle — gradient/shimmer animations prevent settling.
    // Pump for 15s in small increments to let registration attempt + error finish.
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      // Look for the error SnackBar text.
      if (find.textContaining('email').evaluate().isNotEmpty) break;
    }

    // Assert: error message about duplicate email is visible.
    expect(find.textContaining('email'), findsWidgets);

    // Assert: still on the register page.
    expect(find.byKey(const Key('registerEmailField')), findsOneWidget);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
