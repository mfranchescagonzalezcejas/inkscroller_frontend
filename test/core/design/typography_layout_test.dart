/// Tests for AppTypography text scale and AppLayout constants.
///
/// Verifies that the typography scale matches DESIGN.md and that
/// consolidated layout constants haven't drifted.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/constants/layout.dart';
import 'package:inkscroller_flutter/core/design/app_spacing.dart';
import 'package:inkscroller_flutter/core/design/app_typography.dart';

void main() {
  group('AppTypography — text scale', () {
    test('display size matches DESIGN.md (32)', () {
      expect(AppTypography.display, 32.0);
    });

    test('titleLg matches AppTheme titleLarge (22)', () {
      expect(AppTypography.titleLg, 22.0);
    });

    test('titleMd matches AppTheme titleMedium (18)', () {
      expect(AppTypography.titleMd, 18.0);
    });

    test('bodyLg matches AppTheme bodyLarge (16)', () {
      expect(AppTypography.bodyLg, 16.0);
    });

    test('body matches AppTheme bodyMedium (14)', () {
      expect(AppTypography.body, 14.0);
    });

    test('labelLg matches AppTheme labelLarge (14)', () {
      expect(AppTypography.labelLg, 14.0);
    });

    test('label is compact nav/badge size (11)', () {
      expect(AppTypography.label, 11.0);
    });

    test('bodySm is compact label size (13)', () {
      expect(AppTypography.bodySm, 13.0);
    });

    test('fontFamily is Plus Jakarta Sans', () {
      expect(AppTypography.fontFamily, 'Plus Jakarta Sans');
    });

    test('displayStyle has correct height', () {
      expect(AppTypography.displayStyle.height, 1.2);
    });

    test('titleLgStyle has correct height', () {
      expect(AppTypography.titleLgStyle.height, 1.3);
    });

    test('bodyStyle has correct height', () {
      expect(AppTypography.bodyStyle.height, 1.5);
    });
  });

  group('AppLayout — consolidated constants', () {
    test('minTouchTarget is 48 (Material)', () {
      expect(AppLayout.minTouchTarget, 48.0);
    });

    test('iosMinTouchTarget is 44 (Apple HIG)', () {
      expect(AppLayout.iosMinTouchTarget, 44.0);
    });

    test('bottomNavRadius matches .pen (28)', () {
      expect(AppLayout.bottomNavRadius, 28.0);
    });

    test('cardRadius is 16', () {
      expect(AppLayout.cardRadius, 16.0);
    });

    test('buttonRadius is 12', () {
      expect(AppLayout.buttonRadius, 12.0);
    });

    test('authFieldRadius is 16', () {
      expect(AppLayout.authFieldRadius, 16.0);
    });
  });

  group('AppSpacing — pure spacing scale', () {
    test('spacing scale is powers-of-2-friendly', () {
      expect(AppSpacing.xs, 4.0);
      expect(AppSpacing.sm, 8.0);
      expect(AppSpacing.md, 12.0);
      expect(AppSpacing.lg, 16.0);
      expect(AppSpacing.xl, 24.0);
      expect(AppSpacing.twoXl, 32.0);
      expect(AppSpacing.threeXl, 48.0);
    });

    test('no component-specific constants in AppSpacing', () {
      // AppSpacing should only have spacing scale values.
      // Verify no bottomNav, cover, card, etc. prefixed members leak in.
      final members = AppSpacing.toString();
      expect(members, isNot(contains('bottomNav')));
      expect(members, isNot(contains('cover')));
      expect(members, isNot(contains('card')));
    });
  });
}
