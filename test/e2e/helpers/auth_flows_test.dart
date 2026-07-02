import 'package:flutter_test/flutter_test.dart';

import 'auth_flows.dart';
import 'test_user.dart';

void main() {
  group('auth_flows helpers', () {
    test('completeSignUp has correct signature', () {
      // Contract test: verify the helper accepts (WidgetTester, TestUser).
      // Full integration coverage lives in integration_test/ files.
      expect(
        completeSignUp,
        isA<Future<void> Function(WidgetTester, TestUser)>(),
      );
    });

    test('completeSignIn has correct signature', () {
      expect(
        completeSignIn,
        isA<Future<void> Function(WidgetTester, TestUser)>(),
      );
    });

    test('completeSignOut has correct signature', () {
      expect(
        completeSignOut,
        isA<Future<void> Function(WidgetTester)>(),
      );
    });

    test('TestUser.fresh() generates valid fixture data', () {
      final user = TestUser.fresh();
      expect(user.email, isNotEmpty);
      expect(user.email, contains('@e2e.inkscroller.dev'));
      expect(user.password, isNotEmpty);
      expect(user.username, isNotEmpty);
      expect(user.birthDate, isA<DateTime>());
      // Birth date should be ~20 years in the past.
      final twentyYearsAgo = DateTime.now().year - 20;
      expect(user.birthDate.year, twentyYearsAgo);
    });

    test('TestUser.fresh() produces unique emails on consecutive calls', () {
      final user1 = TestUser.fresh();
      final user2 = TestUser.fresh();
      expect(user1.email, isNot(equals(user2.email)));
    });
  });
}
