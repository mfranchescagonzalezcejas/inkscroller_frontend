import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/get_auth_state.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up.dart';
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

  StreamSubscription<dynamic>? _authSubscription;

  AuthNotifier({
    required SignIn signIn,
    required SignUp signUp,
    required SignOut signOut,
    required GetAuthState getAuthState,
  })  : _signIn = signIn,
        _signUp = signUp,
        _signOut = signOut,
        _getAuthState = getAuthState,
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
          isLoading: false,
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
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _signIn(email: email, password: password);

    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (_) => state = state.copyWith(isLoading: false, clearError: true),
    );
  }

  /// Registers a new account with [email] and [password].
  Future<void> signUp({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _signUp(email: email, password: password);

    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (_) => state = state.copyWith(isLoading: false, clearError: true),
    );
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _signOut();

    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (_) => state = state.copyWith(isLoading: false, clearUser: true, clearError: true),
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
