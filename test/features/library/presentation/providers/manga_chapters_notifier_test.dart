import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/chapter.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/get_manga_chapters.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/chapters/manga_chapters_notifier.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetMangaChapters extends Mock implements GetMangaChapters {}

void main() {
  late GetMangaChapters getMangaChapters;
  late MangaChaptersNotifier notifier;

  setUp(() {
    getMangaChapters = _MockGetMangaChapters();
    notifier = MangaChaptersNotifier(getMangaChapters: getMangaChapters);
  });

  test('loadChapters stores loaded chapters', () async {
    when(() => getMangaChapters('manga-1')).thenAnswer(
      (_) async => Right<Failure, List<Chapter>>(<Chapter>[
        Chapter(id: 'c1', readable: true, external: false),
      ]),
    );

    await notifier.loadChapters('manga-1');

    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.chapters, hasLength(1));
    expect(notifier.state.failure, isNull);
  });

  test('loadChapters stores failure when use case fails', () async {
    when(() => getMangaChapters('manga-1')).thenAnswer(
      (_) async => const Left<Failure, List<Chapter>>(
        ServerFailure(message: 'server error'),
      ),
    );

    await notifier.loadChapters('manga-1');

    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.failure, isA<ServerFailure>());
  });
}
