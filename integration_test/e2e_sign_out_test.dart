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

  testWidgets('Sign out returns to guest state', (tester) async {
    // Register the user so we are authenticated.
    await pumpE2EApp(tester);
    await completeSignUp(tester, user);

    // Sign out directly via Firebase.
    await FirebaseAuth.instance.signOut();
    await tester.pump(const Duration(seconds: 3));

    // After sign-out, tap navProfile to trigger auth guard → redirect to /login.
    await tester.tap(find.byKey(const Key('navProfile')));
    await tester.pumpAndSettle();

    // Assert: we're on the login page.
    expect(find.byKey(const Key('signInButton')), findsOneWidget);
    expect(find.byKey(const Key('emailField')), findsOneWidget);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
