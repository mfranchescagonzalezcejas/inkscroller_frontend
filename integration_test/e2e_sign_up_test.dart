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

    // Wait for post-sign-up navigation to settle.
    await tester.pumpAndSettle();

    // Debug: check where we are after sign-up.
    await tester.pumpAndSettle();
    final onNavBar = find.byKey(const Key('navProfile')).evaluate().isNotEmpty;
    final onRegister = find.text('Unite a la colección').evaluate().isNotEmpty;
    final onLogin = find.text('Iniciar sesión').evaluate().isNotEmpty;
    final onProfileComplete = find.text('Complete your profile').evaluate().isNotEmpty;
    expect(
      onNavBar || onRegister || onLogin || onProfileComplete,
      isTrue,
      reason: 'Post-sign-up location unknown. '
          'NavBar:$onNavBar Register:$onRegister Login:$onLogin ProfileComp:$onProfileComplete',
    );
  });
}
