import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga_reading_progress.dart';

void main() {
  group('MangaReadingProgress.updatedAt', () {
    test('defaults to epoch when omitted', () {
      const progress = MangaReadingProgress(mangaId: 'manga-1');

      expect(
        progress.updatedAt,
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
    });

    test('preserves provided timestamp', () {
      final updatedAt = DateTime.utc(2026, 7, 19, 12);
      final progress = MangaReadingProgress(
        mangaId: 'manga-1',
        updatedAt: updatedAt,
      );

      expect(progress.updatedAt, updatedAt);
    });

    test('old JSON without updatedAt sorts last against newer timestamps', () {
      final old = MangaReadingProgress(
        mangaId: 'old',
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
      final recent = MangaReadingProgress(
        mangaId: 'recent',
        updatedAt: DateTime.utc(2026, 7, 19, 12),
      );

      expect(old.updatedAt.isBefore(recent.updatedAt), isTrue);
    });

    test('copyWith preserves updatedAt when not provided', () {
      final updatedAt = DateTime.utc(2026, 7, 19, 12);
      final original = MangaReadingProgress(
        mangaId: 'manga-1',
        updatedAt: updatedAt,
        manuallyMarkedCount: 5,
      );

      final copied = original.copyWith(batchSize: 50);

      expect(copied.updatedAt, updatedAt);
    });

    test('copyWith updates updatedAt when provided', () {
      final original = MangaReadingProgress(
        mangaId: 'manga-1',
        updatedAt: DateTime.utc(2026, 7, 19, 12),
      );
      final newUpdatedAt = DateTime.utc(2026, 7, 20, 12);

      final copied = original.copyWith(updatedAt: newUpdatedAt);

      expect(copied.updatedAt, newUpdatedAt);
    });
  });
}
