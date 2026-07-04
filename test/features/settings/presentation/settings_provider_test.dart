import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga_reading_progress.dart';
import 'package:inkscroller_flutter/features/library/domain/repositories/reading_progress_repository.dart';
import 'package:inkscroller_flutter/features/library/presentation/providers/reading_progress_provider.dart';
import 'package:inkscroller_flutter/features/profile/domain/usecases/get_user_profile.dart';
import 'package:inkscroller_flutter/features/profile/presentation/providers/user_profile_notifier.dart';
import 'package:inkscroller_flutter/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:inkscroller_flutter/features/settings/domain/repositories/account_cleanup_repository.dart';
import 'package:inkscroller_flutter/features/settings/domain/repositories/settings_repository.dart';
import 'package:inkscroller_flutter/features/settings/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

class _MockAccountCleanupRepository extends Mock
    implements AccountCleanupRepository {}

/// Tracks which providers were invalidated during a test.
class _TrackingObserver extends ProviderObserver {
  final List<ProviderBase<Object?>> invalidated;
  _TrackingObserver(this.invalidated);

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    invalidated.add(provider);
  }
}

class _MockReadingProgressRepo extends Mock
    implements ReadingProgressRepository {}

class _MockGetUserProfile extends Mock implements GetUserProfile {}

void main() {
  late SettingsRepository repository;
  late _MockAccountCleanupRepository mockCleanup;

  setUp(() {
    repository = _MockSettingsRepository();
    mockCleanup = _MockAccountCleanupRepository();
    when(() => mockCleanup.currentCleanupUserId).thenReturn('uid-1');
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

    test('deleteAccount calls backend again after full success', () async {
      when(
        () => repository.deleteAccount(),
      ).thenAnswer((_) async => const Right(null));

      final notifier = SettingsNotifier(
        repository: repository,
        cleanup: mockCleanup,
      );

      await notifier.deleteAccount();

      // Second attempt: backend was already cleaned up successfully,
      // but the in-memory flag resets after cleanup — so backend must
      // be called again. A 404 here is a real error, not stale state.
      when(() => repository.deleteAccount()).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Not found', code: 404)),
      );

      await notifier.deleteAccount();

      // Backend WAS called again — flag was reset after first success.
      expect(notifier.state.accountDeleted, false);
      expect(notifier.state.deleteError, 'Not found');
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

    test(
      'deleteAccount marker write failure + cleanup failure — '
      'retry skips backend via in-memory flag',
      () async {
        // Call 1: backend succeeds, marker write throws, cleanup throws.
        when(
          () => repository.deleteAccount(),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockCleanup.markDeletionCleanupPending(),
        ).thenThrow(Exception('storage full'));
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

        // Call 2: same UID — retry should skip backend (in-memory flag)
        // even though hasDeletionCleanupPending returns false (marker was
        // never written to storage).
        when(
          () => mockCleanup.hasDeletionCleanupPending(),
        ).thenAnswer((_) async => false);
        when(
          () => mockCleanup.cleanUpAfterDeletion(
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => null);

        await notifier.deleteAccount(password: 'newpass');

        // Backend NOT called again — in-memory flag preserved the signal.
        verifyNoMoreInteractions(repository);
        verify(
          () => mockCleanup.cleanUpAfterDeletion(password: 'newpass'),
        ).called(1);
        expect(notifier.state.accountDeleted, true);
        expect(notifier.state.cleanupRecoveryPending, false);
      },
    );

    test(
      'deleteAccount marker write failure + cleanup failure then UID changes — '
      'retry calls backend again (no cross-user skip)',
      () async {
        when(
          () => repository.deleteAccount(),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockCleanup.markDeletionCleanupPending(),
        ).thenThrow(Exception('storage full'));
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

        expect(notifier.state.cleanupRecoveryPending, true);

        // UID changes (different user logged in, or session recycled).
        when(() => mockCleanup.currentCleanupUserId).thenReturn('uid-2');
        when(
          () => mockCleanup.hasDeletionCleanupPending(),
        ).thenAnswer((_) async => false);
        when(
          () => mockCleanup.cleanUpAfterDeletion(
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => null);

        await notifier.deleteAccount();

        // Backend MUST be called — in-memory flag was for uid-1, not uid-2.
        verify(() => repository.deleteAccount()).called(2);
        expect(notifier.state.accountDeleted, true);
      },
    );

    test(
      'deleteAccount calls onAccountDeleted before publishing success',
      () async {
        when(
          () => repository.deleteAccount(),
        ).thenAnswer((_) async => const Right(null));

        // Capture state at callback time via a holder that the callback writes to.
        bool? accountDeletedAtCallback;
        late SettingsNotifier notifier;
        notifier = SettingsNotifier(
          repository: repository,
          cleanup: mockCleanup,
          onAccountDeleted: () {
            accountDeletedAtCallback = notifier.state.accountDeleted;
          },
        );

        await notifier.deleteAccount();

        // Proves the callback fires BEFORE accountDeleted is set to true.
        expect(accountDeletedAtCallback, false);
        expect(notifier.state.accountDeleted, true);
      },
    );

    test(
      'ProviderContainer: deleteAccount invalidates readingProgress and userProfile',
      () async {
        when(
          () => repository.deleteAccount(),
        ).thenAnswer((_) async => const Right(null));

        final invalidated = <ProviderBase<Object?>>[];
        final observer = _TrackingObserver(invalidated);

        // Stub mocks so the fakes' constructors succeed.
        final mockReadingRepo = _MockReadingProgressRepo();
        when(() => mockReadingRepo.getAll())
            .thenAnswer((_) async => const <String, MangaReadingProgress>{});
        final mockGetProfile = _MockGetUserProfile();
        when(() => mockGetProfile()).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'stub')),
        );

        final container = ProviderContainer(
          overrides: <Override>[
            settingsRepositoryProvider.overrideWithValue(repository),
            accountCleanupRepositoryProvider.overrideWithValue(mockCleanup),
            readingProgressProvider.overrideWith(
              (ref) => ReadingProgressNotifier(mockReadingRepo),
            ),
            userProfileProvider.overrideWith(
              (ref) => UserProfileNotifier(getUserProfile: mockGetProfile),
            ),
          ],
          observers: <ProviderObserver>[observer],
        );
        addTearDown(container.dispose);

        // Read providers to initialize their state so invalidation disposes them.
        container.read(readingProgressProvider);
        container.read(userProfileProvider);

        // Trigger deletion through the real settingsProvider wiring.
        await container.read(settingsProvider.notifier).deleteAccount();

        expect(container.read(settingsProvider).accountDeleted, true);
        expect(
          invalidated,
          containsAll([
            readingProgressProvider,
            userProfileProvider,
          ]),
        );
      },
    );

    test(
      'deleteAccount succeeds when clearDeletionCleanupPending throws',
      () async {
        when(
          () => repository.deleteAccount(),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockCleanup.clearDeletionCleanupPending(),
        ).thenThrow(Exception('storage gone'));

        final notifier = SettingsNotifier(
          repository: repository,
          cleanup: mockCleanup,
        );

        await notifier.deleteAccount();

        expect(notifier.state.accountDeleted, true);
        expect(notifier.state.isDeletingAccount, false);
        expect(notifier.state.deleteError, isNull);
      },
    );
  });
}
