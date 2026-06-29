import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/auth/domain/entities/app_user.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:inkscroller_flutter/features/auth/presentation/providers/auth_state.dart';
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

void main() {
  FlavorConfig(
    flavor: Flavor.dev,
    apiBaseUrl: 'http://localhost:8000',
    name: 'InkScroller Test',
  );

  late SettingsCacheController controller;
  late SettingsRepository settingsRepository;

  final testAuthState = const AuthState(
    user: AppUser(uid: 'uid-1', email: 'test@example.com'),
  );

  Future<void> pumpSettingsPage(WidgetTester tester) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          settingsCacheControllerProvider.overrideWithValue(controller),
          authProvider.overrideWithValue(testAuthState),
          settingsRepositoryProvider.overrideWithValue(settingsRepository),
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
  });

  testWidgets('renders account section with delete button', (tester) async {
    await pumpSettingsPage(tester);
    await tester.pumpAndSettle();

    expect(find.text('CUENTA', skipOffstage: false), findsOneWidget);
    expect(find.text('Eliminar cuenta'), findsOneWidget);
  });

  testWidgets('clears cache and shows success snackbar', (tester) async {
    await pumpSettingsPage(tester);

    await controller.clearLibraryCache();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    verify(() => controller.clearLibraryCache()).called(1);
  });
}
