import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga_tags.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/search_result.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/get_manga_list.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/search_manga.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/library/library_notifier.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetMangaList extends Mock implements GetMangaList {}

class _MockSearchManga extends Mock implements SearchManga {}

void main() {
  late GetMangaList getMangaList;
  late SearchManga searchManga;

  final mangas = <Manga>[
    Manga(id: '1', title: 'Berserk'),
    Manga(id: '2', title: 'Monster'),
  ];

  setUp(() {
    getMangaList = _MockGetMangaList();
    searchManga = _MockSearchManga();
  });

  group('loadInitial', () {
    test('stores mangas and enables pagination when full page', () async {
      when(
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating')),
      ).thenAnswer(
        (_) async => Right<Failure, List<Manga>>(
          List<Manga>.generate(20, (index) => Manga(id: '$index', title: 'Manga $index')),
        ),
      );

      when(
        () => searchManga(
          any(),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          contentRating: any(named: 'contentRating'),
        ),
    ).thenAnswer(
      (_) async => const Right<Failure, SearchResult>(
        SearchResult(mangas: [], limit: 20, offset: 0, total: 0),
      ),
    );

      final notifier = LibraryNotifier(getMangaList, searchManga);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.mangas, hasLength(20));
      expect(notifier.state.hasMore, isTrue);
      expect(notifier.state.failure, isNull);
    });

    test('stores failure when use case fails', () async {
      when(
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating')),
      ).thenAnswer(
        (_) async => const Left<Failure, List<Manga>>(
          NetworkFailure(message: 'offline'),
        ),
      );
      when(
        () => searchManga(
          any(),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          contentRating: any(named: 'contentRating'),
        ),
    ).thenAnswer(
      (_) async => const Right<Failure, SearchResult>(
        SearchResult(mangas: [], limit: 20, offset: 0, total: 0),
      ),
    );

      final notifier = LibraryNotifier(getMangaList, searchManga);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.mangas, isEmpty);
      expect(notifier.state.failure, isA<NetworkFailure>());
    });

    test('retains active demographics when none are provided', () async {
      when(
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics')),
      ).thenAnswer((_) async => const Right<Failure, List<Manga>>(<Manga>[]));
      when(
        () => searchManga(any(), limit: any(named: 'limit'), offset: any(named: 'offset'), contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics')),
      ).thenAnswer((_) async => const Right<Failure, SearchResult>(SearchResult(mangas: [], limit: 20, offset: 0, total: 0)));

      final notifier = LibraryNotifier(getMangaList, searchManga, initialDemographics: const <String>['seinen']);
      await Future<void>.delayed(Duration.zero);
      await notifier.loadInitial();

      verify(
        () => getMangaList(limit: 20, offset: 0, order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating'), demographics: const <MangaDemographic>[MangaDemographic.seinen]),
      ).called(1);
    });

    test('reordered demographics reuse the tab cache', () async {
      final page = List<Manga>.generate(
        20,
        (index) => Manga(id: 'g$index', title: 'Genre $index'),
      );

      when(
        () => getMangaList(
          limit: 20,
          offset: 0,
          order: any(named: 'order'),
          genre: any(named: 'genre'),
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      ).thenAnswer((_) async => Right<Failure, List<Manga>>(page));
      when(
        () => searchManga(any(), limit: any(named: 'limit'), offset: any(named: 'offset'), contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics')),
      ).thenAnswer((_) async => const Right<Failure, SearchResult>(SearchResult(mangas: [], limit: 20, offset: 0, total: 0)));

      final notifier = LibraryNotifier(getMangaList, searchManga);
      await Future<void>.delayed(Duration.zero);

      await notifier.loadInitial(
        demographics: const <String>['shounen', 'shoujo'],
      );
      await notifier.loadInitial(
        demographics: const <String>['shoujo', 'shounen'],
      );

      // Constructor issues one load; the first explicit load hits the network;
      // the reordered second explicit load hits the canonical cache key.
      verify(
        () => getMangaList(
          limit: 20,
          offset: 0,
          order: any(named: 'order'),
          genre: any(named: 'genre'),
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      ).called(2);
    });
  });

  group('refresh', () {
    test('retries network call after cached failure', () async {
      when(
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating')),
      ).thenAnswer(
        (_) async => const Left<Failure, List<Manga>>(
          NetworkFailure(message: 'offline'),
        ),
      );
      when(
        () => searchManga(
          any(),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          contentRating: any(named: 'contentRating'),
        ),
    ).thenAnswer(
      (_) async => const Right<Failure, SearchResult>(
        SearchResult(mangas: [], limit: 20, offset: 0, total: 0),
      ),
    );

      final notifier = LibraryNotifier(getMangaList, searchManga);
      await Future<void>.delayed(Duration.zero);

      // Initial load failed.
      expect(notifier.state.failure, isA<NetworkFailure>());

      // Override mock: second call succeeds.
      when(
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating')),
      ).thenAnswer(
        (_) async => Right<Failure, List<Manga>>(mangas),
      );

      await notifier.refresh();
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.failure, isNull);
      expect(notifier.state.mangas, hasLength(2));
      expect(notifier.state.mangas.first.title, 'Berserk');
      verify(
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating')),
      ).called(2);
    });

    test('fetches again after successful cached state', () async {
      when(
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating')),
      ).thenAnswer(
        (_) async => Right<Failure, List<Manga>>(mangas),
      );
      when(
        () => searchManga(
          any(),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          contentRating: any(named: 'contentRating'),
        ),
    ).thenAnswer(
      (_) async => const Right<Failure, SearchResult>(
        SearchResult(mangas: [], limit: 20, offset: 0, total: 0),
      ),
    );

      final notifier = LibraryNotifier(getMangaList, searchManga);
      await Future<void>.delayed(Duration.zero);

      // Initial load succeeded and cached.
      expect(notifier.state.mangas, hasLength(2));

      // Second load returns different data.
      final updatedMangas = <Manga>[
        Manga(id: '3', title: 'Pluto'),
      ];
      when(
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating')),
      ).thenAnswer(
        (_) async => Right<Failure, List<Manga>>(updatedMangas),
      );

      await notifier.refresh();
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.mangas, hasLength(1));
      expect(notifier.state.mangas.first.title, 'Pluto');
      verify(
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating')),
      ).called(2);
    });

    test('re-runs search when there is an active query', () async {
      when(
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating')),
      ).thenAnswer((_) async => const Right<Failure, List<Manga>>(<Manga>[]));

      final freshResults = <Manga>[
        Manga(id: 's1', title: 'Fresh Result'),
      ];

      final firstSearch = SearchResult(mangas: freshResults, limit: 20, offset: 0, total: 1);

      when(
        () => searchManga(
          'one piece',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, SearchResult>(firstSearch),
      );

      final notifier = LibraryNotifier(getMangaList, searchManga);
      await Future<void>.delayed(Duration.zero);

      // Establish a search with results
      notifier.setQuery('one piece');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(notifier.state.mangas, hasLength(1));
      expect(notifier.state.query, 'one piece');

      // Re-stub searchManga to return different data on refresh
      final refreshedResult = SearchResult(
        mangas: [Manga(id: 'r1', title: 'Refreshed Result')],
        limit: 20,
        offset: 0,
        total: 1,
      );
      when(
        () => searchManga(
          'one piece',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, SearchResult>(refreshedResult),
      );

      await notifier.refresh();
      await Future<void>.delayed(const Duration(milliseconds: 400));

      // Should have called searchManga with offset 0 (fresh search)
      expect(notifier.state.mangas, hasLength(1));
      expect(notifier.state.mangas.first.id, 'r1');
      expect(notifier.state.query, 'one piece');
      verify(
        () => searchManga('one piece', limit: 20, offset: 0, contentRating: any(named: 'contentRating')),
      ).called(2);
    });
  });

  group('loadMore', () {
    test('appends and deduplicates mangas', () async {
      final initialPage = <Manga>[
        ...mangas,
        ...List<Manga>.generate(
          18,
          (index) => Manga(id: 'seed-$index', title: 'Seed $index'),
        ),
      ];

      when(
        () => getMangaList(limit: 20, offset: 0, genre: any(named: 'genre'), contentRating: any(named: 'contentRating')),
      ).thenAnswer((_) async => Right<Failure, List<Manga>>(initialPage));
      when(
        () => getMangaList(limit: 20, offset: 20, genre: any(named: 'genre'), contentRating: any(named: 'contentRating')),
      ).thenAnswer(
        (_) async => Right<Failure, List<Manga>>(<Manga>[
          mangas.first,
          Manga(id: '3', title: 'Pluto'),
        ]),
      );
      when(
        () => searchManga(
          any(),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          contentRating: any(named: 'contentRating'),
        ),
    ).thenAnswer(
      (_) async => const Right<Failure, SearchResult>(
        SearchResult(mangas: [], limit: 20, offset: 0, total: 0),
      ),
    );

      final notifier = LibraryNotifier(getMangaList, searchManga);
      await Future<void>.delayed(Duration.zero);
      await notifier.loadMore();

      final ids = notifier.state.mangas.map((manga) => manga.id).toList();

      expect(ids.where((id) => id == '1'), hasLength(1));
      expect(ids, containsAll(<String>['1', '2', '3']));
      expect(ids.last, '3');
    });
  });

  group('search', () {
    SearchResult searchPage({
      required List<Manga> mangas,
      int limit = 20,
      int offset = 0,
      required int total,
    }) {
      return SearchResult(mangas: mangas, limit: limit, offset: offset, total: total);
    }

    test('performSearch forwards active demographics', () async {
      when(
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics')),
      ).thenAnswer((_) async => const Right<Failure, List<Manga>>(<Manga>[]));
      when(
        () => searchManga(
          'monster',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'),
          demographics: const <MangaDemographic>[MangaDemographic.seinen],
        ),
      ).thenAnswer(
        (_) async => Right<Failure, SearchResult>(
          searchPage(mangas: mangas, total: 2),
        ),
      );

      final notifier = LibraryNotifier(
        getMangaList,
        searchManga,
        initialDemographics: const <String>['seinen'],
      );
      await Future<void>.delayed(Duration.zero);

      notifier.setQuery('monster');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      verify(
        () => searchManga(
          'monster',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'),
          demographics: const <MangaDemographic>[MangaDemographic.seinen],
        ),
      ).called(1);
    });

    test('performSearch sends limit=20, offset=0 and stores total', () async {
      when(
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating')),
      ).thenAnswer((_) async => const Right<Failure, List<Manga>>(<Manga>[]));
      when(
        () => searchManga(
          'monster',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, SearchResult>(
          searchPage(
            mangas: List<Manga>.generate(
              20,
              (index) => Manga(id: 's$index', title: 'Search $index'),
            ),
            total: 42,
          ),
        ),
      );

      final notifier = LibraryNotifier(getMangaList, searchManga);
      await Future<void>.delayed(Duration.zero);

      notifier.setQuery('monster');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(notifier.state.isSearching, isFalse);
      expect(notifier.state.mangas, hasLength(20));
      expect(notifier.state.hasMore, isTrue);
      expect(notifier.state.query, 'monster');
    });

    test('sets hasMore=false when total is less than or equal to page size', () async {
      when(
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating')),
      ).thenAnswer((_) async => const Right<Failure, List<Manga>>(<Manga>[]));
      when(
        () => searchManga(
          'pluto',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, SearchResult>(
          searchPage(mangas: mangas, total: 2),
        ),
      );

      final notifier = LibraryNotifier(getMangaList, searchManga);
      await Future<void>.delayed(Duration.zero);

      notifier.setQuery('pluto');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(notifier.state.mangas, hasLength(2));
      expect(notifier.state.hasMore, isFalse);
    });

    test('ignores late response after a new query starts', () async {
      when(
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating')),
      ).thenAnswer((_) async => const Right<Failure, List<Manga>>(<Manga>[]));

      final firstManga = Manga(id: 'old', title: 'Old Result');
      final secondManga = Manga(id: 'new', title: 'New Result');

      when(
        () => searchManga(
          'first',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'),
        ),
      ).thenAnswer(
        (_) async => Future<Right<Failure, SearchResult>>.delayed(
          const Duration(milliseconds: 600),
          () => Right(
            searchPage(mangas: [firstManga], total: 1),
          ),
        ),
      );
      when(
        () => searchManga(
          'second',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, SearchResult>(
          searchPage(mangas: [secondManga], total: 1),
        ),
      );

      final notifier = LibraryNotifier(getMangaList, searchManga);
      await Future<void>.delayed(Duration.zero);

      notifier.setQuery('first');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      notifier.setQuery('second');
      await Future<void>.delayed(const Duration(milliseconds: 900));

      expect(notifier.state.query, 'second');
      expect(notifier.state.mangas, hasLength(1));
      expect(notifier.state.mangas.first.id, 'new');
    });

    test('ignores in-flight response when query is replaced mid-flight', () async {
      when(
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating')),
      ).thenAnswer((_) async => const Right<Failure, List<Manga>>(<Manga>[]));

      final oldManga = Manga(id: 'old', title: 'Old Result');
      final newManga = Manga(id: 'new', title: 'New Result');

      // First query: debounce fires, API stays in-flight for 600ms
      when(
        () => searchManga(
          'first',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'),
        ),
      ).thenAnswer(
        (_) async => Future<Right<Failure, SearchResult>>.delayed(
          const Duration(milliseconds: 600),
          () => Right(searchPage(mangas: [oldManga], total: 1)),
        ),
      );
      // Second query: resolves immediately
      when(
        () => searchManga(
          'second',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, SearchResult>(
          searchPage(mangas: [newManga], total: 1),
        ),
      );

      final notifier = LibraryNotifier(getMangaList, searchManga);
      await Future<void>.delayed(Duration.zero);

      // Start first search and let its debounce fire
      notifier.setQuery('first');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      // First API call is now in-flight (gen X).
      // Replace query mid-flight — bumps gen so in-flight response is ignored.
      notifier.setQuery('second');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      // Both first response (stale) and second response have landed
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(notifier.state.query, 'second');
      expect(notifier.state.mangas, hasLength(1));
      expect(notifier.state.mangas.first.id, 'new', reason:
        'should contain second-query result, not the stale in-flight result',
      );
    });
  });

  group('loadMoreSearch', () {
    SearchResult searchPage({
      required List<Manga> mangas,
      int limit = 20,
      int offset = 0,
      required int total,
    }) {
      return SearchResult(mangas: mangas, limit: limit, offset: offset, total: total);
    }

    test('loadMoreSearch forwards active demographics', () async {
      const demographics = <MangaDemographic>[MangaDemographic.shoujo];
      when(
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics')),
      ).thenAnswer((_) async => const Right<Failure, List<Manga>>(<Manga>[]));
      when(
        () => searchManga(
          'query',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'),
          demographics: demographics,
        ),
      ).thenAnswer(
        (_) async => Right<Failure, SearchResult>(
          searchPage(
            mangas: List<Manga>.generate(
              20,
              (index) => Manga(id: 's$index', title: 'Search $index'),
            ),
            total: 21,
          ),
        ),
      );
      when(
        () => searchManga(
          'query',
          limit: 20,
          offset: 20,
          contentRating: any(named: 'contentRating'),
          demographics: demographics,
        ),
      ).thenAnswer(
        (_) async => Right<Failure, SearchResult>(
          searchPage(
            mangas: [Manga(id: 's20', title: 'Search 20')],
            offset: 20,
            total: 21,
          ),
        ),
      );

      final notifier = LibraryNotifier(
        getMangaList,
        searchManga,
        initialDemographics: const <String>['shoujo'],
      );
      await Future<void>.delayed(Duration.zero);

      notifier.setQuery('query');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await notifier.loadMoreSearch();

      verify(
        () => searchManga(
          'query',
          limit: 20,
          offset: 20,
          contentRating: any(named: 'contentRating'),
          demographics: demographics,
        ),
      ).called(1);
    });

    test('appends deduplicated results and advances offset', () async {
      final pageOne = List<Manga>.generate(
        20,
        (index) => Manga(id: 's$index', title: 'Search $index'),
      );
      final pageTwo = <Manga>[
        Manga(id: 's0', title: 'Search 0 updated'),
        Manga(id: 's20', title: 'Search 20'),
      ];

      when(
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating')),
      ).thenAnswer((_) async => const Right<Failure, List<Manga>>(<Manga>[]));
      when(
        () => searchManga(
          'query',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, SearchResult>(
          searchPage(mangas: pageOne, total: 21),
        ),
      );
      when(
        () => searchManga(
          'query',
          limit: 20,
          offset: 20,
          contentRating: any(named: 'contentRating'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, SearchResult>(
          searchPage(mangas: pageTwo, offset: 20, total: 21),
        ),
      );

      final notifier = LibraryNotifier(getMangaList, searchManga);
      await Future<void>.delayed(Duration.zero);

      notifier.setQuery('query');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      await notifier.loadMoreSearch();

      final ids = notifier.state.mangas.map((m) => m.id).toList();
      expect(ids, hasLength(21));
      expect(ids.last, 's20');
      // Duplicate from page two is ignored, first page instance kept.
      expect(ids.where((id) => id == 's0'), hasLength(1));
      expect(notifier.state.hasMore, isFalse);
    });

    test('does not request when exhausted', () async {
      when(
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating')),
      ).thenAnswer((_) async => const Right<Failure, List<Manga>>(<Manga>[]));
      when(
        () => searchManga(
          'query',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, SearchResult>(
          searchPage(mangas: mangas, total: 2),
        ),
      );

      final notifier = LibraryNotifier(getMangaList, searchManga);
      await Future<void>.delayed(Duration.zero);

      notifier.setQuery('query');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(notifier.state.hasMore, isFalse);

      await notifier.loadMoreSearch();

      verify(
        () => searchManga(
          'query',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'),
        ),
      ).called(1);
    });

    test('does not send concurrent requests', () async {
      final pageOne = List<Manga>.generate(
        20,
        (index) => Manga(id: 's$index', title: 'Search $index'),
      );

      when(
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating')),
      ).thenAnswer((_) async => const Right<Failure, List<Manga>>(<Manga>[]));
      when(
        () => searchManga(
          'query',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, SearchResult>(
          searchPage(mangas: pageOne, total: 22),
        ),
      );
      when(
        () => searchManga(
          'query',
          limit: 20,
          offset: 20,
          contentRating: any(named: 'contentRating'),
        ),
      ).thenAnswer(
        (_) async => Future<Right<Failure, SearchResult>>.delayed(
          const Duration(milliseconds: 300),
          () => Right(searchPage(mangas: [Manga(id: 's20', title: 'Search 20')], total: 22)),
        ),
      );

      final notifier = LibraryNotifier(getMangaList, searchManga);
      await Future<void>.delayed(Duration.zero);

      notifier.setQuery('query');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      final first = notifier.loadMoreSearch();
      final second = notifier.loadMoreSearch();
      await first;
      await second;

      verify(
        () => searchManga(
          'query',
          limit: 20,
          offset: 20,
          contentRating: any(named: 'contentRating'),
        ),
      ).called(1);
    });

    test('loads all pages through multiple offsets (0, 20, 40, 60, 80)', () async {
      when(
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating')),
      ).thenAnswer((_) async => const Right<Failure, List<Manga>>(<Manga>[]));

      // 42 total results: pages at offset 0, 20, 40 (last page has 2 items)
      final page1 = List<Manga>.generate(
        20, (i) => Manga(id: 'a$i', title: 'Manga $i'),
      );
      final page2 = List<Manga>.generate(
        20, (i) => Manga(id: 'b$i', title: 'Manga ${i + 20}'),
      );
      final page3 = <Manga>[
        Manga(id: 'c0', title: 'Manga 40'),
        Manga(id: 'c1', title: 'Manga 41'),
      ];

      for (final entry in [
        (offset: 0,  mangas: page1, total: 42),
        (offset: 20, mangas: page2, total: 42),
        (offset: 40, mangas: page3, total: 42),
      ]) {
        when(
          () => searchManga(
            'query',
            limit: 20,
            offset: entry.offset,
            contentRating: any(named: 'contentRating'),
          ),
        ).thenAnswer(
          (_) async => Right<Failure, SearchResult>(
            searchPage(mangas: entry.mangas, total: entry.total),
          ),
        );
      }

      final notifier = LibraryNotifier(getMangaList, searchManga);
      await Future<void>.delayed(Duration.zero);

      notifier.setQuery('query');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(notifier.state.mangas, hasLength(20));
      expect(notifier.state.hasMore, isTrue);

      await notifier.loadMoreSearch();
      expect(notifier.state.mangas, hasLength(40));
      expect(notifier.state.hasMore, isTrue);

      await notifier.loadMoreSearch();
      expect(notifier.state.mangas, hasLength(42));
      expect(notifier.state.hasMore, isFalse);

      // Exhausted — no more pages
      await notifier.loadMoreSearch();
      expect(notifier.state.mangas, hasLength(42));
      // Verify the correct offsets were requested
      verify(() => searchManga('query', limit: 20, offset: 0, contentRating: any(named: 'contentRating'))).called(1);
      verify(() => searchManga('query', limit: 20, offset: 20, contentRating: any(named: 'contentRating'))).called(1);
      verify(() => searchManga('query', limit: 20, offset: 40, contentRating: any(named: 'contentRating'))).called(1);
    });

    test('preserves existing results on failure and allows retry', () async {
      final pageOne = List<Manga>.generate(
        20,
        (index) => Manga(id: 's$index', title: 'Search $index'),
      );

      when(
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating')),
      ).thenAnswer((_) async => const Right<Failure, List<Manga>>(<Manga>[]));
      when(
        () => searchManga(
          'query',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, SearchResult>(
          searchPage(mangas: pageOne, total: 21),
        ),
      );
      when(
        () => searchManga(
          'query',
          limit: 20,
          offset: 20,
          contentRating: any(named: 'contentRating'),
        ),
      ).thenAnswer(
        (_) async => const Left<Failure, SearchResult>(
          NetworkFailure(message: 'offline'),
        ),
      );

      final notifier = LibraryNotifier(getMangaList, searchManga);
      await Future<void>.delayed(Duration.zero);

      notifier.setQuery('query');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      await notifier.loadMoreSearch();

      expect(notifier.state.mangas, hasLength(20));
      expect(notifier.state.isLoadingMore, isFalse);
      expect(notifier.state.failure, isA<NetworkFailure>());
      expect(notifier.state.hasMore, isTrue);
    });

    test('retries from the same offset after failure', () async {
      final pageOne = List<Manga>.generate(
        20,
        (index) => Manga(id: 's$index', title: 'Search $index'),
      );
      final pageTwo = <Manga>[
        Manga(id: 's20', title: 'Search 20'),
      ];

      when(
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating')),
      ).thenAnswer((_) async => const Right<Failure, List<Manga>>(<Manga>[]));
      when(
        () => searchManga(
          'query',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, SearchResult>(
          searchPage(mangas: pageOne, total: 21),
        ),
      );
      when(
        () => searchManga(
          'query',
          limit: 20,
          offset: 20,
          contentRating: any(named: 'contentRating'),
        ),
      ).thenAnswer(
        (_) async => const Left<Failure, SearchResult>(
          NetworkFailure(message: 'offline'),
        ),
      );

      final notifier = LibraryNotifier(getMangaList, searchManga);
      await Future<void>.delayed(Duration.zero);

      notifier.setQuery('query');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      // First attempt: fails
      await notifier.loadMoreSearch();
      expect(notifier.state.mangas, hasLength(20));
      expect(notifier.state.failure, isA<NetworkFailure>());

      // Second attempt: now succeeds — re-stub offset 20 to succeed
      when(
        () => searchManga(
          'query',
          limit: 20,
          offset: 20,
          contentRating: any(named: 'contentRating'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, SearchResult>(
          searchPage(mangas: pageTwo, total: 21),
        ),
      );

      await notifier.loadMoreSearch();
      expect(notifier.state.mangas, hasLength(21));
      expect(notifier.state.mangas.last.id, 's20');
      expect(notifier.state.isLoadingMore, isFalse);
      expect(notifier.state.hasMore, isFalse);
    });

    test('ignores stale response after reset', () async {
      final pageOne = List<Manga>.generate(
        20,
        (index) => Manga(id: 's$index', title: 'Search $index'),
      );
      final freshManga = Manga(id: 'fresh', title: 'Fresh Catalogue');

      when(
        () => getMangaList(limit: 20, offset: 0, order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating')),
      ).thenAnswer((_) async => Right<Failure, List<Manga>>([freshManga]));
      when(
        () => searchManga(
          'query',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, SearchResult>(
          searchPage(mangas: pageOne, total: 21),
        ),
      );
      when(
        () => searchManga(
          'query',
          limit: 20,
          offset: 20,
          contentRating: any(named: 'contentRating'),
        ),
      ).thenAnswer(
        (_) async => Future<Right<Failure, SearchResult>>.delayed(
          const Duration(milliseconds: 400),
          () => Right(
            searchPage(mangas: [Manga(id: 's20', title: 'Search 20')], total: 21),
          ),
        ),
      );

      final notifier = LibraryNotifier(getMangaList, searchManga);
      await Future<void>.delayed(Duration.zero);

      notifier.setQuery('query');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      final pending = notifier.loadMoreSearch();
      await notifier.resetExplore();
      await pending;
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.query, '');
      expect(notifier.state.mangas, hasLength(1));
      expect(notifier.state.mangas.first.id, 'fresh');
    });
  });

  group('clearSearch', () {
    test('resets pagination so the next search starts at offset 0', () async {
      final pageOne = List<Manga>.generate(
        20,
        (index) => Manga(id: 's$index', title: 'Search $index'),
      );

      when(
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating')),
      ).thenAnswer((_) async => const Right<Failure, List<Manga>>(<Manga>[]));
      when(
        () => searchManga(
          'query',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, SearchResult>(
          SearchResult(mangas: pageOne, limit: 20, offset: 0, total: 21),
        ),
      );

      final notifier = LibraryNotifier(getMangaList, searchManga);
      await Future<void>.delayed(Duration.zero);

      notifier.setQuery('query');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      await notifier.clearSearch();

      notifier.setQuery('query');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      verify(
        () => searchManga(
          'query',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'),
        ),
      ).called(2);
    });
  });

  group('resetExplore', () {
    test('resets query, results, offsets, genre, cache and reloads catalogue', () async {
      final pageOne = List<Manga>.generate(
        20,
        (index) => Manga(id: 's$index', title: 'Search $index'),
      );
      final cataloguePage = List<Manga>.generate(
        20,
        (index) => Manga(id: 'cat-$index', title: 'Catalogue $index'),
      );

      when(
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating')),
      ).thenAnswer(
        (_) async => Right<Failure, List<Manga>>(cataloguePage),
      );
      when(
        () => searchManga(
          'query',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, SearchResult>(
          SearchResult(mangas: pageOne, limit: 20, offset: 0, total: 21),
        ),
      );

      final notifier = LibraryNotifier(getMangaList, searchManga);
      await Future<void>.delayed(Duration.zero);

      // Switch to a genre tab to verify cache/genre reset later.
      await notifier.setGenre('action');
      await Future<void>.delayed(Duration.zero);

      notifier.setQuery('query');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(notifier.state.query, 'query');
      expect(notifier.state.mangas, isNotEmpty);

      await notifier.resetExplore();
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.query, '');
      expect(notifier.state.isSearching, isFalse);
      expect(notifier.state.isLoadingMore, isFalse);
      expect(notifier.state.hasMore, isTrue);
      expect(notifier.state.mangas, hasLength(20));
      expect(notifier.state.mangas.first.id, 'cat-0');
    });

    test('ignores late search response after reset', () async {
      final lateManga = Manga(id: 'late', title: 'Late');
      final catalogueManga = Manga(id: 'cat', title: 'Catalogue');

      when(
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating')),
      ).thenAnswer(
        (_) async => Right<Failure, List<Manga>>([catalogueManga]),
      );
      when(
        () => searchManga(
          'query',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'),
        ),
      ).thenAnswer(
        (_) async => Future<Right<Failure, SearchResult>>.delayed(
          const Duration(milliseconds: 600),
          () => Right(
            SearchResult(mangas: [lateManga], limit: 20, offset: 0, total: 1),
          ),
        ),
      );

      final notifier = LibraryNotifier(getMangaList, searchManga);
      await Future<void>.delayed(Duration.zero);

      notifier.setQuery('query');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await notifier.resetExplore();
      await Future<void>.delayed(const Duration(milliseconds: 700));

      expect(notifier.state.query, '');
      expect(notifier.state.mangas, hasLength(1));
      expect(notifier.state.mangas.first.id, 'cat');
    });
  });
}
