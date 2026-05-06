/// Regression tests for design tokens that match the inkscroller.pen source of truth.
///
/// These tests prevent future drift between AppSpacing/AppColors constants and
/// the values specified in design/pencil/inkscroller.pen.
///
/// References:
/// - TASK-025 / PR #80 — visual regression fix
/// - inkscroller.pen node LHiWR (BottomNav), neoRl (HeroOverlay)
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/design/app_spacing.dart';
import 'package:inkscroller_flutter/core/design/app_colors.dart';

void main() {
  group('AppSpacing — pen regression (TASK-025)', () {
    // .pen node LHiWR: "cornerRadius": 28
    test('bottomNavRadius matches .pen cornerRadius (28)', () {
      expect(AppSpacing.bottomNavRadius, 28.0);
    });

    // .pen node LHiWR: "width": 358
    test('bottomNavWidth matches .pen width (358)', () {
      expect(AppSpacing.bottomNavWidth, 358.0);
    });

    // .pen: x=16 → margin from screen edge
    test('bottomNavMargin matches .pen x offset (16)', () {
      expect(AppSpacing.bottomNavMargin, 16.0);
    });

    // .pen node LHiWR: "height": 72
    test('bottomNavHeight matches .pen height (72)', () {
      expect(AppSpacing.bottomNavHeight, 72.0);
    });
  });

  group('AppColors — pen regression (TASK-025)', () {
    // .pen node LHiWR: "fill": "#111416BF" → #111416 at 75% opacity
    test('glassSurface matches .pen fill base (#111416)', () {
      expect(AppColors.glassSurface, const Color(0xFF111416));
    });

    // BF hex = 191/255 ≈ 0.749... → rounds to 0.75
    test('glassOpacity matches .pen fill alpha (75%)', () {
      expect(AppColors.glassOpacity, closeTo(0.75, 0.01));
    });

    // .pen: inactive nav icons use $color-outline
    test('outline color matches .pen color-outline (#4A4F55)', () {
      expect(AppColors.outline, const Color(0xFF4A4F55));
    });

    // .pen: active/primary color
    test('primary color matches .pen color-primary (#80D5CB)', () {
      expect(AppColors.primary, const Color(0xFF80D5CB));
    });

    // .pen: $color-void (background)
    test('voidLowest matches .pen color-void (#080F10)', () {
      expect(AppColors.voidLowest, const Color(0xFF080F10));
    });
  });
}
