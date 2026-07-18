import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/error/exceptions.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/auth/data/datasources/firebase_auth_data_source.dart';
import 'package:inkscroller_flutter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseAuthDataSource extends Mock
    implements FirebaseAuthDataSource {}

void main() {
  late _MockFirebaseAuthDataSource mockDataSource;
  late AuthRepositoryImpl repository;

  setUp(() {
    mockDataSource = _MockFirebaseAuthDataSource();
    repository = AuthRepositoryImpl(mockDataSource);
  });

  // ── updateDisplayName ──────────────────────────────────────────────────

  group('updateDisplayName', () {
    test('returns Right(null) on success', () async {
      when(
        () => mockDataSource.updateDisplayName(any()),
      ).thenAnswer((_) async {});

      final result = await repository.updateDisplayName('alice');

      expect(result, const Right<Failure, void>(null));
      verify(() => mockDataSource.updateDisplayName('alice')).called(1);
    });

    test('returns Left(Failure) when data source throws', () async {
      when(
        () => mockDataSource.updateDisplayName(any()),
      ).thenThrow(const ServerException(message: 'firebase error'));

      final result = await repository.updateDisplayName('alice');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });
}
