import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga_tags.dart';
import 'package:inkscroller_flutter/features/preferences/domain/entities/demographic_resolution.dart';

void main() {
  // ── DemographicResolution (data holder) ────────────────────────────────

  group('DemographicResolution', () {
    test('holds effectiveFilter and allowedOptions', () {
      const resolution = DemographicResolution(
        effectiveFilter: [MangaDemographic.shounen, MangaDemographic.shoujo],
        allowedOptions: MangaDemographic.values,
      );

      expect(
        resolution.effectiveFilter,
        [MangaDemographic.shounen, MangaDemographic.shoujo],
      );
      expect(resolution.allowedOptions, MangaDemographic.values);
    });
  });

  // ── DemographicResolution.resolve (pure function) ──────────────────────

  group('DemographicResolution.resolve', () {
    test('guest with no stored preference gets default [shounen, shoujo]', () {
      final result = DemographicResolution.resolve(isGuest: true);

      expect(
        result.effectiveFilter,
        [MangaDemographic.shounen, MangaDemographic.shoujo],
      );
      expect(
        result.allowedOptions,
        [MangaDemographic.kodomo, MangaDemographic.shounen, MangaDemographic.shoujo],
      );
    });

    test('guest with stored preference filters out disallowed values', () {
      final result = DemographicResolution.resolve(
        isGuest: true,
        stored: [
          MangaDemographic.shounen,
          MangaDemographic.seinen,
          MangaDemographic.josei,
        ],
      );

      // seinen and josei removed for guest; shounen kept
      expect(result.effectiveFilter, [MangaDemographic.shounen]);
      expect(
        result.allowedOptions,
        [MangaDemographic.kodomo, MangaDemographic.shounen, MangaDemographic.shoujo],
      );
    });

    test('guest with only disallowed stored values falls back to default', () {
      final result = DemographicResolution.resolve(
        isGuest: true,
        stored: [MangaDemographic.seinen, MangaDemographic.josei],
      );

      expect(
        result.effectiveFilter,
        [MangaDemographic.shounen, MangaDemographic.shoujo],
      );
    });

    test('authenticated user with no stored preference gets default', () {
      final result = DemographicResolution.resolve(isGuest: false);

      expect(
        result.effectiveFilter,
        [MangaDemographic.shounen, MangaDemographic.shoujo],
      );
      expect(result.allowedOptions, MangaDemographic.values);
    });

    test('authenticated user keeps all stored values', () {
      final result = DemographicResolution.resolve(
        isGuest: false,
        stored: [
          MangaDemographic.kodomo,
          MangaDemographic.seinen,
          MangaDemographic.josei,
          MangaDemographic.unspecified,
        ],
      );

      expect(
        result.effectiveFilter,
        [
          MangaDemographic.kodomo,
          MangaDemographic.seinen,
          MangaDemographic.josei,
          MangaDemographic.unspecified,
        ],
      );
      expect(result.allowedOptions, MangaDemographic.values);
    });

    test('authenticated user with empty stored list gets default', () {
      final result = DemographicResolution.resolve(
        isGuest: false,
        stored: [],
      );

      expect(
        result.effectiveFilter,
        [MangaDemographic.shounen, MangaDemographic.shoujo],
      );
    });

    test('guest allowedOptions never includes seinen/josei/unspecified', () {
      final result = DemographicResolution.resolve(isGuest: true);

      expect(result.allowedOptions, isNot(contains(MangaDemographic.seinen)));
      expect(result.allowedOptions, isNot(contains(MangaDemographic.josei)));
      expect(
        result.allowedOptions,
        isNot(contains(MangaDemographic.unspecified)),
      );
    });
  });
}
