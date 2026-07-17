import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_remote_ds.dart';

/// Concrete implementation of [SettingsRepository].
///
/// Delegates to [SettingsRemoteDataSource] and converts [AppException]s to the
/// domain-safe [Failure] type so the presentation layer never sees Dio details.
class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDataSource _remoteDataSource;

  /// Creates a [SettingsRepositoryImpl] with the given [remoteDataSource].
  const SettingsRepositoryImpl({
    required SettingsRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      await _remoteDataSource.deleteAccount();
      return const Right(null);
    } on AppException catch (error) {
      return Left(_mapExceptionToFailure(error));
    } on Exception catch (_) {
      return const Left(
        UnexpectedFailure(
          message: 'An unexpected error occurred while deleting the account.',
        ),
      );
    }
  }

  Failure _mapExceptionToFailure(AppException exception) {
    return switch (exception) {
      ServerException() => ServerFailure(
        message: exception.message,
        code: exception.code,
      ),
      NetworkException() => NetworkFailure(
        message: exception.message,
        code: exception.code,
      ),
      CacheException() => CacheFailure(
        message: exception.message,
        code: exception.code,
      ),
      UnexpectedException() => UnexpectedFailure(
        message: exception.message,
        code: exception.code,
      ),
    };
  }
}
