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

  testWidgets('Sign up with duplicate email shows error', (tester) async {
    // Arrange: register the user first so the email already exists,
    // then sign out to return to the login screen.
    await pumpE2EApp(tester);
    await completeSignUp(tester, user);
    await completeSignOut(tester);

    // Navigate to register page.
    final createAccountLink = find.text("Don't have an account? Create one");
    if (createAccountLink.evaluate().isNotEmpty) {
      await tester.tap(createAccountLink);
      await tester.pumpAndSettle();
    }

    // Act: fill the registration form with the same email.
    await tester.enterText(
      find.byKey(const Key('registerEmailField')),
      user.email,
    );
    await tester.enterText(
      find.byKey(const Key('registerUsernameField')),
      user.username,
    );
    await tester.enterText(
      find.byKey(const Key('registerPasswordField')),
      user.password,
    );
    await tester.enterText(
      find.byKey(const Key('registerConfirmPasswordField')),
      user.password,
    );

    // Fill birth date.
    await tester.tap(find.byKey(const Key('registerBirthDateField')));
    await tester.pumpAndSettle();
    final okButton = find.text('OK');
    if (okButton.evaluate().isNotEmpty) {
      await tester.tap(okButton);
      await tester.pumpAndSettle();
    }

    // Accept terms.
    final termsCheckbox = find.byType(CheckboxListTile);
    if (termsCheckbox.evaluate().isNotEmpty) {
      await tester.tap(termsCheckbox);
      await tester.pumpAndSettle();
    }

    // Submit the form.
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle(const Duration(seconds: 15));

    // Assert: error message about duplicate email is visible.
    expect(find.textContaining('email ya está registrado'), findsOneWidget);

    // Assert: still on the register page.
    expect(find.byKey(const Key('registerEmailField')), findsOneWidget);
  });
}
