import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/e2e/helpers/auth_flows.dart';
import '../test/e2e/helpers/cleanup.dart';
import '../test/e2e/helpers/test_app.dart';
import '../test/e2e/helpers/test_user.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late TestUser? deleteUser; // Tracks user for tearDown cleanup.

  group('Delete account', () {
    tearDown(() async {
      // Safety net: if a test failed before UI deletion, clean up via API.
      final u = deleteUser;
      if (u != null) {
        await deleteTestUser(email: u.email, password: u.password);
      }
    });

    testWidgets(
      'Settings → delete account → type DELETE → confirm → redirect to login',
      (tester) async {
        deleteUser = TestUser.fresh();
        await pumpE2EApp(tester);
        await completeSignUp(tester, deleteUser!);

        await openDeleteDialog(tester);

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
          if (find.byKey(const Key('signInButton')).evaluate().isNotEmpty) {
            break;
          }
        }

        // Verify redirect to /login.
        expect(find.byKey(const Key('signInButton')), findsWidgets);
      },
    );

    testWidgets('Re-login with deleted credentials fails', (tester) async {
      deleteUser = TestUser.fresh();
      await pumpE2EApp(tester);

      // Register and then delete the account through the UI.
      await completeSignUp(tester, deleteUser!);

      await openDeleteDialog(tester);

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
      await completeSignIn(tester, deleteUser!);

      // The login should have failed — either error SnackBar visible or
      // still on login page.
      expect(
        find.byType(SnackBar).evaluate().isNotEmpty ||
            find.byKey(const Key('signInButton')).evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets(
      'Delete dialog without DELETE text → cancel keeps account active',
      (tester) async {
        deleteUser = TestUser.fresh();
        await pumpE2EApp(tester);
        await completeSignUp(tester, deleteUser!);

        await openDeleteDialog(tester);

        // Type something that is NOT exactly "DELETE" (case-sensitive).
        await tester.enterText(
          find.byKey(const Key('deleteConfirmField')),
          'delete',
        );
        await tester.pump(const Duration(milliseconds: 800));

        // Verify the confirm button is DISABLED (onPressed is null) because
        // the text is not exactly "DELETE".
        final confirmButton = tester.widget<FilledButton>(
          find.byKey(const Key('deleteConfirmButton')),
        );
        expect(confirmButton.onPressed, isNull);

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
      },
    );
  });
}
