import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/chapter.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga_reading_progress.dart';
import 'package:inkscroller_flutter/features/library/domain/repositories/reading_progress_repository.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/reading_progress_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockReadingProgressRepository extends Mock
    implements ReadingProgressRepository {}

void main() {
  late _MockReadingProgressRepository repository;
  late ReadingProgressNotifier notifier;

  setUpAll(() {
    registerFallbackValue(const MangaReadingProgress(mangaId: 'fallback'));
  });

  setUp(() {
    repository = _MockReadingProgressRepository();
    when(
      () => repository.getAll(),
    ).thenAnswer((_) async => const <String, MangaReadingProgress>{});
    when(() => repository.save(any())).thenAnswer((_) async {});
    notifier = ReadingProgressNotifier(repository);
  });

  group('updateManuallyMarkedCount', () {
    test('increments manuallyMarkedCount by delta', () async {
      await notifier.updateManuallyMarkedCount('manga-1', 5);

      final progress = notifier.progressFor('manga-1');
      expect(progress.manuallyMarkedCount, 5);
    });

    test('decrements manuallyMarkedCount by delta', () async {
      // First set to 10
      await notifier.updateManuallyMarkedCount('manga-1', 10);
      // Then decrement by 3
      await notifier.updateManuallyMarkedCount('manga-1', -3);

      final progress = notifier.progressFor('manga-1');
      expect(progress.manuallyMarkedCount, 7);
    });

    test('clamps to zero — never goes below 0', () async {
      await notifier.updateManuallyMarkedCount('manga-1', 5);
      await notifier.updateManuallyMarkedCount('manga-1', -10);

      final progress = notifier.progressFor('manga-1');
      expect(progress.manuallyMarkedCount, 0);
    });

    test('persists via repository', () async {
      await notifier.updateManuallyMarkedCount('manga-1', 5);

      verify(() => repository.save(any())).called(1);
    });

    test('sets updatedAt to now', () async {
      final before = DateTime.now().toUtc();
      await notifier.updateManuallyMarkedCount('manga-1', 5);
      final after = DateTime.now().toUtc();

      final progress = notifier.progressFor('manga-1');
      expect(
        progress.updatedAt.isAfter(before) ||
            progress.updatedAt.isAtSameMomentAs(before),
        isTrue,
      );
      expect(
        progress.updatedAt.isBefore(after) ||
            progress.updatedAt.isAtSameMomentAs(after),
        isTrue,
      );
    });
  });

  group('setBatchSize', () {
    test('updates batchSize', () async {
      await notifier.setBatchSize('manga-1', 50);

      final progress = notifier.progressFor('manga-1');
      expect(progress.batchSize, 50);
    });

    test('persists via repository', () async {
      await notifier.setBatchSize('manga-1', 100);

      verify(() => repository.save(any())).called(1);
    });

    test('does not set updatedAt', () async {
      await notifier.setBatchSize('manga-1', 50);

      final progress = notifier.progressFor('manga-1');
      expect(
        progress.updatedAt,
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        reason: 'updatedAt should remain at epoch default',
      );
    });
  });

  group('syncChapters with backendTotal', () {
    test('uses maxChapterNumber when backendTotal is provided', () async {
      final chapters = <Chapter>[
        Chapter(id: 'c1', number: 1, readable: true, external: false),
        Chapter(id: 'c50', number: 50, readable: true, external: false),
      ];

      await notifier.syncChapters('manga-1', chapters, backendTotal: 200);

      final progress = notifier.progressFor('manga-1');
      expect(progress.totalChaptersCount, 200);
    });

    test('uses maxChapterNumber when no backendTotal', () async {
      final chapters = <Chapter>[
        Chapter(id: 'c1', number: 1, readable: true, external: false),
        Chapter(id: 'c30', number: 30, readable: true, external: false),
      ];

      await notifier.syncChapters('manga-1', chapters);

      final progress = notifier.progressFor('manga-1');
      expect(progress.totalChaptersCount, 30);
    });

    test('never shrinks totalChaptersCount', () async {
      // First sync sets total to 200
      final chapters1 = <Chapter>[
        Chapter(id: 'c1', number: 1, readable: true, external: false),
        Chapter(id: 'c200', number: 200, readable: true, external: false),
      ];
      await notifier.syncChapters('manga-1', chapters1);

      // Second sync with fewer chapters but backendTotal
      final chapters2 = <Chapter>[
        Chapter(id: 'c1', number: 1, readable: true, external: false),
      ];
      await notifier.syncChapters('manga-1', chapters2, backendTotal: 150);

      final progress = notifier.progressFor('manga-1');
      expect(progress.totalChaptersCount, 200);
    });

    test('does not set updatedAt', () async {
      final chapters = <Chapter>[
        Chapter(id: 'c1', number: 1, readable: true, external: false),
      ];
      await notifier.syncChapters('manga-1', chapters);

      final progress = notifier.progressFor('manga-1');
      expect(
        progress.updatedAt,
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        reason: 'updatedAt should remain at epoch default',
      );
    });
  });

  group('setManuallyMarkedCountTo', () {
    test('sets manuallyMarkedCount and readChapterIds', () async {
      final chapters = <Chapter>[
        Chapter(id: 'c1', number: 1, readable: true, external: false),
        Chapter(id: 'c2', number: 2, readable: true, external: false),
        Chapter(id: 'c3', number: 3, readable: true, external: false),
      ];

      await notifier.setManuallyMarkedCountTo('manga-1', 2, chapters: chapters);

      final progress = notifier.progressFor('manga-1');
      expect(progress.manuallyMarkedCount, 2);
      expect(progress.readChapterIds, contains('c1'));
      expect(progress.readChapterIds, contains('c2'));
      expect(progress.readChapterIds, isNot(contains('c3')));
    });

    test('sets updatedAt to now', () async {
      final before = DateTime.now().toUtc();
      await notifier.setManuallyMarkedCountTo('manga-1', 3);
      final after = DateTime.now().toUtc();

      final progress = notifier.progressFor('manga-1');
      expect(
        progress.updatedAt.isAfter(before) ||
            progress.updatedAt.isAtSameMomentAs(before),
        isTrue,
      );
      expect(
        progress.updatedAt.isBefore(after) ||
            progress.updatedAt.isAtSameMomentAs(after),
        isTrue,
      );
    });
  });

  group('toggleChapter', () {
    test('marks chapter as read', () async {
      await notifier.toggleChapter(
        mangaId: 'manga-1',
        chapterId: 'c1',
        totalChaptersCount: 10,
      );

      final progress = notifier.progressFor('manga-1');
      expect(progress.isChapterRead('c1'), isTrue);
      expect(progress.totalChaptersCount, 10);
    });

    test('sets updatedAt to now', () async {
      final before = DateTime.now().toUtc();
      await notifier.toggleChapter(
        mangaId: 'manga-1',
        chapterId: 'c1',
        totalChaptersCount: 10,
      );
      final after = DateTime.now().toUtc();

      final progress = notifier.progressFor('manga-1');
      expect(
        progress.updatedAt.isAfter(before) ||
            progress.updatedAt.isAtSameMomentAs(before),
        isTrue,
      );
      expect(
        progress.updatedAt.isBefore(after) ||
            progress.updatedAt.isAtSameMomentAs(after),
        isTrue,
      );
    });
  });

  group('markThrough', () {
    test('marks all chapters up to target as read', () async {
      final chapters = <Chapter>[
        Chapter(id: 'c1', number: 1, readable: true, external: false),
        Chapter(id: 'c2', number: 2, readable: true, external: false),
        Chapter(id: 'c3', number: 3, readable: true, external: false),
      ];

      await notifier.markThrough(
        mangaId: 'manga-1',
        chapters: chapters,
        targetChapterId: 'c2',
      );

      final progress = notifier.progressFor('manga-1');
      expect(progress.isChapterRead('c1'), isTrue);
      expect(progress.isChapterRead('c2'), isTrue);
      expect(progress.isChapterRead('c3'), isFalse);
    });

    test('sets updatedAt to now', () async {
      final chapters = <Chapter>[
        Chapter(id: 'c1', number: 1, readable: true, external: false),
        Chapter(id: 'c2', number: 2, readable: true, external: false),
      ];
      final before = DateTime.now().toUtc();
      await notifier.markThrough(
        mangaId: 'manga-1',
        chapters: chapters,
        targetChapterId: 'c2',
      );
      final after = DateTime.now().toUtc();

      final progress = notifier.progressFor('manga-1');
      expect(
        progress.updatedAt.isAfter(before) ||
            progress.updatedAt.isAtSameMomentAs(before),
        isTrue,
      );
      expect(
        progress.updatedAt.isBefore(after) ||
            progress.updatedAt.isAtSameMomentAs(after),
        isTrue,
      );
    });
  });
}
