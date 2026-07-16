import '../../domain/entities/app_user.dart';

/// Represents all possible states of the authentication flow.
///
/// Immutable — update by calling [copyWith].
class AuthState {
  /// True while a sign-in, sign-up, or sign-out operation is in-flight.
  final bool isLoading;

  /// The currently authenticated user, or null when signed out.
  final AppUser? user;

  /// A human-readable error message from the most recent failed operation,
  /// or null when there is no error.
  final String? error;

  /// True when Firebase account creation succeeded but backend profile
  /// metadata still needs to be completed.
  final bool profileCompletionPending;

  /// True while the initial Firebase account creation plus backend profile
  /// metadata submission orchestration is in-flight.
  final bool registrationInProgress;

  /// True after a verification email has been sent to the user.
  final bool emailVerificationSent;

  /// [DateTime.now().millisecondsSinceEpoch] when the last verification email
  /// was sent. Used to enforce a 60-second cooldown on the resend button.
  final int? lastVerificationSentAt;

  /// True when a verification email has been sent AND enough time has passed
  /// to allow another resend (60-second cooldown). Returns false when no
  /// email has been sent yet or the cooldown is still active.
  bool get canResendVerification {
    if (lastVerificationSentAt == null) return false;
    return DateTime.now().millisecondsSinceEpoch - lastVerificationSentAt! >= 60000;
  }

  const AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.profileCompletionPending = false,
    this.registrationInProgress = false,
    this.emailVerificationSent = false,
    this.lastVerificationSentAt,
  });

  /// Convenience getter — true when a user is signed in.
  bool get isAuthenticated => user != null;

  /// Convenience getter — true when the user is signed in but their email
  /// has not been verified.
  bool get needsEmailVerification =>
      user != null && !user!.isEmailVerified;

  /// Returns a copy of this state with the provided fields overwritten.
  AuthState copyWith({
    bool? isLoading,
    AppUser? user,
    String? error,
    bool? profileCompletionPending,
    bool? registrationInProgress,
    bool? emailVerificationSent,
    int? lastVerificationSentAt,
    bool clearUser = false,
    bool clearError = false,
    bool clearLastVerificationSentAt = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : user ?? this.user,
      error: clearError ? null : error ?? this.error,
      profileCompletionPending:
          profileCompletionPending ??
              (!clearUser && this.profileCompletionPending),
      registrationInProgress:
          registrationInProgress ??
              (!clearUser && this.registrationInProgress),
      emailVerificationSent:
          emailVerificationSent ??
              (!clearUser && this.emailVerificationSent),
      lastVerificationSentAt:
          clearLastVerificationSentAt
              ? null
              : lastVerificationSentAt ?? this.lastVerificationSentAt,
    );
  }
}
