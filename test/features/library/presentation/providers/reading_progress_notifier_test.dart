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
    when(() => repository.getAll())
        .thenAnswer((_) async => const <String, MangaReadingProgress>{});
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
  });

  group('syncChapters with backendTotal', () {
    test('uses maxChapterNumber when backendTotal is provided', () async {
      final chapters = <Chapter>[
        Chapter(
          id: 'c1',
          number: 1,
          readable: true,
          external: false,
        ),
        Chapter(
          id: 'c50',
          number: 50,
          readable: true,
          external: false,
        ),
      ];

      await notifier.syncChapters(
        'manga-1',
        chapters,
        backendTotal: 200,
      );

      final progress = notifier.progressFor('manga-1');
      expect(progress.totalChaptersCount, 200);
    });

    test('uses maxChapterNumber when no backendTotal', () async {
      final chapters = <Chapter>[
        Chapter(
          id: 'c1',
          number: 1,
          readable: true,
          external: false,
        ),
        Chapter(
          id: 'c30',
          number: 30,
          readable: true,
          external: false,
        ),
      ];

      await notifier.syncChapters('manga-1', chapters);

      final progress = notifier.progressFor('manga-1');
      expect(progress.totalChaptersCount, 30);
    });

    test('never shrinks totalChaptersCount', () async {
      // First sync sets total to 200
      final chapters1 = <Chapter>[
        Chapter(
          id: 'c1',
          number: 1,
          readable: true,
          external: false,
        ),
        Chapter(
          id: 'c200',
          number: 200,
          readable: true,
          external: false,
        ),
      ];
      await notifier.syncChapters('manga-1', chapters1);

      // Second sync with fewer chapters but backendTotal
      final chapters2 = <Chapter>[
        Chapter(
          id: 'c1',
          number: 1,
          readable: true,
          external: false,
        ),
      ];
      await notifier.syncChapters(
        'manga-1',
        chapters2,
        backendTotal: 150,
      );

      final progress = notifier.progressFor('manga-1');
      expect(progress.totalChaptersCount, 200);
    });
  });
}
