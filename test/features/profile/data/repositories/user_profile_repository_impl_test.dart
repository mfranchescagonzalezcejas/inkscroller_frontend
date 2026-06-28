import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/error/exceptions.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/profile/data/datasources/user_profile_remote_ds.dart';
import 'package:inkscroller_flutter/features/profile/data/models/user_profile_model.dart';
import 'package:inkscroller_flutter/features/profile/data/repositories/user_profile_repository_impl.dart';
import 'package:inkscroller_flutter/features/profile/domain/entities/user_profile.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemoteDataSource extends Mock
    implements UserProfileRemoteDataSource {}

void main() {
  late UserProfileRemoteDataSource remoteDataSource;
  late UserProfileRepositoryImpl repository;

  setUp(() {
    remoteDataSource = _MockRemoteDataSource();
    repository = UserProfileRepositoryImpl(remoteDataSource: remoteDataSource);
  });

  const model = UserProfileModel(
    firebaseUid: 'uid-123',
    email: 'alice@example.com',
    username: 'alice_01',
    birthDate: '2000-02-03',
    createdAt: '2026-06-28T12:00:00Z',
  );

  test('updateProfile returns updated profile entity on success', () async {
    when(
      () => remoteDataSource.updateProfile(
        username: any(named: 'username'),
        birthDate: any(named: 'birthDate'),
      ),
    ).thenAnswer((_) async => model);

    final result = await repository.updateProfile(
      username: 'alice_01',
      birthDate: DateTime(2000, 2, 3),
    );

    expect(result, isA<Right<Failure, UserProfile>>());
    final profile = (result as Right<Failure, UserProfile>).value;
    expect(profile.username, 'alice_01');
    expect(profile.birthDate, DateTime(2000, 2, 3));
  });

  test('updateProfile maps server exceptions to server failures', () async {
    when(
      () => remoteDataSource.updateProfile(
        username: any(named: 'username'),
        birthDate: any(named: 'birthDate'),
      ),
    ).thenThrow(const ServerException(message: 'Username already in use'));

    final result = await repository.updateProfile(
      username: 'alice_01',
      birthDate: DateTime(2000, 2, 3),
    );

    expect(result, isA<Left<Failure, UserProfile>>());
    final failure = (result as Left<Failure, UserProfile>).value;
    expect(failure, isA<ServerFailure>());
    expect(failure.message, 'Username already in use');
  });
}
