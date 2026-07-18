import 'dart:math' as math;

import 'chapter.dart';

/// A batch of chapters for the batching UI (tandas).
///
/// Each batch covers a range `[start, end]` (inclusive) and contains either
/// a real [Chapter] reference or a placeholder for chapters not present in
/// MangaDex.
class ChapterBatch {
  const ChapterBatch({
    required this.start,
    required this.end,
    required this.items,
  });

  final int start;
  final int end;
  final List<ChapterBatchItem> items;

  /// Returns a copy omitting [ReadableChapterBatchItem]s whose chapter ID
  /// is in [hiddenIds]. Placeholders are kept as-is.
  ChapterBatch copyWithFilteredItems(Set<String> hiddenIds) {
    final filtered = items.where((item) {
      return switch (item) {
        ReadableChapterBatchItem(:final chapter) => !hiddenIds.contains(chapter.id),
        PlaceholderChapterBatchItem() => true,
      };
    }).toList();
    return ChapterBatch(start: start, end: end, items: filtered);
  }
}

/// A single item inside a [ChapterBatch] — either a real readable chapter
/// or a placeholder for a chapter number not in MangaDex.
sealed class ChapterBatchItem {}

/// A chapter that exists in MangaDex and can be read.
class ReadableChapterBatchItem extends ChapterBatchItem {
  ReadableChapterBatchItem(this.chapter, this.number);

  final Chapter chapter;
  final int number;
}

/// A chapter number that exists in the total count but not in MangaDex.
class PlaceholderChapterBatchItem extends ChapterBatchItem {
  PlaceholderChapterBatchItem(this.chapterNumber);

  final int chapterNumber;
}

/// Divides `[1..totalChaptersCount]` into batches of [batchSize].
///
/// MangaDex chapters are matched by their [Chapter.number]. Any chapter number
/// in the total range that does not have a matching MangaDex chapter becomes a
/// [PlaceholderChapterBatchItem].
List<ChapterBatch> computeChapterBatches({
  required List<Chapter> chapters,
  required int totalChaptersCount,
  required int batchSize,
}) {
  final effectiveTotal = math.max(totalChaptersCount, chapters.length);
  // Deduplicate by chapter number (first occurrence wins) to match
  // the readChapterIds dedup in ReadingProgressNotifier.
  final Map<int, Chapter> byNumber = <int, Chapter>{};
  for (final chapter in chapters) {
    final num? n = chapter.number;
    if (n != null) {
      byNumber.putIfAbsent(n.toInt(), () => chapter);
    }
  }

  final int batchCount = (effectiveTotal / batchSize).ceil();
  final List<ChapterBatch> batches = <ChapterBatch>[];

  for (int batchIndex = 0; batchIndex < batchCount; batchIndex++) {
    final int start = batchIndex * batchSize + 1;
    final int end = math.min(start + batchSize - 1, effectiveTotal);
    final List<ChapterBatchItem> items = <ChapterBatchItem>[];

    for (int num = start; num <= end; num++) {
      final chapter = byNumber[num];
      if (chapter != null) {
        items.add(ReadableChapterBatchItem(chapter, num));
      } else {
        items.add(PlaceholderChapterBatchItem(num));
      }
    }

    batches.add(ChapterBatch(start: start, end: end, items: items));
  }

  return batches;
}
