import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:inkscroller_flutter/main_dev.dart' as app;

/// Bootstraps the real app for E2E testing.
///
/// Initializes [IntegrationTestWidgetsFlutterBinding], launches the app
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

  await app.main();
  await tester.pumpAndSettle(
    const Duration(seconds: 15),
  );
}
