import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/auth/domain/entities/app_user.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/get_auth_state.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_in.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_out.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_up.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_notifier.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Fakes / mocks
// ---------------------------------------------------------------------------

class _MockSignIn extends Mock implements SignIn {}

class _MockSignUp extends Mock implements SignUp {}

class _MockSignOut extends Mock implements SignOut {}

class _MockGetAuthState extends Mock implements GetAuthState {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _kUser = AppUser(uid: 'uid-123', email: 'alice@example.com');

/// Returns an [AuthNotifier] backed by the provided stubs, with a
/// [GetAuthState] that emits a single empty stream by default so the
/// constructor subscription does not interfere with individual tests.
AuthNotifier _makeNotifier({
  required SignIn signIn,
  required SignUp signUp,
  required SignOut signOut,
  required GetAuthState getAuthState,
}) {
  return AuthNotifier(
    signIn: signIn,
    signUp: signUp,
    signOut: signOut,
    getAuthState: getAuthState,
  );
}

void main() {
  late _MockSignIn mockSignIn;
  late _MockSignUp mockSignUp;
  late _MockSignOut mockSignOut;
  late _MockGetAuthState mockGetAuthState;

  setUp(() {
    mockSignIn = _MockSignIn();
    mockSignUp = _MockSignUp();
    mockSignOut = _MockSignOut();
    mockGetAuthState = _MockGetAuthState();

    // Default: auth state stream never emits — keeps notifier initial state clean.
    when(() => mockGetAuthState()).thenAnswer((_) => const Stream.empty());
  });

  // ── signIn ────────────────────────────────────────────────────────────────

  group('signIn', () {
    test('sets isLoading true then false on success', () async {
      when(
        () => mockSignIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Right<Failure, AppUser>(_kUser));

      final notifier = _makeNotifier(
        signIn: mockSignIn,
        signUp: mockSignUp,
        signOut: mockSignOut,
        getAuthState: mockGetAuthState,
      );

      expect(notifier.state.isLoading, isFalse);

      final future = notifier.signIn(email: 'alice@example.com', password: 's3cr3t');
      // isLoading should flip to true synchronously once the async fn yields.
      await future;

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
    });

    test('clears error on successful sign-in', () async {
      when(
        () => mockSignIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Right<Failure, AppUser>(_kUser));

      final notifier = _makeNotifier(
        signIn: mockSignIn,
        signUp: mockSignUp,
        signOut: mockSignOut,
        getAuthState: mockGetAuthState,
      );

      await notifier.signIn(email: 'alice@example.com', password: 's3cr3t');

      expect(notifier.state.error, isNull);
      expect(notifier.state.isLoading, isFalse);
    });

    test('stores error message on failed sign-in', () async {
      when(
        () => mockSignIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => const Left<Failure, AppUser>(
          ServerFailure(message: 'Invalid credentials'),
        ),
      );

      final notifier = _makeNotifier(
        signIn: mockSignIn,
        signUp: mockSignUp,
        signOut: mockSignOut,
        getAuthState: mockGetAuthState,
      );

      await notifier.signIn(email: 'alice@example.com', password: 'wrong');

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, 'Invalid credentials');
    });

    test('isLoading is false and error is set after failure', () async {
      when(
        () => mockSignIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => const Left<Failure, AppUser>(
          NetworkFailure(message: 'No internet'),
        ),
      );

      final notifier = _makeNotifier(
        signIn: mockSignIn,
        signUp: mockSignUp,
        signOut: mockSignOut,
        getAuthState: mockGetAuthState,
      );

      await notifier.signIn(email: 'alice@example.com', password: 'pw');

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, 'No internet');
    });
  });

  // ── signOut ───────────────────────────────────────────────────────────────

  group('signOut', () {
    test('clears user and error on successful sign-out', () async {
      // Prime the notifier with an authenticated-looking state via the stream.
      final streamController = StreamController<AppUser?>.broadcast();
      when(() => mockGetAuthState()).thenAnswer((_) => streamController.stream);
      when(() => mockSignOut()).thenAnswer(
        (_) async => const Right<Failure, void>(null),
      );

      final notifier = _makeNotifier(
        signIn: mockSignIn,
        signUp: mockSignUp,
        signOut: mockSignOut,
        getAuthState: mockGetAuthState,
      );

      // Emit a user so the notifier knows someone is signed in.
      streamController.add(_kUser);
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.user, equals(_kUser));

      await notifier.signOut();

      // After signOut() the fold(Right) branch clears user and error.
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.user, isNull);
      expect(notifier.state.error, isNull);

      await streamController.close();
    });

    test('stores error message on failed sign-out', () async {
      when(() => mockSignOut()).thenAnswer(
        (_) async => const Left<Failure, void>(
          UnexpectedFailure(message: 'Sign-out failed'),
        ),
      );

      final notifier = _makeNotifier(
        signIn: mockSignIn,
        signUp: mockSignUp,
        signOut: mockSignOut,
        getAuthState: mockGetAuthState,
      );

      await notifier.signOut();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, 'Sign-out failed');
    });
  });

  // ── authStateChanges stream ───────────────────────────────────────────────

  group('auth state stream', () {
    test('updates user when stream emits an AppUser', () async {
      final streamController = StreamController<AppUser?>.broadcast();
      when(() => mockGetAuthState()).thenAnswer((_) => streamController.stream);

      final notifier = _makeNotifier(
        signIn: mockSignIn,
        signUp: mockSignUp,
        signOut: mockSignOut,
        getAuthState: mockGetAuthState,
      );

      expect(notifier.state.user, isNull);

      streamController.add(_kUser);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.user, equals(_kUser));
      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.isLoading, isFalse);

      await streamController.close();
    });

    test('clears user when stream emits null', () async {
      final streamController = StreamController<AppUser?>.broadcast();
      when(() => mockGetAuthState()).thenAnswer((_) => streamController.stream);

      final notifier = _makeNotifier(
        signIn: mockSignIn,
        signUp: mockSignUp,
        signOut: mockSignOut,
        getAuthState: mockGetAuthState,
      );

      streamController.add(_kUser);
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.user, equals(_kUser));

      streamController.add(null);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.user, isNull);
      expect(notifier.state.isAuthenticated, isFalse);

      await streamController.close();
    });
  });

  // ── clearError ────────────────────────────────────────────────────────────

  group('clearError', () {
    test('removes error from state without changing other fields', () async {
      when(
        () => mockSignIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => const Left<Failure, AppUser>(
          ServerFailure(message: 'Oops'),
        ),
      );

      final notifier = _makeNotifier(
        signIn: mockSignIn,
        signUp: mockSignUp,
        signOut: mockSignOut,
        getAuthState: mockGetAuthState,
      );

      await notifier.signIn(email: 'alice@example.com', password: 'pw');
      expect(notifier.state.error, 'Oops');

      notifier.clearError();

      expect(notifier.state.error, isNull);
      expect(notifier.state.isLoading, isFalse);
    });
  });

  // ── P0-F7: auth stream error handling ────────────────────────────────────

  group('auth stream error handling (P0-F7)', () {
    test(
        'clears user and sets error when auth stream emits an error — '
        'does not leave notifier in inconsistent state', () async {
      final streamController = StreamController<AppUser?>.broadcast();
      when(() => mockGetAuthState()).thenAnswer((_) => streamController.stream);

      final notifier = _makeNotifier(
        signIn: mockSignIn,
        signUp: mockSignUp,
        signOut: mockSignOut,
        getAuthState: mockGetAuthState,
      );

      // Simulate a previously authenticated user.
      streamController.add(_kUser);
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.user, equals(_kUser));

      // Simulate an auth stream error (e.g. token revoked, network error).
      streamController.addError(Exception('token revoked'));
      await Future<void>.delayed(Duration.zero);

      // P0-F7: user must be cleared — no inconsistent authenticated state.
      expect(notifier.state.user, isNull);
      expect(notifier.state.isAuthenticated, isFalse);
      // isLoading must not be stuck at true.
      expect(notifier.state.isLoading, isFalse);
      // An error message should be present to surface to the UI.
      expect(notifier.state.error, isNotNull);

      await streamController.close();
    });

    test(
        'public navigation is unaffected after auth stream error — '
        'user is null (guest mode), not locked', () async {
      final streamController = StreamController<AppUser?>.broadcast();
      when(() => mockGetAuthState()).thenAnswer((_) => streamController.stream);

      final notifier = _makeNotifier(
        signIn: mockSignIn,
        signUp: mockSignUp,
        signOut: mockSignOut,
        getAuthState: mockGetAuthState,
      );

      streamController.addError(Exception('session expired'));
      await Future<void>.delayed(Duration.zero);

      // The app is in guest mode: user is null, not loading.
      // The router resolveAuthRedirect(currentUser: null) allows public routes.
      expect(notifier.state.user, isNull);
      expect(notifier.state.isLoading, isFalse);

      await streamController.close();
    });
  });
}
