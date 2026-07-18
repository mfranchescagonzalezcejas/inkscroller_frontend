import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_auth_state.dart';
import '../../domain/usecases/reload_user.dart';
import '../../domain/usecases/send_email_verification.dart';
import '../../domain/usecases/send_password_reset.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/domain/usecases/get_user_profile.dart';
import '../../../profile/domain/usecases/update_user_profile.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/router/redirect_notifier.dart';
import 'auth_state.dart';

const String _signUpProfileMetadataFailureReason =
    'sign_up_profile_update_failed';
const String _completeProfileMetadataFailureReason =
    'complete_profile_update_failed';
const String _profileCompletionCheckFailureReason =
    'profile_completion_check_failed';

/// Stable internal key stored in [AuthState.error] when the auth stream
/// reports a session verification failure. Widget layers resolve this to a
/// localized message via [context.l10n.authSessionVerificationFailed].
const String authSessionVerificationErrorKey =
    'auth_session_verification_failed';

// ---------------------------------------------------------------------------
// Firebase auth error codes (stable — matched by authErrorText to localized
// messages in app_*.arb). These replace raw/hardcoded user-facing text from
// the data layer.
// ---------------------------------------------------------------------------

/// Credentials are invalid, not found, or malformed.
const String authInvalidCredentialsKey = 'auth/invalid-credentials';

/// The email is already associated with an existing account.
const String authEmailAlreadyInUseKey = 'auth/email-already-in-use';

/// The chosen password does not meet minimum strength requirements.
const String authWeakPasswordKey = 'auth/weak-password';

/// Too many login attempts — rate-limited by the backend.
const String authTooManyRequestsKey = 'auth/too-many-requests';

/// A network or connectivity failure prevented the auth request.
const String authNetworkErrorKey = 'auth/network-error';

/// An unexpected / uncategorised auth failure.
const String authUnknownErrorKey = 'auth/unknown-error';

/// The user's email has not been verified yet.
const String authEmailNotVerifiedKey = 'auth/email-not-verified';

/// Reports profile metadata failures to observability without coupling the
/// notifier to a concrete analytics SDK.
typedef ProfileMetadataFailureReporter =
    FutureOr<void> Function({required String flow, required String reason});

FutureOr<void> _ignoreProfileMetadataFailure({
  required String flow,
  required String reason,
}) {}

/// Manages the authentication state and orchestrates auth use cases.
///
/// Wired to the widget tree via [authProvider]. Widgets call methods such as
/// [signIn] and [signOut]; the notifier handles loading/error state transitions
/// and updates are pushed via [state =].
class AuthNotifier extends StateNotifier<AuthState> {
  final SignIn _signIn;
  final SignUp _signUp;
  final SignOut _signOut;
  final GetAuthState _getAuthState;
  final SendEmailVerification _sendEmailVerification;
  final SendPasswordReset _sendPasswordReset;
  final ReloadUser _reloadUser;
  final GetUserProfile _getUserProfile;
  final UpdateUserProfile _updateUserProfile;
  final ProfileMetadataFailureReporter _profileMetadataFailureReporter;
  final AuthRepository? _authRepository;

  StreamSubscription<AppUser?>? _authSubscription;
  String? _profileCompletionCheckUserId;
  Future<void>? _profileCompletionCheck;
  bool _disposed = false;

  AuthNotifier({
    required SignIn signIn,
    required SignUp signUp,
    required SignOut signOut,
    required GetAuthState getAuthState,
    required SendEmailVerification sendEmailVerification,
    required SendPasswordReset sendPasswordReset,
    required ReloadUser reloadUser,
    required GetUserProfile getUserProfile,
    required UpdateUserProfile updateUserProfile,
    ProfileMetadataFailureReporter profileMetadataFailureReporter =
        _ignoreProfileMetadataFailure,
    AuthRepository? authRepository,
  }) : _signIn = signIn,
       _signUp = signUp,
       _signOut = signOut,
       _getAuthState = getAuthState,
       _sendEmailVerification = sendEmailVerification,
       _sendPasswordReset = sendPasswordReset,
       _reloadUser = reloadUser,
       _getUserProfile = getUserProfile,
       _updateUserProfile = updateUserProfile,
       _profileMetadataFailureReporter = profileMetadataFailureReporter,
       _authRepository = authRepository,
       super(const AuthState()) {
    _listenToAuthState();
  }

  // --- Auth state listener ---------------------------------------------------

  void _listenToAuthState() {
    _authSubscription = _getAuthState().listen(
      (user) {
        if (kDebugMode) {
          debugPrint('[AUTH] authStateChange → ${user != null ? "user=${user.uid} verified=${user.isEmailVerified}" : "null"}');
        }
        state = state.copyWith(
          user: user,
          clearUser: user == null,
          clearError: true,
          isLoading: state.registrationInProgress && state.isLoading,
          // Preserve verification/reset sent flags across auth state changes so
          // the login page still shows the banner after signOut.
          emailVerificationSent: state.emailVerificationSent,
          passwordResetSent: state.passwordResetSent,
        );
        _checkProfileCompletionIfNeeded(user);
      },
      // P0-F7: If the auth stream itself errors (e.g. token revoked, network
      // failure during session refresh), treat it as a sign-out rather than
      // leaving the notifier in an inconsistent state. The error is surfaced
      // so the UI can show a non-blocking message, but public routes remain
      // accessible because the user field is cleared (guest mode).
      onError: (Object error) {
        state = state.copyWith(
          clearUser: true,
          isLoading: false,
          error: authSessionVerificationErrorKey,
        );
      },
    );
  }

  void _checkProfileCompletionIfNeeded(AppUser? user) {
    if (user == null || state.registrationInProgress) {
      if (kDebugMode) debugPrint('[AUTH] checkProfileCompletion skipped: user=null or regInProgress');
      return;
    }
    if (!user.isEmailVerified) {
      if (kDebugMode) debugPrint('[AUTH] checkProfileCompletion skipped: email not verified');
      return;
    }

    final userId = user.uid;
    if (_profileCompletionCheckUserId == userId &&
        _profileCompletionCheck != null) {
      return;
    }

    final check = _checkProfileCompletion(userId);
    _profileCompletionCheckUserId = userId;
    _profileCompletionCheck = check;
    unawaited(
      check.whenComplete(() {
        if (identical(_profileCompletionCheck, check)) {
          _profileCompletionCheck = null;
        }
      }),
    );
  }

  Future<void> _checkProfileCompletion(String userId) async {
    final result = await _getUserProfile();

    if (_disposed) return;
    if (state.user?.uid != userId || state.registrationInProgress) return;

    result.fold(
      (failure) {
        _reportProfileMetadataFailure(
          flow: 'profile_completion_check',
          reason: _profileCompletionCheckFailureReason,
        );
        // Transient failures (network, timeout, generic server errors) must not
        // clear profileCompletionPending if it was already true — only an
        // explicit incomplete-profile response should force the /register
        // redirect. Preserve the existing pending state on transient failures.
        //
        // A bare 404 (e.g. message 'Not found') does NOT mean incomplete — it
        // can mean a real server error. Only explicit incomplete/missing-profile
        // messages trigger profile completion.
        // Only explicit incomplete/missing-profile messages force /register.
        // Generic messages like "Missing authorization header" must NOT match,
        // so 'missing' requires a profile-context keyword to avoid false positives.
        final msg = failure.message.toLowerCase();
        final isProfileMissing =
            failure is ServerFailure &&
            (msg.contains('incomplete') ||
                (msg.contains('missing') &&
                    (msg.contains('profile') || msg.contains('metadata'))));
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
          profileCompletionPending: isProfileMissing ? true : null,
        );
      },
      (profile) {
        final hasRequiredMetadata = _hasRequiredProfileMetadata(profile);
        state = state.copyWith(
          profileCompletionPending: !hasRequiredMetadata,
          clearError: hasRequiredMetadata,
        );
      },
    );
  }

  bool _hasRequiredProfileMetadata(UserProfile profile) {
    return (profile.username?.trim().isNotEmpty ?? false) &&
        profile.birthDate != null;
  }

  void _reportProfileMetadataFailure({
    required String flow,
    required String reason,
  }) {
    unawaited(
      Future<void>.sync(() async {
        await _profileMetadataFailureReporter(flow: flow, reason: reason);
      }).catchError((_) {}),
    );
  }

  // --- Public methods --------------------------------------------------------

  /// Signs in with [email] and [password].
  ///
  /// The backend enforces email verification — unverified users receive
  /// 403/email_not_verified on protected API calls. The router redirects
  /// unverified users to the verification page.
  Future<void> signIn({required String email, required String password}) async {
    if (kDebugMode) debugPrint('[AUTH] signIn: attempting login for $email');
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      profileCompletionPending: false,
      registrationInProgress: false,
    );

    final result = await _signIn(email: email, password: password);

    result.fold(
      (failure) {
        if (kDebugMode) debugPrint('[AUTH] signIn FAILED: ${failure.message}');
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (user) {
        state = state.copyWith(
          user: user,
          isLoading: false,
          clearError: true,
          profileCompletionPending: false,
        );
        _checkProfileCompletionIfNeeded(user);
      },
    );
  }

  /// Registers a new account and stores required profile metadata.
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required DateTime birthDate,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      profileCompletionPending: false,
      registrationInProgress: true,
    );

    if (kDebugMode) debugPrint('[AUTH] signUp: calling _signUp for $email');
    final result = await _signUp(email: email, password: password);

    await result.fold(
      (failure) async {
        if (kDebugMode) debugPrint('[AUTH] signUp FAILED: ${failure.message}');
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
          registrationInProgress: false,
        );
      },
      (_) async {
        if (kDebugMode) debugPrint('[AUTH] signUp: Firebase account created, updating profile');
        final profileResult = await _updateUserProfile(
          username: username,
          birthDate: birthDate,
        );

        // Non-blocking Firebase Auth displayName sync — best-effort,
        // failure must not block the sign-up flow.
        unawaited(
          _authRepository
              ?.updateDisplayName(username)
              .catchError((Object e) {
            if (kDebugMode) debugPrint('[AUTH] updateDisplayName FAILED: $e');
            return const Right<Failure, void>(null);
          }),
        );

        if (kDebugMode) debugPrint('[AUTH] signUp: sending verification email');
        final verificationResult = await _sendEmailVerification();
        if (kDebugMode) debugPrint('[AUTH] signUp: verification email result received');

        final now = DateTime.now().millisecondsSinceEpoch;
        final profileError = await profileResult.fold(
          (failure) async {
            _reportProfileMetadataFailure(
              flow: 'sign_up',
              reason: _signUpProfileMetadataFailureReason,
            );
            return failure.message;
          },
          (_) async => null,
        );

        final verificationSent = verificationResult.fold(
          (failure) {
            if (kDebugMode) debugPrint('[AUTH] signUp sendVerification FAILED: ${failure.message}');
            return false;
          },
          (_) => true,
        );

        final verificationError = verificationResult.fold<String?>(
          (f) => f.message,
          (_) => null,
        );
        final bothSucceeded = profileError == null && verificationError == null;

        state = state.copyWith(
          isLoading: false,
          clearError: bothSucceeded,
          error: profileError ?? verificationError,
          profileCompletionPending: profileError != null,
          registrationInProgress: false,
          emailVerificationSent: verificationSent,
          lastVerificationSentAt: verificationSent ? now : null,
        );
      },
    );
  }

  /// Retries backend profile metadata completion for an already authenticated
  /// user without creating another Firebase account.
  Future<void> completeProfile({
    required String username,
    required DateTime birthDate,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final profileResult = await _updateUserProfile(
      username: username,
      birthDate: birthDate,
    );

    profileResult.fold(
      (failure) {
        _reportProfileMetadataFailure(
          flow: 'complete_profile',
          reason: _completeProfileMetadataFailureReason,
        );
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
          profileCompletionPending: true,
          registrationInProgress: false,
        );
      },
      (_) => state = state.copyWith(
        isLoading: false,
        clearError: true,
        profileCompletionPending: false,
        registrationInProgress: false,
      ),
    );
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    if (kDebugMode) debugPrint('[AUTH] signOut');
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _signOut();

    result.fold(
      (failure) {
        if (kDebugMode) debugPrint('[AUTH] signOut FAILED: ${failure.message}');
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (_) => state = state.copyWith(
        isLoading: false,
        clearUser: true,
        clearError: true,
        profileCompletionPending: false,
        registrationInProgress: false,
        clearLastVerificationSentAt: true,
        clearPasswordResetSent: true,
      ),
    );
  }

  /// Sends a verification email to the current user.
  Future<void> sendVerificationEmail() async {
    if (kDebugMode) debugPrint('[AUTH] sendVerificationEmail');
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _sendEmailVerification();

    result.fold(
      (failure) {
        if (kDebugMode) debugPrint('[AUTH] sendVerificationEmail FAILED: ${failure.message}');
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
      (_) {
        if (kDebugMode) debugPrint('[AUTH] sendVerificationEmail SUCCESS');
        state = state.copyWith(
          isLoading: false,
          emailVerificationSent: true,
          lastVerificationSentAt: DateTime.now().millisecondsSinceEpoch,
        );
      },
    );
  }

  /// Sends a password reset email to [email].
  Future<void> resetPassword(String email) async {
    if (kDebugMode) debugPrint('[AUTH] resetPassword');
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _sendPasswordReset(email: email);

    result.fold(
      (failure) {
        if (kDebugMode) debugPrint('[AUTH] resetPassword FAILED: ${failure.message}');
        state = state.copyWith(isLoading: false, error: failure.message);
      },
      (_) {
        if (kDebugMode) debugPrint('[AUTH] resetPassword SUCCESS');
        state = state.copyWith(
          isLoading: false,
          passwordResetSent: true,
          clearError: true,
        );
      },
    );
  }

  /// Clears the password reset sent flag.
  void clearPasswordResetSent() {
    state = state.copyWith(clearPasswordResetSent: true);
  }

  /// Reloads the current user and checks if email is verified.
  ///
  /// Returns `true` when email is now verified.
  Future<bool> checkEmailVerification() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _reloadUser();

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (user) {
        state = state.copyWith(
          user: user,
          isLoading: false,
          clearError: true,
        );
        if (user.isEmailVerified) {
          // Trigger profile completion check now that the user is verified.
          _checkProfileCompletionIfNeeded(user);
        }
        return user.isEmailVerified;
      },
    );
  }

  /// Called by the Dio error interceptor when the backend returns
  /// 403/email_not_verified. Sets [AuthState.emailVerificationSent]
  /// so the app redirects the user to the verification page.
  void setEmailVerificationRequired() {
    if (kDebugMode) debugPrint('[AUTH] setEmailVerificationRequired called');
    // Don't set emailVerificationSent — no email was actually sent by this
    // interceptor path. The user lands on /verify-email and can request one
    // via the resend button.
    triggerRouterRefresh();
  }

  /// Clears any pending auth error from the state.
  void clearError() => state = state.copyWith(clearError: true);

  @override
  void dispose() {
    _disposed = true;
    _authSubscription?.cancel();
    super.dispose();
  }
}
