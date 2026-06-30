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

  testWidgets(
    'Sign in with valid credentials navigates to home',
    (tester) async {
      await pumpE2EApp(tester);
      await completeSignUp(tester, user);

      // Verify we're on home with nav bar.
      expect(find.byKey(const Key('navProfile')), findsOneWidget);

      // Sign out directly via Firebase.
      await FirebaseAuth.instance.signOut();
      // Pump enough for auth state to propagate and SnackBar to expire.
      await tester.pump(const Duration(seconds: 8));

      // Tap navProfile to trigger auth guard → redirect to /login.
      await tester.tap(find.byKey(const Key('navProfile')));
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Verify we're on login page.
      expect(find.byKey(const Key('emailField')), findsOneWidget);

      // Use shared helper to fill credentials, submit, and wait for home.
      await completeSignIn(tester, user);

      // Assert: navigation to home — nav bar should be visible.
      expect(find.byKey(const Key('navProfile')), findsOneWidget);

      // Let any pending async providers (e.g. _hydrateAsync) complete
      // before the test ends, to avoid "ProviderContainer already disposed"
      // errors during teardown.
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
