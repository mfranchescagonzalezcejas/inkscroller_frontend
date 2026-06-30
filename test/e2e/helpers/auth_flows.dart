import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_user.dart';

/// Closes the soft keyboard and dismisses any overlay (snackbar, error banner,
/// dialog) that might intercept tap() calls in integration tests on physical
/// devices.
Future<void> _closeOverlaysAndKeyboard(WidgetTester tester) async {
  SystemChannels.textInput.invokeMethod('TextInput.hide');
  await tester.pump(const Duration(milliseconds: 300));
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await tester.pumpAndSettle();
}

/// Sets the text of a read-only [AuthField] by accessing the [EditableText]
/// controller directly. `enterText` does not work on readOnly fields in
/// integration tests because the platform text input is suppressed.
Future<void> _setReadOnlyFieldText(
  WidgetTester tester,
  Finder fieldFinder,
  String text,
) async {
  final editableFinder = find.descendant(
    of: fieldFinder,
    matching: find.byType(EditableText),
  );
  if (editableFinder.evaluate().isNotEmpty) {
    final editable = tester.widget<EditableText>(editableFinder.first);
    editable.controller.text = text;
    await tester.pump();
  }
}

/// Completes the full sign-up flow for E2E testing.
///
/// Starts from the home screen, navigates to login via the profile tab
/// (triggers the auth guard redirect), then to register. Fills the form,
/// submits, and waits for navigation to the home page.
///
/// Locale-agnostic: uses production keys from T4 for reliable widget lookup.
Future<void> completeSignUp(WidgetTester tester, TestUser user) async {
  // Step 1: Navigate to login via the Profile tab (triggers auth redirect).
  await tester.tap(find.byKey(const Key('navProfile')));
  await tester.pumpAndSettle();

  // Step 2: Navigate to register page via the register link key.
  await tester.tap(find.byKey(const Key('registerLink')));
  await tester.pumpAndSettle();

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

  // Set birth date — the field is readOnly so enterText doesn't work.
  // Access the EditableText controller directly.
  final now = DateTime.now();
  final birthDate = DateTime(now.year - 20, now.month, now.day);
  final formattedDate =
      '${birthDate.year}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}';
  await _setReadOnlyFieldText(
    tester,
    find.byKey(const Key('registerBirthDateField')),
    formattedDate,
  );

  // Close keyboard and any overlays before scrolling and tapping.
  await _closeOverlaysAndKeyboard(tester);

  // Scroll down so terms checkbox and button are visible.
  final scrollView = find.byType(SingleChildScrollView);
  if (scrollView.evaluate().isNotEmpty) {
    await tester.drag(scrollView.first, const Offset(0, -300));
    await tester.pumpAndSettle();
  }

  // Accept terms checkbox.
  final termsCheckbox = find.byType(CheckboxListTile);
  if (termsCheckbox.evaluate().isNotEmpty) {
    await tester.tap(termsCheckbox.first, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  // Tap create account button by key (locale-agnostic).
  await tester.tap(
    find.byKey(const Key('createAccountButton')),
    warnIfMissed: false,
  );
  await tester.pumpAndSettle(const Duration(seconds: 15));
}

/// Completes the sign-in flow for E2E testing.
///
/// Starts from the home screen, navigates to login via the profile tab
/// (triggers the auth guard redirect), fills credentials, submits, and
/// waits for navigation to the home page.
///
/// Locale-agnostic: uses production keys for reliable widget lookup.
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

  // Close keyboard before tapping the button.
  await _closeOverlaysAndKeyboard(tester);

  // Tap sign in button by key (locale-agnostic).
  await tester.tap(
    find.byKey(const Key('signInButton')),
    warnIfMissed: false,
  );
  await tester.pumpAndSettle(const Duration(seconds: 15));
}

/// Completes the sign-out flow for E2E testing.
///
/// Assumes the user is authenticated and the app is on a tab page.
/// Navigates to the Profile tab, taps the sign out button, and waits for
/// the guest state (login page or guest home visible).
///
/// Locale-agnostic: uses production keys for reliable widget lookup.
Future<void> completeSignOut(WidgetTester tester) async {
  // Navigate to Profile tab (index 3).
  await tester.tap(find.byKey(const Key('navProfile')));
  await tester.pumpAndSettle();

  // Tap sign out button by key (locale-agnostic).
  await tester.tap(
    find.byKey(const Key('signOutButton')),
    warnIfMissed: false,
  );
  await tester.pumpAndSettle(const Duration(seconds: 10));
}