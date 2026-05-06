import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga.dart';
import 'package:inkscroller_flutter/features/library/domain/repositories/library_repository.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/get_manga_list.dart';
import 'package:mocktail/mocktail.dart';

class _MockLibraryRepository extends Mock implements LibraryRepository {}

void main() {
  late LibraryRepository repository;
  late GetMangaList useCase;

  setUp(() {
    repository = _MockLibraryRepository();
    useCase = GetMangaList(repository);
  });

  test('delegates parameters to repository', () async {
    const expected = Right<Failure, List<Manga>>(<Manga>[]);

    when(
      () => repository.getMangaList(
        limit: 20,
        offset: 40,
        order: <String, String>{'followedCount': 'desc'},
      ),
    ).thenAnswer((_) async => expected);

    final result = await useCase(
      limit: 20,
      offset: 40,
      order: <String, String>{'followedCount': 'desc'},
    );

    expect(result, expected);
    verify(
      () => repository.getMangaList(
        limit: 20,
        offset: 40,
        order: <String, String>{'followedCount': 'desc'},
      ),
    ).called(1);
  });
}
