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

  testWidgets('Sign out returns to guest state', (tester) async {
    // Arrange: register the user so we are authenticated.
    await pumpE2EApp(tester);
    await completeSignUp(tester, user);

    // Act: sign out via the profile page.
    await completeSignOut(tester);

    // Assert: guest state — the login page should be visible (signInButton
    // key present) or we're back on home as guest (navProfile present).
    final onLogin = find.byKey(const Key('signInButton')).evaluate().isNotEmpty;
    final onHome = find.byKey(const Key('navProfile')).evaluate().isNotEmpty;
    expect(onLogin || onHome, isTrue);
  });
}