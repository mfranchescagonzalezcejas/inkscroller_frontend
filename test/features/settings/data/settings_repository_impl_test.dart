import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/error/exceptions.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/settings/data/datasources/settings_remote_ds.dart';
import 'package:inkscroller_flutter/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemoteDataSource extends Mock implements SettingsRemoteDataSource {}

void main() {
  late SettingsRemoteDataSource remoteDataSource;
  late SettingsRepositoryImpl repository;

  setUp(() {
    remoteDataSource = _MockRemoteDataSource();
    repository = SettingsRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );
  });

  test('deleteAccount returns Right(null) on success', () async {
    when(() => remoteDataSource.deleteAccount()).thenAnswer((_) async {});

    final result = await repository.deleteAccount();

    expect(result, isA<Right<Failure, void>>());
    verify(() => remoteDataSource.deleteAccount()).called(1);
  });

  test('deleteAccount maps ServerException to ServerFailure', () async {
    when(() => remoteDataSource.deleteAccount()).thenThrow(
      const ServerException(message: 'Unauthorized', code: 401),
    );

    final result = await repository.deleteAccount();

    expect(result, isA<Left<Failure, void>>());
    final failure = (result as Left<Failure, void>).value;
    expect(failure, isA<ServerFailure>());
    expect(failure.message, 'Unauthorized');
    expect(failure.code, 401);
  });

  test('deleteAccount maps NetworkException to NetworkFailure', () async {
    when(() => remoteDataSource.deleteAccount()).thenThrow(
      const NetworkException(message: 'Connection timeout'),
    );

    final result = await repository.deleteAccount();

    expect(result, isA<Left<Failure, void>>());
    final failure = (result as Left<Failure, void>).value;
    expect(failure, isA<NetworkFailure>());
    expect(failure.message, 'Connection timeout');
  });

  test('deleteAccount maps unexpected exceptions to UnexpectedFailure', () async {
    when(() => remoteDataSource.deleteAccount()).thenThrow(
      Exception('Something unexpected'),
    );

    final result = await repository.deleteAccount();

    expect(result, isA<Left<Failure, void>>());
    final failure = (result as Left<Failure, void>).value;
    expect(failure, isA<UnexpectedFailure>());
  });
}
