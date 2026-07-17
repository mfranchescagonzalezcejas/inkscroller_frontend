import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/core/network/connectivity_status_provider.dart';
import 'package:inkscroller_flutter/features/auth/domain/entities/app_user.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/get_auth_state.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/reload_user.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/send_email_verification.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_in.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_out.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_up.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_notifier.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/chapter.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/chapters_with_languages.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga_reading_progress.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/search_result.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/reader_mode.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/reading_preferences.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/user_library_entry.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/user_library_status.dart';
import 'package:inkscroller_flutter/features/library/domain/repositories/per_title_override_repository.dart';
import 'package:inkscroller_flutter/features/library/domain/repositories/reading_progress_repository.dart';
import 'package:inkscroller_flutter/features/library/domain/repositories/user_library_repository.dart';
import 'package:inkscroller_flutter/features/preferences/domain/repositories/preferences_repository.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/get_manga_chapters.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/get_manga_chapters_with_languages.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/get_manga_languages.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/get_manga_list.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/get_per_title_override.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/remove_per_title_override.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/save_per_title_override.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/search_manga.dart';
import 'package:inkscroller_flutter/features/library/presentation/pages/library_page.dart';
import 'package:inkscroller_flutter/features/library/presentation/pages/manga_detail_page.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/chapters/manga_chapter_provider.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/chapters/manga_chapters_notifier.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/library/library_notifier.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/library/library_provider.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/reading_progress_provider.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/user_library_provider.dart';
import 'package:inkscroller_flutter/features/preferences/domain/entities/user_reading_preferences.dart';
import 'package:inkscroller_flutter/features/preferences/domain/usecases/get_preferences.dart';
import 'package:inkscroller_flutter/features/preferences/domain/usecases/update_preferences.dart';
import 'package:inkscroller_flutter/features/profile/domain/usecases/get_user_profile.dart';
import 'package:inkscroller_flutter/features/profile/domain/usecases/update_user_profile.dart';
import 'package:inkscroller_flutter/flavors/flavor_config.dart';
import 'package:inkscroller_flutter/l10n/app_localizations.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetMangaList extends Mock implements GetMangaList {}

class _MockSearchManga extends Mock implements SearchManga {}

class _MockGetMangaChapters extends Mock implements GetMangaChapters {}

class _MockGetMangaChaptersWithLanguages extends Mock
    implements GetMangaChaptersWithLanguages {}

class _MockGetMangaLanguages extends Mock implements GetMangaLanguages {}

class _MockSignIn extends Mock implements SignIn {}

class _MockSignUp extends Mock implements SignUp {}

class _MockSignOut extends Mock implements SignOut {}

class _MockGetAuthState extends Mock implements GetAuthState {}

class _MockGetUserProfile extends Mock implements GetUserProfile {}

class _MockUpdateUserProfile extends Mock implements UpdateUserProfile {}

class _MockSendEmailVerification extends Mock implements SendEmailVerification {}

class _MockReloadUser extends Mock implements ReloadUser {}

class _MockReadingProgressRepository extends Mock
    implements ReadingProgressRepository {}

class _MockUserLibraryRepository extends Mock
    implements UserLibraryRepository {}

class _MockPerTitleOverrideRepository extends Mock
    implements PerTitleOverrideRepository {}

class _MockPreferencesRepository extends Mock
    implements PreferencesRepository {}

AuthNotifier _makeStubAuthNotifier() {
  final getAuthState = _MockGetAuthState();
  when(() => getAuthState()).thenAnswer((_) => const Stream<AppUser?>.empty());
  return AuthNotifier(
    signIn: _MockSignIn(),
    signUp: _MockSignUp(),
    signOut: _MockSignOut(),
    getAuthState: getAuthState,
    sendEmailVerification: _MockSendEmailVerification(),
    reloadUser: _MockReloadUser(),
    getUserProfile: _MockGetUserProfile(),
    updateUserProfile: _MockUpdateUserProfile(),
  );
}

ReadingProgressNotifier _makeStubReadingProgressNotifier() {
  final repository = _MockReadingProgressRepository();
  when(
    () => repository.getAll(),
  ).thenAnswer((_) async => const <String, MangaReadingProgress>{});
  when(() => repository.save(any())).thenAnswer((_) async {});
  return ReadingProgressNotifier(repository);
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

void _registerGetItMocks() {
  final git = GetIt.instance;

  if (!git.isRegistered<GetPerTitleOverride>()) {
    final repo = _MockPerTitleOverrideRepository();
    when(() => repo.getOverride(any())).thenAnswer((_) async => null);
    when(() => repo.saveOverride(any())).thenAnswer((_) async {});
    when(() => repo.removeOverride(any())).thenAnswer((_) async {});

    git.registerLazySingleton<GetPerTitleOverride>(
      () => GetPerTitleOverride(repo),
    );
    git.registerLazySingleton<SavePerTitleOverride>(
      () => SavePerTitleOverride(repo),
    );
    git.registerLazySingleton<RemovePerTitleOverride>(
      () => RemovePerTitleOverride(repo),
    );
  }

  if (!git.isRegistered<GetPreferences>()) {
    final prefsRepo = _MockPreferencesRepository();
    when(() => prefsRepo.getPreferences()).thenAnswer(
      (_) async => Right<Failure, UserReadingPreferences>(
        UserReadingPreferences(
          defaultReaderMode: ReaderMode.paged,
          defaultLanguage: 'es',
          updatedAt: _fixtureDate,
        ),
      ),
    );
    when(() => prefsRepo.updatePreferences(
      defaultReaderMode: any(named: 'defaultReaderMode'),
      defaultLanguage: any(named: 'defaultLanguage'),
      contentRatingFilter: any(named: 'contentRatingFilter'),
    )).thenAnswer(
      (_) async => Right<Failure, UserReadingPreferences>(
        UserReadingPreferences(
          defaultReaderMode: ReaderMode.paged,
          defaultLanguage: 'es',
          updatedAt: _fixtureDate,
        ),
      ),
    );

    git.registerLazySingleton<GetPreferences>(
      () => GetPreferences(prefsRepo),
    );
    git.registerLazySingleton<UpdatePreferences>(
      () => UpdatePreferences(prefsRepo),
    );
  }
}

/// Shared fixture year for test data factories.
const _fixtureYear = 2026;

/// Shared fixture date used across test data factories.
final _fixtureDate = DateTime(_fixtureYear);

/// How long to wait for the UI to settle after a navigation event.
const _settleDuration = Duration(seconds: 1);

/// Repeatedly pumps [tester] until [finder] matches at least one widget,
/// timing out after [timeout] if the condition is never met.
Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  const pumpInterval = Duration(milliseconds: 50);
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    // Let real-time async operations (mock futures) resolve.
    await tester.runAsync(() => Future<void>.delayed(pumpInterval));
    await tester.pump();
    if (finder.evaluate().isNotEmpty) return;
  }
  await tester.pump();
}

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
  late GetMangaChaptersWithLanguages getMangaChaptersWithLanguages;
  late GetMangaLanguages getMangaLanguages;

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
          connectivityStatusProvider.overrideWith(
            (ref) => Stream<bool>.value(true),
          ),
          authProvider.overrideWith((_) => _makeStubAuthNotifier()),
          libraryProvider.overrideWith(
            (ref) => LibraryNotifier(getMangaList, searchManga),
          ),
          mangaChaptersProvider.overrideWith(
            (ref) => MangaChaptersNotifier(
              getMangaChapters: getMangaChapters,
              getMangaLanguages: getMangaLanguages,
              getMangaChaptersWithLanguages: getMangaChaptersWithLanguages,
            ),
          ),
          readingProgressProvider.overrideWith(
            (ref) => _makeStubReadingProgressNotifier(),
          ),
          userLibraryProvider.overrideWith(
            (ref) => _makeStubUserLibraryNotifier(<String, UserLibraryEntry>{
              'berserk': UserLibraryEntry(
                manga: berserk,
                isInLibrary: true,
                status: UserLibraryStatus.reading,
                updatedAt: _fixtureDate,
              ),
              'monster': UserLibraryEntry(
                manga: monster,
                isInLibrary: true,
                status: UserLibraryStatus.reading,
                updatedAt: _fixtureDate,
              ),
            }),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
  }

  setUp(() {
    registerFallbackValue(const MangaReadingProgress(mangaId: 'fallback'));
    registerFallbackValue(
      UserLibraryEntry(
        manga: Manga(id: 'fallback', title: 'fallback'),
        isInLibrary: true,
        status: UserLibraryStatus.reading,
        updatedAt: _fixtureDate,
      ),
    );
    registerFallbackValue(const PerTitleOverride(
      mangaId: 'fallback',
      preferredReaderMode: ReaderMode.paged,
    ));

    _registerGetItMocks();

    getMangaList = _MockGetMangaList();
    searchManga = _MockSearchManga();
    getMangaChapters = _MockGetMangaChapters();
    getMangaChaptersWithLanguages = _MockGetMangaChaptersWithLanguages();
    getMangaLanguages = _MockGetMangaLanguages();

    when(() => getMangaChaptersWithLanguages('monster')).thenAnswer(
      (_) async => Right<Failure, ChaptersWithLanguages>(
        ChaptersWithLanguages(
          availableLanguages: ['en'],
          matchedLanguage: 'en',
          chapters: [
            Chapter(
              id: 'chapter-1',
              number: 1,
              title: 'Capítulo 1',
              readable: true,
              external: false,
            ),
          ],
        ),
      ),
    );
    when(() => getMangaLanguages('monster')).thenAnswer(
      (_) async => const Right<Failure, List<String>>(['en']),
    );

    when(() => getMangaList(limit: 20, offset: 0)).thenAnswer(
      (_) async => Right<Failure, List<Manga>>(<Manga>[berserk, monster]),
    );
    when(() => searchManga(
      'monster',
      limit: any(named: 'limit'),
      offset: any(named: 'offset'),
      contentRating: any(named: 'contentRating'),
    )).thenAnswer(
      (_) async => Right<Failure, SearchResult>(
        SearchResult(mangas: [monster], limit: 20, offset: 0, total: 1),
      ),
    );
    when(() => getMangaChapters('monster', language: 'en')).thenAnswer(
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

  tearDown(() {
    final git = GetIt.instance;
    if (git.isRegistered<GetPerTitleOverride>()) {
      git.unregister<GetPerTitleOverride>();
    }
    if (git.isRegistered<SavePerTitleOverride>()) {
      git.unregister<SavePerTitleOverride>();
    }
    if (git.isRegistered<RemovePerTitleOverride>()) {
      git.unregister<RemovePerTitleOverride>();
    }
    if (git.isRegistered<GetPreferences>()) {
      git.unregister<GetPreferences>();
    }
    if (git.isRegistered<UpdatePreferences>()) {
      git.unregister<UpdatePreferences>();
    }
  });

  testWidgets('user can search a manga and open its detail page', (
    tester,
  ) async {
    await pumpApp(tester);

    // Let the UI render and settle.
    await tester.pump();
    await tester.pump(_settleDuration);
    await tester.pump();

    expect(find.text('Berserk'), findsOneWidget);
    expect(find.text('Monster'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'monster');
    await tester.pump();
    await tester.pump();

    expect(find.text('Monster'), findsOneWidget);
    expect(find.text('Berserk'), findsNothing);

    await tester.tap(find.text('Monster'));
    await _pumpUntilFound(tester, find.text('Capítulos'));

    expect(find.text('Monster'), findsWidgets);
    expect(find.text('Capítulos'), findsOneWidget);

    await _pumpUntilFound(tester, find.text('Capítulo 1'));

    expect(find.text('Capítulo 1'), findsOneWidget);
    expect(find.text('Chapter One'), findsOneWidget);
  });
}
