import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../test/e2e/helpers/test_app.dart';

void main() {
  testWidgets('Guest navigates to Library without redirect to login',
      (tester) async {
    await pumpE2EApp(tester);

    // Library is accessible to guests — tap the Library tab.
    final libraryTab = find.text('Library');
    expect(libraryTab, findsOneWidget);
    await tester.tap(libraryTab);
    await tester.pumpAndSettle();

    // Verify the library page is visible (title or content loads).
    // The library should show without redirecting to login.
    expect(find.text('Library'), findsWidgets);

    // Verify we are NOT on the login page.
    expect(find.text('Sign in'), findsNothing);
  });

  testWidgets('Guest accessing /profile redirects to /login', (tester) async {
    await pumpE2EApp(tester);

    // Navigate programmatically to the protected /profile route.
    // The router's redirect logic should intercept and send to /login.
    final context = tester.element(find.byType(Scaffold).first);
    GoRouter.of(context).go('/profile');
    await tester.pumpAndSettle();

    // Verify we landed on the login page (redirect happened).
    expect(find.text('Sign in'), findsOneWidget);
  });
}
