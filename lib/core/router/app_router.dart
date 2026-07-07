import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';
import '../l10n/l10n.dart';
import 'app_routes.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/providers/auth_state.dart';
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

/// Notifier that rebuilds the router whenever auth routing inputs change.
///
/// [GoRouter] holds a [Listenable] that it watches for changes; connecting it
/// to Firebase auth and registration flags ensures redirects fire immediately
/// after sign-in, sign-out, or profile metadata recovery state changes.
final _routerRefreshListenable = RouterRefreshListenable(
  firebaseAuthChanges: FirebaseAuth.instance.authStateChanges(),
);

/// Routes that require an authenticated user.
///
/// Guests landing on any of these paths are redirected to `/login`.
const _protectedRoutes = <String>[AppRoutes.profile];

/// Routes reserved for unauthenticated users.
///
/// Authenticated users landing here are redirected to `/`.
const _authOnlyRoutes = <String>[AppRoutes.login, AppRoutes.register];

/// Computes the auth redirect for a given route and Firebase auth state.
///
/// Redirect rules:
/// - Authenticated user with pending or in-flight registration metadata on any
///   route other than `/register` → `/register`
/// - Authenticated user on an auth-only surface (`/login`) → `/`
/// - Authenticated user on `/register` → `/` unless profile metadata recovery
///   is pending or initial registration orchestration is in-flight.
/// - `/register` remains reachable during profile metadata recovery so the
///   backend update can be retried without creating another Firebase account.
/// - `/register` remains reachable during initial registration so Firebase auth
///   changes cannot race backend profile metadata submission.
/// - Guest on a protected surface (`/profile`) → `/login`
/// - All other combinations → `null` (no redirect, allow navigation)
///
/// Public routes (home, explore, library, manga-detail, reader) remain fully
/// accessible without authentication so the app is usable as a guest.
String? resolveAuthRedirect({
  required User? currentUser,
  required String matchedLocation,
  required bool profileCompletionPending,
  required bool registrationInProgress,
}) {
  final isLoggedIn = currentUser != null;

  final mustCompleteRegistration =
      isLoggedIn && (profileCompletionPending || registrationInProgress);

  if (mustCompleteRegistration) {
    return matchedLocation == AppRoutes.register ? null : AppRoutes.register;
  }

  // Authenticated user should not stay on auth screens.
  if (isLoggedIn && _authOnlyRoutes.contains(matchedLocation)) {
    return AppRoutes.home;
  }

  // Guest must not access protected routes — redirect to login.
  if (!isLoggedIn && _protectedRoutes.contains(matchedLocation)) {
    return AppRoutes.login;
  }

  return null;
}

({bool profileCompletionPending, bool registrationInProgress})
_registrationRoutingState(BuildContext context) {
  final authState = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(authProvider);

  return (
    profileCompletionPending: authState.profileCompletionPending,
    registrationInProgress: authState.registrationInProgress,
  );
}

/// Bridges Firebase and Riverpod auth state changes into GoRouter refreshes.
class RouterRefreshListenable extends ChangeNotifier {
  final ProviderListenable<AuthState> _authStateProvider;
  final StreamSubscription<Object?> _firebaseAuthSubscription;

  ProviderContainer? _container;
  ProviderSubscription<AuthState>? _authStateSubscription;

  /// Creates a router refresh listenable.
  RouterRefreshListenable({
    required Stream<Object?> firebaseAuthChanges,
    ProviderListenable<AuthState>? authStateProvider,
  }) : _authStateProvider = authStateProvider ?? authProvider,
       _firebaseAuthSubscription = firebaseAuthChanges.listen((_) {}) {
    _firebaseAuthSubscription.onData((_) => notifyListeners());
  }

  /// Starts watching the active Riverpod [container] for routing flag changes.
  void bind(ProviderContainer container) {
    if (identical(_container, container)) return;

    _authStateSubscription?.close();
    _container = container;
    _authStateSubscription = container.listen<AuthState>(_authStateProvider, (
      previous,
      next,
    ) {
      if (authStateChangeRequiresRefresh(previous, next)) {
        notifyListeners();
      }
    });
  }

  /// Returns true when an [AuthState] transition can affect router redirects.
  static bool authStateChangeRequiresRefresh(
    AuthState? previous,
    AuthState next,
  ) {
    if (previous == null) return false;

    return previous.profileCompletionPending != next.profileCompletionPending ||
        previous.registrationInProgress != next.registrationInProgress;
  }

  @override
  void dispose() {
    _authStateSubscription?.close();
    _firebaseAuthSubscription.cancel();
    super.dispose();
  }
}

/// Centralized application router with authentication guard.
///
/// Public areas remain accessible without authentication. The guard only
/// redirects an already-authenticated user away from the auth surfaces back
/// to `/`.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  refreshListenable: _routerRefreshListenable,
  redirect: (context, state) {
    _routerRefreshListenable.bind(
      ProviderScope.containerOf(context, listen: false),
    );
    final registrationRoutingState = _registrationRoutingState(context);

    return resolveAuthRedirect(
      currentUser: FirebaseAuth.instance.currentUser,
      matchedLocation: state.matchedLocation,
      profileCompletionPending:
          registrationRoutingState.profileCompletionPending,
      registrationInProgress: registrationRoutingState.registrationInProgress,
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
