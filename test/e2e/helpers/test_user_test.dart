import 'package:flutter_test/flutter_test.dart';

import 'test_user.dart';

void main() {
  group('TestUser.fresh()', () {
    test('generates unique emails on consecutive calls', () async {
      final user1 = TestUser.fresh();
      // Small delay to ensure different millisecond timestamp.
      await Future<void>.delayed(const Duration(milliseconds: 2));
      final user2 = TestUser.fresh();

      expect(user1.email, isNot(equals(user2.email)));
    });

    test('email matches the expected pattern', () {
      final user = TestUser.fresh();

      // Pattern: test-{digits}-{4digits}@e2e.inkscroller.dev
      final emailPattern = RegExp(r'^test-\d+-\d{4}@e2e\.inkscroller\.dev$');
      expect(emailPattern.hasMatch(user.email), isTrue,
          reason: 'Email "${user.email}" does not match expected pattern');
    });

    test('has a fixed test password', () {
      final user = TestUser.fresh();
      expect(user.password, equals('TestPass123!'));
    });

    test('username matches the expected pattern', () {
      final user = TestUser.fresh();

      // Pattern: TestUser_{4digits}
      final usernamePattern = RegExp(r'^TestUser_\d{4}$');
      expect(usernamePattern.hasMatch(user.username), isTrue,
          reason: 'Username "${user.username}" does not match expected pattern');
    });

    test('birthDate is approximately 20 years ago', () {
      final user = TestUser.fresh();
      final now = DateTime.now();
      final expectedBirthDate = DateTime(now.year - 20, now.month, now.day);

      // Allow 1 day tolerance for midnight boundary.
      final diff = user.birthDate.difference(expectedBirthDate).abs();
      expect(diff.inDays, lessThanOrEqualTo(1));
    });

    test('two fresh users have different usernames', () async {
      final user1 = TestUser.fresh();
      await Future<void>.delayed(const Duration(milliseconds: 2));
      final user2 = TestUser.fresh();

      // Usernames include random component, so they should differ.
      // Note: there's a tiny collision risk with 4 random digits, but
      // it's acceptable for test helpers.
      expect(user1.username, isNot(equals(user2.username)));
    });
  });
}
