import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_user.dart';

/// Completes the full sign-up flow for E2E testing.
///
/// Assumes the app is already launched and on the login page.
/// Navigates to register, fills the form, submits, and waits
/// for navigation to the home page.
///
/// Uses production keys from T4 for reliable widget lookup.
Future<void> completeSignUp(WidgetTester tester, TestUser user) async {
  // Navigate to register page.
  final createAccountLink = find.text("Don't have an account? Create one");
  if (createAccountLink.evaluate().isNotEmpty) {
    await tester.tap(createAccountLink);
    await tester.pumpAndSettle();
  }

  // Fill email.
  await tester.enterText(
    find.byKey(const Key('registerEmailField')),
    user.email,
  );

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
  await tester.tap(find.byKey(const Key('registerBirthDateField')));
  await tester.pumpAndSettle();

  // Select the birth date in the date picker.
  // The date picker defaults to 18 years ago; we need ~20 years ago.
  // Tap "OK" to confirm the default or selected date.
  final okButton = find.text('OK');
  if (okButton.evaluate().isNotEmpty) {
    await tester.tap(okButton);
    await tester.pumpAndSettle();
  }

  // Accept terms checkbox.
  final termsCheckbox = find.byType(CheckboxListTile);
  if (termsCheckbox.evaluate().isNotEmpty) {
    await tester.tap(termsCheckbox);
    await tester.pumpAndSettle();
  }

  // Tap "Create account" button.
  await tester.tap(find.text('Create account'));
  await tester.pumpAndSettle(
    const Duration(seconds: 15),
  );
}

/// Completes the sign-in flow for E2E testing.
///
/// Assumes the app is already launched and on the login page.
/// Fills credentials, submits, and waits for navigation to the home page.
Future<void> completeSignIn(WidgetTester tester, TestUser user) async {
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

  // Tap "Sign in" button.
  await tester.tap(find.text('Sign in'));
  await tester.pumpAndSettle(
    const Duration(seconds: 15),
  );
}

/// Completes the sign-out flow for E2E testing.
///
/// Assumes the user is authenticated and the app is on a tab page.
/// Navigates to the Profile tab, taps "Sign out", and waits for
/// the guest state (login page visible).
Future<void> completeSignOut(WidgetTester tester) async {
  // Navigate to Profile tab (index 3).
  // The bottom nav has a "Profile" label.
  final profileTab = find.text('Profile');
  if (profileTab.evaluate().isNotEmpty) {
    await tester.tap(profileTab);
    await tester.pumpAndSettle();
  }

  // Tap "Sign out" button.
  final signOutButton = find.text('Sign out');
  if (signOutButton.evaluate().isNotEmpty) {
    await tester.tap(signOutButton);
    await tester.pumpAndSettle(
      const Duration(seconds: 10),
    );
  }
}
