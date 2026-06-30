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
    // Arrange: register the user first so the email already exists,
    // then sign out to return to the login screen.
    await pumpE2EApp(tester);
    await completeSignUp(tester, user);
    await completeSignOut(tester);

    // Navigate to register page via the key.
    await tester.tap(find.byKey(const Key('registerLink')));
    await tester.pumpAndSettle();

    // Act: fill the registration form with the same email.
    await tester.enterText(
      find.byKey(const Key('registerEmailField')),
      user.email,
    );
    await tester.enterText(
      find.byKey(const Key('registerUsernameField')),
      'another_${user.username}',
    );
    await tester.enterText(
      find.byKey(const Key('registerPasswordField')),
      user.password,
    );
    await tester.enterText(
      find.byKey(const Key('registerConfirmPasswordField')),
      user.password,
    );

    // Set birth date via controller (readOnly field workaround).
    final now = DateTime.now();
    final birthDate = DateTime(now.year - 20, now.month, now.day);
    final formattedDate =
        '${birthDate.year}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}';
    final editable = find.descendant(
      of: find.byKey(const Key('registerBirthDateField')),
      matching: find.byType(EditableText),
    );
    if (editable.evaluate().isNotEmpty) {
      tester.widget<EditableText>(editable.first).controller.text =
          formattedDate;
      await tester.pump();
    }

    // Scroll down.
    final scrollView = find.byType(SingleChildScrollView);
    if (scrollView.evaluate().isNotEmpty) {
      await tester.drag(scrollView.first, const Offset(0, -300));
      await tester.pumpAndSettle();
    }

    // Accept terms.
    final termsCheckbox = find.byType(CheckboxListTile);
    if (termsCheckbox.evaluate().isNotEmpty) {
      await tester.tap(termsCheckbox.first, warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    // Submit the form.
    await tester.tap(
      find.byKey(const Key('createAccountButton')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle(const Duration(seconds: 15));

    // Assert: error message about duplicate email is visible.
    // Firebase surfaces "email-already-in-use" which the data source maps to
    // "El email ya está registrado." in Spanish regardless of app locale.
    expect(find.textContaining('email ya está registrado'), findsOneWidget);

    // Assert: still on the register page.
    expect(find.byKey(const Key('registerEmailField')), findsOneWidget);
  });
}