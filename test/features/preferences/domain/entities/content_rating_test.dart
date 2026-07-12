import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/preferences/domain/entities/content_rating.dart';

void main() {
  group('ContentRating', () {
    // ── wireValue ─────────────────────────────────────────────────────────

    test('wireValue returns the enum name', () {
      expect(ContentRating.safe.wireValue, 'safe');
      expect(ContentRating.suggestive.wireValue, 'suggestive');
      expect(ContentRating.all.wireValue, 'all');
    });

    // ── valuesForAge ──────────────────────────────────────────────────────

    test('guest users only see safe', () {
      expect(ContentRating.valuesForAge(25, true), [ContentRating.safe]);
    });

    test('null age only sees safe', () {
      expect(ContentRating.valuesForAge(null, false), [ContentRating.safe]);
    });

    test('under 16 only sees safe', () {
      expect(ContentRating.valuesForAge(15, false), [ContentRating.safe]);
    });

    test('16-17 sees safe and suggestive', () {
      expect(
        ContentRating.valuesForAge(16, false),
        [ContentRating.safe, ContentRating.suggestive],
      );
      expect(
        ContentRating.valuesForAge(17, false),
        [ContentRating.safe, ContentRating.suggestive],
      );
    });

    test('18+ sees all ratings', () {
      expect(
        ContentRating.valuesForAge(18, false),
        ContentRating.values,
      );
      expect(
        ContentRating.valuesForAge(30, false),
        ContentRating.values,
      );
    });

    // ── effectiveForAge ───────────────────────────────────────────────────

    test('guest gets safe regardless of stored', () {
      expect(
        ContentRating.effectiveForAge(25, true, ContentRating.all),
        ContentRating.safe,
      );
    });

    test('null age gets safe regardless of stored', () {
      expect(
        ContentRating.effectiveForAge(null, false, ContentRating.all),
        ContentRating.safe,
      );
    });

    test('under 16 gets safe regardless of stored', () {
      expect(
        ContentRating.effectiveForAge(15, false, ContentRating.all),
        ContentRating.safe,
      );
    });

    test('16-17 with stored suggestive returns suggestive', () {
      expect(
        ContentRating.effectiveForAge(16, false, ContentRating.suggestive),
        ContentRating.suggestive,
      );
    });

    test('16-17 with stored all falls back to safe', () {
      expect(
        ContentRating.effectiveForAge(16, false, ContentRating.all),
        ContentRating.safe,
      );
    });

    test('18+ with no stored preference defaults to suggestive', () {
      expect(
        ContentRating.effectiveForAge(18, false, null),
        ContentRating.suggestive,
      );
    });

    test('18+ with stored all returns all', () {
      expect(
        ContentRating.effectiveForAge(18, false, ContentRating.all),
        ContentRating.all,
      );
    });
  });
}
