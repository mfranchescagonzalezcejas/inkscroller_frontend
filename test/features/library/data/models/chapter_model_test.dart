import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/library/data/models/chapter_model.dart';

void main() {
  group('ChapterModel.fromJson', () {
    test('parses a full payload', () {
      final model = ChapterModel.fromJson(<String, dynamic>{
        'id': 'chapter-1',
        'number': '12.5',
        'title': 'The Eclipse',
        'date': '2024-03-10T00:00:00.000Z',
        'readable': true,
        'external': false,
        'externalUrl': null,
      });

      expect(model.id, 'chapter-1');
      expect(model.number, '12.5');
      expect(model.title, 'The Eclipse');
      expect(model.date, DateTime.parse('2024-03-10T00:00:00.000Z'));
      expect(model.readable, isTrue);
      expect(model.external, isFalse);
      expect(model.externalUrl, isNull);
    });

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
