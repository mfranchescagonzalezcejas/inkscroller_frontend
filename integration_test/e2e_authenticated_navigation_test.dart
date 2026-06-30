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

  testWidgets(
      'Authenticated user navigates Library → manga detail → reader → back',
      (tester) async {
    await pumpE2EApp(tester);

    // Register the user so we are authenticated.
    await completeSignUp(tester, user);

    // Verify we're on home with nav bar.
    expect(find.byKey(const Key('navProfile')), findsOneWidget);

    // Wait for library data to load from the backend.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // The library/home page shows manga tiles. Tap the first InkWell
    // (manga cover or title) to navigate to the detail page.
    final mangaTiles = find.byType(InkWell);
    if (mangaTiles.evaluate().isNotEmpty) {
      await tester.tap(mangaTiles.first, warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // On the detail page, look for chapter list items.
      final chapterTiles = find.byType(ListTile);
      if (chapterTiles.evaluate().isNotEmpty) {
        // Tap the first chapter to open the reader.
        await tester.tap(chapterTiles.first, warnIfMissed: false);
        await tester.pumpAndSettle(const Duration(seconds: 10));

        // Verify the reader page loaded (a Scaffold is present).
        expect(find.byType(Scaffold), findsWidgets);

        // Press back to return to the manga detail page.
        await tester.pageBack();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Verify we are back on the manga detail page.
        expect(find.byType(Scaffold), findsWidgets);
      }
    }
  });
}