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

      expect(resolution.effectiveFilter, [
        MangaDemographic.shounen,
        MangaDemographic.shoujo,
      ]);
      expect(resolution.allowedOptions, MangaDemographic.values);
    });
  });

  // ── DemographicResolution.resolve (pure function) ──────────────────────

  group('DemographicResolution.resolve', () {
    test('guest with no stored preference gets default [shounen, shoujo]', () {
      final result = DemographicResolution.resolve(isGuest: true);

      expect(result.effectiveFilter, [
        MangaDemographic.shounen,
        MangaDemographic.shoujo,
      ]);
      expect(result.allowedOptions, [
        MangaDemographic.shounen,
        MangaDemographic.shoujo,
      ]);
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
      expect(result.allowedOptions, [
        MangaDemographic.shounen,
        MangaDemographic.shoujo,
      ]);
    });

    test('guest with only disallowed stored values falls back to default', () {
      final result = DemographicResolution.resolve(
        isGuest: true,
        stored: [MangaDemographic.seinen, MangaDemographic.josei],
      );

      expect(result.effectiveFilter, [
        MangaDemographic.shounen,
        MangaDemographic.shoujo,
      ]);
    });

    test('authenticated user with no stored preference gets default', () {
      final result = DemographicResolution.resolve(isGuest: false);

      expect(result.effectiveFilter, [
        MangaDemographic.shounen,
        MangaDemographic.shoujo,
      ]);
      expect(result.allowedOptions, [
        MangaDemographic.shounen,
        MangaDemographic.shoujo,
        MangaDemographic.seinen,
        MangaDemographic.josei,
      ]);
    });

    test('supported user keeps an unspecified mixed selection', () {
      final result = DemographicResolution.resolve(
        isGuest: false,
        supportsUnspecified: true,
        stored: [
          MangaDemographic.seinen,
          MangaDemographic.josei,
          MangaDemographic.unspecified,
        ],
      );

      expect(result.effectiveFilter, [
        MangaDemographic.seinen,
        MangaDemographic.josei,
        MangaDemographic.unspecified,
      ]);
      expect(result.allowedOptions, contains(MangaDemographic.unspecified));
    });

    test('unsupported capability removes unspecified regardless of age', () {
      final result = DemographicResolution.resolve(
        isGuest: false,
        stored: <MangaDemographic>[MangaDemographic.unspecified],
      );

      expect(
        result.allowedOptions,
        isNot(contains(MangaDemographic.unspecified)),
      );
      expect(result.effectiveFilter, <MangaDemographic>[
        MangaDemographic.shounen,
        MangaDemographic.shoujo,
      ]);
    });

    test('unavailable capability with stored unspecified falls back to default', () {
      final result = DemographicResolution.resolve(
        isGuest: false,
        stored: <MangaDemographic>[
          MangaDemographic.unspecified,
          MangaDemographic.shounen,
        ],
      );

      expect(result.effectiveFilter, <MangaDemographic>[
        MangaDemographic.shounen,
        MangaDemographic.shoujo,
      ]);
      expect(
        result.allowedOptions,
        isNot(contains(MangaDemographic.unspecified)),
      );
    });

    test('authenticated user with empty stored list gets default', () {
      final result = DemographicResolution.resolve(isGuest: false, stored: []);

      expect(result.effectiveFilter, [
        MangaDemographic.shounen,
        MangaDemographic.shoujo,
      ]);
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

  group('DemographicResolution.isValidSelection', () {
    test('requires at least one selected demographic', () {
      expect(
        DemographicResolution.isValidSelection(<MangaDemographic>[]),
        isFalse,
      );
      expect(
        DemographicResolution.isValidSelection(<MangaDemographic>[
          MangaDemographic.shounen,
        ]),
        isTrue,
      );
    });
  });

  group('DemographicResolution.selectionForDialog', () {
    test('uses the effective filter when stored values are unavailable', () {
      final resolution = DemographicResolution.resolve(
        isGuest: false,
        stored: <MangaDemographic>[
          MangaDemographic.shounen,
          MangaDemographic.unspecified,
        ],
      );

      expect(
        DemographicResolution.selectionForDialog(
          stored: <MangaDemographic>[
            MangaDemographic.shounen,
            MangaDemographic.unspecified,
          ],
          resolution: resolution,
        ),
        <MangaDemographic>[
          MangaDemographic.shounen,
          MangaDemographic.shoujo,
        ],
      );
    });

    test('keeps a fully allowed stored selection', () {
      const stored = <MangaDemographic>[
        MangaDemographic.shounen,
        MangaDemographic.seinen,
      ];
      final resolution = DemographicResolution.resolve(
        isGuest: false,
        stored: stored,
      );

      expect(
        DemographicResolution.selectionForDialog(
          stored: stored,
          resolution: resolution,
        ),
        stored,
      );
    });
  });
}
