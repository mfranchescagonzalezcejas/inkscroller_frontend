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
      () => mockCleanup.cleanUpAfterDeletion(),
    ).thenAnswer((_) async => null);
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
    });

    test('deleteAccount does not accept later 404 after success', () async {
      when(
        () => repository.deleteAccount(),
      ).thenAnswer((_) async => const Right(null));

      final notifier = SettingsNotifier(
        repository: repository,
        cleanup: mockCleanup,
      );

      await notifier.deleteAccount();

      verify(() => mockCleanup.cleanUpAfterDeletion()).called(1);

      // A later 404 should not be treated as "already deleted".
      when(() => repository.deleteAccount()).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Not found', code: 404)),
      );

      await notifier.deleteAccount();

      expect(notifier.state.accountDeleted, false);
      expect(notifier.state.deleteError, 'Not found');
      verifyNoMoreInteractions(mockCleanup);
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
        verify(() => mockCleanup.cleanUpAfterDeletion()).called(1);
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
      'deleteAccount reports warning when prefs clear fails but marks deleted',
      () async {
        when(
          () => repository.deleteAccount(),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockCleanup.cleanUpAfterDeletion(),
        ).thenAnswer((_) async => 'Prefs clear failed');

        final notifier = SettingsNotifier(
          repository: repository,
          cleanup: mockCleanup,
        );

        await notifier.deleteAccount();

        // Backend succeeded → accountDeleted is true even with prefs warning.
        expect(notifier.state.accountDeleted, true);
        expect(notifier.state.isDeletingAccount, false);
        expect(notifier.state.deleteWarning, 'Prefs clear failed');
        expect(notifier.state.deleteError, isNull);
      },
    );

    test(
      'deleteAccount handles cleanup exception — does NOT mark deleted',
      () async {
        when(
          () => repository.deleteAccount(),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockCleanup.cleanUpAfterDeletion(),
        ).thenThrow(Exception('unexpected'));

        final notifier = SettingsNotifier(
          repository: repository,
          cleanup: mockCleanup,
        );

        await notifier.deleteAccount();

        // Critical cleanup failure → account NOT marked deleted, error shown.
        expect(notifier.state.accountDeleted, false);
        expect(notifier.state.isDeletingAccount, false);
        expect(notifier.state.deleteError, 'Error durante la limpieza');
        expect(notifier.state.deleteWarning, isNull);
      },
    );

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
          () => mockCleanup.cleanUpAfterDeletion(),
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

        // Warning cleared on retry start, error set from failure
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

      // Second call succeeds — error should be cleared
      when(
        () => repository.deleteAccount(),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => mockCleanup.cleanUpAfterDeletion(),
      ).thenAnswer((_) async => null);

      await notifier.deleteAccount();
      expect(notifier.state.deleteError, isNull);
      expect(notifier.state.accountDeleted, true);
    });

    test('deleteAccount first-attempt backend 404 → error, '
        'no cleanup', () async {
      when(() => repository.deleteAccount()).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Not found', code: 404)),
      );

      final notifier = SettingsNotifier(
        repository: repository,
        cleanup: mockCleanup,
      );

      await notifier.deleteAccount();

      // First-attempt 404 with no prior success → error, cleanup NOT called.
      expect(notifier.state.accountDeleted, false);
      expect(notifier.state.isDeletingAccount, false);
      expect(notifier.state.deleteError, 'Not found');
      verifyNever(() => mockCleanup.cleanUpAfterDeletion());
    });

    test('deleteAccount retry after backend success + cleanup failure: '
        '404 → error, no cleanup', () async {
      // Call 1: backend succeeds, cleanup throws.
      when(
        () => repository.deleteAccount(),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => mockCleanup.cleanUpAfterDeletion(),
      ).thenThrow(Exception('Firebase Auth deletion failed'));

      final notifier = SettingsNotifier(
        repository: repository,
        cleanup: mockCleanup,
      );
      await notifier.deleteAccount();

      expect(notifier.state.accountDeleted, false);
      expect(notifier.state.deleteError, 'Error durante la limpieza');
      verify(() => mockCleanup.cleanUpAfterDeletion()).called(1);

      // Call 2: backend returns 404, which must still fail without cleanup.
      when(() => repository.deleteAccount()).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Not found', code: 404)),
      );

      await notifier.deleteAccount();

      expect(notifier.state.accountDeleted, false);
      expect(notifier.state.deleteError, 'Not found');
      // Cleanup only called in call 1 (threw). Not called again.
      verifyNoMoreInteractions(mockCleanup);
    });

    test('deleteAccount after critical cleanup failure: '
        'later 404 does NOT mark success or call cleanup', () async {
      // Call 1: backend succeeds, cleanup throws.
      when(
        () => repository.deleteAccount(),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => mockCleanup.cleanUpAfterDeletion(),
      ).thenThrow(Exception('Firebase Auth deletion failed'));

      final notifier = SettingsNotifier(
        repository: repository,
        cleanup: mockCleanup,
      );
      await notifier.deleteAccount();

      expect(notifier.state.accountDeleted, false);
      expect(notifier.state.deleteError, 'Error durante la limpieza');
      verify(() => mockCleanup.cleanUpAfterDeletion()).called(1);

      // Call 2: backend 404 must not be treated as deletion success.
      when(() => repository.deleteAccount()).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Not found', code: 404)),
      );

      await notifier.deleteAccount();

      // 404 remains a backend failure → error, no cleanup.
      expect(notifier.state.accountDeleted, false);
      expect(notifier.state.deleteError, 'Not found');
      verifyNoMoreInteractions(mockCleanup);
    });

    test('deleteAccount retry after backend success + cleanup failure: '
        'non-404 error → error, no cleanup', () async {
      // Call 1: backend succeeds, cleanup throws.
      when(
        () => repository.deleteAccount(),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => mockCleanup.cleanUpAfterDeletion(),
      ).thenThrow(Exception('Firebase Auth deletion failed'));

      final notifier = SettingsNotifier(
        repository: repository,
        cleanup: mockCleanup,
      );
      await notifier.deleteAccount();

      // Call 2: different server error (not 404).
      // Reset cleanup mock to avoid conflict with setUp stub.
      reset(mockCleanup);
      when(() => repository.deleteAccount()).thenAnswer(
        (_) async =>
            const Left(ServerFailure(message: 'Server error', code: 500)),
      );

      await notifier.deleteAccount();

      // Non-404 → error, cleanup NOT called this time.
      expect(notifier.state.accountDeleted, false);
      expect(notifier.state.deleteError, 'Server error');
      verifyNever(() => mockCleanup.cleanUpAfterDeletion());
    });

    test('deleteAccount reports error when Firebase Auth deletion fails '
        '— does NOT mark deleted', () async {
      when(
        () => repository.deleteAccount(),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => mockCleanup.cleanUpAfterDeletion(),
      ).thenThrow(Exception('Firebase Auth deletion failed'));

      final notifier = SettingsNotifier(
        repository: repository,
        cleanup: mockCleanup,
      );

      await notifier.deleteAccount();

      // Firebase Auth deletion is critical → account NOT marked deleted.
      expect(notifier.state.accountDeleted, false);
      expect(notifier.state.isDeletingAccount, false);
      expect(notifier.state.deleteError, 'Error durante la limpieza');
      expect(notifier.state.deleteWarning, isNull);
    });

    test('non-404 failure with "not found" text does NOT '
        'treat account as already deleted', () async {
      when(() => repository.deleteAccount()).thenAnswer(
        (_) async =>
            const Left(ServerFailure(message: 'Resource not found', code: 500)),
      );

      final notifier = SettingsNotifier(
        repository: repository,
        cleanup: mockCleanup,
      );

      await notifier.deleteAccount();

      // Non-404 with "not found" text → NOT treated as already deleted.
      expect(notifier.state.accountDeleted, false);
      expect(notifier.state.deleteError, 'Resource not found');
      verifyNever(() => mockCleanup.cleanUpAfterDeletion());
    });
  });
}
