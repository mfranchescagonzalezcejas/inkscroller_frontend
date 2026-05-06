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
}
