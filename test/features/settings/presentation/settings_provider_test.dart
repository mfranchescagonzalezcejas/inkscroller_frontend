import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/settings/domain/repositories/account_cleanup_repository.dart';
import 'package:inkscroller_flutter/features/settings/domain/repositories/settings_repository.dart';
import 'package:inkscroller_flutter/features/settings/presentation/providers/settings_provider.dart';
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
    ).thenAnswer((_) async => {});
  });

  group('SettingsNotifier', () {
    test('initial state has default values', () {
      final notifier = SettingsNotifier(
        repository: repository,
        cleanup: mockCleanup,
      );

      expect(notifier.state.isDeletingAccount, false);
      expect(notifier.state.deleteError, isNull);
      expect(notifier.state.accountDeleted, false);
      expect(notifier.state.cleanupRecoveryPending, false);
      expect(notifier.state.requiresRecentLogin, false);
    });

    test('deleteAccount sets loading then success state', () async {
      when(
        () => repository.deleteAccount(),
      ).thenAnswer((_) async => const Right(null));

      final notifier = SettingsNotifier(
        repository: repository,
        cleanup: mockCleanup,
      );

      await notifier.deleteAccount();

      expect(notifier.state.isDeletingAccount, false);
      expect(notifier.state.accountDeleted, true);
      expect(notifier.state.deleteError, isNull);
      expect(notifier.state.deleteWarning, isNull);
      expect(notifier.state.cleanupRecoveryPending, false);
    });

    test(
      'deleteAccount marks pending then cleans up on backend success',
      () async {
        when(
          () => repository.deleteAccount(),
        ).thenAnswer((_) async => const Right(null));

        final notifier = SettingsNotifier(
          repository: repository,
          cleanup: mockCleanup,
        );

        await notifier.deleteAccount();

        verify(() => mockCleanup.markDeletionCleanupPending()).called(1);
        verify(
          () => mockCleanup.cleanUpAfterDeletion(
            password: any(named: 'password'),
          ),
        ).called(1);
        verify(() => mockCleanup.clearDeletionCleanupPending()).called(1);
        expect(notifier.state.accountDeleted, true);
      },
    );

    test('deleteAccount does not accept later 404 after success', () async {
      when(
        () => repository.deleteAccount(),
      ).thenAnswer((_) async => const Right(null));

      final notifier = SettingsNotifier(
        repository: repository,
        cleanup: mockCleanup,
      );

      await notifier.deleteAccount();

      // A later 404 should not be treated as "already deleted".
      when(() => repository.deleteAccount()).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Not found', code: 404)),
      );

      await notifier.deleteAccount();

      expect(notifier.state.accountDeleted, false);
      expect(notifier.state.deleteError, 'Not found');
      // Backend called again, but cleanup NOT called (backend failed).
      verify(() => repository.deleteAccount()).called(2);
    });

    test(
      'deleteAccount ignores reentrant calls while deletion is in flight',
      () async {
        final deleteCompleter = Completer<Either<Failure, void>>();
        when(
          () => repository.deleteAccount(),
        ).thenAnswer((_) => deleteCompleter.future);

        final notifier = SettingsNotifier(
          repository: repository,
          cleanup: mockCleanup,
        );

        final firstDelete = notifier.deleteAccount();
        await Future<void>.delayed(Duration.zero);

        await notifier.deleteAccount();
        deleteCompleter.complete(const Right(null));
        await firstDelete;

        expect(notifier.state.accountDeleted, true);
        expect(notifier.state.isDeletingAccount, false);
        verify(() => repository.deleteAccount()).called(1);
        verify(
          () => mockCleanup.cleanUpAfterDeletion(
            password: any(named: 'password'),
          ),
        ).called(1);
      },
    );

    test('deleteAccount sets error state on failure', () async {
      when(() => repository.deleteAccount()).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Server error')),
      );

      final notifier = SettingsNotifier(
        repository: repository,
        cleanup: mockCleanup,
      );

      await notifier.deleteAccount();

      expect(notifier.state.isDeletingAccount, false);
      expect(notifier.state.deleteError, 'Server error');
      expect(notifier.state.accountDeleted, false);
    });

    test('deleteAccount sets error state on network failure', () async {
      when(() => repository.deleteAccount()).thenAnswer(
        (_) async => const Left(NetworkFailure(message: 'No connection')),
      );

      final notifier = SettingsNotifier(
        repository: repository,
        cleanup: mockCleanup,
      );

      await notifier.deleteAccount();

      expect(notifier.state.isDeletingAccount, false);
      expect(notifier.state.deleteError, 'No connection');
    });

    test('resetState clears deleteError', () async {
      when(() => repository.deleteAccount()).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Server error')),
      );

      final notifier = SettingsNotifier(
        repository: repository,
        cleanup: mockCleanup,
      );

      await notifier.deleteAccount();
      expect(notifier.state.deleteError, 'Server error');

      notifier.resetState();
      expect(notifier.state.deleteError, isNull);
    });

    test(
      'resetState keeps recent-login recovery flag while cleanup pending',
      () {
        final notifier = SettingsNotifier(
          repository: repository,
          cleanup: mockCleanup,
        );

        notifier.state = notifier.state.copyWith(
          cleanupRecoveryPending: true,
          requiresRecentLogin: true,
          deleteError: 'Volvé a iniciar sesión para completar la eliminación.',
        );

        notifier.resetState();

        expect(notifier.state.deleteError, isNull);
        expect(notifier.state.cleanupRecoveryPending, true);
        expect(notifier.state.requiresRecentLogin, true);
      },
    );

    test(
      'deleteAccount reports warning when prefs clear fails but marks deleted',
      () async {
        when(
          () => repository.deleteAccount(),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockCleanup.cleanUpAfterDeletion(
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => 'Prefs clear failed');

        final notifier = SettingsNotifier(
          repository: repository,
          cleanup: mockCleanup,
        );

        await notifier.deleteAccount();

        expect(notifier.state.accountDeleted, true);
        expect(notifier.state.isDeletingAccount, false);
        expect(notifier.state.deleteWarning, 'Prefs clear failed');
        expect(notifier.state.deleteError, isNull);
      },
    );

    test(
      'deleteAccount handles cleanup exception — sets pending and error',
      () async {
        when(
          () => repository.deleteAccount(),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockCleanup.cleanUpAfterDeletion(
            password: any(named: 'password'),
          ),
        ).thenThrow(Exception('unexpected'));

        final notifier = SettingsNotifier(
          repository: repository,
          cleanup: mockCleanup,
        );

        await notifier.deleteAccount();

        expect(notifier.state.accountDeleted, false);
        expect(notifier.state.isDeletingAccount, false);
        expect(notifier.state.cleanupRecoveryPending, true);
        expect(notifier.state.deleteError, 'Error durante la limpieza');
        expect(notifier.state.deleteWarning, isNull);
      },
    );

    test('deleteAccount handles AccountCleanupException — preserves pending '
        'and sets requiresRecentLogin', () async {
      when(
        () => repository.deleteAccount(),
      ).thenAnswer((_) async => const Right(null));
      when(
        () =>
            mockCleanup.cleanUpAfterDeletion(password: any(named: 'password')),
      ).thenThrow(
        const AccountCleanupException(
          message: 'Volvé a iniciar sesión para completar la eliminación.',
          requiresRecentLogin: true,
        ),
      );

      final notifier = SettingsNotifier(
        repository: repository,
        cleanup: mockCleanup,
      );

      await notifier.deleteAccount();

      expect(notifier.state.accountDeleted, false);
      expect(notifier.state.isDeletingAccount, false);
      expect(notifier.state.cleanupRecoveryPending, true);
      expect(notifier.state.requiresRecentLogin, true);
      expect(
        notifier.state.deleteError,
        'Volvé a iniciar sesión para completar la eliminación.',
      );
    });

    test(
      'deleteAccount clears stale deleteError on retry after success',
      () async {
        // First call: backend failure
        when(() => repository.deleteAccount()).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Server error')),
        );

        final notifier = SettingsNotifier(
          repository: repository,
          cleanup: mockCleanup,
        );
        await notifier.deleteAccount();
        expect(notifier.state.deleteError, isNotNull);
        expect(notifier.state.accountDeleted, false);

        // Second call: backend success, cleanup warning
        when(
          () => repository.deleteAccount(),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockCleanup.cleanUpAfterDeletion(
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => 'Warning');

        await notifier.deleteAccount();
        expect(notifier.state.deleteError, isNull);
        expect(notifier.state.accountDeleted, true);
        expect(notifier.state.deleteWarning, 'Warning');
      },
    );

    test(
      'deleteAccount clears stale deleteWarning when retrying after backend failure',
      () async {
        when(() => repository.deleteAccount()).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Server error')),
        );

        final notifier = SettingsNotifier(
          repository: repository,
          cleanup: mockCleanup,
        );
        // Manually set a stale warning to simulate prior state
        notifier.state = notifier.state.copyWith(
          deleteWarning: 'stale warning',
        );
        await notifier.deleteAccount();

        expect(notifier.state.deleteWarning, isNull);
        expect(notifier.state.deleteError, 'Server error');
      },
    );

    test('deleteAccount clears previous error on retry', () async {
      // First call fails
      when(() => repository.deleteAccount()).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Server error')),
      );

      final notifier = SettingsNotifier(
        repository: repository,
        cleanup: mockCleanup,
      );
      await notifier.deleteAccount();
      expect(notifier.state.deleteError, 'Server error');

      // Second call succeeds
      when(
        () => repository.deleteAccount(),
      ).thenAnswer((_) async => const Right(null));
      when(
        () =>
            mockCleanup.cleanUpAfterDeletion(password: any(named: 'password')),
      ).thenAnswer((_) async => null);

      await notifier.deleteAccount();
      expect(notifier.state.deleteError, isNull);
      expect(notifier.state.accountDeleted, true);
    });

    test(
      'deleteAccount first-attempt backend 404 → error, no cleanup',
      () async {
        when(() => repository.deleteAccount()).thenAnswer(
          (_) async =>
              const Left(ServerFailure(message: 'Not found', code: 404)),
        );

        final notifier = SettingsNotifier(
          repository: repository,
          cleanup: mockCleanup,
        );

        await notifier.deleteAccount();

        expect(notifier.state.accountDeleted, false);
        expect(notifier.state.isDeletingAccount, false);
        expect(notifier.state.deleteError, 'Not found');
        verifyNever(
          () => mockCleanup.cleanUpAfterDeletion(
            password: any(named: 'password'),
          ),
        );
      },
    );

    test(
      'deleteAccount retry skips backend when pending from prior cleanup failure',
      () async {
        // Call 1: backend succeeds, cleanup throws.
        when(
          () => repository.deleteAccount(),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockCleanup.cleanUpAfterDeletion(
            password: any(named: 'password'),
          ),
        ).thenThrow(Exception('Firebase Auth deletion failed'));

        final notifier = SettingsNotifier(
          repository: repository,
          cleanup: mockCleanup,
        );
        await notifier.deleteAccount();

        expect(notifier.state.accountDeleted, false);
        expect(notifier.state.cleanupRecoveryPending, true);
        verify(() => repository.deleteAccount()).called(1);

        // Call 2: should skip backend, go straight to cleanup.
        when(
          () => mockCleanup.hasDeletionCleanupPending(),
        ).thenAnswer((_) async => true);
        when(
          () => mockCleanup.cleanUpAfterDeletion(
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => null);

        await notifier.deleteAccount(password: 'newpass');

        // Backend NOT called again.
        verifyNoMoreInteractions(repository);
        verify(
          () => mockCleanup.cleanUpAfterDeletion(password: 'newpass'),
        ).called(1);
        expect(notifier.state.accountDeleted, true);
        expect(notifier.state.cleanupRecoveryPending, false);
      },
    );

    test(
      'deleteAccount stale in-memory pending does not skip backend without scoped marker',
      () async {
        final notifier = SettingsNotifier(
          repository: repository,
          cleanup: mockCleanup,
        );
        notifier.state = const SettingsState(cleanupRecoveryPending: true);
        when(() => repository.deleteAccount()).thenAnswer(
          (_) async =>
              const Left(ServerFailure(message: 'Not found', code: 404)),
        );

        await notifier.deleteAccount();

        verify(() => repository.deleteAccount()).called(1);
        verifyNever(
          () => mockCleanup.cleanUpAfterDeletion(
            password: any(named: 'password'),
          ),
        );
        expect(notifier.state.cleanupRecoveryPending, true);
        expect(notifier.state.deleteError, 'Not found');
      },
    );

    test(
      'deleteAccount retry with hasDeletionCleanupPending skips backend',
      () async {
        when(
          () => mockCleanup.hasDeletionCleanupPending(),
        ).thenAnswer((_) async => true);

        final notifier = SettingsNotifier(
          repository: repository,
          cleanup: mockCleanup,
        );

        await notifier.deleteAccount(password: 'pass');

        // Backend NOT called — pending flag was already true.
        verifyNever(() => repository.deleteAccount());
        verify(
          () => mockCleanup.cleanUpAfterDeletion(password: 'pass'),
        ).called(1);
        expect(notifier.state.accountDeleted, true);
      },
    );

    test(
      'deleteAccount retry success clears pending and accountDeleted true',
      () async {
        // Simulate a prior failure that left pending state.
        final notifier = SettingsNotifier(
          repository: repository,
          cleanup: mockCleanup,
        );
        notifier.state = const SettingsState(
          cleanupRecoveryPending: true,
          deleteError: 'Error durante la limpieza',
        );

        when(
          () => mockCleanup.hasDeletionCleanupPending(),
        ).thenAnswer((_) async => true);

        when(
          () => mockCleanup.cleanUpAfterDeletion(
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => null);

        await notifier.deleteAccount(password: 'pass');

        expect(notifier.state.accountDeleted, true);
        expect(notifier.state.cleanupRecoveryPending, false);
        expect(notifier.state.deleteError, isNull);
        expect(notifier.state.isDeletingAccount, false);
      },
    );

    test(
      'deleteAccount proceeds when markDeletionCleanupPending throws',
      () async {
        when(
          () => repository.deleteAccount(),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockCleanup.markDeletionCleanupPending(),
        ).thenThrow(Exception('storage full'));

        final notifier = SettingsNotifier(
          repository: repository,
          cleanup: mockCleanup,
        );

        await notifier.deleteAccount(password: 'pw');

        // cleanUpAfterDeletion still called despite marker failure.
        verify(
          () => mockCleanup.cleanUpAfterDeletion(password: 'pw'),
        ).called(1);
        verify(() => mockCleanup.clearDeletionCleanupPending()).called(1);
        expect(notifier.state.accountDeleted, true);
        expect(notifier.state.deleteError, isNull);
      },
    );

    test('deleteAccount retry fail remains pending', () async {
      final notifier = SettingsNotifier(
        repository: repository,
        cleanup: mockCleanup,
      );
      notifier.state = const SettingsState(cleanupRecoveryPending: true);

      when(
        () => mockCleanup.hasDeletionCleanupPending(),
      ).thenAnswer((_) async => true);

      when(
        () =>
            mockCleanup.cleanUpAfterDeletion(password: any(named: 'password')),
      ).thenThrow(Exception('still failing'));

      await notifier.deleteAccount();

      expect(notifier.state.accountDeleted, false);
      expect(notifier.state.cleanupRecoveryPending, true);
      expect(notifier.state.isDeletingAccount, false);
    });
  });
}
