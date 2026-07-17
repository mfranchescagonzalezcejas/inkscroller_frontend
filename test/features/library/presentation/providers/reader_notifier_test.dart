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

  test('loadChapter stores EmptyChapterFailure when pages are empty', () async {
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

  // ── Background precache batch ───────────────────────────────────────────

  group('background precache batch', () {
    const _initialPrecacheCount = 5;

    test('completes after initial display and loadedPages reaches total', () async {
      const pageCount = 8;
      final pages = List.generate(
        pageCount,
        (i) => 'https://example.com/$i.jpg',
      );

      when(() => getChapterPages('ch-bg')).thenAnswer(
        (_) async => Right<Failure, List<String>>(pages),
      );
      when(() => resolveReaderMode(
        globalReaderMode: any(named: 'globalReaderMode'),
        titleOverride: any(named: 'titleOverride'),
        contentMetadata: any(named: 'contentMetadata'),
      )).thenReturn(ReaderMode.vertical);

      notifier = ReaderNotifier(
        getChapterPages: getChapterPages,
        resolveReaderMode: resolveReaderMode,
        initialPrecacheTimeout: const Duration(milliseconds: 1),
        precacheNetworkImage: (_) async {},
      );

      await notifier.loadChapter(chapterId: 'ch-bg');

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.loadedPages, _initialPrecacheCount);
      expect(notifier.state.pages.length, pageCount);

      // Let the unawaited background batch drain.
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.loadedPages, pageCount);
    });

    test('individual page failures do not block remaining pages', () async {
      const pageCount = 8;
      final pages = List.generate(
        pageCount,
        (i) => 'https://example.com/$i.jpg',
      );
      // pages[6] is in the background sublist (pages.sublist(5)).
      final failUrl = pages[6];

      when(() => getChapterPages('ch-fail')).thenAnswer(
        (_) async => Right<Failure, List<String>>(pages),
      );
      when(() => resolveReaderMode(
        globalReaderMode: any(named: 'globalReaderMode'),
        titleOverride: any(named: 'titleOverride'),
        contentMetadata: any(named: 'contentMetadata'),
      )).thenReturn(ReaderMode.vertical);

      notifier = ReaderNotifier(
        getChapterPages: getChapterPages,
        resolveReaderMode: resolveReaderMode,
        initialPrecacheTimeout: const Duration(milliseconds: 1),
        precacheNetworkImage: (url) async {
          if (url == failUrl) throw Exception('fail');
        },
      );

      await notifier.loadChapter(chapterId: 'ch-fail');
      await Future<void>.delayed(Duration.zero);

      // All 8 pages processed: initial 5 load + 3 background pages
      // (2 succeed, 1 throws, but loaded increments either way).
      expect(notifier.state.loadedPages, pageCount);
    });

    test(
      '_loadGeneration guard prevents stale background writes across '
      'chapter loads',
      () async {
        final firstPages = List.generate(
          8,
          (i) => 'https://example.com/first-$i.jpg',
        );
        final secondPages = List.generate(
          3,
          (i) => 'https://example.com/second-$i.jpg',
        );
        final slowCompleter = Completer<void>();

        when(() => getChapterPages('ch-first')).thenAnswer(
          (_) async => Right<Failure, List<String>>(firstPages),
        );
        when(() => getChapterPages('ch-second')).thenAnswer(
          (_) async => Right<Failure, List<String>>(secondPages),
        );
        when(() => resolveReaderMode(
          globalReaderMode: any(named: 'globalReaderMode'),
          titleOverride: any(named: 'titleOverride'),
          contentMetadata: any(named: 'contentMetadata'),
        )).thenReturn(ReaderMode.vertical);

        notifier = ReaderNotifier(
          getChapterPages: getChapterPages,
          resolveReaderMode: resolveReaderMode,
          initialPrecacheTimeout: const Duration(milliseconds: 1),
          precacheNetworkImage: (url) async {
            if (url == firstPages[6]) await slowCompleter.future;
          },
        );

        await notifier.loadChapter(chapterId: 'ch-first');
        expect(notifier.state.loadedPages, _initialPrecacheCount);

        // Load a second chapter while the first's background batch is still
        // blocked — this bumps _loadGeneration.
        await notifier.loadChapter(chapterId: 'ch-second');
        expect(notifier.state.loadedPages, secondPages.length);

        // Release the blocked background page.
        slowCompleter.complete();
        await Future<void>.delayed(Duration.zero);

        // The first's stale background write must NOT have overwritten state.
        expect(notifier.state.loadedPages, secondPages.length);
        expect(notifier.state.pages, secondPages);
      },
    );
  });
}
