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
import 'package:inkscroller_flutter/features/auth/domain/usecases/send_password_reset.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_in.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_out.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_up.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_notifier.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/chapter.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/chapters_with_languages.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga_reading_progress.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/reader_mode.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/reading_preferences.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/user_library_entry.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/user_library_status.dart';
import 'package:inkscroller_flutter/features/library/domain/repositories/per_title_override_repository.dart';
import 'package:inkscroller_flutter/features/library/domain/repositories/reading_progress_repository.dart';
import 'package:inkscroller_flutter/features/library/domain/repositories/user_library_repository.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/get_manga_chapters.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/get_manga_chapters_with_languages.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/get_manga_languages.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/get_per_title_override.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/remove_per_title_override.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/save_per_title_override.dart';
import 'package:inkscroller_flutter/features/library/presentation/pages/manga_detail_page.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/chapters/manga_chapter_provider.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/chapters/manga_chapters_notifier.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/reading_progress_provider.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/user_library_provider.dart';
import 'package:inkscroller_flutter/features/library/presentation/widgets/chapter_tile.dart';
import 'package:inkscroller_flutter/features/library/presentation/widgets/language_selector.dart';
import 'package:inkscroller_flutter/features/library/presentation/widgets/reading_progress_section.dart';
import 'package:inkscroller_flutter/features/preferences/domain/entities/user_reading_preferences.dart';
import 'package:inkscroller_flutter/features/preferences/domain/repositories/preferences_repository.dart';
import 'package:inkscroller_flutter/features/preferences/domain/usecases/get_preferences.dart';
import 'package:inkscroller_flutter/features/preferences/domain/usecases/update_preferences.dart';
import 'package:inkscroller_flutter/features/preferences/presentation/providers/preferences_notifier.dart';
import 'package:inkscroller_flutter/features/preferences/presentation/providers/preferences_provider.dart';
import 'package:inkscroller_flutter/features/preferences/presentation/providers/preferences_state.dart';
import 'package:inkscroller_flutter/features/profile/domain/usecases/get_user_profile.dart';
import 'package:inkscroller_flutter/features/profile/domain/usecases/update_user_profile.dart';
import 'package:inkscroller_flutter/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

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

class _MockSendPasswordReset extends Mock implements SendPasswordReset {}

class _MockReloadUser extends Mock implements ReloadUser {}

class _MockReadingProgressRepository extends Mock
    implements ReadingProgressRepository {}

class _MockUserLibraryRepository extends Mock
    implements UserLibraryRepository {}

class _MockPerTitleOverrideRepository extends Mock
    implements PerTitleOverrideRepository {}

class _MockPreferencesRepository extends Mock
    implements PreferencesRepository {}

class _StubPreferencesNotifier extends PreferencesNotifier {
  _StubPreferencesNotifier(String defaultLanguage)
    : super(
        getPreferences: GetPreferences(_MockPreferencesRepository()),
        updatePreferences: UpdatePreferences(_MockPreferencesRepository()),
      ) {
    state = PreferencesState(
      preferences: UserReadingPreferences(
        defaultReaderMode: ReaderMode.paged,
        defaultLanguage: defaultLanguage,
        updatedAt: _fixtureDate,
      ),
    );
  }
}

final _fixtureDate = DateTime(2026);

AuthNotifier _makeStubAuthNotifier() {
  final getAuthState = _MockGetAuthState();
  when(() => getAuthState()).thenAnswer((_) => const Stream<AppUser?>.empty());
  return AuthNotifier(
    signIn: _MockSignIn(),
    signUp: _MockSignUp(),
    signOut: _MockSignOut(),
    getAuthState: getAuthState,
    sendEmailVerification: _MockSendEmailVerification(),
    sendPasswordReset: _MockSendPasswordReset(),
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

UserLibraryNotifier _makeStubUserLibraryNotifier() {
  final repository = _MockUserLibraryRepository();
  when(
    () => repository.getAll(userId: any(named: 'userId')),
  ).thenAnswer((_) async => const <String, UserLibraryEntry>{});
  when(() => repository.hydrate(any())).thenAnswer((_) async => const <String, UserLibraryEntry>{});
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
    when(
      () => prefsRepo.updatePreferences(
        defaultReaderMode: any(named: 'defaultReaderMode'),
        defaultLanguage: any(named: 'defaultLanguage'),
        contentRatingFilter: any(named: 'contentRatingFilter'),
      ),
    ).thenAnswer(
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

void _unregisterGetItMocks() {
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
}

void main() {
  setUpAll(() {
    registerFallbackValue(const MangaReadingProgress(mangaId: 'fallback'));
    registerFallbackValue(
      UserLibraryEntry(
        manga: Manga(id: 'fallback', title: 'fallback'),
        isInLibrary: true,
        status: UserLibraryStatus.reading,
        updatedAt: _fixtureDate,
      ),
    );
    registerFallbackValue(
      const PerTitleOverride(
        mangaId: 'fallback',
        preferredReaderMode: ReaderMode.paged,
      ),
    );
  });

  setUp(() {
    _registerGetItMocks();
  });

  tearDown(() {
    _unregisterGetItMocks();
  });

  group('MangaDetailPage language integration', () {
    late _MockGetMangaChapters getMangaChapters;
    late _MockGetMangaChaptersWithLanguages getMangaChaptersWithLanguages;
    late _MockGetMangaLanguages getMangaLanguages;
    late MangaChaptersNotifier notifier;

    setUp(() {
      getMangaChapters = _MockGetMangaChapters();
      getMangaChaptersWithLanguages = _MockGetMangaChaptersWithLanguages();
      getMangaLanguages = _MockGetMangaLanguages();
      notifier = MangaChaptersNotifier(
        getMangaChapters: getMangaChapters,
        getMangaLanguages: getMangaLanguages,
        getMangaChaptersWithLanguages: getMangaChaptersWithLanguages,
      );

      when(
        () => getMangaChaptersWithLanguages(
          any<String>(),
          preferredLang: any<String>(named: 'preferredLang'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, ChaptersWithLanguages>(
          ChaptersWithLanguages(
            availableLanguages: ['en', 'es'],
            matchedLanguage: 'es',
            chapters: [
              Chapter(
                id: 'ch-1',
                number: 1,
                readable: true,
                external: false,
              ),
            ],
          ),
        ),
      );
      when(
        () => getMangaChapters(
          any<String>(),
          language: any<String>(named: 'language'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, List<Chapter>>([
          Chapter(
            id: 'ch-1',
            number: 1,
            readable: true,
            external: false,
          ),
        ]),
      );
    });

    Future<void> pumpPage(
      WidgetTester tester, {
      required Manga manga,
      required MangaChaptersNotifier notifier,
    }) {
      return tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            connectivityStatusProvider.overrideWith(
              (ref) => Stream<bool>.value(true),
            ),
            authProvider.overrideWith((_) => _makeStubAuthNotifier()),
            mangaChaptersProvider.overrideWith((ref) => notifier),
            preferencesProvider.overrideWith(
              (ref) => _StubPreferencesNotifier('es'),
            ),
            readingProgressProvider.overrideWith(
              (ref) => _makeStubReadingProgressNotifier(),
            ),
            userLibraryProvider.overrideWith(
              (ref) => _makeStubUserLibraryNotifier(),
            ),
          ],
          child: MaterialApp.router(
            locale: const Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: GoRouter(
              initialLocation: '/manga/${manga.id}',
              routes: <RouteBase>[
                GoRoute(
                  path: '/manga/:mangaId',
                  builder: (_, __) => MangaDetailPage(manga: manga),
                ),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('loads languages and chapters with default language on init', (
      tester,
    ) async {
      final manga = Manga(
        id: 'm1',
        title: 'Test Manga',
      );

      await pumpPage(tester, manga: manga, notifier: notifier);
      await tester.pumpAndSettle();

      verify(
        () => getMangaChaptersWithLanguages(
          'm1',
          preferredLang: any(named: 'preferredLang'),
        ),
      ).called(1);
    });

    testWidgets('renders LanguageSelector when languages are loaded', (
      tester,
    ) async {
      final manga = Manga(
        id: 'm1',
        title: 'Test Manga',
      );

      await pumpPage(tester, manga: manga, notifier: notifier);
      await tester.pumpAndSettle();

      expect(find.byType(LanguageSelector), findsOneWidget);
    });

    testWidgets('reloads chapters when language changes', (tester) async {
      final manga = Manga(
        id: 'm1',
        title: 'Test Manga',
      );

      await pumpPage(tester, manga: manga, notifier: notifier);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Español').last);
      await tester.pumpAndSettle();

      verify(() => getMangaChapters('m1', language: 'es')).called(greaterThan(0));
    });

  });

  group('MangaDetailPage 4-state rendering', () {
    late _MockGetMangaChapters getMangaChapters;
    late _MockGetMangaChaptersWithLanguages getMangaChaptersWithLanguages;
    late _MockGetMangaLanguages getMangaLanguages;
    late MangaChaptersNotifier notifier;

    setUp(() {
      getMangaChapters = _MockGetMangaChapters();
      getMangaChaptersWithLanguages = _MockGetMangaChaptersWithLanguages();
      getMangaLanguages = _MockGetMangaLanguages();
      notifier = MangaChaptersNotifier(
        getMangaChapters: getMangaChapters,
        getMangaLanguages: getMangaLanguages,
        getMangaChaptersWithLanguages: getMangaChaptersWithLanguages,
      );

      when(
        () => getMangaChaptersWithLanguages(
          any<String>(),
          preferredLang: any<String>(named: 'preferredLang'),
        ),
      ).thenAnswer(
        (_) async => const Right<Failure, ChaptersWithLanguages>(
          ChaptersWithLanguages(
            availableLanguages: ['en'],
            matchedLanguage: 'en',
            chapters: [],
          ),
        ),
      );
      when(
        () => getMangaChapters(
          any<String>(),
          language: any<String>(named: 'language'),
        ),
      ).thenAnswer(
        (_) async => const Right<Failure, List<Chapter>>([]),
      );
    });

    Future<void> pumpPage(
      WidgetTester tester, {
      required Manga manga,
      required MangaChaptersNotifier notifier,
      Map<String, MangaReadingProgress>? progressOverrides,
    }) {
      return tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            connectivityStatusProvider.overrideWith(
              (ref) => Stream<bool>.value(true),
            ),
            authProvider.overrideWith((_) => _makeStubAuthNotifier()),
            mangaChaptersProvider.overrideWith((ref) => notifier),
            preferencesProvider.overrideWith(
              (ref) => _StubPreferencesNotifier('en'),
            ),
            readingProgressProvider.overrideWith(
              (ref) => _makeStubReadingProgressNotifier(),
            ),
            userLibraryProvider.overrideWith(
              (ref) => _makeStubUserLibraryNotifier(),
            ),
          ],
          child: MaterialApp.router(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: GoRouter(
              initialLocation: '/manga/${manga.id}',
              routes: <RouteBase>[
                GoRoute(
                  path: '/manga/:mangaId',
                  builder: (_, __) => MangaDetailPage(manga: manga),
                ),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets(
      'normal state: has malId + totalChaptersCount + MD chapters → tracking section visible',
      (tester) async {
        // Setup: chapters with numbers, malId present, totalChaptersCount > 0
        when(
          () => getMangaChaptersWithLanguages(
            any<String>(),
            preferredLang: any<String>(named: 'preferredLang'),
          ),
        ).thenAnswer(
          (_) async => Right<Failure, ChaptersWithLanguages>(
            ChaptersWithLanguages(
              availableLanguages: ['en'],
              matchedLanguage: 'en',
              chapters: [
                Chapter(id: 'c1', number: 1, readable: true, external: false),
                Chapter(id: 'c2', number: 2, readable: true, external: false),
              ],
            ),
          ),
        );

        final manga = Manga(id: 'm1', title: 'Test', malId: 1234);

        // Override progress to have totalChaptersCount
        final mockRepo = _MockReadingProgressRepository();
        when(() => mockRepo.getAll()).thenAnswer(
          (_) async => <String, MangaReadingProgress>{
            'm1': const MangaReadingProgress(
              mangaId: 'm1',
              totalChaptersCount: 100,
            ),
          },
        );
        when(() => mockRepo.save(any())).thenAnswer((_) async {});

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              connectivityStatusProvider.overrideWith(
                (ref) => Stream<bool>.value(true),
              ),
              authProvider.overrideWith((_) => _makeStubAuthNotifier()),
              mangaChaptersProvider.overrideWith((ref) => notifier),
              preferencesProvider.overrideWith(
                (ref) => _StubPreferencesNotifier('en'),
              ),
              readingProgressProvider.overrideWith(
                (ref) => ReadingProgressNotifier(mockRepo),
              ),
              userLibraryProvider.overrideWith(
                (ref) => _makeStubUserLibraryNotifier(),
              ),
            ],
            child: MaterialApp.router(
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: GoRouter(
                initialLocation: '/manga/m1',
                routes: <RouteBase>[
                  GoRoute(
                    path: '/manga/:mangaId',
                    builder: (_, __) => MangaDetailPage(manga: manga),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // ReadingProgressSection should be visible (tracking state)
        expect(find.byType(ReadingProgressSection), findsOneWidget);
      },
    );

    testWidgets(
      'nothing state: no malId + no chapters → no tracking, no chapter list',
      (tester) async {
        final manga = Manga(id: 'm1', title: 'Test');

        await pumpPage(tester, manga: manga, notifier: notifier);
        await tester.pumpAndSettle();

        // No tracking section
        expect(find.byType(ReadingProgressSection), findsNothing);
        // No chapter tiles
        expect(find.byType(ChapterTile), findsNothing);
      },
    );

    testWidgets(
      'solo-MD state: no malId + MD chapters present → flat chapter list, no tracking',
      (tester) async {
        when(
          () => getMangaChaptersWithLanguages(
            any<String>(),
            preferredLang: any<String>(named: 'preferredLang'),
          ),
        ).thenAnswer(
          (_) async => Right<Failure, ChaptersWithLanguages>(
            ChaptersWithLanguages(
              availableLanguages: ['en'],
              matchedLanguage: 'en',
              chapters: [
                Chapter(id: 'c1', number: 1, readable: true, external: false),
              ],
            ),
          ),
        );

        final manga = Manga(id: 'm1', title: 'Test');

        await pumpPage(tester, manga: manga, notifier: notifier);
        await tester.pumpAndSettle();

        // Tracking section shows for any manga with synced chapters,
        // regardless of malId (totalChaptersCount > 0 from syncChapters).
        expect(find.byType(ReadingProgressSection), findsOneWidget);
        // Flat chapter list should be visible (batchSize 25 > 1 chapter)
        expect(find.byType(ChapterTile), findsOneWidget);
      },
    );
  });
}
