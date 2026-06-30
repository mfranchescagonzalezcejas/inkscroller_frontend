// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_user.dart';

// ---------------------------------------------------------------------------
// Human-like timing constants
// ---------------------------------------------------------------------------

/// Delay between individual keystrokes when typing into a field.
const Duration _kTypingDelay = Duration(milliseconds: 50);

/// Pause between focus and start of typing (human looks at the field).
const Duration _kPreTypeDelay = Duration(milliseconds: 300);

/// Pause after finishing typing in a field (human reads what they typed).
const Duration _kPostTypeDelay = Duration(milliseconds: 500);

/// Scroll offset for navigating long forms (registers page terms checkbox,
/// settings page delete button). Matches typical mobile scroll distance.
const Offset _kScrollOffset = Offset(0, -300);

/// Pause between a tap and the next interaction (human sees the effect).
const Duration _kTapDelay = Duration(milliseconds: 600);

/// Pause after opening a new page (human orients themselves).
const Duration _kPageLoadDelay = Duration(milliseconds: 1200);

/// Pause after closing overlays / keyboard (human waits for UI to settle).
const Duration _kOverlayDelay = Duration(milliseconds: 800);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Closes the soft keyboard and dismisses any overlay (snackbar, error banner,
/// dialog) that might intercept tap() calls in integration tests on physical
/// devices.
Future<void> _closeOverlaysAndKeyboard(WidgetTester tester) async {
  await SystemChannels.textInput.invokeMethod('TextInput.hide');
  await tester.pump(_kOverlayDelay);
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await tester.pumpAndSettle();
  // Extra settle time for animation to finish.
  await tester.pump(_kOverlayDelay);
}

/// Types [text] character by character into the field found by [fieldFinder],
/// with a small delay between each keystroke to simulate human typing speed.
///
/// This is NOT used for readOnly fields — see [_setReadOnlyFieldText] for those.
Future<void> _typeTextHuman(
  WidgetTester tester,
  Finder fieldFinder,
  String text,
) async {
  // Human pauses before typing (looks at the field).
  await tester.pump(_kPreTypeDelay);
  await tester.enterText(fieldFinder, text);
  // Simulate typing delay by pumping per character.
  for (var i = 0; i < text.length; i++) {
    await tester.pump(_kTypingDelay);
  }
  // Human pauses after finishing typing (reads what they typed).
  await tester.pump(_kPostTypeDelay);
}

/// Sets the text of a read-only [AuthField] by accessing the [EditableText]
/// controller directly. `enterText` does not work on readOnly fields in
/// integration tests because the platform text input is suppressed.
///
/// Includes a short settle delay to mimic human interaction speed.
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
    // Human pauses before setting date (picker interaction simulation).
    await tester.pump(_kPreTypeDelay);
    editable.controller.text = text;
    await tester.pump(_kPostTypeDelay);
  }
}

/// Human-like tap with a pause before and after the tap.
Future<void> _tapHuman(
  WidgetTester tester,
  Finder finder, {
  bool warnIfMissed = true,
}) async {
  await tester.pump(_kTapDelay);
  await tester.tap(finder, warnIfMissed: warnIfMissed);
  await tester.pump(_kTapDelay);
}

/// Human-like scroll — slower, with a small pause after.
Future<void> _scrollHuman(
  WidgetTester tester,
  Finder scrollable,
  Offset offset,
) async {
  await tester.pump(_kTapDelay);
  await tester.drag(scrollable, offset);
  await tester.pumpAndSettle();
  await tester.pump(_kPostTypeDelay);
}

// ---------------------------------------------------------------------------
// Public flows
// ---------------------------------------------------------------------------

/// Fills the registration form fields for E2E testing.
///
/// Assumes the test is already on the register page. Fills email, username,
/// password, confirm password, birth date (readOnly workaround), scrolls
/// down, and accepts the terms checkbox. Does NOT tap the create account
/// button — the caller is responsible for submitting.
///
/// Locale-agnostic: uses production keys for reliable widget lookup.
Future<void> fillRegistrationForm(WidgetTester tester, TestUser user) async {
  // Fill email — human types into field.
  await _typeTextHuman(
    tester,
    find.byKey(const Key('registerEmailField')),
    user.email,
  );

  // Fill username.
  await _typeTextHuman(
    tester,
    find.byKey(const Key('registerUsernameField')),
    user.username,
  );

  // Fill password.
  await _typeTextHuman(
    tester,
    find.byKey(const Key('registerPasswordField')),
    user.password,
  );

  // Fill confirm password.
  await _typeTextHuman(
    tester,
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
    await _scrollHuman(tester, scrollView.first, _kScrollOffset);
  }

  // Accept terms checkbox.
  final termsCheckbox = find.byType(CheckboxListTile);
  if (termsCheckbox.evaluate().isNotEmpty) {
    await _tapHuman(tester, termsCheckbox.first, warnIfMissed: false);
    await tester.pumpAndSettle();
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
  print('[completeSignUp] Starting with user: ${user.email}');
  // Wait for nav bar to appear — on physical devices the app may take
  // variable time to initialize after pumpE2EApp. Use pump() instead of
  // pumpAndSettle() because shimmer/gradient animations never settle.
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (find.byKey(const Key('navProfile')).evaluate().isNotEmpty) {
      print('[completeSignUp] navProfile found after ${(i + 1) * 0.5}s');
      break;
    }
  }
  final navVisible = find.byKey(const Key('navProfile')).evaluate().isNotEmpty;
  print('[completeSignUp] navProfile visible=$navVisible');
  
  if (navVisible) {
    // Step 1: Navigate to login via the Profile tab (triggers auth redirect).
    await _tapHuman(tester, find.byKey(const Key('navProfile')));
    await tester.pumpAndSettle();
    await tester.pump(_kPageLoadDelay);
  } else {
    // The app may have landed on the login page directly (e.g., after a
    // prior test deleted the account). Check if we're already there.
    final onLogin = find.byKey(const Key('emailField')).evaluate().isNotEmpty;
    print('[completeSignUp] fallback: onLogin=$onLogin');
    if (!onLogin) {
      throw StateError(
        'completeSignUp: navProfile not found and not on login page',
      );
    }
    // Already on login page — proceed directly to register.
    await tester.pump(_kPageLoadDelay);
  }

  // Check if we're on login page.
  final onLogin =
      find.byKey(const Key('emailField')).evaluate().isNotEmpty;
  final onRegister =
      find.byKey(const Key('registerLink')).evaluate().isNotEmpty;
  print('[completeSignUp] After navProfile — onLogin=$onLogin onRegister=$onRegister');

  // Step 2: Navigate to register page via the register link key.
  await _tapHuman(tester, find.byKey(const Key('registerLink')));
  await tester.pumpAndSettle();
  await tester.pump(_kPageLoadDelay);

  // Fill the registration form.
  await fillRegistrationForm(tester, user);

  // Tap create account button by key (locale-agnostic).
  await _tapHuman(
    tester,
    find.byKey(const Key('createAccountButton')),
    warnIfMissed: false,
  );
  // Don't use pumpAndSettle — gradient/shimmer animations never settle.
  // Pump for 20s in small increments to let registration + navigation finish.
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (find.byKey(const Key('navProfile')).evaluate().isNotEmpty) break;
  }
  // Wait for navigation + profile sync.
  await tester.pump(_kPageLoadDelay);

  // Retry loop: the registration flow may take variable time on physical
  // devices. Poll until navProfile appears or we exhaust retries.
  for (var attempt = 0; attempt < 5; attempt++) {
    final navFound = find.byKey(const Key('navProfile')).evaluate().isNotEmpty;
    final createFound =
        find.byKey(const Key('createAccountButton')).evaluate().isNotEmpty;
    print(
      '[completeSignUp] attempt=$attempt nav=$navFound create=$createFound',
    );
    if (navFound) break;
    // If still on register page, the tap may not have registered.
    // Try tapping the button again.
    if (createFound) {
      print('[completeSignUp] retrying tap on createAccountButton');
      await _tapHuman(
        tester,
        find.byKey(const Key('createAccountButton')),
        warnIfMissed: false,
      );
    }
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }
}

/// Completes the sign-in flow for E2E testing.
///
/// Starts from the home screen, navigates to login via the profile tab
/// (triggers the auth guard redirect), fills credentials, submits, and
/// waits for navigation to the home page.
///
/// Locale-agnostic: uses production keys for reliable widget lookup.
Future<void> completeSignIn(WidgetTester tester, TestUser user) async {
  // If we're not already on the login page, navigate there via Profile tab.
  if (find.byKey(const Key('emailField')).evaluate().isEmpty) {
    // Wait for nav bar to appear.
    for (var i = 0; i < 20; i++) {
      if (find.byKey(const Key('navProfile')).evaluate().isNotEmpty) break;
      await tester.pump(const Duration(milliseconds: 500));
    }
    await _tapHuman(tester, find.byKey(const Key('navProfile')));
    await tester.pumpAndSettle();
    await tester.pump(_kPageLoadDelay);
  }

  // Fill email.
  await _typeTextHuman(
    tester,
    find.byKey(const Key('emailField')),
    user.email,
  );

  // Fill password.
  await _typeTextHuman(
    tester,
    find.byKey(const Key('passwordField')),
    user.password,
  );

  // Close keyboard before tapping the button.
  await _closeOverlaysAndKeyboard(tester);

  // Tap sign in button by key (locale-agnostic).
  await _tapHuman(
    tester,
    find.byKey(const Key('signInButton')),
    warnIfMissed: false,
  );
  // Don't use pumpAndSettle — gradient/shimmer animations never settle.
  // Pump for 15s total in small increments to let auth + navigation finish.
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (find.byKey(const Key('navProfile')).evaluate().isNotEmpty) break;
  }
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
  await _tapHuman(tester, find.byKey(const Key('navProfile')));
  await tester.pumpAndSettle();
  await tester.pump(_kPageLoadDelay);

  // Tap sign out button by key (locale-agnostic).
  await _tapHuman(
    tester,
    find.byKey(const Key('signOutButton')),
    warnIfMissed: false,
  );
  // Don't use pumpAndSettle — SnackBar + gradient animations prevent settling.
  // Pump for 15s in small increments to let sign-out + redirect complete.
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    // After sign-out, the login page should appear (emailField on login).
    if (find.byKey(const Key('signInButton')).evaluate().isNotEmpty) break;
    // Or guest home if no redirect.
    if (find.byKey(const Key('navProfile')).evaluate().isNotEmpty) break;
  }
  await tester.pump(_kPageLoadDelay);
}

/// Navigates from any authenticated tab to the delete account dialog.
///
/// Handles profile tab → settings → scroll to delete button → tap → wait
/// for dialog animation. Assumes the user is authenticated and the app
/// shows the bottom nav bar.
Future<void> openDeleteDialog(WidgetTester tester) async {
  // Navigate to Profile via the nav bar.
  await _tapHuman(tester, find.byKey(const Key('navProfile')));
  await tester.pumpAndSettle();
  await tester.pump(_kPageLoadDelay);

  // Check if we're on the profile page.
  final onProfile =
      find.byKey(const Key('settingsButton')).evaluate().isNotEmpty;
  if (!onProfile) {
    // Maybe we're on login (auth guard). Try again after settle.
    await tester.pumpAndSettle();
  }

  // Tap settings icon on the profile page.
  await _tapHuman(
    tester,
    find.byKey(const Key('settingsButton')),
    warnIfMissed: false,
  );
  await tester.pumpAndSettle();
  await tester.pump(_kPageLoadDelay);

  // Scroll to make deleteAccountButton visible and tappable.
  final deleteBtnFinder = find.byKey(const Key('deleteAccountButton'));
  if (deleteBtnFinder.evaluate().isEmpty) {
    final scrollable = find.byType(Scrollable).last;
    for (var i = 0; i < 5; i++) {
      await tester.drag(scrollable, _kScrollOffset);
      await tester.pumpAndSettle();
      if (deleteBtnFinder.evaluate().isNotEmpty) break;
    }
  }
  await tester.scrollUntilVisible(
    deleteBtnFinder.first,
    -100,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();

  // Close any overlays/snackbars that might intercept the tap.
  await _closeOverlaysAndKeyboard(tester);

  // Tap "Eliminar cuenta" to open the dialog.
  await _tapHuman(tester, deleteBtnFinder.first, warnIfMissed: false);
  // Pump multiple times to let the dialog animation complete.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (find.byKey(const Key('deleteConfirmField')).evaluate().isNotEmpty) break;
  }
}

/// Deletes the authenticated user's account via the profile page.
///
/// Assumes the user is authenticated and the app is on a tab page.
/// Navigates to Profile, opens the delete dialog, types the email, confirms,
/// and waits for navigation back to the home page.
Future<void> completeDeleteAccount(
  WidgetTester tester,
  TestUser user,
) async {
  // Navigate to Profile tab.
  await _tapHuman(tester, find.byKey(const Key('navProfile')));
  await tester.pumpAndSettle();
  await tester.pump(_kPageLoadDelay);

  // Tap delete account button.
  await _tapHuman(
    tester,
    find.byKey(const Key('deleteAccountButton')),
    warnIfMissed: false,
  );
  await tester.pumpAndSettle();
  await tester.pump(_kTapDelay);

  // Type 'DELETE' to confirm deletion (dialog checks for this exact string).
  await _typeTextHuman(
    tester,
    find.byKey(const Key('deleteConfirmField')),
    'DELETE',
  );

  // Close keyboard.
  await _closeOverlaysAndKeyboard(tester);

  // Tap confirm delete.
  await _tapHuman(
    tester,
    find.byKey(const Key('deleteConfirmButton')),
    warnIfMissed: false,
  );
  // Don't use pumpAndSettle — SnackBar + gradient animations prevent settling.
  // Pump for 15s in small increments to let delete + redirect complete.
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (find.byKey(const Key('navProfile')).evaluate().isNotEmpty) break;
  }
  await tester.pump(_kPageLoadDelay);
}
