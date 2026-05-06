import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/library/data/models/manga_reading_progress_model.dart';

void main() {
  test('fromJson parses model fields with defaults', () {
    final MangaReadingProgressModel model = MangaReadingProgressModel.fromJson(
      <String, dynamic>{
        'mangaId': 'manga-1',
        'readChapterIds': <String>['c-2', 'c-1'],
      },
    );

    expect(model.mangaId, 'manga-1');
    expect(model.readChapterIds, <String>{'c-1', 'c-2'});
    expect(model.totalChaptersCount, 0);
  });

  test('toJson serializes readChapterIds sorted', () {
    const MangaReadingProgressModel model = MangaReadingProgressModel(
      mangaId: 'manga-1',
      readChapterIds: <String>{'c-10', 'c-1'},
      totalChaptersCount: 100,
    );

    final Map<String, dynamic> json = model.toJson();

    expect(json['mangaId'], 'manga-1');
    expect(json['readChapterIds'], <String>['c-1', 'c-10']);
    expect(json['totalChaptersCount'], 100);
  });
}
