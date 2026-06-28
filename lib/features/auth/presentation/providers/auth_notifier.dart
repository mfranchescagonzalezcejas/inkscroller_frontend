import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/usecases/get_auth_state.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/domain/usecases/get_user_profile.dart';
import '../../../profile/domain/usecases/update_user_profile.dart';
import 'auth_state.dart';

const String _signUpProfileMetadataFailureReason =
    'sign_up_profile_update_failed';
const String _completeProfileMetadataFailureReason =
    'complete_profile_update_failed';
const String _profileCompletionCheckFailureReason =
    'profile_completion_check_failed';

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
  final GetUserProfile _getUserProfile;
  final UpdateUserProfile _updateUserProfile;
  final ProfileMetadataFailureReporter _profileMetadataFailureReporter;

  StreamSubscription<AppUser?>? _authSubscription;
  String? _profileCompletionCheckUserId;
  Future<void>? _profileCompletionCheck;
  bool _disposed = false;

  AuthNotifier({
    required SignIn signIn,
    required SignUp signUp,
    required SignOut signOut,
    required GetAuthState getAuthState,
    required GetUserProfile getUserProfile,
    required UpdateUserProfile updateUserProfile,
    ProfileMetadataFailureReporter profileMetadataFailureReporter =
        _ignoreProfileMetadataFailure,
  }) : _signIn = signIn,
       _signUp = signUp,
       _signOut = signOut,
       _getAuthState = getAuthState,
       _getUserProfile = getUserProfile,
       _updateUserProfile = updateUserProfile,
       _profileMetadataFailureReporter = profileMetadataFailureReporter,
       super(const AuthState()) {
    _listenToAuthState();
  }

  // --- Auth state listener ---------------------------------------------------

  void _listenToAuthState() {
    _authSubscription = _getAuthState().listen(
      (user) {
        state = state.copyWith(
          user: user,
          clearUser: user == null,
          clearError: true,
          isLoading: state.registrationInProgress && state.isLoading,
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
          error: 'La sesión no pudo verificarse. Iniciá sesión nuevamente.',
        );
      },
    );
  }

  void _checkProfileCompletionIfNeeded(AppUser? user) {
    if (user == null || state.registrationInProgress) return;

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
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
          profileCompletionPending: true,
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
  Future<void> signIn({required String email, required String password}) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      profileCompletionPending: false,
      registrationInProgress: false,
    );

    final result = await _signIn(email: email, password: password);

    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
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

    final result = await _signUp(email: email, password: password);

    await result.fold(
      (failure) async => state = state.copyWith(
        isLoading: false,
        error: failure.message,
        registrationInProgress: false,
      ),
      (_) async {
        final profileResult = await _updateUserProfile(
          username: username,
          birthDate: birthDate,
        );

        profileResult.fold(
          (failure) {
            _reportProfileMetadataFailure(
              flow: 'sign_up',
              reason: _signUpProfileMetadataFailureReason,
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
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _signOut();

    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (_) => state = state.copyWith(
        isLoading: false,
        clearUser: true,
        clearError: true,
        profileCompletionPending: false,
        registrationInProgress: false,
      ),
    );
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
