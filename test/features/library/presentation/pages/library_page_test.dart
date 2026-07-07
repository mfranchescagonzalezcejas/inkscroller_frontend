import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/l10n/app_localizations.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/core/network/connectivity_status_provider.dart';
import 'package:inkscroller_flutter/features/auth/domain/entities/app_user.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/get_auth_state.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_in.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_out.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_up.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_notifier.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga_reading_progress.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/user_library_entry.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/user_library_status.dart';
import 'package:inkscroller_flutter/features/library/domain/repositories/reading_progress_repository.dart';
import 'package:inkscroller_flutter/features/library/domain/repositories/user_library_repository.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/get_manga_list.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/search_manga.dart';
import 'package:inkscroller_flutter/features/library/presentation/pages/library_page.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/library/library_provider.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/library/library_notifier.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/reading_progress_provider.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/user_library_provider.dart';
import 'package:inkscroller_flutter/flavors/flavor_config.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetMangaList extends Mock implements GetMangaList {}

class _MockSearchManga extends Mock implements SearchManga {}

class _MockSignIn extends Mock implements SignIn {}

class _MockSignUp extends Mock implements SignUp {}

class _MockSignOut extends Mock implements SignOut {}

class _MockGetAuthState extends Mock implements GetAuthState {}

class _MockReadingProgressRepository extends Mock
    implements ReadingProgressRepository {}

class _MockUserLibraryRepository extends Mock
    implements UserLibraryRepository {}

ReadingProgressNotifier _makeStubReadingProgressNotifier() {
  final repository = _MockReadingProgressRepository();
  when(
    () => repository.getAll(),
  ).thenAnswer((_) async => const <String, MangaReadingProgress>{});
  when(() => repository.save(any())).thenAnswer((_) async {});
  return ReadingProgressNotifier(repository);
}

AuthNotifier _makeStubAuthNotifier() {
  final getAuthState = _MockGetAuthState();
  when(() => getAuthState()).thenAnswer((_) => const Stream<AppUser?>.empty());
  return AuthNotifier(
    signIn: _MockSignIn(),
    signUp: _MockSignUp(),
    signOut: _MockSignOut(),
    getAuthState: getAuthState,
  );
}

UserLibraryNotifier _makeStubUserLibraryNotifier([
  Map<String, UserLibraryEntry> initial = const <String, UserLibraryEntry>{},
]) {
  final repository = _MockUserLibraryRepository();
  when(
    () => repository.getAll(userId: any(named: 'userId')),
  ).thenAnswer((_) async => initial);
  when(() => repository.hydrate(any())).thenAnswer((_) async => initial);
  when(
    () => repository.save(any(), userId: any(named: 'userId')),
  ).thenAnswer((_) async {});
  when(
    () => repository.remove(any(), userId: any(named: 'userId')),
  ).thenAnswer((_) async {});
  return UserLibraryNotifier(repository);
}

void main() {
  FlavorConfig(
    flavor: Flavor.dev,
    apiBaseUrl: 'http://localhost:8000',
    name: 'InkScroller Test',
  );

  setUpAll(() {
    registerFallbackValue(const MangaReadingProgress(mangaId: 'fallback'));
    registerFallbackValue(
      UserLibraryEntry(
        manga: Manga(id: 'fallback', title: 'fallback'),
        isInLibrary: true,
        status: UserLibraryStatus.reading,
        updatedAt: DateTime(2026),
      ),
    );
  });

  late GetMangaList getMangaList;
  late SearchManga searchManga;

  Future<void> pumpLibraryPage(
    WidgetTester tester, {
    required GetMangaList getMangaList,
    required SearchManga searchManga,
    bool isOnline = true,
    Map<String, UserLibraryEntry> libraryEntries =
        const <String, UserLibraryEntry>{},
  }) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          connectivityStatusProvider.overrideWith(
            (ref) => Stream<bool>.value(isOnline),
          ),
          authProvider.overrideWith((_) => _makeStubAuthNotifier()),
          libraryProvider.overrideWith(
            (ref) => LibraryNotifier(getMangaList, searchManga),
          ),
          readingProgressProvider.overrideWith(
            (ref) => _makeStubReadingProgressNotifier(),
          ),
          userLibraryProvider.overrideWith(
            (ref) => _makeStubUserLibraryNotifier(libraryEntries),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LibraryPage(),
        ),
      ),
    );
  }

  setUp(() {
    getMangaList = _MockGetMangaList();
    searchManga = _MockSearchManga();
  });

  testWidgets('shows empty local library state while initial load is pending', (
    tester,
  ) async {
    final completer = Completer<Either<Failure, List<Manga>>>();

    when(
      () => getMangaList(limit: 20, offset: 0),
    ).thenAnswer((_) => completer.future);
    when(
      () => searchManga(any()),
    ).thenAnswer((_) async => const Right<Failure, List<Manga>>(<Manga>[]));

    await pumpLibraryPage(
      tester,
      getMangaList: getMangaList,
      searchManga: searchManga,
    );

    expect(find.byType(LibraryPage), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(
      find.text(
        'Tu biblioteca está vacía. Añadí mangas desde Inicio o el detalle.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows empty catalogue message when no mangas are returned', (
    tester,
  ) async {
    when(
      () => getMangaList(limit: 20, offset: 0),
    ).thenAnswer((_) async => const Right<Failure, List<Manga>>(<Manga>[]));
    when(
      () => searchManga(any()),
    ).thenAnswer((_) async => const Right<Failure, List<Manga>>(<Manga>[]));

    await pumpLibraryPage(
      tester,
      getMangaList: getMangaList,
      searchManga: searchManga,
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Tu biblioteca está vacía. Añadí mangas desde Inicio o el detalle.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders manga tiles when mangas are loaded', (tester) async {
    final manga1 = Manga(id: '1', title: 'Berserk');
    final manga2 = Manga(id: '2', title: 'Monster');
    when(() => getMangaList(limit: 20, offset: 0)).thenAnswer(
      (_) async => Right<Failure, List<Manga>>(<Manga>[manga1, manga2]),
    );
    when(
      () => searchManga(any()),
    ).thenAnswer((_) async => const Right<Failure, List<Manga>>(<Manga>[]));

    await pumpLibraryPage(
      tester,
      getMangaList: getMangaList,
      searchManga: searchManga,
      libraryEntries: <String, UserLibraryEntry>{
        '1': UserLibraryEntry(
          manga: manga1,
          isInLibrary: true,
          status: UserLibraryStatus.reading,
          updatedAt: DateTime(2026),
        ),
        '2': UserLibraryEntry(
          manga: manga2,
          isInLibrary: true,
          status: UserLibraryStatus.completed,
          updatedAt: DateTime(2026),
        ),
      },
    );
    await tester.pumpAndSettle();

    expect(find.text('Berserk'), findsOneWidget);
    expect(find.text('Monster'), findsOneWidget);
  });

  testWidgets(
    'shows search empty state when debounced search returns no results',
    (tester) async {
      final manga = Manga(id: '1', title: 'Initial');
      when(
        () => getMangaList(limit: 20, offset: 0),
      ).thenAnswer((_) async => Right<Failure, List<Manga>>(<Manga>[manga]));
      when(
        () => searchManga('pluto'),
      ).thenAnswer((_) async => const Right<Failure, List<Manga>>(<Manga>[]));

      await pumpLibraryPage(
        tester,
        getMangaList: getMangaList,
        searchManga: searchManga,
        libraryEntries: <String, UserLibraryEntry>{
          '1': UserLibraryEntry(
            manga: manga,
            isInLibrary: true,
            status: UserLibraryStatus.reading,
            updatedAt: DateTime(2026),
          ),
        },
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'pluto');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Sin resultados para "pluto"'), findsOneWidget);
    },
  );

  testWidgets(
    'shows offline banner when connectivity provider reports offline',
    (tester) async {
      when(
        () => getMangaList(limit: 20, offset: 0),
      ).thenAnswer((_) async => const Right<Failure, List<Manga>>(<Manga>[]));
      when(
        () => searchManga(any()),
      ).thenAnswer((_) async => const Right<Failure, List<Manga>>(<Manga>[]));

      await pumpLibraryPage(
        tester,
        getMangaList: getMangaList,
        searchManga: searchManga,
        isOnline: false,
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Sin conexión. Mostrando datos guardados si están disponibles.',
        ),
        findsOneWidget,
      );
    },
  );
}
