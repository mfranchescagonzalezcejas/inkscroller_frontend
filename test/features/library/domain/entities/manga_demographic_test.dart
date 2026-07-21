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

    test('tryFromJson returns null for unknown values', () {
      expect(MangaDemographic.tryFromJson('ecchi'), isNull);
      expect(MangaDemographic.tryFromJson('kodomo'), isNull);
    });

    test('fromJson returns default for unknown values', () {
      expect(MangaDemographic.fromJson('ecchi'), MangaDemographic.shounen);
      expect(MangaDemographic.fromJson('kodomo'), MangaDemographic.shounen);
    });

    test('fromJson is case-sensitive — unknown casing falls back to default', () {
      expect(MangaDemographic.fromJson('Shounen'), MangaDemographic.shounen);
    });

    test('roundtrip toJson/fromJson preserves value', () {
      for (final value in MangaDemographic.values) {
        expect(MangaDemographic.fromJson(value.toJson()), value);
      }
    });
  });

  group('canonicalDemographicsKey', () {
    test('returns none for null', () {
      expect(canonicalDemographicsKey(null), 'none');
    });

    test('returns none for empty list', () {
      expect(canonicalDemographicsKey(<String>[]), 'none');
    });

    test('sorts and deduplicates values', () {
      expect(
        canonicalDemographicsKey(<String>['seinen', 'shounen', 'shounen']),
        'seinen,shounen',
      );
    });

    test('maps reordered input to the same canonical key', () {
      expect(
        canonicalDemographicsKey(<String>['shoujo', 'shounen']),
        canonicalDemographicsKey(<String>['shounen', 'shoujo']),
      );
    });
  });
}
