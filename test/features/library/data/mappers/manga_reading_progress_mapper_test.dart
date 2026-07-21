import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/library/data/mappers/manga_reading_progress_mapper.dart';
import 'package:inkscroller_flutter/features/library/data/models/manga_reading_progress_model.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga_reading_progress.dart';

void main() {
  test('maps model to domain entity with new fields', () {
    final MangaReadingProgressModel model = MangaReadingProgressModel(
      mangaId: 'manga-1',
      readChapterIds: const <String>{'c-1', 'c-2'},
      totalChaptersCount: 20,
      manuallyMarkedCount: 42,
      batchSize: 50,
      updatedAt: DateTime.utc(2026, 7, 19, 12),
    );

    final MangaReadingProgress entity = model.toEntity();

    expect(entity.mangaId, model.mangaId);
    expect(entity.readChapterIds, model.readChapterIds);
    expect(entity.totalChaptersCount, model.totalChaptersCount);
    expect(entity.manuallyMarkedCount, 42);
    expect(entity.batchSize, 50);
    expect(entity.updatedAt, model.updatedAt);
  });

  test('maps domain entity to model with new fields', () {
    final MangaReadingProgress entity = MangaReadingProgress(
      mangaId: 'manga-1',
      readChapterIds: const <String>{'c-1', 'c-2'},
      totalChaptersCount: 20,
      manuallyMarkedCount: 10,
      batchSize: 100,
      updatedAt: DateTime.utc(2026, 7, 19, 12),
    );

    final MangaReadingProgressModel model = entity.toModel();

    expect(model.mangaId, entity.mangaId);
    expect(model.readChapterIds, entity.readChapterIds);
    expect(model.totalChaptersCount, entity.totalChaptersCount);
    expect(model.manuallyMarkedCount, 10);
    expect(model.batchSize, 100);
    expect(model.updatedAt, entity.updatedAt);
  });

  test(
    'readChaptersCount returns max of readChapterIds.length and manuallyMarkedCount',
    () {
      const MangaReadingProgress progress = MangaReadingProgress(
        mangaId: 'manga-1',
        readChapterIds: <String>{'c-1', 'c-2', 'c-3'},
        manuallyMarkedCount: 25,
      );

      expect(progress.readChaptersCount, 25);
    },
  );

  test('readChaptersCount returns readChapterIds.length when larger', () {
    const MangaReadingProgress progress = MangaReadingProgress(
      mangaId: 'manga-1',
      readChapterIds: <String>{'c-1', 'c-2', 'c-3', 'c-4', 'c-5'},
      manuallyMarkedCount: 3,
    );

    expect(progress.readChaptersCount, 5);
  });

  test('copyWith preserves manuallyMarkedCount and batchSize', () {
    const MangaReadingProgress original = MangaReadingProgress(
      mangaId: 'manga-1',
      readChapterIds: <String>{'c-1'},
      totalChaptersCount: 100,
      manuallyMarkedCount: 15,
      batchSize: 50,
    );

    final copied = original.copyWith(batchSize: 100);

    expect(copied.manuallyMarkedCount, 15);
    expect(copied.batchSize, 100);
  });
}
