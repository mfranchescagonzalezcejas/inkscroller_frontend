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

    test('deleteAccount treats backend 404 on retry as already-deleted — '
        'still proceeds to cleanup', () async {
      // First call: backend already deleted (404)
      when(() => repository.deleteAccount()).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Not found', code: 404)),
      );
      when(
        () => mockCleanup.cleanUpAfterDeletion(),
      ).thenAnswer((_) async => null);

      final notifier = SettingsNotifier(
        repository: repository,
        cleanup: mockCleanup,
      );

      await notifier.deleteAccount();

      // 404 treated as "already deleted" → cleanup runs → account marked deleted.
      expect(notifier.state.accountDeleted, true);
      expect(notifier.state.isDeletingAccount, false);
      expect(notifier.state.deleteError, isNull);
      verify(() => mockCleanup.cleanUpAfterDeletion()).called(1);
    });

    test(
      'deleteAccount backend 404 + Firebase Auth delete fails → error',
      () async {
        when(() => repository.deleteAccount()).thenAnswer(
          (_) async =>
              const Left(ServerFailure(message: 'Not found', code: 404)),
        );
        when(
          () => mockCleanup.cleanUpAfterDeletion(),
        ).thenThrow(Exception('Firebase Auth deletion failed'));

        final notifier = SettingsNotifier(
          repository: repository,
          cleanup: mockCleanup,
        );

        await notifier.deleteAccount();

        // Backend 404 → cleanup attempted → Firebase Auth failure → error.
        expect(notifier.state.accountDeleted, false);
        expect(notifier.state.isDeletingAccount, false);
        expect(notifier.state.deleteError, 'Error durante la limpieza');
        verify(() => mockCleanup.cleanUpAfterDeletion()).called(1);
      },
    );

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
