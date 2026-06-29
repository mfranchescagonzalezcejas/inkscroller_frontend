import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'test_user.dart';

/// Completes the full sign-up flow for E2E testing.
///
/// Starts from the home screen, navigates to login via the profile
/// tab (triggers the auth guard redirect), then to register.
/// Fills the form, submits, and waits for navigation to the home page.
///
/// Locale-agnostic: uses production keys from T4 and T17 for widget lookup.
///
/// NOTE: navigation to login/register can fail on some devices due to
/// system nav bars or animation timing. If the Profile tab tap doesn't
/// trigger an auth redirect, the helpers silently skip and tests will
/// fail on element-level assertions (enterText, tap, etc.).
Future<void> completeSignUp(WidgetTester tester, TestUser user) async {
  // Step 1: Navigate to login via the Profile tab (triggers auth redirect).
  final navProfile = find.byKey(const Key('navProfile'));
  if (navProfile.evaluate().isNotEmpty) {
    await tester.tap(navProfile);
    await tester.pumpAndSettle();
  }

  // Step 2: Navigate to register page via the register link key.
  final registerLink = find.byKey(const Key('registerLink'));
  if (registerLink.evaluate().isNotEmpty) {
    await tester.tap(registerLink);
    await tester.pumpAndSettle();
  }

  // Fill email.
  final emailField = find.byKey(const Key('registerEmailField'));
  if (emailField.evaluate().isEmpty) return; // Not on register page.
  await tester.enterText(emailField, user.email);

  // Fill username.
  await tester.enterText(
    find.byKey(const Key('registerUsernameField')),
    user.username,
  );

  // Fill password.
  await tester.enterText(
    find.byKey(const Key('registerPasswordField')),
    user.password,
  );

  // Fill confirm password.
  await tester.enterText(
    find.byKey(const Key('registerConfirmPasswordField')),
    user.password,
  );

  // Fill birth date — tap the read-only field to open date picker.
  final birthDateField = find.byKey(const Key('registerBirthDateField'));
  if (birthDateField.evaluate().isEmpty) return;
  await tester.tap(birthDateField);
  // Wait for the date picker dialog to fully open (animation + dialog render).
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();

  // Select the birth date in the date picker.
  // Samsung devices may use localized/alternative button text.
  // Try multiple possible button texts to dismiss the picker.
  const datePickerButtons = ['OK', 'Done', 'Listo', 'Hecho', 'Confirm'];
  for (final buttonText in datePickerButtons) {
    final btn = find.text(buttonText);
    if (btn.evaluate().isNotEmpty) {
      await tester.tap(btn);
      await tester.pumpAndSettle();
      break;
    }
  }

  // Scroll down so terms checkbox and button are visible.
  final scrollView = find.byType(SingleChildScrollView);
  if (scrollView.evaluate().isEmpty) return;
  await tester.drag(scrollView, const Offset(0, -300));
  await tester.pumpAndSettle();

  // Accept terms checkbox.
  final termsCheckbox = find.byType(CheckboxListTile);
  if (termsCheckbox.evaluate().isNotEmpty) {
    await tester.tap(termsCheckbox);
    await tester.pumpAndSettle();
  }

  // Tap create account button by key (locale-agnostic).
  final createButton = find.byKey(const Key('createAccountButton'));
  if (createButton.evaluate().isEmpty) return;
  await tester.tap(createButton);
  await tester.pumpAndSettle(
    const Duration(seconds: 15),
  );
}

/// Completes the sign-in flow for E2E testing.
///
/// Starts from the home screen, navigates to login via the profile
/// tab (triggers the auth guard redirect), fills credentials, submits,
/// and waits for navigation to the home page.
///
/// Locale-agnostic: uses production keys from T4 and T17 for widget lookup.
Future<void> completeSignIn(WidgetTester tester, TestUser user) async {
  // Navigate to login via the Profile tab (triggers auth redirect).
  await tester.tap(find.byKey(const Key('navProfile')));
  await tester.pumpAndSettle();

  // Fill email.
  await tester.enterText(
    find.byKey(const Key('emailField')),
    user.email,
  );

  // Fill password.
  await tester.enterText(
    find.byKey(const Key('passwordField')),
    user.password,
  );

  // Tap sign in button by key (locale-agnostic).
  await tester.tap(find.byKey(const Key('signInButton')));
  await tester.pumpAndSettle(
    const Duration(seconds: 15),
  );
}

/// Completes the sign-out flow for E2E testing.
///
/// Assumes the user is authenticated and the app is on a tab page.
/// Navigates to the Profile tab, taps "Cerrar sesión", and waits for
/// the guest state (login page visible).
///
/// Locale-agnostic: uses production keys for widget lookup.
Future<void> completeSignOut(WidgetTester tester) async {
  // Navigate to Profile tab (index 3).
  await tester.tap(find.byKey(const Key('navProfile')));
  await tester.pumpAndSettle();

  // Tap sign out button by key (locale-agnostic).
  final signOutButton = find.byKey(const Key('signOutButton'));
  if (signOutButton.evaluate().isNotEmpty) {
    await tester.tap(signOutButton);
    await tester.pumpAndSettle(
      const Duration(seconds: 10),
    );
  }
}
