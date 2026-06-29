import 'dart:math';

/// Generates unique test users for E2E tests.
///
/// Each call to [fresh] produces a user with a unique email address
/// based on the current timestamp and a random suffix. The password is
/// fixed to simplify test setup.
class TestUser {
  /// The user's email address (unique per call to [fresh]).
  final String email;

  /// The user's password (fixed for all test users).
  final String password;

  /// The user's display name (randomized per call to [fresh]).
  final String username;

  /// The user's birth date (approximately 20 years ago).
  final DateTime birthDate;

  const TestUser._({
    required this.email,
    required this.password,
    required this.username,
    required this.birthDate,
  });

  /// Creates a fresh test user with a unique email.
  ///
  /// Email format: `test-{timestamp}-{random4}@e2e.inkscroller.dev`
  /// Password: `TestPass123!`
  /// Username: `TestUser_{random4}`
  /// BirthDate: today minus 20 years.
  factory TestUser.fresh() {
    final now = DateTime.now();
    final ms = now.millisecondsSinceEpoch;
    final rnd = Random();

    // 4-digit random suffix for uniqueness within the same millisecond.
    final suffix = rnd.nextInt(9000) + 1000;
    final usernameSuffix = rnd.nextInt(9000) + 1000;

    return TestUser._(
      email: 'test-$ms-$suffix@e2e.inkscroller.dev',
      password: 'TestPass123!',
      username: 'TestUser_$usernameSuffix',
      birthDate: DateTime(now.year - 20, now.month, now.day),
    );
  }
}
