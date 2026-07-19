import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inkscroller_flutter/features/auth/domain/entities/app_user.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/get_auth_state.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/reload_user.dart';
import 'package:inkscroller_flutter/features/profile/domain/usecases/get_user_profile.dart';
import 'package:inkscroller_flutter/features/profile/domain/usecases/update_user_profile.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/send_email_verification.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/send_password_reset.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_in.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_out.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_up.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_notifier.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:inkscroller_flutter/features/home/domain/entities/home_chapter.dart';
import 'package:inkscroller_flutter/features/home/presentation/pages/home_page.dart';
import 'package:inkscroller_flutter/features/home/presentation/providers/continue_reading_provider.dart';
import 'package:inkscroller_flutter/features/home/presentation/providers/home_latest_chapters_provider.dart';
import 'package:inkscroller_flutter/features/home/presentation/providers/home_provider.dart';
import 'package:inkscroller_flutter/features/home/presentation/providers/home_state.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/get_manga_list.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/search_manga.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/library/library_notifier.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/library/library_provider.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/library/library_state.dart';
import 'package:inkscroller_flutter/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetMangaList extends Mock implements GetMangaList {}

class _MockSearchManga extends Mock implements SearchManga {}

class _MockSignIn extends Mock implements SignIn {}

class _MockSignUp extends Mock implements SignUp {}

class _MockSignOut extends Mock implements SignOut {}

class _MockGetAuthState extends Mock implements GetAuthState {}

class _MockGetUserProfile extends Mock implements GetUserProfile {}

class _MockUpdateUserProfile extends Mock implements UpdateUserProfile {}

class _MockSendEmailVerification extends Mock implements SendEmailVerification {}

class _MockSendPasswordReset extends Mock implements SendPasswordReset {}

class _MockReloadUser extends Mock implements ReloadUser {}

class _FixedLibraryNotifier extends LibraryNotifier {
  _FixedLibraryNotifier(LibraryState state)
    : super(_MockGetMangaList(), _MockSearchManga()) {
    this.state = state;
  }

  @override
  Future<void> loadInitial({
    LibraryMode mode = LibraryMode.normal,
    String? genre,
    String? contentRating,
    List<String>? demographics,
  }) async {}
}

AuthNotifier _stubAuthNotifier() {
  final getAuthState = _MockGetAuthState();
  when(() => getAuthState()).thenAnswer((_) => const Stream<AppUser?>.empty());
  return AuthNotifier(
    signIn: _MockSignIn(),
    signUp: _MockSignUp(),
    signOut: _MockSignOut(),
    getAuthState: getAuthState,
    sendEmailVerification: _MockSendEmailVerification(),
    sendPasswordReset: _MockSendPasswordReset(),
    reloadUser: _MockReloadUser(),
    getUserProfile: _MockGetUserProfile(),
    updateUserProfile: _MockUpdateUserProfile(),
  );
}

Widget _harness({required List<Manga> featured}) {
  final notifier = _FixedLibraryNotifier(
    const LibraryState(
      mangas: <Manga>[],
      isLoading: false,
      isLoadingMore: false,
      hasMore: false,
      query: '',
      isSearching: false,
    ),
  );
  final router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (_, __) => ProviderScope(
          overrides: <Override>[
            authProvider.overrideWith((_) => _stubAuthNotifier()),
            libraryProvider.overrideWith((_) => notifier),
            homeProvider.overrideWithValue(HomeState(
                featured: featured,
                popular: const [],
                shounen: const [],
                shoujo: const [],
                seinen: const [],
                josei: const [],
              )),
            continueReadingProvider.overrideWith(
              (_) async => const <ContinueReadingItem>[],
            ),
            homeLatestChaptersProvider.overrideWith(
              (_) async => const <HomeChapter>[],
            ),
          ],
          child: const HomePage(),
        ),
      ),
      GoRoute(
        path: '/explore',
        builder: (_, __) => const Scaffold(body: Text('Explore destination')),
      ),
    ],
  );

  return MaterialApp.router(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  );
}

void main() {
  testWidgets(
    'always renders the Explore CTA when Home has no featured manga',
    (tester) async {
      await tester.pumpWidget(_harness(featured: const <Manga>[]));
      await tester.pumpAndSettle();

      expect(find.text('Explore all →'), findsOneWidget);
    },
  );

  testWidgets('opens Explore from the CTA when Home has featured manga', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        featured: <Manga>[Manga(id: 'm1', title: 'Manga 1')],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Explore all →'));
    await tester.pumpAndSettle();
    expect(find.text('Explore destination'), findsOneWidget);
  });
}
