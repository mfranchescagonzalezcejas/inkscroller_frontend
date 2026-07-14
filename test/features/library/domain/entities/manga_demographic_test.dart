import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga_tags.dart';

void main() {
  group('MangaDemographic enum', () {
    test('has all 5 values — kodomo removed (not in MangaDex)', () {
      expect(MangaDemographic.values.length, 5);
    });

    test('toJson returns lowercase name for all values', () {
      expect(MangaDemographic.shounen.toJson(), 'shounen');
      expect(MangaDemographic.shoujo.toJson(), 'shoujo');
      expect(MangaDemographic.seinen.toJson(), 'seinen');
      expect(MangaDemographic.josei.toJson(), 'josei');
      expect(MangaDemographic.unspecified.toJson(), 'unspecified');
    });

    test('fromJson parses all valid values', () {
      expect(MangaDemographic.fromJson('shounen'), MangaDemographic.shounen);
      expect(MangaDemographic.fromJson('shoujo'), MangaDemographic.shoujo);
      expect(MangaDemographic.fromJson('seinen'), MangaDemographic.seinen);
      expect(MangaDemographic.fromJson('josei'), MangaDemographic.josei);
      expect(
        MangaDemographic.fromJson('unspecified'),
        MangaDemographic.unspecified,
      );
    });

    test('fromJson maps unknown values to unspecified', () {
      expect(MangaDemographic.fromJson('ecchi'), MangaDemographic.unspecified);
      expect(MangaDemographic.fromJson('kodomo'), MangaDemographic.unspecified);
    });

    test('fromJson is case-sensitive — unknown casing maps to unspecified', () {
      expect(MangaDemographic.fromJson('Shounen'), MangaDemographic.unspecified);
    });

    test('roundtrip toJson/fromJson preserves value', () {
      for (final value in MangaDemographic.values) {
        expect(MangaDemographic.fromJson(value.toJson()), value);
      }
    });
  });
}
