import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/get_chapter_pages.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/resolve_reader_mode.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/reader/reader_notifier.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetChapterPages extends Mock implements GetChapterPages {}

class _MockResolveReaderMode extends Mock implements ResolveReaderMode {}

void main() {
  late GetChapterPages getChapterPages;
  late ResolveReaderMode resolveReaderMode;
  late ReaderNotifier notifier;

  setUp(() {
    getChapterPages = _MockGetChapterPages();
    resolveReaderMode = _MockResolveReaderMode();
    notifier = ReaderNotifier(
      getChapterPages: getChapterPages,
      resolveReaderMode: resolveReaderMode,
    );
  });

  test('loadChapter stores failure when use case fails', () async {
    when(() => getChapterPages('chapter-1')).thenAnswer(
      (_) async =>
          const Left<Failure, List<String>>(NetworkFailure(message: 'offline')),
    );

    await notifier.loadChapter(chapterId: 'chapter-1');

    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.failure, isA<NetworkFailure>());
    expect(notifier.state.pages, isEmpty);
  });

  test('loadChapter stores UnexpectedFailure when pages are empty', () async {
    when(
      () => getChapterPages('chapter-1'),
    ).thenAnswer((_) async => const Right<Failure, List<String>>(<String>[]));

    await notifier.loadChapter(chapterId: 'chapter-1');

    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.failure, isA<UnexpectedFailure>());
    expect(notifier.state.failure?.message, 'Capítulo sin páginas');
  });
}
