import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/library/data/models/chapter_model.dart';

void main() {
  group('ChapterModel.fromJson', () {
    test('keeps optional values nullable', () {
      final model = ChapterModel.fromJson(<String, dynamic>{
        'id': 'chapter-2',
        'number': null,
        'title': null,
        'date': null,
        'readable': false,
        'external': true,
        'externalUrl': 'https://external',
      });

      expect(model.number, isNull);
      expect(model.title, isNull);
      expect(model.date, isNull);
      expect(model.readable, isFalse);
      expect(model.external, isTrue);
      expect(model.externalUrl, 'https://external');
    });

    test('parses chapter number from numeric payloads', () {
      final model = ChapterModel.fromJson(<String, dynamic>{
        'id': 'chapter-3',
        'number': 7.5,
        'title': 'Half step',
        'date': null,
        'readable': true,
        'external': false,
      });

      expect(model.number, '7.5');
    });
  });
}
