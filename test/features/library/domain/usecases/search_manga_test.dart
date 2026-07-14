import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga_tags.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/search_result.dart';
import 'package:inkscroller_flutter/features/library/domain/repositories/library_repository.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/search_manga.dart';
import 'package:mocktail/mocktail.dart';

class _MockLibraryRepository extends Mock implements LibraryRepository {}

void main() {
  late LibraryRepository repository;
  late SearchManga useCase;

  final result = SearchResult(
    mangas: [Manga(id: '1', title: 'Berserk')],
    limit: 20,
    offset: 0,
    total: 1,
  );

  setUp(() {
    repository = _MockLibraryRepository();
    useCase = SearchManga(repository);
  });

  test('forwards query, limit and offset to repository', () async {
    final expected = Right<Failure, SearchResult>(result);

    when(
      () => repository.searchManga(
        'monster',
        limit: 20,
        offset: 0,
        contentRating: any(named: 'contentRating'),
        demographics: any(named: 'demographics'),
      ),
    ).thenAnswer((_) async => expected);

    final actual = await useCase('monster', limit: 20, offset: 0);

    expect(actual, expected);
    verify(
      () => repository.searchManga(
        'monster',
        limit: 20,
        offset: 0,
        contentRating: any(named: 'contentRating'),
        demographics: any(named: 'demographics'),
      ),
    ).called(1);
  });

  test('forwards demographics to repository', () async {
    final expected = Right<Failure, SearchResult>(result);
    const demographics = <MangaDemographic>[
      MangaDemographic.shounen,
      MangaDemographic.unspecified,
    ];

    when(
      () => repository.searchManga(
        'monster',
        limit: 20,
        offset: 0,
        contentRating: any(named: 'contentRating'),
        demographics: demographics,
      ),
    ).thenAnswer((_) async => expected);

    final actual = await useCase(
      'monster',
      limit: 20,
      offset: 0,
      demographics: demographics,
    );

    expect(actual, expected);
    verify(
      () => repository.searchManga(
        'monster',
        limit: 20,
        offset: 0,
        contentRating: any(named: 'contentRating'),
        demographics: demographics,
      ),
    ).called(1);
  });

  test('returns SearchResult on success', () async {
    when(
      () => repository.searchManga(
        any(),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
        contentRating: any(named: 'contentRating'),
        demographics: any(named: 'demographics'),
      ),
    ).thenAnswer((_) async => Right<Failure, SearchResult>(result));

    final actual = await useCase('query', limit: 10, offset: 20);

    expect(actual, Right<Failure, SearchResult>(result));
  });

  test('returns Failure on error', () async {
    const failure = NetworkFailure(message: 'offline');
    when(
      () => repository.searchManga(
        any(),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
        contentRating: any(named: 'contentRating'),
        demographics: any(named: 'demographics'),
      ),
    ).thenAnswer((_) async => const Left<Failure, SearchResult>(failure));

    final actual = await useCase('query', limit: 10, offset: 20);

    expect(actual, const Left<Failure, SearchResult>(failure));
  });
}
