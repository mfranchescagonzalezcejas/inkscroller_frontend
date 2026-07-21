import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/di/injection.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
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
import 'package:inkscroller_flutter/features/home/presentation/providers/home_provider.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga_tags.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/get_manga_list.dart';
import 'package:inkscroller_flutter/features/library/domain/usecases/search_manga.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/library/library_notifier.dart';
import 'package:inkscroller_flutter/features/preferences/domain/usecases/get_preferences.dart';
import 'package:inkscroller_flutter/features/preferences/domain/usecases/update_preferences.dart';
import 'package:inkscroller_flutter/features/preferences/domain/entities/user_reading_preferences.dart';
import 'package:inkscroller_flutter/features/preferences/presentation/providers/preferences_notifier.dart';
import 'package:inkscroller_flutter/features/preferences/presentation/providers/preferences_provider.dart';
import 'package:inkscroller_flutter/features/profile/domain/usecases/get_user_profile.dart';
import 'package:inkscroller_flutter/features/profile/domain/usecases/update_user_profile.dart';
import 'package:inkscroller_flutter/features/profile/domain/entities/user_profile.dart';
import 'package:inkscroller_flutter/features/profile/presentation/providers/user_profile_notifier.dart';
import 'package:inkscroller_flutter/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockGetMangaList extends Mock implements GetMangaList {}

class _MockSearchManga extends Mock implements SearchManga {}

class _MockSignIn extends Mock implements SignIn {}

class _MockSignUp extends Mock implements SignUp {}

class _MockSignOut extends Mock implements SignOut {}

class _MockGetAuthState extends Mock implements GetAuthState {}

class _MockSendEmailVerification extends Mock
    implements SendEmailVerification {}

class _MockSendPasswordReset extends Mock implements SendPasswordReset {}

class _MockReloadUser extends Mock implements ReloadUser {}

class _MockGetUserProfile extends Mock implements GetUserProfile {}

class _MockUpdateUserProfile extends Mock implements UpdateUserProfile {}

class _MockGetPreferences extends Mock implements GetPreferences {}

class _MockUpdatePreferences extends Mock implements UpdatePreferences {}

void main() {
  setUp(LibraryNotifier.resetSharedCache);

  test('guest Home loads safe shounen and shoujo catalog filters', () async {
    await sl.reset();
    addTearDown(sl.reset);
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final getMangaList = _MockGetMangaList();
    final authEvents = StreamController<AppUser?>();
    addTearDown(authEvents.close);
    final getAuthState = _MockGetAuthState();
    when(() => getAuthState()).thenAnswer((_) => authEvents.stream);
    when(
      () => getMangaList(
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
        order: any(named: 'order'),
        genre: any(named: 'genre'),
        contentRating: any(named: 'contentRating'),
        demographics: any(named: 'demographics'),
      ),
    ).thenAnswer((_) async => const Right<Failure, List<Manga>>(<Manga>[]));
    sl
      ..registerLazySingleton<SharedPreferences>(() => preferences)
      ..registerLazySingleton<GetMangaList>(() => getMangaList)
      ..registerLazySingleton<SearchManga>(_MockSearchManga.new);

    final container = ProviderContainer(
      overrides: <Override>[
        authProvider.overrideWith(
          (_) => AuthNotifier(
            signIn: _MockSignIn(),
            signUp: _MockSignUp(),
            signOut: _MockSignOut(),
            getAuthState: getAuthState,
            sendEmailVerification: _MockSendEmailVerification(),
            sendPasswordReset: _MockSendPasswordReset(),
            reloadUser: _MockReloadUser(),
            getUserProfile: _MockGetUserProfile(),
            updateUserProfile: _MockUpdateUserProfile(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(homeDataProvider);
    authEvents.add(null);
    await Future<void>.delayed(Duration.zero);

    verify(
      () => getMangaList(
        limit: 20,
        offset: 0,
        contentRating: 'safe',
        demographics: const <MangaDemographic>[
          MangaDemographic.shounen,
          MangaDemographic.shoujo,
        ],
      ),
    ).called(1);
  });

  test(
    'authenticated Home falls back after profile and preferences fail',
    () async {
      await sl.reset();
      addTearDown(sl.reset);
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();
      final getMangaList = _MockGetMangaList();
      final authEvents = StreamController<AppUser?>();
      addTearDown(authEvents.close);
      final getAuthState = _MockGetAuthState();
      when(() => getAuthState()).thenAnswer((_) => authEvents.stream);
      final getUserProfile = _MockGetUserProfile();
      when(() => getUserProfile()).thenAnswer(
        (_) async => const Left<Failure, UserProfile>(
          ServerFailure(message: 'Profile unavailable'),
        ),
      );
      when(
        () => getMangaList(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          order: any(named: 'order'),
          genre: any(named: 'genre'),
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      ).thenAnswer((_) async => const Right<Failure, List<Manga>>(<Manga>[]));
      final getPreferences = _MockGetPreferences();
      when(() => getPreferences()).thenAnswer(
        (_) async => const Left<Failure, UserReadingPreferences>(
          ServerFailure(message: 'Preferences unavailable'),
        ),
      );
      final preferencesNotifier = PreferencesNotifier(
        getPreferences: getPreferences,
        updatePreferences: _MockUpdatePreferences(),
      );
      final profileNotifier = UserProfileNotifier(
        getUserProfile: getUserProfile,
        updateUserProfile: _MockUpdateUserProfile(),
      );
      sl
        ..registerLazySingleton<SharedPreferences>(() => preferences)
        ..registerLazySingleton<GetMangaList>(() => getMangaList)
        ..registerLazySingleton<SearchManga>(_MockSearchManga.new);

      final container = ProviderContainer(
        overrides: <Override>[
          authProvider.overrideWith(
            (_) => AuthNotifier(
              signIn: _MockSignIn(),
              signUp: _MockSignUp(),
              signOut: _MockSignOut(),
              getAuthState: getAuthState,
              sendEmailVerification: _MockSendEmailVerification(),
              sendPasswordReset: _MockSendPasswordReset(),
              reloadUser: _MockReloadUser(),
              getUserProfile: getUserProfile,
              updateUserProfile: _MockUpdateUserProfile(),
            ),
          ),
          preferencesProvider.overrideWith((_) => preferencesNotifier),
          userProfileProvider.overrideWith((_) => profileNotifier),
        ],
      );
      addTearDown(container.dispose);

      container.read(preferencesProvider);
      container.read(userProfileProvider);
      container.listen(homeDataProvider, (_, __) {});
      authEvents.add(
        const AppUser(
          uid: 'user-1',
          email: 'user@example.com',
          isEmailVerified: true,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(container.read(authProvider).user?.isEmailVerified, isTrue);
      verifyNever(
        () => getMangaList(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          order: any(named: 'order'),
          genre: any(named: 'genre'),
          contentRating: any(named: 'contentRating'),
          demographics: any(named: 'demographics'),
        ),
      );
      await container.read(preferencesProvider.notifier).loadPreferences();
      await container.read(userProfileProvider.notifier).loadProfile();
      expect(container.read(preferencesProvider).error, isNotNull);
      expect(container.read(userProfileProvider).error, isNotNull);

      verify(
        () => getMangaList(
          limit: 20,
          offset: 0,
          contentRating: 'safe',
          demographics: const <MangaDemographic>[
            MangaDemographic.shounen,
            MangaDemographic.shoujo,
          ],
        ),
      ).called(1);
    },
  );

  testWidgets('Discover caches non-All results per filter', (tester) async {
    await sl.reset();
    addTearDown(sl.reset);
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final getMangaList = _MockGetMangaList();
    final romance = Manga(
      id: 'romance',
      title: 'Romance',
      genres: const ['Romance'],
    );
    final action = Manga(
      id: 'action',
      title: 'Action',
      genres: const ['Action'],
    );

    when(
      () => getMangaList(
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
        order: any(named: 'order'),
        genre: any(named: 'genre'),
        contentRating: any(named: 'contentRating'),
        demographics: any(named: 'demographics'),
        language: any(named: 'language'),
      ),
    ).thenAnswer((invocation) async {
      final genre = invocation.namedArguments[#genre] as String?;
      return Right<Failure, List<Manga>>(<Manga>[
        if (genre == 'romance') romance,
        if (genre == 'action') action,
      ]);
    });

    sl
      ..registerLazySingleton<SharedPreferences>(() => preferences)
      ..registerLazySingleton<GetMangaList>(() => getMangaList)
      ..registerLazySingleton<SearchManga>(_MockSearchManga.new);

    WidgetRef? widgetRef;
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (_, ref, __) {
            widgetRef = ref;
            ref.watch(homeDiscoverMangasProvider);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    triggerDiscoverFilter(widgetRef!, HomeDiscoverFilter.romance);
    await tester.pump();
    await tester.pump();
    expect(widgetRef!.read(homeDiscoverMangasProvider), <Manga>[romance]);

    triggerDiscoverFilter(widgetRef!, HomeDiscoverFilter.action);
    expect(widgetRef!.read(homeDiscoverMangasProvider), isEmpty);
    await tester.pump();
    await tester.pump();
    expect(widgetRef!.read(homeDiscoverMangasProvider), <Manga>[action]);

    triggerDiscoverFilter(widgetRef!, HomeDiscoverFilter.romance);
    expect(widgetRef!.read(homeDiscoverMangasProvider), <Manga>[romance]);
  });
}
