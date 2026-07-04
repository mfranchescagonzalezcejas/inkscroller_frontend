import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import '../test/e2e/helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Guest navigates to Library without redirect to login', (
    tester,
  ) async {
    await pumpE2EApp(tester);
    await tester.pump(const Duration(milliseconds: 1200));

    // The nav bar should be visible — guest can browse.
    expect(find.byKey(const Key('navProfile')), findsOneWidget);

    // Verify we are NOT on the login page.
    expect(find.byKey(const Key('signInButton')), findsNothing);
  });

  testWidgets('Guest accessing /profile redirects to /login', (tester) async {
    await pumpE2EApp(tester);
    await tester.pump(const Duration(milliseconds: 1200));

    // Navigate programmatically to the protected /profile route.
    final context = tester.element(find.byType(Scaffold).first);
    GoRouter.of(context).go('/profile');
    await tester.pumpAndSettle();

    // Verify we landed on the login page (redirect happened).
    expect(find.byKey(const Key('signInButton')), findsOneWidget);
  });
}
