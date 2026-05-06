import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inkscroller_flutter/core/router/app_routes.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/chapter.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga.dart';
import 'package:inkscroller_flutter/features/library/presentation/widgets/chapter_tile.dart';
import 'package:inkscroller_flutter/features/library/presentation/widgets/cover_image.dart';
import 'package:inkscroller_flutter/features/library/presentation/widgets/manga_tile.dart';
import 'package:inkscroller_flutter/l10n/app_localizations.dart';

void main() {
  testWidgets('MangaTile renders title and navigates on tap', (tester) async {
    final router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (_, __) => Scaffold(
            body: MangaTile(
              manga: Manga(id: 'manga-1', title: 'Berserk'),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.mangaDetailPattern,
          builder: (_, state) =>
              Scaffold(body: Text(state.pathParameters['mangaId']!)),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );

    expect(find.text('Berserk'), findsOneWidget);

    await tester.tap(find.byType(MangaTile));
    await tester.pumpAndSettle();

    expect(find.text('manga-1'), findsOneWidget);
  });

  testWidgets('MangaTile does not crash when score is null', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MangaTile(
            manga: Manga(id: 'manga-null-score', title: 'Null Score Manga'),
          ),
        ),
      ),
    );

    expect(find.text('Null Score Manga'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.text('--'), findsOneWidget);
  });

  testWidgets('ChapterTile shows chapter number and readable icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ChapterTile(
            chapter: Chapter(
              id: 'chapter-1',
              number: 3,
              title: 'Awakening',
              readable: true,
              external: false,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Capítulo 3'), findsOneWidget);
    expect(find.text('Awakening'), findsOneWidget);
    expect(find.byIcon(Icons.menu_book), findsOneWidget);
  });

  testWidgets('MangaTile shows reading progress when available', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MangaTile(
            manga: Manga(id: 'manga-progress', title: 'Progress Manga'),
            readChaptersCount: 4,
            totalChaptersCount: 10,
          ),
        ),
      ),
    );

    expect(find.text('4 / 10 leídos'), findsOneWidget);
  });

  testWidgets('ChapterTile shows extra label and external icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ChapterTile(
            chapter: Chapter(
              id: 'chapter-2',
              readable: false,
              external: true,
              externalUrl: 'https://example.com',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Extra'), findsOneWidget);
    expect(find.byIcon(Icons.open_in_new), findsOneWidget);
  });

  testWidgets('CoverImage shows unsupported icon when url is null', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: CoverImage()),
      ),
    );

    expect(find.byIcon(Icons.image_not_supported), findsOneWidget);
  });
}
