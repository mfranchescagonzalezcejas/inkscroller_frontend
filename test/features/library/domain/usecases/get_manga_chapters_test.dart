import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/chapter.dart';
import 'package:inkscroller_flutter/features/library/domain/repositories/library_repository.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/get_manga_chapters.dart';
import 'package:mocktail/mocktail.dart';

class _MockLibraryRepository extends Mock implements LibraryRepository {}

void main() {
  late LibraryRepository repository;
  late GetMangaChapters useCase;

  setUp(() {
    repository = _MockLibraryRepository();
    useCase = GetMangaChapters(repository);
  });

  test('call forwards language to repository', () async {
    final chapter = Chapter(
      id: 'chapter-1',
      title: 'Chapter 1',
      number: 1,
      readable: true,
      external: false,
      language: 'es',
    );
    when(
      () => repository.getMangaChapters(
        'manga-1',
        language: 'es',
      ),
    ).thenAnswer((_) async => Right([chapter]));

    final result = await useCase('manga-1', language: 'es');

    expect(result.isRight(), isTrue);
    result.fold((_) => fail('expected right'), (chapters) {
      expect(chapters, hasLength(1));
      expect(chapters.first.id, 'chapter-1');
      expect(chapters.first.language, 'es');
    });
    verify(
      () => repository.getMangaChapters('manga-1', language: 'es'),
    ).called(1);
  });

  test('call returns failure when repository fails', () async {
    when(
      () => repository.getMangaChapters(
        any(),
        language: any(named: 'language'),
      ),
    ).thenAnswer((_) async => const Left(NetworkFailure(message: 'offline')));

    final result = await useCase('manga-1', language: 'es');

    expect(result.isLeft(), isTrue);
    result.fold((failure) {
      expect(failure, isA<NetworkFailure>());
      expect(failure.message, 'offline');
    }, (_) => fail('expected left'));
  });
}
