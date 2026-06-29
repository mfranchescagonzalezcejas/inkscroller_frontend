import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../features/auth/data/datasources/firebase_auth_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_auth_state.dart';
import '../../features/auth/domain/usecases/get_id_token.dart';
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
import '../../features/library/domain/usecases/get_manga_detail.dart';
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
import '../../features/settings/data/repositories/settings_cache_repository_impl.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_cache_repository.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/usecases/clear_settings_cache.dart';
import '../../features/settings/domain/usecases/get_settings_cache_size.dart';
import '../network/dio_client.dart';

/// Global get_it service locator instance used across the app.
final sl = GetIt.instance;

/// Registers all infrastructure dependencies as lazy singletons.
///
/// Called once during app bootstrap in [mainCommon] before `runApp`.
/// Wires [DioClient], auth, data sources, repositories, and use cases.
Future<void> initDI() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // ── Auth ──────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);

  sl.registerLazySingleton<FirebaseAuthDataSource>(
    () => FirebaseAuthDataSourceImpl(sl<FirebaseAuth>()),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<FirebaseAuthDataSource>()),
  );

  sl.registerLazySingleton<SignIn>(() => SignIn(sl<AuthRepository>()));
  sl.registerLazySingleton<SignUp>(() => SignUp(sl<AuthRepository>()));
  sl.registerLazySingleton<SignOut>(() => SignOut(sl<AuthRepository>()));
  sl.registerLazySingleton<GetAuthState>(
    () => GetAuthState(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<GetIdToken>(() => GetIdToken(sl<AuthRepository>()));

  // Core
  sl.registerLazySingleton<DioClient>(
    () => DioClient(
      tokenProvider: () async {
        final tokenResult = await sl<GetIdToken>()();

        return tokenResult.fold((_) => null, (token) => token);
      },
    ),
  );

  // Library - local datasource
  sl.registerLazySingleton<LibraryLocalDataSource>(
    () => LibraryLocalDataSourceImpl(sl<SharedPreferences>()),
  );

  // Library - datasource
  sl.registerLazySingleton<LibraryRemoteDataSource>(
    () => LibraryRemoteDataSourceImpl(sl<DioClient>().dio),
  );

  // Library - repository
  sl.registerLazySingleton<LibraryRepository>(
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
  sl.registerLazySingleton<GetMangaList>(() => GetMangaList(sl()));

  sl.registerLazySingleton<GetMangaDetail>(() => GetMangaDetail(sl()));
  sl.registerLazySingleton<GetMangaChapters>(() => GetMangaChapters(sl()));

  sl.registerLazySingleton<GetChapterPages>(
    () => GetChapterPages(sl<LibraryRepository>()),
  );

  sl.registerLazySingleton<ResolveReaderMode>(() => const ResolveReaderMode());

  sl.registerLazySingleton<SearchManga>(
    () => SearchManga(sl<LibraryRepository>()),
  );

  // Library - per-title override repository
  sl.registerLazySingleton<PerTitleOverrideRepository>(
    () => PerTitleOverrideRepositoryImpl(sl<SharedPreferences>()),
  );

  sl.registerLazySingleton<ReadingProgressRepository>(
    () => ReadingProgressRepositoryImpl(sl<SharedPreferences>()),
  );

  sl.registerLazySingleton<UserLibraryRemoteDataSource>(
    () => UserLibraryRemoteDataSourceImpl(dioClient: sl<DioClient>()),
  );

  sl.registerLazySingleton<UserLibraryRepository>(
    () => UserLibraryRepositoryImpl(
      sl<SharedPreferences>(),
      sl<UserLibraryRemoteDataSource>(),
    ),
  );

  sl.registerLazySingleton<SavePerTitleOverride>(
    () => SavePerTitleOverride(sl<PerTitleOverrideRepository>()),
  );
  sl.registerLazySingleton<GetPerTitleOverride>(
    () => GetPerTitleOverride(sl<PerTitleOverrideRepository>()),
  );
  sl.registerLazySingleton<RemovePerTitleOverride>(
    () => RemovePerTitleOverride(sl<PerTitleOverrideRepository>()),
  );

  // Preferences - local datasource
  sl.registerLazySingleton<PreferencesLocalDataSource>(
    () => PreferencesLocalDataSourceImpl(sl<SharedPreferences>()),
  );

  // Preferences - remote datasource
  sl.registerLazySingleton<PreferencesRemoteDataSource>(
    () => PreferencesRemoteDataSourceImpl(dioClient: sl<DioClient>()),
  );

  // Preferences - repository
  sl.registerLazySingleton<PreferencesRepository>(
    () => PreferencesRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

  // Preferences - use cases
  sl.registerLazySingleton<GetPreferences>(
    () => GetPreferences(sl<PreferencesRepository>()),
  );
  sl.registerLazySingleton<UpdatePreferences>(
    () => UpdatePreferences(sl<PreferencesRepository>()),
  );

  // Profile - remote datasource
  sl.registerLazySingleton<UserProfileRemoteDataSource>(
    () => UserProfileRemoteDataSourceImpl(dioClient: sl<DioClient>()),
  );

  // Profile - repository
  sl.registerLazySingleton<UserProfileRepository>(
    () => UserProfileRepositoryImpl(remoteDataSource: sl()),
  );

  // Profile - use cases
  sl.registerLazySingleton<GetUserProfile>(
    () => GetUserProfile(sl<UserProfileRepository>()),
  );
  sl.registerLazySingleton<UpdateUserProfile>(
    () => UpdateUserProfile(sl<UserProfileRepository>()),
  );

  // Home - datasource
  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(sl<DioClient>().dio),
  );

  // Home - repository
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(remote: sl<HomeRemoteDataSource>()),
  );

  // Home - use cases
  sl.registerLazySingleton<GetLatestHomeChapters>(
    () => GetLatestHomeChapters(sl<HomeRepository>()),
  );

  // Settings - cache repository
  sl.registerLazySingleton<SettingsCacheRepository>(
    () =>
        SettingsCacheRepositoryImpl(sharedPreferences: sl<SharedPreferences>()),
  );

  // Settings - cache use cases
  sl.registerLazySingleton<ClearSettingsCache>(
    () => ClearSettingsCache(sl<SettingsCacheRepository>()),
  );
  sl.registerLazySingleton<GetSettingsCacheSize>(
    () => GetSettingsCacheSize(sl<SettingsCacheRepository>()),
  );

  // Settings - account deletion
  initSettingsDI();
}

/// Registers account-level settings dependencies (remote data source +
/// repository).
void initSettingsDI() {
  sl.registerLazySingleton<SettingsRemoteDataSource>(
    () => SettingsRemoteDataSourceImpl(dioClient: sl<DioClient>()),
  );

  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(remoteDataSource: sl<SettingsRemoteDataSource>()),
  );
}
