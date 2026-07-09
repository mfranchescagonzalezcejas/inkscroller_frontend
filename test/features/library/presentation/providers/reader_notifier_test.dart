import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/reader_mode.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/reading_preferences.dart';
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

  setUpAll(() {
    registerFallbackValue(const ReaderContentMetadata(pageCount: 0));
  });

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
    expect(notifier.state.failure, isA<EmptyChapterFailure>());
  });

  test('loadChapter abandons initial precache writes after timeout', () async {
    final blockedPrecache = Completer<void>();
    final pages = List.generate(5, (index) => 'https://example.com/$index.jpg');

    when(
      () => getChapterPages('chapter-1'),
    ).thenAnswer((_) async => Right<Failure, List<String>>(pages));
    when(
      () => resolveReaderMode(
        globalReaderMode: any<ReaderMode?>(named: 'globalReaderMode'),
        titleOverride: any<PerTitleOverride?>(named: 'titleOverride'),
        contentMetadata: any<ReaderContentMetadata>(named: 'contentMetadata'),
      ),
    ).thenReturn(ReaderMode.vertical);

    notifier = ReaderNotifier(
      getChapterPages: getChapterPages,
      resolveReaderMode: resolveReaderMode,
      initialPrecacheTimeout: const Duration(milliseconds: 1),
      precacheNetworkImage: (_) => blockedPrecache.future,
    );

    await notifier.loadChapter(chapterId: 'chapter-1');

    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.loadedPages, pages.length);

    blockedPrecache.complete();
    await Future<void>.delayed(Duration.zero);

    expect(notifier.state.loadedPages, pages.length);
  });
}
