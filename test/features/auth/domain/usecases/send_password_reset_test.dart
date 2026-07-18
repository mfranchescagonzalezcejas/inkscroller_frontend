import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:inkscroller_flutter/features/auth/domain/usecases/send_password_reset.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AuthRepository repository;
  late SendPasswordReset useCase;

  setUp(() {
    repository = _MockAuthRepository();
    useCase = SendPasswordReset(repository);
  });

  test('returns Right(null) on success', () async {
    when(
      () => repository.sendPasswordReset(email: 'alice@example.com'),
    ).thenAnswer((_) async => const Right<Failure, void>(null));

    final result = await useCase(email: 'alice@example.com');

    expect(result, const Right<Failure, void>(null));
    verify(() => repository.sendPasswordReset(email: 'alice@example.com'))
        .called(1);
  });

  test('returns Left on failure', () async {
    when(
      () => repository.sendPasswordReset(email: 'alice@example.com'),
    ).thenAnswer(
      (_) async => const Left<Failure, void>(
        ServerFailure(message: 'auth/too-many-requests'),
      ),
    );

    final result = await useCase(email: 'alice@example.com');

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure.message, 'auth/too-many-requests'),
      (_) => fail('Expected Left'),
    );
  });
}
