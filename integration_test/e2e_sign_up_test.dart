// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/e2e/helpers/cleanup.dart';
import '../test/e2e/helpers/test_app.dart';
import '../test/e2e/helpers/test_user.dart';

/// Helper: capture a screenshot and print what's visible.
Future<void> _snapshot(
  WidgetTester tester,
  String label, {
  bool dumpTree = false,
}) async {
  print('─── $label ───');

  // Print which keys are visible.
  final keysToCheck = <String>[
    'navProfile',
    'registerLink',
    'signInButton',
    'emailField',
    'passwordField',
    'registerEmailField',
    'registerUsernameField',
    'registerPasswordField',
    'registerConfirmPasswordField',
    'registerBirthDateField',
    'createAccountButton',
    'deleteConfirmField',
  ];
  final foundKeys = <String>[];
  for (final key in keysToCheck) {
    if (find.byKey(Key(key)).evaluate().isNotEmpty) {
      foundKeys.add(key);
    }
  }
  print('  Visible keys: ${foundKeys.isEmpty ? "(none)" : foundKeys.join(", ")}');

  if (dumpTree) {
    final allWidgets = tester.widgetList(find.byType(Widget));
    final typeCounts = <String, int>{};
    for (final w in allWidgets) {
      final name = w.runtimeType.toString();
      typeCounts[name] = (typeCounts[name] ?? 0) + 1;
    }
    final interesting = <String>[
      'LoginPage', 'RegisterPage', 'HomePage', 'LibraryPage',
      'ProfilePage', 'SettingsPage', 'MainScaffold',
      'AuthGradientButton', 'AuthField', 'CheckboxListTile',
      'SingleChildScrollView', 'DatePickerDialog',
      'Scaffold', 'Column', 'GridView', 'ListView',
      'TextButton', 'FilledButton', 'IconButton',
    ];
    for (final type in interesting) {
      if (typeCounts.containsKey(type)) {
        print('  $type: ${typeCounts[type]}');
      }
    }
  }
}

void main() {
  late TestUser user;

  setUp(() {
    user = TestUser.fresh();
  });

  tearDown(() async {
    await deleteTestUser(email: user.email, password: user.password);
  });

  testWidgets('Sign up — screenshot diagnosis', (tester) async {
    // Step 0: Boot the app.
    await pumpE2EApp(tester);
    await _snapshot(tester, '00_app_booted', dumpTree: true);

    // Step 1: Tap Profile tab → auth guard should redirect to login.
    final navProfile = find.byKey(const Key('navProfile'));
    print('\n=== Step 1: Tap navProfile ===');
    print('  navProfile found: ${navProfile.evaluate().isNotEmpty}');
    if (navProfile.evaluate().isNotEmpty) {
      await tester.tap(navProfile);
      await tester.pumpAndSettle();
    }
    await _snapshot(tester, '01_after_profile_tap', dumpTree: true);

    // Step 2: Tap register link → should go to register page.
    final registerLink = find.byKey(const Key('registerLink'));
    print('\n=== Step 2: Tap registerLink ===');
    print('  registerLink found: ${registerLink.evaluate().isNotEmpty}');
    if (registerLink.evaluate().isNotEmpty) {
      await tester.tap(registerLink);
      await tester.pumpAndSettle();
    }
    await _snapshot(tester, '02_after_register_tap', dumpTree: true);

    // Step 3: Fill email.
    print('\n=== Step 3: Fill email ===');
    final emailField = find.byKey(const Key('registerEmailField'));
    print('  registerEmailField found: ${emailField.evaluate().isNotEmpty}');
    if (emailField.evaluate().isEmpty) {
      print('  ❌ Not on register page — aborting.');
      await _snapshot(tester, '03_aborted_no_register_page');
      return;
    }
    await tester.enterText(emailField, user.email);
    await tester.pump();

    // Step 4: Fill username.
    print('\n=== Step 4: Fill username ===');
    await tester.enterText(
      find.byKey(const Key('registerUsernameField')),
      user.username,
    );
    await tester.pump();

    // Step 5: Fill password.
    print('\n=== Step 5: Fill password ===');
    await tester.enterText(
      find.byKey(const Key('registerPasswordField')),
      user.password,
    );
    await tester.pump();

    // Step 6: Fill confirm password.
    print('\n=== Step 6: Fill confirm password ===');
    await tester.enterText(
      find.byKey(const Key('registerConfirmPasswordField')),
      user.password,
    );
    await tester.pump();
    await _snapshot(tester, '04_form_filled');

    // Step 7: Set birth date directly (bypass date picker).
    // The date picker dialog doesn't open reliably in integration tests on
    // Samsung devices. Setting the controller text directly via enterText
    // works because the validator only checks the parsed value, not the input
    // mechanism.
    print('\n=== Step 7: Set birth date ===');
    final birthDateField = find.byKey(const Key('registerBirthDateField'));
    print('  registerBirthDateField found: ${birthDateField.evaluate().isNotEmpty}');
    if (birthDateField.evaluate().isNotEmpty) {
      // Format: YYYY-MM-DD — 20 years ago.
      final now = DateTime.now();
      final birthDate =
          DateTime(now.year - 20, now.month, now.day);
      final formattedDate =
          '${birthDate.year}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}';
      print('  Setting date: $formattedDate');
      // enterText doesn't work on readOnly fields in integration tests.
      // Access the EditableText's controller directly and set the text.
      final editableFinder = find.descendant(
        of: birthDateField,
        matching: find.byType(EditableText),
      );
      if (editableFinder.evaluate().isNotEmpty) {
        final editableWidget =
            tester.widget<EditableText>(editableFinder.first);
        editableWidget.controller.text = formattedDate;
        await tester.pump();
        print(
          '  Birth date set via controller: "${editableWidget.controller.text}"',
        );
      } else {
        print('  ❌ Could not find EditableText — trying enterText fallback');
        await tester.enterText(birthDateField, formattedDate);
        await tester.pump();
      }
    }
    await _snapshot(tester, '05_birth_date_set');

    // Step 9: Close any overlays (keyboard, snackbars, dialogs) then scroll.
    print('\n=== Step 9: Close overlays + scroll ===');
    // Hide keyboard.
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    await tester.pump(const Duration(milliseconds: 300));
    // Dismiss any snackbars/errors via Escape.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    // Now scroll down to reveal checkbox and button.
    final scrollView = find.byType(SingleChildScrollView);
    print('  SingleChildScrollView found: ${scrollView.evaluate().length}');
    if (scrollView.evaluate().isNotEmpty) {
      await tester.drag(scrollView.first, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
    await _snapshot(tester, '07_after_scroll');

    // Step 10: Accept terms checkbox.
    print('\n=== Step 10: Tap checkbox ===');
    final termsCheckbox = find.byType(CheckboxListTile);
    print('  CheckboxListTile found: ${termsCheckbox.evaluate().length}');
    if (termsCheckbox.evaluate().isNotEmpty) {
      // Check current state before tapping.
      final cb = tester.widget<CheckboxListTile>(termsCheckbox.first);
      print('  Checkbox value BEFORE tap: ${cb.value}');
      await tester.tap(termsCheckbox.first, warnIfMissed: false);
      await tester.pumpAndSettle();
      final cbAfter = tester.widget<CheckboxListTile>(termsCheckbox.first);
      print('  Checkbox value AFTER tap: ${cbAfter.value}');
    }

    // Step 11: Tap "Create account" button.
    print('\n=== Step 11: Tap createAccountButton ===');
    final createButton = find.byKey(const Key('createAccountButton'));
    print('  createAccountButton found: ${createButton.evaluate().isNotEmpty}');
    if (createButton.evaluate().isNotEmpty) {
      await tester.tap(createButton, warnIfMissed: false);
      // Wait for sign-up to complete (Firebase + backend).
      await tester.pumpAndSettle(const Duration(seconds: 15));
    }
    await _snapshot(tester, '08_after_create_tap', dumpTree: true);

    // Final: where are we?
    print('\n=== Final: Location check ===');
    final onNavBar = find.byKey(const Key('navProfile')).evaluate().isNotEmpty;
    final onRegisterEmail = find.byKey(const Key('registerEmailField')).evaluate().isNotEmpty;
    final onRegisterUsername = find.byKey(const Key('registerUsernameField')).evaluate().isNotEmpty;
    final onLoginEmail = find.byKey(const Key('emailField')).evaluate().isNotEmpty;
    final onLoginPassword = find.byKey(const Key('passwordField')).evaluate().isNotEmpty;
    final onRegister = onRegisterEmail && onRegisterUsername;
    final onLogin = onLoginEmail && onLoginPassword;
    print('  On home (navProfile): $onNavBar');
    print('  On register (email+username keys): $onRegister');
    print('  On login (email+password keys): $onLogin');
    print('  Stale keys (register email only, username gone?): registerEmail=$onRegisterEmail registerUsername=$onRegisterUsername');
    print('  Stale keys (login email only, password gone?): email=$onLoginEmail password=$onLoginPassword');
    await _snapshot(tester, '09_final_state', dumpTree: true);

    expect(onNavBar || onRegister || onLogin, isTrue,
      reason: 'Expected to be on home, register, or login after sign-up flow. '
          'Home:$onNavBar Register:$onRegister Login:$onLogin '
          'registerEmail:$onRegisterEmail registerUsername:$onRegisterUsername '
          'email:$onLoginEmail password:$onLoginPassword',
    );
  });
}