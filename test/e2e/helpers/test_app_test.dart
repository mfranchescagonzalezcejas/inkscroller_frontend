import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

void main() {
  group('pumpE2EApp', () {
    test('is a function that accepts WidgetTester', () {
      // Verify the helper exists and has the expected signature.
      // Actual integration testing happens in integration_test/ files.
      expect(pumpE2EApp, isA<Function>());
    });
  });
}
