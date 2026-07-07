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
      expect(
        emailPattern.hasMatch(user.email),
        isTrue,
        reason: 'Email "${user.email}" does not match expected pattern',
      );
    });

    test('has a fixed test password', () {
      final user = TestUser.fresh();
      expect(user.password, equals('TestPass123!'));
    });

    test('username matches the expected pattern', () {
      final user = TestUser.fresh();

      // Pattern: TestUser_{digits}_{4digits}
      final usernamePattern = RegExp(r'^TestUser_\d+_\d{4}$');
      expect(
        usernamePattern.hasMatch(user.username),
        isTrue,
        reason: 'Username "${user.username}" does not match expected pattern',
      );
    });

    test('username uses the same monotonic counter as email', () {
      final user = TestUser.fresh();

      final emailMatch = RegExp(
        r'^test-(\d+)-\d{4}@e2e\.inkscroller\.dev$',
      ).firstMatch(user.email);
      final usernameMatch = RegExp(
        r'^TestUser_(\d+)_\d{4}$',
      ).firstMatch(user.username);

      expect(emailMatch, isNotNull);
      expect(usernameMatch, isNotNull);
      expect(usernameMatch!.group(1), emailMatch!.group(1));
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

      // Usernames include monotonic counter + random component,
      // so collision is effectively impossible.
      expect(user1.username, isNot(equals(user2.username)));
    });
  });
}
