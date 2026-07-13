import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/library/data/models/manga_model.dart';
import 'package:inkscroller_flutter/features/library/data/models/search_result_model.dart';

void main() {
  group('SearchResultModel.fromJson', () {
    test('parses full envelope and maps nested manga', () {
      final model = SearchResultModel.fromJson(<String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'manga-1',
            'title': 'Berserk',
          },
          <String, dynamic>{
            'id': 'manga-2',
            'title': 'Monster',
          },
        ],
        'limit': 20,
        'offset': 10,
        'total': 42,
      });

      expect(model.mangas, hasLength(2));
      expect(model.mangas.first, isA<MangaModel>());
      expect(model.mangas.first.id, 'manga-1');
      expect(model.mangas.first.title, 'Berserk');
      expect(model.limit, 20);
      expect(model.offset, 10);
      expect(model.total, 42);
    });

    test('uses empty list when data key is missing', () {
      final model = SearchResultModel.fromJson(<String, dynamic>{
        'limit': 10,
        'offset': 0,
        'total': 0,
      });

      expect(model.mangas, isEmpty);
      expect(model.limit, 10);
      expect(model.offset, 0);
      expect(model.total, 0);
    });

    test('preserves zero total and empty data', () {
      final model = SearchResultModel.fromJson(<String, dynamic>{
        'data': <Map<String, dynamic>>[],
        'limit': 20,
        'offset': 0,
        'total': 0,
      });

      expect(model.mangas, isEmpty);
      expect(model.total, 0);
    });
  });

  group('SearchResultModel.toEntity', () {
    test('maps manga models to domain entities and preserves metadata', () {
      final model = SearchResultModel.fromJson(<String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'manga-1',
            'title': 'Berserk',
          },
        ],
        'limit': 20,
        'offset': 0,
        'total': 1,
      });

      final entity = model.toEntity();

      expect(entity.mangas, hasLength(1));
      expect(entity.mangas.single.id, 'manga-1');
      expect(entity.mangas.single.title, 'Berserk');
      expect(entity.limit, 20);
      expect(entity.offset, 0);
      expect(entity.total, 1);
    });
  });
}
