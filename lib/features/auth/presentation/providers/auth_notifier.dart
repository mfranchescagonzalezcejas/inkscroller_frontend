import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/get_auth_state.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up.dart';
import '../../../profile/domain/usecases/update_user_profile.dart';
import 'auth_state.dart';

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
  final UpdateUserProfile _updateUserProfile;

  StreamSubscription<dynamic>? _authSubscription;

  AuthNotifier({
    required SignIn signIn,
    required SignUp signUp,
    required SignOut signOut,
    required GetAuthState getAuthState,
    required UpdateUserProfile updateUserProfile,
  }) : _signIn = signIn,
       _signUp = signUp,
       _signOut = signOut,
       _getAuthState = getAuthState,
       _updateUserProfile = updateUserProfile,
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
      (_) => state = state.copyWith(
        isLoading: false,
        clearError: true,
        profileCompletionPending: false,
      ),
    );
  }

  /// Registers a new account and stores profile metadata when provided.
  Future<void> signUp({
    required String email,
    required String password,
    String? username,
    DateTime? birthDate,
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
        if (username == null && birthDate == null) {
          // No profile metadata to store — registration is complete.
          state = state.copyWith(
            isLoading: false,
            clearError: true,
            profileCompletionPending: false,
            registrationInProgress: false,
          );
          return;
        }

        if (username == null || birthDate == null) {
          // One field provided without the other — inconsistent state.
          state = state.copyWith(
            isLoading: false,
            error: 'Profile data is incomplete.',
            profileCompletionPending: true,
            registrationInProgress: false,
          );
          return;
        }

        final profileResult = await _updateUserProfile(
          username: username,
          birthDate: birthDate,
        );

        profileResult.fold(
          (failure) => state = state.copyWith(
            isLoading: false,
            error: failure.message,
            profileCompletionPending: true,
            registrationInProgress: false,
          ),
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
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
        profileCompletionPending: true,
        registrationInProgress: false,
      ),
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
    _authSubscription?.cancel();
    super.dispose();
  }
}
