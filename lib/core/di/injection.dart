import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../features/auth/data/datasources/firebase_auth_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_auth_state.dart';
import '../../features/auth/domain/usecases/get_id_token.dart';
import '../../features/auth/domain/usecases/reload_user.dart';
import '../../features/auth/domain/usecases/send_email_verification.dart';
import '../../features/auth/domain/usecases/send_password_reset.dart';
import '../../features/auth/domain/usecases/sign_in.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/domain/usecases/sign_up.dart';
import '../../features/home/data/datasources/home_remote_ds.dart';
import '../../features/home/data/datasources/home_remote_ds_impl.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/get_latest_home_chapters.dart';
import '../../features/library/data/datasources/library_local_ds.dart';
import '../../features/library/data/datasources/library_local_ds_impl.dart';
import '../../features/library/data/datasources/library_remote_ds.dart';
import '../../features/library/data/datasources/library_remote_ds_impl.dart';
import '../../features/library/data/datasources/user_library_remote_ds.dart';
import '../../features/library/data/datasources/user_library_remote_ds_impl.dart';
import '../../features/library/data/repositories/library_repository_impl.dart';
import '../../features/library/data/repositories/per_title_override_repository_impl.dart';
import '../../features/library/data/repositories/reading_progress_repository_impl.dart';
import '../../features/library/data/repositories/user_library_repository_impl.dart';
import '../../features/library/domain/repositories/library_repository.dart';
import '../../features/library/domain/repositories/per_title_override_repository.dart';
import '../../features/library/domain/repositories/reading_progress_repository.dart';
import '../../features/library/domain/repositories/user_library_repository.dart';
import '../../features/library/domain/usecases/get_chapter_pages.dart';
import '../../features/library/domain/usecases/get_manga_chapters.dart';
import '../../features/library/domain/usecases/get_manga_chapters_with_languages.dart';
import '../../features/library/domain/usecases/get_manga_detail.dart';
import '../../features/library/domain/usecases/get_manga_languages.dart';
import '../../features/library/domain/usecases/get_manga_list.dart';
import '../../features/library/domain/usecases/get_per_title_override.dart';
import '../../features/library/domain/usecases/remove_per_title_override.dart';
import '../../features/library/domain/usecases/resolve_reader_mode.dart';
import '../../features/library/domain/usecases/save_per_title_override.dart';
import '../../features/library/domain/usecases/search_manga.dart';
import '../../features/preferences/data/datasources/preferences_local_ds.dart';
import '../../features/preferences/data/datasources/preferences_local_ds_impl.dart';
import '../../features/preferences/data/datasources/preferences_remote_ds.dart';
import '../../features/preferences/data/datasources/preferences_remote_ds_impl.dart';
import '../../features/preferences/data/repositories/preferences_repository_impl.dart';
import '../../features/preferences/domain/repositories/preferences_repository.dart';
import '../../features/preferences/domain/usecases/get_preferences.dart';
import '../../features/preferences/domain/usecases/update_preferences.dart';
import '../../features/profile/data/datasources/user_profile_remote_ds.dart';
import '../../features/profile/data/datasources/user_profile_remote_ds_impl.dart';
import '../../features/profile/data/repositories/user_profile_repository_impl.dart';
import '../../features/profile/domain/repositories/user_profile_repository.dart';
import '../../features/profile/domain/usecases/get_user_profile.dart';
import '../../features/profile/domain/usecases/update_user_profile.dart';
import '../../features/settings/data/datasources/settings_remote_ds.dart';
import '../../features/settings/data/datasources/settings_remote_ds_impl.dart';
import '../../features/settings/data/repositories/account_cleanup_repository_impl.dart';
import '../../features/settings/data/repositories/settings_cache_repository_impl.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/account_cleanup_repository.dart';
import '../../features/settings/domain/repositories/settings_cache_repository.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/usecases/clear_settings_cache.dart';
import '../../features/settings/domain/usecases/get_settings_cache_size.dart';
import '../network/dio_client.dart';

/// Global get_it service locator instance used across the app.
final sl = GetIt.instance;

/// Registers [factory] as a [LazySingleton] only if [T] is not already
/// registered in [sl]. Skips silently when the type is present.
void _registerIfAbsent<T extends Object>(T Function() factory) {
  if (!sl.isRegistered<T>()) {
    sl.registerLazySingleton<T>(factory);
  }
}

/// Registers all infrastructure dependencies as lazy singletons.
///
/// Called once during app bootstrap in [mainCommon] before `runApp`.
/// Wires [DioClient], auth, data sources, repositories, and use cases.
/// Safe to call multiple times — each registration is individually guarded.
Future<void> initDI() async {
  // ── SharedPrefs ─────────────────────────────────────────────────────────
  if (!sl.isRegistered<SharedPreferences>()) {
    final sharedPreferences = await SharedPreferences.getInstance();
    sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  }

  // ── Auth ────────────────────────────────────────────────────────────────
  _registerIfAbsent<FirebaseAuth>(() => FirebaseAuth.instance);

  _registerIfAbsent<FirebaseAuthDataSource>(
    () => FirebaseAuthDataSourceImpl(sl<FirebaseAuth>()),
  );

  _registerIfAbsent<AuthRepository>(
    () => AuthRepositoryImpl(sl<FirebaseAuthDataSource>()),
  );

  _registerIfAbsent<SignIn>(() => SignIn(sl<AuthRepository>()));
  _registerIfAbsent<SignUp>(() => SignUp(sl<AuthRepository>()));
  _registerIfAbsent<SignOut>(() => SignOut(sl<AuthRepository>()));
  _registerIfAbsent<GetAuthState>(() => GetAuthState(sl<AuthRepository>()));
  _registerIfAbsent<GetIdToken>(() => GetIdToken(sl<AuthRepository>()));
  _registerIfAbsent<SendEmailVerification>(
    () => SendEmailVerification(sl<AuthRepository>()),
  );
  _registerIfAbsent<SendPasswordReset>(
    () => SendPasswordReset(sl<AuthRepository>()),
  );
  _registerIfAbsent<ReloadUser>(
    () => ReloadUser(sl<AuthRepository>()),
  );

  // Core
  _registerIfAbsent<DioClient>(
    () => DioClient(
      tokenProvider: () async {
        final tokenResult = await sl<GetIdToken>()();

        return tokenResult.fold((_) => null, (token) => token);
      },
    ),
  );

  // Library - local datasource
  _registerIfAbsent<LibraryLocalDataSource>(
    () => LibraryLocalDataSourceImpl(sl<SharedPreferences>()),
  );

  // Library - datasource
  _registerIfAbsent<LibraryRemoteDataSource>(
    () => LibraryRemoteDataSourceImpl(sl<DioClient>().dio),
  );

  // Library - repository
  _registerIfAbsent<LibraryRepository>(
    () => LibraryRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      mangaListCacheTtl: const Duration(
        minutes: AppConstants.mangaListCacheTtlMinutes,
      ),
      mangaDetailCacheTtl: const Duration(
        minutes: AppConstants.mangaDetailCacheTtlMinutes,
      ),
      mangaChaptersCacheTtl: const Duration(
        minutes: AppConstants.mangaChaptersCacheTtlMinutes,
      ),
    ),
  );

  // Library - use cases
  _registerIfAbsent<GetMangaList>(() => GetMangaList(sl()));
  _registerIfAbsent<GetMangaDetail>(() => GetMangaDetail(sl()));
  _registerIfAbsent<GetMangaChapters>(() => GetMangaChapters(sl()));
  _registerIfAbsent<GetMangaChaptersWithLanguages>(
    () => GetMangaChaptersWithLanguages(sl<LibraryRepository>()),
  );
  _registerIfAbsent<GetMangaLanguages>(
    () => GetMangaLanguages(sl<LibraryRepository>()),
  );
  _registerIfAbsent<GetChapterPages>(
    () => GetChapterPages(sl<LibraryRepository>()),
  );
  _registerIfAbsent<ResolveReaderMode>(() => const ResolveReaderMode());
  _registerIfAbsent<SearchManga>(
    () => SearchManga(sl<LibraryRepository>()),
  );

  // Library - per-title override repository
  _registerIfAbsent<PerTitleOverrideRepository>(
    () => PerTitleOverrideRepositoryImpl(sl<SharedPreferences>()),
  );

  _registerIfAbsent<ReadingProgressRepository>(
    () => ReadingProgressRepositoryImpl(sl<SharedPreferences>()),
  );

  _registerIfAbsent<UserLibraryRemoteDataSource>(
    () => UserLibraryRemoteDataSourceImpl(dioClient: sl<DioClient>()),
  );

  _registerIfAbsent<UserLibraryRepository>(
    () => UserLibraryRepositoryImpl(
      sl<SharedPreferences>(),
      sl<UserLibraryRemoteDataSource>(),
    ),
  );

  _registerIfAbsent<SavePerTitleOverride>(
    () => SavePerTitleOverride(sl<PerTitleOverrideRepository>()),
  );
  _registerIfAbsent<GetPerTitleOverride>(
    () => GetPerTitleOverride(sl<PerTitleOverrideRepository>()),
  );
  _registerIfAbsent<RemovePerTitleOverride>(
    () => RemovePerTitleOverride(sl<PerTitleOverrideRepository>()),
  );

  // Preferences - local datasource
  _registerIfAbsent<PreferencesLocalDataSource>(
    () => PreferencesLocalDataSourceImpl(sl<SharedPreferences>()),
  );

  // Preferences - remote datasource
  _registerIfAbsent<PreferencesRemoteDataSource>(
    () => PreferencesRemoteDataSourceImpl(dioClient: sl<DioClient>()),
  );

  // Preferences - repository
  _registerIfAbsent<PreferencesRepository>(
    () => PreferencesRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

  // Preferences - use cases
  _registerIfAbsent<GetPreferences>(
    () => GetPreferences(sl<PreferencesRepository>()),
  );
  _registerIfAbsent<UpdatePreferences>(
    () => UpdatePreferences(sl<PreferencesRepository>()),
  );

  // Profile - remote datasource
  _registerIfAbsent<UserProfileRemoteDataSource>(
    () => UserProfileRemoteDataSourceImpl(dioClient: sl<DioClient>()),
  );

  // Profile - repository
  _registerIfAbsent<UserProfileRepository>(
    () => UserProfileRepositoryImpl(remoteDataSource: sl()),
  );

  // Profile - use cases
  _registerIfAbsent<GetUserProfile>(
    () => GetUserProfile(sl<UserProfileRepository>()),
  );
  _registerIfAbsent<UpdateUserProfile>(
    () => UpdateUserProfile(sl<UserProfileRepository>()),
  );

  // Home - datasource
  _registerIfAbsent<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(sl<DioClient>().dio),
  );

  // Home - repository
  _registerIfAbsent<HomeRepository>(
    () => HomeRepositoryImpl(remote: sl<HomeRemoteDataSource>()),
  );

  // Home - use cases
  _registerIfAbsent<GetLatestHomeChapters>(
    () => GetLatestHomeChapters(sl<HomeRepository>()),
  );

  // Settings - cache repository
  _registerIfAbsent<SettingsCacheRepository>(
    () => SettingsCacheRepositoryImpl(sharedPreferences: sl<SharedPreferences>()),
  );

  // Settings - cache use cases
  _registerIfAbsent<ClearSettingsCache>(
    () => ClearSettingsCache(sl<SettingsCacheRepository>()),
  );
  _registerIfAbsent<GetSettingsCacheSize>(
    () => GetSettingsCacheSize(sl<SettingsCacheRepository>()),
  );

  // Settings - account deletion
  _registerIfAbsent<SettingsRemoteDataSource>(
    () => SettingsRemoteDataSourceImpl(dioClient: sl<DioClient>()),
  );
  _registerIfAbsent<SettingsRepository>(
    () => SettingsRepositoryImpl(remoteDataSource: sl<SettingsRemoteDataSource>()),
  );
  _registerIfAbsent<AccountCleanupRepository>(
    () => AccountCleanupRepositoryImpl(
      firebaseAuth: sl<FirebaseAuth>(),
      prefs: sl<SharedPreferences>(),
    ),
  );
}
