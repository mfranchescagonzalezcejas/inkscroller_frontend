import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga.dart';
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

  test('loadInitial stores mangas and enables pagination when full page', () async {
    when(
      () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order')),
    ).thenAnswer(
      (_) async => Right<Failure, List<Manga>>(
        List<Manga>.generate(20, (index) => Manga(id: '$index', title: 'Manga $index')),
      ),
    );

    when(() => searchManga(any())).thenAnswer(
      (_) async => const Right<Failure, List<Manga>>(<Manga>[]),
    );

    final notifier = LibraryNotifier(getMangaList, searchManga);
    await Future<void>.delayed(Duration.zero);

    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.mangas, hasLength(20));
    expect(notifier.state.hasMore, isTrue);
    expect(notifier.state.failure, isNull);
  });

  test('loadInitial stores failure when use case fails', () async {
    when(
      () => getMangaList(limit: 20, offset: any(named: 'offset'), order: any(named: 'order')),
    ).thenAnswer(
      (_) async => const Left<Failure, List<Manga>>(
        NetworkFailure(message: 'offline'),
      ),
    );
    when(() => searchManga(any())).thenAnswer(
      (_) async => const Right<Failure, List<Manga>>(<Manga>[]),
    );

    final notifier = LibraryNotifier(getMangaList, searchManga);
    await Future<void>.delayed(Duration.zero);

    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.mangas, isEmpty);
    expect(notifier.state.failure, isA<NetworkFailure>());
  });

  test('loadMore appends and deduplicates mangas', () async {
    final initialPage = <Manga>[
      ...mangas,
      ...List<Manga>.generate(
        18,
        (index) => Manga(id: 'seed-$index', title: 'Seed $index'),
      ),
    ];

    when(
      () => getMangaList(limit: 20, offset: 0),
    ).thenAnswer((_) async => Right<Failure, List<Manga>>(initialPage));
    when(
      () => getMangaList(limit: 20, offset: 20),
    ).thenAnswer(
      (_) async => Right<Failure, List<Manga>>(<Manga>[
        mangas.first,
        Manga(id: '3', title: 'Pluto'),
      ]),
    );
    when(() => searchManga(any())).thenAnswer(
      (_) async => const Right<Failure, List<Manga>>(<Manga>[]),
    );

    final notifier = LibraryNotifier(getMangaList, searchManga);
    await Future<void>.delayed(Duration.zero);
    await notifier.loadMore();

    final ids = notifier.state.mangas.map((manga) => manga.id).toList();

    expect(ids.where((id) => id == '1'), hasLength(1));
    expect(ids, containsAll(<String>['1', '2', '3']));
    expect(ids.last, '3');
  });
}
