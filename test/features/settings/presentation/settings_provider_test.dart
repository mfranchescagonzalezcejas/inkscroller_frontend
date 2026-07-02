import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:inkscroller_flutter/core/di/injection.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/settings/domain/repositories/settings_repository.dart';
import 'package:inkscroller_flutter/features/settings/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

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
  });

  tearDown(() async {
    if (GetIt.I.isRegistered<SharedPreferences>()) {
      await GetIt.I.unregister<SharedPreferences>();
    }
  });

  group('SettingsNotifier', () {
    test('initial state has default values', () {
      final notifier = SettingsNotifier(
        repository: repository,
        firebaseAuth: mockAuth,
      );

      expect(notifier.state.isDeletingAccount, false);
      expect(notifier.state.deleteError, isNull);
      expect(notifier.state.accountDeleted, false);
    });

    test('deleteAccount sets loading then success state', () async {
      when(() => repository.deleteAccount())
          .thenAnswer((_) async => const Right(null));
      when(() => mockAuth.currentUser).thenReturn(null);
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      final notifier = SettingsNotifier(
        repository: repository,
        firebaseAuth: mockAuth,
      );

      await notifier.deleteAccount();

      expect(notifier.state.isDeletingAccount, false);
      expect(notifier.state.accountDeleted, true);
      expect(notifier.state.deleteError, isNull);
    });

    test('deleteAccount sets error state on failure', () async {
      when(() => repository.deleteAccount()).thenAnswer(
        (_) async => const Left(
          ServerFailure(message: 'Server error'),
        ),
      );

      final notifier = SettingsNotifier(
        repository: repository,
        firebaseAuth: mockAuth,
      );

      await notifier.deleteAccount();

      expect(notifier.state.isDeletingAccount, false);
      expect(notifier.state.deleteError, 'Server error');
      expect(notifier.state.accountDeleted, false);
    });

    test('deleteAccount sets error state on network failure', () async {
      when(() => repository.deleteAccount()).thenAnswer(
        (_) async => const Left(
          NetworkFailure(message: 'No connection'),
        ),
      );

      final notifier = SettingsNotifier(
        repository: repository,
        firebaseAuth: mockAuth,
      );

      await notifier.deleteAccount();

      expect(notifier.state.isDeletingAccount, false);
      expect(notifier.state.deleteError, 'No connection');
    });

    test('resetState clears deleteError', () async {
      when(() => repository.deleteAccount()).thenAnswer(
        (_) async => const Left(
          ServerFailure(message: 'Server error'),
        ),
      );

      final notifier = SettingsNotifier(
        repository: repository,
        firebaseAuth: mockAuth,
      );

      await notifier.deleteAccount();
      expect(notifier.state.deleteError, 'Server error');

      notifier.resetState();
      expect(notifier.state.deleteError, isNull);
    });

    test(
      'deleteAccount reports failure when user.delete() throws',
      () async {
        when(() => repository.deleteAccount())
            .thenAnswer((_) async => const Right(null));
        final mockUser = _MockUser();
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.delete()).thenThrow(
          Exception('Firebase token expired'),
        );
        when(() => mockAuth.signOut()).thenAnswer((_) async {});

        final notifier = SettingsNotifier(
          repository: repository,
          firebaseAuth: mockAuth,
        );

        await notifier.deleteAccount();

        // Backend deletion succeeded, but Firebase cleanup failed.
        // Account must NOT be marked as deleted.
        expect(notifier.state.accountDeleted, false);
        expect(notifier.state.isDeletingAccount, false);
        expect(notifier.state.deleteError, isNotNull);
      },
    );

    test('deleteAccount clears previous error on retry', () async {
      // First call fails
      when(() => repository.deleteAccount()).thenAnswer(
        (_) async => const Left(
          ServerFailure(message: 'Server error'),
        ),
      );

      final notifier = SettingsNotifier(
        repository: repository,
        firebaseAuth: mockAuth,
      );
      await notifier.deleteAccount();
      expect(notifier.state.deleteError, 'Server error');

      // Second call succeeds — error should be cleared
      when(() => repository.deleteAccount())
          .thenAnswer((_) async => const Right(null));
      when(() => mockAuth.currentUser).thenReturn(null);
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      await notifier.deleteAccount();
      expect(notifier.state.deleteError, isNull);
      expect(notifier.state.accountDeleted, true);
    });
  });
}
