import 'package:flutter/material.dart';

/// UI constants for Library screen parity with Pencil design.
class LibraryUiConstants {
  LibraryUiConstants._();

  // Layout
  static const double topBarHeight = 56;
  static const double avatarSize = 32;
  static const double horizontalPadding = 20;
  static const double cardOverlayHeight = 90;
  static const double cardOverlayHorizontalPadding = 10;
  static const double cardOverlayBottomPadding = 12;
  static const double cardBadgeRadius = 20;
  static const double cardGridBottomPadding = 140;
  static const double tabMinLabelHeight = 24;
  static const double tabFontSize = 13;
  static const FontWeight tabActiveWeight = FontWeight.w600;
  static const FontWeight tabInactiveWeight = FontWeight.w400;

  // Shared bottom navigation safe spacing for scrollable content
  static const double contentBottomSafePadding = 140;

  // Grid
  static const double gridMainSpacing = 20;
  static const double gridCrossSpacing = 12;
  static const int largeGridBreakpoint = 900;
  static const int mediumGridBreakpoint = 600;
  static const int largeGridColumns = 4;
  static const int mediumGridColumns = 3;
  static const int smallGridColumns = 2;

  // Status mapping (temporary until user library status exists server-side)
  static const String ongoingStatus = 'ongoing';
  static const String completedStatus = 'completed';
  static const String hiatusStatus = 'hiatus';
}
