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

    // Assert: guest state — either the login page or the "Sign in" CTA
    // is visible, confirming the session was closed.
    expect(
      find.textContaining('Sign in').evaluate().isNotEmpty ||
          find.text('Library').evaluate().isNotEmpty,
      isTrue,
    );
  });
}
