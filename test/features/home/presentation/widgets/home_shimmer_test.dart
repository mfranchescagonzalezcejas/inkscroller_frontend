import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/widgets/inkscroller_shimmer.dart';
import 'package:inkscroller_flutter/features/home/presentation/constants/home_layout.dart';
import 'package:inkscroller_flutter/features/home/presentation/widgets/home_shimmer.dart';

void main() {
  group('HomeShimmer.carousel', () {
    testWidgets('renders a single shimmer at hero carousel height', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HomeShimmer.carousel())),
      );

      final shimmer = tester.widget<InkScrollerShimmer>(
        find.byType(InkScrollerShimmer),
      );
      expect(shimmer.height, HomeLayout.heroCarouselHeight);
    });

    testWidgets('wraps shimmer in ExcludeSemantics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HomeShimmer.carousel())),
      );

      expect(
        find.ancestor(
          of: find.byType(InkScrollerShimmer),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
    });
  });

  group('HomeShimmer.cardRow', () {
    testWidgets('renders a row of small shimmer boxes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HomeShimmer.cardRow())),
      );

      expect(find.byType(Row), findsOneWidget);
      final shimmers = tester.widgetList<InkScrollerShimmer>(
        find.byType(InkScrollerShimmer),
      );
      expect(shimmers, isNotEmpty);
      for (final shimmer in shimmers) {
        expect(shimmer.height, HomeLayout.continueReadingCardHeight);
      }
    });

    testWidgets('wraps row in ExcludeSemantics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HomeShimmer.cardRow())),
      );

      expect(
        find.ancestor(
          of: find.byType(Row),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
    });
  });
}
