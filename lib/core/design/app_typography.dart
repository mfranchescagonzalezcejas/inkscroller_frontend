/// Design tokens for InkScroller — Typography scale.
///
/// Uses Plus Jakarta Sans to balance modern tech with editorial elegance.
/// Based on DESIGN.md typography specs.
library;
import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  // ═══════════════════════════════════════════════════════════════════════
  // FONT FAMILY
  // ═══════════════════════════════════════════════════════════════════════

  static const String fontFamily = 'Plus Jakarta Sans';

  // ═══════════════════════════════════════════════════════════════════════
  // DISPLAY SCALE — For title screens, hero text
  // ═══════════════════════════════════════════════════════════════════════

  /// Display large — Magazine cover feel
  static const double display = 32;
  static const FontWeight displayWeight = FontWeight.w700;

  // ═══════════════════════════════════════════════════════════════════════
  // TITLE SCALE — For headers and section titles
  // ═══════════════════════════════════════════════════════════════════════

  /// Title large — Screen titles, major headers
  static const double titleLg = 20;
  static const FontWeight titleLgWeight = FontWeight.w700;

  /// Title medium — Card titles, subheaders
  static const double titleMd = 16;
  static const FontWeight titleMdWeight = FontWeight.w600;

  // ═══════════════════════════════════════════════════════════════════════
  // BODY SCALE — For content text
  // ═══════════════════════════════════════════════════════════════════════

  /// Body — Default body text
  static const double body = 14;
  static const FontWeight bodyWeight = FontWeight.w400;

  /// Body large — Extended body text
  static const double bodyLg = 16;
  static const FontWeight bodyLgWeight = FontWeight.w400;

  // ═══════════════════════════════════════════════════════════════════════
  // LABEL SCALE — For captions, badges, navigation
  // ═══════════════════════════════════════════════════════════════════════

  /// Label — Navigation labels, badges, timestamps
  static const double label = 11;
  static const FontWeight labelWeight = FontWeight.w500;

  /// Label large — Button text
  static const double labelLg = 14;
  static const FontWeight labelLgWeight = FontWeight.w600;

  // ═══════════════════════════════════════════════════════════════════════
  // TEXT STYLES — Pre-configured TextStyles for common use cases
  // ═══════════════════════════════════════════════════════════════════════

  static TextStyle get displayStyle => const TextStyle(
        fontFamily: fontFamily,
        fontSize: display,
        fontWeight: displayWeight,
        height: 1.2,
      );

  static TextStyle get titleLgStyle => const TextStyle(
        fontFamily: fontFamily,
        fontSize: titleLg,
        fontWeight: titleLgWeight,
        height: 1.3,
      );

  static TextStyle get titleMdStyle => const TextStyle(
        fontFamily: fontFamily,
        fontSize: titleMd,
        fontWeight: titleMdWeight,
        height: 1.4,
      );

  static TextStyle get bodyStyle => const TextStyle(
        fontFamily: fontFamily,
        fontSize: body,
        fontWeight: bodyWeight,
        height: 1.5,
      );

  static TextStyle get bodyLgStyle => const TextStyle(
        fontFamily: fontFamily,
        fontSize: bodyLg,
        fontWeight: bodyLgWeight,
        height: 1.5,
      );

  static TextStyle get labelStyle => const TextStyle(
        fontFamily: fontFamily,
        fontSize: label,
        fontWeight: labelWeight,
        height: 1.4,
      );

  static TextStyle get labelLgStyle => const TextStyle(
        fontFamily: fontFamily,
        fontSize: labelLg,
        fontWeight: labelLgWeight,
        height: 1.4,
      );
}
