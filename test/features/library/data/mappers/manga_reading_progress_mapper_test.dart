import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/library/data/mappers/manga_reading_progress_mapper.dart';
import 'package:inkscroller_flutter/features/library/data/models/manga_reading_progress_model.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga_reading_progress.dart';

void main() {
  test('maps model to domain entity', () {
    const MangaReadingProgressModel model = MangaReadingProgressModel(
      mangaId: 'manga-1',
      readChapterIds: <String>{'c-1', 'c-2'},
      totalChaptersCount: 20,
    );

    final MangaReadingProgress entity = model.toEntity();

    expect(entity.mangaId, model.mangaId);
    expect(entity.readChapterIds, model.readChapterIds);
    expect(entity.totalChaptersCount, model.totalChaptersCount);
  });

  test('maps domain entity to model', () {
    const MangaReadingProgress entity = MangaReadingProgress(
      mangaId: 'manga-1',
      readChapterIds: <String>{'c-1', 'c-2'},
      totalChaptersCount: 20,
    );

    final MangaReadingProgressModel model = entity.toModel();

    expect(model.mangaId, entity.mangaId);
    expect(model.readChapterIds, entity.readChapterIds);
    expect(model.totalChaptersCount, entity.totalChaptersCount);
  });
}
