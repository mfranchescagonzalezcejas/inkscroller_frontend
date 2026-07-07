import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/router/app_routes.dart';
import 'package:inkscroller_flutter/core/router/app_router.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_state.dart';

class _FakeUser implements User {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('resolveAuthRedirect', () {
    // ── Guest on public routes ──────────────────────────────────────────────

    test('P0-F7: guest can access public routes without redirect', () {
      for (final route in <String>[
        AppRoutes.home,
        AppRoutes.explore,
        AppRoutes.library,
        AppRoutes.settings,
      ]) {
        expect(
          resolveAuthRedirect(
            currentUser: null,
            matchedLocation: route,
            profileCompletionPending: false,
            registrationInProgress: false,
          ),
          isNull,
          reason: 'Guest should access $route freely',
        );
      }
    });

    test('P0-F7: guest can access manga-detail public route', () {
      expect(
        resolveAuthRedirect(
          currentUser: null,
          matchedLocation: AppRoutes.mangaDetailPath('some-id'),
          profileCompletionPending: false,
          registrationInProgress: false,
        ),
        isNull,
      );
    });

    // ── Guest on auth-only routes ───────────────────────────────────────────

    test('guest can access /login and /register', () {
      expect(
        resolveAuthRedirect(
          currentUser: null,
          matchedLocation: AppRoutes.login,
          profileCompletionPending: false,
          registrationInProgress: false,
        ),
        isNull,
      );
      expect(
        resolveAuthRedirect(
          currentUser: null,
          matchedLocation: AppRoutes.register,
          profileCompletionPending: false,
          registrationInProgress: false,
        ),
        isNull,
      );
    });

    // ── Guest on protected routes ───────────────────────────────────────────

    test('P0-F7: guest is redirected to /login when accessing /profile', () {
      expect(
        resolveAuthRedirect(
          currentUser: null,
          matchedLocation: AppRoutes.profile,
          profileCompletionPending: false,
          registrationInProgress: false,
        ),
        AppRoutes.login,
      );
    });

    // ── Authenticated user on auth routes ───────────────────────────────────

    test('P0-F7: authenticated user is redirected away from /login', () {
      final user = _FakeUser();
      expect(
        resolveAuthRedirect(
          currentUser: user,
          matchedLocation: AppRoutes.login,
          profileCompletionPending: false,
          registrationInProgress: false,
        ),
        AppRoutes.home,
      );
    });

    test('authenticated user is redirected away from /register by default', () {
      final user = _FakeUser();
      expect(
        resolveAuthRedirect(
          currentUser: user,
          matchedLocation: AppRoutes.register,
          profileCompletionPending: false,
          registrationInProgress: false,
        ),
        AppRoutes.home,
      );
    });

    test(
      'authenticated user with pending profile completion is redirected back to /register',
      () {
        final user = _FakeUser();
        for (final route in <String>[AppRoutes.home, AppRoutes.profile]) {
          expect(
            resolveAuthRedirect(
              currentUser: user,
              matchedLocation: route,
              profileCompletionPending: true,
              registrationInProgress: false,
            ),
            AppRoutes.register,
            reason: 'Pending profile completion must not stay on $route',
          );
        }
      },
    );

    test(
      'authenticated user with in-flight registration is redirected back to /register',
      () {
        final user = _FakeUser();
        for (final route in <String>[AppRoutes.home, AppRoutes.settings]) {
          expect(
            resolveAuthRedirect(
              currentUser: user,
              matchedLocation: route,
              profileCompletionPending: false,
              registrationInProgress: true,
            ),
            AppRoutes.register,
            reason: 'In-flight registration must not stay on $route',
          );
        }
      },
    );

    test('authenticated user can access /register for profile completion', () {
      final user = _FakeUser();
      expect(
        resolveAuthRedirect(
          currentUser: user,
          matchedLocation: AppRoutes.register,
          profileCompletionPending: true,
          registrationInProgress: false,
        ),
        isNull,
      );
    });

    test(
      'cold-start incomplete profile detection routes authenticated user to /register',
      () {
        final user = _FakeUser();
        expect(
          resolveAuthRedirect(
            currentUser: user,
            matchedLocation: AppRoutes.home,
            profileCompletionPending: true,
            registrationInProgress: false,
          ),
          AppRoutes.register,
        );
      },
    );

    test(
      'cold-start complete profile detection allows authenticated user to continue',
      () {
        final user = _FakeUser();
        expect(
          resolveAuthRedirect(
            currentUser: user,
            matchedLocation: AppRoutes.home,
            profileCompletionPending: false,
            registrationInProgress: false,
          ),
          isNull,
        );
      },
    );

    test(
      'authenticated user can stay on /register while registration runs',
      () {
        final user = _FakeUser();
        expect(
          resolveAuthRedirect(
            currentUser: user,
            matchedLocation: AppRoutes.register,
            profileCompletionPending: false,
            registrationInProgress: true,
          ),
          isNull,
        );
      },
    );

    // ── Authenticated user on public and protected routes ───────────────────

    test('authenticated user can access public routes without redirect', () {
      final user = _FakeUser();
      for (final route in <String>[
        AppRoutes.home,
        AppRoutes.explore,
        AppRoutes.library,
        AppRoutes.settings,
      ]) {
        expect(
          resolveAuthRedirect(
            currentUser: user,
            matchedLocation: route,
            profileCompletionPending: false,
            registrationInProgress: false,
          ),
          isNull,
          reason: 'Authenticated user should access $route freely',
        );
      }
    });

    test('P0-F7: authenticated user can access /profile without redirect', () {
      final user = _FakeUser();
      expect(
        resolveAuthRedirect(
          currentUser: user,
          matchedLocation: AppRoutes.profile,
          profileCompletionPending: false,
          registrationInProgress: false,
        ),
        isNull,
      );
    });

    // ── Auth error fallback — public routes remain unblocked ────────────────

    test(
      'P0-F7: null user (auth error fallback) does not block public routes',
      () {
        // After an auth stream error, AuthNotifier clears the user (null).
        // The router must not redirect guests away from public content.
        expect(
          resolveAuthRedirect(
            currentUser: null,
            matchedLocation: AppRoutes.home,
            profileCompletionPending: false,
            registrationInProgress: false,
          ),
          isNull,
        );
        expect(
          resolveAuthRedirect(
            currentUser: null,
            matchedLocation: AppRoutes.explore,
            profileCompletionPending: false,
            registrationInProgress: false,
          ),
          isNull,
        );
        expect(
          resolveAuthRedirect(
            currentUser: null,
            matchedLocation: AppRoutes.library,
            profileCompletionPending: false,
            registrationInProgress: false,
          ),
          isNull,
        );
      },
    );
  });

  group('RouterRefreshListenable', () {
    test('notifies when Firebase auth emits', () async {
      final firebaseAuthChanges = StreamController<Object?>.broadcast();
      final listenable = RouterRefreshListenable(
        firebaseAuthChanges: firebaseAuthChanges.stream,
      );
      addTearDown(listenable.dispose);
      addTearDown(firebaseAuthChanges.close);

      var refreshCount = 0;
      listenable.addListener(() => refreshCount++);

      firebaseAuthChanges.add(Object());
      await Future<void>.delayed(Duration.zero);

      expect(refreshCount, 1);
    });

    test('notifies when registration routing flags change', () async {
      final authStateProvider = StateProvider<AuthState>(
        (_) => const AuthState(),
      );
      final container = ProviderContainer();
      final firebaseAuthChanges = StreamController<Object?>.broadcast();
      final listenable = RouterRefreshListenable(
        firebaseAuthChanges: firebaseAuthChanges.stream,
        authStateProvider: authStateProvider,
      );
      addTearDown(container.dispose);
      addTearDown(listenable.dispose);
      addTearDown(firebaseAuthChanges.close);

      var refreshCount = 0;
      listenable
        ..addListener(() => refreshCount++)
        ..bind(container);

      container.read(authStateProvider.notifier).state = const AuthState(
        isLoading: true,
      );
      await Future<void>.delayed(Duration.zero);

      expect(refreshCount, 0);

      container.read(authStateProvider.notifier).state = const AuthState(
        isLoading: true,
        registrationInProgress: true,
      );
      await Future<void>.delayed(Duration.zero);

      expect(refreshCount, 1);

      container.read(authStateProvider.notifier).state = const AuthState(
        profileCompletionPending: true,
      );
      await Future<void>.delayed(Duration.zero);

      expect(refreshCount, 2);
    });
  });
}
