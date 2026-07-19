import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inkscroller_flutter/core/router/app_routes.dart';
import 'package:inkscroller_flutter/features/home/presentation/providers/home_provider.dart';
import 'package:inkscroller_flutter/features/home/presentation/providers/home_state.dart';
import 'package:inkscroller_flutter/features/home/presentation/widgets/hero_carousel.dart';
import 'package:inkscroller_flutter/features/home/presentation/widgets/home_shimmer.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/get_manga_list.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/search_manga.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/library/library_notifier.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/user_library_entry.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/user_library_status.dart';
import 'package:inkscroller_flutter/features/library/domain/repositories/user_library_repository.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/library/library_provider.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/library/library_state.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/user_library_provider.dart';
import 'package:inkscroller_flutter/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetMangaList extends Mock implements GetMangaList {}

class _MockSearchManga extends Mock implements SearchManga {}

class _MockUserLibraryRepository extends Mock
    implements UserLibraryRepository {}

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

void main() {
  final mangaA = Manga(
    id: 'manga-a',
    title: 'Manga A',
    coverUrl: 'https://example.com/a.jpg',
    score: 8.5,
  );
  final mangaB = Manga(
    id: 'manga-b',
    title: 'Manga B',
    coverUrl: 'https://example.com/b.jpg',
    score: 7,
  );

  setUp(() {
    LibraryNotifier.resetSharedCache();
    registerFallbackValue(
      UserLibraryEntry(
        manga: Manga(id: 'fallback', title: 'fallback'),
        isInLibrary: true,
        status: UserLibraryStatus.reading,
        updatedAt: DateTime(2026),
      ),
    );
  });

  Widget buildTestHarness({
    required List<Manga> featured,
    LibraryState? libraryState,
  }) {
    final userLibRepo = _MockUserLibraryRepository();
    when(() => userLibRepo.getAll(userId: any(named: 'userId')))
        .thenAnswer((_) async => const <String, UserLibraryEntry>{});
    when(() => userLibRepo.hydrate(any()))
        .thenAnswer((_) async => const <String, UserLibraryEntry>{});
    when(() => userLibRepo.save(any(), userId: any(named: 'userId')))
        .thenAnswer((_) async {});
    when(() => userLibRepo.remove(any(), userId: any(named: 'userId')))
        .thenAnswer((_) async {});

    final notifier = _FixedLibraryNotifier(
      libraryState ??
          const LibraryState(
            mangas: <Manga>[],
            isLoading: false,
            isLoadingMore: false,
            hasMore: false,
            query: '',
            isSearching: false,
          ),
    );
    return ProviderScope(
      overrides: <Override>[
        libraryProvider.overrideWith((_) => notifier),
        userLibraryProvider.overrideWith(
          (_) => UserLibraryNotifier(userLibRepo),
        ),
        homeProvider.overrideWithValue(HomeState(
          featured: featured,
          popular: const [],
          shounen: const [],
          shoujo: const [],
          seinen: const [],
          josei: const [],
        )),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: <RouteBase>[
            GoRoute(
              path: '/',
              builder: (_, __) => const Scaffold(body: HeroCarousel()),
            ),
            GoRoute(
              path: '/manga/:id',
              builder: (_, __) => const Scaffold(
                key: ValueKey('mangaDetail'),
                body: Text('DETAIL'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  group('HeroCarousel', () {
    testWidgets('renders placeholder when no featured manga', (tester) async {
      await tester.pumpWidget(buildTestHarness(featured: const []));
      await tester.pump();

      // When empty, the carousel returns a fixed-height SizedBox
      expect(find.byType(HeroCarousel), findsOneWidget);
    });

    testWidgets('renders at least one featured manga page', (tester) async {
      await tester.pumpWidget(
        buildTestHarness(featured: [mangaA, mangaB]),
      );
      await tester.pump();

      // PageView only renders the active page; check the first manga
      expect(find.text('Manga A'), findsOneWidget);
    });
  });
}
