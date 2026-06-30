import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

/// Unit tests for the E2E test app bootstrap helper.
///
/// Full integration coverage lives in `integration_test/` files.
void main() {
  group('pumpE2EApp', () {
    test('has correct signature — Future<void> Function(WidgetTester)', () {
      // Verify the helper exists and has the expected type.
      // Actual integration testing happens in integration_test/ files.
      expect(
        pumpE2EApp,
        isA<Future<void> Function(WidgetTester)>(),
      );
    });
  });
}
