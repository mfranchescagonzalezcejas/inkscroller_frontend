import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/search_result.dart';

void main() {
  group('SearchResult', () {
    test('holds mangas, limit, offset, and total metadata', () {
      final manga = Manga(id: 'm-1', title: 'Berserk');
      final result = SearchResult(
        mangas: [manga],
        limit: 20,
        offset: 10,
        total: 42,
      );

      expect(result.mangas, [manga]);
      expect(result.limit, 20);
      expect(result.offset, 10);
      expect(result.total, 42);
    });

    test('is const-constructible when empty', () {
      const resultA = SearchResult(
        mangas: [],
        limit: 20,
        offset: 0,
        total: 0,
      );
      const resultB = SearchResult(
        mangas: [],
        limit: 20,
        offset: 0,
        total: 0,
      );

      expect(identical(resultA, resultB), isTrue);
    });
  });
}
