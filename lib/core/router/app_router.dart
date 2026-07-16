import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';
import '../l10n/l10n.dart';
import 'app_routes.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';
import '../../features/explore/presentation/pages/explore_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/library/domain/entities/chapter.dart';
import '../../features/library/domain/entities/manga.dart';
import '../../features/library/presentation/pages/library_page.dart';
import '../../features/library/presentation/pages/manga_detail_page.dart';
import '../../features/library/presentation/pages/reader_page.dart';
import '../../features/navigation/presentation/pages/main_scaffold.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/about/presentation/pages/about_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

/// Notifier that rebuilds the router whenever the Firebase auth state changes.
///
/// [GoRouter] holds a [Listenable] that it watches for changes; connecting it
/// to the Firebase auth stream ensures route redirects fire immediately after
/// sign-in or sign-out without requiring an explicit refresh.
final _authStateListenable = _FirebaseAuthStateListenable();

/// Routes that require an authenticated user.
///
/// Guests landing on any of these paths are redirected to `/login`.
const _protectedRoutes = <String>[AppRoutes.profile];

/// Routes reserved for unauthenticated users.
///
/// Authenticated+verified users landing here are redirected to `/`.
const _authOnlyRoutes = <String>[AppRoutes.login, AppRoutes.register];
const _authVerifiedRoutes = <String>[AppRoutes.verifyEmail];

/// Computes the auth redirect for a given route and Firebase auth state.
///
/// The backend enforces email verification — unverified users cannot access
/// protected endpoints. The router redirects them to `/verify-email` so they
/// see the verification page instead of a broken app.
///
/// Redirect rules:
/// - Authenticated+verified user on auth surfaces → `/`
/// - Authenticated+verified user on `/verify-email` → `/`
/// - Authenticated+unverified user on non-auth routes → `/verify-email`
/// - Guest on protected routes → `/login`
/// - Guest on `/verify-email` → `/login`
/// - All other combinations → `null` (no redirect)
String? resolveAuthRedirect({
  required User? currentUser,
  required String matchedLocation,
}) {
  final isLoggedIn = currentUser != null;
  final isVerified = currentUser?.emailVerified ?? false;

  if (kDebugMode) {
    debugPrint(
      '[ROUTER] resolveRedirect route=$matchedLocation '
      'loggedIn=$isLoggedIn verified=$isVerified',
    );
  }

  // Verified user should not stay on auth or verification screens.
  if (isLoggedIn && isVerified) {
    if (_authOnlyRoutes.contains(matchedLocation) ||
        _authVerifiedRoutes.contains(matchedLocation)) {
      return AppRoutes.home;
    }
    return null;
  }

  // Guest must not access protected routes — redirect to login.
  if (!isLoggedIn && _protectedRoutes.contains(matchedLocation)) {
    return AppRoutes.login;
  }

  // Guest cannot access verification page.
  if (!isLoggedIn && _authVerifiedRoutes.contains(matchedLocation)) {
    return AppRoutes.login;
  }

  // Unverified user on any app page → redirect to verification page.
  // Only /register is exempt (signUp flow needs it) so the user can
  // complete registration before being redirected to verify-email.
  if (isLoggedIn && !isVerified && matchedLocation != AppRoutes.register) {
    return AppRoutes.verifyEmail;
  }

  return null;
}

class _FirebaseAuthStateListenable extends ChangeNotifier {
  _FirebaseAuthStateListenable() {
    FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }
}

/// Centralized application router with authentication guard.
///
/// Public areas remain accessible without authentication. The guard only
/// redirects an already-authenticated user away from the auth surfaces back
/// to `/`.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  refreshListenable: _authStateListenable,
  redirect: (context, state) {
    return resolveAuthRedirect(
      currentUser: FirebaseAuth.instance.currentUser,
      matchedLocation: state.matchedLocation,
    );
  },
  routes: <RouteBase>[
    // ── Auth surfaces ─────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.register,
      name: 'register',
      builder: (context, state) => const RegisterPage(),
    ),

    // ── Protected shell ───────────────────────────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScaffold(navigationShell: navigationShell);
      },
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.home,
              name: 'home',
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.explore,
              name: 'explore',
              builder: (context, state) => const ExplorePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.library,
              name: 'library',
              builder: (context, state) => const LibraryPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.profile,
              name: 'profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),

    // ── Auth sub-routes ─────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.verifyEmail,
      name: 'verify-email',
      builder: (context, state) => const VerifyEmailPage(),
    ),

    // ── Sub-routes (accessible from tabs, not tabs themselves) ────────────
    GoRoute(
      path: AppRoutes.settings,
      name: 'settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: AppRoutes.about,
      name: 'about',
      builder: (context, state) => const AboutPage(),
    ),

    GoRoute(
      path: AppRoutes.mangaDetailPattern,
      name: 'manga-detail',
      builder: (context, state) {
        final Manga? manga = state.extra as Manga?;

        if (manga == null) {
          return _RouteErrorPage(
            title: context.l10n.routeInvalidTitle,
            message: context.l10n.routeMissingMangaMessage,
          );
        }

        return MangaDetailPage(manga: manga);
      },
    ),
    GoRoute(
      path: AppRoutes.readerPattern,
      name: 'reader',
      builder: (context, state) {
        final String? mangaId = state.pathParameters['mangaId'];
        final String? chapterId = state.pathParameters['chapterId'];

        if (chapterId == null || chapterId.isEmpty) {
          return _RouteErrorPage(
            title: context.l10n.routeInvalidTitle,
            message: context.l10n.routeMissingChapterMessage,
          );
        }

        // P0-F2: Accept an optional [Chapter] entity via route extra.
        // When present, ReaderPage uses it to short-circuit rendering for
        // external chapters (chapter.external == true) before any provider
        // load occurs. Deep-links without extra still work: the guard is a
        // no-op when chapter is null (the provider handles the fetch normally).
        final Chapter? chapter = state.extra as Chapter?;

        return ReaderPage(
          chapterId: chapterId,
          mangaId: mangaId,
          chapter: chapter,
        );
      },
    ),
  ],
  errorBuilder: (context, state) => _RouteErrorPage(
    title: context.l10n.routeNotFoundTitle,
    message: state.error?.toString() ?? context.l10n.routeNotFoundMessage,
  ),
);

class _RouteErrorPage extends StatelessWidget {
  final String title;
  final String message;

  const _RouteErrorPage({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go(AppRoutes.home),
                child: Text(context.l10n.backToHomeAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
