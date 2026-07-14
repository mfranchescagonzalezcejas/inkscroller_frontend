import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/error/exceptions.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/library/data/datasources/library_local_ds.dart';
import 'package:inkscroller_flutter/features/library/data/datasources/library_remote_ds.dart';
import 'package:inkscroller_flutter/features/library/data/models/chapter_model.dart';
import 'package:inkscroller_flutter/features/library/data/models/manga_model.dart';
import 'package:inkscroller_flutter/features/library/data/models/search_result_model.dart';
import 'package:inkscroller_flutter/features/library/data/repositories/library_repository_impl.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga_tags.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/search_result.dart';
import 'package:mocktail/mocktail.dart';

class _MockLibraryRemoteDataSource extends Mock
    implements LibraryRemoteDataSource {}

class _MockLibraryLocalDataSource extends Mock
    implements LibraryLocalDataSource {}

void main() {
  setUpAll(() {
    registerFallbackValue(const Duration(minutes: 1));
    registerFallbackValue(const MangaModel(id: 'fallback', title: 'fallback'));
    registerFallbackValue(<MangaModel>[]);
    registerFallbackValue(
      ChapterModel(id: 'fallback', readable: true, external: false),
    );
    registerFallbackValue(<ChapterModel>[]);
    registerFallbackValue(<String, String>{});
    registerFallbackValue(<String>[]);
    registerFallbackValue(<MangaDemographic>[]);
    registerFallbackValue(
      const SearchResultModel(
        mangas: [],
        limit: 20,
        offset: 0,
        total: 0,
      ),
    );
  });

  late LibraryRemoteDataSource remoteDataSource;
  late LibraryLocalDataSource localDataSource;
  late LibraryRepositoryImpl repository;

  setUp(() {
    remoteDataSource = _MockLibraryRemoteDataSource();
    localDataSource = _MockLibraryLocalDataSource();
    repository = LibraryRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
      mangaListCacheTtl: const Duration(minutes: 10),
      mangaDetailCacheTtl: const Duration(minutes: 30),
      mangaChaptersCacheTtl: const Duration(minutes: 15),
    );

    when(
      () => localDataSource.cacheMangaList(
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
        order: any(named: 'order'),
        genre: any(named: 'genre'),
        contentRating: any(named: 'contentRating'),
        demographics: any(named: 'demographics'),
        mangas: any(named: 'mangas'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => localDataSource.cacheMangaDetail(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => localDataSource.cacheMangaChapters(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => localDataSource.getCachedMangaList(
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
        order: any(named: 'order'),
        genre: any(named: 'genre'),
        contentRating: any(named: 'contentRating'),
        demographics: any(named: 'demographics'),
        maxAge: any(named: 'maxAge'),
      ),
    ).thenAnswer((_) async => null);
    when(
      () => localDataSource.getCachedMangaDetail(
        any(),
        maxAge: any(named: 'maxAge'),
      ),
    ).thenAnswer((_) async => null);
    when(
      () => localDataSource.getCachedMangaChapters(
        any(),
        maxAge: any(named: 'maxAge'),
      ),
    ).thenAnswer((_) async => null);
  });

  group('getMangaList', () {
    test('returns mapped entities when datasource succeeds', () async {
      when(
        () => remoteDataSource.getMangaList(
          limit: 20,
          offset: 0,
        ),
      ).thenAnswer(
        (_) async => <MangaModel>[
          const MangaModel(id: '1', title: 'Berserk'),
          const MangaModel(id: '2', title: 'Monster'),
        ],
      );

      final result = await repository.getMangaList(limit: 20, offset: 0);

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected right'), (mangas) {
        expect(mangas, hasLength(2));
        expect(mangas.first.title, 'Berserk');
      });
    });

    test('maps AppException into typed Failure', () async {
      when(
        () => remoteDataSource.getMangaList(
          limit: 20,
          offset: 0,
        ),
      ).thenThrow(const ServerException(message: 'server down', code: 500));

      final result = await repository.getMangaList(limit: 20, offset: 0);

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'server down');
        expect(failure.code, 500);
      }, (_) => fail('expected left'));
    });

    test('maps unknown exceptions into UnexpectedFailure', () async {
      when(
        () => remoteDataSource.getMangaList(
          limit: 20,
          offset: 0,
        ),
      ).thenThrow(Exception('boom'));

      final result = await repository.getMangaList(limit: 20, offset: 0);

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<UnexpectedFailure>());
        expect(failure.message, contains('boom'));
      }, (_) => fail('expected left'));
    });

    test('returns cached mangas when remote fails', () async {
      when(
        () => remoteDataSource.getMangaList(
          limit: 20,
          offset: 0,
        ),
      ).thenThrow(const NetworkException(message: 'offline'));
      when(
        () => localDataSource.getCachedMangaList(
          limit: 20,
          offset: 0,
          maxAge: any(named: 'maxAge'),
        ),
      ).thenAnswer(
        (_) async => <MangaModel>[const MangaModel(id: 'cached', title: 'Cached')],
      );

      final result = await repository.getMangaList(limit: 20, offset: 0);

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected right'), (mangas) {
        expect(mangas.single.id, 'cached');
      });
    });

    test('persisted cache key includes genre, contentRating and demographics', () async {
      when(
        () => remoteDataSource.getMangaList(
          limit: 20,
          offset: 0,
          genre: 'action',
          contentRating: 'safe',
          demographics: [MangaDemographic.shounen, MangaDemographic.unspecified],
        ),
      ).thenAnswer(
        (_) async => <MangaModel>[const MangaModel(id: '1', title: 'One')],
      );

      await repository.getMangaList(
        limit: 20,
        offset: 0,
        genre: 'action',
        contentRating: 'safe',
        demographics: [MangaDemographic.shounen, MangaDemographic.unspecified],
      );

      verify(
        () => localDataSource.cacheMangaList(
          limit: 20,
          offset: 0,
          genre: 'action',
          contentRating: 'safe',
          demographics: ['shounen', 'unspecified'],
          mangas: [const MangaModel(id: '1', title: 'One')],
        ),
      ).called(1);
    });
  });

  group('searchManga', () {
    test('forwards limit, offset and contentRating to datasource', () async {
      when(
        () => remoteDataSource.searchManga(
          'berserk',
          limit: 20,
          offset: 10,
          contentRating: 'safe',
          demographics: any(named: 'demographics'),
        ),
      ).thenAnswer(
        (_) async => const SearchResultModel(
          mangas: [MangaModel(id: '1', title: 'Berserk')],
          limit: 20,
          offset: 10,
          total: 1,
        ),
      );

      await repository.searchManga(
        'berserk',
        limit: 20,
        offset: 10,
        contentRating: 'safe',
      );

      verify(
        () => remoteDataSource.searchManga(
          'berserk',
          limit: 20,
          offset: 10,
          contentRating: 'safe',
          demographics: any(named: 'demographics'),
        ),
      ).called(1);
    });

    test('forwards demographics to datasource', () async {
      const demographics = <MangaDemographic>[
        MangaDemographic.shounen,
        MangaDemographic.unspecified,
      ];
      when(
        () => remoteDataSource.searchManga(
          'berserk',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'),
          demographics: demographics,
        ),
      ).thenAnswer(
        (_) async => const SearchResultModel(
          mangas: [MangaModel(id: '1', title: 'Berserk')],
          limit: 20,
          offset: 0,
          total: 1,
        ),
      );

      await repository.searchManga(
        'berserk',
        limit: 20,
        offset: 0,
        demographics: demographics,
      );

      verify(
        () => remoteDataSource.searchManga(
          'berserk',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'),
          demographics: demographics,
        ),
      ).called(1);
    });

    test('search memory cache isolates different demographic filters', () async {
      const filterA = <MangaDemographic>[MangaDemographic.shounen];
      const filterB = <MangaDemographic>[MangaDemographic.shoujo];

      when(
        () => remoteDataSource.searchManga(
          'query',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      ).thenAnswer((invocation) async {
        final symbol = Symbol('demographics');
        final demographics = invocation.namedArguments[symbol]
            as List<MangaDemographic>?;
        if (demographics == filterA) {
          return const SearchResultModel(
            mangas: [MangaModel(id: 'a', title: 'A')],
            limit: 20,
            offset: 0,
            total: 1,
          );
        }
        return const SearchResultModel(
          mangas: [MangaModel(id: 'b', title: 'B')],
          limit: 20,
          offset: 0,
          total: 1,
        );
      });

      final resultA = await repository.searchManga(
        'query',
        limit: 20,
        offset: 0,
        demographics: filterA,
      );
      final resultB = await repository.searchManga(
        'query',
        limit: 20,
        offset: 0,
        demographics: filterB,
      );

      resultA.fold((_) => fail('expected right'), (searchResult) {
        expect(searchResult.mangas.single.id, 'a');
      });
      resultB.fold((_) => fail('expected right'), (searchResult) {
        expect(searchResult.mangas.single.id, 'b');
      });

      // Now fail the network and verify each filter falls back to its own cache.
      when(
        () => remoteDataSource.searchManga(
          'query',
          limit: 20,
          offset: 0,
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      ).thenThrow(const NetworkException(message: 'offline'));

      final cachedA = await repository.searchManga(
        'query',
        limit: 20,
        offset: 0,
        demographics: filterA,
      );
      final cachedB = await repository.searchManga(
        'query',
        limit: 20,
        offset: 0,
        demographics: filterB,
      );

      cachedA.fold((_) => fail('expected right'), (searchResult) {
        expect(searchResult.mangas.single.id, 'a');
      });
      cachedB.fold((_) => fail('expected right'), (searchResult) {
        expect(searchResult.mangas.single.id, 'b');
      });
    });

    test('maps SearchResultModel to SearchResult entity', () async {
      when(
        () => remoteDataSource.searchManga(
          'monster',
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          contentRating: any(named: 'contentRating'),
        ),
      ).thenAnswer(
        (_) async => const SearchResultModel(
          mangas: [MangaModel(id: '1', title: 'Berserk')],
          limit: 20,
          offset: 0,
          total: 1,
        ),
      );

      final result = await repository.searchManga(
        'monster',
        limit: 20,
        offset: 0,
      );

      expect(result, isA<Right<Failure, SearchResult>>());
      result.fold((_) => fail('expected right'), (searchResult) {
        expect(searchResult.mangas, hasLength(1));
        expect(searchResult.mangas.single.id, '1');
        expect(searchResult.limit, 20);
        expect(searchResult.offset, 0);
        expect(searchResult.total, 1);
      });
    });

    test('maps AppException into typed Failure', () async {
      when(
        () => remoteDataSource.searchManga(
          any(),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          contentRating: any(named: 'contentRating'),
        ),
      ).thenThrow(const ServerException(message: 'server down', code: 500));

      final result = await repository.searchManga(
        'berserk',
        limit: 20,
        offset: 0,
      );

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, 'server down');
        expect(failure.code, 500);
      }, (_) => fail('expected left'));
    });

    test('maps unknown exceptions into UnexpectedFailure', () async {
      when(
        () => remoteDataSource.searchManga(
          any(),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          contentRating: any(named: 'contentRating'),
        ),
      ).thenThrow(Exception('boom'));

      final result = await repository.searchManga(
        'berserk',
        limit: 20,
        offset: 0,
      );

      expect(result.isLeft(), isTrue);
      result.fold((failure) {
        expect(failure, isA<UnexpectedFailure>());
        expect(failure.message, contains('boom'));
      }, (_) => fail('expected left'));
    });
  });

  test('getMangaChapters returns cached chapters when remote fails', () async {
    when(() => remoteDataSource.getMangaChapters('manga-1')).thenThrow(
      const NetworkException(message: 'offline'),
    );
    when(
      () => localDataSource.getCachedMangaChapters(
        'manga-1',
        maxAge: any(named: 'maxAge'),
      ),
    ).thenAnswer(
      (_) async => <ChapterModel>[
        ChapterModel(id: 'chapter-1', readable: true, external: false),
      ],
    );

    final result = await repository.getMangaChapters('manga-1');

    expect(result.isRight(), isTrue);
    result.fold((_) => fail('expected right'), (chapters) {
      expect(chapters.single.id, 'chapter-1');
    });
  });
}
