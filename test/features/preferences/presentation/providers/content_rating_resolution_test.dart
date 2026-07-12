import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/preferences/domain/entities/content_rating.dart';
import 'package:inkscroller_flutter/features/preferences/presentation/providers/content_rating_resolution_provider.dart';

void main() {
  // ── ContentRatingResolution ──────────────────────────────────────────────

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
}
