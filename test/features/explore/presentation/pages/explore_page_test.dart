import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/network/connectivity_status_provider.dart';
import 'package:inkscroller_flutter/features/auth/domain/entities/app_user.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/get_auth_state.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_in.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_out.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_up.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_notifier.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:inkscroller_flutter/core/widgets/inkscroller_logo_loader.dart';
import 'package:inkscroller_flutter/features/explore/presentation/pages/explore_page.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga_reading_progress.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/user_library_entry.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/user_library_status.dart';
import 'package:inkscroller_flutter/features/library/domain/repositories/reading_progress_repository.dart';
import 'package:inkscroller_flutter/features/library/domain/repositories/user_library_repository.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/get_manga_list.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/search_manga.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/library/library_notifier.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/library/library_provider.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/library/library_state.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/reading_progress_provider.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/user_library_provider.dart';
import 'package:inkscroller_flutter/features/profile/domain/usecases/get_user_profile.dart';
import 'package:inkscroller_flutter/features/profile/domain/usecases/update_user_profile.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/l10n_test_helpers.dart';

class _MockGetMangaList extends Mock implements GetMangaList {}

class _MockSearchManga extends Mock implements SearchManga {}

class _MockSignIn extends Mock implements SignIn {}

class _MockSignUp extends Mock implements SignUp {}

class _MockSignOut extends Mock implements SignOut {}

class _MockGetAuthState extends Mock implements GetAuthState {}

class _MockGetUserProfile extends Mock implements GetUserProfile {}

class _MockUpdateUserProfile extends Mock implements UpdateUserProfile {}

class _MockReadingProgressRepository extends Mock
    implements ReadingProgressRepository {}

class _MockUserLibraryRepository extends Mock
    implements UserLibraryRepository {}

class _SpyLibraryNotifier extends LibraryNotifier {
  _SpyLibraryNotifier(super.getMangaList, super.searchManga);

  int loadMoreCalls = 0;
  int loadMoreSearchCalls = 0;
  int resetExploreCalls = 0;

  @override
  Future<void> loadInitial({
    LibraryMode mode = LibraryMode.normal,
    String? genre,
    String? contentRating,
  }) async {}

  @override
  Future<void> loadMore() async {
    loadMoreCalls++;
  }

  @override
  Future<void> loadMoreSearch() async {
    loadMoreSearchCalls++;
  }

  @override
  Future<void> resetExplore() async {
    resetExploreCalls++;
    return super.resetExplore();
  }
}

class _FixedStateNotifier extends LibraryNotifier {
  _FixedStateNotifier(this.fixedState)
      : super(_MockGetMangaList(), _MockSearchManga()) {
    state = fixedState;
  }

  final LibraryState fixedState;

  @override
  Future<void> loadInitial({
    LibraryMode mode = LibraryMode.normal,
    String? genre,
    String? contentRating,
  }) async {}
}

ReadingProgressNotifier _makeStubReadingProgressNotifier() {
  final repository = _MockReadingProgressRepository();
  when(
    () => repository.getAll(),
  ).thenAnswer((_) async => const <String, MangaReadingProgress>{});
  when(() => repository.save(any())).thenAnswer((_) async {});
  return ReadingProgressNotifier(repository);
}

AuthNotifier _makeStubAuthNotifier() {
  final getAuthState = _MockGetAuthState();
  when(() => getAuthState()).thenAnswer((_) => const Stream<AppUser?>.empty());
  return AuthNotifier(
    signIn: _MockSignIn(),
    signUp: _MockSignUp(),
    signOut: _MockSignOut(),
    getAuthState: getAuthState,
    getUserProfile: _MockGetUserProfile(),
    updateUserProfile: _MockUpdateUserProfile(),
  );
}

UserLibraryNotifier _makeStubUserLibraryNotifier([
  Map<String, UserLibraryEntry> initial = const <String, UserLibraryEntry>{},
]) {
  final repository = _MockUserLibraryRepository();
  when(
    () => repository.getAll(userId: any(named: 'userId')),
  ).thenAnswer((_) async => initial);
  when(() => repository.hydrate(any())).thenAnswer((_) async => initial);
  when(
    () => repository.save(any(), userId: any(named: 'userId')),
  ).thenAnswer((_) async {});
  when(
    () => repository.remove(any(), userId: any(named: 'userId')),
  ).thenAnswer((_) async {});
  return UserLibraryNotifier(repository);
}

void main() {
  setUpAll(() {
    registerFallbackValue(const MangaReadingProgress(mangaId: 'fallback'));
    registerFallbackValue(
      UserLibraryEntry(
        manga: Manga(id: 'fallback', title: 'fallback'),
        isInLibrary: true,
        status: UserLibraryStatus.reading,
        updatedAt: DateTime(2026),
      ),
    );
  });

  Future<void> pumpExplorePage(
    WidgetTester tester, {
    required LibraryNotifier notifier,
    bool isOnline = true,
  }) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          connectivityStatusProvider.overrideWith(
            (ref) => Stream<bool>.value(isOnline),
          ),
          authProvider.overrideWith((_) => _makeStubAuthNotifier()),
          exploreProvider.overrideWith((ref) => notifier),
          readingProgressProvider.overrideWith(
            (ref) => _makeStubReadingProgressNotifier(),
          ),
          userLibraryProvider.overrideWith(
            (ref) => _makeStubUserLibraryNotifier(),
          ),
        ],
        child: wrapWithL10n(const ExplorePage(), locale: const Locale('es')),
      ),
    );
  }

  group('scroll pagination', () {
    testWidgets('scroll with empty query calls loadMore', (tester) async {
      final getMangaList = _MockGetMangaList();
      final searchManga = _MockSearchManga();
      final notifier = _SpyLibraryNotifier(getMangaList, searchManga);

      // ponytail: provide enough mangas to make the grid scrollable in a 400x600 viewport
      notifier.state = LibraryState(
        mangas: List<Manga>.generate(
          40,
          (index) => Manga(id: '$index', title: 'Manga $index'),
        ),
        isLoading: false,
        isLoadingMore: false,
        hasMore: true,
        query: '',
        isSearching: false,
      );

      await tester.binding.setSurfaceSize(const Size(400, 400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpExplorePage(tester, notifier: notifier);
      await tester.pumpAndSettle();

      final grid = find.byType(MasonryGridView);
      expect(grid, findsOneWidget);

      // ponytail: fling hard to the bottom to trigger extentAfter <= 600
      await tester.fling(grid, const Offset(0, -10000), 3000);
      await tester.pumpAndSettle();

      expect(notifier.loadMoreCalls, greaterThan(0));
      expect(notifier.loadMoreSearchCalls, 0);
    });

    testWidgets(
      'scroll with active query calls loadMoreSearch instead of loadMore',
      (tester) async {
        final getMangaList = _MockGetMangaList();
        final searchManga = _MockSearchManga();
        final notifier = _SpyLibraryNotifier(getMangaList, searchManga);

        notifier.state = LibraryState(
          mangas: List<Manga>.generate(
            40,
            (index) => Manga(id: '$index', title: 'Manga $index'),
          ),
          isLoading: false,
          isLoadingMore: false,
          hasMore: true,
          query: 'pluto',
          isSearching: false,
        );

        await tester.binding.setSurfaceSize(const Size(400, 400));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await pumpExplorePage(tester, notifier: notifier);
        await tester.pumpAndSettle();

        final grid = find.byType(MasonryGridView);
        expect(grid, findsOneWidget);

        await tester.fling(grid, const Offset(0, -10000), 3000);
        await tester.pumpAndSettle();

        expect(notifier.loadMoreSearchCalls, greaterThan(0));
        expect(notifier.loadMoreCalls, 0);
      },
    );
  });

  group('bottom loader and end reached', () {
    testWidgets('shows bottom loader while loading more during search', (
      tester,
    ) async {
      final notifier = _FixedStateNotifier(
        LibraryState(
          mangas: [Manga(id: '1', title: 'Berserk')],
          isLoading: false,
          isLoadingMore: true,
          hasMore: true,
          query: 'pluto',
          isSearching: false,
        ),
      );

      await pumpExplorePage(tester, notifier: notifier);
      await tester.pump();

      expect(find.byType(InkScrollerLogoLoader), findsOneWidget);
    });

    testWidgets('shows end reached message when search has no more results', (
      tester,
    ) async {
      final notifier = _FixedStateNotifier(
        LibraryState(
          mangas: [Manga(id: '1', title: 'Berserk')],
          isLoading: false,
          isLoadingMore: false,
          hasMore: false,
          query: 'pluto',
          isSearching: false,
        ),
      );

      await pumpExplorePage(tester, notifier: notifier);
      await tester.pumpAndSettle();

      expect(find.text('No hay más mangas para cargar'), findsOneWidget);
    });

    testWidgets(
      'does not show end reached during first search with empty results',
      (tester) async {
        final notifier = _FixedStateNotifier(
          const LibraryState(
            mangas: [],
            isLoading: false,
            isLoadingMore: false,
            hasMore: false,
            query: 'pluto',
            isSearching: true,
          ),
        );

        await pumpExplorePage(tester, notifier: notifier);
        await tester.pump();

        expect(find.text('No hay más mangas para cargar'), findsNothing);
        expect(find.byType(InkScrollerLogoLoader), findsOneWidget);
      },
    );
  });

  group('tab exit reset', () {
    testWidgets('resetExplore is called when returning to an inactive tab', (
      tester,
    ) async {
      final getMangaList = _MockGetMangaList();
      final searchManga = _MockSearchManga();
      final notifier = _SpyLibraryNotifier(getMangaList, searchManga);

      notifier.state = LibraryState(
        mangas: [Manga(id: '1', title: 'Berserk')],
        isLoading: false,
        isLoadingMore: false,
        hasMore: true,
        query: '',
        isSearching: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            connectivityStatusProvider.overrideWith(
              (ref) => Stream<bool>.value(true),
            ),
            authProvider.overrideWith((_) => _makeStubAuthNotifier()),
            exploreProvider.overrideWith((ref) => notifier),
            readingProgressProvider.overrideWith(
              (ref) => _makeStubReadingProgressNotifier(),
            ),
            userLibraryProvider.overrideWith(
              (ref) => _makeStubUserLibraryNotifier(),
            ),
          ],
          child: wrapWithL10n(
            const _TickerSwitcher(child: ExplorePage()),
            locale: const Locale('es'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(notifier.resetExploreCalls, 0);

      // Leave the tab (disable ticker) and then return (enable ticker).
      await tester.tap(find.text('Toggle ticker'));
      await tester.pump();
      await tester.tap(find.text('Toggle ticker'));
      await tester.pump();

      expect(notifier.resetExploreCalls, 1);
    });

    testWidgets('does not reset on initial mount', (tester) async {
      final getMangaList = _MockGetMangaList();
      final searchManga = _MockSearchManga();
      final notifier = _SpyLibraryNotifier(getMangaList, searchManga);

      notifier.state = LibraryState(
        mangas: [Manga(id: '1', title: 'Berserk')],
        isLoading: false,
        isLoadingMore: false,
        hasMore: true,
        query: '',
        isSearching: false,
      );

      await pumpExplorePage(tester, notifier: notifier);
      await tester.pumpAndSettle();

      expect(notifier.resetExploreCalls, 0);
    });
  });
}

class _TickerSwitcher extends StatefulWidget {
  final Widget child;

  const _TickerSwitcher({required this.child});

  @override
  State<_TickerSwitcher> createState() => _TickerSwitcherState();
}

class _TickerSwitcherState extends State<_TickerSwitcher> {
  // ponytail: simple ticker wrapper to simulate StatefulShellRoute.indexedStack tab switches
  bool _enabled = true;

  void toggle() => setState(() => _enabled = !_enabled);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TickerMode(
        enabled: _enabled,
        child: Column(
          children: [
            ElevatedButton(
              onPressed: toggle,
              child: const Text('Toggle ticker'),
            ),
            Expanded(child: widget.child),
          ],
        ),
      ),
    );
  }
}
