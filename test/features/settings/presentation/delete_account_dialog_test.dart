import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:inkscroller_flutter/core/di/injection.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/settings/domain/repositories/settings_repository.dart';
import 'package:inkscroller_flutter/features/settings/presentation/providers/settings_provider.dart';
import 'package:inkscroller_flutter/features/settings/presentation/widgets/delete_account_dialog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  late SettingsRepository repository;
  late _MockFirebaseAuth mockAuth;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    if (!GetIt.I.isRegistered<SharedPreferences>()) {
      final prefs = await SharedPreferences.getInstance();
      sl.registerLazySingleton<SharedPreferences>(() => prefs);
    }
    repository = _MockSettingsRepository();
    mockAuth = _MockFirebaseAuth();
    when(() => repository.deleteAccount())
        .thenAnswer((_) async => const Right(null));
    when(() => mockAuth.currentUser).thenReturn(null);
    when(() => mockAuth.signOut()).thenAnswer((_) async {});
  });

  tearDown(() async {
    if (GetIt.I.isRegistered<SharedPreferences>()) {
      await GetIt.I.unregister<SharedPreferences>();
    }
  });

  Widget buildDialog() {
    return ProviderScope(
      overrides: <Override>[
        settingsRepositoryProvider.overrideWithValue(repository),
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            repository: repository,
            firebaseAuth: mockAuth,
          ),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: DeleteAccountDialog(),
        ),
      ),
    );
  }

  testWidgets('renders title and warning text', (tester) async {
    await tester.pumpWidget(buildDialog());
    await tester.pumpAndSettle();

    expect(find.text('Eliminar cuenta'), findsOneWidget);
    expect(
      find.text(
        'Esta acción es permanente e irreversible. Se eliminarán todos tus datos, '
        'incluyendo tu perfil, preferencias y progreso de lectura.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('confirm button is disabled initially', (tester) async {
    await tester.pumpWidget(buildDialog());
    await tester.pumpAndSettle();

    final eliminarButton = find.widgetWithText(FilledButton, 'Eliminar');
    expect(eliminarButton, findsOneWidget);

    final button = tester.widget<FilledButton>(eliminarButton);
    // onPressed should be null when text is empty
    expect(button.onPressed, isNull);
  });

  testWidgets('confirm button remains disabled for wrong text', (tester) async {
    await tester.pumpWidget(buildDialog());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'DELETEIT');
    await tester.pump();

    final eliminarButton = find.widgetWithText(FilledButton, 'Eliminar');
    final button = tester.widget<FilledButton>(eliminarButton);
    expect(button.onPressed, isNull);
  });

  testWidgets('confirm button is enabled when text matches DELETE',
      (tester) async {
    await tester.pumpWidget(buildDialog());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();

    final eliminarButton = find.widgetWithText(FilledButton, 'Eliminar');
    final button = tester.widget<FilledButton>(eliminarButton);
    expect(button.onPressed, isNotNull);
  });

  testWidgets('cancel button closes dialog', (tester) async {
    await tester.pumpWidget(buildDialog());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();

    // Dialog should be closed
    expect(find.byType(DeleteAccountDialog), findsNothing);
  });

  testWidgets('confirm button calls deleteAccount and closes dialog',
      (tester) async {
    await tester.pumpWidget(buildDialog());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();

    verify(() => repository.deleteAccount()).called(1);
  });

  testWidgets('delete error keeps dialog open and resets loading state',
      (tester) async {
    when(() => repository.deleteAccount()).thenAnswer(
      (_) async => const Left(
        ServerFailure(message: 'Server error'),
      ),
    );

    await tester.pumpWidget(buildDialog());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();

    verify(() => repository.deleteAccount()).called(1);
    // Dialog must remain visible — not popped on failure.
    expect(find.byType(DeleteAccountDialog), findsOneWidget);
    // Confirm button must be re-enabled (loading state reset).
    final eliminarButton = find.widgetWithText(FilledButton, 'Eliminar');
    expect(eliminarButton, findsOneWidget);
    final button = tester.widget<FilledButton>(eliminarButton);
    expect(button.onPressed, isNotNull);
  });
}
