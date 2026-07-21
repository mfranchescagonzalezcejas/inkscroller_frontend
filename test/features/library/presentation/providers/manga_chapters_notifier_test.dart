import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/chapter.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/chapters_with_languages.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/get_manga_chapters.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/get_manga_chapters_with_languages.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/get_manga_languages.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/chapters/manga_chapters_notifier.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetMangaChapters extends Mock implements GetMangaChapters {}

class _MockGetMangaChaptersWithLanguages extends Mock
    implements GetMangaChaptersWithLanguages {}

class _MockGetMangaLanguages extends Mock implements GetMangaLanguages {}

void main() {
  late GetMangaChapters getMangaChapters;
  late GetMangaChaptersWithLanguages getMangaChaptersWithLanguages;
  late GetMangaLanguages getMangaLanguages;
  late MangaChaptersNotifier notifier;

  setUp(() {
    getMangaChapters = _MockGetMangaChapters();
    getMangaChaptersWithLanguages = _MockGetMangaChaptersWithLanguages();
    getMangaLanguages = _MockGetMangaLanguages();
    notifier = MangaChaptersNotifier(
      getMangaChapters: getMangaChapters,
      getMangaLanguages: getMangaLanguages,
      getMangaChaptersWithLanguages: getMangaChaptersWithLanguages,
    );
  });

  group('first load (cache miss)', () {
    test('shows loading while fetch is in flight', () async {
      final completer = Completer<Either<Failure, List<Chapter>>>();
      when(() => getMangaChapters('manga-1', language: 'en')).thenAnswer(
        (_) => completer.future,
      );

      // Start loadChapters but don't await it yet — we need to check
      // the intermediate loading state.
      final loadFuture = notifier.loadChapters('manga-1');

      // Before the API responds, loading should be visible.
      expect(notifier.state.isLoading, isTrue);
      expect(notifier.state.chapters, isEmpty);
      expect(notifier.state.selectedLanguage, 'en');

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
      when(() => getMangaChapters('manga-1', language: 'en')).thenAnswer(
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
      when(() => getMangaChapters('manga-1', language: 'en')).thenAnswer(
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
      when(() => getMangaChapters('manga-1', language: 'en')).thenAnswer(
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
      when(() => getMangaChapters('manga-1', language: 'en')).thenAnswer(
        (_) async => Right<Failure, List<Chapter>>(<Chapter>[
          Chapter(id: 'c1', readable: true, external: false),
        ]),
      );
      await notifier.loadChapters('manga-1');
      expect(notifier.state.chapters, hasLength(1));

      // Load manga-2 — cache miss, should show loading.
      when(() => getMangaChapters('manga-2', language: 'en')).thenAnswer(
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
      when(() => getMangaChapters('manga-1', language: 'en')).thenAnswer(
        (_) async => Right<Failure, List<Chapter>>(<Chapter>[
          Chapter(id: 'c1', readable: true, external: false),
        ]),
      );
      await notifier.loadChapters('manga-1');
      expect(notifier.state.chapters, hasLength(1));

      // Load manga-2 — cache miss, API fails.
      when(() => getMangaChapters('manga-2', language: 'en')).thenAnswer(
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

  group('stale response guard', () {
    test('ignores stale response when navigating to another manga mid-flight',
        () async {
      final completer = Completer<Either<Failure, List<Chapter>>>();
      when(() => getMangaChapters('manga-1', language: 'en')).thenAnswer(
        (_) => completer.future,
      );
      when(() => getMangaChapters('manga-2', language: 'en')).thenAnswer(
        (_) async => Right<Failure, List<Chapter>>(<Chapter>[
          Chapter(id: 'c2', readable: true, external: false),
        ]),
      );

      // Start loading manga-1, but don't await yet.
      final manga1Future = notifier.loadChapters('manga-1');
      expect(notifier.state.isLoading, isTrue);

      // Navigate to manga-2 — this should update _lastRequestKey.
      await notifier.loadChapters('manga-2');
      expect(notifier.state.chapters.first.id, 'c2');

      // Now resolve manga-1 — its response should be ignored since
      // manga-2 was the last requested.
      completer.complete(
        Right<Failure, List<Chapter>>(<Chapter>[
          Chapter(id: 'c1', readable: true, external: false),
        ]),
      );
      await manga1Future;

      // State should still be manga-2's data.
      expect(notifier.state.chapters, hasLength(1));
      expect(notifier.state.chapters.first.id, 'c2');
    });
  });

  group('empty cache hit', () {
    test('keeps empty chapter list when background refresh fails', () async {
      // First load — cache miss, API returns empty list.
      when(() => getMangaChapters('manga-1', language: 'en')).thenAnswer(
        (_) async => const Right<Failure, List<Chapter>>(<Chapter>[]),
      );
      await notifier.loadChapters('manga-1');
      expect(notifier.state.chapters, isEmpty);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.failure, isNull);

      // Second load — cache hit, API fails.
      when(() => getMangaChapters('manga-1', language: 'en')).thenAnswer(
        (_) async => const Left<Failure, List<Chapter>>(
          ServerFailure(message: 'server error'),
        ),
      );
      await notifier.loadChapters('manga-1');

      // Should keep the cached empty list, NOT show an error.
      expect(notifier.state.chapters, isEmpty);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.failure, isNull);
    });
  });

  group('clearCache', () {
    test('clears in-memory cache and resets state', () async {
      // Load chapters first.
      when(() => getMangaChapters('manga-1', language: 'en')).thenAnswer(
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
      expect(notifier.state.availableLanguages, <String>['en']);
      expect(notifier.state.selectedLanguage, 'en');
      expect(notifier.state.isLanguageLoading, isFalse);

      // Next load should be a cache miss (shimmer then loaded).
      when(() => getMangaChapters('manga-1', language: 'en')).thenAnswer(
        (_) async => Right<Failure, List<Chapter>>(<Chapter>[
          Chapter(id: 'c1', readable: true, external: false),
        ]),
      );

      await notifier.loadChapters('manga-1');
      expect(notifier.state.chapters, hasLength(1));
      expect(notifier.state.isLoading, isFalse);
    });
  });

  group('language support', () {
    test('loadChapters passes language param to use case', () async {
      when(() => getMangaChapters('manga-1', language: 'es')).thenAnswer(
        (_) async => Right<Failure, List<Chapter>>(<Chapter>[
          Chapter(id: 'c1-es', readable: true, external: false),
        ]),
      );

      await notifier.loadChapters('manga-1', language: 'es');

      expect(notifier.state.selectedLanguage, 'es');
      expect(notifier.state.chapters, hasLength(1));
      expect(notifier.state.chapters.first.id, 'c1-es');
      verify(() => getMangaChapters('manga-1', language: 'es')).called(1);
    });

    test('loadLanguages success updates availableLanguages and chapters', () async {
      when(() => getMangaChaptersWithLanguages('manga-1', preferredLang: any(named: 'preferredLang'))).thenAnswer(
        (_) async => Right<Failure, ChaptersWithLanguages>(
          ChaptersWithLanguages(
            availableLanguages: ['en', 'es', 'ja'],
            matchedLanguage: 'en',
            chapters: [
              Chapter(id: 'c1', readable: true, external: false),
            ],
          ),
        ),
      );

      await notifier.loadLanguages('manga-1');

      expect(notifier.state.isLanguageLoading, isFalse);
      expect(notifier.state.availableLanguages, <String>['en', 'es', 'ja']);
      expect(notifier.state.selectedLanguage, 'en');
      expect(notifier.state.chapters, hasLength(1));
    });

    test('loadLanguages failure falls back to [en]', () async {
      when(() => getMangaChaptersWithLanguages('manga-1', preferredLang: any(named: 'preferredLang'))).thenAnswer(
        (_) async => const Left<Failure, ChaptersWithLanguages>(
          ServerFailure(message: 'server error'),
        ),
      );

      await notifier.loadLanguages('manga-1');

      expect(notifier.state.isLanguageLoading, isFalse);
      expect(notifier.state.availableLanguages, <String>['en']);
    });

    test('per-language cache independence keeps distinct chapter lists', () async {
      when(() => getMangaChapters('manga-1', language: 'en')).thenAnswer(
        (_) async => Right<Failure, List<Chapter>>(<Chapter>[
          Chapter(id: 'c1-en', readable: true, external: false),
        ]),
      );
      when(() => getMangaChapters('manga-1', language: 'es')).thenAnswer(
        (_) async => Right<Failure, List<Chapter>>(<Chapter>[
          Chapter(id: 'c1-es', readable: true, external: false),
        ]),
      );

      await notifier.loadChapters('manga-1', language: 'en');
      expect(notifier.state.chapters.first.id, 'c1-en');

      await notifier.loadChapters('manga-1', language: 'es');
      expect(notifier.state.chapters.first.id, 'c1-es');

      await notifier.loadChapters('manga-1', language: 'en');
      expect(notifier.state.chapters.first.id, 'c1-en');
    });

    test('composite stale guard discards previous language response', () async {
      final enCompleter = Completer<Either<Failure, List<Chapter>>>();
      when(() => getMangaChapters('manga-1', language: 'en')).thenAnswer(
        (_) => enCompleter.future,
      );
      when(() => getMangaChapters('manga-1', language: 'es')).thenAnswer(
        (_) async => Right<Failure, List<Chapter>>(<Chapter>[
          Chapter(id: 'c1-es', readable: true, external: false),
        ]),
      );

      // Start loading English chapters.
      final enFuture = notifier.loadChapters('manga-1', language: 'en');
      expect(notifier.state.isLoading, isTrue);

      // Switch to Spanish before English resolves.
      await notifier.loadChapters('manga-1', language: 'es');
      expect(notifier.state.chapters.first.id, 'c1-es');
      expect(notifier.state.selectedLanguage, 'es');

      // Resolve the older English request.
      enCompleter.complete(
        Right<Failure, List<Chapter>>(<Chapter>[
          Chapter(id: 'c1-en', readable: true, external: false),
        ]),
      );
      await enFuture;

      // State must still reflect Spanish, not the stale English response.
      expect(notifier.state.chapters, hasLength(1));
      expect(notifier.state.chapters.first.id, 'c1-es');
      expect(notifier.state.selectedLanguage, 'es');
    });

    test('cross-manga reset resets language to default', () async {
      when(() => getMangaChapters('manga-1', language: 'es')).thenAnswer(
        (_) async => Right<Failure, List<Chapter>>(<Chapter>[
          Chapter(id: 'c1-es', readable: true, external: false),
        ]),
      );
      when(() => getMangaChapters('manga-2', language: 'en')).thenAnswer(
        (_) async => Right<Failure, List<Chapter>>(<Chapter>[
          Chapter(id: 'c2-en', readable: true, external: false),
        ]),
      );

      await notifier.loadChapters('manga-1', language: 'es');
      expect(notifier.state.selectedLanguage, 'es');

      await notifier.loadChapters('manga-2');
      expect(notifier.state.selectedLanguage, 'en');
      expect(notifier.state.chapters.first.id, 'c2-en');
    });

    test('clearCache resets language state', () async {
      when(() => getMangaChapters('manga-1', language: 'es')).thenAnswer(
        (_) async => Right<Failure, List<Chapter>>(<Chapter>[
          Chapter(id: 'c1-es', readable: true, external: false),
        ]),
      );
      when(() => getMangaChaptersWithLanguages('manga-1', preferredLang: any(named: 'preferredLang'))).thenAnswer(
        (_) async => const Right<Failure, ChaptersWithLanguages>(
          ChaptersWithLanguages(
            availableLanguages: ['en', 'es'],
            matchedLanguage: 'en',
            chapters: [],
          ),
        ),
      );

      await notifier.loadLanguages('manga-1');
      await notifier.loadChapters('manga-1', language: 'es');
      expect(notifier.state.availableLanguages, <String>['en', 'es']);
      expect(notifier.state.selectedLanguage, 'es');

      notifier.clearCache();

      expect(notifier.state.availableLanguages, <String>['en']);
      expect(notifier.state.selectedLanguage, 'en');
      expect(notifier.state.isLanguageLoading, isFalse);
    });

    test('changing language reloads chapters with new lang', () async {
      when(() => getMangaChapters('manga-1', language: 'en')).thenAnswer(
        (_) async => Right<Failure, List<Chapter>>(<Chapter>[
          Chapter(id: 'c1-en', readable: true, external: false),
        ]),
      );
      when(() => getMangaChapters('manga-1', language: 'es')).thenAnswer(
        (_) async => Right<Failure, List<Chapter>>(<Chapter>[
          Chapter(id: 'c1-es', readable: true, external: false),
        ]),
      );

      await notifier.loadChapters('manga-1');
      expect(notifier.state.selectedLanguage, 'en');
      expect(notifier.state.chapters.first.id, 'c1-en');

      await notifier.loadChapters('manga-1', language: 'es');
      expect(notifier.state.selectedLanguage, 'es');
      expect(notifier.state.chapters.first.id, 'c1-es');
      verify(() => getMangaChapters('manga-1', language: 'es')).called(1);
    });
  });
}
