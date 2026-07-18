import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/chapter.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/chapter_batch.dart';

void main() {
  List<Chapter> makeChapters(int count, {double startNumber = 1}) {
    return List.generate(
      count,
      (i) => Chapter(
        id: 'ch-${startNumber + i}',
        number: startNumber + i,
        readable: true,
        external: false,
      ),
    );
  }

  group('computeChapterBatches', () {
    test('produces 44 batches for 1100 chapters with batchSize 25', () {
      final chapters = makeChapters(100);
      final batches = computeChapterBatches(
        chapters: chapters,
        totalChaptersCount: 1100,
        batchSize: 25,
      );

      expect(batches.length, 44);
      // Last batch should have 1100 % 25 = 0 items → actually 25
      // because 1100/25 = 44 exactly
      expect(batches.last.end, 1100);
      expect(batches.first.start, 1);
      expect(batches.first.end, 25);
    });

    test('inserts placeholder items for chapters absent from MangaDex', () {
      final chapters = makeChapters(10); // only chapters 1-10
      final batches = computeChapterBatches(
        chapters: chapters,
        totalChaptersCount: 15,
        batchSize: 25,
      );

      expect(batches.length, 1);
      expect(batches.first.items.length, 15);

      // First 10 items should be readable
      final readables = batches.first.items
          .whereType<ReadableChapterBatchItem>()
          .toList();
      expect(readables.length, 10);

      // Last 5 should be placeholders
      final placeholders = batches.first.items
          .whereType<PlaceholderChapterBatchItem>()
          .toList();
      expect(placeholders.length, 5);
      expect(placeholders.first.chapterNumber, 11);
      expect(placeholders.last.chapterNumber, 15);
    });

    test('handles empty chapters list', () {
      final batches = computeChapterBatches(
        chapters: const <Chapter>[],
        totalChaptersCount: 10,
        batchSize: 25,
      );

      expect(batches.length, 1);
      expect(batches.first.items.length, 10);
      expect(
        batches.first.items.every((item) => item is PlaceholderChapterBatchItem),
        isTrue,
      );
    });

    test('handles totalChaptersCount less than chapters length', () {
      final chapters = makeChapters(30);
      final batches = computeChapterBatches(
        chapters: chapters,
        totalChaptersCount: 20,
        batchSize: 25,
      );

      // Should use chapters.length (30) since it's larger
      expect(batches.length, 2); // ceil(30/25) = 2
      expect(batches.last.end, 30);
    });

    test('handles batchSize of 10', () {
      final chapters = makeChapters(5);
      final batches = computeChapterBatches(
        chapters: chapters,
        totalChaptersCount: 25,
        batchSize: 10,
      );

      expect(batches.length, 3); // ceil(25/10) = 3
      expect(batches[0].items.length, 10);
      expect(batches[1].items.length, 10);
      expect(batches[2].items.length, 5);
    });

    test('matches chapter by number, not list position', () {
      // Chapters 1, 3, 5 exist (gaps at 2, 4)
      final chapters = <Chapter>[
        Chapter(id: 'c1', number: 1, readable: true, external: false),
        Chapter(id: 'c3', number: 3, readable: true, external: false),
        Chapter(id: 'c5', number: 5, readable: true, external: false),
      ];

      final batches = computeChapterBatches(
        chapters: chapters,
        totalChaptersCount: 5,
        batchSize: 25,
      );

      expect(batches.length, 1);
      expect(batches.first.items.length, 5);

      final readables = batches.first.items
          .whereType<ReadableChapterBatchItem>()
          .toList();
      expect(readables.length, 3);

      final placeholders = batches.first.items
          .whereType<PlaceholderChapterBatchItem>()
          .toList();
      expect(placeholders.length, 2);
      expect(placeholders.map((p) => p.chapterNumber).toList(), [2, 4]);
    });
  });
}
