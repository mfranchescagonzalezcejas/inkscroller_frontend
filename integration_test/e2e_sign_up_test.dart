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

    // Verify navigation to home — the bottom nav or Library tab should be visible.
    expect(find.text('Library'), findsOneWidget);
  });
}
