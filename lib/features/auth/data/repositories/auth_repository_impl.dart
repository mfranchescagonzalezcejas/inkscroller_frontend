import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_data_source.dart';

/// Concrete implementation of [AuthRepository].
///
/// Delegates to [FirebaseAuthDataSource] and converts [AppException]s to the
/// domain-safe [Failure] type so the presentation layer never sees Firebase
/// details.
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource _dataSource;

  const AuthRepositoryImpl(this._dataSource);

  @override
  Stream<AppUser?> get authStateChanges => _dataSource.authStateChanges;

  @override
  AppUser? get currentUser => _dataSource.currentUser;

  @override
  Future<Either<Failure, AppUser>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _dataSource.signIn(email: email, password: password);
      return Right(user);
    } on AppException catch (e) {
      return Left(_mapToFailure(e));
    } on Exception catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppUser>> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _dataSource.signUp(email: email, password: password);
      return Right(user);
    } on AppException catch (e) {
      return Left(_mapToFailure(e));
    } on Exception catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _dataSource.signOut();
      return const Right(null);
    } on AppException catch (e) {
      return Left(_mapToFailure(e));
    } on Exception catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> getIdToken() async {
    try {
      final token = await _dataSource.getIdToken();
      return Right(token);
    } on AppException catch (e) {
      return Left(_mapToFailure(e));
    } on Exception catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  Failure _mapToFailure(AppException exception) {
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
