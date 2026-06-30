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

  testWidgets('Sign up with valid data navigates to home', (tester) async {
    await pumpE2EApp(tester);

    await completeSignUp(tester, user);

    // Verify we left the auth flow — emailField should no longer be visible.
    expect(find.byKey(const Key('emailField')), findsNothing);
    // Verify we're on the home page — Library content or bottom nav is visible.
    // find.text('Library') works for both EN and ES since it's the nav label.
    expect(
      find.text('Library').evaluate().isNotEmpty ||
          find.text('Biblioteca').evaluate().isNotEmpty,
      isTrue,
    );
  });
}
