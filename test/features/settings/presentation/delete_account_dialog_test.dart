// ignore_for_file: prefer_const_constructors
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/settings/domain/repositories/account_cleanup_repository.dart';
import 'package:inkscroller_flutter/features/settings/domain/repositories/settings_repository.dart';
import 'package:inkscroller_flutter/features/settings/presentation/providers/settings_provider.dart';
import 'package:inkscroller_flutter/features/settings/presentation/widgets/delete_account_dialog.dart';
import 'package:inkscroller_flutter/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

class _MockAccountCleanupRepository extends Mock
    implements AccountCleanupRepository {}

void main() {
  late SettingsRepository repository;
  late _MockAccountCleanupRepository mockCleanup;

  setUp(() {
    repository = _MockSettingsRepository();
    mockCleanup = _MockAccountCleanupRepository();
    when(() => mockCleanup.currentCleanupUserId).thenReturn('uid-1');
    when(
      () => repository.deleteAccount(),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => mockCleanup.cleanUpAfterDeletion(password: any(named: 'password')),
    ).thenAnswer((_) async => null);
    when(
      () => mockCleanup.hasDeletionCleanupPending(),
    ).thenAnswer((_) async => false);
    when(
      () => mockCleanup.markDeletionCleanupPending(),
    ).thenAnswer((_) async {});
    when(
      () => mockCleanup.clearDeletionCleanupPending(),
    ).thenAnswer((_) async {});
  });

  /// Builds dialog with optional initial state override.
  Widget buildDialog({SettingsState? initialState}) {
    return ProviderScope(
      overrides: <Override>[
        settingsRepositoryProvider.overrideWithValue(repository),
        settingsProvider.overrideWith((ref) {
          final notifier = SettingsNotifier(
            repository: repository,
            cleanup: mockCleanup,
          );
          if (initialState != null) {
            notifier.state = initialState;
          }
          return notifier;
        }),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: DeleteAccountDialog()),
      ),
    );
  }

  Widget buildDialogRoute({SettingsState? initialState}) {
    return ProviderScope(
      overrides: <Override>[
        settingsRepositoryProvider.overrideWithValue(repository),
        settingsProvider.overrideWith((ref) {
          final notifier = SettingsNotifier(
            repository: repository,
            cleanup: mockCleanup,
          );
          if (initialState != null) {
            notifier.state = initialState;
          }
          return notifier;
        }),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                key: const Key('openDeleteDialogButton'),
                onPressed: () {
                  showDialog<bool>(
                    context: context,
                    builder: (_) => const DeleteAccountDialog(),
                  );
                },
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );
  }

  testWidgets('renders title and warning text', (tester) async {
    await tester.pumpWidget(buildDialog());
    await tester.pumpAndSettle();

    expect(find.text('Delete account'), findsOneWidget);
    expect(
      find.text(
        'This action is permanent and irreversible. All your data will be deleted, including your profile, preferences, and reading progress.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('confirm button is disabled initially', (tester) async {
    await tester.pumpWidget(buildDialog());
    await tester.pumpAndSettle();

    final eliminarButton = find.widgetWithText(FilledButton, 'Delete');
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

    final eliminarButton = find.widgetWithText(FilledButton, 'Delete');
    final button = tester.widget<FilledButton>(eliminarButton);
    expect(button.onPressed, isNull);
  });

  testWidgets('confirm button is enabled when text matches DELETE', (
    tester,
  ) async {
    await tester.pumpWidget(buildDialog());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();

    final eliminarButton = find.widgetWithText(FilledButton, 'Delete');
    final button = tester.widget<FilledButton>(eliminarButton);
    expect(button.onPressed, isNotNull);
  });

  testWidgets('cancel button closes dialog', (tester) async {
    await tester.pumpWidget(buildDialog());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    // Dialog should be closed
    expect(find.byType(DeleteAccountDialog), findsNothing);
  });

  testWidgets('confirm button calls deleteAccount and closes dialog', (
    tester,
  ) async {
    await tester.pumpWidget(buildDialog());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    verify(() => repository.deleteAccount()).called(1);
  });

  testWidgets('delete error keeps dialog open and resets loading state', (
    tester,
  ) async {
    when(() => repository.deleteAccount()).thenAnswer(
      (_) async => const Left(ServerFailure(message: 'Server error')),
    );

    await tester.pumpWidget(buildDialog());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    verify(() => repository.deleteAccount()).called(1);
    // Dialog must remain visible — not popped on failure.
    expect(find.byType(DeleteAccountDialog), findsOneWidget);
    // Confirm button must be re-enabled (loading state reset).
    final eliminarButton = find.widgetWithText(FilledButton, 'Delete');
    expect(eliminarButton, findsOneWidget);
    final button = tester.widget<FilledButton>(eliminarButton);
    expect(button.onPressed, isNotNull);
  });

  testWidgets('recovery pending keeps dialog open and disables cancel', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildDialog(
        initialState: const SettingsState(
          cleanupRecoveryPending: true,
          deleteError: 'Error durante la limpieza',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Dialog is still open.
    expect(find.byType(DeleteAccountDialog), findsOneWidget);
    // Recovery message shown.
    expect(find.byKey(const Key('deleteRecoveryMessage')), findsOneWidget);
    // Confirm button shows "Finalizar" and is enabled.
    expect(find.widgetWithText(FilledButton, 'Finish'), findsOneWidget);
    // Cancel is disabled.
    final cancelBtn = find.widgetWithText(TextButton, 'Cancel');
    final cancelWidget = tester.widget<TextButton>(cancelBtn);
    expect(cancelWidget.onPressed, isNull);
  });

  testWidgets('requiresRecentLogin shows password field', (tester) async {
    await tester.pumpWidget(
      buildDialog(
        initialState: const SettingsState(
          cleanupRecoveryPending: true,
          requiresRecentLogin: true,
          deleteError: 'Volvé a iniciar sesión para completar la eliminación.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('deletePasswordField')), findsOneWidget);
    // DELETE field is not visible (recovery mode hides it).
    expect(find.byKey(const Key('deleteConfirmField')), findsNothing);
  });

  testWidgets(
    'confirm button disabled when requiresRecentLogin and password empty',
    (tester) async {
      await tester.pumpWidget(
        buildDialog(
          initialState: const SettingsState(
            cleanupRecoveryPending: true,
            requiresRecentLogin: true,
            deleteError: 'Volvé a iniciar sesión para completar la eliminación.',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Finish'),
      );
      expect(button.onPressed, isNull);
    },
  );

  testWidgets(
    'confirm button enabled when requiresRecentLogin and password non-empty',
    (tester) async {
      await tester.pumpWidget(
        buildDialog(
          initialState: const SettingsState(
            cleanupRecoveryPending: true,
            requiresRecentLogin: true,
            deleteError: 'Volvé a iniciar sesión para completar la eliminación.',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('deletePasswordField')),
        'secret123',
      );
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Finish'),
      );
      expect(button.onPressed, isNotNull);
    },
  );

  testWidgets('retry passes password to notifier', (tester) async {
    await tester.pumpWidget(
      buildDialog(
        initialState: const SettingsState(
          cleanupRecoveryPending: true,
          requiresRecentLogin: true,
          deleteError: 'Volvé a iniciar sesión para completar la eliminación.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Enter password and tap Finalizar.
    await tester.enterText(
      find.byKey(const Key('deletePasswordField')),
      'secret123',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Finish'));
    await tester.pumpAndSettle();

    // Cleanup was called with the password.
    verify(
      () => mockCleanup.cleanUpAfterDeletion(password: 'secret123'),
    ).called(1);
  });

  testWidgets('success after retry closes dialog', (tester) async {
    // Simulate prior pending state.
    when(
      () => mockCleanup.cleanUpAfterDeletion(password: any(named: 'password')),
    ).thenAnswer((_) async => null);

    await tester.pumpWidget(
      buildDialog(
        initialState: const SettingsState(
          cleanupRecoveryPending: true,
          deleteError: 'Error durante la limpieza',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Finish'));
    await tester.pumpAndSettle();

    // Dialog closed after success.
    expect(find.byType(DeleteAccountDialog), findsNothing);
  });

  testWidgets('system back does not close dialog during recovery', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildDialogRoute(
        initialState: const SettingsState(
          cleanupRecoveryPending: true,
          deleteError: 'Error durante la limpieza',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('openDeleteDialogButton')));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(DeleteAccountDialog), findsOneWidget);
  });
}
