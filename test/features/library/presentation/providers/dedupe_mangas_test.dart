import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/library/dedupe_mangas.dart';

void main() {
  group('dedupeMangas', () {
    test('returns an empty list when source is empty', () {
      final result = dedupeMangas([]);

      expect(result, isEmpty);
    });

    test('returns all items unchanged when there are no duplicates', () {
      final source = [
        Manga(id: '1', title: 'Berserk'),
        Manga(id: '2', title: 'Monster'),
        Manga(id: '3', title: 'Vagabond'),
      ];

      final result = dedupeMangas(source);

      expect(result.map((m) => m.id), equals(['1', '2', '3']));
    });

    test('removes duplicates keeping the last occurrence', () {
      final first = Manga(id: '1', title: 'Berserk v1');
      final duplicate = Manga(id: '1', title: 'Berserk v2');
      final other = Manga(id: '2', title: 'Monster');

      final result = dedupeMangas([first, other, duplicate]);

      expect(result, hasLength(2));
      expect(result.map((m) => m.id), containsAll(['1', '2']));
      // last occurrence wins
      final retained = result.firstWhere((m) => m.id == '1');
      expect(retained.title, equals('Berserk v2'));
    });

    test('returns a single-element list when source has one item', () {
      final source = [Manga(id: '42', title: 'One Piece')];

      final result = dedupeMangas(source);

      expect(result, hasLength(1));
      expect(result.first.id, equals('42'));
    });
  });
}
