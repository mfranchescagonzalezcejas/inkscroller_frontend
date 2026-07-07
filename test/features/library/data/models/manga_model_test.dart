import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/library/data/models/manga_model.dart';

void main() {
  group('MangaModel.fromJson', () {
    test('falls back to safe defaults for nullable metadata fields', () {
      final model = MangaModel.fromJson(<String, dynamic>{
        'id': 'manga-2',
        'title': 'Vagabond',
        'genres': null,
        'authors': null,
        'rank': null,
      });

      expect(model.id, 'manga-2');
      expect(model.title, 'Vagabond');
      expect(model.genres, isEmpty);
      expect(model.authors, isEmpty);
      expect(model.score, isNull);
      expect(model.rank, isNull);
    });

    test('sanitizes malformed genre/author lists safely', () {
      final model = MangaModel.fromJson(<String, dynamic>{
        'id': 'manga-3',
        'title': 'Dorohedoro',
        'genres': <dynamic>['Action', null, 1, '   '],
        'authors': <dynamic>[null, 'Q Hayashida', 123],
      });

      expect(model.genres, <String>['Action']);
      expect(model.authors, <String>['Q Hayashida']);
    });
  });
}
