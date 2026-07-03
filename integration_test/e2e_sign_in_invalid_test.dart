import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/e2e/helpers/auth_flows.dart';
import '../test/e2e/helpers/cleanup.dart';
import '../test/e2e/helpers/test_app.dart';
import '../test/e2e/helpers/test_user.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late TestUser user;

  setUp(() {
    user = TestUser.fresh();
  });

  tearDown(() async {
    await deleteTestUser(email: user.email, password: user.password);
  });

  testWidgets('Sign in with wrong password shows error and stays on login', (
    tester,
  ) async {
    // Arrange: register the user so the account exists, then sign out.
    await pumpE2EApp(tester);
    await completeSignUp(tester, user);
    await completeSignOut(tester);

    // Act: enter correct email but wrong password.
    await tester.enterText(find.byKey(const Key('emailField')), user.email);
    await tester.enterText(
      find.byKey(const Key('passwordField')),
      'WrongPassword999!',
    );

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle(const Duration(seconds: 15));

    // Assert: error message is visible.
    expect(find.textContaining('Credenciales'), findsOneWidget);

    // Assert: still on the login page (email field still visible).
    expect(find.byKey(const Key('emailField')), findsOneWidget);
  });
}
