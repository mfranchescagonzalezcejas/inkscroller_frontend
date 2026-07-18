import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga_tags.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/search_result.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/get_manga_list.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/search_manga.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/library/library_notifier.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/library/library_state.dart';
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
    LibraryNotifier.resetSharedCache();
  });

  group('loadInitial', () {
    test('stores mangas and enables pagination when full page', () async {
      when(
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics')),
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
          contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics'),
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
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics')),
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
          contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics'),
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
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics')),
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
          contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics'),
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
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics')),
      ).thenAnswer(
        (_) async => Right<Failure, List<Manga>>(mangas),
      );

      await notifier.refresh();
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.failure, isNull);
      expect(notifier.state.mangas, hasLength(2));
      expect(notifier.state.mangas.first.title, 'Berserk');
      verify(
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics')),
      ).called(2);
    });

    test('fetches again after successful cached state', () async {
      when(
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics')),
      ).thenAnswer(
        (_) async => Right<Failure, List<Manga>>(mangas),
      );
      when(
        () => searchManga(
          any(),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics'),
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
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics')),
      ).thenAnswer(
        (_) async => Right<Failure, List<Manga>>(updatedMangas),
      );

      await notifier.refresh();
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.mangas, hasLength(1));
      expect(notifier.state.mangas.first.title, 'Pluto');
      verify(
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics')),
      ).called(2);
    });

    test('re-runs search when there is an active query', () async {
      when(
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics')),
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
          contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics'),
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
          contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics'),
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
        () => searchManga('one piece', limit: 20, offset: 0, contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics')),
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
        () => getMangaList(limit: 20, offset: 0, genre: any(named: 'genre'), contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics')),
      ).thenAnswer((_) async => Right<Failure, List<Manga>>(initialPage));
      when(
        () => getMangaList(limit: 20, offset: 20, genre: any(named: 'genre'), contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics')),
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
          contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics'),
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
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics')),
      ).thenAnswer((_) async => const Right<Failure, List<Manga>>(<Manga>[]));
      when(
        () => searchManga(
          'monster',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics'),
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
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics')),
      ).thenAnswer((_) async => const Right<Failure, List<Manga>>(<Manga>[]));
      when(
        () => searchManga(
          'pluto',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics'),
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
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics')),
      ).thenAnswer((_) async => const Right<Failure, List<Manga>>(<Manga>[]));

      final firstManga = Manga(id: 'old', title: 'Old Result');
      final secondManga = Manga(id: 'new', title: 'New Result');

      when(
        () => searchManga(
          'first',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics'),
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
          contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics'),
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
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics')),
      ).thenAnswer((_) async => const Right<Failure, List<Manga>>(<Manga>[]));

      final oldManga = Manga(id: 'old', title: 'Old Result');
      final newManga = Manga(id: 'new', title: 'New Result');

      // First query: debounce fires, API stays in-flight for 600ms
      when(
        () => searchManga(
          'first',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics'),
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
          contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics'),
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
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics')),
      ).thenAnswer((_) async => const Right<Failure, List<Manga>>(<Manga>[]));
      when(
        () => searchManga(
          'query',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics'),
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
          contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics'),
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
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics')),
      ).thenAnswer((_) async => const Right<Failure, List<Manga>>(<Manga>[]));
      when(
        () => searchManga(
          'query',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics'),
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
          contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics'),
        ),
      ).called(1);
    });

    test('does not send concurrent requests', () async {
      final pageOne = List<Manga>.generate(
        20,
        (index) => Manga(id: 's$index', title: 'Search $index'),
      );

      when(
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics')),
      ).thenAnswer((_) async => const Right<Failure, List<Manga>>(<Manga>[]));
      when(
        () => searchManga(
          'query',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics'),
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
          contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics'),
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
          contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics'),
        ),
      ).called(1);
    });

    test('loads all pages through multiple offsets (0, 20, 40, 60, 80)', () async {
      when(
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics')),
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
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics')),
      ).thenAnswer((_) async => const Right<Failure, List<Manga>>(<Manga>[]));
      when(
        () => searchManga(
          'query',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics'),
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
          contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics'),
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
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics')),
      ).thenAnswer((_) async => const Right<Failure, List<Manga>>(<Manga>[]));
      when(
        () => searchManga(
          'query',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics'),
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
          contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics'),
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
          contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics'),
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
        () => getMangaList(limit: 20, offset: 0, order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics')),
      ).thenAnswer((_) async => Right<Failure, List<Manga>>([freshManga]));
      when(
        () => searchManga(
          'query',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics'),
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
          contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics'),
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
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics')),
      ).thenAnswer((_) async => const Right<Failure, List<Manga>>(<Manga>[]));
      when(
        () => searchManga(
          'query',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics'),
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
          contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics'),
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
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics')),
      ).thenAnswer(
        (_) async => Right<Failure, List<Manga>>(cataloguePage),
      );
      when(
        () => searchManga(
          'query',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics'),
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
        () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order'), genre: any(named: 'genre'), contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics')),
      ).thenAnswer(
        (_) async => Right<Failure, List<Manga>>([catalogueManga]),
      );
      when(
        () => searchManga(
          'query',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'), demographics: any(named: 'demographics'),
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

  group('cache TTL', () {
    test('fresh cache hit skips network call', () async {
      when(
        () => getMangaList(
          limit: 20,
          offset: any(named: 'offset'),
          order: any(named: 'order'),
          genre: any(named: 'genre'),
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, List<Manga>>(mangas),
      );
      when(
        () => searchManga(
          any(),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      ).thenAnswer(
        (_) async => const Right<Failure, SearchResult>(
          SearchResult(mangas: [], limit: 20, offset: 0, total: 0),
        ),
      );

      final notifier = LibraryNotifier(getMangaList, searchManga);
      await Future<void>.delayed(Duration.zero);

      // First load hits the network and caches.
      expect(notifier.state.mangas, hasLength(2));

      // Reset mock tracking — only care about calls AFTER this point.
      clearInteractions(getMangaList);

      // Second load with same key — should serve from cache, no extra call.
      await notifier.loadInitial();
      await Future<void>.delayed(Duration.zero);

      // No network call — fresh cache hit.
      verifyNever(
        () => getMangaList(
          limit: 20,
          offset: any(named: 'offset'),
          order: any(named: 'order'),
          genre: any(named: 'genre'),
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      );

      expect(notifier.state.mangas, hasLength(2));
    });

    test('cache miss triggers network fetch', () async {
      when(
        () => getMangaList(
          limit: 20,
          offset: any(named: 'offset'),
          order: any(named: 'order'),
          genre: any(named: 'genre'),
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, List<Manga>>(mangas),
      );
      when(
        () => searchManga(
          any(),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      ).thenAnswer(
        (_) async => const Right<Failure, SearchResult>(
          SearchResult(mangas: [], limit: 20, offset: 0, total: 0),
        ),
      );

      final notifier = LibraryNotifier(getMangaList, searchManga);
      await Future<void>.delayed(Duration.zero);

      // Constructor load is a cache miss → network call.
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.mangas, hasLength(2));

      // Different key (genre=action) → another cache miss → network call.
      await notifier.setGenre('action');
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.mangas, isNotEmpty);
      verify(
        () => getMangaList(
          limit: 20,
          offset: 0,
          order: any(named: 'order'),
          genre: 'action',
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      ).called(1);
    });

    test('stale cache hit shows LoadingMore and refreshes in background', () async {
      when(
        () => getMangaList(
          limit: 20,
          offset: any(named: 'offset'),
          order: any(named: 'order'),
          genre: any(named: 'genre'),
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, List<Manga>>(mangas),
      );
      when(
        () => searchManga(
          any(),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      ).thenAnswer(
        (_) async => const Right<Failure, SearchResult>(
          SearchResult(mangas: [], limit: 20, offset: 0, total: 0),
        ),
      );

      final notifier = LibraryNotifier(
        getMangaList,
        searchManga,
        enablePreload: false,
      );
      await Future<void>.delayed(Duration.zero);
      clearInteractions(getMangaList);

      // Seed a stale entry for the "romance" genre key (6 min old).
      final staleMangas = <Manga>[
        Manga(id: 'old-1', title: 'Stale One'),
        Manga(id: 'old-2', title: 'Stale Two'),
      ];
      LibraryNotifier.seedCacheEntry(
        mode: LibraryMode.normal,
        genre: 'romance',
        state: LibraryState(
          mangas: staleMangas,
          isLoading: false,
          isLoadingMore: false,
          hasMore: true,
          query: '',
          isSearching: false,
        ),
        cachedAt: DateTime.now().subtract(const Duration(minutes: 6)),
      );

      // Do NOT await — stale path sets state synchronously before _staleRefresh.
      final genreFuture = notifier.setGenre('romance');

      expect(notifier.state.isLoadingMore, isTrue);
      expect(notifier.state.mangas, hasLength(2));
      expect(notifier.state.mangas[0].id, 'old-1');

      // Now await so _staleRefresh runs to completion.
      await genreFuture;
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      // Background refresh fired via the original stub.
      verify(
        () => getMangaList(
          limit: 20,
          offset: 0,
          order: any(named: 'order'),
          genre: 'romance',
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      ).called(1);
    });

    test('stale cache hit keeps grid visible when bg refresh fails', () async {
      when(
        () => getMangaList(
          limit: 20,
          offset: any(named: 'offset'),
          order: any(named: 'order'),
          genre: any(named: 'genre'),
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, List<Manga>>(mangas),
      );
      when(
        () => searchManga(
          any(),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      ).thenAnswer(
        (_) async => const Right<Failure, SearchResult>(
          SearchResult(mangas: [], limit: 20, offset: 0, total: 0),
        ),
      );

      final notifier = LibraryNotifier(
        getMangaList,
        searchManga,
        enablePreload: false,
      );
      await Future<void>.delayed(Duration.zero);

      // Seed a stale entry for the "action" genre (6 min old).
      final staleMangas = <Manga>[
        Manga(id: 'keep-1', title: 'Keep One'),
      ];
      LibraryNotifier.seedCacheEntry(
        mode: LibraryMode.normal,
        genre: 'action',
        state: LibraryState(
          mangas: staleMangas,
          isLoading: false,
          isLoadingMore: false,
          hasMore: true,
          query: '',
          isSearching: false,
        ),
        cachedAt: DateTime.now().subtract(const Duration(minutes: 6)),
      );

      // Stale bg refresh will fail.
      when(
        () => getMangaList(
          limit: 20,
          offset: 0,
          order: any(named: 'order'),
          genre: 'action',
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      ).thenAnswer(
        (_) async => const Left<Failure, List<Manga>>(
          NetworkFailure(message: 'still offline'),
        ),
      );

      // Do NOT await — stale path sets state synchronously.
      final genreFuture = notifier.setGenre('action');

      expect(notifier.state.isLoadingMore, isTrue);
      expect(notifier.state.mangas, hasLength(1));
      expect(notifier.state.mangas[0].id, 'keep-1');
      expect(notifier.state.failure, isNull);

      // Now await so the stale refresh runs and fails.
      await genreFuture;
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      // Grid preserved, failure surfaced.
      expect(notifier.state.isLoadingMore, isFalse);
      expect(notifier.state.mangas, hasLength(1));
      expect(notifier.state.mangas[0].id, 'keep-1');
      expect(notifier.state.failure, isA<NetworkFailure>());
    });
  });

  group('resetExplore scoping', () {
    test('two notifiers: resetExplore on one leaves other keys in cache', () async {
      when(
        () => getMangaList(
          limit: 20,
          offset: any(named: 'offset'),
          order: any(named: 'order'),
          genre: any(named: 'genre'),
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, List<Manga>>(mangas),
      );
      when(
        () => searchManga(
          any(),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      ).thenAnswer(
        (_) async => const Right<Failure, SearchResult>(
          SearchResult(mangas: [], limit: 20, offset: 0, total: 0),
        ),
      );

      final notifierA = LibraryNotifier(getMangaList, searchManga);
      await Future<void>.delayed(Duration.zero);

      // Switch to a genre tab so notifierA has a key in _myCacheKeys.
      await notifierA.setGenre('romance');
      await Future<void>.delayed(Duration.zero);

      // Now switching back to All should be a fresh cache hit.
      clearInteractions(getMangaList);
      await notifierA.loadInitial();
      await Future<void>.delayed(Duration.zero);

      // All served from cache — no network call.
      verifyNever(
        () => getMangaList(
          limit: 20,
          offset: any(named: 'offset'),
          order: any(named: 'order'),
          genre: any(named: 'genre'),
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      );

      // Create notifierB, let it load, then resetExplore it.
      final notifierB = LibraryNotifier(getMangaList, searchManga);
      await Future<void>.delayed(Duration.zero);
      await notifierB.resetExplore();
      await Future<void>.delayed(Duration.zero);

      // notifierA's keys should survive notifierB's resetExplore.
      clearInteractions(getMangaList);
      await notifierA.loadInitial();
      await Future<void>.delayed(Duration.zero);

      verifyNever(
        () => getMangaList(
          limit: 20,
          offset: any(named: 'offset'),
          order: any(named: 'order'),
          genre: any(named: 'genre'),
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      );
    });
  });

  group('refresh removes from _myCacheKeys', () {
    test('refresh evicts key from instance cache set', () async {
      when(
        () => getMangaList(
          limit: 20,
          offset: any(named: 'offset'),
          order: any(named: 'order'),
          genre: any(named: 'genre'),
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, List<Manga>>(mangas),
      );
      when(
        () => searchManga(
          any(),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      ).thenAnswer(
        (_) async => const Right<Failure, SearchResult>(
          SearchResult(mangas: [], limit: 20, offset: 0, total: 0),
        ),
      );

      final notifier = LibraryNotifier(getMangaList, searchManga);
      await Future<void>.delayed(Duration.zero);

      // Initial load wrote to cache and _myCacheKeys.
      // Now refresh — should evict the key from both cache AND _myCacheKeys.
      clearInteractions(getMangaList);
      await notifier.refresh();
      await Future<void>.delayed(Duration.zero);

      // After refresh, the key is removed from _myCacheKeys, so resetExplore
      // should NOT try to remove it again (no-op on next resetExplore).
      verify(
        () => getMangaList(
          limit: 20,
          offset: 0,
          order: any(named: 'order'),
          genre: any(named: 'genre'),
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      ).called(1);
    });
  });

  group('preload', () {
    test('preloads adjacent tabs after successful Home loadInitial', () async {
      when(
        () => getMangaList(
          limit: 20,
          offset: any(named: 'offset'),
          order: any(named: 'order'),
          genre: any(named: 'genre'),
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, List<Manga>>(mangas),
      );
      when(
        () => searchManga(
          any(),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      ).thenAnswer(
        (_) async => const Right<Failure, SearchResult>(
          SearchResult(mangas: [], limit: 20, offset: 0, total: 0),
        ),
      );

      // ignore: unused_local_variable
      final notifier = LibraryNotifier(
        getMangaList,
        searchManga,
        enablePreload: true,
      );
      await Future<void>.delayed(Duration.zero);

      // Let preload fire-and-forget complete.
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Preload fires for 3 adjacent tabs (popular, romance, action).
      // Constructor already called getMangaList once (for 'All' tab).
      // Preload adds 3 more calls.
      verify(
        () => getMangaList(
          limit: 20,
          offset: 0,
          order: any(named: 'order'),
          genre: any(named: 'genre'),
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      ).called(4); // 1 constructor + 3 preload
    });

    test('preload skips fresh entries', () async {
      when(
        () => getMangaList(
          limit: 20,
          offset: any(named: 'offset'),
          order: any(named: 'order'),
          genre: any(named: 'genre'),
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, List<Manga>>(mangas),
      );
      when(
        () => searchManga(
          any(),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      ).thenAnswer(
        (_) async => const Right<Failure, SearchResult>(
          SearchResult(mangas: [], limit: 20, offset: 0, total: 0),
        ),
      );

      final notifier = LibraryNotifier(
        getMangaList,
        searchManga,
        enablePreload: true,
      );
      await Future<void>.delayed(Duration.zero);

      // Preload fires for 3 tabs.
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Reset tracking — only care about calls AFTER this point.
      clearInteractions(getMangaList);

      // Switch to Romance tab — should hit preload cache, no new call.
      await notifier.setGenre('romance');
      await Future<void>.delayed(Duration.zero);

      // No additional network call for 'romance' since preload populated it.
      verifyNever(
        () => getMangaList(
          limit: 20,
          offset: 0,
          order: any(named: 'order'),
          genre: 'romance',
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      );
    });

    test('preload respects _loadVersion guard — discards on version bump', () async {
      int romanceCallCount = 0;
      final romanceCompleter = Completer<Either<Failure, List<Manga>>>();
      when(
        () => getMangaList(
          limit: 20,
          offset: 0,
          order: any(named: 'order'),
          genre: 'romance',
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      ).thenAnswer((_) async {
        romanceCallCount++;
        if (romanceCallCount <= 1) {
          return romanceCompleter.future;
        }
        return Right<Failure, List<Manga>>(mangas);
      });

      // Stub all other getMangaList calls to return immediately.
      when(
        () => getMangaList(
          limit: 20,
          offset: any(named: 'offset'),
          order: any(named: 'order'),
          genre: any(named: 'genre'),
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, List<Manga>>(mangas),
      );
      when(
        () => searchManga(
          any(),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      ).thenAnswer(
        (_) async => const Right<Failure, SearchResult>(
          SearchResult(mangas: [], limit: 20, offset: 0, total: 0),
        ),
      );

      final notifier = LibraryNotifier(
        getMangaList,
        searchManga,
        enablePreload: true,
      );

      // Wait for constructor + popular preload to complete.
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // The first romance preload is still pending in the Completer.
      // Bump _loadVersion by calling loadInitial with different params.
      clearInteractions(getMangaList);
      await notifier.setGenre('action');
      await Future<void>.delayed(Duration.zero);

      // Now complete the first romance preload — should be discarded because
      // the constructor's capturedVersion < current _loadVersion.
      romanceCompleter.complete(
        Right<Failure, List<Manga>>([
          Manga(id: 'preloaded', title: 'Should Be Discarded'),
        ]),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Override the romance cache entry with a stale one so the upcoming
      // setGenre('romance') must go to the network.
      LibraryNotifier.seedCacheEntry(
        mode: LibraryMode.normal,
        genre: 'romance',
        state: LibraryState(
          mangas: <Manga>[Manga(id: 'stale', title: 'Stale Romance')],
          isLoading: false,
          isLoadingMore: false,
          hasMore: true,
          query: '',
          isSearching: false,
        ),
        cachedAt: DateTime.now().subtract(const Duration(minutes: 6)),
      );

      // Switching to romance — stale entry forces network fetch.
      clearInteractions(getMangaList);
      await notifier.setGenre('romance');
      await Future<void>.delayed(Duration.zero);

      // The first preload was discarded (never updated cache), stale-seeded
      // entry forces a real network call.
      verify(
        () => getMangaList(
          limit: 20,
          offset: 0,
          order: any(named: 'order'),
          genre: 'romance',
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      ).called(1);
    });

    test('preload does NOT fire when enablePreload is false', () async {
      when(
        () => getMangaList(
          limit: 20,
          offset: any(named: 'offset'),
          order: any(named: 'order'),
          genre: any(named: 'genre'),
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, List<Manga>>(mangas),
      );
      when(
        () => searchManga(
          any(),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      ).thenAnswer(
        (_) async => const Right<Failure, SearchResult>(
          SearchResult(mangas: [], limit: 20, offset: 0, total: 0),
        ),
      );

      // ignore: unused_local_variable
      final notifier = LibraryNotifier(
        getMangaList,
        searchManga,
        enablePreload: false,
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Only 1 network call (constructor) — no preload.
      verify(
        () => getMangaList(
          limit: 20,
          offset: 0,
          order: any(named: 'order'),
          genre: any(named: 'genre'),
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      ).called(1);
    });
  });
}
