import 'dart:math';

/// Generates unique test users for E2E tests.
///
/// Each call to [fresh] produces a user with a unique email address
/// based on a monotonic counter and a random suffix. The password is
/// fixed to simplify test setup.
class TestUser {
  /// Monotonic counter to guarantee uniqueness even within the same millisecond.
  static int _counter = 0;

  /// The user's email address (unique per call to [fresh]).
  final String email;

  /// The user's password (fixed for all test users).
  final String password;

  /// The user's display name (unique per call to [fresh]).
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
  /// Email format: `test-{counter}-{random4}@e2e.inkscroller.dev`
  /// Password: `TestPass123!`
  /// Username: `TestUser_{counter}_{random4}`
  /// BirthDate: today minus 20 years.
  factory TestUser.fresh() {
    final now = DateTime.now();
    final rnd = Random();

    // Monotonic counter ensures uniqueness even within the same millisecond.
    final seq = _counter++;

    // 4-digit random suffix for additional entropy.
    final suffix = rnd.nextInt(9000) + 1000;

    return TestUser._(
      email: 'test-$seq-$suffix@e2e.inkscroller.dev',
      password: 'TestPass123!',
      username: 'TestUser_${seq}_$suffix',
      birthDate: DateTime(now.year - 20, now.month, now.day),
    );
  }
}
