import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/library/data/mappers/chapter_mapper.dart';
import 'package:inkscroller_flutter/features/library/data/models/chapter_model.dart';

void main() {
  test('ChapterModelMapper.toEntity parses chapter number', () {
    final model = ChapterModel(
      id: 'chapter-1',
      number: '4.5',
      title: 'Title',
      date: DateTime.parse('2024-01-01T00:00:00.000Z'),
      readable: true,
      external: false,
    );

    final entity = model.toEntity();

    expect(entity.id, model.id);
    expect(entity.number, 4.5);
    expect(entity.title, model.title);
    expect(entity.date, model.date);
    expect(entity.readable, isTrue);
    expect(entity.external, isFalse);
  });

  test('ChapterModelMapper.toEntity keeps null number as null', () {
    final model = ChapterModel(
      id: 'chapter-2',
      readable: false,
      external: true,
      externalUrl: 'https://external',
    );

    final entity = model.toEntity();

    expect(entity.number, isNull);
    expect(entity.externalUrl, 'https://external');
  });

  test('ChapterModelMapper.toEntity keeps invalid decimals nullable', () {
    final model = ChapterModel(
      id: 'chapter-invalid',
      number: 'special',
      readable: false,
      external: true,
    );

    final entity = model.toEntity();

    expect(entity.number, isNull);
  });
}
