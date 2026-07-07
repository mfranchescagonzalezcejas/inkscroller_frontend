import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/e2e/helpers/auth_flows.dart';
import '../test/e2e/helpers/cleanup.dart';
import '../test/e2e/helpers/test_app.dart';
import '../test/e2e/helpers/test_user.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late TestUser user;

  setUp(() {
    user = TestUser.fresh();
  });

  tearDown(() async {
    await deleteTestUser(email: user.email, password: user.password);
  });

  testWidgets('Sign in with valid credentials navigates to home', (
    tester,
  ) async {
    // Arrange: register the user and sign out so we start from login.
    await pumpE2EApp(tester);
    await completeSignUp(tester, user);
    await completeSignOut(tester);

    // Act: sign in with valid credentials.
    await completeSignIn(tester, user);

    // Assert: navigation to home — the Library tab should be visible.
    expect(find.text('Library'), findsOneWidget);
  });
}
