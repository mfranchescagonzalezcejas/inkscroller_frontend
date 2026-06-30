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

      // Navigate to Settings via the gear icon on the Profile page.
      await tester.tap(find.byKey(const Key('navProfile')));
      await tester.pumpAndSettle();

      // The profile page should have a settings link or icon.
      final settingsIcon = find.byIcon(Icons.settings_outlined);
      if (settingsIcon.evaluate().isNotEmpty) {
        await tester.tap(settingsIcon, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      // The delete account dialog text is hardcoded in Spanish in the
      // DeleteAccountDialog widget, so we use those exact strings.
      final deleteButton = find.text('Eliminar cuenta');
      if (deleteButton.evaluate().isNotEmpty) {
        await tester.tap(deleteButton.first, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      // Type "DELETE" into the confirmation field.
      await tester.enterText(
        find.byKey(const Key('deleteConfirmField')),
        'DELETE',
      );
      await tester.pumpAndSettle();

      // Tap the "Eliminar" confirm button.
      await tester.tap(find.text('Eliminar').first, warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(seconds: 15));

      // Verify redirect to /login — the signInButton key should be visible.
      expect(find.byKey(const Key('signInButton')), findsWidgets);
    });

    testWidgets('Re-login with deleted credentials fails', (tester) async {
      final user = TestUser.fresh();
      await pumpE2EApp(tester);

      // Register and then delete the account through the UI.
      await completeSignUp(tester, user);

      // Navigate to profile and delete account.
      await tester.tap(find.byKey(const Key('navProfile')));
      await tester.pumpAndSettle();

      final settingsIcon = find.byIcon(Icons.settings_outlined);
      if (settingsIcon.evaluate().isNotEmpty) {
        await tester.tap(settingsIcon, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      final deleteButton = find.text('Eliminar cuenta');
      if (deleteButton.evaluate().isNotEmpty) {
        await tester.tap(deleteButton.first, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      await tester.enterText(
        find.byKey(const Key('deleteConfirmField')),
        'DELETE',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eliminar').first, warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(seconds: 15));

      // We should be on the login page now.
      expect(find.byKey(const Key('signInButton')), findsWidgets);

      // Attempt to re-login with the same (now deleted) credentials.
      await completeSignIn(tester, user);

      // The login should have failed — either error message visible or
      // still on login page. The data source surfaces "Credenciales
      // inválidas." in Spanish regardless of app locale.
      expect(
        find.textContaining('Credenciales').evaluate().isNotEmpty ||
            find.byKey(const Key('signInButton')).evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets(
        'Delete dialog without DELETE text → cancel keeps account active',
        (tester) async {
      final user = TestUser.fresh();
      await pumpE2EApp(tester);
      await completeSignUp(tester, user);

      tearDown(() async {
        await deleteTestUser(email: user.email, password: user.password);
      });

      // Navigate to profile and open delete dialog.
      await tester.tap(find.byKey(const Key('navProfile')));
      await tester.pumpAndSettle();

      final settingsIcon = find.byIcon(Icons.settings_outlined);
      if (settingsIcon.evaluate().isNotEmpty) {
        await tester.tap(settingsIcon, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      final deleteButton = find.text('Eliminar cuenta');
      if (deleteButton.evaluate().isNotEmpty) {
        await tester.tap(deleteButton.first, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      // Type something that is NOT exactly "DELETE" (case-sensitive).
      await tester.enterText(
        find.byKey(const Key('deleteConfirmField')),
        'delete',
      );
      await tester.pumpAndSettle();

      // Tap "Cancelar" to close the dialog without deleting.
      final cancelButton = find.text('Cancelar');
      if (cancelButton.evaluate().isNotEmpty) {
        await tester.tap(cancelButton.first, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      // Verify the dialog is closed and the account is still active
      // (the "Eliminar cuenta" button is still visible on settings page).
      expect(find.text('Eliminar cuenta'), findsWidgets);
    });
  });
}