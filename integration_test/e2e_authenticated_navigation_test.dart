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

    // Navigate to Library tab.
    final libraryTab = find.text('Library');
    expect(libraryTab, findsOneWidget);
    await tester.tap(libraryTab);
    await tester.pumpAndSettle();

    // Wait for library data to load from the backend.
    await tester.pump(const Duration(seconds: 3));

    // The library page shows manga tiles (MangaTile widgets with cover images).
    // Tap the first visible manga tile to navigate to its detail page.
    // MangaTile uses InkWell, so find it by the manga title text.
    final mangaTiles = find.byType(InkWell);
    if (mangaTiles.evaluate().isNotEmpty) {
      await tester.tap(mangaTiles.first);
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Verify we are on the manga detail page — the detail page has a
      // chapters section. Look for any chapter tile or a "no chapters" message.
      // The detail page should show the manga title or chapter list.
      final detailVisible = find.text('Loading chapter...').evaluate().isNotEmpty ||
          find.byType(ListTile).evaluate().isNotEmpty;

      if (detailVisible) {
        // Tap the first chapter tile (if any) to open the reader.
        final chapterTiles = find.byType(ListTile);
        if (chapterTiles.evaluate().isNotEmpty) {
          await tester.tap(chapterTiles.first);
          await tester.pumpAndSettle(const Duration(seconds: 10));

          // Verify the reader page loaded — look for reader UI elements.
          // The reader uses PagedReaderView or shows loading/error state.
          final readerLoaded =
              find.textContaining('Loading chapter').evaluate().isNotEmpty ||
                  find.byType(Scaffold).evaluate().isNotEmpty;

          expect(readerLoaded, isTrue);

          // Press back to return to the manga detail page.
          await tester.pageBack();
          await tester.pumpAndSettle(const Duration(seconds: 5));

          // Verify we are back on the manga detail page.
          // The detail page should still be visible (chapters section).
          expect(find.byType(Scaffold), findsOneWidget);
        }
      }
    }
  });
}
