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
    expect(model.manuallyMarkedCount, 0);
    expect(model.batchSize, 25);
    expect(
      model.updatedAt,
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  });

  test('fromJson defaults for missing manuallyMarkedCount and batchSize', () {
    final MangaReadingProgressModel model = MangaReadingProgressModel.fromJson(
      <String, dynamic>{
        'mangaId': 'manga-2',
        'readChapterIds': <String>[],
        'totalChaptersCount': 50,
      },
    );

    expect(model.manuallyMarkedCount, 0);
    expect(model.batchSize, 25);
  });

  test('fromJson round-trips new fields', () {
    final MangaReadingProgressModel original = MangaReadingProgressModel(
      mangaId: 'manga-3',
      readChapterIds: const <String>{'c-1'},
      totalChaptersCount: 100,
      manuallyMarkedCount: 42,
      batchSize: 50,
      updatedAt: DateTime.utc(2026, 7, 19, 12),
    );

    final roundTripped = MangaReadingProgressModel.fromJson(original.toJson());

    expect(roundTripped.manuallyMarkedCount, 42);
    expect(roundTripped.batchSize, 50);
    expect(roundTripped.updatedAt, original.updatedAt);
  });

  test('toJson serializes readChapterIds sorted', () {
    final MangaReadingProgressModel model = MangaReadingProgressModel(
      mangaId: 'manga-1',
      readChapterIds: const <String>{'c-10', 'c-1'},
      totalChaptersCount: 100,
      updatedAt: DateTime.utc(2026, 7, 19, 12),
    );

    final Map<String, dynamic> json = model.toJson();

    expect(json['mangaId'], 'manga-1');
    expect(json['readChapterIds'], <String>['c-1', 'c-10']);
    expect(json['totalChaptersCount'], 100);
    expect(json['manuallyMarkedCount'], 0);
    expect(json['batchSize'], 25);
    expect(json['updatedAt'], model.updatedAt!.toIso8601String());
  });

  test('toJson includes manuallyMarkedCount and batchSize', () {
    const MangaReadingProgressModel model = MangaReadingProgressModel(
      mangaId: 'manga-4',
      manuallyMarkedCount: 30,
      batchSize: 100,
    );

    final json = model.toJson();

    expect(json['manuallyMarkedCount'], 30);
    expect(json['batchSize'], 100);
  });
}
