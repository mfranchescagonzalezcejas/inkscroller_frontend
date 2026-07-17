import 'dart:async';

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

  group('first load (cache miss)', () {
    test('shows loading while fetch is in flight', () async {
      final completer = Completer<Either<Failure, List<Chapter>>>();
      when(() => getMangaChapters('manga-1')).thenAnswer(
        (_) => completer.future,
      );

      // Start loadChapters but don't await it yet — we need to check
      // the intermediate loading state.
      final loadFuture = notifier.loadChapters('manga-1');

      // Before the API responds, loading should be visible.
      expect(notifier.state.isLoading, isTrue);
      expect(notifier.state.chapters, isEmpty);

      // Resolve the API call.
      completer.complete(
        Right<Failure, List<Chapter>>(<Chapter>[
          Chapter(id: 'c1', readable: true, external: false),
        ]),
      );
      await loadFuture;

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.chapters, hasLength(1));
      expect(notifier.state.failure, isNull);
    });

    test('stores failure when use case fails and no cache exists', () async {
      when(() => getMangaChapters('manga-1')).thenAnswer(
        (_) async => const Left<Failure, List<Chapter>>(
          ServerFailure(message: 'server error'),
        ),
      );

      await notifier.loadChapters('manga-1');

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.chapters, isEmpty);
      expect(notifier.state.failure, isA<ServerFailure>());
    });
  });

  group('repeat visit (cache hit)', () {
    setUp(() {
      // First load populates the in-memory cache.
      when(() => getMangaChapters('manga-1')).thenAnswer(
        (_) async => Right<Failure, List<Chapter>>(<Chapter>[
          Chapter(id: 'c1', readable: true, external: false),
        ]),
      );
    });

    test('serves cached chapters immediately without loading state', () async {
      // Populate cache via first load.
      await notifier.loadChapters('manga-1');

      // Second load — cache hit, data shown without loading shimmer.
      await notifier.loadChapters('manga-1');

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.chapters, hasLength(1));
      expect(notifier.state.failure, isNull);
    });

    test('keeps cached chapters when background refresh fails', () async {
      // Populate cache via first load.
      await notifier.loadChapters('manga-1');

      // Second load — make the use case fail this time.
      when(() => getMangaChapters('manga-1')).thenAnswer(
        (_) async => const Left<Failure, List<Chapter>>(
          ServerFailure(message: 'server error'),
        ),
      );

      await notifier.loadChapters('manga-1');

      // Should keep the cached chapters and NOT propagate the failure.
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.chapters, hasLength(1));
      expect(notifier.state.failure, isNull);
    });
  });

  group('cross-manga navigation', () {
    test('shows loading for new manga even when another had chapters', () async {
      final completer = Completer<Either<Failure, List<Chapter>>>();
      // Load manga-1 first.
      when(() => getMangaChapters('manga-1')).thenAnswer(
        (_) async => Right<Failure, List<Chapter>>(<Chapter>[
          Chapter(id: 'c1', readable: true, external: false),
        ]),
      );
      await notifier.loadChapters('manga-1');
      expect(notifier.state.chapters, hasLength(1));

      // Load manga-2 — cache miss, should show loading.
      when(() => getMangaChapters('manga-2')).thenAnswer(
        (_) => completer.future,
      );

      final loadFuture = notifier.loadChapters('manga-2');

      // Should be loading because manga-2 is not in cache.
      expect(notifier.state.isLoading, isTrue);
      // Stale chapters from manga-1 should be cleared on cache miss.
      expect(notifier.state.chapters, isEmpty);

      completer.complete(
        Right<Failure, List<Chapter>>(<Chapter>[
          Chapter(id: 'c2', readable: true, external: false),
        ]),
      );
      await loadFuture;

      expect(notifier.state.chapters, hasLength(1));
      expect(notifier.state.chapters.first.id, 'c2');
      expect(notifier.state.isLoading, isFalse);
    });

    test('shows error when new manga fails and previous chapters were cleared',
        () async {
      // Load manga-1 first.
      when(() => getMangaChapters('manga-1')).thenAnswer(
        (_) async => Right<Failure, List<Chapter>>(<Chapter>[
          Chapter(id: 'c1', readable: true, external: false),
        ]),
      );
      await notifier.loadChapters('manga-1');
      expect(notifier.state.chapters, hasLength(1));

      // Load manga-2 — cache miss, API fails.
      when(() => getMangaChapters('manga-2')).thenAnswer(
        (_) async => const Left<Failure, List<Chapter>>(
          ServerFailure(message: 'server error'),
        ),
      );

      await notifier.loadChapters('manga-2');

      // Should show error: previous chapters were cleared, nothing to fall back to.
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.chapters, isEmpty);
      expect(notifier.state.failure, isA<ServerFailure>());
    });
  });

  group('clearCache', () {
    test('clears in-memory cache and resets state', () async {
      // Load chapters first.
      when(() => getMangaChapters('manga-1')).thenAnswer(
        (_) async => Right<Failure, List<Chapter>>(<Chapter>[
          Chapter(id: 'c1', readable: true, external: false),
        ]),
      );
      await notifier.loadChapters('manga-1');
      expect(notifier.state.chapters, hasLength(1));

      // Clear cache.
      notifier.clearCache();

      expect(notifier.state.chapters, isEmpty);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.failure, isNull);

      // Next load should be a cache miss (shimmer then loaded).
      when(() => getMangaChapters('manga-1')).thenAnswer(
        (_) async => Right<Failure, List<Chapter>>(<Chapter>[
          Chapter(id: 'c1', readable: true, external: false),
        ]),
      );

      await notifier.loadChapters('manga-1');
      expect(notifier.state.chapters, hasLength(1));
      expect(notifier.state.isLoading, isFalse);
    });
  });
}
