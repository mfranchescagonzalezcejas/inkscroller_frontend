import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/library/domain/repositories/library_repository.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/get_manga_languages.dart';
import 'package:mocktail/mocktail.dart';

class _MockLibraryRepository extends Mock implements LibraryRepository {}

void main() {
  late LibraryRepository repository;
  late GetMangaLanguages useCase;

  setUp(() {
    repository = _MockLibraryRepository();
    useCase = GetMangaLanguages(repository);
  });

  test('call delegates to repository and returns language list', () async {
    when(() => repository.getMangaLanguages('manga-1')).thenAnswer(
      (_) async => const Right(['en', 'es']),
    );

    final result = await useCase('manga-1');

    expect(result, equals(const Right<Failure, List<String>>(['en', 'es'])));
    verify(() => repository.getMangaLanguages('manga-1')).called(1);
  });

  test('call returns failure when repository fails', () async {
    when(() => repository.getMangaLanguages('manga-1')).thenAnswer(
      (_) async => const Left(ServerFailure(message: 'server down', code: 500)),
    );

    final result = await useCase('manga-1');

    expect(result.isLeft(), isTrue);
    result.fold((failure) {
      expect(failure, isA<ServerFailure>());
      expect(failure.message, 'server down');
      expect(failure.code, 500);
    }, (_) => fail('expected left'));
  });
}
