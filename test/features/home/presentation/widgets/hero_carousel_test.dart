import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/core/router/app_routes.dart';
import 'package:inkscroller_flutter/features/home/presentation/providers/home_provider.dart';
import 'package:inkscroller_flutter/features/home/presentation/providers/home_state.dart';
import 'package:inkscroller_flutter/features/home/presentation/widgets/hero_carousel.dart';
import 'package:inkscroller_flutter/features/home/presentation/widgets/home_shimmer.dart';
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

class _FixedLibraryNotifier extends LibraryNotifier {
  _FixedLibraryNotifier(LibraryState state)
    : super(_MockGetMangaList(), _MockSearchManga()) {
    this.state = state;
  }

  int refreshCalls = 0;

  @override
  Future<void> loadInitial({
    LibraryMode mode = LibraryMode.normal,
    String? genre,
    String? contentRating,
    List<String>? demographics,
  }) async {}

  @override
  Future<void> refresh({
    String? contentRating,
    List<String>? demographics,
  }) async {
    refreshCalls++;
  }
}

Manga _manga(String id, {String? coverUrl, String? title}) => Manga(
  id: id,
  title: title ?? 'Manga $id',
  coverUrl: coverUrl,
  type: 'manga',
  demographic: 'seinen',
  score: 8.5,
);

LibraryState _libraryState({bool isLoading = false, Failure? failure}) =>
    LibraryState(
      mangas: const <Manga>[],
      isLoading: isLoading,
      isLoadingMore: false,
      hasMore: false,
      query: '',
      isSearching: false,
      failure: failure,
    );

Widget _harness({
  required List<Manga> featured,
  required LibraryState libraryState,
}) {
  final notifier = _FixedLibraryNotifier(libraryState);
  final router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (_, __) => ProviderScope(
          overrides: <Override>[
            homeProvider.overrideWithValue(HomeState(
                featured: featured,
                popular: const [],
                shounen: const [],
                shoujo: const [],
                seinen: const [],
                josei: const [],
              )),
            libraryProvider.overrideWith((_) => notifier),
          ],
          child: const Scaffold(body: HeroCarousel()),
        ),
      ),
      GoRoute(
        path: AppRoutes.mangaDetailPattern,
        builder: (_, state) =>
            Scaffold(body: Text(state.pathParameters['mangaId']!)),
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
  testWidgets('shows the carousel shimmer while the library is loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        featured: const <Manga>[],
        libraryState: _libraryState(isLoading: true),
      ),
    );

    expect(find.byType(HomeShimmer), findsOneWidget);
  });

  testWidgets('shows an empty message when no featured manga exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(featured: const <Manga>[], libraryState: _libraryState()),
    );

    expect(find.text('No featured manga yet.'), findsOneWidget);
  });

  testWidgets('shows a retry action for a library failure', (tester) async {
    await tester.pumpWidget(
      _harness(
        featured: const <Manga>[],
        libraryState: _libraryState(
          failure: const ServerFailure(message: 'network error'),
        ),
      ),
    );

    expect(find.text('Could not load featured manga.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('syncs the active dot after a swipe', (tester) async {
    await tester.pumpWidget(
      _harness(
        featured: <Manga>[_manga('one'), _manga('two')],
        libraryState: _libraryState(),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('hero-dot-active-0')),
      findsOneWidget,
    );
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('hero-dot-active-1')),
      findsOneWidget,
    );
  });

  testWidgets('uses a fallback cover and navigates from the read action', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        featured: <Manga>[
          _manga(
            'one',
            title: 'A very long manga title that must ellipsize safely',
          ),
        ],
        libraryState: _libraryState(),
      ),
    );

    expect(find.byIcon(Icons.image_not_supported), findsOneWidget);
    final title = tester.widget<Text>(
      find.textContaining('A very long manga title'),
    );
    expect(title.overflow, TextOverflow.ellipsis);
    await tester.tap(find.bySemanticsLabel('Read Now'));
    await tester.pumpAndSettle();
    expect(find.text('one'), findsOneWidget);
  });

  testWidgets('fits a 360dp viewport with a 48dp Read Now target', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _harness(
        featured: <Manga>[
          _manga(
            'one',
            title:
                'A deliberately long title that must not overflow on narrow screens',
          ),
        ],
        libraryState: _libraryState(),
      ),
    );

    expect(
      tester
          .getSize(find.byKey(const ValueKey<String>('hero-read-now')))
          .height,
      48,
    );
    expect(tester.takeException(), isNull);
  });
}
