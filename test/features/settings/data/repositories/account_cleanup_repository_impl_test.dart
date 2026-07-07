import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/settings/data/repositories/account_cleanup_repository_impl.dart';
import 'package:inkscroller_flutter/features/settings/domain/repositories/account_cleanup_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _MockUserCredential extends Mock implements UserCredential {}

class _MockPrefs extends Mock implements SharedPreferences {}

class _FakeAuthCredential extends Fake implements AuthCredential {}

/// Minimal stateful SharedPreferences fake for crash-window tests.
class _StatefulPrefs implements SharedPreferences {
  final Map<String, Object?> store;
  final void Function(String key, {required bool value})? onSetBool;

  _StatefulPrefs({required this.store, this.onSetBool});

  @override
  Future<bool> setBool(String key, bool value) async {
    onSetBool?.call(key, value: value);
    store[key] = value;
    return true;
  }

  @override
  bool? getBool(String key) => store[key] as bool?;

  @override
  Future<bool> setString(String key, String value) async {
    store[key] = value;
    return true;
  }

  @override
  String? getString(String key) => store[key] as String?;

  @override
  Future<bool> remove(String key) async {
    store.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    store.clear();
    return true;
  }

  // Unused members — throw to catch accidental usage.
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(_FakeAuthCredential());
  });

  late _MockFirebaseAuth mockAuth;
  late _MockUser mockUser;
  late _MockPrefs mockPrefs;
  late AccountCleanupRepositoryImpl repository;

  setUp(() {
    mockAuth = _MockFirebaseAuth();
    mockUser = _MockUser();
    mockPrefs = _MockPrefs();
    repository = AccountCleanupRepositoryImpl(
      firebaseAuth: mockAuth,
      prefs: mockPrefs,
    );

    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockAuth.signOut()).thenAnswer((_) async {});
    when(() => mockUser.email).thenReturn('test@example.com');
    when(() => mockUser.uid).thenReturn('firebase-user-1');
  });

  group('cleanUpAfterDeletion', () {
    test(
      'success: delete + clear + signOut returns null and calls signOut',
      () async {
        when(() => mockUser.delete()).thenAnswer((_) async {});
        when(() => mockPrefs.clear()).thenAnswer((_) async => true);

        final result = await repository.cleanUpAfterDeletion();

        expect(result, isNull);
        verify(() => mockUser.delete()).called(1);
        verify(() => mockPrefs.clear()).called(1);
        verify(() => mockAuth.signOut()).called(1);
      },
    );

    test('user.delete fails with generic error: does NOT sign out, '
        'throws AccountCleanupException', () async {
      when(() => mockUser.delete()).thenAnswer(
        (_) async => throw FirebaseAuthException(
          code: 'quota-exceeded',
          message: 'Project quota exceeded.',
        ),
      );
      when(() => mockPrefs.clear()).thenAnswer((_) async => true);

      await expectLater(
        repository.cleanUpAfterDeletion(),
        throwsA(
          isA<AccountCleanupException>()
              .having(
                (e) => e.requiresRecentLogin,
                'requiresRecentLogin',
                false,
              )
              .having(
                (e) => e.message,
                'message',
                'No pudimos eliminar tu cuenta de Firebase. Intentá de nuevo.',
              ),
        ),
      );
      verifyNever(() => mockAuth.signOut());
      verifyNever(() => mockPrefs.clear());
    });

    test(
      'requires-recent-login on delete: throws typed exception, no signout',
      () async {
        when(() => mockUser.delete()).thenAnswer(
          (_) async => throw FirebaseAuthException(
            code: 'requires-recent-login',
            message: 'Recent login required.',
          ),
        );
        when(() => mockPrefs.clear()).thenAnswer((_) async => true);

        await expectLater(
          repository.cleanUpAfterDeletion(),
          throwsA(
            isA<AccountCleanupException>()
                .having(
                  (e) => e.requiresRecentLogin,
                  'requiresRecentLogin',
                  true,
                )
                .having(
                  (e) => e.message,
                  'message',
                  'Volvé a iniciar sesión para completar la eliminación.',
                ),
          ),
        );
        verifyNever(() => mockAuth.signOut());
        verifyNever(() => mockPrefs.clear());
      },
    );

    test(
      'requires-recent-login on reauth: throws typed exception, no signout',
      () async {
        when(() => mockUser.reauthenticateWithCredential(any())).thenAnswer(
          (_) async => throw FirebaseAuthException(
            code: 'requires-recent-login',
            message: 'Recent login required.',
          ),
        );
        when(() => mockPrefs.clear()).thenAnswer((_) async => true);

        await expectLater(
          repository.cleanUpAfterDeletion(password: 'password123'),
          throwsA(
            isA<AccountCleanupException>().having(
              (e) => e.requiresRecentLogin,
              'requiresRecentLogin',
              true,
            ),
          ),
        );
        verifyNever(() => mockAuth.signOut());
        verifyNever(() => mockPrefs.clear());
      },
    );

    test('password provided: reauthenticate then delete and signout', () async {
      when(
        () => mockUser.reauthenticateWithCredential(any()),
      ).thenAnswer((_) async => _MockUserCredential());
      when(() => mockUser.delete()).thenAnswer((_) async {});
      when(() => mockPrefs.clear()).thenAnswer((_) async => true);

      final result = await repository.cleanUpAfterDeletion(
        password: 'password123',
      );

      expect(result, isNull);
      verify(
        () => mockUser.reauthenticateWithCredential(
          any(that: isA<AuthCredential>()),
        ),
      ).called(1);
      verify(() => mockUser.delete()).called(1);
      verify(() => mockAuth.signOut()).called(1);
    });

    test(
      'prefs.clear returns false: signs out, returns prefs warning',
      () async {
        when(() => mockUser.delete()).thenAnswer((_) async {});
        when(() => mockPrefs.clear()).thenAnswer((_) async => false);

        final result = await repository.cleanUpAfterDeletion();

        expect(result, 'Prefs clear failed');
        verify(() => mockAuth.signOut()).called(1);
      },
    );

    test('user-not-found is treated as success and signs out', () async {
      when(() => mockUser.delete()).thenAnswer(
        (_) async => throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'The user account has been deleted.',
        ),
      );
      when(() => mockPrefs.clear()).thenAnswer((_) async => true);

      final result = await repository.cleanUpAfterDeletion();

      expect(result, isNull);
      verify(() => mockUser.delete()).called(1);
      verify(() => mockAuth.signOut()).called(1);
    });

    test('no current user: signs out', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      when(() => mockPrefs.clear()).thenAnswer((_) async => true);

      final result = await repository.cleanUpAfterDeletion();

      expect(result, isNull);
      verify(() => mockAuth.signOut()).called(1);
    });
  });

  group('pending marker methods', () {
    test('hasDeletionCleanupPending returns false by default', () async {
      when(() => mockPrefs.getBool(any())).thenReturn(null);

      expect(await repository.hasDeletionCleanupPending(), false);
    });

    test('markDeletionCleanupPending sets the flag', () async {
      when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);
      when(
        () => mockPrefs.setString(any(), any()),
      ).thenAnswer((_) async => true);

      await repository.markDeletionCleanupPending();

      verify(
        () => mockPrefs.setBool('settings.accountDeletionCleanupPending', true),
      ).called(1);
      verify(
        () => mockPrefs.setString(
          'settings.accountDeletionCleanupPendingUid',
          'firebase-user-1',
        ),
      ).called(1);
    });

    test('hasDeletionCleanupPending returns true after marking', () async {
      when(
        () => mockPrefs.getBool('settings.accountDeletionCleanupPending'),
      ).thenReturn(true);
      when(
        () => mockPrefs.getString('settings.accountDeletionCleanupPendingUid'),
      ).thenReturn('firebase-user-1');

      expect(await repository.hasDeletionCleanupPending(), true);
    });

    test(
      'hasDeletionCleanupPending returns false for another Firebase user',
      () async {
        when(
          () => mockPrefs.getBool('settings.accountDeletionCleanupPending'),
        ).thenReturn(true);
        when(
          () =>
              mockPrefs.getString('settings.accountDeletionCleanupPendingUid'),
        ).thenReturn('firebase-user-1');
        when(() => mockUser.uid).thenReturn('firebase-user-2');

        expect(await repository.hasDeletionCleanupPending(), false);
      },
    );

    test(
      'hasDeletionCleanupPending returns false when pending uid is missing',
      () async {
        when(
          () => mockPrefs.getBool('settings.accountDeletionCleanupPending'),
        ).thenReturn(true);
        when(
          () =>
              mockPrefs.getString('settings.accountDeletionCleanupPendingUid'),
        ).thenReturn(null);

        expect(await repository.hasDeletionCleanupPending(), false);
      },
    );

    test('clearDeletionCleanupPending removes the flag', () async {
      when(() => mockPrefs.remove(any())).thenAnswer((_) async => true);

      await repository.clearDeletionCleanupPending();

      verify(
        () => mockPrefs.remove('settings.accountDeletionCleanupPending'),
      ).called(1);
      verify(
        () => mockPrefs.remove('settings.accountDeletionCleanupPendingUid'),
      ).called(1);
    });

    test(
      'hasDeletionCleanupPending returns true for UID-only marker with same UID',
      () async {
        when(
          () =>
              mockPrefs.getString('settings.accountDeletionCleanupPendingUid'),
        ).thenReturn('firebase-user-1');
        when(
          () => mockPrefs.getBool('settings.accountDeletionCleanupPending'),
        ).thenReturn(null);

        expect(await repository.hasDeletionCleanupPending(), true);
      },
    );

    test(
      'hasDeletionCleanupPending returns false for UID-only marker with different UID',
      () async {
        when(
          () =>
              mockPrefs.getString('settings.accountDeletionCleanupPendingUid'),
        ).thenReturn('firebase-user-1');
        when(() => mockUser.uid).thenReturn('firebase-user-2');

        expect(await repository.hasDeletionCleanupPending(), false);
      },
    );

    test(
      'hasDeletionCleanupPending returns false for UID-only marker with no current user',
      () async {
        when(() => mockAuth.currentUser).thenReturn(null);
        when(
          () =>
              mockPrefs.getString('settings.accountDeletionCleanupPendingUid'),
        ).thenReturn('firebase-user-1');

        expect(await repository.hasDeletionCleanupPending(), false);
      },
    );

    test('markDeletionCleanupPending writes UID before pending bool', () async {
      final callOrder = <String>[];
      when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async {
        callOrder.add('setString');
        return true;
      });
      when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async {
        callOrder.add('setBool');
        return true;
      });

      await repository.markDeletionCleanupPending();

      expect(callOrder, ['setString', 'setBool']);
    });

    test(
      'pending-without-UID never happens: crash between writes leaves safe state',
      () async {
        // Stateful fake: stores values in a map, setBool throws on first call.
        final store = <String, Object?>{};
        var boolCallCount = 0;
        final fakePrefs = _StatefulPrefs(
          store: store,
          onSetBool: (key, {required value}) {
            boolCallCount++;
            if (boolCallCount == 1) {
              throw Exception('crash before pending write');
            }
          },
        );

        final repo = AccountCleanupRepositoryImpl(
          firebaseAuth: mockAuth,
          prefs: fakePrefs,
        );

        await expectLater(
          repo.markDeletionCleanupPending(),
          throwsA(isA<Exception>()),
        );

        // UID was written but pending was NOT — UID-only is treated as
        // pending (the backend DELETE succeeded but cleanup never completed).
        expect(
          store['settings.accountDeletionCleanupPendingUid'],
          'firebase-user-1',
        );
        expect(store['settings.accountDeletionCleanupPending'], isNull);
        expect(await repo.hasDeletionCleanupPending(), true);
      },
    );
  });
}
