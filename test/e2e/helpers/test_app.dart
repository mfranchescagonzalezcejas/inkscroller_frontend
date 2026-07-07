import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:inkscroller_flutter/main_dev.dart' as app;

/// Bootstraps the real app for E2E testing.
///
/// Initializes [IntegrationTestWidgetsFlutterBinding], launches the app
/// via [main_dev.main], and waits for the widget tree to settle in bounded
/// steps. Each iteration pumps a 500ms frame and checks for pending
/// animations; the loop stops early if the tree settles before the 15s cap.
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

  const pumpInterval = Duration(milliseconds: 500);
  const maxDuration = Duration(seconds: 15);
  final deadline = DateTime.now().add(maxDuration);

  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(pumpInterval);
    if (tester.binding.hasScheduledFrame) continue;
    // No more frames scheduled — tree is idle.
    return;
  }
}
