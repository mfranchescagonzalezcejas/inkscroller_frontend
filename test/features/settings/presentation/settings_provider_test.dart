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

/// SharedPreferences mock where [clear] returns false.
class _FailingPrefs implements SharedPreferences {
  @override
  Future<bool> clear() async => false;

  // Stub remaining members — unused by delete flow.
  @override
  Set<String> getKeys() => <String>{};
  @override
  Object? get(String key) => null;
  @override
  bool? getBool(String key) => null;
  @override
  int? getInt(String key) => null;
  @override
  double? getDouble(String key) => null;
  @override
  String? getString(String key) => null;
  @override
  List<String>? getStringList(String key) => null;
  @override
  Future<bool> setBool(String key, bool value) async => true;
  @override
  Future<bool> setInt(String key, int value) async => true;
  @override
  Future<bool> setDouble(String key, double value) async => true;
  @override
  Future<bool> setString(String key, String value) async => true;
  @override
  Future<bool> setStringList(String key, List<String> value) async => true;
  @override
  Future<bool> remove(String key) async => true;
  @override
  Future<void> reload() async {}
  @override
  bool containsKey(String key) => false;
  @override
  Future<bool> commit() async => true;
}

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
      'deleteAccount succeeds when user.delete() throws — local cleanup still runs',
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

        // Backend deletion succeeded → account is deleted locally.
        // Firebase user.delete() failure is a warning, not a blocker.
        expect(notifier.state.accountDeleted, true);
        expect(notifier.state.isDeletingAccount, false);
        expect(notifier.state.deleteError, isNull);
        expect(notifier.state.deleteWarning, isNotNull);

        // Local cleanup must have run despite Firebase failure.
        verify(() => mockAuth.signOut()).called(1);
      },
    );

    test(
      'deleteAccount handles signOut() failure after backend success',
      () async {
        when(() => repository.deleteAccount())
            .thenAnswer((_) async => const Right(null));
        when(() => mockAuth.currentUser).thenReturn(null);
        when(() => mockAuth.signOut()).thenThrow(
          Exception('Sign out failed'),
        );

        final notifier = SettingsNotifier(
          repository: repository,
          firebaseAuth: mockAuth,
        );

        await notifier.deleteAccount();

        // signOut() threw → local cleanup failed.
        // isDeletingAccount must not be stuck, error reported.
        expect(notifier.state.isDeletingAccount, false);
        expect(notifier.state.accountDeleted, false);
        expect(notifier.state.deleteError, isNotNull);
        expect(
          notifier.state.deleteError,
          contains('Local cleanup failed'),
        );
      },
    );

    test(
      'deleteAccount clears stale deleteWarning on retry after success',
      () async {
        // First call: backend success + Firebase warning
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
        expect(notifier.state.deleteWarning, isNotNull);
        expect(notifier.state.accountDeleted, true);

        // Second call: backend success, no Firebase user → warning should clear
        when(() => repository.deleteAccount())
            .thenAnswer((_) async => const Right(null));
        when(() => mockAuth.currentUser).thenReturn(null);

        await notifier.deleteAccount();
        expect(notifier.state.deleteWarning, isNull);
        expect(notifier.state.accountDeleted, true);
      },
    );

    test(
      'deleteAccount clears stale deleteWarning when retrying after backend failure',
      () async {
        // First call fails with warning state from prior success
        when(() => repository.deleteAccount()).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Server error')),
        );

        final notifier = SettingsNotifier(
          repository: repository,
          firebaseAuth: mockAuth,
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

    test(
      'deleteAccount reports failure when prefs.clear() returns false',
      () async {
        when(() => repository.deleteAccount())
            .thenAnswer((_) async => const Right(null));
        when(() => mockAuth.currentUser).thenReturn(null);
        when(() => mockAuth.signOut()).thenAnswer((_) async {});

        final notifier = SettingsNotifier(
          repository: repository,
          firebaseAuth: mockAuth,
        );

        // Replace the registered SharedPreferences with a mock that fails
        if (GetIt.I.isRegistered<SharedPreferences>()) {
          await GetIt.I.unregister<SharedPreferences>();
        }
        sl.registerLazySingleton<SharedPreferences>(
          () => _FailingPrefs(),
        );

        await notifier.deleteAccount();

        expect(notifier.state.isDeletingAccount, false);
        expect(notifier.state.accountDeleted, false);
        expect(notifier.state.deleteError, isNotNull);
        expect(
          notifier.state.deleteError,
          contains('Local cleanup failed'),
        );
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
