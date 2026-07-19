import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inkscroller_flutter/core/router/app_routes.dart';
import 'package:inkscroller_flutter/features/home/presentation/widgets/demographic_manga_row.dart';
import 'package:inkscroller_flutter/features/home/presentation/widgets/home_shimmer.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga.dart';
import 'package:inkscroller_flutter/l10n/app_localizations.dart';

void main() {
  final mangaA = Manga(
    id: 'manga-a',
    title: 'Manga A',
    coverUrl: 'https://example.com/a.jpg',
  );
  final mangaB = Manga(
    id: 'manga-b',
    title: 'Manga B',
    coverUrl: 'https://example.com/b.jpg',
  );

  Widget buildTestWidget({
    required List<Manga> mangas,
    required String title,
    bool isLoading = false,
  }) {
    return MaterialApp.router(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => DemographicMangaRow(
              mangas: mangas,
              title: title,
              isLoading: isLoading,
            ),
          ),
          GoRoute(
            path: AppRoutes.mangaDetailPattern,
            builder: (_, __) => const Scaffold(
              key: ValueKey('mangaDetailPage'),
              body: Text('DETAIL'),
            ),
          ),
        ],
      ),
    );
  }

  group('DemographicMangaRow', () {
    testWidgets('renders shimmer while loading', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(mangas: [], title: 'Popular', isLoading: true),
      );

      expect(find.byType(HomeShimmer), findsOneWidget);
      expect(find.text('Popular'), findsOneWidget);
    });

    testWidgets('renders empty SizedBox when mangas is empty', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(mangas: [], title: 'Shounen', isLoading: false),
      );

      expect(find.byType(DemographicMangaRow), findsOneWidget);
      expect(find.text('Shounen'), findsNothing);
    });

    testWidgets('renders title and manga tiles when data present', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          mangas: [mangaA, mangaB],
          title: 'Trending',
          isLoading: false,
        ),
      );

      expect(find.text('Trending'), findsOneWidget);
      expect(find.text('Manga A'), findsOneWidget);
      expect(find.text('Manga B'), findsOneWidget);
    });

    testWidgets('tapping a tile navigates to manga detail', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          mangas: [mangaA],
          title: 'Popular',
          isLoading: false,
        ),
      );

      await tester.tap(find.text('Manga A'));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
