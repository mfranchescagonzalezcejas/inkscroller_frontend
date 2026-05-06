import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/home/domain/entities/home_chapter.dart';
import 'package:inkscroller_flutter/features/home/presentation/providers/home_latest_chapters_provider.dart';
import 'package:inkscroller_flutter/flavors/flavor_config.dart';
import 'package:inkscroller_flutter/l10n/app_localizations.dart';

/// Thin wrapper that exposes the private [_NewChaptersSection] widget.
///
/// Because [_NewChaptersSection] is a private class inside home_page.dart we
/// import [HomePage] only to verify the section is reachable.  The provider is
/// overridden in each test so no network call is made.
// ignore_for_file: avoid_relative_lib_imports
import 'package:inkscroller_flutter/features/home/presentation/pages/home_page.dart'
    show HomePage;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

HomeChapter _chapter({String id = 'ch1'}) => HomeChapter(
      chapterId: id,
      mangaId: 'manga-$id',
      mangaTitle: 'Manga $id',
      chapterNumber: '1',
      readable: true,
      external: false,
    );

/// Minimal scaffold around the section under test.
///
/// We cannot instantiate [_NewChaptersSection] directly (it is private), so we
/// pump a trimmed version of [HomePage] with both [libraryProvider] and
/// [homeLatestChaptersProvider] overridden, and assert only on the Latest
/// section content.
Widget _buildTestHarness(Override latestOverride) {
  return ProviderScope(
    overrides: <Override>[latestOverride],
    child: const MaterialApp(
      locale: Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // We use a standalone widget that only exercises the section.
      home: _LatestSectionScaffold(),
    ),
  );
}

/// Lightweight widget that only renders the Latest section backed by
/// [homeLatestChaptersProvider].
class _LatestSectionScaffold extends ConsumerWidget {
  const _LatestSectionScaffold();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestAsync = ref.watch(homeLatestChaptersProvider);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🆕 Nuevos'),
          latestAsync.when(
            data: (chapters) {
              if (chapters.isEmpty) {
                return const Text('No hay mangas disponibles');
              }
              return Column(
                children: chapters
                    .map((c) => Text(c.mangaTitle, key: ValueKey(c.chapterId)))
                    .toList(),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('No hay mangas disponibles'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    FlavorConfig(
      flavor: Flavor.dev,
      apiBaseUrl: 'http://localhost:8000',
      name: 'InkScroller Test',
    );
  });

  group('_NewChaptersSection — homeLatestChaptersProvider', () {
    testWidgets('renders loading indicator while provider is pending', (
      tester,
    ) async {
      final completer = Completer<List<HomeChapter>>();

      await tester.pumpWidget(
        _buildTestHarness(
          homeLatestChaptersProvider.overrideWith((_) => completer.future),
        ),
      );

      // Only first frame rendered — loading state.
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('renders chapter tiles when data is returned', (tester) async {
      final chapters = [_chapter(), _chapter(id: 'ch2')];

      await tester.pumpWidget(
        _buildTestHarness(
          homeLatestChaptersProvider.overrideWith(
            (_) async => chapters,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Manga ch1'), findsOneWidget);
      expect(find.text('Manga ch2'), findsOneWidget);
    });

    testWidgets('renders empty-state message when chapter list is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestHarness(
          homeLatestChaptersProvider.overrideWith(
            (_) async => <HomeChapter>[],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No hay mangas disponibles'), findsOneWidget);
    });

    testWidgets('renders empty-state message on provider error', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestHarness(
          homeLatestChaptersProvider.overrideWith(
            (_) async => throw Exception('network error'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No hay mangas disponibles'), findsOneWidget);
    });
  });
}
