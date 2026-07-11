import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga.dart';
import 'package:inkscroller_flutter/features/library/domain/repositories/library_repository.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/search_manga.dart';
import 'package:mocktail/mocktail.dart';

class _MockLibraryRepository extends Mock implements LibraryRepository {}

void main() {
  late LibraryRepository repository;
  late SearchManga useCase;

  setUp(() {
    repository = _MockLibraryRepository();
    useCase = SearchManga(repository);
  });

  test('delegates query to repository', () async {
    const expected = Right<Failure, (List<Manga>, int)>((<Manga>[], 0));

    when(
      () => repository.searchManga('monster', limit: 20, offset: 0),
    ).thenAnswer((_) async => expected);

    final result = await useCase('monster', limit: 20, offset: 0);

    expect(result, expected);
    verify(
      () => repository.searchManga('monster', limit: 20, offset: 0),
    ).called(1);
  });
}
