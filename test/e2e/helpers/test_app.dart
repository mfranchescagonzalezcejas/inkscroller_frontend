import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:inkscroller_flutter/main_dev.dart' as app;

/// Bootstraps the real app for E2E testing.
///
/// Initializes [IntegrationTestWidgetsFlutterBinding], resets [GetIt] to avoid
/// singleton registration conflicts between tests, signs out any lingering
/// Firebase Auth session from a prior test, launches the app
/// via [main_dev.main], and waits for the widget tree to settle.
///
/// Call this at the beginning of every E2E test:
/// ```dart
/// testWidgets('my test', (tester) async {
///   await pumpE2EApp(tester);
///   // ... interact with the real app ...
/// });
/// ```
Future<void> pumpE2EApp(WidgetTester tester) async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Reset GetIt to avoid "already registered" errors when multiple tests
  // run in the same process (integration_test shares the Dart VM).
  await GetIt.instance.reset();

  // Sign out any lingering Firebase Auth session from a prior test.
  // Firebase Auth is a native singleton — GetIt.reset() doesn't clear it.
  try {
    await FirebaseAuth.instance.signOut();
  } on Exception catch (_) {
    // Ignore — Firebase may not be initialized yet on first run.
  }

  await app.main();
  // Pump for 15s to let the app settle. After a sign-out in a prior test,
  // the router may briefly redirect to /login before settling on /.
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (find.byKey(const Key('navProfile')).evaluate().isNotEmpty) break;
  }
}
