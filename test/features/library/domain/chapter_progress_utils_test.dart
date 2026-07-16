import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/library/domain/chapter_progress_utils.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/chapter.dart';

void main() {
  test('formatChapterNumber strips trailing decimal zeroes', () {
    expect(formatChapterNumber(3), '3');
    expect(formatChapterNumber(12.5), '12.5');
  });

  test('chaptersUpToTarget orders decimals before specials', () {
    final chapters = <Chapter>[
      Chapter(id: 'special', title: 'Special', readable: false, external: true),
      Chapter(id: 'c10', number: 10, readable: true, external: false),
      Chapter(id: 'c9.5', number: 9.5, readable: true, external: false),
      Chapter(id: 'c9', number: 9, readable: true, external: false),
    ];

    final ordered = chaptersUpToTarget(chapters, 'c10');

    expect(ordered.map((chapter) => chapter.id), <String>['c9', 'c9.5', 'c10']);
  });

  group('organizeChapters', () {
    final chapters = <Chapter>[
      Chapter(id: 'c10', number: 10, readable: true, external: false),
      Chapter(id: 'c1', number: 1, readable: true, external: false),
      Chapter(id: 'c5', number: 5, readable: true, external: false),
      Chapter(id: 'extra', readable: false, external: true),
    ];

    test('sorts ascending by default', () {
      final result = organizeChapters(chapters);
      expect(result.map((c) => c.id), <String>['c1', 'c5', 'c10', 'extra']);
    });

    test('reverses order when descending', () {
      final result = organizeChapters(chapters, descending: true);
      // Extras stay at the bottom even in descending order.
      expect(result.map((c) => c.id), <String>['c10', 'c5', 'c1', 'extra']);
    });

    test('filters out read chapters', () {
      final result = organizeChapters(
        chapters,
        readChapterIds: {'c1', 'c5'},
      );
      expect(result.map((c) => c.id), <String>['c10', 'extra']);
    });

    test('combines descending + unread filter', () {
      final result = organizeChapters(
        chapters,
        descending: true,
        readChapterIds: {'c5'},
      );
      expect(result.map((c) => c.id), <String>['c10', 'c1', 'extra']);
    });

    test('empty readChapterIds keeps all', () {
      final result = organizeChapters(
        chapters,
        readChapterIds: <String>{},
      );
      expect(result.length, 4);
    });

    test('null readChapterIds keeps all (filter inactive)', () {
      final result = organizeChapters(chapters);
      expect(result.map((c) => c.id),
          <String>['c1', 'c5', 'c10', 'extra']);
    });

    test('unnumbered chapters always at the bottom (descending)', () {
      final result = organizeChapters(chapters, descending: true);
      expect(result.last.number, isNull);
      expect(result.map((c) => c.id),
          <String>['c10', 'c5', 'c1', 'extra']);
    });

    test('unnumbered chapters always at the bottom (ascending)', () {
      final result = organizeChapters(chapters);
      expect(result.last.number, isNull);
      expect(result.map((c) => c.id),
          <String>['c1', 'c5', 'c10', 'extra']);
    });
  });
}
