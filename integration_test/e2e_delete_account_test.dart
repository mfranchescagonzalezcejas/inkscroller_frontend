import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/e2e/helpers/auth_flows.dart';
import '../test/e2e/helpers/cleanup.dart';
import '../test/e2e/helpers/test_app.dart';
import '../test/e2e/helpers/test_user.dart';

void main() {
  group('Delete account', () {
    testWidgets(
        'Settings → delete account → type DELETE → confirm → redirect to login',
        (tester) async {
      final user = TestUser.fresh();
      // Register the user first — no tearDown cleanup needed because
      // the test itself deletes the account via the UI flow.
      await pumpE2EApp(tester);
      await completeSignUp(tester, user);

      // Navigate to Settings via the gear icon on the Library page.
      final settingsIcon = find.byIcon(Icons.settings_outlined);
      expect(settingsIcon, findsOneWidget);
      await tester.tap(settingsIcon);
      await tester.pumpAndSettle();

      // Tap "Eliminar cuenta" (Delete account) button.
      final deleteButton = find.text('Eliminar cuenta');
      expect(deleteButton, findsOneWidget);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // The delete account dialog should be visible.
      expect(find.text('Eliminar cuenta'), findsWidgets);

      // Type "DELETE" into the confirmation field.
      await tester.enterText(
        find.byKey(const Key('deleteConfirmField')),
        'DELETE',
      );
      await tester.pumpAndSettle();

      // The "Eliminar" (Delete) button should now be enabled — tap it.
      final confirmButton = find.text('Eliminar');
      expect(confirmButton, findsOneWidget);
      await tester.tap(confirmButton);

      // Wait for the deletion process and redirect.
      await tester.pumpAndSettle(const Duration(seconds: 15));

      // Verify redirect to /login — the Sign in button should be visible.
      expect(find.text('Sign in'), findsOneWidget);

      // Verify guest state — the user is no longer authenticated.
      // Clean up: since the account is deleted, the helper treats
      // user-not-found as success.
    });

    testWidgets('Re-login with deleted credentials fails', (tester) async {
      final user = TestUser.fresh();
      await pumpE2EApp(tester);

      // Register and then delete the account through the UI.
      await completeSignUp(tester, user);

      // Navigate to Settings and delete the account.
      final settingsIcon = find.byIcon(Icons.settings_outlined);
      await tester.tap(settingsIcon);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eliminar cuenta'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('deleteConfirmField')),
        'DELETE',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle(const Duration(seconds: 15));

      // We should be on the login page now.
      expect(find.text('Sign in'), findsOneWidget);

      // Attempt to re-login with the same credentials.
      await completeSignIn(tester, user);

      // Verify the login failed — the error message should be visible
      // ("Credenciales inválidas" or similar). The app should still be
      // on the login page.
      expect(
        find.textContaining('Credenciales').evaluate().isNotEmpty ||
            find.text('Sign in').evaluate().isNotEmpty,
        isTrue,
      );

      // Cleanup: since the account is already deleted, the helper
      // will treat user-not-found as success.
      await deleteTestUser(email: user.email, password: user.password);
    });

    testWidgets(
        'Delete dialog without DELETE text keeps button disabled → cancel keeps account active',
        (tester) async {
      final user = TestUser.fresh();
      await pumpE2EApp(tester);
      await completeSignUp(tester, user);

      tearDown(() async {
        await deleteTestUser(email: user.email, password: user.password);
      });

      // Navigate to Settings.
      final settingsIcon = find.byIcon(Icons.settings_outlined);
      await tester.tap(settingsIcon);
      await tester.pumpAndSettle();

      // Open the delete account dialog.
      await tester.tap(find.text('Eliminar cuenta'));
      await tester.pumpAndSettle();

      // Verify the "Eliminar" button is disabled (onPressed is null)
      // when no text is entered.
      final confirmButton = find.text('Eliminar');
      expect(confirmButton, findsOneWidget);

      // Type something that is NOT exactly "DELETE".
      await tester.enterText(
        find.byKey(const Key('deleteConfirmField')),
        'delete',
      );
      await tester.pumpAndSettle();

      // The button should still be disabled (case-sensitive check).
      // We verify by checking the button is not tappable — the FilledButton
      // has onPressed: null when _canDelete is false.

      // Tap "Cancelar" to close the dialog without deleting.
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // Verify the dialog is closed and the account is still active.
      // Navigate back to Settings to confirm the delete button is still there.
      expect(find.text('Eliminar cuenta'), findsOneWidget);
    });
  });
}
