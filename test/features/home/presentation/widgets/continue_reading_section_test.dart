import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inkscroller_flutter/core/router/app_routes.dart';
import 'package:inkscroller_flutter/features/home/presentation/providers/continue_reading_provider.dart';
import 'package:inkscroller_flutter/features/home/presentation/widgets/continue_reading_section.dart';
import 'package:inkscroller_flutter/features/home/presentation/widgets/home_shimmer.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga_reading_progress.dart';
import 'package:inkscroller_flutter/l10n/app_localizations.dart';

ContinueReadingItem _item(String id, {int read = 3, int total = 10}) =>
    ContinueReadingItem(
      manga: Manga(id: id, title: 'Manga $id'),
      progress: MangaReadingProgress(
        mangaId: id,
        readChapterIds: List<String>.generate(
          read,
          (index) => 'c-$index',
        ).toSet(),
        manuallyMarkedCount: read,
        totalChaptersCount: total,
      ),
    );

Widget _harness(Override override) {
  final router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (_, __) => ProviderScope(
          overrides: <Override>[override],
          child: const Scaffold(body: ContinueReadingSection()),
        ),
      ),
      GoRoute(
        path: AppRoutes.mangaDetailPattern,
        builder: (_, state) =>
            Scaffold(body: Text(state.pathParameters['mangaId']!)),
      ),
    ],
  );

  return MaterialApp.router(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  );
}

void main() {
  testWidgets('shows the card row shimmer while progress is loading', (
    tester,
  ) async {
    final completer = Completer<List<ContinueReadingItem>>();
    await tester.pumpWidget(
      _harness(continueReadingProvider.overrideWith((_) => completer.future)),
    );

    expect(find.byType(HomeShimmer), findsOneWidget);
  });

  testWidgets('hides the section when progress is empty or fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(continueReadingProvider.overrideWith((_) async => const [])),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ContinueReadingSection), findsOneWidget);
    expect(find.byType(ListView), findsNothing);

    await tester.pumpWidget(
      _harness(
        continueReadingProvider.overrideWith(
          (_) async => throw Exception('failed'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ListView), findsNothing);
  });

  testWidgets('renders cards with progress semantics and navigates on tap', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _harness(
        continueReadingProvider.overrideWith(
          (_) async => <ContinueReadingItem>[_item('first'), _item('second')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Manga first'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('3 / 10 read')), findsNWidgets(2));
    await tester.tap(find.text('Manga first'));
    await tester.pumpAndSettle();
    expect(find.text('first'), findsOneWidget);
    semantics.dispose();
  });
}
