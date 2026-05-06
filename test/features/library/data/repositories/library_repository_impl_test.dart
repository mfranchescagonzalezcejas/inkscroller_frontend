import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/error/exceptions.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/library/data/datasources/library_local_ds.dart';
import 'package:inkscroller_flutter/features/library/data/datasources/library_remote_ds.dart';
import 'package:inkscroller_flutter/features/library/data/models/chapter_model.dart';
import 'package:inkscroller_flutter/features/library/data/models/manga_model.dart';
import 'package:inkscroller_flutter/features/library/data/repositories/library_repository_impl.dart';
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
  });

  test('searchManga maps datasource models into entities', () async {
    when(
      () => remoteDataSource.searchManga('berserk'),
    ).thenAnswer(
      (_) async => <MangaModel>[const MangaModel(id: '1', title: 'Berserk')],
    );

    final result = await repository.searchManga('berserk');

    expect(result, isA<Right<Failure, dynamic>>());
    result.fold((_) => fail('expected right'), (mangas) {
      expect(mangas.single.id, '1');
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
