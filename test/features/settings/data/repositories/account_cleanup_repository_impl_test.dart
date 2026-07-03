import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/features/settings/data/repositories/account_cleanup_repository_impl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _MockPrefs extends Mock implements SharedPreferences {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
  });

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

  test(
    'user.delete fails: does NOT sign out and throws critical exception',
    () async {
      when(
        () => mockUser.delete(),
      ).thenAnswer((_) async => throw Exception('quota-exceeded'));
      when(() => mockPrefs.clear()).thenAnswer((_) async => true);

      await expectLater(
        repository.cleanUpAfterDeletion(),
        throwsA(isA<Exception>()),
      );
      verify(() => mockPrefs.clear()).called(1);
      verifyNever(() => mockAuth.signOut());
    },
  );

  test('prefs.clear returns false: signs out, returns prefs warning', () async {
    when(() => mockUser.delete()).thenAnswer((_) async {});
    when(() => mockPrefs.clear()).thenAnswer((_) async => false);

    final result = await repository.cleanUpAfterDeletion();

    expect(result, 'Prefs clear failed');
    verify(() => mockAuth.signOut()).called(1);
  });

  test(
    'user.delete fails: does NOT sign out and throws critical exception even if prefs also fail',
    () async {
      when(
        () => mockUser.delete(),
      ).thenAnswer((_) async => throw Exception('network'));
      when(() => mockPrefs.clear()).thenAnswer((_) async => false);

      await expectLater(
        repository.cleanUpAfterDeletion(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('network'),
          ),
        ),
      );
      verifyNever(() => mockAuth.signOut());
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

    // Already-missing user is not an error — no exception thrown.
    expect(result, isNull);
    verify(() => mockUser.delete()).called(1);
    verify(() => mockAuth.signOut()).called(1);
  });

  test('generic FirebaseAuthException does NOT sign out and throws', () async {
    when(() => mockUser.delete()).thenAnswer(
      (_) async => throw FirebaseAuthException(
        code: 'quota-exceeded',
        message: 'Project quota exceeded.',
      ),
    );
    when(() => mockPrefs.clear()).thenAnswer((_) async => true);

    await expectLater(
      repository.cleanUpAfterDeletion(),
      throwsA(isA<FirebaseAuthException>()),
    );
    verifyNever(() => mockAuth.signOut());
  });
}
