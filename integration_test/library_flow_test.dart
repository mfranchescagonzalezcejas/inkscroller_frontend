import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/chapter.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/get_manga_chapters.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/get_manga_list.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/search_manga.dart';
import 'package:inkscroller_flutter/features/library/presentation/pages/library_page.dart';
import 'package:inkscroller_flutter/features/library/presentation/pages/manga_detail_page.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/library/library_notifier.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/library/library_provider.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/chapters/manga_chapter_provider.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/chapters/manga_chapters_notifier.dart';
import 'package:inkscroller_flutter/flavors/flavor_config.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetMangaList extends Mock implements GetMangaList {}

class _MockSearchManga extends Mock implements SearchManga {}

class _MockGetMangaChapters extends Mock implements GetMangaChapters {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  FlavorConfig(
    flavor: Flavor.dev,
    apiBaseUrl: 'http://localhost:8000',
    name: 'InkScroller Test',
  );

  final berserk = Manga(
    id: 'berserk',
    title: 'Berserk',
    description: 'Dark fantasy',
    demographic: 'seinen',
    genres: const <String>['Action'],
  );
  final monster = Manga(
    id: 'monster',
    title: 'Monster',
    description: 'Thriller',
    demographic: 'seinen',
    genres: const <String>['Mystery'],
  );

  late GetMangaList getMangaList;
  late SearchManga searchManga;
  late GetMangaChapters getMangaChapters;

  Future<void> pumpApp(WidgetTester tester) {
    final router = GoRouter(
      initialLocation: '/library',
      routes: <RouteBase>[
        GoRoute(
          path: '/library',
          builder: (_, __) => const LibraryPage(),
        ),
        GoRoute(
          path: '/manga/:mangaId',
          builder: (_, state) => MangaDetailPage(
            manga: state.extra! as Manga,
          ),
        ),
      ],
    );

    return tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          libraryProvider.overrideWith(
            (ref) => LibraryNotifier(getMangaList, searchManga),
          ),
          mangaChaptersProvider.overrideWith(
            (ref) => MangaChaptersNotifier(getMangaChapters: getMangaChapters),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  setUp(() {
    getMangaList = _MockGetMangaList();
    searchManga = _MockSearchManga();
    getMangaChapters = _MockGetMangaChapters();

    when(() => getMangaList(limit: 20, offset: 0)).thenAnswer(
      (_) async => Right<Failure, List<Manga>>(<Manga>[berserk, monster]),
    );
    when(() => searchManga('monster')).thenAnswer(
      (_) async => Right<Failure, List<Manga>>(<Manga>[monster]),
    );
    when(() => getMangaChapters('monster')).thenAnswer(
      (_) async => Right<Failure, List<Chapter>>(<Chapter>[
        Chapter(
          id: 'chapter-1',
          number: 1,
          title: 'Chapter One',
          readable: true,
          external: false,
        ),
      ]),
    );
  });

  testWidgets('user can search a manga and open its detail page', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.pumpAndSettle();

    expect(find.text('Berserk'), findsOneWidget);
    expect(find.text('Monster'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'monster');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Monster'), findsOneWidget);
    expect(find.text('Berserk'), findsNothing);

    await tester.tap(find.text('Monster'));
    await tester.pumpAndSettle();

    expect(find.text('Monster'), findsWidgets);
    expect(find.text('Capítulos'), findsOneWidget);
    expect(find.text('Capítulo 1.0'), findsOneWidget);
    expect(find.text('Chapter One'), findsOneWidget);
  });
}
