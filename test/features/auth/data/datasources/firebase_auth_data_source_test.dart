import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/error/exceptions.dart';
import 'package:inkscroller_flutter/features/auth/data/datasources/firebase_auth_data_source.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

/// Tests for [FirebaseAuthDataSourceImpl] covering updateDisplayName behavior
/// including successful calls, no-op when currentUser is null, and Firebase
/// exception mapping.
void main() {
  late _MockFirebaseAuth mockFirebaseAuth;
  late FirebaseAuthDataSourceImpl dataSource;

  setUp(() {
    mockFirebaseAuth = _MockFirebaseAuth();
    dataSource = FirebaseAuthDataSourceImpl(mockFirebaseAuth);
  });

  // ── updateDisplayName ──────────────────────────────────────────────────

  group('updateDisplayName', () {
    test('calls user.updateDisplayName when currentUser is non-null', () async {
      final mockUser = _MockUser();
      when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.updateDisplayName(any())).thenAnswer((_) async {});

      await dataSource.updateDisplayName('alice');

      verify(() => mockUser.updateDisplayName('alice')).called(1);
    });

    test('throws mapped FirebaseAuthException on error', () async {
      final mockUser = _MockUser();
      when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(
        () => mockUser.updateDisplayName(any()),
      ).thenThrow(
        FirebaseAuthException(code: 'too-many-requests'),
      );

      expect(
        () => dataSource.updateDisplayName('alice'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            'auth/too-many-requests',
          ),
        ),
      );
    });

    test('is a no-op when currentUser is null', () async {
      when(() => mockFirebaseAuth.currentUser).thenReturn(null);

      // Should not throw
      await dataSource.updateDisplayName('alice');

      // currentUser was accessed but returned null — no User.updateDisplayName call
      verify(() => mockFirebaseAuth.currentUser).called(1);
    });
  });
}
