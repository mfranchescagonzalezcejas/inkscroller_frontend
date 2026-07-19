import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/widgets/inkscroller_shimmer.dart';
import 'package:inkscroller_flutter/features/home/presentation/widgets/home_shimmer.dart';

void main() {
  group('HomeShimmer', () {
    testWidgets('full-page variant renders skeleton sections', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HomeShimmer())),
      );

      expect(find.byType(HomeShimmer), findsOneWidget);
      expect(find.byType(InkScrollerShimmer), findsWidgets);
    });

    testWidgets('carousel variant renders inline placeholder', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HomeShimmer.carousel())),
      );

      expect(find.byType(HomeShimmer), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(HomeShimmer),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
    });
  });
}
