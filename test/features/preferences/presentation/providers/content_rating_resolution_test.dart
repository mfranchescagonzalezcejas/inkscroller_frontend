import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/preferences/domain/entities/content_rating.dart';
import 'package:inkscroller_flutter/features/preferences/presentation/providers/content_rating_resolution_provider.dart';

void main() {
  // ── ContentRatingResolution (data holder) ────────────────────────────────

  group('ContentRatingResolution', () {
    test('holds effective rating, allowed options, and editability', () {
      const resolution = ContentRatingResolution(
        effectiveRating: ContentRating.suggestive,
        allowedOptions: [ContentRating.safe, ContentRating.suggestive],
        isEditable: true,
      );

      expect(resolution.effectiveRating, ContentRating.suggestive);
      expect(
        resolution.allowedOptions,
        [ContentRating.safe, ContentRating.suggestive],
      );
      expect(resolution.isEditable, isTrue);
    });

    test('isEditable is false when only one option allowed', () {
      const resolution = ContentRatingResolution(
        effectiveRating: ContentRating.safe,
        allowedOptions: [ContentRating.safe],
        isEditable: false,
      );

      expect(resolution.isEditable, isFalse);
      expect(resolution.allowedOptions.length, 1);
    });
  });

  // ── resolve (pure function) ──────────────────────────────────────────────

  group('ContentRatingResolution.resolve', () {
    late DateTime fixedNow;

    setUp(() {
      fixedNow = DateTime(2026, 7, 12);
    });

    test('guest user resolves to safe, not editable', () {
      final result = ContentRatingResolution.resolve(
        isGuest: true,
        birthDate: DateTime(2000),
        stored: ContentRating.all,
        now: fixedNow,
      );

      expect(result.effectiveRating, ContentRating.safe);
      expect(result.allowedOptions, [ContentRating.safe]);
      expect(result.isEditable, isFalse);
    });

    test('under-16 resolves to safe, not editable', () {
      final result = ContentRatingResolution.resolve(
        isGuest: false,
        birthDate: DateTime(2012),
        now: fixedNow,
      );

      expect(result.effectiveRating, ContentRating.safe);
      expect(result.allowedOptions, [ContentRating.safe]);
      expect(result.isEditable, isFalse);
    });

    test('16-17 resolves to suggestive, editable', () {
      final result = ContentRatingResolution.resolve(
        isGuest: false,
        birthDate: DateTime(2009),
        now: fixedNow,
      );

      expect(result.effectiveRating, ContentRating.suggestive);
      expect(
        result.allowedOptions,
        [ContentRating.safe, ContentRating.suggestive],
      );
      expect(result.isEditable, isTrue);
    });

    test('18+ defaults to suggestive, editable, all options', () {
      final result = ContentRatingResolution.resolve(
        isGuest: false,
        birthDate: DateTime(1990),
        now: fixedNow,
      );

      expect(result.effectiveRating, ContentRating.suggestive);
      expect(result.allowedOptions, ContentRating.values);
      expect(result.isEditable, isTrue);
    });

    test('stored preference is used when within allowed options', () {
      final result = ContentRatingResolution.resolve(
        isGuest: false,
        birthDate: DateTime(1990),
        stored: ContentRating.safe,
        now: fixedNow,
      );

      expect(result.effectiveRating, ContentRating.safe);
    });

    test('stored all is kept for 18+', () {
      final result = ContentRatingResolution.resolve(
        isGuest: false,
        birthDate: DateTime(1990),
        stored: ContentRating.all,
        now: fixedNow,
      );

      expect(result.effectiveRating, ContentRating.all);
    });

    test('missing birth date resolves to safe, not editable', () {
      final result = ContentRatingResolution.resolve(
        isGuest: false,
        now: fixedNow,
      );

      expect(result.effectiveRating, ContentRating.safe);
      expect(result.allowedOptions, [ContentRating.safe]);
      expect(result.isEditable, isFalse);
    });

    test('birthday today — age is correct (not off by one)', () {
      // Born July 12, 1990 — turns 36 today
      final result = ContentRatingResolution.resolve(
        isGuest: false,
        birthDate: DateTime(1990, 7, 12),
        now: fixedNow,
      );

      // Age should be 36, so 18+ → suggestive default, editable
      expect(result.effectiveRating, ContentRating.suggestive);
      expect(result.isEditable, isTrue);
    });

    test('birthday tomorrow — age is correct year younger', () {
      // Born July 13, 1990 — still 35 until tomorrow
      final result = ContentRatingResolution.resolve(
        isGuest: false,
        birthDate: DateTime(1990, 7, 13),
        now: fixedNow,
      );

      // Age should be 35, still 18+ → suggestive
      expect(result.effectiveRating, ContentRating.suggestive);
      expect(result.isEditable, isTrue);
    });
  });
}
