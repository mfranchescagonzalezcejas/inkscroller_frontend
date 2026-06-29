import 'package:flutter_test/flutter_test.dart';

import 'auth_flows.dart';
import 'test_user.dart';

void main() {
  group('auth_flows helpers', () {
    test('completeSignUp is a function', () {
      expect(completeSignUp, isA<Function>());
    });

    test('completeSignIn is a function', () {
      expect(completeSignIn, isA<Function>());
    });

    test('completeSignOut is a function', () {
      expect(completeSignOut, isA<Function>());
    });

    test('TestUser can be created for flow helpers', () {
      final user = TestUser.fresh();
      expect(user.email, isNotEmpty);
      expect(user.password, isNotEmpty);
    });
  });
}
