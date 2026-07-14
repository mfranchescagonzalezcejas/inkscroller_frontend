import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:inkscroller_flutter/core/di/injection.dart';
import 'package:inkscroller_flutter/features/auth/domain/entities/app_user.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/get_auth_state.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_in.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_out.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_up.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_notifier.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_state.dart';
import 'package:inkscroller_flutter/features/library/data/datasources/library_remote_ds.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga_capabilities.dart';
import 'package:inkscroller_flutter/features/preferences/domain/usecases/get_preferences.dart';
import 'package:inkscroller_flutter/features/preferences/domain/usecases/update_preferences.dart';
import 'package:inkscroller_flutter/features/preferences/presentation/providers/demographic_resolution_provider.dart';
import 'package:inkscroller_flutter/features/preferences/presentation/providers/manga_capabilities_provider.dart';
import 'package:inkscroller_flutter/features/preferences/presentation/providers/preferences_notifier.dart';
import 'package:inkscroller_flutter/features/preferences/presentation/providers/preferences_provider.dart';
import 'package:inkscroller_flutter/features/profile/domain/entities/user_profile.dart';
import 'package:inkscroller_flutter/features/profile/domain/usecases/get_user_profile.dart';
import 'package:inkscroller_flutter/features/profile/domain/usecases/update_user_profile.dart';
import 'package:inkscroller_flutter/features/profile/presentation/providers/user_profile_notifier.dart';
import 'package:inkscroller_flutter/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:inkscroller_flutter/features/profile/presentation/providers/user_profile_state.dart';
import 'package:mocktail/mocktail.dart';

class _A extends Mock implements SignIn {} class _B extends Mock implements SignUp {} class _C extends Mock implements SignOut {} class _D extends Mock implements GetAuthState {} class _E extends Mock implements GetUserProfile {} class _I extends Mock implements UpdateUserProfile {} class _F extends Mock implements GetPreferences {} class _G extends Mock implements UpdatePreferences {} class _H extends Mock implements LibraryRemoteDataSource {}

void main() {
  late _H remote;
  setUp(() async { await sl.reset(); remote = _H(); sl.registerLazySingleton<LibraryRemoteDataSource>(() => remote); });
  tearDown(() async => sl.reset());
  test('adult with supported capability may select unspecified', () async {
    final d = _D(); when(() => d()).thenAnswer((_) => const Stream<AppUser?>.empty());
    final auth = AuthNotifier(signIn: _A(), signUp: _B(), signOut: _C(), getAuthState: d, getUserProfile: _E(), updateUserProfile: _I())..state = const AuthState(user: AppUser(uid: 'user-1', email: 'adult@example.test'));
    final prefs = PreferencesNotifier(getPreferences: _F(), updatePreferences: _G());
    final profile = UserProfileNotifier(getUserProfile: _E())..state = UserProfileState(profile: UserProfile(firebaseUid: 'user-1', email: 'adult@example.test', birthDate: DateTime(1990, 1, 1), createdAt: DateTime(2020)));
    when(() => remote.getMangaCapabilities()).thenAnswer((_) async => const MangaCapabilities(supportsUnspecified: true));
    final c = ProviderContainer(overrides: [authProvider.overrideWith((_) => auth), preferencesProvider.overrideWith((_) => prefs), userProfileProvider.overrideWith((_) => profile)]); addTearDown(c.dispose);
    await c.read(mangaCapabilitiesProvider.future);
    expect(c.read(demographicResolutionProvider).allowedOptions.map((e) => e.name), contains('unspecified'));
  });

  Future<ProviderContainer> containerFor({required AppUser? user, required DateTime? birthDate, required bool fails}) async {
      final d = _D(); when(() => d()).thenAnswer((_) => const Stream<AppUser?>.empty());
      final auth = AuthNotifier(signIn: _A(), signUp: _B(), signOut: _C(), getAuthState: d, getUserProfile: _E(), updateUserProfile: _I())..state = AuthState(user: user);
      final prefs = PreferencesNotifier(getPreferences: _F(), updatePreferences: _G());
      final profile = UserProfileNotifier(getUserProfile: _E())..state = UserProfileState(profile: user == null ? null : UserProfile(firebaseUid: user.uid, email: user.email, birthDate: birthDate, createdAt: DateTime(2020)));
      if (fails) { when(() => remote.getMangaCapabilities()).thenThrow(DioException(requestOptions: RequestOptions(path: '/manga/capabilities'), type: DioExceptionType.connectionError)); } else { when(() => remote.getMangaCapabilities()).thenAnswer((_) async => const MangaCapabilities(supportsUnspecified: true)); }
      final c = ProviderContainer(overrides: [authProvider.overrideWith((_) => auth), preferencesProvider.overrideWith((_) => prefs), userProfileProvider.overrideWith((_) => profile)]); addTearDown(c.dispose);
      return c;
  }

  test('minor denies unspecified even when capability is supported', () async {
    final c = await containerFor(user: const AppUser(uid: 'minor', email: 'minor@test'), birthDate: DateTime(2010, 1, 1), fails: false);
    await c.read(mangaCapabilitiesProvider.future);
    expect(c.read(demographicResolutionProvider).allowedOptions.map((e) => e.name), isNot(contains('unspecified')));
  });
  test('guest denies unspecified even when capability is supported', () async {
    final c = await containerFor(user: null, birthDate: null, fails: false);
    await c.read(mangaCapabilitiesProvider.future);
    expect(c.read(demographicResolutionProvider).allowedOptions.map((e) => e.name), isNot(contains('unspecified')));
  });
  test('capability DioException fails closed and denies unspecified', () async {
    final c = await containerFor(user: const AppUser(uid: 'adult', email: 'adult@test'), birthDate: DateTime(1990, 1, 1), fails: true);
    final capabilities = await c.read(mangaCapabilitiesProvider.future);
    expect(capabilities, const MangaCapabilities(supportsUnspecified: false));
    expect(c.read(demographicResolutionProvider).allowedOptions.map((e) => e.name), isNot(contains('unspecified')));
  });
}
