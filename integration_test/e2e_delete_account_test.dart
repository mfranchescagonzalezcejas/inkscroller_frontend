import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/e2e/helpers/auth_flows.dart';
import '../test/e2e/helpers/cleanup.dart';
import '../test/e2e/helpers/test_app.dart';
import '../test/e2e/helpers/test_user.dart';

/// Navigates to the delete account dialog from an authenticated home state.
/// Handles profile → settings → scrolling to "Eliminar cuenta" → tap.
Future<void> _openDeleteDialog(WidgetTester tester) async {
  // Navigate to Profile via the nav bar.
  await tester.tap(find.byKey(const Key('navProfile')));
  await tester.pumpAndSettle(const Duration(seconds: 10));

  final onProfile = find.byKey(const Key('settingsButton')).evaluate().isNotEmpty;
  print('[delete] After navProfile — onProfile=$onProfile');
  if (!onProfile) {
    // Maybe we're on login (auth guard). Try again after settle.
    await tester.pumpAndSettle(const Duration(seconds: 5));
    final onProfile2 = find.byKey(const Key('settingsButton')).evaluate().isNotEmpty;
    print('[delete] After extra settle — onProfile=$onProfile2');
  }

  // Tap settings icon on the profile page.
  await tester.tap(find.byKey(const Key('settingsButton')), warnIfMissed: false);
  await tester.pumpAndSettle(const Duration(seconds: 10));

  final onDeleteBtn = find.byKey(const Key('deleteAccountButton')).evaluate().isNotEmpty;
  print('[delete] After settings tap — onDeleteBtn=$onDeleteBtn');

  // Scroll down to find deleteAccountButton if needed.
  if (!onDeleteBtn) {
    final scrollable = find.byType(Scrollable).last;
    for (var i = 0; i < 5; i++) {
      await tester.drag(scrollable, const Offset(0, -300));
      await tester.pumpAndSettle();
      if (find.byKey(const Key('deleteAccountButton')).evaluate().isNotEmpty) {
        break;
      }
    }
  }

  // Scroll to make deleteAccountButton visible and tappable.
  final deleteBtnFinder = find.byKey(const Key('deleteAccountButton'));
  await tester.scrollUntilVisible(
    deleteBtnFinder.first,
    -100,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();

  // Close any overlays/snackbars that might intercept the tap.
  await SystemChannels.textInput.invokeMethod('TextInput.hide');
  await tester.pump(const Duration(milliseconds: 300));

  // Tap "Eliminar cuenta" to open the dialog.
  await tester.tap(deleteBtnFinder.first, warnIfMissed: false);
  // Pump multiple times to let the dialog animation complete.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (find.byKey(const Key('deleteConfirmField')).evaluate().isNotEmpty) break;
  }

  final onDialog = find.byKey(const Key('deleteConfirmField')).evaluate().isNotEmpty;
  print('[delete] After dialog tap — onDialog=$onDialog');
}

void main() {
  late TestUser deleteUser; // Tracks user for tearDown cleanup.

  group('Delete account', () {
    tearDown(() async {
      // Safety net: if a test failed before UI deletion, clean up via API.
      await deleteTestUser(
        email: deleteUser.email,
        password: deleteUser.password,
      );
    });

    testWidgets(
        'Settings → delete account → type DELETE → confirm → redirect to login',
        (tester) async {
      deleteUser = TestUser.fresh();
      await pumpE2EApp(tester);
      await completeSignUp(tester, deleteUser);

      await _openDeleteDialog(tester);

      // Type "DELETE" into the confirmation field.
      await tester.enterText(
        find.byKey(const Key('deleteConfirmField')),
        'DELETE',
      );
      await tester.pump(const Duration(milliseconds: 800));

      // Close keyboard before tapping confirm.
      await SystemChannels.textInput.invokeMethod('TextInput.hide');
      await tester.pump(const Duration(milliseconds: 500));

      // Tap the confirm delete button.
      await tester.tap(
        find.byKey(const Key('deleteConfirmButton')),
        warnIfMissed: false,
      );
      // Don't use pumpAndSettle — SnackBar + gradient animations prevent settling.
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (find.byKey(const Key('signInButton')).evaluate().isNotEmpty) break;
      }

      // Verify redirect to /login.
      expect(find.byKey(const Key('signInButton')), findsWidgets);
    });

    testWidgets('Re-login with deleted credentials fails', (tester) async {
      deleteUser = TestUser.fresh();
      await pumpE2EApp(tester);

      // Register and then delete the account through the UI.
      await completeSignUp(tester, deleteUser);

      await _openDeleteDialog(tester);

      await tester.enterText(
        find.byKey(const Key('deleteConfirmField')),
        'DELETE',
      );
      await tester.pump(const Duration(milliseconds: 800));

      await SystemChannels.textInput.invokeMethod('TextInput.hide');
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(
        find.byKey(const Key('deleteConfirmButton')),
        warnIfMissed: false,
      );
      // Don't use pumpAndSettle — SnackBar + gradient animations prevent settling.
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (find.byKey(const Key('signInButton')).evaluate().isNotEmpty) break;
      }

      // We should be on the login page now.
      expect(find.byKey(const Key('signInButton')), findsWidgets);

      // Attempt to re-login with the same (now deleted) credentials.
      await completeSignIn(tester, deleteUser);

      // The login should have failed — either error message visible or
      // still on login page.
      expect(
        find.textContaining('Credenciales').evaluate().isNotEmpty ||
            find.byKey(const Key('signInButton')).evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets(
        'Delete dialog without DELETE text → cancel keeps account active',
        (tester) async {
      deleteUser = TestUser.fresh();
      await pumpE2EApp(tester);
      await completeSignUp(tester, deleteUser);

      await _openDeleteDialog(tester);

      // Type something that is NOT exactly "DELETE" (case-sensitive).
      await tester.enterText(
        find.byKey(const Key('deleteConfirmField')),
        'delete',
      );
      await tester.pump(const Duration(milliseconds: 800));

      // Close keyboard.
      await SystemChannels.textInput.invokeMethod('TextInput.hide');
      await tester.pump(const Duration(milliseconds: 500));

      // Tap cancel to close the dialog without deleting.
      await tester.tap(
        find.byKey(const Key('deleteCancelButton')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify the dialog is closed and the account is still active.
      expect(find.byKey(const Key('deleteAccountButton')), findsWidgets);
      // tearDown will clean up via API.
    });
  });
}
