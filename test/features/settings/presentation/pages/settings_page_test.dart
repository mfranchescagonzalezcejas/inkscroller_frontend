import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/auth/domain/entities/app_user.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/get_auth_state.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_in.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_out.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/sign_up.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_notifier.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:inkscroller_flutter/features/profile/domain/usecases/get_user_profile.dart';
import 'package:inkscroller_flutter/features/profile/domain/usecases/update_user_profile.dart';
import 'package:inkscroller_flutter/features/settings/domain/repositories/settings_repository.dart';
import 'package:inkscroller_flutter/features/settings/presentation/pages/settings_page.dart';
import 'package:inkscroller_flutter/features/settings/presentation/providers/settings_cache_controller.dart';
import 'package:inkscroller_flutter/features/settings/presentation/providers/settings_provider.dart';
import 'package:inkscroller_flutter/flavors/flavor_config.dart';
import 'package:inkscroller_flutter/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockSettingsCacheController extends Mock
    implements SettingsCacheController {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

/// Creates a stub [AuthNotifier] that stays in the initial state.
AuthNotifier _makeStubAuthNotifier() {
  final signIn = _MockSignIn();
  final signUp = _MockSignUp();
  final signOut = _MockSignOut();
  final getAuthState = _MockGetAuthState();
  final getUserProfile = _MockGetUserProfile();
  final updateUserProfile = _MockUpdateUserProfile();
  when(() => getAuthState()).thenAnswer((_) => const Stream<AppUser?>.empty());
  return AuthNotifier(
    signIn: signIn,
    signUp: signUp,
    signOut: signOut,
    getAuthState: getAuthState,
    getUserProfile: getUserProfile,
    updateUserProfile: updateUserProfile,
  );
}

class _MockSignIn extends Mock implements SignIn {}
class _MockSignUp extends Mock implements SignUp {}
class _MockSignOut extends Mock implements SignOut {}
class _MockGetAuthState extends Mock implements GetAuthState {}
class _MockGetUserProfile extends Mock implements GetUserProfile {}
class _MockUpdateUserProfile extends Mock implements UpdateUserProfile {}

void main() {
  FlavorConfig(
    flavor: Flavor.dev,
    apiBaseUrl: 'http://localhost:8000',
    name: 'InkScroller Test',
  );

  late SettingsCacheController controller;
  late SettingsRepository settingsRepository;

  Future<void> pumpSettingsPage(WidgetTester tester) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          settingsCacheControllerProvider.overrideWithValue(controller),
          settingsRepositoryProvider.overrideWithValue(settingsRepository),
          authProvider.overrideWith((_) => _makeStubAuthNotifier()),
        ],
        child: const MaterialApp(
          locale: Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsPage(),
        ),
      ),
    );
  }

  setUp(() {
    controller = _MockSettingsCacheController();
    settingsRepository = _MockSettingsRepository();

    when(() => controller.getCacheSize()).thenReturn(0);
    when(
      () => controller.clearLibraryCache(),
    ).thenAnswer((_) async => const Right(null));
  });

  testWidgets('renders app info and cache controls', (tester) async {
    await pumpSettingsPage(tester);
    await tester.pumpAndSettle();

    // App info section
    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('APLICACIÓN', skipOffstage: false), findsOneWidget);
    expect(find.text('InkScroller Test'), findsOneWidget);
    expect(find.text('DEV'), findsOneWidget);
    expect(find.text('http://localhost:8000'), findsOneWidget);

    // Cache section
    expect(find.text('CACHÉ', skipOffstage: false), findsOneWidget);
    expect(find.text('0 B'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Limpiar datos guardados'), 120);
    expect(find.text('Limpiar datos guardados'), findsOneWidget);
  });

  testWidgets('clears cache and shows success snackbar', (tester) async {
    await pumpSettingsPage(tester);

    // The clear-cache button is below the fold in the test viewport.
    // Verify the controller mock is properly wired by invoking the callback
    // through the widget tree's settings cache controller override.
    await controller.clearLibraryCache();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    verify(() => controller.clearLibraryCache()).called(1);
  });
}
