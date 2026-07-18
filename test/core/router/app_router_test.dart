import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/router/app_routes.dart';
import 'package:inkscroller_flutter/core/router/app_router.dart';

class _FakeUser implements User {
  final bool _emailVerified;

  _FakeUser({bool emailVerified = true}) : _emailVerified = emailVerified;

  @override
  bool get emailVerified => _emailVerified;

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
          resolveAuthRedirect(currentUser: null, matchedLocation: route),
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
        ),
        isNull,
      );
    });

    // ── Guest on auth-only routes ───────────────────────────────────────────

    test('guest can access /login and /register', () {
      expect(
        resolveAuthRedirect(currentUser: null, matchedLocation: AppRoutes.login),
        isNull,
      );
      expect(
        resolveAuthRedirect(
          currentUser: null,
          matchedLocation: AppRoutes.register,
        ),
        isNull,
      );
    });

    // ── Guest on protected routes ───────────────────────────────────────────

    test('guest can access /profile without redirect', () {
      expect(
        resolveAuthRedirect(
          currentUser: null,
          matchedLocation: AppRoutes.profile,
        ),
        isNull,
      );
    });

    // ── Authenticated user on auth routes ───────────────────────────────────

    test('P0-F7: authenticated user is redirected away from /login', () {
      final user = _FakeUser();
      expect(
        resolveAuthRedirect(currentUser: user, matchedLocation: AppRoutes.login),
        AppRoutes.home,
      );
    });

    test('P0-F7: authenticated user is redirected away from /register', () {
      final user = _FakeUser();
      expect(
        resolveAuthRedirect(
          currentUser: user,
          matchedLocation: AppRoutes.register,
        ),
        AppRoutes.home,
      );
    });

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
          resolveAuthRedirect(currentUser: user, matchedLocation: route),
          isNull,
          reason: 'Authenticated user should access $route freely',
        );
      }
    });

    test('P0-F7: authenticated user can access /profile without redirect', () {
      final user = _FakeUser();
      expect(
        resolveAuthRedirect(currentUser: user, matchedLocation: AppRoutes.profile),
        isNull,
      );
    });

    // ── Auth error fallback — public routes remain unblocked ────────────────

    test('P0-F7: null user (auth error fallback) does not block public routes', () {
      // After an auth stream error, AuthNotifier clears the user (null).
      // The router must not redirect guests away from public content.
      expect(
        resolveAuthRedirect(currentUser: null, matchedLocation: AppRoutes.home),
        isNull,
      );
      expect(
        resolveAuthRedirect(
          currentUser: null,
          matchedLocation: AppRoutes.explore,
        ),
        isNull,
      );
      expect(
        resolveAuthRedirect(
          currentUser: null,
          matchedLocation: AppRoutes.library,
        ),
        isNull,
      );
    });
  });
}
